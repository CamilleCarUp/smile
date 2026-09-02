import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/ort_schluessel.dart';
import 'package:smile/data/plz_verzeichnis.dart';

void main() {
  group('ortSchluessel', () {
    test('löst Umlaute und Akzente auf', () {
      expect(ortSchluessel('Zürich'), 'zurich');
      expect(ortSchluessel('Genève'), 'geneve');
      expect(ortSchluessel('Delémont'), 'delemont');
    });

    test('macht aus allem anderen Trenner', () {
      expect(ortSchluessel('St. Gallen'), 'st gallen');
      expect(ortSchluessel('La Chaux-de-Fonds'), 'la chaux de fonds');
      expect(ortSchluessel('Ibach (SZ)'), 'ibach sz');
      // Manche Briefköpfe hängen die Zustellnummer an.
      expect(ortSchluessel('8004 Zürich 4'), 'zurich');
      expect(ortSchluessel('  Bern  '), 'bern');
    });
  });

  group('PlzVerzeichnis', () {
    test('liest beide Arten von Zeilen', () {
      final v = PlzVerzeichnis.ausText('8005,ZH\nzurich,ZH\n3011,BE\nbern,BE\n');
      expect(v.anzahlPlz, 2);
      expect(v.anzahlOrte, 2);
      expect(v.kanton(plz: '8005'), 'ZH');
      expect(v.kanton(ort: 'Bern'), 'BE');
    });

    test('überspringt Kommentare, Leerzeilen und Unsinn', () {
      final v = PlzVerzeichnis.ausText('''
# Kommentar

8005,ZH
0000,ZH
9490,
6300,ZG,Zug
''');
      expect(v.kanton(plz: '8005'), 'ZH');
      // Vierstellig ab 1000, zweistelliges Kürzel, sonst nichts.
      expect(v.kanton(plz: '0000'), isNull);
      expect(v.kanton(plz: '9490'), isNull);
      // Zusätzliche Spalten stören nicht.
      expect(v.kanton(plz: '6300'), 'ZG');
    });

    test('der Ortsname springt ein, wenn die Postleitzahl fehlt', () {
      // Postfach-Postleitzahlen stehen nicht im Ortschaftenverzeichnis.
      final v = PlzVerzeichnis.ausText('3011,BE\nbern,BE\n');
      expect(v.kanton(plz: '3000', ort: 'Bern'), 'BE');
    });

    test('widersprechen sich Postleitzahl und Ort, gibt es keine Antwort', () {
      // So sieht eine verdrehte Ziffer aus. Eine Ombudsstelle im falschen
      // Kanton wäre schlechter als keine.
      final v = PlzVerzeichnis.ausText('3005,BE\n8005,ZH\nzurich,ZH\nbern,BE\n');
      expect(v.kanton(plz: '3005', ort: 'Zürich'), isNull);
      expect(v.kanton(plz: '8005', ort: 'Zürich'), 'ZH');
    });

    test('unbekannt heisst null, nicht irgendein Kanton', () {
      final v = PlzVerzeichnis.ausText('8005,ZH');
      expect(v.kanton(plz: '1234'), isNull);
      expect(v.kanton(ort: 'Entenhausen'), isNull);
      expect(v.kanton(), isNull);
    });

    test('ohne Tabelle bleibt das Verzeichnis leer statt zu raten', () {
      final v = PlzVerzeichnis.ausText('# nur ein Kommentar\n');
      expect(v.istLeer, isTrue);
      expect(v.kanton(plz: '8005'), isNull);
    });
  });

  group('die mitgelieferte Tabelle', () {
    // Gegen die echte Datei, nicht gegen ausgedachte Zeilen: Sie wird von
    // einem Werkzeug erzeugt, und ein Fehler darin fiele sonst erst auf dem
    // Gerät auf.
    final datei = File('assets/reference-data/plz_kantone.csv');
    final verzeichnis = PlzVerzeichnis.ausText(datei.readAsStringSync());

    test('deckt die Schweiz ab', () {
      expect(verzeichnis.anzahlPlz, greaterThan(3000));
      expect(verzeichnis.anzahlOrte, greaterThan(3800));
    });

    test('trifft die Kantone bekannter Orte', () {
      expect(verzeichnis.kanton(plz: '8005', ort: 'Zürich'), 'ZH');
      expect(verzeichnis.kanton(plz: '6500', ort: 'Bellinzona'), 'TI');
      expect(verzeichnis.kanton(plz: '9016', ort: 'St. Gallen'), 'SG');
      expect(verzeichnis.kanton(plz: '2800', ort: 'Delémont'), 'JU');
      // Frauenfeld teilt sich die 8500 mit Zürcher Gemeinden -- der
      // Adressenanteil entscheidet.
      expect(verzeichnis.kanton(plz: '8500', ort: 'Frauenfeld'), 'TG');
    });

    test('fängt Postfach-Postleitzahlen über den Ort auf', () {
      // 3000 Bern und 1211 Genève sind reine Postfach-Postleitzahlen und
      // stehen nicht im Ortschaftenverzeichnis.
      expect(verzeichnis.kanton(plz: '3000'), isNull);
      expect(verzeichnis.kanton(plz: '3000', ort: 'Bern'), 'BE');
      expect(verzeichnis.kanton(plz: '1211', ort: 'Genève'), 'GE');
    });

    test('enthält nur normalisierte Schlüssel', () {
      // Erzeugendes Werkzeug und App müssen dieselbe Normalform verwenden;
      // sonst findet die App die Ortsnamen nie.
      for (final zeile in datei.readAsLinesSync()) {
        final t = zeile.trim();
        if (t.isEmpty || t.startsWith('#')) continue;
        final felder = t.split(',');
        expect(felder, hasLength(2), reason: zeile);
        final schluessel = felder[0];
        final istPlz = RegExp(r'^[1-9]\d{3}$').hasMatch(schluessel);
        if (!istPlz) {
          expect(ortSchluessel(schluessel), schluessel,
              reason: 'nicht normalisiert: $zeile');
        }
        expect(RegExp(r'^[A-Z]{2}$').hasMatch(felder[1]), isTrue, reason: zeile);
      }
    });
  });
}
