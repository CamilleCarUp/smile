import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/ombudsman_data.dart';
import 'package:smile/data/swiss_cantons.dart';
import 'package:smile/models/user_profile.dart';
import 'package:smile/screens/ombudsman_screen.dart';
import 'package:smile/state/profile_controller.dart';

import '../support/fake_store.dart';

void main() {
  setUp(() => profileController = ProfileController(store: FakeStore()));

  Future<void> zeige(WidgetTester tester, {String? praxisKanton, String? praxisOrt}) =>
      tester.pumpWidget(MaterialApp(
          home: OmbudsmanScreen(praxisKanton: praxisKanton, praxisOrt: praxisOrt)));

  group('Zuordnung der Kantone', () {
    test('jede Stelle nennt mindestens einen Kanton', () {
      for (final stelle in ombudsmanContacts) {
        expect(stelle.cantons, isNotEmpty, reason: 'Stelle ${stelle.region}');
      }
    });

    test('kein Kanton hat zwei zuständige Stellen', () {
      // Zwei Treffer hiessen, dass die App raten müsste.
      for (final kanton in swissCantons) {
        final treffer =
            ombudsmanContacts.where((c) => c.covers(kanton.code)).length;
        expect(treffer, lessThanOrEqualTo(1), reason: 'Kanton ${kanton.code}');
      }
    });

    test('St. Gallen deckt beide Appenzell mit ab', () {
      final sg = ombudsmanContacts.firstWhere((c) => c.covers('SG'));
      expect(sg.covers('AR'), isTrue);
      expect(sg.covers('AI'), isTrue);
    });

    test('die bekannten Lücken sind genau drei', () {
      // Für Nidwalden, Obwalden und Uri ist keine eigene Stelle bekannt.
      // Ändert sich das, soll dieser Test daran erinnern.
      final ohne = swissCantons
          .where((k) => !ombudsmanContacts.any((c) => c.covers(k.code)))
          .map((k) => k.code)
          .toList();
      expect(ohne, ['NW', 'OW', 'UR']);
    });
  });

  group('Anzeige', () {
    testWidgets('ohne hinterlegten Kanton kommt ein Hinweis darauf', (tester) async {
      await zeige(tester);

      expect(find.textContaining('Meine Angaben'), findsOneWidget);
      expect(find.textContaining('Für Zürich'), findsNothing);
    });

    testWidgets('mit Kanton steht die zuständige Stelle zuoberst', (tester) async {
      profileController.profile = const UserProfile(
          firstName: 'Toni', lastName: 'Maloni', canton: 'ZH');

      await zeige(tester);

      expect(find.text('Für Zürich'), findsOneWidget);
      // Die Stelle erscheint einmal oben und nicht nochmals in der Restliste.
      expect(find.text('Zürich'), findsOneWidget);
    });

    testWidgets('der Hinweis auf den Praxiskanton fehlt nicht', (tester) async {
      // Zuständig ist die Stelle im Kanton der Praxis, nicht des Wohnorts —
      // wer auswärts behandelt wird, würde sonst an die falsche geraten.
      profileController.profile = const UserProfile(
          firstName: 'Toni', lastName: 'Maloni', canton: 'ZH');

      await zeige(tester);

      expect(find.textContaining('Kanton der Praxis'), findsOneWidget);
    });

    testWidgets('der Kanton der Praxis sticht den aus dem Profil', (tester) async {
      // Wer in Zürich wohnt und sich in Bern behandeln lässt, gehört an die
      // Berner Stelle -- die Rechnung weiss das besser als das Profil.
      profileController.profile = const UserProfile(
          firstName: 'Toni', lastName: 'Maloni', canton: 'ZH');

      await zeige(tester, praxisKanton: 'BE', praxisOrt: '3000 Bern');

      expect(find.text('Für die Praxis in 3000 Bern'), findsOneWidget);
      expect(find.textContaining('aus der Rechnung gelesen'), findsOneWidget);
      // Die Berner Stelle steht oben und nicht nochmals in der Restliste.
      expect(find.text('Bern'), findsOneWidget);
    });

    testWidgets('ohne Profil reicht der Kanton aus der Rechnung', (tester) async {
      await zeige(tester, praxisKanton: 'ZH', praxisOrt: '8005 Zürich');

      expect(find.text('Für die Praxis in 8005 Zürich'), findsOneWidget);
      expect(find.textContaining('Meine Angaben'), findsNothing);
    });

    testWidgets('für einen Kanton ohne Stelle wird das gesagt', (tester) async {
      profileController.profile = const UserProfile(
          firstName: 'Toni', lastName: 'Maloni', canton: 'UR');

      await zeige(tester);

      expect(find.textContaining('keine eigene Stelle'), findsOneWidget);
    });
  });
}
