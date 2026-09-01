import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/logic/invoice_parser.dart';
import 'package:smile/models/ocr_result.dart';

/// Aufgezeichnete Texterkennung einer echten Rechnung.
///
/// Bewusst echte statt ausgedachter Daten: Rechnungen sehen anders aus, als
/// man sie sich vorstellt — der Dezimalpunkt fehlt, Umlaute verrutschen, und
/// wenn jemand einen Bildschirm abfotografiert, landet die Werkzeugleiste des
/// PDF-Betrachters mit im Text. Genau das steckt in diesem Datensatz.
List<OcrPage> _loadFixture(String name) {
  final raw = File('test/fixtures/$name').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (json['pages'] as List)
      .map((p) => OcrPage.fromJson(Map<String, dynamic>.from(p as Map)))
      .toList();
}

void main() {
  group('numberCandidates', () {
    test('nimmt einen sichtbaren Dezimaltrenner beim Wort', () {
      expect(numberCandidates('39.70'), [39.70]);
      expect(numberCandidates('1.20'), [1.20]);
      expect(numberCandidates('122,0'), [122.0]);
    });

    test('deutet ein Leerzeichen als verlorenen Trenner', () {
      // Häufigster Erkennungsfehler auf echten Rechnungen.
      expect(numberCandidates('92 20'), [92.20]);
      expect(numberCandidates('38 4'), [38.4]);
      expect(numberCandidates('23 05'), [23.05]);
    });

    test('ignoriert angehängte Währungskürzel, auch falsch erkannte', () {
      expect(numberCandidates('320.20 CHF'), [320.20]);
      expect(numberCandidates('320.20GHF'), [320.20]);
      expect(numberCandidates('320.20 CHE'), [320.20]);
    });

    test('bietet bei fehlendem Trenner mehrere Lesarten an, statt zu raten', () {
      // "120" ist auf der Rechnung der Taxpunktwert 1.20 — das lässt sich aus
      // dem Zahlenfeld allein nicht entscheiden.
      expect(numberCandidates('120'), [120.0, 12.0, 1.20]);
      expect(numberCandidates('15'), [15.0, 1.5]);
    });

    test('liefert nichts zurück, wo keine Zahl ist', () {
      expect(numberCandidates('Kostenvoranschlag'), isEmpty);
      expect(numberCandidates(''), isEmpty);
    });
  });

  group('groupIntoRows', () {
    test('hält Tarifcode und Betrag zusammen, obwohl sie weit auseinander stehen', () {
      // Der Kern von Phase 2: im flachen Erkennungstext verlieren diese beiden
      // ihren Bezug, über die vertikale Überlappung nicht.
      const code = OcrTextLine(
          text: '4.0650 Infiltrationsanästhesie',
          box: OcrBox(left: 88, top: 2134, right: 413, bottom: 2157));
      const amount = OcrTextLine(
          text: '92 20', box: OcrBox(left: 1662, top: 2140, right: 1719, bottom: 2162));
      const otherRow = OcrTextLine(
          text: '146.40', box: OcrBox(left: 1651, top: 2185, right: 1719, bottom: 2210));

      final rows = groupIntoRows([code, amount, otherRow]);

      expect(rows, hasLength(2));
      expect(rows.first.map((l) => l.text), containsAll(['4.0650 Infiltrationsanästhesie', '92 20']));
      expect(rows.last.single.text, '146.40');
    });

    test('sortiert Zeilen von oben nach unten und Zellen von links nach rechts', () {
      const unten = OcrTextLine(text: 'unten', box: OcrBox(left: 90, top: 300, right: 150, bottom: 320));
      const obenRechts = OcrTextLine(text: 'rechts', box: OcrBox(left: 900, top: 100, right: 960, bottom: 120));
      const obenLinks = OcrTextLine(text: 'links', box: OcrBox(left: 90, top: 100, right: 150, bottom: 120));

      final rows = groupIntoRows([unten, obenRechts, obenLinks]);

      expect(rows.first.map((l) => l.text).toList(), ['links', 'rechts']);
      expect(rows.last.single.text, 'unten');
    });
  });

  group('InvoiceParser mit echter Rechnung (Kostenvoranschlag)', () {
    late ParsedInvoice invoice;

    setUp(() {
      invoice = const InvoiceParser().parse(_loadFixture('ocr_kostenvoranschlag.json'));
    });

    test('findet genau die fünf Tarifpositionen', () {
      expect(invoice.rows.map((r) => r.code).toList(),
          ['4.0020', '4.0650', '4.5350', '4.5800', '4.5810']);
    });

    test('lässt die Werkzeugleiste des PDF-Betrachters draussen', () {
      // Der Screenshot enthält "Add Links to URLS", "Remove All Web-Links",
      // "Sign", "Protect" usw. Ohne Tarifcode ist nichts davon eine Position —
      // das erledigt die Code-Erkennung ohne Sonderregel.
      final alleTexte = invoice.rows.map((r) => '${r.code} ${r.description}').join(' ');
      expect(alleTexte, isNot(contains('Links')));
      expect(alleTexte, isNot(contains('Sign')));
      expect(alleTexte, isNot(contains('Protect')));
    });

    test('liest die Bezeichnungen mit, auch mit Erkennungsfehlern', () {
      expect(invoice.rows[0].description, 'Kurzbefundaufnatme');
      expect(invoice.rows[1].description, 'infiltrationsanästhesie');
      expect(invoice.rows[2].description, 'Kompositfüllung, einflächig');
    });

    test('der rechteste Wert jeder Zeile ist der Zeilenbetrag', () {
      final betraege = invoice.rows.map((r) => r.rightmostNumber?.best).toList();
      expect(betraege, [39.70, 92.20, 146.40, 23.05, 18.85]);
    });

    test('die Zeilenbeträge ergeben in Summe das ausgewiesene Total', () {
      // Diese Gegenprobe ist der Grund, warum unsichere Zahlen nicht geraten
      // werden müssen: die Rechnung prüft sich selbst.
      final summe = invoice.rows
          .map((r) => r.rightmostNumber?.best ?? 0)
          .fold(0.0, (a, b) => a + b);

      expect(invoice.statedTotal?.best, 320.20);
      expect(summe, closeTo(320.20, 0.01));
    });

    test('markiert mehrdeutige Zahlenfelder als solche', () {
      // In der Zeile 4.0020 steht der Taxpunktwert als "120" — ohne Trenner.
      final row = invoice.rows.first;
      final mehrdeutige = row.numbers.where((n) => n.isAmbiguous).toList();
      expect(mehrdeutige, isNotEmpty,
          reason: 'Ein Feld ohne erkennbaren Dezimaltrenner muss als unsicher gelten, '
              'damit später die Gegenrechnung entscheidet statt einer Vermutung.');
    });

    test('liest die Kopfdaten der Praxis', () {
      expect(invoice.header.dentistName, 'Dr. med. dent. Max Muster');
      expect(invoice.header.dentistAddress, 'Alte Gase 13, 8005 Zürich');
      expect(invoice.header.dentistEmail, 'test@zahnarzt.ch');
    });

    test('liest Referenznummer, Datum und Patient', () {
      expect(invoice.header.invoiceNumber, '112233');
      expect(invoice.header.patient, 'Toni Maloni, R115');
      // Auf der Rechnung steht "16.022026" — der zweite Punkt fehlt.
      expect(invoice.header.date, DateTime(2026, 2, 16));
    });
  });
}
