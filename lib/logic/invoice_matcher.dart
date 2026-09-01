import '../data/tariff_catalog.dart';
import '../models/ocr_result.dart';
import '../models/request.dart';
import 'invoice_parser.dart';
import 'invoice_resolver.dart';

/// Fuehrt Parser und Resolver zu dem Ergebnis zusammen, das die Screens
/// anzeigen. Reine Logik ohne Flutter-Abhaengigkeit — testbar ohne Geraet.
class InvoiceAnalysisResult {
  final List<TariffLine> lines;
  final double invoiceTotal;
  final double referenceTotal;

  /// Ermittelter Faktor zwischen Taxpunkten und Franken.
  final double? factor;

  /// Auf der Rechnung ausgewiesenes Total, falls gefunden.
  final double? statedTotal;

  /// Ging die Summenprobe auf?
  final bool totalsMatch;

  /// Darf die App aus diesem Ergebnis eine Aussage ableiten?
  final bool isTrustworthy;

  /// Kopfdaten der Rechnung, falls gelesen.
  final ParsedInvoiceHeader? header;

  const InvoiceAnalysisResult({
    required this.lines,
    required this.invoiceTotal,
    required this.referenceTotal,
    this.factor,
    this.statedTotal,
    this.totalsMatch = false,
    this.isTrustworthy = false,
    this.header,
  });

  double get difference => invoiceTotal - referenceTotal;
  int get unresolvedCount => lines.where((l) => !l.isResolved).length;
}

/// Wertet die erkannten Seiten einer echten Rechnung aus.
///
/// Was hier NICHT passiert: eine Position als auffaellig markieren. Der
/// Resolver stellt fest, was auf der Rechnung steht — ob eine zweifach
/// verrechnete Anaesthesie eine Rueckfrage rechtfertigt, ist eine fachliche
/// Entscheidung und noch nicht getroffen. Bis dahin bleibt [TariffLine.flagged]
/// durchgehend false und der Referenzbetrag gleich dem Rechnungsbetrag.
/// Lieber keine Aussage als eine, die niemand verantwortet hat.
InvoiceAnalysisResult analyzeInvoice(List<OcrPage> pages, TariffCatalog catalog) {
  final parsed = const InvoiceParser().parse(pages);
  final resolved = const InvoiceResolver().resolve(parsed, catalog);

  final lines = resolved.lines
      .map((l) => TariffLine(
            code: l.code,
            description: l.description.isEmpty ? l.code : l.description,
            amountChf: l.amountChf,
            quantity: l.quantity,
            taxpunkte: l.taxpunkte,
            taxpunkteFromCatalog: l.taxpunkteSource == TaxpunkteSource.catalog,
          ))
      .toList();

  final invoiceTotal = resolved.sumOfLines;

  return InvoiceAnalysisResult(
    lines: lines,
    invoiceTotal: invoiceTotal,
    referenceTotal: invoiceTotal,
    factor: resolved.taxpunktwert,
    statedTotal: resolved.statedTotal,
    totalsMatch: resolved.totalsMatch,
    isTrustworthy: resolved.isTrustworthy,
    header: parsed.header,
  );
}

/// Feste Beispieldaten aus dem Klickdummy (Kap. 4.4 der Thesis) — die doppelt
/// verrechnete Infiltrationsanaesthesie ist markiert. Wird noch als
/// Rueckfallweg genutzt, wenn keine Erkennungsdaten vorliegen.
InvoiceAnalysisResult analyzeInvoiceDemo() {
  final lines = <TariffLine>[
    const TariffLine(code: '4.0020', description: 'Kurze klinische Untersuchung', amountChf: 39.70, quantity: 1, taxpunkte: 33.1, taxpunkteFromCatalog: true),
    const TariffLine(code: '4.0650', description: 'Infiltrationsanästhesie', amountChf: 46.10, quantity: 1, taxpunkte: 38.4, taxpunkteFromCatalog: true),
    const TariffLine(code: '4.0650', description: 'Infiltrationsanästhesie', amountChf: 46.10, flagged: true, quantity: 1, taxpunkte: 38.4, taxpunkteFromCatalog: true),
    const TariffLine(code: '4.5350', description: 'Kompositfüllung, einflächig', amountChf: 146.40, quantity: 1, taxpunkte: 122.0, taxpunkteFromCatalog: true),
    const TariffLine(code: '4.5800', description: 'Schmelzätzung', amountChf: 23.05, quantity: 1, taxpunkte: 19.2, taxpunkteFromCatalog: true),
    const TariffLine(code: '4.5810', description: 'Dentinkonditionierung', amountChf: 18.85, quantity: 1, taxpunkte: 15.7, taxpunkteFromCatalog: true),
  ];
  final invoiceTotal = lines.fold(0.0, (sum, l) => sum + l.amountChf);
  final flaggedSum = lines.where((l) => l.flagged).fold(0.0, (sum, l) => sum + l.amountChf);
  return InvoiceAnalysisResult(
    lines: lines,
    invoiceTotal: invoiceTotal,
    referenceTotal: invoiceTotal - flaggedSum,
    factor: 1.20,
    statedTotal: invoiceTotal,
    totalsMatch: true,
    isTrustworthy: true,
  );
}
