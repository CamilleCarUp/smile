// Reine Logik-Tests -- laufen ohne Geraet/Emulator in Millisekunden,
// da invoice_matcher.dart keine Flutter-Abhaengigkeit hat.
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/logic/invoice_matcher.dart';

void main() {
  group('analyzeInvoiceDemo', () {
    test('liefert die sechs Demo-Positionen aus dem Klickdummy', () {
      final result = analyzeInvoiceDemo();
      expect(result.lines, hasLength(6));
    });

    test('markiert genau die doppelt verrechnete Infiltrationsanästhesie', () {
      final result = analyzeInvoiceDemo();
      final flagged = result.lines.where((l) => l.flagged).toList();
      expect(flagged, hasLength(1));
      expect(flagged.single.code, '4.0650');
    });

    test('invoiceTotal ist die Summe aller Positionen', () {
      final result = analyzeInvoiceDemo();
      final expectedTotal = result.lines.fold(0.0, (sum, l) => sum + l.amountChf);
      expect(result.invoiceTotal, closeTo(expectedTotal, 0.001));
    });

    test('referenceTotal zieht die markierten Positionen vom invoiceTotal ab', () {
      final result = analyzeInvoiceDemo();
      final flaggedSum = result.lines.where((l) => l.flagged).fold(0.0, (sum, l) => sum + l.amountChf);
      expect(result.referenceTotal, closeTo(result.invoiceTotal - flaggedSum, 0.001));
    });

    test('difference entspricht invoiceTotal minus referenceTotal', () {
      final result = analyzeInvoiceDemo();
      expect(result.difference, closeTo(result.invoiceTotal - result.referenceTotal, 0.001));
    });
  });
}
