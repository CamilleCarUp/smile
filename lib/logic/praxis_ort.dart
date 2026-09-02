/// Postleitzahl und Ort der Praxis, gelesen aus dem Briefkopf der Rechnung.
///
/// Bewusst ein eigenes Modul: Die Adresse des Patienten steht auf derselben
/// Seite, und eine Suche ueber die ganze Rechnung wuerde frueher oder spaeter
/// den Wohnort des Patienten erwischen. Gefuettert wird das hier deshalb nur
/// mit dem Adressblock, den der Parser der Praxis zuordnet.
class PraxisOrt {
  final String plz;
  final String ort;

  const PraxisOrt(this.plz, this.ort);

  /// Vier Ziffern, nicht Teil einer laengeren Zahl. 0xxx gibt es in der
  /// Schweiz nicht, das schliesst Betraege wie "0900" aus.
  static final RegExp _plz = RegExp(r'(?<!\d)([1-9]\d{3})(?!\d)');

  /// Ein Wort, das noch zum Ortsnamen gehoeren kann: "St.", "Gallen",
  /// "Chaux-de-Fonds", "Zuerich-Oerlikon".
  static final RegExp _ortswort =
      RegExp(r"^[A-Za-zÄÖÜäöüÀ-ÿ][A-Za-zÄÖÜäöüÀ-ÿ.'’/-]*$");

  /// Woerter, bei denen der Ortsname sicher zu Ende ist. Manche Briefkoepfe
  /// setzen Telefon und Ort auf dieselbe Zeile.
  static final RegExp _schluss = RegExp(
      r'^(tel|telefon|fon|fax|mail|e-?mail|web|www|ch|schweiz|suisse|postfach|mwst|uid|iban)\b',
      caseSensitive: false);

  /// Sucht in einer zusammengesetzten Adresse ("Alte Gasse 13, 8005 Zürich")
  /// nach Postleitzahl und Ort. Gibt null zurueck, wenn nichts Belastbares
  /// dasteht -- ein geratener Ort waere schlimmer als keiner, weil daran die
  /// Ombudsstelle haengt.
  static PraxisOrt? ausAdresse(String? adresse) {
    if (adresse == null || adresse.trim().isEmpty) return null;
    final segmente = adresse.split(RegExp(r'[,;|\n]'));

    for (var i = 0; i < segmente.length; i++) {
      final treffer = _plz.firstMatch(segmente[i]);
      if (treffer == null) continue;

      // Der Ort steht hinter der Postleitzahl -- oder, wenn die Zeile dort
      // endet, im naechsten Abschnitt.
      var ort = _ortAus(segmente[i].substring(treffer.end));
      if (ort == null && i + 1 < segmente.length) {
        ort = _ortAus(segmente[i + 1]);
      }
      if (ort == null) continue;

      return PraxisOrt(treffer.group(1)!, ort);
    }
    return null;
  }

  static String? _ortAus(String rest) {
    final woerter = <String>[];
    for (final wort in rest.trim().split(RegExp(r'\s+'))) {
      if (wort.isEmpty) break;
      if (_schluss.hasMatch(wort)) break;
      if (!_ortswort.hasMatch(wort)) break;
      woerter.add(wort);
      if (woerter.length == 4) break;
    }
    if (woerter.isEmpty) return null;

    // Ein einzelner Buchstabe ist kein Ort, sondern ein Rest der Erkennung.
    final name = woerter.join(' ').replaceAll(RegExp(r'[\s.,-]+$'), '');
    return name.length >= 2 ? name : null;
  }

  @override
  String toString() => '$plz $ort';

  @override
  bool operator ==(Object other) =>
      other is PraxisOrt && other.plz == plz && other.ort == ort;

  @override
  int get hashCode => Object.hash(plz, ort);
}
