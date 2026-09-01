// Testet UploadController isoliert von der UI -- reine ChangeNotifier-Logik.
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/models/ocr_result.dart';
import 'package:smile/state/upload_controller.dart';

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

    test('processUpload erstellt eine Anfrage mit den hochgeladenen Dateien', () {
      uploadController.addUploadedFile('Rechnung_Test.pdf');
      final req = uploadController.processUpload();

      expect(req.filename, contains('Rechnung_Test.pdf'));
      expect(req.lines, isNotEmpty);
    });
  });
}
