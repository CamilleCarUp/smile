import '../models/ocr_result.dart';

/// Rekonstruiert aus einer Texterkennung die Struktur einer Zahnarztrechnung.
///
/// Reines Dart, keine Flutter-Abhaengigkeit — dadurch gegen aufgezeichnete
/// Erkennungsdaten echter Rechnungen testbar (siehe
/// test/fixtures/ocr_kostenvoranschlag.json).
///
/// Grundannahme, aus echten Daten gewonnen: **Tarifcodes werden zuverlaessig
/// erkannt, Zahlen nicht.** Das Muster `4.xxxx` ist markant genug, dass die
/// Texterkennung es praktisch immer trifft. Bei Betraegen geht dagegen
/// regelmaessig der Dezimaltrenner verloren ("92 20" statt 92.20, "120" statt
/// 1.20) oder eine Ziffer ganz ("15" statt 15.7).
///
/// Deshalb wird hier bewusst NICHT auf einen Zahlenwert festgelegt. Jedes
/// Zahlenfeld liefert seine plausiblen Lesarten; welche stimmt, entscheidet
/// der spaetere Abgleich anhand der Referenz-Taxpunkte und der
/// Rechnungssumme. Eine falsch geratene Zahl waere schlimmer als gar keine:
/// Die App wuerde eine Abweichung behaupten, die es nicht gibt.

/// Ein erkanntes Zahlenfeld mit allen plausiblen Lesarten (beste zuerst).
class NumberField {
  final String raw;
  final List<double> candidates;
  final OcrBox box;

  const NumberField({required this.raw, required this.candidates, required this.box});

  double? get best => candidates.isEmpty ? null : candidates.first;
  bool get isAmbiguous => candidates.length > 1;

  @override
  String toString() => '"$raw" -> $candidates';
}

/// Eine Rechnungszeile mit Tarifcode.
class ParsedTariffRow {
  final String code;
  final String description;

  /// Alle Zahlenfelder dieser Zeile, von links nach rechts. Je nach
  /// Rechnungsformular sind das Anzahl / Taxpunkte / Taxpunktwert /
  /// Zeilenbetrag — die Zuordnung passiert bewusst erst im Abgleich, weil
  /// nicht jede Praxis dieselben Spalten druckt.
  final List<NumberField> numbers;

  final OcrBox box;

  const ParsedTariffRow({
    required this.code,
    required this.description,
    required this.numbers,
    required this.box,
  });

  /// Der Zeilenbetrag steht in aller Regel ganz rechts.
  NumberField? get rightmostNumber => numbers.isEmpty ? null : numbers.last;
}

/// Was sich ausser den Positionen noch aus der Rechnung lesen laesst.
class ParsedInvoiceHeader {
  final String? dentistName;
  final String? dentistAddress;
  final String? dentistEmail;
  final String? invoiceNumber;
  final String? patient;
  final DateTime? date;

  const ParsedInvoiceHeader({
    this.dentistName,
    this.dentistAddress,
    this.dentistEmail,
    this.invoiceNumber,
    this.patient,
    this.date,
  });
}

class ParsedInvoice {
  final List<ParsedTariffRow> rows;
  final ParsedInvoiceHeader header;

  /// Das auf der Rechnung ausgewiesene Total, falls gefunden. Dient als
  /// Gegenprobe fuer die Einzelbetraege.
  final NumberField? statedTotal;

  const ParsedInvoice({
    required this.rows,
    required this.header,
    this.statedTotal,
  });

  bool get isEmpty => rows.isEmpty;
}

// --- Zahlen -----------------------------------------------------------------

