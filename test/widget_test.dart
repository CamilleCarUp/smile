// Smoke-Test: wo die App startet.
//
// Zwei Wege: Beim allerersten Start fragt sie nach dem Namen, danach fuehrt
// sie direkt zu den Aktionen. Eine Anmeldung gibt es bewusst nicht -- es gibt
// kein Konto und nichts, was sie schuetzen wuerde.
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/main.dart';
import 'package:smile/models/user_profile.dart';
import 'package:smile/state/profile_controller.dart';

import 'support/fake_store.dart';

void main() {
  setUp(() => profileController = ProfileController(store: FakeStore()));

  testWidgets('beim ersten Start wird nach dem Namen gefragt', (tester) async {
    await tester.pumpWidget(const SmileApp());

    expect(find.text('Vorname'), findsOneWidget);
    expect(find.text('Nachname'), findsOneWidget);
    expect(find.text('Rechnung prüfen'), findsNothing,
        reason: 'Ohne Namen gibt es noch nichts zu tun.');
  });

  testWidgets('mit hinterlegtem Namen startet die App bei den Aktionen',
      (tester) async {
    profileController.profile =
        const UserProfile(firstName: 'Toni', lastName: 'Maloni');

    await tester.pumpWidget(const SmileApp());

    expect(find.text('Rechnung prüfen'), findsOneWidget);
    expect(find.text('Kostenschätzung'), findsOneWidget);
    expect(find.text('Meine Anfragen'), findsOneWidget);
  });

  testWidgets('es gibt keine Anmelde- oder Registrierungsmaske', (tester) async {
    profileController.profile =
        const UserProfile(firstName: 'Toni', lastName: 'Maloni');

    await tester.pumpWidget(const SmileApp());

    expect(find.text('Anmelden'), findsNothing);
    expect(find.text('Registrieren'), findsNothing);
  });

  testWidgets('das Datenschutz-Versprechen steht auf dem Startbildschirm',
      (tester) async {
    profileController.profile =
        const UserProfile(firstName: 'Toni', lastName: 'Maloni');

    await tester.pumpWidget(const SmileApp());

    expect(find.textContaining('kein Konto'), findsOneWidget);
  });
}
