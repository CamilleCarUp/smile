import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/screens/sperr_screen.dart';
import 'package:smile/state/sperr_controller.dart';

import '../support/fake_biometrie.dart';

void main() {
  late FakeBiometrie sensor;

  Future<void> zeige(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SperrScreen()));
    await tester.pumpAndSettle();
  }

  setUp(() {
    sensor = FakeBiometrie();
    sperrController = SperrController(sensor: sensor)..beimStart(aktiv: true);
  });

  testWidgets('fragt von selbst, ohne dass jemand tippen muss', (tester) async {
    await zeige(tester);

    expect(sensor.abfragen, 1);
    expect(sperrController.istGesperrt, isFalse);
  });

  testWidgets('nach einem Abbruch bleibt die Sperre stehen', (tester) async {
    sensor.erkennt = false;

    await zeige(tester);

    expect(sperrController.istGesperrt, isTrue);
    expect(find.text('Smile ist gesperrt'), findsOneWidget);
    expect(find.textContaining('Nicht erkannt'), findsOneWidget);
    expect(find.text('Nochmals versuchen'), findsOneWidget);
  });

  testWidgets('ein zweiter Versuch ist möglich', (tester) async {
    sensor.erkennt = false;
    await zeige(tester);

    sensor.erkennt = true;
    await tester.tap(find.text('Nochmals versuchen'));
    await tester.pumpAndSettle();

    expect(sensor.abfragen, 2);
    expect(sperrController.istGesperrt, isFalse);
  });

  testWidgets('nennt beide Wege hinein', (tester) async {
    // Wer den Sensor nicht nutzen kann oder mag, kommt über den Gerätecode
    // hinein — sonst wäre die Sperre eine Falle.
    sensor.erkennt = false;
    await zeige(tester);

    expect(find.textContaining('Code deines Geräts'), findsOneWidget);
  });
}
