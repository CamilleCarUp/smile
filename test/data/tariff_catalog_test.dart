import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/tariff_catalog.dart';

/// Frei erfundene Positionen — auch in Testdaten liegen keine Tarifinhalte.
const _erweitert = '''
{
  "_meta": { "status": "Beispiel" },
  "codes": [
    {
      "code": "9.1000",
      "description_de": "Beispielleistung",
      "tp": 100,
      "tp_pp_max": 115,
      "tp_pp_min": 85,
      "beinhaltet": ["Erster Handgriff", "Zweiter Handgriff"],
      "nicht_kumulierbar_mit": ["9.1100"],
      "limitationen": [
        { "max": 6, "wortlaut": "Maximal 6 mal pro Sitzung verrechenbar." },
        { "max": 1, "tage": 365, "gleiche_praxis": true,
          "wortlaut": "Nur 1 mal innerhalb von 12 Monaten in der gleichen Praxis." }
      ]
    }
  ]
}
''';

const _nurTaxpunkte = '''
{ "codes": [ { "code": "9.2000", "description_de": "Beispiel", "tp": 50 } ] }
''';

void main() {
  group('erweiterter Katalog', () {
    late TariffEntry eintrag;
    setUp(() => eintrag = TariffCatalog.fromJsonString(_erweitert).lookup('9.1000')!);

    test('liest Bandbreite, Beinhaltet und Kumulationsverbot', () {
      expect(eintrag.ppMax, 115);
      expect(eintrag.ppMin, 85);
      expect(eintrag.beinhaltet, hasLength(2));
      expect(eintrag.nichtKumulierbarMit, ['9.1100']);
    });

    test('unterscheidet Limitationen je Sitzung und je Zeitraum', () {
      expect(eintrag.limitationen, hasLength(2));

      final jeSitzung = eintrag.limitationen.firstWhere((l) => l.jeSitzung);
      expect(jeSitzung.maxAnzahl, 6);
      expect(jeSitzung.zeitraum, isNull);

      final jeZeitraum = eintrag.limitationen.firstWhere((l) => !l.jeSitzung);
      expect(jeZeitraum.zeitraum, const Duration(days: 365));
      expect(jeZeitraum.gleichePraxis, isTrue);
    });

    test('der Wortlaut bleibt erhalten', () {
      // Ein Befund zitiert die Vorschrift. Ohne den Wortlaut stünde er als
      // Behauptung der App da.
      expect(eintrag.limitationen.first.wortlaut, contains('Maximal 6 mal'));
    });

    test('gilt als vollständig', () {
      expect(TariffCatalog.fromJsonString(_erweitert).istVollstaendig, isTrue);
    });
  });

  group('Seed ohne erweiterte Angaben', () {
    test('bleibt lesbar und gilt als unvollständig', () {
      // Das ist der ausgelieferte Zustand ohne Lizenz: Taxpunkte ja,
      // Regelangaben nein — die erweiterten Regeln prüfen dann nichts.
      final katalog = TariffCatalog.fromJsonString(_nurTaxpunkte);

      expect(katalog.lookup('9.2000')!.taxpunkte, 50);
      expect(katalog.lookup('9.2000')!.ppMax, isNull);
      expect(katalog.istVollstaendig, isFalse);
    });

    test('der mitgelieferte Katalog ist unvollständig — und das ist richtig so', () {
      // Wäre er es nicht, lägen lizenzierte Daten im Repository.
      final seed = TariffCatalog.fromJsonString(
          '{"codes":[{"code":"4.0020","description_de":"x","tp":33.1}]}');
      expect(seed.istVollstaendig, isFalse);
    });
  });
}
