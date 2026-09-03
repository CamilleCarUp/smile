import '../models/finding.dart';
import 'invoice_resolver.dart';

/// Beurteilt eine gelesene Rechnung.
///
/// Strikte Trennung zum Resolver: Der stellt fest, *was* auf der Rechnung
/// steht. Hier wird entschieden, *ob* daran etwas zu beanstanden ist. Der
/// Resolver darf deshalb auch Preisniveaus errechnen, die der Tarif gar nicht
/// zulaesst — sonst koennte genau der Fall nie erkannt werden, den diese
/// Regeln suchen.
///
/// Grundsatz: Die beiden Fehler sind nicht gleich teuer. Eine uebersehene
/// Doppelverrechnung kostet den Nutzer ein paar Franken. Ein Fehlalarm schickt
/// ihn mit einem unbegruendeten Vorwurf zu seinem Zahnarzt — das kostet ihn
/// eine peinliche Situation, die Praxis Zeit und die App ihre Glaubwuerdigkeit.
/// Im Zweifel wird deshalb nichts behauptet.
class InvoiceRules {
  /// Obergrenze der Taxpunkte fuer Privatpatienten, relativ zum mittleren
  /// Wert. Der amtliche Katalog weist zu jeder Position `TP (PP) max` aus;
  /// ueber alle geprueften Positionen liegt dieser bei rund dem 1.15-fachen.
  /// Aufgerundet auf 1.16, damit Rundungen nicht zu Fehlalarmen fuehren.
  static const double taxpunkteMaxAufschlag = 1.16;

  /// Hoechster Taxpunktwert fuer Privatpatienten (SSO).
  static const double taxpunktwertMax = 1.70;

  /// Groesster Faktor zwischen Taxpunkten und Franken, den der Tarif zulaesst.
  static const double maxErlaubterFaktor = taxpunkteMaxAufschlag * taxpunktwertMax;

  /// Zusaetzlicher Spielraum, bevor ein Befund erhoben wird. Deckt Rundungen
  /// auf der Rechnung und in unserer eigenen Berechnung ab.
  final double sicherheitsmarge;

  const InvoiceRules({this.sicherheitsmarge = 1.03});

  double get befundSchwelle => maxErlaubterFaktor * sicherheitsmarge;

  /// Prueft eine aufgeloeste Rechnung.
  ///
  /// Vorbedingungen, ohne die gar nichts behauptet wird:
  ///   * Die Summenprobe muss aufgehen — sonst ist offen, ob die Rechnung
  ///     ueberhaupt vollstaendig gelesen wurde.
  ///   * Der Faktor muss eindeutig sein. Ist er mehrdeutig, koennte derselbe
  ///     Betrag auch mit halbem Faktor und doppelten Mengen zustande kommen.
  ///   * Mindestens eine Position muss ihre Taxpunkte aus der
  ///     Referenzdatenbank haben. Taxpunkte, die von derselben Rechnung
  ///     abgelesen wurden, koennen ihr Preisniveau nicht bewerten — das waere
  ///     ein Zirkelschluss.
  List<InvoiceFinding> evaluate(ResolvedInvoice invoice) {
    final findings = <InvoiceFinding>[];

    final faktor = invoice.taxpunktwert;
    if (faktor == null) return findings;
    if (!invoice.totalsMatch) return findings;
    if (invoice.warnings.contains(ResolverWarning.taxpunktwertAmbiguous)) return findings;

    final ausReferenz = invoice.lines
        .where((l) => l.taxpunkteSource == TaxpunkteSource.catalog && l.isResolved)
        .toList();
    if (ausReferenz.isEmpty) return findings;

    // --- Regel 1: Preisniveau ueber dem tariflichen Hoechstsatz ------------
    if (faktor > befundSchwelle) {
      final zulaessigeSumme = invoice.sumOfLines * (maxErlaubterFaktor / faktor);
      findings.add(InvoiceFinding(
        kind: FindingKind.factorAboveTariffMaximum,
        title: 'Preisniveau über dem tariflichen Höchstsatz',
        explanation:
            'Aus den Beträgen und den amtlichen Taxpunkten ergibt sich ein Faktor von '
            '${faktor.toStringAsFixed(2)} Franken je Taxpunkt. Der Tarif lässt für '
            'Privatpatienten höchstens ${maxErlaubterFaktor.toStringAsFixed(2)} zu '
            '(Taxpunkte höchstens ${taxpunkteMaxAufschlag.toStringAsFixed(2)}-fach, '
            'Taxpunktwert höchstens ${taxpunktwertMax.toStringAsFixed(2)}). '
            'Bei ${maxErlaubterFaktor.toStringAsFixed(2)} läge die Rechnung bei rund '
            'CHF ${zulaessigeSumme.toStringAsFixed(2)} statt '
            'CHF ${invoice.sumOfLines.toStringAsFixed(2)}.',
        frage: 'Aus den verrechneten Beträgen und den amtlichen Taxpunkten ergibt '
            'sich ein Faktor von ${faktor.toStringAsFixed(2)} Franken je Taxpunkt. '
            'Nach meinem Verständnis lässt der Tarif für Privatpatienten höchstens '
            '${maxErlaubterFaktor.toStringAsFixed(2)} zu (Taxpunkte höchstens '
            '${taxpunkteMaxAufschlag.toStringAsFixed(2)}-fach, Taxpunktwert höchstens '
            '${taxpunktwertMax.toStringAsFixed(2)}).',
        observed: faktor,
        allowed: maxErlaubterFaktor,
        excessChf: invoice.sumOfLines - zulaessigeSumme,
      ));
    }

    // --- Regel 2: Menge über dem Behandlungsmuster -------------------------
    // NOCH NICHT GEBAUT, und das ist Absicht.
    //
    // Der Fall aus der Thesis: Infiltrationsanaesthesie zweimal bei einer
    // einflaechigen Fuellung. Der Resolver erkennt die Menge 2 bereits
    // zuverlaessig -- was fehlt, sind die ERWARTETEN Mengen je
    // Behandlungsmuster. Die Referenzdatei listet Codes, aber keine Mengen.
    //
    // Diese Zahlen duerfen nicht geschaetzt werden. Sie muessen aus der
    // Thesis oder von zahnmedizinischer Seite kommen. Bis dahin bleibt die
    // Regel ungebaut: lieber keine Aussage als eine, die niemand verantwortet.
    //
    // Voraussetzung: geklaerte Nutzungsrechte am Tarif (siehe
    // docs/tarifdaten.md) und erwartete Mengen je Muster.

    return findings;
  }
}

const invoiceRules = InvoiceRules();
