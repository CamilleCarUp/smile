import '../models/ocr_result.dart';

/// Teilt erfasste Seiten in einzelne Rechnungen auf.
///
/// Ein PDF aus der Praxis enthaelt oft mehrere Rechnungen -- oder jemand
/// fotografiert zwei Belege hintereinander. Ohne Trennung addiert die App
/// fremde Totale zu einer Summe, die es nie gab. Das waere schlimmer als jede
/// unsichere Lesung: Es sieht richtig aus.
///
/// Die Regel, nach Verlaesslichkeit:
///   1. Referenznummer je Seite. Aendert sie sich, beginnt eine neue Rechnung.
///   2. Seitenzaehler ("Seite: 1/2"). Steht er auf 1, beginnt eine neue; steht
///      er hoeher, ist die Seite eine Fortsetzung.
///   3. Weder noch: zusammenlassen.
///
/// Im Zweifel wird **nicht** getrennt. Eine faelschlich zerrissene Rechnung
/// faellt bei der Summenprobe auf und wird als unsicher gemeldet; eine
/// faelschlich zusammengefasste ergibt vier addierte Totale, die niemand als
/// falsch erkennt.
///
/// Bewusst vor dem Parser und unabhaengig von ihm: Hier werden nur Seiten
/// gruppiert, nicht gelesen.
class Rechnungsseite {
  final OcrPage seite;

  /// Referenz- oder Rechnungsnummer, falls auf der Seite zu finden.
  final String? referenz;

  /// "Seite: 2/3" -> nummer 2, von 3.
  final int? nummer;
  final int? von;

  const Rechnungsseite({required this.seite, this.referenz, this.nummer, this.von});
}

class Rechnungsgruppe {
  final List<OcrPage> seiten;

  /// Referenznummer der Rechnung, sofern auf einer ihrer Seiten gelesen.
  final String? referenz;

  const Rechnungsgruppe({required this.seiten, this.referenz});
}

class RechnungsTrenner {
  const RechnungsTrenner();

  /// Etiketten, hinter denen die Nummer der Rechnung steht. Je nach
  /// Praxissoftware anders benannt.
  /// Nach dem Etikett folgt irgendeine Schreibweise von "Nummer" -- die
  /// Texterkennung liest daraus auch schon mal "Referenznumner".
  static final RegExp _referenzEtikett =
      RegExp(r'^(referenz|rechnungs|beleg)\s*-?\s*n', caseSensitive: false);
  static final RegExp _seitenEtikett = RegExp(r'^seite\b', caseSensitive: false);

  /// Eine Nummer besteht aus Ziffern und darf getrennt sein ("28 358").
  static final RegExp _nummernWert = RegExp(r'^[\d\s./-]{3,}$');
  static final RegExp _seitenWert = RegExp(r'(\d{1,2})\s*/\s*(\d{1,2})');

  List<Rechnungsgruppe> trennen(List<OcrPage> seiten) {
    if (seiten.isEmpty) return const [];

    final gruppen = <List<OcrPage>>[];
    final referenzen = <String?>[];

    for (final seite in seiten) {
      final m = merkmale(seite);
      final beginntNeu = gruppen.isEmpty || _beginntNeu(m, referenzen.last);

      if (beginntNeu) {
        gruppen.add([seite]);
        referenzen.add(m.referenz);
      } else {
        gruppen.last.add(seite);
        // Steht die Nummer erst auf einer Folgeseite, gilt sie fuer die
        // ganze Gruppe.
        if (referenzen.last == null && m.referenz != null) {
          referenzen[referenzen.length - 1] = m.referenz;
        }
      }
    }

    return [
      for (var i = 0; i < gruppen.length; i++)
        Rechnungsgruppe(seiten: gruppen[i], referenz: referenzen[i]),
    ];
  }

  bool _beginntNeu(Rechnungsseite m, String? laufendeReferenz) {
    // Beide Nummern gelesen: Sie entscheiden allein.
    if (m.referenz != null && laufendeReferenz != null) {
      return m.referenz != laufendeReferenz;
    }
    // Sonst der Seitenzaehler. "1" heisst Anfang, alles darueber Fortsetzung.
    if (m.nummer != null) return m.nummer == 1;
    // Kein Signal: zusammenlassen.
    return false;
  }

  /// Was sich einer einzelnen Seite ohne Auswertung entnehmen laesst.
  Rechnungsseite merkmale(OcrPage seite) {
    String? referenz;
    int? nummer;
    int? von;

    for (final zeile in seite.lines) {
      final text = zeile.text.trim();

      if (referenz == null && _referenzEtikett.hasMatch(text)) {
        referenz = _wertZu(zeile, seite, _nummernWert)?.replaceAll(RegExp(r'\s'), '');
      }

      if (nummer == null && _seitenEtikett.hasMatch(text)) {
        final treffer = _seitenWert.firstMatch(text) ??
            _seitenWert.firstMatch(_wertZu(zeile, seite, _seitenWert) ?? '');
        if (treffer != null) {
          nummer = int.tryParse(treffer.group(1)!);
          von = int.tryParse(treffer.group(2)!);
        }
      }
    }

    return Rechnungsseite(seite: seite, referenz: referenz, nummer: nummer, von: von);
  }

  /// Der Wert zu einem Etikett: hinter dem Doppelpunkt in derselben Zelle,
  /// sonst in der naechsten Zelle rechts auf derselben Zeilenhoehe.
  String? _wertZu(OcrTextLine etikett, OcrPage seite, RegExp form) {
    final rest = etikett.text.split(':').skip(1).join(':').trim();
    if (rest.isNotEmpty && form.hasMatch(rest)) return rest;

    OcrTextLine? naechste;
    for (final andere in seite.lines) {
      if (identical(andere, etikett)) continue;
      if (andere.box.left < etikett.box.right) continue;
      if (!andere.box.sharesRowWith(etikett.box, tolerance: 4)) continue;
      if (naechste == null || andere.box.left < naechste.box.left) naechste = andere;
    }
    final wert = naechste?.text.trim();
    if (wert == null || !form.hasMatch(wert)) return null;
    return wert;
  }
}

const RechnungsTrenner rechnungsTrenner = RechnungsTrenner();
