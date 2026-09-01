/// Ergebnis der Texterkennung — bewusst OHNE Flutter- oder Plugin-Import.
///
/// Der Grund: der gesamte Parser aus Phase 2 baut auf diesen Strukturen auf.
/// Solange sie reines Dart bleiben, laesst sich das Auslesen einer Rechnung
/// ohne Geraet, ohne Emulator und ohne Widget-Baum testen — mit echten
/// aufgezeichneten Erkennungsdaten als Testdatensatz.

/// Rechteck in Bildkoordinaten (Ursprung oben links, Pixel).
class OcrBox {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  /// Liegen zwei Textstuecke auf derselben Zeilenhoehe?
  ///
  /// Das ist der Kern der Tabellenrekonstruktion: In einer Rechnung stehen
  /// Tarifcode, Bezeichnung und Betrag weit auseinander, aber auf gleicher
  /// Hoehe. Im flachen OCR-Text geht dieser Zusammenhang verloren — hier
  /// nicht.
  ///
  /// [tolerance] federt leichte Schraeglagen (fotografierte Rechnungen) ab.
  bool sharesRowWith(OcrBox other, {double tolerance = 0}) {
    return top - tolerance < other.bottom && bottom + tolerance > other.top;
  }

  Map<String, dynamic> toJson() => {
        'l': left.roundToDouble(),
        't': top.roundToDouble(),
        'r': right.roundToDouble(),
        'b': bottom.roundToDouble(),
      };

  factory OcrBox.fromJson(Map<String, dynamic> json) => OcrBox(
        left: (json['l'] as num).toDouble(),
        top: (json['t'] as num).toDouble(),
        right: (json['r'] as num).toDouble(),
        bottom: (json['b'] as num).toDouble(),
      );

  @override
  String toString() => 'OcrBox(${left.round()},${top.round()} - ${right.round()},${bottom.round()})';
}

/// Eine von der Texterkennung gefundene Textzeile samt Position.
class OcrTextLine {
  final String text;
  final OcrBox box;

  const OcrTextLine({required this.text, required this.box});

  Map<String, dynamic> toJson() => {'text': text, 'box': box.toJson()};

  factory OcrTextLine.fromJson(Map<String, dynamic> json) => OcrTextLine(
        text: json['text'] as String,
        box: OcrBox.fromJson(Map<String, dynamic>.from(json['box'] as Map)),
      );
}

/// Alle erkannten Zeilen einer Seite.
class OcrPage {
  final String sourceName;
  final List<OcrTextLine> lines;

  const OcrPage({required this.sourceName, required this.lines});

  /// Der flache Text, wie ihn die Texterkennung ohne Positionen liefern
  /// wuerde. Nur noch fuer die Anzeige gedacht — nicht zum Auswerten.
  String get flatText => lines.map((l) => l.text).join('\n');

  /// Zeilen von oben nach unten, bei gleicher Hoehe von links nach rechts.
  List<OcrTextLine> get sortedByPosition {
    final sorted = List<OcrTextLine>.of(lines);
    sorted.sort((a, b) {
      final byTop = a.box.top.compareTo(b.box.top);
      return byTop != 0 ? byTop : a.box.left.compareTo(b.box.left);
    });
    return sorted;
  }

  Map<String, dynamic> toJson() => {
        'source': sourceName,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  factory OcrPage.fromJson(Map<String, dynamic> json) => OcrPage(
        sourceName: json['source'] as String,
        lines: (json['lines'] as List)
            .map((l) => OcrTextLine.fromJson(Map<String, dynamic>.from(l as Map)))
            .toList(),
      );
}
