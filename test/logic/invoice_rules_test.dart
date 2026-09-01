import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/tariff_catalog.dart';
import 'package:smile/logic/invoice_matcher.dart';
import 'package:smile/logic/invoice_parser.dart';
import 'package:smile/logic/invoice_resolver.dart';
import 'package:smile/logic/invoice_rules.dart';
import 'package:smile/models/finding.dart';
import 'package:smile/models/ocr_result.dart';

TariffCatalog _catalog() => TariffCatalog.fromJsonString(
    File('assets/reference-data/dentotar_seed.json').readAsStringSync());

List<OcrPage> _fixture() {
  final raw = File('test/fixtures/ocr_kostenvoranschlag.json').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (json['pages'] as List)
      .map((p) => OcrPage.fromJson(Map<String, dynamic>.from(p as Map)))
      .toList();
}

const _box = OcrBox(left: 0, top: 0, right: 10, bottom: 10);

NumberField _num(String raw, List<double> candidates) =>
    NumberField(raw: raw, candidates: candidates, box: _box);

/// Baut eine Rechnung aus (Code, Menge auf dem Papier, Betrag).
ParsedInvoice _invoice(List<(String, String, double)> rows, {double? total}) {
  return ParsedInvoice(
    rows: rows
        .map((r) => ParsedTariffRow(
              code: r.$1,
              description: '',
              numbers: [
                _num(r.$2, [double.parse(r.$2)]),
                _num('${r.$3}', [r.$3]),
              ],
              box: _box,
            ))
        .toList(),
    header: const ParsedInvoiceHeader(),
    statedTotal: total == null ? null : _num('$total', [total]),
  );
}

void main() {
  group('Regel 1 — Preisniveau über dem tariflichen Höchstsatz', () {
    test('die echte Testrechnung löst keinen Befund aus', () {
      final result = analyzeInvoice(_fixture(), _catalog());
      expect(result.factor, 1.20);
      expect(result.findings, isEmpty);
      expect(result.referenceTotal, result.invoiceTotal);
    });

    test('erkennt eine Rechnung deutlich über dem Höchstsatz', () {
      // 4.5350 hat 122.0 Taxpunkte. Zulässig sind höchstens 122.0 × 1.972,
      // also rund CHF 240.60. Verrechnet werden 300.00.
      final resolved = const InvoiceResolver().resolve(
        _invoice([('4.5350', '1', 300.00), ('4.0020', '1', 81.40)], total: 381.40),
        _catalog(),
      );
      final findings = const InvoiceRules().evaluate(resolved);

      expect(resolved.taxpunktwert, closeTo(2.46, 0.01));
      expect(findings, hasLength(1));
      expect(findings.single.kind, FindingKind.factorAboveTariffMaximum);
      expect(findings.single.excessChf, closeTo(75.7, 1.0));
    });

    test('die Mengenspalte entscheidet die Mehrdeutigkeit', () {
      // Ohne diesen Mechanismus wäre die Regel wirkungslos: zum halben Faktor
      // mit doppelten Mengen passt jede Rechnung rechnerisch genauso gut.
      // Erst die auf dem Papier gedruckte Menge 1 widerlegt die Lesart
      // "Faktor 1.23, zweimal verrechnet".
      final resolved = const InvoiceResolver().resolve(
        _invoice([('4.5350', '1', 300.00), ('4.0020', '1', 81.40)], total: 381.40),
        _catalog(),
      );
      expect(resolved.warnings, isNot(contains(ResolverWarning.taxpunktwertAmbiguous)));
      expect(resolved.lines.map((l) => l.quantity).toList(), [1, 1]);
    });

    test('schweigt, wenn die Mengenspalte fehlt und der Faktor mehrdeutig bleibt', () {
      // Dieselben Beträge, aber ohne gedruckte Menge. Jetzt ist nicht
      // entscheidbar, ob teuer einmal oder normal zweimal verrechnet wurde —
      // und die App behauptet dann nichts.
      final ohneMenge = ParsedInvoice(
        rows: [
          ParsedTariffRow(
              code: '4.5350', description: '', numbers: [_num('300.0', [300.00])], box: _box),
          ParsedTariffRow(
              code: '4.0020', description: '', numbers: [_num('81.4', [81.40])], box: _box),
        ],
        header: const ParsedInvoiceHeader(),
        statedTotal: _num('381.4', [381.40]),
      );
      final resolved = const InvoiceResolver().resolve(ohneMenge, _catalog());
      final findings = const InvoiceRules().evaluate(resolved);

      expect(resolved.warnings, contains(ResolverWarning.taxpunktwertAmbiguous));
      expect(findings, isEmpty,
          reason: 'Bei mehrdeutigem Faktor darf kein Befund erhoben werden.');
    });

    test('schweigt, wenn die Summenprobe nicht aufgeht', () {
      final resolved = const InvoiceResolver().resolve(
        _invoice([('4.5350', '1', 300.00), ('4.0020', '1', 81.40)], total: 999.00),
        _catalog(),
      );
      expect(const InvoiceRules().evaluate(resolved), isEmpty,
          reason: 'Ohne bestätigte Lesung ist offen, ob die Rechnung vollständig erfasst wurde.');
    });

    test('schweigt bei Codes ausserhalb der Referenzdatenbank', () {
      // Taxpunkte, die von derselben Rechnung abgelesen wurden, können ihr
      // eigenes Preisniveau nicht bewerten — das wäre ein Zirkelschluss.
      final resolved = const InvoiceResolver().resolve(
        _invoice([('4.5350', '1', 300.00), ('4.0020', '1', 81.40)], total: 381.40),
        TariffCatalog.fromEntries(const []),
      );
      expect(const InvoiceRules().evaluate(resolved), isEmpty);
    });

    test('die Rundung des Faktors verwirft keine korrekte Position', () {
      // Regression: Der Faktor wird für die Anzeige auf zwei Stellen gerundet
      // (2.45906 -> 2.46). Wurde damit auch nachgerechnet, ergab das bei 122
      // Taxpunkten 12 Rappen Abweichung — genug, um die Frankenprobe zu
      // reissen und eine völlig korrekte Position als "nicht aufschlüsselbar"
      // auszugeben. Je teurer die Position, desto schlimmer.
      final resolved = const InvoiceResolver().resolve(
        _invoice([('4.5350', '1', 300.00), ('4.0020', '1', 81.40)], total: 381.40),
        _catalog(),
      );
      expect(resolved.lines.every((l) => l.isResolved), isTrue,
          reason: 'Gerechnet wird ungerundet, gerundet wird nur die Anzeige.');
      expect(resolved.taxpunktwert, closeTo(2.46, 0.01));
    });

    test('der Höchstsatz leitet sich aus den amtlichen Grenzen ab', () {
      // Taxpunkte höchstens 1.16-fach (TP (PP) max), Taxpunktwert höchstens
      // 1.70 — beides aus dem offiziellen Tarif.
      expect(InvoiceRules.maxErlaubterFaktor, closeTo(1.972, 0.001));
      expect(const InvoiceRules().befundSchwelle,
          greaterThan(InvoiceRules.maxErlaubterFaktor));
    });
  });
}