/// Plausible Lesarten eines erkannten Zahlenfelds, beste zuerst.
///
/// Beispiele aus echten Erkennungsdaten:
/// * `"39.70"`      -> `[39.7]`          (Trenner sichtbar, eindeutig)
/// * `"92 20"`      -> `[92.2]`          (Leerzeichen statt Trenner)
/// * `"320.20GHF"`  -> `[320.2]`         (Waehrung angehaengt)
/// * `"120"`        -> `[120, 12.0, 1.2]` (Trenner fehlt ganz — mehrdeutig)
List<double> numberCandidates(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.,\s]'), '').trim();
  if (cleaned.isEmpty) return const [];

  // Trenner sichtbar, gefolgt von ein bis zwei Nachkommastellen.
  final explicit = RegExp(r'^(\d+)\s*[.,]\s*(\d{1,2})$').firstMatch(cleaned);
  if (explicit != null) {
    return [double.parse('${explicit.group(1)}.${explicit.group(2)}')];
  }

  // Trenner als Leerzeichen erkannt: "92 20", "38 4".
  final spaced = RegExp(r'^(\d+)\s+(\d{1,2})$').firstMatch(cleaned);
  if (spaced != null) {
    return [double.parse('${spaced.group(1)}.${spaced.group(2)}')];
  }

  // Reine Ziffernfolge: der Trenner kann komplett fehlen. Alle Lesarten
  // anbieten, statt eine zu raten.
  final digits = cleaned.replaceAll(RegExp(r'\s'), '');
  if (RegExp(r'^\d+$').hasMatch(digits)) {
    final asWritten = double.parse(digits);
    final out = <double>[asWritten];
    if (digits.length >= 2) out.add(asWritten / 10);
    if (digits.length >= 3) out.add(asWritten / 100);
    return out;
  }

  return const [];
}

// --- Zeilenbildung ----------------------------------------------------------

/// Schaetzt, wie stark das Bild verkantet ist.
///
/// Fotografiert jemand eine Rechnung, liegt sie fast nie exakt gerade. Schon
/// eineinhalb Grad Neigung verschieben die rechte Blattkante gegenueber der
/// linken um mehr als eine Zeilenhoehe. Dann liegt der Betrag einer Zeile
/// tiefer als der Tarifcode der naechsten -- und eine Zeilenbildung, die nur
/// die Hoehe vergleicht, verschmilzt die ganze Tabelle zu einem Block.
///
/// Genau das ist auf einem echten Foto passiert: von fuenf Positionen kam
/// eine an.
///
/// Geschaetzt wird ueber ein Projektionsprofil: Fuer eine Reihe von
/// Kandidaten-Neigungen werden alle Textstuecke entzerrt und in schmale
/// Hoehenbaender einsortiert. Bei der richtigen Neigung fallen sie am
/// saubersten in wenige, dicht besetzte Baender -- also dorthin, wo die Summe
/// der quadrierten Belegungen am groessten ist.
///
/// [maxSlope] deckt rund elf Grad ab. Das klingt viel, ist es aber nicht:
/// Ein aus der Hand aufgenommenes Foto lag in der Praxis bei acht Grad, was
/// die rechte Spalte um 180 Pixel gegenueber der linken verschiebt. Ein zu
/// enger Suchbereich ist der schlechtere Fehler -- dann bleibt die Verkantung
/// unerkannt und die Betraege landen bei der falschen Position.
/// Schaetzt, wie stark das Bild verkantet ist -- und liefert bewusst MEHRERE
/// Kandidaten statt eines Werts.
///
/// Fotografiert jemand eine Rechnung, liegt sie fast nie exakt gerade. Schon
/// eineinhalb Grad Neigung verschieben die rechte Blattkante gegenueber der
/// linken um mehr als eine Zeilenhoehe. Dann liegt der Betrag einer Zeile
/// tiefer als der Tarifcode der naechsten, und die Zeilenbildung ordnet jeden
/// Betrag der falschen Position zu.
///
/// Geschaetzt wird ueber ein Projektionsprofil: Fuer eine Reihe von
/// Kandidaten-Neigungen werden alle Textstuecke entzerrt und in schmale
/// Hoehenbaender einsortiert. Bei einer passenden Neigung fallen sie sauber in
/// wenige, dicht besetzte Baender.
///
/// **Warum mehrere Kandidaten:** Eine Rechnung ist ein regelmaessiges Raster.
/// Verschiebt man die Neigung gerade so weit, dass jede Zeile auf die
/// naechste faellt, ist das Ergebnis genauso "scharf" -- nur um eine Zeile
/// versetzt. Aus der Schaerfe allein laesst sich das nicht entscheiden. Auf
/// einem echten Foto lagen die gleichwertigen Kandidaten 0.031 auseinander,
/// und der bestbewertete war der falsche: jede Position bekam den Betrag
/// ihrer Nachbarin.
///
/// Entschieden wird deshalb erst in [InvoiceParser.parse], und zwar an einem
/// Kriterium, das die Rechnung selbst mitbringt: nur bei der richtigen
/// Ausrichtung ergeben die Zeilenbetraege in Summe das ausgewiesene Total.
///
/// [maxSlope] deckt rund elf Grad ab. Das klingt viel, ist es aber nicht: ein
/// aus der Hand aufgenommenes Foto lag in der Praxis bei neun Grad.
List<double> skewCandidates(
  List<OcrTextLine> lines, {
  double maxSlope = 0.20,
  int count = 6,
}) {
  // Bei sehr wenigen Textstuecken ist die Schaetzung nicht belastbar; dann
  // lieber gar nicht entzerren als in die falsche Richtung.
  if (lines.length < 8) return const [0.0];

  final heights = lines.map((l) => l.box.height).toList()..sort();
  final medianHeight = heights[heights.length ~/ 2];
  final binWidth = medianHeight <= 0 ? 1.0 : medianHeight / 2;

  // Feine Schrittweite: bei 0.001 bleibt der Restfehler ueber die Blattbreite
  // unter zwei Pixeln.
  const steps = 200;
  final scored = <({double slope, int score})>[];
  for (var step = -steps; step <= steps; step++) {
    final slope = maxSlope * step / steps;
    final counts = <int, int>{};
    for (final line in lines) {
      final corrected = line.box.centerY - slope * line.box.centerX;
      final bin = (corrected / binWidth).floor();
      counts[bin] = (counts[bin] ?? 0) + 1;
    }
    var score = 0;
    for (final c in counts.values) {
      score += c * c;
    }
    scored.add((slope: slope, score: score));
  }

  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.slope.abs().compareTo(b.slope.abs());
  });

  // Nur deutlich verschiedene Neigungen aufnehmen -- benachbarte Rasterwerte
  // beschreiben dieselbe Ausrichtung.
  final chosen = <double>[];
  for (final entry in scored) {
    if (chosen.every((c) => (entry.slope - c).abs() > 0.012)) {
      chosen.add(entry.slope);
    }
    if (chosen.length >= count) break;
  }
  return chosen;
}

