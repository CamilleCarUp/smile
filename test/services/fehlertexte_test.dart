import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/services/fehlertexte.dart';

void main() {
  group('Kamera', () {
    test('verweigerter Zugriff sagt, wo man ihn freigibt', () {
      final text = kameraFehlerText(
          PlatformException(code: 'camera_access_denied', message: 'denied'));

      expect(text, contains('Berechtigungen'));
      expect(text, contains('Galerie'), reason: 'es braucht einen Ausweg');
      expect(text, isNot(contains('PlatformException')));
    });

    test('kein Sensor nennt die Alternativen', () {
      final text = kameraFehlerText(PlatformException(code: 'no_available_camera'));

      expect(text, contains('keine Kamera'));
      expect(text, contains('PDF'));
    });

    test('unbekannte Ursache bleibt brauchbar', () {
      // Die technische Ursache bleibt dran -- klein und am Schluss.
      final text = kameraFehlerText(PlatformException(code: 'irgendwas_neues'));

      expect(text, startsWith('Die Kamera liess sich nicht öffnen'));
      expect(text, contains('irgendwas_neues'));
    });

    test('auch ein gewöhnlicher Fehler ergibt einen Satz', () {
      expect(kameraFehlerText(StateError('kaputt')),
          startsWith('Die Kamera liess sich nicht öffnen'));
    });
  });

  group('Galerie', () {
    test('verweigerter Zugriff nennt die Kamera als Ausweg', () {
      final text = galerieFehlerText(PlatformException(code: 'photo_access_denied'));

      expect(text, contains('Einstellungen'));
      expect(text, contains('Kamera'));
    });
  });

  group('PDF', () {
    test('geschütztes Dokument wird als solches benannt', () {
      expect(pdfFehlerText(Exception('PdfException: password required')),
          contains('geschützt'));
    });

    test('voller Speicher wird als solcher benannt', () {
      expect(
          pdfFehlerText(const FileSystemException(
              'write failed', '/tmp', OSError('ENOSPC: no space left on device', 28))),
          contains('kein Platz'));
    });

    test('sonst der Rat, die Rechnung abzufotografieren', () {
      expect(pdfFehlerText(StateError('irgendwas')), contains('fotografiere'));
    });
  });
}
