// Testet UploadController isoliert von der UI -- reine ChangeNotifier-Logik.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/tariff_catalog.dart';
import 'package:smile/data/tariff_repository.dart';
import 'package:smile/models/ocr_result.dart';
import 'package:smile/state/requests_repository.dart';
import 'package:smile/state/upload_controller.dart';

import '../support/fake_store.dart';

void main() {
  setUp(() => uploadController.reset());
  tearDown(() => uploadController.reset());

  group('UploadController', () {
    test('addUploadedFile fügt eine Datei hinzu und benachrichtigt Listener', () {
      var notified = false;
      uploadController.addListener(() => notified = true);

      uploadController.addUploadedFile('Foto1.jpg', path: '/tmp/foto1.jpg');

      expect(uploadController.currentUploadFiles, hasLength(1));
      expect(uploadController.currentUploadFiles.first.name, 'Foto1.jpg');
      expect(notified, isTrue);
    });

    test('removeUploadedFile entfernt die Datei am gegebenen Index', () {
      uploadController.addUploadedFile('Foto1.jpg');
      uploadController.addUploadedFile('Foto2.jpg');

      uploadController.removeUploadedFile(0);

      expect(uploadController.currentUploadFiles, hasLength(1));
      expect(uploadController.currentUploadFiles.first.name, 'Foto2.jpg');
    });

    test('reset leert die Liste der hochgeladenen Dateien', () {
      uploadController.addUploadedFile('Foto1.jpg');
      uploadController.reset();
      expect(uploadController.currentUploadFiles, isEmpty);
    });

    test('runOcrOnUploads speichert Zeilen und Rohtext je Datei', () async {
      uploadController.addUploadedFile('seite1.jpg', path: '/tmp/seite1.jpg');

      // Aufgezeichnete statt echte Erkennung: dadurch braucht dieser Test
      // weder Geraet noch ML Kit und laeuft in Millisekunden.
      Future<OcrPage> fakeRecognizer(String path) async => OcrPage(
            sourceName: path,
            lines: const [
              OcrTextLine(text: '4.0650', box: OcrBox(left: 40, top: 300, right: 100, bottom: 316)),
              OcrTextLine(text: '46.10', box: OcrBox(left: 620, top: 301, right: 690, bottom: 317)),
            ],
          );

      await uploadController.runOcrOnUploads(fakeRecognizer);

      final file = uploadController.currentUploadFiles.single;
      expect(file.ocrPage, isNotNull);
      expect(file.ocrPage!.lines, hasLength(2));
      expect(file.recognizedText, '4.0650\n46.10');
    });

    test('runOcrOnUploads haelt einen Erkennungsfehler fest, statt abzustuerzen', () async {
      uploadController.addUploadedFile('kaputt.jpg', path: '/tmp/kaputt.jpg');

      Future<OcrPage> failingRecognizer(String path) async => throw StateError('Bild unlesbar');

      await uploadController.runOcrOnUploads(failingRecognizer);

      final file = uploadController.currentUploadFiles.single;
      expect(file.ocrPage, isNull);
      expect(file.recognizedText, contains('Fehler bei der Texterkennung'));
    });

    test('processUpload erstellt eine Anfrage mit den hochgeladenen Dateien', () async {
      uploadController.addUploadedFile('Rechnung_Test.pdf');
      final req = await uploadController.processUpload();

      expect(req.files, hasLength(1));
      expect(req.lines, isNotEmpty);
      // Der Kameraname überlebt die Erfassung nicht: Benannt wird nach dem,
      // was auf der Rechnung steht. Hier greift die Demo-Auswertung, die
      // keine Rechnungsnummer kennt -- also Praxis und Datum.
      expect(req.filename, isNot(contains('Rechnung_Test')));
      expect(req.filename, contains('Max Muster'));
      expect(req.files.single.name, endsWith('.pdf'),
          reason: 'die Endung des Originals bleibt erhalten');
    });

    test('ohne Erkennungsdaten greift die Demo-Auswertung', () async {
      uploadController.addUploadedFile('Rechnung_Test.pdf');
      final req = await uploadController.processUpload();

      // Erkennbar an der markierten Position aus dem Klickdummy.
      expect(req.flaggedLines, hasLength(1));
      expect(req.flaggedLines.single.code, '4.0650');
    });
  });

  group('mehrere Rechnungen in einem Import', () {
    OcrPage fixture(String name) {
      final json = jsonDecode(File('test/fixtures/$name').readAsStringSync())
          as Map<String, dynamic>;
      return OcrPage.fromJson(
          Map<String, dynamic>.from((json['pages'] as List).first as Map));
    }

    setUp(() {
      requestsRepository = RequestsRepository(store: FakeStore());
      tariffRepository.overrideWith(TariffCatalog.fromJsonString(
          File('assets/reference-data/dentotar_seed.json').readAsStringSync()));
    });

    test('aus zwei Rechnungen werden zwei Einträge, nicht ein Total', () async {
      // Der Fehler, den es zu verhindern gilt: vier fremde Totale zu einer
      // Summe addiert, die es nie gab -- und die richtig aussieht.
      uploadController.addUploadedFile('seite1.png', path: '/tmp/1.png');
      uploadController.addUploadedFile('seite2.png', path: '/tmp/2.png');
      uploadController.currentUploadFiles[0].ocrPage =
          fixture('ocr_rechnung_mit_tp_spalten.json');
      uploadController.currentUploadFiles[1].ocrPage =
          fixture('ocr_kostenvoranschlag.json');

      final erste = await uploadController.processUpload();

      expect(uploadController.erkannteRechnungen, 2);
      expect(requestsRepository.requests, hasLength(2));
      // Angezeigt wird die erste, nicht die zuletzt angelegte.
      expect(requestsRepository.currentRequest, same(erste));
      expect(erste.invoiceNumber, '20001');
      // Jede Rechnung behält ihr eigenes Total.
      expect(erste.statedTotal, 257.30);
      expect(erste.files.single.name, contains('20001'));
    });

    test('eine einzelne Rechnung bleibt ein Eintrag', () async {
      uploadController.addUploadedFile('seite1.png', path: '/tmp/1.png');
      uploadController.currentUploadFiles.single.ocrPage =
          fixture('ocr_rechnung_mit_tp_spalten.json');

      await uploadController.processUpload();

      expect(uploadController.erkannteRechnungen, 1);
      expect(requestsRepository.requests, hasLength(1));
    });
  });
}