/// Die bestbewertete Neigung. Fuer sich genommen nicht ausreichend -- siehe
/// [skewCandidates] und [InvoiceParser.parse].
double estimateSkew(List<OcrTextLine> lines, {double maxSlope = 0.20}) =>
    skewCandidates(lines, maxSlope: maxSlope, count: 1).first;

/// Fasst Textstuecke zu Zeilen zusammen.
///
/// Das ist der Kern: Tarifcode und Betrag stehen auf einer Rechnung weit
/// auseinander (auf echten Belegen ueber 1500 Pixel), aber auf gleicher
/// Hoehe. Im flachen Erkennungstext geht dieser Bezug verloren, hier nicht.
///
/// Zwei Dinge, die aus echten Fotos gelernt sind:
///
/// * Zuerst wird die Verkantung herausgerechnet (siehe [estimateSkew]).
///   Ohne das versagt die Zeilenbildung auf jedem freihaendig aufgenommenen
///   Bild.
/// * Verglichen werden **Mittellinien**, nicht Ueberlappungen. Die Textkaesten
///   sind unterschiedlich hoch -- eine lange Leistungsbezeichnung ist gut
///   anderthalbmal so hoch wie die Zahl daneben. Ueber die Ueberlappung
///   beruehren sich dann benachbarte Zeilen, obwohl ihre Mitten sauber
///   getrennt liegen.
///
/// [rowToleranceFactor] ist bewusst relativ zur mittleren Zeilenhoehe:
/// absolute Pixelwerte waeren je nach Kameraaufloesung mal zu grosszuegig,
/// mal zu streng.
List<List<OcrTextLine>> groupIntoRows(
  List<OcrTextLine> lines, {
  double rowToleranceFactor = 0.6,
  double? skew,
}) {
  if (lines.isEmpty) return [];

  final slope = skew ?? estimateSkew(lines);
  final heights = lines.map((l) => l.box.height).toList()..sort();
  final medianHeight = heights[heights.length ~/ 2];
  final threshold = (medianHeight <= 0 ? 1.0 : medianHeight) * rowToleranceFactor;

  final entries = lines
      .map((l) => (line: l, y: l.box.centerY - slope * l.box.centerX))
      .toList()
    ..sort((a, b) {
      final byY = a.y.compareTo(b.y);
      return byY != 0 ? byY : a.line.box.left.compareTo(b.line.box.left);
    });

  final rows = <List<({OcrTextLine line, double y})>>[];
  for (final entry in entries) {
    List<({OcrTextLine line, double y})>? match;
    for (final row in rows) {
      if (row.any((existing) => (entry.y - existing.y).abs() <= threshold)) {
        match = row;
        break;
      }
    }
    if (match == null) {
      rows.add([entry]);
    } else {
      match.add(entry);
    }
  }

  for (final row in rows) {
    row.sort((a, b) => a.line.box.left.compareTo(b.line.box.left));
  }
  rows.sort((a, b) {
    double top(List<({OcrTextLine line, double y})> r) =>
        r.map((e) => e.y).reduce((x, y) => x < y ? x : y);
    return top(a).compareTo(top(b));
  });

  return rows.map((row) => row.map((e) => e.line).toList()).toList();
}

