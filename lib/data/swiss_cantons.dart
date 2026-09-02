/// Die 26 Kantone.
///
/// Bewusst nur Kuerzel und Name: Fuer die Zuordnung zur Ombudsstelle reicht
/// der Kanton. Welcher es ist, kommt normalerweise aus der Rechnung -- die
/// Postleitzahl der Praxis, uebersetzt ueber das Amtliche
/// Ortschaftenverzeichnis (siehe lib/data/plz_verzeichnis.dart). Diese Liste
/// dient der Anzeige und dem freiwilligen Eintrag im Profil, der einspringt,
/// wenn auf der Rechnung keine Adresse zu lesen war.

class Canton {
  final String code;
  final String name;
  const Canton(this.code, this.name);
}

const List<Canton> swissCantons = [
  Canton('AG', 'Aargau'),
  Canton('AI', 'Appenzell Innerrhoden'),
  Canton('AR', 'Appenzell Ausserrhoden'),
  Canton('BE', 'Bern'),
  Canton('BL', 'Basel-Landschaft'),
  Canton('BS', 'Basel-Stadt'),
  Canton('FR', 'Freiburg'),
  Canton('GE', 'Genf'),
  Canton('GL', 'Glarus'),
  Canton('GR', 'Graubünden'),
  Canton('JU', 'Jura'),
  Canton('LU', 'Luzern'),
  Canton('NE', 'Neuenburg'),
  Canton('NW', 'Nidwalden'),
  Canton('OW', 'Obwalden'),
  Canton('SG', 'St. Gallen'),
  Canton('SH', 'Schaffhausen'),
  Canton('SO', 'Solothurn'),
  Canton('SZ', 'Schwyz'),
  Canton('TG', 'Thurgau'),
  Canton('TI', 'Tessin'),
  Canton('UR', 'Uri'),
  Canton('VD', 'Waadt'),
  Canton('VS', 'Wallis'),
  Canton('ZG', 'Zug'),
  Canton('ZH', 'Zürich'),
];

String? cantonName(String? code) {
  if (code == null || code.isEmpty) return null;
  for (final c in swissCantons) {
    if (c.code == code) return c.name;
  }
  return null;
}
