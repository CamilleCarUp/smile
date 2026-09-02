/// Benennt eine erfasste Rechnung nach dem, was auf ihr steht.
///
/// Ein Kamerabild heisst "IMG_20260216_101233.jpg". Wer nach drei Monaten in
/// den Verlauf schaut, erkennt daran nichts wieder. Rechnungsnummer und
/// Praxisname stehen im Briefkopf und sind genau das, wonach jemand sucht --
/// deshalb wird gleich bei der Erfassung danach benannt, nicht spaeter von
/// Hand.
///
/// Was nicht gelesen wurde, wird nicht erfunden: Fehlt die Nummer, traegt der
/// Name die Praxis und das Datum; fehlt beides, wenigstens das Datum.

/// Platzhalter, die der Verlauf setzt, wenn nichts zu lesen war. Sie taugen
/// nicht als Namensbestandteil.
const Set<String> _platzhalter = {'praxis nicht erkannt', 'unbekannt', ''};

/// In Dateinamen unzulaessige Zeichen, plus Steuerzeichen.
final RegExp _verboten = RegExp(r'[\\/:*?"<>|\x00-\x1f]');

/// Laenge, ab der ein Name unhandlich wird -- auch fuer Dateisysteme.
const int maxNamensLaenge = 80;

String? _brauchbar(String? wert) {
  if (wert == null) return null;
  final sauber = wert.replaceAll(_verboten, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (sauber.isEmpty) return null;
  if (_platzhalter.contains(sauber.toLowerCase())) return null;
  return sauber;
}

String _datum(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Der Name einer Rechnung: Nummer und Praxis, soweit gelesen.
///
///   beides      "112233 Dr. med. dent. Max Muster"
///   nur Nummer  "Rechnung 112233"
///   nur Praxis  "Dr. med. dent. Max Muster 16.02.2026"
///   nichts      "Rechnung vom 16.02.2026"
String rechnungsName({
  String? rechnungsnummer,
  String? praxis,
  DateTime? datum,
}) {
  final nummer = _brauchbar(rechnungsnummer);
  final name = _brauchbar(praxis);
  final tag = datum == null ? null : _datum(datum);

  final String ganz;
  if (nummer != null && name != null) {
    ganz = '$nummer $name';
  } else if (nummer != null) {
    ganz = 'Rechnung $nummer';
  } else if (name != null) {
    // Ohne Nummer traegt das Datum die Unterscheidung: Bei derselben Praxis
    // liegen sonst zwei gleich benannte Rechnungen im Verlauf.
    ganz = tag == null ? name : '$name $tag';
  } else {
    ganz = tag == null ? 'Rechnung' : 'Rechnung vom $tag';
  }

  return ganz.length <= maxNamensLaenge
      ? ganz
      : '${ganz.substring(0, maxNamensLaenge).trimRight()}…';
}

/// Der Name einer einzelnen Seite.
///
/// Die Endung des Originals bleibt erhalten -- eine Datei ohne Endung waere
/// auf dem Geraet nicht mehr zu oeffnen.
String seitenName({
  required String basis,
  required int seite,
  required int seiten,
  String? original,
}) {
  final endung = _endungVon(original);
  final mitSeite = seiten > 1 ? '$basis Seite $seite' : basis;
  return '$mitSeite$endung';
}

String _endungVon(String? original) {
  if (original == null) return '';
  final punkt = original.lastIndexOf('.');
  if (punkt <= 0 || punkt == original.length - 1) return '';
  final endung = original.substring(punkt);
  // Ein Punkt mitten im Namen ist keine Endung.
  return RegExp(r'^\.[A-Za-z0-9]{1,5}$').hasMatch(endung) ? endung.toLowerCase() : '';
}
