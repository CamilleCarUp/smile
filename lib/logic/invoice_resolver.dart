import '../data/tariff_catalog.dart';
import 'invoice_parser.dart';

/// Rechnet aus einer erkannten Rechnung die belastbaren Zahlen heraus.
///
/// Das Problem: die Texterkennung liefert Zahlen beschaedigt (fehlender
/// Dezimalpunkt, verschluckte Ziffern). Ihnen zu glauben, hiesse falsche
/// Abweichungen zu behaupten.
///
/// Der Ausweg ist die Redundanz der Rechnung selbst. Zwei Angaben sind
/// belastbar: der **Tarifcode** (das Muster 4.xxxx wird zuverlaessig erkannt)
/// und der **Zeilenbetrag** (steht ganz rechts, meist mit lesbarem
/// Dezimaltrenner). Alles Uebrige wird gerechnet statt gelesen.
///
/// Fuer die Taxpunkte gibt es zwei Quellen, in dieser Reihenfolge:
///   1. **Die Referenzdatenbank**, wenn sie den Code kennt — der sicherste Weg.
///   2. **Die Rechnung selbst.** Rechnungen drucken ihre Taxpunkte in einer
///      eigenen Spalte mit. Deren Erkennung ist unsicher ("192" statt 19.2),
///      aber unter allen Lesarten passt meist nur eine zum Zeilenbetrag.
///
/// Damit ist die App nicht auf den Umfang der Referenzdatenbank beschraenkt.
/// Auf einer echten Testrechnung werden auch ganz ohne Katalog vier von fuenf
/// Positionen korrekt aufgeschluesselt.
///
/// Zwei Proben verhindern, dass eine Vermutung als Ergebnis durchgeht:
///   * die zurueckgerechnete Anzahl muss eine ganze Zahl sein, und
///   * Taxpunkte × Taxpunktwert × Anzahl muss den Zeilenbetrag auf wenige
///     Rappen treffen.
/// Wo das nicht aufgeht, bleibt die Position unaufgeschluesselt — das ist
/// gewollt. Eine erfundene Zahl waere schlimmer als eine fehlende.

enum ResolverWarning {
  /// Mindestens eine Position ist nicht in der Referenzdatenbank.
  unknownTariffCodes,

  /// Es liess sich kein Taxpunktwert finden, der zu den Betraegen passt.
  taxpunktwertNotFound,

  /// Die Summe der Zeilenbetraege weicht vom ausgewiesenen Total ab.
  totalMismatch,

  /// Auf der Rechnung wurde kein Total gefunden — die Gegenprobe fehlt.
  noStatedTotal,

  /// Zum halben Taxpunktwert mit doppelten Mengen passt die Rechnung genauso
  /// gut. Rechnerisch nicht entscheidbar — die Mengen sind dann unsicher.
  taxpunktwertAmbiguous,

  /// Mindestens eine Position liess sich nicht in Taxpunkte und Anzahl
  /// zerlegen. Ihr Betrag zaehlt weiterhin zur Summe, aber ueber ihren Inhalt
  /// kann die App nichts sagen.
  linesUnresolved,
}

/// Woher die Taxpunkte einer Position stammen.
enum TaxpunkteSource {
  /// Aus der Referenzdatenbank — der sicherste Fall.
  catalog,

  /// Von der Rechnung selbst abgelesen und gegen den Betrag geprueft.
  invoice,

  /// Nicht bestimmbar.
  unresolved,
}

class ResolvedLine {
  final String code;
  final String description;
  final double amountChf;

  /// Taxpunkte aus der Referenz. Null, wenn der Code dort nicht steht.
  final double? referenceTaxpunkte;

  /// Die tatsaechlich verwendeten Taxpunkte — aus der Referenz oder von der
  /// Rechnung. Null, wenn die Position nicht aufgeschluesselt werden konnte.
  final double? taxpunkte;

  final TaxpunkteSource taxpunkteSource;

