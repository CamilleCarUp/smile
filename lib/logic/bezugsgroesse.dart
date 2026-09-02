import '../models/request.dart';

/// Worauf sich die Menge einer Position bezieht.
///
/// Der Tarif haengt an jede Position eine Bezugsgroesse: pro Zahn, pro
/// Flaeche, pro Kanal, pro Sextant, pro Sitzung, pro Zeiteinheit. Sie ist die
/// eigentliche Mengenregel -- "Anzahl 6" heisst bei einer Position pro
/// Sitzung etwas voellig anderes als bei einer pro 5 Minuten.
///
/// Gelesen wird sie hier aus dem Text der Rechnung selbst, nicht aus einem
/// Katalog. Das ist Absicht: Die Rechnung gehoert dem Nutzer, und an ihrem
/// Text haengt keine Nutzungsbeschraenkung. Was die Praxis nicht ausdruckt,
/// bleibt eben unbekannt -- lieber eine Luecke als eine Behauptung.
enum Bezugsgroesse { sitzung, kiefer, quadrant, sextant, zahn, kanal, flaeche, zeit, unbekannt }

class Bezugsangabe {
  final Bezugsgroesse art;

  /// Minuten je Einheit, nur bei [Bezugsgroesse.zeit].
  final int? minuten;

  /// Anzahl Flaechen, nur bei [Bezugsgroesse.flaeche] und nur, wenn sie
  /// dasteht ("einflächig", "3-fl."). "mehrflächig" laesst sie offen.
  final int? flaechen;

  const Bezugsangabe(this.art, {this.minuten, this.flaechen});

  static const unbekannt = Bezugsangabe(Bezugsgroesse.unbekannt);

  bool get istBekannt => art != Bezugsgroesse.unbekannt;

  @override
  bool operator ==(Object other) =>
      other is Bezugsangabe &&
      other.art == art &&
      other.minuten == minuten &&
      other.flaechen == flaechen;

  @override
  int get hashCode => Object.hash(art, minuten, flaechen);

  @override
  String toString() => 'Bezugsangabe(${art.name}, min: $minuten, fl: $flaechen)';
}

// Die Texterkennung verwechselt in "Min." gern i mit l oder 1, deshalb die
// nachsichtige Schreibweise.
final RegExp _zeit = RegExp(r'(?:pro|je)\s*(\d{1,3})\s*m[il1]n', caseSensitive: false);
final RegExp _flaechenZahl = RegExp(r'(\d)\s*-?\s*fl\b', caseSensitive: false);

const Map<String, int> _flaechenWort = {
  'einfläch': 1,
  'einflaech': 1,
  'zweifläch': 2,
  'zweiflaech': 2,
  'dreifläch': 3,
  'dreiflaech': 3,
  'vierfläch': 4,
  'vierflaech': 4,
};

/// Liest die Bezugsgroesse aus dem Text einer Rechnungszeile.
Bezugsangabe bezugAus(String beschreibung) {
  final text = beschreibung.toLowerCase();

  final zeit = _zeit.firstMatch(text);
  if (zeit != null) {
    final minuten = int.tryParse(zeit.group(1)!);
    if (minuten != null && minuten > 0) {
      return Bezugsangabe(Bezugsgroesse.zeit, minuten: minuten);
    }
  }

  for (final eintrag in _flaechenWort.entries) {
    if (text.contains(eintrag.key)) {
      return Bezugsangabe(Bezugsgroesse.flaeche, flaechen: eintrag.value);
    }
  }
  if (text.contains('mehrfläch') || text.contains('mehrflaech')) {
    return const Bezugsangabe(Bezugsgroesse.flaeche);
  }
  final flaechen = _flaechenZahl.firstMatch(text);
  if (flaechen != null) {
    return Bezugsangabe(Bezugsgroesse.flaeche,
        flaechen: int.tryParse(flaechen.group(1)!));
  }

  if (text.contains('sitzung')) return const Bezugsangabe(Bezugsgroesse.sitzung);
  if (text.contains('quadrant')) return const Bezugsangabe(Bezugsgroesse.quadrant);
  if (text.contains('sextant')) return const Bezugsangabe(Bezugsgroesse.sextant);
  if (text.contains('kiefer')) return const Bezugsangabe(Bezugsgroesse.kiefer);
  if (text.contains('kanal') || text.contains('kanäle')) {
    return const Bezugsangabe(Bezugsgroesse.kanal);
  }
  // "pro Zahn" -- nicht blosses "zahn", das steckt in "Zahnstein",
  // "Zahnreinigung" und einem halben Dutzend weiterer Bezeichnungen.
  if (RegExp(r'\bpro\s+zahn\b').hasMatch(text)) {
    return const Bezugsangabe(Bezugsgroesse.zahn);
  }

  return Bezugsangabe.unbekannt;
}

