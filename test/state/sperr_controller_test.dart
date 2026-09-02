import 'package:flutter_test/flutter_test.dart';
import 'package:smile/state/sperr_controller.dart';

import '../support/fake_biometrie.dart';

void main() {
  late FakeBiometrie sensor;
  late SperrController sperre;

  setUp(() {
    sensor = FakeBiometrie();
    sperre = SperrController(sensor: sensor);
  });

  test('ohne eingeschaltete Sperre startet die App offen', () {
    sperre.beimStart(aktiv: false);
    expect(sperre.istGesperrt, isFalse);
  });

  test('mit eingeschalteter Sperre startet die App gesperrt', () {
    sperre.beimStart(aktiv: true);
    expect(sperre.istGesperrt, isTrue);
  });

  test('erkannt heisst offen', () async {
    sperre.beimStart(aktiv: true);

    expect(await sperre.entsperren(), isTrue);
    expect(sperre.istGesperrt, isFalse);
    expect(sensor.abfragen, 1);
  });

  test('abgelehnt heisst zu', () async {
    sensor.erkennt = false;
    sperre.beimStart(aktiv: true);

    expect(await sperre.entsperren(), isFalse);
    expect(sperre.istGesperrt, isTrue,
        reason: 'Ein Abbruch darf den Verlauf nicht freigeben.');
  });

  test('beim Wechsel in den Hintergrund wird wieder zugesperrt', () async {
    sperre.beimStart(aktiv: true);
    await sperre.entsperren();
    expect(sperre.istGesperrt, isFalse);

    sperre.inDenHintergrund(aktiv: true);

    expect(sperre.istGesperrt, isTrue);
  });

  test('ohne eingeschaltete Sperre passiert im Hintergrund nichts', () async {
    sperre.beimStart(aktiv: false);
    sperre.inDenHintergrund(aktiv: false);
    expect(sperre.istGesperrt, isFalse);
  });

  test('die laufende Abfrage sperrt sich nicht selbst zu', () async {
    // Der Systemdialog schiebt die App selbst kurz in den Hintergrund. Wuerde
    // das zusperren, käme man aus der Schlaufe nie heraus.
    sperre.beimStart(aktiv: true);
    await sperre.entsperren();

    final laeuft = sperre.entsperren();
    sperre.inDenHintergrund(aktiv: true);

    expect(await laeuft, isTrue);
    expect(sperre.istGesperrt, isFalse);
  });

  test('meldet, ob das Gerät überhaupt sperren kann', () async {
    expect(await sperre.istMoeglich(), isTrue);
    sensor.moeglich = false;
    expect(await sperre.istMoeglich(), isFalse);
  });
}
