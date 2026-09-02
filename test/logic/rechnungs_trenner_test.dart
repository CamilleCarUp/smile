import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/logic/rechnungs_trenner.dart';
import 'package:smile/models/ocr_result.dart';

List<OcrPage> _fixture(String name) {
  final json =
      jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;
  return (json['pages'] as List)
      .map((p) => OcrPage.fromJson(Map<String, dynamic>.from(p as Map)))
      .toList();
}

/// Eine Seite mit genau den Angaben, um die es beim Trennen geht.
///
/// Bewusst nur der Briefkopf und keine Positionen: Getestet wird hier die
/// Regel, nicht die Auswertung. Die Regel gegen echte Daten prüft der letzte
/// Test dieser Datei.
OcrPage _seite({String? referenz, String? seitenzaehler, String name = 'x.png'}) {
  final lines = <OcrTextLine>[];
  var top = 100.0;
  void zeile(String etikett, String wert) {
    lines.add(OcrTextLine(
        text: etikett,
        box: OcrBox(left: 100, top: top, right: 220, bottom: top + 14)));
    lines.add(OcrTextLine(
        text: wert,
        box: OcrBox(left: 260, top: top, right: 340, bottom: top + 14)));
    top += 24;
  }

  if (seitenzaehler != null) zeile('Seite:', seitenzaehler);
  if (referenz != null) zeile('Referenznummer:', referenz);
  lines.add(OcrTextLine(
      text: '4.5350 Kompositfüllung, einflächig',
      box: const OcrBox(left: 100, top: 300, right: 400, bottom: 316)));
  return OcrPage(sourceName: name, lines: lines);
}

void main() {
  group('Merkmale einer Seite', () {
    test('liest Referenznummer und Seitenzähler', () {
      final m = rechnungsTrenner.merkmale(_seite(referenz: '28358', seitenzaehler: '1/2'));

      expect(m.referenz, '28358');
      expect(m.nummer, 1);
      expect(m.von, 2);
    });

    test('nimmt die Referenz des Zahlteils nicht für die Rechnungsnummer', () {
      // Im QR-Zahlteil steht ein Feld "Referenz" mit einer ganz anderen
      // Nummer. Sie hier zu nehmen hiesse, jede Seite für eine eigene
      // Rechnung zu halten.
      final seite = OcrPage(sourceName: 'x.png', lines: const [
        OcrTextLine(text: 'Referenz', box: OcrBox(left: 50, top: 900, right: 110, bottom: 914)),
        OcrTextLine(
            text: '12 34560 00001 33930 00002 83585',
            box: OcrBox(left: 50, top: 920, right: 320, bottom: 936)),
      ]);

      expect(rechnungsTrenner.merkmale(seite).referenz, isNull);
    });
  });

  group('Trennen', () {
    test('verschiedene Referenznummern sind verschiedene Rechnungen', () {
      final gruppen = rechnungsTrenner.trennen([
        _seite(referenz: '28358', seitenzaehler: '1/1'),
        _seite(referenz: '28336', seitenzaehler: '1/1'),
        _seite(referenz: '28335', seitenzaehler: '1/1'),
      ]);

      expect(gruppen, hasLength(3));
      expect(gruppen.map((g) => g.referenz).toList(), ['28358', '28336', '28335']);
    });

    test('dieselbe Referenznummer bleibt eine Rechnung', () {
      final gruppen = rechnungsTrenner.trennen([
        _seite(referenz: '28358', seitenzaehler: '1/2'),
        _seite(referenz: '28358', seitenzaehler: '2/2'),
      ]);

      expect(gruppen, hasLength(1));
      expect(gruppen.single.seiten, hasLength(2));
    });

    test('ohne Nummer entscheidet der Seitenzähler', () {
      final gruppen = rechnungsTrenner.trennen([
        _seite(seitenzaehler: '1/2'),
        _seite(seitenzaehler: '2/2'),
        _seite(seitenzaehler: '1/1'),
      ]);

      expect(gruppen.map((g) => g.seiten.length).toList(), [2, 1]);
    });

    test('ohne jedes Signal wird zusammengelassen', () {
      // Im Zweifel nicht trennen: Eine zerrissene Rechnung fällt bei der
      // Summenprobe auf. Eine falsch zusammengefasste sieht richtig aus.
      final gruppen = rechnungsTrenner.trennen([_seite(), _seite()]);

      expect(gruppen, hasLength(1));
    });

    test('steht die Nummer erst auf Seite zwei, gilt sie für die Rechnung', () {
      final gruppen = rechnungsTrenner.trennen([
        _seite(seitenzaehler: '1/2'),
        _seite(referenz: '28358', seitenzaehler: '2/2'),
      ]);

      expect(gruppen, hasLength(1));
      expect(gruppen.single.referenz, '28358');
    });

    test('keine Seiten, keine Rechnung', () {
      expect(rechnungsTrenner.trennen(const []), isEmpty);
    });
  });

  group('an echten Aufzeichnungen', () {
    // Die wichtigste Prüfung: Eine gewöhnliche Rechnung darf der Trenner
    // nicht anfassen.
    for (final datei in const [
      'ocr_rechnung_mit_tp_spalten.json',
      'ocr_kostenvoranschlag.json',
      'ocr_kostenvoranschlag_verkantet.json',
      'ocr_kostenvoranschlag_stark_verkantet.json',
      'ocr_kostenvoranschlag_zeilenversatz.json',
    ]) {
      test('$datei bleibt eine Rechnung', () {
        final gruppen = rechnungsTrenner.trennen(_fixture(datei));

        expect(gruppen, hasLength(1));
        expect(gruppen.single.seiten, hasLength(1));
      });
    }

    test('die Referenznummer wird gelesen, wo sie lesbar ist', () {
      final m = rechnungsTrenner.merkmale(_fixture('ocr_rechnung_mit_tp_spalten.json').single);

      expect(m.referenz, '20001');
      expect(m.nummer, 1);
      expect(m.von, 1);
    });

    test('zwei echte Rechnungen hintereinander werden getrennt', () {
      // Zusammengesetzt aus zwei echten Aufzeichnungen — das ist genau der
      // Fall, der im PDF aus der Praxis vorkommt.
      final gruppen = rechnungsTrenner.trennen([
        ..._fixture('ocr_rechnung_mit_tp_spalten.json'),
        ..._fixture('ocr_kostenvoranschlag.json'),
      ]);

      expect(gruppen, hasLength(2),
          reason: 'Zusammen ergäben sie ein Total, das es nie gab.');
    });
  });
}
