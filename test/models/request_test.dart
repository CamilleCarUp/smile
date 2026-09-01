import 'package:flutter_test/flutter_test.dart';
import 'package:smile/models/request.dart';

DentalRequest _buildRequest({List<TariffLine>? lines}) {
  return DentalRequest(
    id: 1,
    filename: 'Rechnung_Test.pdf',
    files: [UploadedFile('Rechnung_Test.pdf')],
    invoiceNumber: '999999',
    dentistName: 'Dr. med. dent. Test Zahnarzt',
    dentistAddress: 'Teststrasse 1, 8000 Zürich',
    date: DateTime(2026, 1, 1),
    lines: lines ??
        const [
          TariffLine(code: '4.0020', description: 'Untersuchung', amountChf: 40.0),
          TariffLine(code: '4.0650', description: 'Anästhesie', amountChf: 46.0, flagged: true),
        ],
    invoiceTotal: 86.0,
    referenceTotal: 40.0,
  );
}

void main() {
  group('DentalRequest', () {
    test('flaggedLines enthält nur als abweichend markierte Positionen', () {
      final req = _buildRequest();
      expect(req.flaggedLines, hasLength(1));
      expect(req.flaggedLines.single.code, '4.0650');
    });

    test('flaggedLines ist leer, wenn keine Position markiert ist', () {
      final req = _buildRequest(lines: const [
        TariffLine(code: '4.0020', description: 'Untersuchung', amountChf: 40.0),
      ]);
      expect(req.flaggedLines, isEmpty);
    });

    test('difference ist invoiceTotal minus referenceTotal', () {
      final req = _buildRequest();
      expect(req.difference, closeTo(46.0, 0.001));
    });

    test('startet standardmässig im Status "captured"', () {
      final req = _buildRequest();
      expect(req.status, RequestStatus.captured);
    });
  });

  group('UploadedFile', () {
    test('recognizedText ist anfangs unbesetzt und danach änderbar', () {
      final f = UploadedFile('Foto.jpg', path: '/tmp/foto.jpg');
      expect(f.recognizedText, isNull);
      f.recognizedText = 'erkannter Text';
      expect(f.recognizedText, 'erkannter Text');
    });
  });
}
