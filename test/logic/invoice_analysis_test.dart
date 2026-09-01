import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/tariff_catalog.dart';
import 'package:smile/logic/invoice_matcher.dart';
import 'package:smile/models/ocr_result.dart';

/// Die ganze Kette an einer echten Rechnung: Erkennung -> Zeilen -> Positionen
/// -> Zahlen -> das, was die Screens anzeigen.
List<OcrPage> _fixture() {
  final raw = File('test/fixtures/ocr_kostenvoranschlag.json').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (json['pages'] as List)
      .map((p) => OcrPage.fromJson(Map<String, dynamic>.from(p as Map)))
      .toList();
}

TariffCatalog _catalog() => TariffCatalog.fromJsonString(
    File('assets/reference-data/dentotar_seed.json').readAsStringSync());

void main() {
  group('analyzeInvoice mit echter Rechnung', () {
    late InvoiceAnalysisResult result;

    setUp(() => result = analyzeInvoice(_fixture(), _catalog()));

    test('liefert die fünf Positionen mit Beträgen und Mengen', () {
      expect(result.lines.map((l) => l.code).toList(),
          ['4.0020', '4.0650', '4.5350', '4.5800', '4.5810']);
      expect(result.lines.map((l) => l.quantity).toList(), [1, 2, 1, 1, 1]);
      expect(result.lines.map((l) => l.amountChf).toList(),
          [39.70, 92.20, 146.40, 23.05, 18.85]);
    });

    test('rechnet Summe, Faktor und Gegenprobe aus', () {
      expect(result.invoiceTotal, closeTo(320.20, 0.01));
      expect(result.factor, 1.20);
      expect(result.statedTotal, 320.20);
      expect(result.totalsMatch, isTrue);
      expect(result.isTrustworthy, isTrue);
      expect(result.unresolvedCount, 0);
    });

    test('markiert nichts, solange keine Prüfregeln festgelegt sind', () {
      // Bewusst so: der Resolver stellt fest, was auf der Rechnung steht.
      // Ob eine doppelte Anästhesie eine Rückfrage rechtfertigt, ist eine
      // fachliche Entscheidung und noch nicht getroffen.
      expect(result.lines.where((l) => l.flagged), isEmpty);
      expect(result.referenceTotal, result.invoiceTotal);
      expect(result.difference, 0);
    });

    test('liest die Kopfdaten für die Rückfrage mit', () {
      expect(result.header?.dentistName, 'Dr. med. dent. Max Muster');
      expect(result.header?.dentistEmail, 'test@zahnarzt.ch');
      expect(result.header?.invoiceNumber, '112233');
    });

    test('kennzeichnet, woher die Taxpunkte stammen', () {
      expect(result.lines.every((l) => l.taxpunkteFromCatalog), isTrue);
    });
  });

  group('analyzeInvoice ohne Referenzdatenbank', () {
    test('kommt weit, aber lässt die unlesbare Position offen', () {
      final result = analyzeInvoice(_fixture(), TariffCatalog.fromEntries(const []));

      expect(result.factor, 1.20);
      expect(result.unresolvedCount, 1);
      expect(result.lines.where((l) => l.isResolved).length, 4);
      expect(result.lines.every((l) => !l.taxpunkteFromCatalog), isTrue);
      expect(result.isTrustworthy, isFalse,
          reason: 'Eine offene Position genügt, um das Ergebnis nicht als '
              'belastbar auszugeben.');
      // Die Summe stimmt trotzdem — der Betrag der offenen Position zählt mit.
      expect(result.invoiceTotal, closeTo(320.20, 0.01));
      expect(result.totalsMatch, isTrue);
    });
  });

  group('analyzeInvoiceDemo', () {
    test('bleibt als Rückfallweg erhalten und markiert die Doppelverrechnung', () {
      final demo = analyzeInvoiceDemo();
      expect(demo.lines, hasLength(6));
      expect(demo.lines.where((l) => l.flagged).single.code, '4.0650');
      expect(demo.isTrustworthy, isTrue);
    });
  });
}
