import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/logic/bezugsgroesse.dart';
import 'package:smile/data/tariff_catalog.dart';
import 'package:smile/logic/invoice_matcher.dart';
import 'package:smile/models/ocr_result.dart';
import 'package:smile/models/request.dart';

List<OcrPage> _fixture(String name) {
  final json =
      jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;
  return (json['pages'] as List)
      .map((p) => OcrPage.fromJson(Map<String, dynamic>.from(p as Map)))
      .toList();
}

TariffLine _zeile(String beschreibung, {int? menge}) => TariffLine(
      code: '4.0000',
      description: beschreibung,
      amountChf: 0,
      quantity: menge,
    );

void main() {
  group('bezugAus', () {
    test('erkennt Zeitpositionen samt Takt', () {
      expect(bezugAus('DH-Behandlung, pro 5 Min.'),
          const Bezugsangabe(Bezugsgroesse.zeit, minuten: 5));
      expect(bezugAus('Konsilium, pro 15 Min.'),
          const Bezugsangabe(Bezugsgroesse.zeit, minuten: 15));
      // Die Texterkennung verwechselt in "Min." gern i mit l oder 1.
      expect(bezugAus('Honorierung nach Zeitaufwand, pro 5 Mln.').art,
          Bezugsgroesse.zeit);
    });

    test('erkennt Flächenangaben in beiden Schreibweisen', () {
      expect(bezugAus('Kompositfüllung, einflächig'),
          const Bezugsangabe(Bezugsgroesse.flaeche, flaechen: 1));
      expect(bezugAus('Amalgam, 3-fl.'),
          const Bezugsangabe(Bezugsgroesse.flaeche, flaechen: 3));
      // "mehrflächig" nennt keine Zahl — dann bleibt sie offen.
      expect(bezugAus('Kompositfüllung, mehrflächig'),
          const Bezugsangabe(Bezugsgroesse.flaeche));
    });

    test('erkennt die übrigen Bezugsgrössen', () {
      expect(bezugAus('Lachgassedierung, pro Sitzung').art, Bezugsgroesse.sitzung);
      expect(bezugAus('Plaqueanfärbung, pro Sextant').art, Bezugsgroesse.sextant);
      expect(bezugAus('Wurzelspitzenresektion, pro Quadrant').art, Bezugsgroesse.quadrant);
      expect(bezugAus('Totalprothese, pro Kiefer').art, Bezugsgroesse.kiefer);
      expect(bezugAus('Pulpaexstirpation, 1 Kanal').art, Bezugsgroesse.kanal);
      expect(bezugAus('Schliffkorrektur, pro Zahn').art, Bezugsgroesse.zahn);
    });

    test('verwechselt "Zahn" im Wort nicht mit "pro Zahn"', () {
      // Sonst wäre jede zweite Position eine Zahnposition.
      expect(bezugAus('Zahnsteinentfernung').art, Bezugsgroesse.unbekannt);
      expect(bezugAus('Zahnreinigung').art, Bezugsgroesse.unbekannt);
    });

    test('schweigt, wo nichts dasteht', () {
      // Der häufige Fall: Die Praxis druckt eine Kurzbezeichnung ohne Einheit.
      expect(bezugAus('Kurzbefundaufnahme').istBekannt, isFalse);
      expect(bezugAus('').istBekannt, isFalse);
    });
  });

  group('Zeitabrechnung', () {
    test('addiert Anzahl mal Takt', () {
      final zeit = Zeitabrechnung.aus([
        _zeile('DH-Behandlung, pro 5 Min.', menge: 12),
        _zeile('Konsilium, pro 15 Min.', menge: 2),
        _zeile('Kompositfüllung, einflächig', menge: 1),
      ]);

      expect(zeit.gesamt, const Duration(minutes: 90));
      expect(zeit.zeilen, hasLength(2));
      expect(zeit.istVollstaendig, isTrue);
      expect(zeit.alsText, '1 Stunde 30 Minuten');
    });

    test('meldet sich als unvollständig, wenn eine Menge fehlt', () {
      // Eine zu kleine Zeitsumme sähe nach einer harmlosen Rechnung aus.
      final zeit = Zeitabrechnung.aus([
        _zeile('DH-Behandlung, pro 5 Min.', menge: 6),
        _zeile('DH-Behandlung, pro 5 Min.'),
      ]);

      expect(zeit.gesamt, const Duration(minutes: 30));
      expect(zeit.istVollstaendig, isFalse);
    });

    test('ohne Zeitpositionen bleibt sie leer', () {
      final zeit = Zeitabrechnung.aus([_zeile('Kurzbefundaufnahme', menge: 1)]);
      expect(zeit.istLeer, isTrue);
      expect(zeit.gesamt, Duration.zero);
    });
  });

  group('qualifikationAus', () {
    test('unterscheidet DH und PA', () {
      expect(qualifikationAus('DH-Behandlung, pro 5 Min.'),
          Behandlungsqualifikation.dentalhygienikerin);
      expect(qualifikationAus('Dentalhygiene'),
          Behandlungsqualifikation.dentalhygienikerin);
      expect(qualifikationAus('PA-Behandlung, pro 5 Min.'),
          Behandlungsqualifikation.prophylaxeassistentin);
      expect(qualifikationAus('Prophylaxeassistentin, pro 5 Min.'),
          Behandlungsqualifikation.prophylaxeassistentin);
    });

    test('rät nicht', () {
      expect(qualifikationAus('Kompositfüllung, einflächig'),
          Behandlungsqualifikation.unbekannt);
    });
  });

  group('an einer echten Rechnung', () {
    test('die vorliegende Rechnung nennt keine Einheiten', () {
      // Ernüchternd, aber wichtig festzuhalten: Diese Praxissoftware druckt
      // Kurzbezeichnungen ohne Bezugsgrösse. Nur "einflächig" ist zu holen.
      // Genau deshalb darf die Regel nichts behaupten, wo nichts dasteht.
      final katalog = TariffCatalog.fromJsonString(
          File('assets/reference-data/dentotar_seed.json').readAsStringSync());
      final analyse = analyzeInvoice(_fixture('ocr_kostenvoranschlag.json'), katalog);
      final erkannt = <String, Bezugsgroesse>{
        for (final line in analyse.lines)
          line.description: bezugAus(line.description).art,
      };

      expect(erkannt.values.where((a) => a == Bezugsgroesse.flaeche), isNotEmpty,
          reason: 'die einflächige Kompositfüllung ist zu erkennen');
      expect(Zeitabrechnung.aus(analyse.lines).istLeer, isTrue,
          reason: 'Zeitpositionen kommen auf dieser Rechnung nicht vor');
    });
  });
}
