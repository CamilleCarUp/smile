// Erzeugt assets/reference-data/plz_kantone.csv aus dem Amtlichen
// Ortschaftenverzeichnis von swisstopo.
//
// Datensatz herunterladen (kostenlos, monatlich aktualisiert):
//   https://data.geo.admin.ch/ch.swisstopo-vd.ortschaftenverzeichnis_plz/
//     ortschaftenverzeichnis_plz/ortschaftenverzeichnis_plz_2056.csv.zip
//
// Aufruf aus dem Projektverzeichnis:
//   dart run tool/plz_kantone_erzeugen.dart <pfad-zur-entpackten-csv>
//
// Aus rund 5700 Zeilen (Ortschaft x Gemeinde) werden zwei Arten von
// Eintraegen: Postleitzahl -> Kanton und Ortsname -> Kanton. Der Ortsname
// faengt die Postfach-Postleitzahlen auf, die im Verzeichnis fehlen.
//
// Reicht ein Eintrag ueber eine Kantonsgrenze, entscheidet die Spalte
// "Adressenanteil": aufgenommen wird nur, wo mindestens 90 Prozent der
// Adressen im selben Kanton liegen. Der Rest bleibt weg -- die App soll
// lieber nichts sagen als das Falsche.

import 'dart:io';

import 'package:smile/data/ort_schluessel.dart';

/// Ab diesem Anteil gilt ein Kanton als der eine zustaendige.
const double schwelle = 0.9;

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Aufruf: dart run tool/plz_kantone_erzeugen.dart <csv>');
    exitCode = 64;
    return;
  }

  final quelle = File(args.first);
  if (!quelle.existsSync()) {
    stderr.writeln('Nicht gefunden: ${quelle.path}');
    exitCode = 66;
    return;
  }

  final zeilen = quelle.readAsLinesSync();
  if (zeilen.isEmpty) {
    stderr.writeln('Leere Datei.');
    exitCode = 65;
    return;
  }

  final trenner = zeilen.first.contains(';') ? ';' : ',';
  final kopf = zeilen.first.split(trenner).map(_saeubern).toList();
  final iOrt = _spalte(kopf, ['Ortschaftsname']);
  final iPlz = _spalte(kopf, ['PLZ4', 'PLZ']);
  final iKanton = _spalte(kopf, ['Kantonskürzel', 'Kantonskuerzel', 'Kanton']);
  final iAnteil = _spalte(kopf, ['Adressenanteil']);
  if (iOrt < 0 || iPlz < 0 || iKanton < 0 || iAnteil < 0) {
    stderr.writeln('Spalten nicht gefunden. Kopfzeile: ${kopf.join(" | ")}');
    exitCode = 65;
    return;
  }

  final nachPlz = <String, Map<String, double>>{};
  final nachOrt = <String, Map<String, double>>{};
  for (final zeile in zeilen.skip(1)) {
    if (zeile.trim().isEmpty) continue;
    final felder = zeile.split(trenner).map(_saeubern).toList();
    if (felder.length <= iAnteil) continue;

    final kanton = felder[iKanton].trim().toUpperCase();
    // Liechtensteiner Ortschaften stehen ohne Kanton im Verzeichnis.
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(kanton)) continue;

    final anteil =
        double.tryParse(felder[iAnteil].replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

    final plz = felder[iPlz].trim();
    if (RegExp(r'^[1-9]\d{3}$').hasMatch(plz)) {
      _zaehle(nachPlz, plz, kanton, anteil);
    }
    final ort = ortSchluessel(felder[iOrt]);
    if (ort.isNotEmpty) _zaehle(nachOrt, ort, kanton, anteil);
  }

  final plzKlar = <String, String>{};
  final plzOffen = <String>[];
  _entscheide(nachPlz, plzKlar, plzOffen);

  final ortKlar = <String, String>{};
  final ortOffen = <String>[];
  _entscheide(nachOrt, ortKlar, ortOffen);

  final puffer = StringBuffer()
    ..writeln('# Zuordnung zu Kantonen, erzeugt aus dem Amtlichen Ortschaftenverzeichnis')
    ..writeln('# von swisstopo (AMTOVZ_CSV_LV95) mit tool/plz_kantone_erzeugen.dart.')
    ..writeln('# Nicht von Hand bearbeiten.')
    ..writeln('#')
    ..writeln('# Zwei Arten von Zeilen:')
    ..writeln('#   8005,ZH      Postleitzahl -> Kanton')
    ..writeln('#   zurich,ZH    Ortsname (normalisiert) -> Kanton')
    ..writeln('# Der Ortsname faengt die Postfach-Postleitzahlen auf, die im')
    ..writeln('# Ortschaftenverzeichnis fehlen (3000 Bern, 1211 Geneve und weitere).')
    ..writeln('#')
    ..writeln('# Reicht ein Eintrag ueber eine Kantonsgrenze, entscheidet der')
    ..writeln('# Adressenanteil: aufgenommen wird nur, wo mindestens '
        '${(schwelle * 100).round()} Prozent der')
    ..writeln('# Adressen im selben Kanton liegen.')
    ..writeln('# Postleitzahlen: ${plzKlar.length} (ausgelassen: '
        '${plzOffen.length} -- ${plzOffen.join(", ")})')
    ..writeln('# Ortsnamen: ${ortKlar.length} (ausgelassen: '
        '${ortOffen.length} -- ${ortOffen.join(", ")})');
  plzKlar.forEach((plz, kanton) => puffer.writeln('$plz,$kanton'));
  ortKlar.forEach((ort, kanton) => puffer.writeln('$ort,$kanton'));

  File('assets/reference-data/plz_kantone.csv')
      .writeAsStringSync(puffer.toString());
  stdout.writeln('${plzKlar.length} Postleitzahlen und ${ortKlar.length} '
      'Ortsnamen geschrieben, ${plzOffen.length + ortOffen.length} ausgelassen.');
}

void _zaehle(Map<String, Map<String, double>> nach, String schluessel,
    String kanton, double anteil) {
  final eintrag = nach.putIfAbsent(schluessel, () => <String, double>{});
  eintrag[kanton] = (eintrag[kanton] ?? 0) + anteil;
}

void _entscheide(Map<String, Map<String, double>> nach,
    Map<String, String> klar, List<String> offen) {
  final schluessel = nach.keys.toList()..sort();
  for (final s in schluessel) {
    final anteile = nach[s]!;
    final summe = anteile.values.fold<double>(0, (a, b) => a + b);
    if (summe <= 0) {
      offen.add(s);
      continue;
    }
    var bester = '';
    var bestwert = 0.0;
    anteile.forEach((kanton, wert) {
      if (wert > bestwert) {
        bester = kanton;
        bestwert = wert;
      }
    });
    if (bestwert / summe >= schwelle) {
      klar[s] = bester;
    } else {
      offen.add(s);
    }
  }
}

String _saeubern(String feld) {
  var f = feld.trim().replaceAll('﻿', '');
  if (f.length >= 2 && f.startsWith('"') && f.endsWith('"')) {
    f = f.substring(1, f.length - 1);
  }
  return f;
}

int _spalte(List<String> kopf, List<String> namen) {
  for (final name in namen) {
    final i = kopf.indexWhere((k) => k.toLowerCase() == name.toLowerCase());
    if (i >= 0) return i;
  }
  return -1;
}