  /// Aus Betrag, Taxpunkten und Taxpunktwert zurueckgerechnete Anzahl.
  final int? quantity;

  const ResolvedLine({
    required this.code,
    required this.description,
    required this.amountChf,
    required this.taxpunkteSource,
    this.referenceTaxpunkte,
    this.taxpunkte,
    this.quantity,
  });

  /// Steht der Code in der Referenzdatenbank?
  bool get isKnownCode => referenceTaxpunkte != null;

  /// Konnte die Position in Taxpunkte und Anzahl zerlegt werden?
  bool get isResolved => quantity != null && taxpunkte != null;

  /// Was diese Position bei [taxpunktwert] und der ermittelten Anzahl kosten
  /// muesste.
  double? expectedAmount(double taxpunktwert) {
    final tp = taxpunkte;
    final qty = quantity;
    if (tp == null || qty == null) return null;
    return tp * taxpunktwert * qty;
  }
}

class ResolvedInvoice {
  final List<ResolvedLine> lines;

  /// Der ermittelte Faktor zwischen Taxpunkten und Franken.
  ///
  /// Vorsicht bei der Beschriftung: Fuer Privatpatienten sind die Taxpunkte
  /// selbst eine Spanne, aus der die Praxis waehlt, und erst darauf wirkt ihr
  /// Taxpunktwert. Was hier herauskommt, ist deshalb ein kombinierter Faktor
  /// und nicht zwingend der Taxpunktwert der Praxis.
  final double? taxpunktwert;

  /// Das auf der Rechnung ausgewiesene Total, falls gefunden.
  final double? statedTotal;

  final Set<ResolverWarning> warnings;

  const ResolvedInvoice({
    required this.lines,
    required this.warnings,
    this.taxpunktwert,
    this.statedTotal,
  });

  double get sumOfLines => lines.fold(0.0, (sum, l) => sum + l.amountChf);

  /// Stimmt die Summe der Positionen mit dem ausgewiesenen Total ueberein?
  /// Die wichtigste Vertrauensfrage: stimmt sie, wurde die Rechnung
  /// vollstaendig und richtig gelesen.
  bool get totalsMatch {
    final total = statedTotal;
    if (total == null) return false;
    return (sumOfLines - total).abs() <= 0.05;
  }

  /// Anteil der Positionen, deren Code in der Referenzdatenbank steht.
  double get codeCoverage {
    if (lines.isEmpty) return 0;
    return lines.where((l) => l.isKnownCode).length / lines.length;
  }

  /// Anteil der Positionen, die in Taxpunkte und Anzahl zerlegt werden
  /// konnten — unabhaengig davon, woher die Taxpunkte kamen.
  double get resolvedCoverage {
    if (lines.isEmpty) return 0;
    return lines.where((l) => l.isResolved).length / lines.length;
  }

  /// Taugt das Ergebnis als Grundlage fuer eine Aussage gegenueber dem
  /// Nutzer? Bewusst streng: lieber "konnte nicht sicher gelesen werden" als
  /// eine erfundene Abweichung.
  bool get isTrustworthy =>
      lines.isNotEmpty &&
      taxpunktwert != null &&
      totalsMatch &&
      resolvedCoverage == 1.0 &&
      !warnings.contains(ResolverWarning.taxpunktwertAmbiguous);
}

class InvoiceResolver {
  /// Suchbereich fuer den Faktor Taxpunkte -> Franken.
  ///
  /// Wichtig: Das ist die Grenze des **technisch Moeglichen**, nicht des
  /// rechtlich Zulaessigen. Der Tarif laesst hoechstens rund das 1.97-fache
  /// zu — wuerde hier bei diesem Wert abgeschnitten, koennte eine Rechnung
  /// oberhalb davon nie erkannt werden: sie waere schlicht "nicht lesbar"
  /// statt "ueber dem Hoechstsatz". Die Beurteilung macht deshalb
  /// logic/invoice_rules.dart, nicht der Resolver.
  ///
  /// Nach unten ist der Taxpunktwert frei; publizierte Preisspannen
  /// entsprechen einem Band ab rund 0.85, was als praktische Untergrenze
  /// dient. Weil der Bereich mehr als den Faktor 2 umfasst, passt zum halben
  /// Wert mit doppelten Mengen eine Rechnung rechnerisch genauso gut — siehe
  /// [ResolverWarning.taxpunktwertAmbiguous].
  final double minTaxpunktwert;
  final double maxTaxpunktwert;

