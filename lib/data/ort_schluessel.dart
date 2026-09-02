/// Normalform eines Ortsnamens.
///
/// Auf einer Rechnung steht "Zürich", "8004 Zürich 4" oder "St. Gallen"; im
/// Ortschaftenverzeichnis steht dasselbe anders geschrieben. Verglichen wird
/// deshalb nicht der Name, sondern sein Schluessel: Kleinbuchstaben, Umlaute
/// und Akzente aufgeloest, alles uebrige zu Leerzeichen.
///
///   'Zürich'            -> 'zurich'
///   'St. Gallen'        -> 'st gallen'
///   'La Chaux-de-Fonds' -> 'la chaux de fonds'
///   '8004 Zürich 4'     -> 'zurich'
///
/// Bewusst ohne Flutter-Abhaengigkeit: dasselbe Verfahren erzeugt die Tabelle
/// (tool/plz_kantone_erzeugen.dart) und liest sie in der App.
const Map<String, String> _ohneAkzent = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y', 'ç': 'c', 'ñ': 'n',
  'ß': 'ss', 'æ': 'ae', 'œ': 'oe',
};

String ortSchluessel(String ort) {
  final puffer = StringBuffer();
  for (final zeichen in ort.toLowerCase().split('')) {
    final ersatz = _ohneAkzent[zeichen];
    if (ersatz != null) {
      puffer.write(ersatz);
      continue;
    }
    final code = zeichen.codeUnitAt(0);
    // a-z bleibt, alles andere wird zum Trenner. Damit fallen auch die
    // Ziffern weg, mit denen manche Ortschaften gefuehrt werden
    // ("Lausanne 25").
    puffer.write(code >= 0x61 && code <= 0x7a ? zeichen : ' ');
  }
  return puffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}
