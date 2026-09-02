import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'ort_schluessel.dart';

/// Pfad der erzeugten Zuordnungstabelle.
const String plzVerzeichnisAsset = 'assets/reference-data/plz_kantone.csv';

/// Postleitzahl oder Ortsname -> Kantonskuerzel.
///
/// Datenquelle ist das Amtliche Ortschaftenverzeichnis von swisstopo
/// (ch.swisstopo-vd.ortschaftenverzeichnis_plz). swisstopo stellt monatlich
/// eine aktualisierte Fassung kostenlos zum Download bereit; die Datei im
/// Repository wird daraus mit `tool/plz_kantone_erzeugen.dart` gebaut. Anders
/// als beim Tarifkatalog steht der Nutzung nichts entgegen -- trotzdem liegt
/// im Repository nur die abgeleitete Tabelle, nicht der Originaldatensatz.
///
/// Zwei Arten von Eintraegen, unterschieden am ersten Feld:
///   `8005,ZH`     eine Postleitzahl
///   `zurich,ZH`   ein normalisierter Ortsname
///
/// Der Ortsname faengt die Postfach-Postleitzahlen auf. Das
/// Ortschaftenverzeichnis kennt sie nicht -- "3000 Bern" oder "1211 Genève"
/// stehen nicht darin, kommen auf Briefkoepfen aber vor.
class PlzVerzeichnis {
  final Map<String, String> _nachPlz;
  final Map<String, String> _nachOrt;

  const PlzVerzeichnis._(this._nachPlz, this._nachOrt);

  /// Das aktuell geladene Verzeichnis. Vor dem Laden leer, damit ein Aufruf
  /// vor `laden()` nichts Falsches behauptet.
  static PlzVerzeichnis aktuell = const PlzVerzeichnis._({}, {});

  static final RegExp _plzMuster = RegExp(r'^[1-9]\d{3}$');
  static final RegExp _kantonMuster = RegExp(r'^[A-Z]{2}$');

  factory PlzVerzeichnis.ausText(String csv) {
    final nachPlz = <String, String>{};
    final nachOrt = <String, String>{};
    for (final zeile in csv.split('\n')) {
      final t = zeile.trim();
      if (t.isEmpty || t.startsWith('#')) continue;
      final felder = t.split(',');
      if (felder.length < 2) continue;
      final schluessel = felder[0].trim();
      final kanton = felder[1].trim().toUpperCase();
      if (!_kantonMuster.hasMatch(kanton)) continue;
      if (_plzMuster.hasMatch(schluessel)) {
        nachPlz[schluessel] = kanton;
      } else {
        final ort = ortSchluessel(schluessel);
        if (ort.isNotEmpty) nachOrt[ort] = kanton;
      }
    }
    return PlzVerzeichnis._(nachPlz, nachOrt);
  }

  int get anzahlPlz => _nachPlz.length;
  int get anzahlOrte => _nachOrt.length;
  bool get istLeer => _nachPlz.isEmpty && _nachOrt.isEmpty;

  /// Der Kanton zu Postleitzahl und/oder Ort.
  ///
  /// Widersprechen sich die beiden, gibt es keine Antwort. Das passiert, wenn
  /// die Texterkennung eine Ziffer verdreht hat -- und eine Ombudsstelle im
  /// falschen Kanton ist schlechter als keine.
  String? kanton({String? plz, String? ort}) {
    final ausPlz = plz == null ? null : _nachPlz[plz.trim()];
    final ausOrt = ort == null ? null : _nachOrt[ortSchluessel(ort)];
    if (ausPlz != null && ausOrt != null && ausPlz != ausOrt) return null;
    return ausPlz ?? ausOrt;
  }

  /// Laedt die Tabelle beim Start. Scheitert das, bleibt es beim leeren
  /// Verzeichnis -- die App startet auch ohne.
  static Future<void> laden({AssetBundle? bundle}) async {
    try {
      final text = await (bundle ?? rootBundle).loadString(plzVerzeichnisAsset);
      aktuell = PlzVerzeichnis.ausText(text);
    } catch (_) {
      aktuell = const PlzVerzeichnis._({}, {});
    }
  }
}