  /// Wie weit die zurueckgerechnete Anzahl von einer ganzen Zahl abweichen
  /// darf (Rundung auf Rappen).
  final double quantityTolerance;

  /// Wie weit der zurueckgerechnete Betrag vom verrechneten abweichen darf.
  /// Diese Probe in Franken ist die schaerfere der beiden: sie verwirft
  /// Lesarten, die als Anzahl zwar aufgehen, aber den Betrag verfehlen.
  final double amountTolerance;

  /// Groesste Anzahl, die als plausibel gilt.
  final int maxQuantity;

  const InvoiceResolver({
    this.minTaxpunktwert = 0.85,
    this.maxTaxpunktwert = 3.00,
    this.quantityTolerance = 0.05,
    this.amountTolerance = 0.10,
    this.maxQuantity = 20,
  });

  ResolvedInvoice resolve(ParsedInvoice invoice, TariffCatalog catalog) {
    final warnings = <ResolverWarning>{};

    final raw = <_RawLine>[];
    for (final row in invoice.rows) {
      final amount = row.rightmostNumber?.best;
      if (amount == null) continue;
      final entry = catalog.lookup(row.code);
      if (entry == null) warnings.add(ResolverWarning.unknownTariffCodes);

      // Alle Zahlenfelder ausser dem Betrag kommen als Taxpunkte in Frage.
      // Welche Spalte welche ist, weiss die App nicht — das entscheidet die
      // Gegenprobe.
      final tpCandidates = <double>[];
      for (var i = 0; i < row.numbers.length - 1; i++) {
        tpCandidates.addAll(row.numbers[i].candidates);
      }

      raw.add(_RawLine(
        code: row.code,
        description: row.description,
        amount: amount,
        catalogTaxpunkte: entry?.taxpunkte,
        invoiceTaxpunkteCandidates: tpCandidates,
      ));
    }

    final search = _findTaxpunktwert(raw);
    final taxpunktwert = search?.displayValue;
    final rechenwert = search?.preciseValue;
    if (taxpunktwert == null && raw.isNotEmpty) {
      warnings.add(ResolverWarning.taxpunktwertNotFound);
    }
    if (search?.isAmbiguous ?? false) {
      warnings.add(ResolverWarning.taxpunktwertAmbiguous);
    }

    final lines = raw.map((l) {
      final fit = rechenwert == null ? null : _fitLine(l, rechenwert);
      return ResolvedLine(
        code: l.code,
        description: l.description,
        amountChf: l.amount,
        referenceTaxpunkte: l.catalogTaxpunkte,
        taxpunkte: fit?.taxpunkte,
        quantity: fit?.quantity,
        taxpunkteSource: fit?.source ?? TaxpunkteSource.unresolved,
      );
    }).toList();

    if (lines.any((l) => !l.isResolved)) {
      warnings.add(ResolverWarning.linesUnresolved);
    }

    final statedTotal = invoice.statedTotal?.best;
    if (statedTotal == null) {
      warnings.add(ResolverWarning.noStatedTotal);
    } else {
      final sum = lines.fold(0.0, (s, l) => s + l.amountChf);
      if ((sum - statedTotal).abs() > 0.05) {
        warnings.add(ResolverWarning.totalMismatch);
      }
    }

    return ResolvedInvoice(
      lines: lines,
      warnings: warnings,
      taxpunktwert: taxpunktwert,
      statedTotal: statedTotal,
    );
  }

