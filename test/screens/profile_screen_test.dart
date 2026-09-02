import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/models/user_profile.dart';
import 'package:smile/screens/profile_screen.dart';
import 'package:smile/state/profile_controller.dart';
import 'package:smile/state/sperr_controller.dart';

import '../support/fake_biometrie.dart';
import '../support/fake_store.dart';

void main() {
  late FakeBiometrie sensor;

  setUp(() {
    profileController = ProfileController(store: FakeStore());
    sensor = FakeBiometrie();
    sperrController = SperrController(sensor: sensor);
  });

  Future<void> zeige(WidgetTester tester, {bool firstRun = false}) =>
      tester.pumpWidget(MaterialApp(home: ProfileScreen(firstRun: firstRun)));

  testWidgets('ohne Namen wird nicht weitergemacht', (tester) async {
    await zeige(tester, firstRun: true);

    await tester.tap(find.text("Los geht's"));
    await tester.pump();

    expect(find.text('Bitte ausfüllen'), findsNWidgets(2),
        reason: 'Vor- und Nachname sind beide Pflicht.');
    expect(profileController.profile.isComplete, isFalse);
  });

  testWidgets('ein halber Name genügt nicht', (tester) async {
    await zeige(tester, firstRun: true);

    await tester.enterText(find.byType(TextField).first, 'Toni');
    await tester.tap(find.text("Los geht's"));
    await tester.pump();

    expect(find.text('Bitte ausfüllen'), findsOneWidget);
    expect(profileController.profile.isComplete, isFalse);
  });

  testWidgets('mit Vor- und Nachname geht es weiter', (tester) async {
    await zeige(tester, firstRun: true);

    final felder = find.byType(TextField);
    await tester.enterText(felder.at(0), 'Toni');
    await tester.enterText(felder.at(1), 'Maloni');
    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();

    expect(profileController.profile.fullName, 'Toni Maloni');
    expect(find.text('Rechnung prüfen'), findsOneWidget,
        reason: 'Nach der Eingabe landet man auf dem Startbildschirm.');
  });

  testWidgets('die E-Mail bleibt freiwillig', (tester) async {
    await zeige(tester, firstRun: true);

    final felder = find.byType(TextField);
    await tester.enterText(felder.at(0), 'Toni');
    await tester.enterText(felder.at(1), 'Maloni');
    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();

    expect(profileController.profile.isComplete, isTrue);
    expect(profileController.profile.wantsCopy, isFalse);
  });

  testWidgets('später lassen sich die Angaben ändern', (tester) async {
    profileController.profile =
        const UserProfile(firstName: 'Toni', lastName: 'Maloni');

    await zeige(tester);

    expect(find.text('Speichern'), findsOneWidget);
    expect(find.text("Los geht's"), findsNothing);
    // Die bestehenden Angaben stehen zum Bearbeiten bereit.
    expect(find.text('Toni'), findsOneWidget);
    expect(find.text('Maloni'), findsOneWidget);
  });

  group('App-Sperre', () {
    testWidgets('beim ersten Start steht der Schalter nicht im Weg', (tester) async {
      await zeige(tester, firstRun: true);

      expect(find.text('App sperren'), findsNothing);
    });

    testWidgets('lässt sich einschalten und wird gespeichert', (tester) async {
      profileController.profile =
          const UserProfile(firstName: 'Toni', lastName: 'Maloni');
      await zeige(tester);

      await tester.scrollUntilVisible(find.text('App sperren'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('App sperren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(profileController.profile.appLock, isTrue);
    });

    testWidgets('ohne Sperre auf dem Gerät bleibt sie aus', (tester) async {
      // Sonst hätte der Nutzer eine Sperre, die ihn aussperrt statt zu
      // schützen.
      sensor.moeglich = false;
      profileController.profile =
          const UserProfile(firstName: 'Toni', lastName: 'Maloni');
      await zeige(tester);

      await tester.scrollUntilVisible(find.text('App sperren'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('App sperren'));
      await tester.pumpAndSettle();

      expect(find.textContaining('weder Fingerabdruck noch Code'), findsOneWidget);
      // Der Schalter selbst muss aus bleiben. Über "Speichern" zu prüfen ginge
      // hier nicht: Die Meldung liegt genau über dem Knopf -- der Tipp würde
      // ins Leere gehen und der Test aus dem falschen Grund bestehen.
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    });
  });
}
