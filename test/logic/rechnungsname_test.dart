import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/tariff_catalog.dart';
import 'package:smile/logic/invoice_matcher.dart';
import 'package:smile/logic/rechnungsname.dart';
import 'package:smile/models/ocr_result.dart';
import 'package:smile/models/request.dart';
import 'package:smile/state/requests_repository.dart';

import '../support/fake_store.dart';

List<OcrPage> _fixture() {
  final json = jsonDecode(
      File('test/fixtures/ocr_kostenvoranschlag.json').readAsStringSync()) as Map<String, dynamic>;
  return (json['pages'] as List)
      .map((p) => OcrPage.fromJson(Map<String, dynamic>.from(p as Map)))
      .toList();
}

void main() {
  group('rechnungsName', () {
    test('nimmt Rechnungsnummer und Praxis', () {
      expect(
          rechnungsName(
              rechnungsnummer: '112233',
              praxis: 'Dr. med. dent. Max Muster',
              datum: DateTime(2026, 2, 16)),
          '112233 Dr. med. dent. Max Muster');
    });

    test('kommt mit einer fehlenden Angabe zurecht', () {
      expect(rechnungsName(rechnungsnummer: '112233'), 'Rechnung 112233');
      // Ohne Nummer trägt das Datum die Unterscheidung.
      expect(
          rechnungsName(
              praxis: 'Zahnarztpraxis Seefeld', datum: DateTime(2026, 2, 16)),
          'Zahnarztpraxis Seefeld 16.02.2026');
      expect(rechnungsName(datum: DateTime(2026, 2, 16)), 'Rechnung vom 16.02.2026');
      expect(rechnungsName(), 'Rechnung');
    });

    test('erfindet keine Praxis, wo keine gelesen wurde', () {
      // Genau dieser Platzhalter steht im Verlauf, wenn der Briefkopf
      // unlesbar war — als Dateiname wäre er eine Behauptung.
      expect(
          rechnungsName(
              rechnungsnummer: '112233', praxis: 'Praxis nicht erkannt'),
          'Rechnung 112233');
      expect(rechnungsName(rechnungsnummer: '  ', praxis: '   '), 'Rechnung');
    });

    test('wirft Zeichen hinaus, die in keinen Dateinamen gehören', () {
      expect(rechnungsName(rechnungsnummer: 'R/115', praxis: 'Praxis "Zahn" *'),
          'R 115 Praxis Zahn');
    });

    test('kürzt einen überlangen Namen', () {
      final lang = rechnungsName(
          rechnungsnummer: '112233', praxis: 'Gemeinschaftspraxis ' * 10);
      expect(lang.length, lessThanOrEqualTo(maxNamensLaenge + 1));
      expect(lang, endsWith('…'));
    });
  });

  group('seitenName', () {
    test('behält die Endung des Originals', () {
      expect(
          seitenName(basis: '112233 Muster', seite: 1, seiten: 1, original: 'IMG_2034.JPG'),
          '112233 Muster.jpg');
    });

    test('nummeriert nur bei mehreren Seiten', () {
      expect(
          seitenName(basis: '112233 Muster', seite: 2, seiten: 3, original: 'a.png'),
          '112233 Muster Seite 2.png');
    });

    test('kommt ohne Endung aus', () {
      expect(seitenName(basis: 'Rechnung', seite: 1, seiten: 1), 'Rechnung');
      expect(seitenName(basis: 'Rechnung', seite: 1, seiten: 1, original: 'foto'), 'Rechnung');
      // Ein Punkt mitten im Namen ist keine Endung.
      expect(seitenName(basis: 'Rechnung', seite: 1, seiten: 1, original: 'Dr. Muster Rechnung'),
          'Rechnung');
    });
  });

  group('beim Erfassen einer echten Rechnung', () {
    setUp(() => requestsRepository = RequestsRepository(store: FakeStore()));

    test('Bild und Eintrag heissen nach Nummer und Praxis', () {
      final katalog = TariffCatalog.fromJsonString(
          File('assets/reference-data/dentotar_seed.json').readAsStringSync());

      final req = requestsRepository.createFromAnalysis(
        files: [UploadedFile('IMG_20260216_101233.jpg', path: '/tmp/img.jpg')],
        analysis: analyzeInvoice(_fixture(), katalog),
      );

      expect(req.filename, '112233 Dr. med. dent. Max Muster');
      expect(req.files.single.name, '112233 Dr. med. dent. Max Muster.jpg');
    });
  });
}