// --- Parser -----------------------------------------------------------------

final RegExp _tariffCode = RegExp(r'\b(\d[.,]\d{4})\b');
final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
final RegExp _looksNumeric = RegExp(r'^[\s\d.,]*\d[\s\d.,]*(CHF|CHE|GHF|Fr\.?)?\s*$', caseSensitive: false);

class InvoiceParser {
  const InvoiceParser();

  ParsedInvoice parse(List<OcrPage> pages) {
    final allLines = <OcrTextLine>[];
    for (final page in pages) {
      allLines.addAll(page.lines);
    }
    if (allLines.isEmpty) {
      return const ParsedInvoice(rows: [], header: ParsedInvoiceHeader());
    }

    // Mehrere Ausrichtungen der Seite sind rechnerisch gleich plausibel
    // (siehe [skewCandidates]). Entschieden wird an der Rechnung selbst:
    // Nur wenn die Zeilenbetraege in Summe das ausgewiesene Total ergeben,
    // wurden sie der richtigen Position zugeordnet.
    ParsedInvoice? erste;
    ParsedInvoice? stimmige;

    for (final slope in skewCandidates(allLines)) {
      final rows = groupIntoRows(allLines, skew: slope);
      final invoice = ParsedInvoice(
        rows: _extractTariffRows(rows),
        header: _extractHeader(rows),
        statedTotal: _extractStatedTotal(rows),
      );
      erste ??= invoice;

      // Unter den stimmigen gewinnt die mit den meisten Positionen: sonst
      // koennte eine Ausrichtung gewinnen, bei der nur eine einzige Position
      // erkannt wird und deren Betrag zufaellig dem Total entspricht.
      if (_addsUp(invoice) &&
          (stimmige == null || invoice.rows.length > stimmige.rows.length)) {
        stimmige = invoice;
      }
    }

    // Keine Ausrichtung geht auf? Dann die bestbewertete zurueckgeben -- die
    // Summenprobe schlaegt spaeter an und das Ergebnis gilt als unsicher.
    return stimmige ?? erste!;
  }

  /// Ergeben die Zeilenbetraege in Summe das ausgewiesene Total?
  bool _addsUp(ParsedInvoice invoice) {
    final total = invoice.statedTotal?.best;
    if (total == null || invoice.rows.isEmpty) return false;
    final sum = invoice.rows
        .fold(0.0, (s, r) => s + (r.rightmostNumber?.best ?? 0));
    return (sum - total).abs() <= 0.05;
  }

