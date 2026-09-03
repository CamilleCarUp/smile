import 'package:flutter_test/flutter_test.dart';
import 'package:smile/logic/behandlung.dart';
import 'package:smile/models/request.dart';

TariffLine _line(String code, {DateTime? datum, double betrag = 10}) =>
    TariffLine(code: code, description: code, amountChf: betrag, date: datum);

void main() {
  group('sitzungen', () {
    test('ohne Zeilendaten bleibt alles zusammen', () {
      // Kein Mangel, sondern die ehrliche Wiedergabe dessen, was auf der
      // Rechnung steht.
      final tage = sitzungen([_line('4.5350'), _line('4.5800')]);

      expect(tage, hasLength(1));
      expect(tage.single.datum, isNull);
      expect(tage.single.positionen, hasLength(2));
    });

    test('teilt nach Behandlungstag und sortiert nach Datum', () {
      final tage = sitzungen([
        _line('4.5430', datum: DateTime(2026, 2, 12)),
        _line('4.0020', datum: DateTime(2026, 2, 3)),
        _line('4.5800', datum: DateTime(2026, 2, 12)),
      ]);

      expect(tage.map((t) => t.datum).toList(),
          [DateTime(2026, 2, 3), DateTime(2026, 2, 12)]);
      expect(tage.first.positionen.single.code, '4.0020');
      expect(tage.last.positionen, hasLength(2));
    });

    test('die Uhrzeit spielt keine Rolle', () {
      final tage = sitzungen([
        _line('4.5350', datum: DateTime(2026, 2, 12, 8, 30)),
        _line('4.5800', datum: DateTime(2026, 2, 12, 16, 5)),
      ]);

      expect(tage, hasLength(1));
    });

    test('Positionen ohne Datum stehen hinten, nicht bei einem fremden Tag', () {
      final tage = sitzungen([
        _line('4.5430', datum: DateTime(2026, 2, 12)),
        _line('4.0300'),
      ]);

      expect(tage, hasLength(2));
      expect(tage.last.datum, isNull);
      expect(tage.last.positionen.single.code, '4.0300');
    });

    test('jede Sitzung rechnet ihre eigene Summe', () {
      final tage = sitzungen([
        _line('4.5430', datum: DateTime(2026, 2, 12), betrag: 217.55),
        _line('4.5800', datum: DateTime(2026, 2, 12), betrag: 23.05),
        _line('4.0020', datum: DateTime(2026, 2, 3), betrag: 39.70),
      ]);

      expect(tage.first.summe, closeTo(39.70, 0.001));
      expect(tage.last.summe, closeTo(240.60, 0.001));
    });

    test('keine Positionen, keine Sitzung', () {
      expect(sitzungen(const []), isEmpty);
    });
  });
}
