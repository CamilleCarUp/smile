import '../data/tariff_catalog.dart';
import '../models/finding.dart';
import '../models/request.dart';
import 'behandlung.dart';

/// Die Regeln, die erst mit dem vollstaendigen Tarif pruefbar werden.
///
/// Anders als Regel 1, die aus Betraegen und Referenz-Taxpunkten ein
/// Preisniveau herleitet, pruefen diese Regeln **ausformulierte Vorschriften**
/// des Tarifs: die Obergrenze je Position, Mengenbeschraenkungen je Sitzung
/// oder Zeitraum, und Kumulationsverbote. Das sind keine Erwartungswerte,
/// sondern Saetze, die im Katalog stehen -- ein Befund kann sie deshalb
/// woertlich zitieren.
///
/// **Ohne vollstaendigen Katalog prueft hier nichts.** Der mitgelieferte Seed
/// enthaelt nur Taxpunkte; dann bleibt es bei Regel 1. Lieber keine Aussage
/// als eine auf leeren Daten.
///
/// Der Verlauf ist der eigentliche Vorteil dieser App: Die Rechnungen eines
/// Menschen liegen auf seinem Geraet. "Darf innerhalb von 12 Monaten in der
/// gleichen Praxis nur einmal verrechnet werden" kann sonst niemand pruefen --
/// keine Praxissoftware, kein Versicherer.
class TarifRegeln {
  /// Spielraum, bevor ein Befund erhoben wird. Deckt Rundungen auf der
  /// Rechnung und in unserer eigenen Rueckrechnung ab.
  final double sicherheitsmarge;

  const TarifRegeln({this.sicherheitsmarge = 1.03});

  List<InvoiceFinding> pruefe({
    required List<TariffLine> lines,
    required TariffCatalog katalog,
    required bool vertrauenswuerdig,
    double? faktor,
    DateTime? rechnungsdatum,
    String? praxis,
    List<DentalRequest> verlauf = const [],
  }) {
    // Dieselben Vorbedingungen wie bei Regel 1: Wurde die Rechnung nicht
    // belastbar gelesen, ist jede Mengenaussage darueber wertlos.
    if (!vertrauenswuerdig) return const [];
    if (!katalog.istVollstaendig) return const [];

    return [
      ..._preisJePosition(lines, katalog, faktor),
      ..._mengeJeSitzung(lines, katalog),
      ..._kumulationsverbote(lines, katalog),
      ..._wiederholungInnertFrist(
          lines, katalog, rechnungsdatum, praxis, verlauf),
    ];
  }

  /// Jede Position gegen ihre eigene Obergrenze.
  ///
  /// Gerechnet wird aus Betrag, Menge und Faktor zurueck, nicht aus den
  /// Taxpunkten der Zeile: Stammen die aus dem Katalog, koennten sie die
  /// Obergrenze gar nicht ueberschreiten -- der Vergleich waere ein Zirkel.
  List<InvoiceFinding> _preisJePosition(
      List<TariffLine> lines, TariffCatalog katalog, double? faktor) {
    if (faktor == null || faktor <= 0) return const [];
    final findings = <InvoiceFinding>[];

    for (final line in lines) {
      final eintrag = katalog.lookup(line.code);
      final max = eintrag?.ppMax;
      final menge = line.quantity;
      if (max == null || menge == null || menge <= 0) continue;

      final tpEffektiv = line.amountChf / (menge * faktor);
      if (tpEffektiv <= max * sicherheitsmarge) continue;

      final zulaessig = max * menge * faktor;
      findings.add(InvoiceFinding(
        kind: FindingKind.positionAboveMaximum,
        title: '${line.description.isEmpty ? line.code : line.description}: '
            'über dem Höchstsatz',
        explanation:
            'Für diese Position lässt der Tarif bei Privatpatienten höchstens '
            '${max.toStringAsFixed(1)} Taxpunkte zu. Aus Betrag, Anzahl und dem '
            'Taxpunktwert dieser Rechnung ergeben sich '
            '${tpEffektiv.toStringAsFixed(1)}. Zum Höchstsatz läge die Position bei '
            'rund CHF ${zulaessig.toStringAsFixed(2)} statt '
            'CHF ${line.amountChf.toStringAsFixed(2)}.',
        observed: tpEffektiv,
        allowed: max,
        excessChf: line.amountChf - zulaessig,
      ));
    }
    return findings;
  }

