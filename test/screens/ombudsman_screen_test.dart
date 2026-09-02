import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/ombudsman_data.dart';
import 'package:smile/data/swiss_cantons.dart';
import 'package:smile/screens/ombudsman_screen.dart';

void main() {
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
    testWidgets('ohne Ort auf der Rechnung kommt ein Hinweis darauf', (tester) async {
      await zeige(tester);

      expect(find.textContaining('kein Ort der Praxis'), findsOneWidget);
      expect(find.textContaining('Für die Praxis'), findsNothing);
    });

    testWidgets('mit Kanton steht die zuständige Stelle zuoberst', (tester) async {
      await zeige(tester, praxisKanton: 'ZH', praxisOrt: '8005 Zürich');

      expect(find.text('Für die Praxis in 8005 Zürich'), findsOneWidget);
      // Die Stelle erscheint einmal oben und nicht nochmals in der Restliste.
      expect(find.text('Zürich'), findsOneWidget);
    });

    testWidgets('der Hinweis auf den Praxiskanton fehlt nicht', (tester) async {
      // Zuständig ist die Stelle im Kanton der Praxis, nicht des Wohnorts —
      // wer auswärts behandelt wird, würde sonst an die falsche geraten.
      await zeige(tester, praxisKanton: 'BE', praxisOrt: '3011 Bern');

      expect(find.textContaining('Kanton der Praxis'), findsOneWidget);
      expect(find.text('Bern'), findsOneWidget);
    });

    testWidgets('für einen Kanton ohne Stelle wird das gesagt', (tester) async {
      await zeige(tester, praxisKanton: 'UR', praxisOrt: '6460 Altdorf');

      expect(find.textContaining('keine eigene Stelle'), findsOneWidget);
    });
  });
}
