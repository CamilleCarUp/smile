import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/tariff_catalog.dart';
import 'package:smile/logic/invoice_matcher.dart';
import 'package:smile/logic/invoice_parser.dart';
import 'package:smile/models/ocr_result.dart';

/// Eine zweite Praxissoftware, aufgezeichnet von einer echten Rechnung.
///
/// Sie macht drei Dinge anders als die bisherige Testrechnung:
///   * TP und TPW stehen als eigene Spalten auf der Rechnung,
///   * jeder Position ist ein Behandlungsdatum vorangestellt,
///   * Datum, Code und Bezeichnung stecken in derselben erkannten Zelle.
///
/// Namen, Adressen, IBAN und Referenznummern sind in der Aufzeichnung
/// ersetzt; Tarifzeilen, Beträge und Koordinaten sind unverändert.
List<OcrPage> _fixture() {
  final json = jsonDecode(
          File('test/fixtures/ocr_rechnung_mit_tp_spalten.json').readAsStringSync())
      as Map<String, dynamic>;
  return (json['pages'] as List)
      .map((p) => OcrPage.fromJson(Map<String, dynamic>.from(p as Map)))
      .toList();
}

TariffCatalog _catalog() => TariffCatalog.fromJsonString(
    File('assets/reference-data/dentotar_seed.json').readAsStringSync());

void main() {
  group('Parser', () {
    late ParsedInvoice invoice;
    setUp(() => invoice = invoiceParser.parse(_fixture()));

    test('findet alle drei Positionen', () {
      expect(invoice.rows.map((r) => r.code).toList(),
          ['4.5430', '4.5800', '4.0300']);
    });

    test('das Datum steht nicht in der Bezeichnung', () {
      // "16.02.2026 4.5430 Komposit-Füllung, Molar, zweiflächig" kommt als
      // eine Zelle an. Bliebe das Datum stehen, stünde es in der App unter
      // jeder Position und im Mailentwurf an die Praxis.
      expect(invoice.rows.first.description, 'Komposit-Füllung, Molar, zweiflächig');
      expect(invoice.rows.first.date, DateTime(2026, 2, 16));
      for (final row in invoice.rows) {
        expect(row.description, isNot(contains('2026')));
        expect(row.date, DateTime(2026, 2, 16));
      }
    });

    test('liest das ausgewiesene Total', () {
      expect(invoice.statedTotal?.best, 257.30);
    });

    test('erkennt die Praxis samt Ort', () {
      expect(invoice.header.dentistName, contains('Max Muster'));
      expect(invoice.header.dentistPlace?.plz, '8134');
      expect(invoice.header.dentistPlace?.ort, 'Adliswil');
    });
  });

  group('Auswertung', () {
    late InvoiceAnalysisResult result;
    setUp(() => result = analyzeInvoice(_fixture(), _catalog()));

    test('Beträge und Mengen stimmen', () {
      expect(result.lines.map((l) => l.amountChf).toList(), [217.55, 23.05, 16.70]);
      expect(result.lines.map((l) => l.quantity).toList(), [1, 1, 1]);
    });

    test('der Faktor ist der ausgewiesene Taxpunktwert', () {
      expect(result.factor, closeTo(1.20, 0.01));
    });

    test('die Summenprobe geht auf', () {
      expect(result.statedTotal, 257.30);
      expect(result.totalsMatch, isTrue);
      expect(result.isTrustworthy, isTrue);
    });

    test('die Taxpunkte stimmen mit unserer Referenz überein', () {
      // 4.5430 und 4.5800 stehen im Seed-Katalog — eine fremde Praxis
      // bestätigt damit unsere Werte.
      final tp = {for (final l in result.lines) l.code: l.taxpunkte};
      expect(tp['4.5430'], closeTo(181.3, 0.05));
      expect(tp['4.5800'], closeTo(19.2, 0.05));
      // 4.0300 kennt der Katalog nicht; die Rechnung weist 13.9 aus.
      expect(tp['4.0300'], closeTo(13.9, 0.05));
    });

    test('an dieser Rechnung ist nichts zu beanstanden', () {
      // Die wichtigste Prüfung von allen: Eine korrekte Rechnung muss die App
      // in Ruhe lassen. Taxpunktwert 1.20 liegt weit unter dem Höchstsatz.
      expect(result.findings, isEmpty);
    });
  });
}
