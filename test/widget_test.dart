// Smoke-Test: die App startet und zeigt den Einstiegsbildschirm.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smile/main.dart';

void main() {
  testWidgets('SmileApp startet auf dem Entry-Screen mit Login/Registrieren',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmileApp());

    expect(find.text('Anmelden'), findsOneWidget);
    expect(find.text('Registrieren'), findsOneWidget);
  });
}
