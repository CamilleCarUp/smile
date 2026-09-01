import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/tariff_catalog.dart';
import 'package:smile/logic/invoice_matcher.dart';
import 'package:smile/logic/invoice_parser.dart';
import 'package:smile/logic/invoice_resolver.dart';
import 'package:smile/models/ocr_result.dart';

List<OcrPage> _fixture(String name) {
  final raw = File('test/fixtures/$name').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (json['pages'] as List)
      .map((p) => OcrPage.fromJson(Map<String, dynamic>.from(p as Map)))
      .toList();
}

TariffCatalog _catalog() => TariffCatalog.fromJsonString(
    File('assets/reference-data/dentotar_seed.json').readAsStringSync());

void main() {
  group('Verkantetes Foto', () {
    // Aufzeichnung eines echten Handy-Fotos. Die Texterkennung war hier
    // ausgezeichnet -- alle Codes, alle Beträge, sogar die Mengenspalte sauber.
    // Trotzdem kam von fünf Positionen nur eine an: Das Blatt lag rund
    // eineinhalb Grad schief, wodurch die Beträge rechts etwa 35 Pixel tiefer
    // standen als ihre Codes links. Bei nur 45 Pixel Zeilenabstand lag damit
    // jeder Code näher an den Zahlen der Zeile darüber als an seinen eigenen.
    late List<OcrPage> pages;

    setUp(() => pages = _fixture('ocr_kostenvoranschlag_verkantet.json'));

    test('die Verkantung wird erkannt', () {
      final skew = estimateSkew(pages.single.lines);
      expect(skew, greaterThan(0.015),
          reason: 'Rund 35 Pixel Versatz auf 1500 Pixel Breite');
      expect(skew, lessThan(0.035));
    });

    test('ohne Entzerrung bekommt jede Position den Betrag ihrer Nachbarin', () {
      // Der eigentliche Schaden ist nicht, dass Zeilen verlorengehen, sondern
      // dass die Zuordnung um eine Zeile verrutscht: Die Anästhesie erhält die
      // Zahlen der Kurzbefundaufnahme, die Füllung die der Anästhesie. Auf dem
      // Bildschirm sieht das völlig plausibel aus — echte Zahlen dieser
      // Rechnung, nur bei der falschen Position. Genau die Sorte Fehler, die
      // niemand bemerkt.
      final rows = groupIntoRows(pages.single.lines, skew: 0);

      List<String> zeileMit(String code) => rows
          .firstWhere((r) => r.any((c) => c.text.startsWith(code)))
          .map((c) => c.text)
          .toList();

      expect(zeileMit('4.0020'), isNot(contains('39.70')),
          reason: 'Die Kurzbefundaufnahme verliert ihren eigenen Betrag.');
      expect(zeileMit('4.0650'), contains('39.70'),
          reason: 'Und die Anästhesie erbt ihn — das ist der gefährliche Teil.');
    });

    test('mit Entzerrung behält jede Position ihren eigenen Betrag', () {
      final rows = groupIntoRows(pages.single.lines);

      List<String> zeileMit(String code) => rows
          .firstWhere((r) => r.any((c) => c.text.startsWith(code)))
          .map((c) => c.text)
          .toList();

      expect(zeileMit('4.0020'), contains('39.70'));
      expect(zeileMit('4.0650'), contains('92.20'));
      expect(zeileMit('4.5350'), contains('146.40'));
    });

    test('die Summenprobe hätte den verrutschten Fall aufgefangen', () {
      // Auch wenn die Entzerrung eines Tages versagt: Verrutschte Zuordnungen
      // lassen die Summe nicht mehr aufgehen, und dann gibt die App das
      // Ergebnis nicht als belastbar aus. Das Sicherheitsnetz bleibt gespannt.
      final verrutscht = ParsedInvoice(
        rows: const InvoiceParser()
            .parse(pages)
            .rows
            .take(4)
            .toList(),
        header: const ParsedInvoiceHeader(),
        statedTotal: const InvoiceParser().parse(pages).statedTotal,
      );
      final resolved = const InvoiceResolver().resolve(verrutscht, _catalog());
      expect(resolved.totalsMatch, isFalse);
      expect(resolved.isTrustworthy, isFalse);
    });

    test('mit Entzerrung werden alle fünf Positionen gefunden', () {
      final invoice = const InvoiceParser().parse(pages);
      expect(invoice.rows.map((r) => r.code).toList(),
          ['4.0020', '4.0650', '4.5350', '4.5800', '4.5810']);
    });

    test('jede Position behält ihren eigenen Betrag', () {
      final invoice = const InvoiceParser().parse(pages);
      expect(invoice.rows.map((r) => r.rightmostNumber?.best).toList(),
          [39.70, 92.20, 146.40, 23.05, 18.85]);
      expect(invoice.statedTotal?.best, 320.20);
    });

    test('die vollständige Auswertung geht auf', () {
      final result = analyzeInvoice(pages, _catalog());

      expect(result.factor, 1.20);
      expect(result.lines.map((l) => l.quantity).toList(), [1, 2, 1, 1, 1]);
      expect(result.invoiceTotal, closeTo(320.20, 0.01));
      expect(result.totalsMatch, isTrue);
      expect(result.isTrustworthy, isTrue);
      expect(result.findings, isEmpty, reason: 'Faktor 1.20 liegt weit unter dem Höchstsatz');
    });

    test('die Kopfdaten kommen sauber durch', () {
      final result = analyzeInvoice(pages, _catalog());
      expect(result.header?.dentistEmail, 'test@zahnarzt.ch');
      expect(result.header?.invoiceNumber, '112233');
      expect(result.header?.date, DateTime(2026, 2, 16));
    });
  });

  group('Gerade aufgenommene Rechnung', () {
    test('bleibt von der Entzerrung unberührt', () {
      final pages = _fixture('ocr_kostenvoranschlag.json');
      expect(estimateSkew(pages.single.lines).abs(), lessThan(0.01));

      final result = analyzeInvoice(pages, _catalog());
      expect(result.lines.map((l) => l.code).toList(),
          ['4.0020', '4.0650', '4.5350', '4.5800', '4.5810']);
      expect(result.factor, 1.20);
    });
  });
}