  /// Sucht fuer eine Zeile die beste Zerlegung in Taxpunkte und Anzahl.
  ///
  /// Die Referenzdatenbank hat Vorrang. Fehlt der Code dort, werden alle
  /// Lesarten der Zahlenfelder durchprobiert; es gewinnt die mit der
  /// **kleinsten** Anzahl. Ohne diese Regel liesse sich derselbe Betrag auch
  /// als "ein Zehntel der Taxpunkte, zehnmal verrechnet" lesen.
  _LineFit? _fitLine(_RawLine line, double taxpunktwert) {
    final options = <(double, TaxpunkteSource)>[];
    final catalogTp = line.catalogTaxpunkte;
    if (catalogTp != null) {
      options.add((catalogTp, TaxpunkteSource.catalog));
    } else {
      for (final c in line.invoiceTaxpunkteCandidates) {
        options.add((c, TaxpunkteSource.invoice));
      }
    }

    _LineFit? best;
    for (final (tp, source) in options) {
      if (tp <= 0) continue;
      final exact = line.amount / (tp * taxpunktwert);
      final qty = exact.round();
      if (qty < 1 || qty > maxQuantity) continue;
      if ((exact - qty).abs() > quantityTolerance) continue;
      // Gegenprobe in Franken — verwirft Lesarten, die als Anzahl aufgehen,
      // den Betrag aber verfehlen.
      if ((tp * taxpunktwert * qty - line.amount).abs() > amountTolerance) continue;
      if (best == null || qty < best.quantity) {
        best = _LineFit(taxpunkte: tp, quantity: qty, source: source, deviation: (exact - qty).abs());
      }
    }
    return best;
  }

  /// Sucht den Faktor, bei dem moeglichst viele Positionen aufgehen.
  _TaxpunktwertSearch? _findTaxpunktwert(List<_RawLine> lines) {
    if (lines.isEmpty) return null;

    // Bevorzugt an den Positionen ausrichten, deren Taxpunkte aus der
    // Referenz stammen — die sind sicher. Nur wenn es keine gibt, werden die
    // von der Rechnung gelesenen herangezogen.
    final anchors = lines.where((l) => l.catalogTaxpunkte != null).toList();
    final basis = anchors.isNotEmpty ? anchors : lines;

    final candidates = <double>{};
    for (final line in basis) {
      for (final tp in line.possibleTaxpunkte) {
        if (tp <= 0) continue;
        for (var qty = 1; qty <= 4; qty++) {
          final candidate = line.amount / (tp * qty);
          if (candidate >= minTaxpunktwert && candidate <= maxTaxpunktwert) {
            candidates.add(candidate);
          }
        }
      }
    }
    if (candidates.isEmpty) return null;

    double? bestCandidate;
    var bestHits = 0;
    var bestDeviation = double.infinity;

    ({int hits, double deviation}) score(double candidate) {
      var hits = 0;
      var deviation = 0.0;
      for (final line in basis) {
        final fit = _fitLine(line, candidate);
        if (fit != null) {
          hits++;
          deviation += fit.deviation;
        } else {
          deviation += 1;
        }
      }
      return (hits: hits, deviation: deviation);
    }

    for (final candidate in candidates) {
      final s = score(candidate);
      if (s.hits > bestHits || (s.hits == bestHits && s.deviation < bestDeviation)) {
        bestCandidate = candidate;
        bestHits = s.hits;
        bestDeviation = s.deviation;
      }
    }
    if (bestCandidate == null || bestHits == 0) return null;

    // Die strukturelle Mehrdeutigkeit: Halbiert man den Faktor und verdoppelt
    // alle Mengen, passt die Rechnung rechnerisch immer genauso gut. Aus den
    // Betraegen allein ist das nicht zu entscheiden.
    //
    // Aufloesen laesst es sich ueber die Mengenspalte: Rechnungen drucken ihre
    // Anzahl mit. Stimmt eine zurueckgerechnete Menge mit einer Zahl ueberein,
    // die auf derselben Zeile steht, ist die konkurrierende Lesart widerlegt.
    // Ohne solche Bestaetigung bleibt es mehrdeutig — dann wird der GROESSERE
    // Faktor gewaehlt, weil er die kleineren Mengen ergibt: lieber eine
    // doppelte Verrechnung uebersehen als eine behaupten, die es nicht gibt.
    int corroboration(double candidate) {
      var count = 0;
      for (final line in lines) {
        final fit = _fitLine(line, candidate);
        if (fit == null) continue;
        final passtZurMengenspalte =
            line.otherNumbers.any((n) => (n - fit.quantity).abs() < 0.01);
        if (passtZurMengenspalte) count++;
      }
      return count;
    }

    final equallyGood = candidates.where((c) {
      final s = score(c);
      return s.hits == bestHits && s.deviation <= bestDeviation + 0.01;
    }).toList()
      ..sort((a, b) {
        final byCorroboration = corroboration(b).compareTo(corroboration(a));
        return byCorroboration != 0 ? byCorroboration : b.compareTo(a);
      });

    bestCandidate = equallyGood.first;
    final topCorroboration = corroboration(bestCandidate!);
    final ambiguous = equallyGood.any((c) =>
        (c - bestCandidate!).abs() / bestCandidate! > 0.1 &&
        corroboration(c) == topCorroboration);

    // Nachjustieren ueber alle Positionen, die aufgehen.
    var amountSum = 0.0;
    var taxpunkteSum = 0.0;
    for (final line in lines) {
      final fit = _fitLine(line, bestCandidate!);
      if (fit == null) continue;
      amountSum += line.amount;
      taxpunkteSum += fit.taxpunkte * fit.quantity;
    }

    final value = taxpunkteSum > 0 ? amountSum / taxpunkteSum : bestCandidate!;
    return _TaxpunktwertSearch(
      preciseValue: value,
      displayValue: double.parse(value.toStringAsFixed(2)),
      isAmbiguous: ambiguous,
    );
  }
}

