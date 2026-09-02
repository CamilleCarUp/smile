import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smile/logic/invoice_parser.dart';
import 'package:smile/logic/praxis_ort.dart';
import 'package:smile/models/ocr_result.dart';

List<OcrPage> _fixture(String name) {
  final json =
      jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;
  return (json['pages'] as List)
      .map((p) => OcrPage.fromJson(Map<String, dynamic>.from(p as Map)))
      .toList();
}

void main() {
  group('PraxisOrt.ausAdresse', () {
    test('liest Postleitzahl und Ort aus einer gewöhnlichen Adresse', () {
      final ort = PraxisOrt.ausAdresse('Alte Gasse 13, 8005 Zürich');
      expect(ort?.plz, '8005');
      expect(ort?.ort, 'Zürich');
    });

    test('kommt mit zusammengesetzten Ortsnamen zurecht', () {
      expect(PraxisOrt.ausAdresse('Rue du Parc 1, 2300 La Chaux-de-Fonds')?.ort,
          'La Chaux-de-Fonds');
      expect(PraxisOrt.ausAdresse('Bahnhofstrasse 2, 9000 St. Gallen')?.ort,
          'St. Gallen');
    });

    test('ignoriert ein vorangestelltes Länderkürzel', () {
      final ort = PraxisOrt.ausAdresse('CH-3000 Bern');
      expect(ort?.plz, '3000');
      expect(ort?.ort, 'Bern');
    });

    test('hört auf, wo der Ortsname aufhört', () {
      // Manche Briefköpfe setzen Telefonnummer und Ort auf dieselbe Zeile.
      expect(PraxisOrt.ausAdresse('6300 Zug Tel. 041 726 20 30')?.ort, 'Zug');
      expect(PraxisOrt.ausAdresse('4054 Basel www.praxis.ch')?.ort, 'Basel');
    });

    test('findet den Ort auch im nächsten Abschnitt', () {
      // Die Texterkennung trennt Postleitzahl und Ort gelegentlich.
      final ort = PraxisOrt.ausAdresse('Alte Gasse 13, 8005, Zürich');
      expect(ort?.plz, '8005');
      expect(ort?.ort, 'Zürich');
    });

    test('erfindet nichts, wenn keine Adresse dasteht', () {
      expect(PraxisOrt.ausAdresse(null), isNull);
      expect(PraxisOrt.ausAdresse(''), isNull);
      expect(PraxisOrt.ausAdresse('Praxis nicht erkannt'), isNull);
      // Beträge und Referenznummern sind keine Postleitzahlen.
      expect(PraxisOrt.ausAdresse('Referenznummer 112233'), isNull);
      expect(PraxisOrt.ausAdresse('Total 320.20 CHF'), isNull);
    });
  });

  group('aus einer echten Rechnung', () {
    // Alle vier Aufnahmen derselben Rechnung, auch die schiefen. Der Ort der
    // Praxis entscheidet über die Ombudsstelle -- er muss auch dann noch
    // stimmen, wenn die Positionen nicht mehr aufgehen.
    const aufnahmen = {
      'gerade': 'ocr_kostenvoranschlag.json',
      'verkantet': 'ocr_kostenvoranschlag_verkantet.json',
      'stark verkantet': 'ocr_kostenvoranschlag_stark_verkantet.json',
      'mit Zeilenversatz': 'ocr_kostenvoranschlag_zeilenversatz.json',
    };

    aufnahmen.forEach((was, datei) {
      test('$was: Postleitzahl und Ort der Praxis', () {
        final invoice = invoiceParser.parse(_fixture(datei));

        expect(invoice.header.dentistPlace?.plz, '8005');
        expect(invoice.header.dentistPlace?.ort, 'Zürich');
      });
    });
  });
}
