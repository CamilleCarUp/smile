import 'package:flutter_test/flutter_test.dart';
import 'package:smile/models/ocr_result.dart';

OcrTextLine _line(String text, double left, double top, {double width = 60, double height = 14}) {
  return OcrTextLine(
    text: text,
    box: OcrBox(left: left, top: top, right: left + width, bottom: top + height),
  );
}

void main() {
  group('OcrBox.sharesRowWith', () {
    test('erkennt Textstücke auf gleicher Zeilenhöhe, auch weit auseinander', () {
      // So sieht eine Rechnungszeile aus: Code ganz links, Betrag ganz rechts.
      const code = OcrBox(left: 40, top: 300, right: 100, bottom: 316);
      const amount = OcrBox(left: 620, top: 301, right: 690, bottom: 317);
      expect(code.sharesRowWith(amount), isTrue);
    });

    test('trennt Textstücke aus verschiedenen Zeilen', () {
      const zeile1 = OcrBox(left: 40, top: 300, right: 100, bottom: 316);
      const zeile2 = OcrBox(left: 40, top: 330, right: 100, bottom: 346);
      expect(zeile1.sharesRowWith(zeile2), isFalse);
    });

    test('Toleranz fängt leicht schräg fotografierte Zeilen ab', () {
      const links = OcrBox(left: 40, top: 300, right: 100, bottom: 314);
      const rechts = OcrBox(left: 620, top: 316, right: 690, bottom: 330);
      expect(links.sharesRowWith(rechts), isFalse);
      expect(links.sharesRowWith(rechts, tolerance: 6), isTrue);
    });
  });

  group('OcrBox Geometrie', () {
    test('berechnet Breite, Höhe und Mittelpunkt', () {
      const box = OcrBox(left: 10, top: 20, right: 110, bottom: 60);
      expect(box.width, 100);
      expect(box.height, 40);
      expect(box.centerX, 60);
      expect(box.centerY, 40);
    });
  });

  group('OcrPage', () {
    test('sortiert Zeilen von oben nach unten, dann von links nach rechts', () {
      final page = OcrPage(sourceName: 'test.jpg', lines: [
        _line('rechts oben', 500, 100),
        _line('unten', 40, 300),
        _line('links oben', 40, 100),
      ]);
      expect(page.sortedByPosition.map((l) => l.text).toList(),
          ['links oben', 'rechts oben', 'unten']);
    });

    test('flatText verkettet die Zeilen', () {
      final page = OcrPage(sourceName: 'test.jpg', lines: [
        _line('erste', 40, 100),
        _line('zweite', 40, 130),
      ]);
      expect(page.flatText, 'erste\nzweite');
    });

    test('überlebt eine JSON-Rundreise verlustfrei', () {
      final original = OcrPage(sourceName: 'rechnung.jpg', lines: [
        _line('4.0650', 40, 300),
        _line('46.10', 620, 301),
      ]);

      final restored = OcrPage.fromJson(original.toJson());

      expect(restored.sourceName, original.sourceName);
      expect(restored.lines, hasLength(2));
      expect(restored.lines.first.text, '4.0650');
      expect(restored.lines.first.box.left, original.lines.first.box.left);
      expect(restored.lines.last.box.top, original.lines.last.box.top);
    });
  });
}