  /// Nur Zeilen mit Tarifcode zaehlen als Rechnungsposition.
  ///
  /// Das erledigt nebenbei das Rauschproblem: Fotografiert jemand einen
  /// Bildschirm ab, landen Menuebeschriftungen des PDF-Betrachters mit im
  /// Text. Ohne Tarifcode fliegen sie hier ohne Sonderbehandlung raus.
  List<ParsedTariffRow> _extractTariffRows(List<List<OcrTextLine>> rows) {
    final result = <ParsedTariffRow>[];

    for (final row in rows) {
      OcrTextLine? codeCell;
      String? rawCode;
      for (final cell in row) {
        final match = _tariffCode.firstMatch(cell.text);
        if (match != null) {
          codeCell = cell;
          rawCode = match.group(1);
          break;
        }
      }
      if (rawCode == null || codeCell == null) continue;

      // Die Erkennung liest den Punkt im Tarifcode gelegentlich als Komma
      // ("4,0020"). Verglichen wird mit der Schreibweise des Tarifs, aus der
      // Bezeichnung entfernt wird aber der tatsaechlich gelesene Text.
      // Ohne das faellt die betroffene Position komplett aus der Erfassung.
      final code = rawCode.replaceAll(',', '.');
      final description = codeCell.text.replaceFirst(rawCode, '').trim();

      final numbers = <NumberField>[];
      for (final cell in row) {
        if (identical(cell, codeCell)) continue;
        if (!_looksNumeric.hasMatch(cell.text)) continue;
        final candidates = numberCandidates(cell.text);
        if (candidates.isEmpty) continue;
        numbers.add(NumberField(raw: cell.text, candidates: candidates, box: cell.box));
      }

      result.add(ParsedTariffRow(
        code: code,
        description: description,
        numbers: numbers,
        box: codeCell.box,
      ));
    }

    return result;
  }

  /// Das Rechnungstotal: die unterste Zeile, die mit "Total" beginnt.
  /// Bewusst die unterste — weiter oben stehen oft Zwischensummen.
  NumberField? _extractStatedTotal(List<List<OcrTextLine>> rows) {
    NumberField? found;
    for (final row in rows) {
      final hasTotalLabel = row.any((c) => c.text.trim().toLowerCase().startsWith('total'));
      if (!hasTotalLabel) continue;
      for (final cell in row.reversed) {
        if (!_looksNumeric.hasMatch(cell.text)) continue;
        final candidates = numberCandidates(cell.text);
        if (candidates.isEmpty) continue;
        found = NumberField(raw: cell.text, candidates: candidates, box: cell.box);
        break;
      }
    }
    return found;
  }

  ParsedInvoiceHeader _extractHeader(List<List<OcrTextLine>> rows) {
    String? valueAfterLabel(String labelPrefix) {
      for (final row in rows) {
        for (var i = 0; i < row.length; i++) {
          final text = row[i].text.trim().toLowerCase();
          if (!text.startsWith(labelPrefix.toLowerCase())) continue;
          // Wert steht entweder rechts daneben oder hinter dem Doppelpunkt.
          if (i + 1 < row.length) return row[i + 1].text.trim();
          final rest = row[i].text.split(RegExp(r'[:.]')).skip(1).join(':').trim();
          if (rest.isNotEmpty) return rest;
        }
      }
      return null;
    }

    String? email;
    OcrTextLine? nameCell;
    for (final row in rows) {
      for (final cell in row) {
        email ??= _email.firstMatch(cell.text)?.group(0);
        // Der Praxisname steht im Briefkopf, also im obersten Treffer.
        if (nameCell == null && RegExp(r'dent\.', caseSensitive: false).hasMatch(cell.text)) {
          nameCell = cell;
        }
      }
    }

    // Adresszeilen: gleiche Spalte wie der Name, darunter, oberhalb der
    // E-Mail-Zeile.
    String? address;
    if (nameCell != null) {
      final parts = <String>[];
      for (final row in rows) {
        for (final cell in row) {
          if (cell.box.top <= nameCell.box.top) continue;
          if ((cell.box.left - nameCell.box.left).abs() > 60) continue;
          if (_email.hasMatch(cell.text)) continue;
          if (cell.box.top - nameCell.box.top > 200) continue;
          parts.add(cell.text.trim());
        }
      }
      if (parts.isNotEmpty) address = parts.join(', ');
    }

    // Datum: die Ziffern sind belastbarer als die Trennzeichen
    // ("16.022026" statt "16.02.2026").
    DateTime? date;
    final rawDate = valueAfterLabel('datum');
    if (rawDate != null) {
      final digits = rawDate.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 8) {
        final day = int.tryParse(digits.substring(0, 2));
        final month = int.tryParse(digits.substring(2, 4));
        final year = int.tryParse(digits.substring(4, 8));
        if (day != null && month != null && year != null && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          date = DateTime(year, month, day);
        }
      }
    }

    return ParsedInvoiceHeader(
      dentistName: nameCell?.text.trim(),
      dentistAddress: address,
      dentistEmail: email,
      invoiceNumber: valueAfterLabel('referenz'),
      patient: valueAfterLabel('patient'),
      date: date,
    );
  }
}

const invoiceParser = InvoiceParser();