class _LineFit {
  final double taxpunkte;
  final int quantity;
  final TaxpunkteSource source;
  final double deviation;
  const _LineFit({
    required this.taxpunkte,
    required this.quantity,
    required this.source,
    required this.deviation,
  });
}

class _TaxpunktwertSearch {
  /// Der ungerundete Wert. Damit wird gerechnet.
  ///
  /// Die Rundung auf zwei Stellen ist eine Anzeigefrage und hat im Rechenweg
  /// nichts verloren: Bei 122 Taxpunkten macht sie schon 12 Rappen aus, bei
  /// 286 Taxpunkten ueber einen Franken. Beides genug, um eine voellig
  /// korrekte Position an der Frankenprobe scheitern zu lassen.
  final double preciseValue;

  /// Der gerundete Wert fuer die Anzeige.
  final double displayValue;

  final bool isAmbiguous;

  const _TaxpunktwertSearch({
    required this.preciseValue,
    required this.displayValue,
    required this.isAmbiguous,
  });
}

class _RawLine {
  final String code;
  final String description;
  final double amount;
  final double? catalogTaxpunkte;
  final List<double> invoiceTaxpunkteCandidates;

  const _RawLine({
    required this.code,
    required this.description,
    required this.amount,
    required this.invoiceTaxpunkteCandidates,
    this.catalogTaxpunkte,
  });

  List<double> get possibleTaxpunkte =>
      catalogTaxpunkte != null ? [catalogTaxpunkte!] : invoiceTaxpunkteCandidates;

  /// Alle Zahlen der Zeile ausser dem Betrag — darunter die Mengenspalte.
  /// Dient als Gegenprobe, wenn der Faktor nicht eindeutig ist.
  List<double> get otherNumbers => invoiceTaxpunkteCandidates;
}

const invoiceResolver = InvoiceResolver();
