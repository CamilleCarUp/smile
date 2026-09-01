import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/tariff_catalog.dart';
import 'package:smile/logic/invoice_parser.dart';
import 'package:smile/logic/invoice_resolver.dart';
import 'package:smile/models/ocr_result.dart';

List<OcrPage> _loadFixture(String name) {
  final raw = File('test/fixtures/$name').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (json['pages'] as List)
      .map((p) => OcrPage.fromJson(Map<String, dynamic>.from(p as Map)))
      .toList();
}

/// Der echte Referenzdatensatz der App — nicht ein Testabzug davon. So faellt
/// auf, wenn jemand die Datei kaputt macht.
TariffCatalog _loadCatalog() {
  return TariffCatalog.fromJsonString(
      File('assets/reference-data/dentotar_seed.json').readAsStringSync());
}

void main() {
  group('TariffCatalog', () {
    test('liest die Referenzdatei der App ein', () {
      final catalog = _loadCatalog();
      expect(catalog.size, 14);
      expect(catalog.lookup('4.0650')?.taxpunkte, 38.4);
      expect(catalog.lookup('4.5350')?.taxpunkte, 122.0);
    });

    test('alle Taxpunkte stimmen mit dem offiziellen Katalog überein', () {
      // Gegen die amtliche Fassung (Tarif 222, V2.00 / 01.01.2025) geprüft.
      final catalog = _loadCatalog();
      const official = {
        '4.0020': 33.1, '4.0650': 38.4, '4.5350': 122.0, '4.5370': 142.9,
        '4.5390': 170.8, '4.5410': 142.9, '4.5430': 181.3, '4.5450': 216.2,
        '4.5470': 233.6, '4.5510': 240.6, '4.5530': 258.0, '4.5550': 285.9,
        '4.5800': 19.2, '4.5810': 15.7,
      };
      official.forEach((code, tp) {
        expect(catalog.lookup(code)?.taxpunkte, tp, reason: 'Taxpunkte für $code');
      });
    });

    test('nutzt deutsche Bezeichnungen, wie sie auf der Rechnung stehen', () {
      expect(_loadCatalog().lookup('4.0650')?.description, 'Infiltrationsanästhesie');
      expect(_loadCatalog().lookup('4.5350')?.description, 'Kompositfüllung, 1-flächig');
    });

    test('legt offen, dass der Katalog stark unvollständig ist', () {
      // Der Katalog deckt 14 von rund 578 Positionen ab. Die App darf das
      // nicht verschweigen — sonst wirkt ein "nichts gefunden" wie ein
      // Freispruch, obwohl schlicht die Daten fehlen.
      final status = _loadCatalog().status;
      expect(status, isNotEmpty);
      expect(status.toLowerCase(), contains('unvollstaendig'));
    });

    test('meldet unbekannte Codes als unbekannt, statt zu raten', () {
      expect(_loadCatalog().lookup('9.9999'), isNull);
      expect(_loadCatalog().contains('9.9999'), isFalse);
    });
  });

  group('InvoiceResolver mit echter Rechnung', () {
    late ResolvedInvoice resolved;

    setUp(() {
      final invoice = const InvoiceParser().parse(_loadFixture('ocr_kostenvoranschlag.json'));
      resolved = const InvoiceResolver().resolve(invoice, _loadCatalog());
    });

    test('ermittelt den Taxpunktwert der Praxis aus den Beträgen', () {
      // Auf der Rechnung steht 1.20 — die Texterkennung hatte daraus "120"
      // gemacht. Der Wert wird hier gerechnet, nicht gelesen.
      expect(resolved.taxpunktwert, 1.20);
    });

    test('leitet die Mengen her, obwohl das Mengenfeld falsch erkannt wurde', () {
      // Im Bild steht im Mengenfeld "20" bzw. "10" (verlorener Dezimalpunkt).
      // Die richtigen Mengen ergeben sich aus Betrag / (Taxpunkte × TPW).
      expect(resolved.lines.map((l) => l.quantity).toList(), [1, 2, 1, 1, 1]);
    });

    test('erkennt die doppelt verrechnete Infiltrationsanästhesie', () {
      final anaesthesie = resolved.lines.firstWhere((l) => l.code == '4.0650');
      expect(anaesthesie.quantity, 2);
      expect(anaesthesie.amountChf, 92.20);
    });

    test('alle Positionen sind in der Referenzdatenbank enthalten', () {
      expect(resolved.codeCoverage, 1.0);
      expect(resolved.warnings, isNot(contains(ResolverWarning.unknownTariffCodes)));
    });

    test('die Summenprobe gegen das ausgewiesene Total geht auf', () {
      expect(resolved.sumOfLines, closeTo(320.20, 0.01));
      expect(resolved.statedTotal, 320.20);
      expect(resolved.totalsMatch, isTrue);
    });

    test('stuft das Ergebnis als belastbar ein', () {
      expect(resolved.isTrustworthy, isTrue);
      expect(resolved.warnings, isEmpty);
    });

    test('die erwarteten Beträge decken sich mit den verrechneten', () {
      for (final line in resolved.lines) {
        expect(line.expectedAmount(resolved.taxpunktwert!), closeTo(line.amountChf, 0.05),
            reason: 'Position ${line.code} sollte rechnerisch aufgehen');
      }
    });
  });

  group('InvoiceResolver ohne vollständigen Katalog', () {
    ParsedInvoice parsed() =>
        const InvoiceParser().parse(_loadFixture('ocr_kostenvoranschlag.json'));

    // Nur zwei der fünf Codes bekannt — der Rest muss von der Rechnung kommen.
    TariffCatalog partialCatalog() => TariffCatalog.fromEntries(const [
          TariffEntry(code: '4.0020', description: 'Kurzbefundaufnahme', taxpunkte: 33.1),
          TariffEntry(code: '4.5350', description: 'Kompositfüllung, 1-flächig', taxpunkte: 122.0),
        ]);

    test('liest fehlende Taxpunkte von der Rechnung ab', () {
      final r = const InvoiceResolver().resolve(parsed(), partialCatalog());

      expect(r.taxpunktwert, 1.20);
      expect(r.lines.map((l) => l.taxpunkteSource).toList(), [
        TaxpunkteSource.catalog,
        TaxpunkteSource.invoice,
        TaxpunkteSource.catalog,
        TaxpunkteSource.invoice,
        TaxpunkteSource.unresolved,
      ]);
    });

    test('erkennt die doppelte Anästhesie auch ohne Katalogeintrag', () {
      // 4.0650 steht nicht im Katalog. Die Taxpunkte 38.4 werden von der
      // Rechnung gelesen ("38 4"), daraus ergibt sich Menge 2 — dieselbe
      // Aussage wie mit Referenzdatenbank.
      final r = const InvoiceResolver().resolve(parsed(), partialCatalog());
      final anaesthesie = r.lines.firstWhere((l) => l.code == '4.0650');

      expect(anaesthesie.isKnownCode, isFalse);
      expect(anaesthesie.taxpunkte, 38.4);
      expect(anaesthesie.quantity, 2);
      expect(anaesthesie.taxpunkteSource, TaxpunkteSource.invoice);
    });

    test('kommt auch ganz ohne Referenzdatenbank zum richtigen Ergebnis', () {
      final leer = TariffCatalog.fromEntries(const []);
      final r = const InvoiceResolver().resolve(parsed(), leer);

      expect(r.taxpunktwert, 1.20, reason: 'Der Faktor ergibt sich aus den Beträgen selbst');
      expect(r.lines.where((l) => l.isResolved).length, 4);
      expect(r.lines.map((l) => l.quantity).toList(), [1, 2, 1, 1, null]);
      expect(r.codeCoverage, 0.0);
      expect(r.resolvedCoverage, closeTo(0.8, 0.001));
    });

    test('lässt eine Position offen, statt eine falsche Zahl zu erfinden', () {
      // Bei 4.5810 hat die Texterkennung aus 15.7 ein "15" gemacht. Als Menge
      // ginge das knapp auf (18.85 / 18.00 ≈ 1.05), die Frankenprobe verwirft
      // es aber: 15 × 1.20 = 18.00, verrechnet sind 18.85.
      final r = const InvoiceResolver().resolve(parsed(), partialCatalog());
      final offen = r.lines.firstWhere((l) => l.code == '4.5810');

      expect(offen.isResolved, isFalse);
      expect(offen.taxpunkte, isNull);
      expect(offen.quantity, isNull);
      expect(offen.amountChf, 18.85,
          reason: 'Der Betrag zählt weiterhin zur Summe — nur die Zerlegung fehlt');
      expect(r.warnings, contains(ResolverWarning.linesUnresolved));
      expect(r.isTrustworthy, isFalse,
          reason: 'Solange eine Position offen ist, darf das Ergebnis nicht als '
              'belastbar gelten.');
    });

    test('die Summenprobe geht trotz offener Position auf', () {
      // Wichtig: eine nicht zerlegbare Position macht die Rechnung nicht
      // unlesbar. Betrag und Total stimmen weiterhin.
      final r = const InvoiceResolver().resolve(parsed(), partialCatalog());
      expect(r.sumOfLines, closeTo(320.20, 0.01));
      expect(r.totalsMatch, isTrue);
    });
  });

  group('InvoiceResolver in Grenzfällen', () {
    ParsedInvoice buildInvoice(List<(String code, double amount)> rows, {double? total}) {
      return ParsedInvoice(
        rows: rows
            .map((r) => ParsedTariffRow(
                  code: r.$1,
                  description: '',
                  numbers: [
                    NumberField(
                        raw: '${r.$2}',
                        candidates: [r.$2],
                        box: const OcrBox(left: 0, top: 0, right: 10, bottom: 10)),
                  ],
                  box: const OcrBox(left: 0, top: 0, right: 10, bottom: 10),
                ))
            .toList(),
        header: const ParsedInvoiceHeader(),
        statedTotal: total == null
            ? null
            : NumberField(
                raw: '$total',
                candidates: [total],
                box: const OcrBox(left: 0, top: 0, right: 10, bottom: 10)),
      );
    }

    test('meldet unbekannte Tarifcodes, statt sie stillschweigend zu übergehen', () {
      final resolved = const InvoiceResolver()
          .resolve(buildInvoice([('9.9999', 50.0)], total: 50.0), _loadCatalog());

      expect(resolved.warnings, contains(ResolverWarning.unknownTariffCodes));
      expect(resolved.lines.single.isKnownCode, isFalse);
      expect(resolved.lines.single.quantity, isNull);
      expect(resolved.isTrustworthy, isFalse);
    });

    test('meldet eine nicht aufgehende Summenprobe', () {
      final resolved = const InvoiceResolver()
          .resolve(buildInvoice([('4.5350', 146.40)], total: 999.00), _loadCatalog());

      expect(resolved.warnings, contains(ResolverWarning.totalMismatch));
      expect(resolved.totalsMatch, isFalse);
      expect(resolved.isTrustworthy, isFalse);
    });

    test('meldet eine fehlende Gegenprobe, wenn kein Total gefunden wurde', () {
      final resolved =
          const InvoiceResolver().resolve(buildInvoice([('4.5350', 146.40)]), _loadCatalog());

      expect(resolved.warnings, contains(ResolverWarning.noStatedTotal));
      expect(resolved.isTrustworthy, isFalse);
    });

    test('gibt keinen Taxpunktwert aus, wenn keiner plausibel passt', () {
      // Ein Betrag, der zu keinem Taxpunktwert im Bereich 1.0–1.7 führt.
      final resolved = const InvoiceResolver()
          .resolve(buildInvoice([('4.5350', 12.34)], total: 12.34), _loadCatalog());

      expect(resolved.taxpunktwert, isNull);
      expect(resolved.warnings, contains(ResolverWarning.taxpunktwertNotFound));
    });
  });
}
