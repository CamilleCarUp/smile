// Smoke-Test: die App startet direkt auf dem Startbildschirm.
//
// Bewusst ohne Anmeldung: Es gibt kein Konto und nichts, was eine Anmeldung
// schuetzen wuerde. Eine Maske, die nach Zugangsdaten fragt und nichts
// bewacht, waere die falsche erste Begegnung mit einer App, die
// Hemmschwellen abbauen soll.
import 'package:flutter_test/flutter_test.dart';

import 'package:smile/main.dart';

void main() {
  testWidgets('SmileApp startet ohne Anmeldung direkt bei den Aktionen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmileApp());

    expect(find.text('Rechnung prüfen'), findsOneWidget);
    expect(find.text('Kostenschätzung'), findsOneWidget);
    expect(find.text('Meine Anfragen'), findsOneWidget);
  });

  testWidgets('es gibt keine Anmelde- oder Registrierungsmaske mehr',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmileApp());

    expect(find.text('Anmelden'), findsNothing);
    expect(find.text('Registrieren'), findsNothing);
  });

  testWidgets('das Datenschutz-Versprechen steht auf dem Startbildschirm',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmileApp());

    expect(find.textContaining('kein Konto'), findsOneWidget);
  });
}
