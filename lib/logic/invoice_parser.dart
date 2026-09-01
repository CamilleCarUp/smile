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

/// Fasst Textstuecke zu Zeilen zusammen.
///
/// Das ist der Kern: Tarifcode und Betrag stehen auf einer Rechnung weit
/// auseinander (hier ueber 1500 Pixel), aber auf gleicher Hoehe. Im flachen
/// Erkennungstext geht dieser Bezug verloren — ueber die vertikale
/// Ueberlappung nicht.
///
/// [toleranceFactor] federt schraeg fotografierte Rechnungen ab und ist
/// bewusst relativ zur Zeilenhoehe: absolute Pixelwerte waeren je nach
/// Kameraaufloesung mal zu grosszuegig, mal zu streng.
List<List<OcrTextLine>> groupIntoRows(List<OcrTextLine> lines, {double toleranceFactor = 0.25}) {
  final rows = <List<OcrTextLine>>[];

  final sorted = List<OcrTextLine>.of(lines)
    ..sort((a, b) {
      final byTop = a.box.top.compareTo(b.box.top);
      return byTop != 0 ? byTop : a.box.left.compareTo(b.box.left);
    });

  for (final line in sorted) {
    List<OcrTextLine>? match;
    for (final row in rows) {
      final fits = row.any((existing) {
        final tolerance = (existing.box.height + line.box.height) / 2 * toleranceFactor;
        return existing.box.sharesRowWith(line.box, tolerance: tolerance);
      });
      if (fits) {
        match = row;
        break;
      }
    }
    if (match == null) {
      rows.add([line]);
    } else {
      match.add(line);
    }
  }

  for (final row in rows) {
    row.sort((a, b) => a.box.left.compareTo(b.box.left));
  }
  rows.sort((a, b) => a.first.box.top.compareTo(b.first.box.top));
  return rows;
}

// --- Parser -----------------------------------------------------------------

final RegExp _tariffCode = RegExp(r'\b(\d\.\d{4})\b');
final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
final RegExp _looksNumeric = RegExp(r'^[\s\d.,]*\d[\s\d.,]*(CHF|CHE|GHF|Fr\.?)?\s*$', caseSensitive: false);

class InvoiceParser {
  const InvoiceParser();

  ParsedInvoice parse(List<OcrPage> pages) {
    final allLines = <OcrTextLine>[];
    for (final page in pages) {
      allLines.addAll(page.lines);
    }
    final rows = groupIntoRows(allLines);

    return ParsedInvoice(
      rows: _extractTariffRows(rows),
      header: _extractHeader(rows),
      statedTotal: _extractStatedTotal(rows),
    );
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
      String? code;
      for (final cell in row) {
        final match = _tariffCode.firstMatch(cell.text);
        if (match != null) {
          codeCell = cell;
          code = match.group(1);
          break;
        }
      }
      if (code == null || codeCell == null) continue;

      final description = codeCell.text.replaceFirst(code, '').trim();

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
