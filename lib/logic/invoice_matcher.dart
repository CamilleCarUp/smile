import '../models/request.dart';

/// Reine Logik ohne Flutter-Abhaengigkeit -- absichtlich so getrennt, damit
/// sie sich ohne Geraet/Emulator in Millisekunden testen laesst
/// (`flutter test`, keine UI, kein Widget-Baum noetig).
///
/// Phase 1: liefert feste Demo-Daten (dieselbe Beispielrechnung wie im
/// Klickdummy / Kap. 4.4 der Thesis). Phase 2 ersetzt den Koerper dieser
/// Datei durch echtes Parsen des OCR-Texts + Abgleich mit der lokalen
/// DENTOTAR-Referenzdatenbank -- die Signatur (Dateien/Text rein,
/// TariffLine-Liste raus) bleibt gleich, damit Screens und bestehende
/// Tests unveraendert weiterfunktionieren.
class InvoiceAnalysisResult {
  final List<TariffLine> lines;
  final double invoiceTotal;
  final double referenceTotal;

  const InvoiceAnalysisResult({
    required this.lines,
    required this.invoiceTotal,
    required this.referenceTotal,
  });

  double get difference => invoiceTotal - referenceTotal;
}

InvoiceAnalysisResult analyzeInvoiceDemo() {
  final lines = <TariffLine>[
    const TariffLine(code: '4.0020', description: 'Kurze klinische Untersuchung', amountChf: 39.70),
    const TariffLine(code: '4.0650', description: 'Infiltrationsanästhesie', amountChf: 46.10),
    const TariffLine(code: '4.0650', description: 'Infiltrationsanästhesie', amountChf: 46.10, flagged: true),
    const TariffLine(code: '4.5350', description: 'Kompositfüllung, einflächig', amountChf: 146.40),
    const TariffLine(code: '4.5800', description: 'Schmelzätzung', amountChf: 23.05),
    const TariffLine(code: '4.5810', description: 'Dentinkonditionierung', amountChf: 18.85),
  ];
  final invoiceTotal = lines.fold(0.0, (sum, l) => sum + l.amountChf);
  final flaggedSum = lines.where((l) => l.flagged).fold(0.0, (sum, l) => sum + l.amountChf);
  return InvoiceAnalysisResult(
    lines: lines,
    invoiceTotal: invoiceTotal,
    referenceTotal: invoiceTotal - flaggedSum,
  );
}
