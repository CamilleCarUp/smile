import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/tariff_catalog.dart';
import 'package:smile/logic/tarif_regeln.dart';
import 'package:smile/models/finding.dart';
import 'package:smile/models/request.dart';

/// Frei erfundene Positionen mit Codes, die es im Tarif nicht gibt.
///
/// Absicht: Auch in Testdaten liegen keine Tarifinhalte. Geprüft wird die
/// Mechanik der Regeln, und die ist von den echten Zahlen unabhängig.
TariffCatalog _katalog() => TariffCatalog.fromEntries(const [
      TariffEntry(
        code: '9.1000',
        description: 'Beispielleistung mit Bandbreite',
        taxpunkte: 100,
        ppMax: 115,
        ppMin: 85,
      ),
      TariffEntry(
        code: '9.2000',
        description: 'Beispielleistung pro Sextant',
        taxpunkte: 10,
        limitationen: [
          Limitation(maxAnzahl: 6, wortlaut: 'Maximal 6 mal pro Sitzung verrechenbar.'),
        ],
      ),
      TariffEntry(
        code: '9.3000',
        description: 'Beispielleistung einmal jährlich',
        taxpunkte: 50,
        limitationen: [
          Limitation(
            maxAnzahl: 1,
            zeitraum: Duration(days: 365),
            wortlaut: 'Darf pro Patient innerhalb von 12 Monaten in der gleichen '
                'Praxis nur 1 mal verrechnet werden.',
          ),
        ],
      ),
      TariffEntry(
        code: '9.4000',
        description: 'Beispielleistung A',
        taxpunkte: 20,
        nichtKumulierbarMit: ['9.4100'],
      ),
      TariffEntry(
        code: '9.4100',
        description: 'Beispielleistung B',
        taxpunkte: 25,
        nichtKumulierbarMit: ['9.4000'],
      ),
    ]);

TariffLine _line(String code, {int menge = 1, double betrag = 120, DateTime? datum}) =>
    TariffLine(
        code: code,
        description: code,
        amountChf: betrag,
        quantity: menge,
        date: datum);

DentalRequest _alteRechnung(
        {required String praxis, required DateTime datum, required String code}) =>
    DentalRequest(
      id: 1,
      filename: 'alt',
      files: const [],
      invoiceNumber: '1',
      dentistName: praxis,
      dentistAddress: '',
      date: datum,
      lines: [TariffLine(code: code, description: code, amountChf: 60, quantity: 1)],
      invoiceTotal: 60,
      referenceTotal: 60,
    );

