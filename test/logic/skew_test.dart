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

  group('Stark verkantetes Foto (rund acht Grad)', () {
    // Zweites Gerätefoto, deutlich schiefer als das erste. Die App fand nur
    // zwei Positionen und wies beiden den Betrag einer anderen zu. Zwei
    // Ursachen: die Neigung lag mit 0.137 weit ausserhalb des damaligen
    // Suchbereichs von 0.06, und die Texterkennung las den Punkt im ersten
    // Tarifcode als Komma ("4,0020"), wodurch die Position ganz durchfiel.
    late List<OcrPage> pages;

    setUp(() => pages = _fixture('ocr_kostenvoranschlag_stark_verkantet.json'));

    test('die starke Verkantung wird erkannt', () {
      final skew = estimateSkew(pages.single.lines);
      expect(skew, closeTo(0.137, 0.015),
          reason: 'Rund 180 Pixel Versatz über die Blattbreite');
    });

    test('ein Tarifcode mit Komma wird trotzdem gefunden', () {
      final invoice = const InvoiceParser().parse(pages);
      expect(invoice.rows.map((r) => r.code), contains('4.0020'),
          reason: 'Auf dem Papier steht "4,0020" — normalisiert wird auf die '
              'Schreibweise des Tarifs.');
      expect(invoice.rows.firstWhere((r) => r.code == '4.0020').description,
          'Kurzbefundaufnahme',
          reason: 'Aus der Bezeichnung muss der tatsächlich gelesene Text weg, '
              'nicht der normalisierte.');
    });

    test('alle fünf Positionen behalten ihren eigenen Betrag', () {
      final invoice = const InvoiceParser().parse(pages);
      expect(invoice.rows.map((r) => r.code).toList(),
          ['4.0020', '4.0650', '4.5350', '4.5800', '4.5810']);
      expect(invoice.rows.map((r) => r.rightmostNumber?.best).toList(),
          [39.70, 92.20, 146.40, 23.05, 18.85]);
    });

    test('die vollständige Auswertung geht auf', () {
      final result = analyzeInvoice(pages, _catalog());
      expect(result.factor, 1.20);
      expect(result.lines.map((l) => l.quantity).toList(), [1, 2, 1, 1, 1]);
      expect(result.invoiceTotal, closeTo(320.20, 0.01));
      expect(result.totalsMatch, isTrue);
      expect(result.isTrustworthy, isTrue);
      expect(result.findings, isEmpty);
    });

    test('ohne ausreichenden Suchbereich bleibt die Verkantung unerkannt', () {
      // Der Nachweis, dass der weite Suchbereich nötig ist. Mit dem alten
      // Grenzwert 0.06 wird die tatsächliche Neigung von 0.137 nie gefunden.
      final zuEng = estimateSkew(pages.single.lines, maxSlope: 0.06);
      expect(zuEng.abs(), lessThan(0.06));
      expect((zuEng - 0.137).abs(), greaterThan(0.05));
    });
  });

  group('Neun Grad — mehrere Ausrichtungen sind gleich plausibel', () {
    // Drittes Gerätefoto. Hier fand die App zwar alle fünf Positionen, wies
    // aber jeder den Betrag ihrer Nachbarin zu; die letzte bekam sogar das
    // Rechnungstotal. Ursache ist grundsätzlich: Eine Rechnung ist ein
    // regelmässiges Raster. Verschiebt man die Neigung gerade so weit, dass
    // jede Zeile auf die nächste fällt, ist das Ergebnis genauso "scharf".
    // Aus der Schärfe allein lässt sich das nicht entscheiden — hier lagen
    // die gleichwertigen Kandidaten 0.031 auseinander, und der bestbewertete
    // war der falsche.
    late List<OcrPage> pages;

    setUp(() => pages = _fixture('ocr_kostenvoranschlag_zeilenversatz.json'));

    test('das Projektionsprofil allein wählt die falsche Ausrichtung', () {
      // Der Nachweis, dass die Summenprobe als Entscheider nötig ist.
      final rows = groupIntoRows(pages.single.lines, skew: estimateSkew(pages.single.lines));
      final zeile = rows.firstWhere((r) => r.any((c) => c.text.startsWith('4.0020')));
      expect(zeile.map((c) => c.text), isNot(contains('39.70')),
          reason: 'Die bestbewertete Neigung ordnet den Betrag der falschen Position zu.');
    });

    test('mehrere Kandidaten werden angeboten', () {
      final kandidaten = skewCandidates(pages.single.lines);
      expect(kandidaten.length, greaterThan(1));
      expect(kandidaten.any((s) => (s - 0.157).abs() < 0.012), isTrue,
          reason: 'Die richtige Neigung muss unter den Kandidaten sein.');
    });

    test('die Summenprobe wählt die richtige Ausrichtung', () {
      final invoice = const InvoiceParser().parse(pages);
      expect(invoice.rows.map((r) => r.code).toList(),
          ['4.0020', '4.0650', '4.5350', '4.5800', '4.5810']);
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
    });
  });

  group('Schiefe Aufnahme wird als solche gemeldet', () {
    test('das stark verkantete Foto gilt als schief', () {
      final invoice = const InvoiceParser()
          .parse(_fixture('ocr_kostenvoranschlag_stark_verkantet.json'));
      expect(invoice.wasPhotographedCrooked, isTrue);
    });

    test('die gerade Aufnahme gilt nicht als schief', () {
      final invoice =
          const InvoiceParser().parse(_fixture('ocr_kostenvoranschlag.json'));
      expect(invoice.wasPhotographedCrooked, isFalse);
    });

    test('die Meldung erreicht die Auswertung', () {
      final result = analyzeInvoice(
          _fixture('ocr_kostenvoranschlag_zeilenversatz.json'), _catalog());
      expect(result.wasPhotographedCrooked, isTrue,
          reason: 'Auch wenn die Lesung gelingt, bleibt die Aufnahme schief — '
              'der Hinweis erscheint nur, wenn das Ergebnis unsicher ist.');
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