/// Wieviel Behandlungszeit die Rechnung verrechnet.
///
/// Die Zeitpositionen sagen es selbst: Anzahl mal Minuten je Einheit. Das ist
/// keine Schaetzung und kein Muster, sondern eine Addition -- und der Nutzer
/// ist der Einzige, der weiss, wie lange er tatsaechlich im Stuhl sass.
/// Deshalb wird hier gerechnet und nicht beurteilt.
class Zeitabrechnung {
  final Duration gesamt;

  /// Zeilen, die zur Summe beigetragen haben.
  final List<TariffLine> zeilen;

  /// Falsch, wenn eine Zeitzeile ohne Menge dabei war. Dann ist die Summe zu
  /// klein -- und eine zu kleine Zahl waere hier schlimmer als gar keine,
  /// weil sie nach einer harmlosen Rechnung aussaehe.
  final bool istVollstaendig;

  const Zeitabrechnung(this.gesamt, this.zeilen, {this.istVollstaendig = true});

  bool get istLeer => zeilen.isEmpty;

  static Zeitabrechnung aus(List<TariffLine> lines) {
    var minuten = 0;
    var vollstaendig = true;
    final beteiligt = <TariffLine>[];
    for (final line in lines) {
      final bezug = bezugAus(line.description);
      if (bezug.art != Bezugsgroesse.zeit || bezug.minuten == null) continue;
      final menge = line.quantity;
      if (menge == null || menge <= 0) {
        vollstaendig = false;
        continue;
      }
      minuten += bezug.minuten! * menge;
      beteiligt.add(line);
    }
    return Zeitabrechnung(Duration(minutes: minuten), beteiligt,
        istVollstaendig: vollstaendig);
  }

  String get alsText {
    final stunden = gesamt.inHours;
    final rest = gesamt.inMinutes % 60;
    if (stunden == 0) return '$rest Minuten';
    if (rest == 0) return stunden == 1 ? '1 Stunde' : '$stunden Stunden';
    return '$stunden ${stunden == 1 ? "Stunde" : "Stunden"} $rest Minuten';
  }
}

/// Wer laut Rechnung behandelt hat.
///
/// Der Tarif fuehrt dieselbe Leistung unter verschiedenen Nummern, je nach
/// Qualifikation -- und die teurere zu verrechnen ist der haeufigste
/// dokumentierte Griff daneben. Die App sieht nur, was verrechnet wurde; wer
/// tatsaechlich am Stuhl stand, weiss allein der Nutzer.
enum Behandlungsqualifikation { zahnarzt, dentalhygienikerin, prophylaxeassistentin, unbekannt }

Behandlungsqualifikation qualifikationAus(String beschreibung) {
  final text = beschreibung.toLowerCase();
  if (RegExp(r'\bdh\b|dentalhygien').hasMatch(text)) {
    return Behandlungsqualifikation.dentalhygienikerin;
  }
  if (RegExp(r'\bpa\b|prophylaxeassist').hasMatch(text)) {
    return Behandlungsqualifikation.prophylaxeassistentin;
  }
  return Behandlungsqualifikation.unbekannt;
}
