import 'package:flutter_test/flutter_test.dart';
import 'package:smile/services/pdf_service.dart';

void main() {
  group('PdfSeiten', () {
    test('meldet, wenn nicht das ganze Dokument aufbereitet wurde', () {
      // 40 Seiten wären gut hundert Megabyte Zwischenbilder und einige
      // Minuten Texterkennung — der Nutzer muss erfahren, dass etwas fehlt.
      const teil = PdfSeiten(pfade: ['a.png', 'b.png'], seitenImDokument: 40);

      expect(teil.begrenzt, isTrue);
    });

    test('ein vollständig aufbereitetes Dokument ist nicht begrenzt', () {
      const ganz = PdfSeiten(pfade: ['a.png'], seitenImDokument: 1);

      expect(ganz.begrenzt, isFalse);
    });
  });

  test('die Obergrenze ist bewusst niedrig', () {
    // Eine Rechnung hat ein bis drei Seiten. Wer mehr schickt, schickt einen
    // Stapel — und den soll die App nicht stillschweigend durchkauen.
    expect(PdfService.maxSeiten, lessThanOrEqualTo(20));
  });
}