void main() {
  group('Vorbedingungen', () {
    test('ohne vollständigen Katalog prüft nichts', () {
      // Der mitgelieferte Seed kennt nur Taxpunkte. Auf leeren Daten zu
      // urteilen wäre schlimmer als zu schweigen.
      final seed = TariffCatalog.fromEntries(const [
        TariffEntry(code: '9.2000', description: 'x', taxpunkte: 10),
      ]);

      expect(seed.istVollstaendig, isFalse);
      expect(
          tarifRegeln.pruefe(
              lines: [_line('9.2000', menge: 99)],
              katalog: seed,
              vertrauenswuerdig: true,
              faktor: 1.2),
          isEmpty);
    });

    test('bei unsicherer Lesung prüft nichts', () {
      expect(
          tarifRegeln.pruefe(
              lines: [_line('9.2000', menge: 99)],
              katalog: _katalog(),
              vertrauenswuerdig: false,
              faktor: 1.2),
          isEmpty);
    });
  });

  group('Höchstsatz je Position', () {
    test('über der eigenen Obergrenze gibt es einen Befund', () {
      // 140 Taxpunkte effektiv bei erlaubten 115.
      final befunde = tarifRegeln.pruefe(
        lines: [_line('9.1000', betrag: 168.0)],
        katalog: _katalog(),
        vertrauenswuerdig: true,
        faktor: 1.2,
      );

      expect(befunde, hasLength(1));
      expect(befunde.single.kind, FindingKind.positionAboveMaximum);
      expect(befunde.single.observed, closeTo(140, 0.1));
      expect(befunde.single.allowed, 115);
      expect(befunde.single.excessChf, closeTo(30, 0.5));
    });

    test('am oberen Rand der Bandbreite gibt es keinen', () {
      // 115 Taxpunkte × 1.2 = 138.00 — zulässig.
      expect(
          tarifRegeln.pruefe(
            lines: [_line('9.1000', betrag: 138.0)],
            katalog: _katalog(),
            vertrauenswuerdig: true,
            faktor: 1.2,
          ),
          isEmpty);
    });

    test('die Menge wird herausgerechnet', () {
      // Zweimal zum Höchstsatz ist kein Befund über den Preis.
      expect(
          tarifRegeln.pruefe(
            lines: [_line('9.1000', menge: 2, betrag: 276.0)],
            katalog: _katalog(),
            vertrauenswuerdig: true,
            faktor: 1.2,
          ),
          isEmpty);
    });
  });

  group('Menge je Sitzung', () {
    test('über dem Limit gibt es einen Befund samt Wortlaut', () {
      final befunde = tarifRegeln.pruefe(
        lines: [_line('9.2000', menge: 8, betrag: 96)],
        katalog: _katalog(),
        vertrauenswuerdig: true,
        faktor: 1.2,
      );

      expect(befunde.single.kind, FindingKind.quantityAboveLimit);
      expect(befunde.single.explanation, contains('Maximal 6 mal pro Sitzung'));
      expect(befunde.single.observed, 8);
    });

    test('auf das Limit verteilt über zwei Sitzungen ist es keiner', () {
      // Zwei Termine, je sechs — der Tarif begrenzt pro Sitzung, nicht pro
      // Rechnung. Ohne Zeilendatum wäre das ein Fehlalarm.
      final befunde = tarifRegeln.pruefe(
        lines: [
          _line('9.2000', menge: 6, betrag: 72, datum: DateTime(2026, 2, 3)),
          _line('9.2000', menge: 6, betrag: 72, datum: DateTime(2026, 2, 12)),
        ],
        katalog: _katalog(),
        vertrauenswuerdig: true,
        faktor: 1.2,
      );

      expect(befunde, isEmpty);
    });
  });

  group('Kumulationsverbot', () {
    test('zwei sich ausschliessende Positionen ergeben genau einen Befund', () {
      // Das Verbot steht in beiden Einträgen — gemeldet wird es einmal.
      final befunde = tarifRegeln.pruefe(
        lines: [_line('9.4000', betrag: 24), _line('9.4100', betrag: 30)],
        katalog: _katalog(),
        vertrauenswuerdig: true,
        faktor: 1.2,
      );

      expect(befunde, hasLength(1));
      expect(befunde.single.kind, FindingKind.notCumulable);
    });

    test('an verschiedenen Terminen ist es kein Verstoss', () {
      expect(
          tarifRegeln.pruefe(
            lines: [
              _line('9.4000', betrag: 24, datum: DateTime(2026, 2, 3)),
              _line('9.4100', betrag: 30, datum: DateTime(2026, 5, 20)),
            ],
            katalog: _katalog(),
            vertrauenswuerdig: true,
            faktor: 1.2,
          ),
          isEmpty);
    });
  });

  group('Wiederholung innert Frist', () {
    // Die Regel, die nur diese App prüfen kann: Der Verlauf liegt auf dem
    // Gerät des Patienten.
    test('dieselbe Praxis innerhalb der Frist ergibt einen Befund', () {
      final befunde = tarifRegeln.pruefe(
        lines: [_line('9.3000', betrag: 60)],
        katalog: _katalog(),
        vertrauenswuerdig: true,
        faktor: 1.2,
        rechnungsdatum: DateTime(2026, 2, 17),
        praxis: 'Dr. med. dent. Max Muster',
        verlauf: [
          _alteRechnung(
              praxis: 'Dr. med. dent. Max Muster',
              datum: DateTime(2025, 9, 1),
              code: '9.3000'),
        ],
      );

      expect(befunde.single.kind, FindingKind.repeatedWithinPeriod);
      expect(befunde.single.explanation, contains('01.09.2025'));
      expect(befunde.single.explanation, contains('12 Monaten'));
    });

    test('ausserhalb der Frist nicht', () {
      expect(
          tarifRegeln.pruefe(
            lines: [_line('9.3000', betrag: 60)],
            katalog: _katalog(),
            vertrauenswuerdig: true,
            faktor: 1.2,
            rechnungsdatum: DateTime(2026, 2, 17),
            praxis: 'Dr. med. dent. Max Muster',
            verlauf: [
              _alteRechnung(
                  praxis: 'Dr. med. dent. Max Muster',
                  datum: DateTime(2024, 1, 5),
                  code: '9.3000'),
            ],
          ),
          isEmpty);
    });

    test('eine andere Praxis nicht', () {
      // Der Tarif sagt "in der gleichen Praxis". Alles andere wäre eine
      // Unterstellung gegenüber zwei Praxen, die nichts voneinander wissen.
      expect(
          tarifRegeln.pruefe(
            lines: [_line('9.3000', betrag: 60)],
            katalog: _katalog(),
            vertrauenswuerdig: true,
            faktor: 1.2,
            rechnungsdatum: DateTime(2026, 2, 17),
            praxis: 'Dr. med. dent. Max Muster',
            verlauf: [
              _alteRechnung(
                  praxis: 'Zahnarztpraxis Seefeld',
                  datum: DateTime(2025, 9, 1),
                  code: '9.3000'),
            ],
          ),
          isEmpty);
    });

    test('ohne Verlauf gibt es nichts zu vergleichen', () {
      expect(
          tarifRegeln.pruefe(
            lines: [_line('9.3000', betrag: 60)],
            katalog: _katalog(),
            vertrauenswuerdig: true,
            faktor: 1.2,
            rechnungsdatum: DateTime(2026, 2, 17),
            praxis: 'Dr. med. dent. Max Muster',
          ),
          isEmpty);
    });
  });
}