  /// "Maximal N mal pro Sitzung verrechenbar."
  List<InvoiceFinding> _mengeJeSitzung(
      List<TariffLine> lines, TariffCatalog katalog) {
    final findings = <InvoiceFinding>[];

    for (final sitzung in sitzungen(lines)) {
      final proCode = <String, int>{};
      for (final line in sitzung.positionen) {
        final menge = line.quantity;
        if (menge == null) continue;
        proCode[line.code] = (proCode[line.code] ?? 0) + menge;
      }

      proCode.forEach((code, anzahl) {
        final eintrag = katalog.lookup(code);
        if (eintrag == null) return;
        for (final limit in eintrag.limitationen.where((l) => l.jeSitzung)) {
          if (anzahl <= limit.maxAnzahl) continue;
          findings.add(InvoiceFinding(
            kind: FindingKind.quantityAboveLimit,
            title: '${eintrag.description}: $anzahl mal verrechnet',
            explanation: 'Der Tarif hält zu dieser Position fest: '
                '«${limit.wortlaut}»'
                '${sitzung.datum == null ? '' : ' Auf dieser Rechnung steht sie für den '
                    '${_tag(sitzung.datum!)} $anzahl mal.'}',
            observed: anzahl.toDouble(),
            allowed: limit.maxAnzahl.toDouble(),
          ));
        }
      });
    }
    return findings;
  }

  /// "Leistung X ist nicht kumulierbar mit Leistung Y."
  List<InvoiceFinding> _kumulationsverbote(
      List<TariffLine> lines, TariffCatalog katalog) {
    final findings = <InvoiceFinding>[];
    final gemeldet = <String>{};

    for (final sitzung in sitzungen(lines)) {
      final codes = sitzung.positionen.map((l) => l.code).toSet();
      for (final code in codes) {
        final eintrag = katalog.lookup(code);
        if (eintrag == null) continue;
        for (final anderer in eintrag.nichtKumulierbarMit) {
          if (!codes.contains(anderer)) continue;
          // Das Verbot steht in beiden Eintraegen -- nur einmal melden.
          final paar = ([code, anderer]..sort()).join('+');
          if (!gemeldet.add(paar)) continue;

          final zweiter = katalog.lookup(anderer);
          findings.add(InvoiceFinding(
            kind: FindingKind.notCumulable,
            title: 'Zwei Positionen, die sich ausschliessen',
            explanation:
                '«${eintrag.description}» und «${zweiter?.description ?? anderer}» '
                'stehen zusammen auf dieser Rechnung'
                '${sitzung.datum == null ? '' : ' für den ${_tag(sitzung.datum!)}'}. '
                'Der Tarif lässt sie nicht zusammen zu.',
          ));
        }
      }
    }
    return findings;
  }

  /// "Darf innerhalb von 12 Monaten in der gleichen Praxis nur 1 mal
  /// verrechnet werden."
  ///
  /// Das ist die Regel, die nur diese App pruefen kann.
  List<InvoiceFinding> _wiederholungInnertFrist(
    List<TariffLine> lines,
    TariffCatalog katalog,
    DateTime? rechnungsdatum,
    String? praxis,
    List<DentalRequest> verlauf,
  ) {
    if (rechnungsdatum == null) return const [];
    final findings = <InvoiceFinding>[];

    for (final code in lines.map((l) => l.code).toSet()) {
      final eintrag = katalog.lookup(code);
      if (eintrag == null) continue;

      for (final limit in eintrag.limitationen.where((l) => !l.jeSitzung)) {
        final ab = rechnungsdatum.subtract(limit.zeitraum!);

        var frueher = 0;
        DateTime? letzte;
        for (final alt in verlauf) {
          if (limit.gleichePraxis &&
              praxis != null &&
              alt.dentistName.trim().toLowerCase() != praxis.trim().toLowerCase()) {
            continue;
          }
          for (final line in alt.lines.where((l) => l.code == code)) {
            final wann = line.date ?? alt.date;
            if (wann.isBefore(ab) || wann.isAfter(rechnungsdatum)) continue;
            frueher += line.quantity ?? 1;
            if (letzte == null || wann.isAfter(letzte)) letzte = wann;
          }
        }
        if (frueher == 0) continue;

        final jetzt = lines
            .where((l) => l.code == code)
            .fold<int>(0, (s, l) => s + (l.quantity ?? 1));
        if (frueher + jetzt <= limit.maxAnzahl) continue;

        findings.add(InvoiceFinding(
          kind: FindingKind.repeatedWithinPeriod,
          title: '${eintrag.description}: schon einmal verrechnet',
          explanation: 'Der Tarif hält fest: «${limit.wortlaut}» '
              'In deinem Verlauf steht dieselbe Position bereits vom '
              '${_tag(letzte!)}. Smile sieht das, weil deine Rechnungen auf '
              'diesem Gerät liegen — der Praxis ist es womöglich entgangen.',
          observed: (frueher + jetzt).toDouble(),
          allowed: limit.maxAnzahl.toDouble(),
        ));
      }
    }
    return findings;
  }

  static String _tag(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

const TarifRegeln tarifRegeln = TarifRegeln();
