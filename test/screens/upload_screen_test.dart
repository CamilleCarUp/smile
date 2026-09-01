// Regressionstest fuer einen frueheren Bug: der "Rechnung analysieren"-Button
// blieb dauerhaft deaktiviert, weil sein onPressed-Status ausserhalb eines
// AnimatedBuilder berechnet wurde und dadurch nicht neu gebaut wurde, wenn
// eine Datei hinzugefuegt wurde. Dieser Test faengt genau diese Bug-Klasse ab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/screens/upload_screen.dart';
import 'package:smile/state/upload_controller.dart';

void main() {
  setUp(() => uploadController.reset());
  tearDown(() => uploadController.reset());

  testWidgets(
      '"Rechnung analysieren" ist ohne Datei deaktiviert und wird aktiviert, '
      'sobald eine Datei hinzugefügt wird', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: UploadScreen()));

    final buttonFinder = find.widgetWithText(ElevatedButton, 'Rechnung analysieren');
    expect(buttonFinder, findsOneWidget);

    ElevatedButton button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull,
        reason: 'Ohne hochgeladene Datei muss der Button deaktiviert sein.');

    // Simuliert das Ergebnis von Kamera/Galerie/PDF-Import, ohne echte
    // Platform-Picker aufzurufen (die im Test keine Plattform-Kanäle haben).
    uploadController.addUploadedFile('Testrechnung.jpg', path: '/tmp/testrechnung.jpg');
    await tester.pump();

    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNotNull,
        reason: 'Regression: der Button muss reagieren, sobald sich der '
            'UploadController ändert, nicht erst nach einem manuellen Rebuild.');
  });

  testWidgets('Leere Dateiliste zeigt den Platzhaltertext', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: UploadScreen()));
    expect(find.text('Noch keine Datei ausgewählt.'), findsOneWidget);
  });

  testWidgets('Hochgeladene Datei wird in der Liste angezeigt', (WidgetTester tester) async {
    uploadController.addUploadedFile('Testrechnung.jpg', path: '/tmp/testrechnung.jpg');
    await tester.pumpWidget(const MaterialApp(home: UploadScreen()));
    expect(find.text('Testrechnung.jpg'), findsOneWidget);
  });
}
