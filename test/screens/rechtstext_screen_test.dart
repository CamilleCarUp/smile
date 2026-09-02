import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/rechtstexte.dart';
import 'package:smile/screens/about_screen.dart';
import 'package:smile/screens/rechtstext_screen.dart';

void main() {
  /// Die Texte sind laenger als ein Testfenster. Was nicht sichtbar ist, ist
  /// in einer ListView auch nicht gebaut -- also hinscrollen statt suchen.
  Future<void> hinScrollen(WidgetTester tester, Finder ziel) =>
      tester.scrollUntilVisible(ziel, 200,
          scrollable: find.byType(Scrollable).first);

  testWidgets('der Datenschutztext wird vollständig angezeigt', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: RechtstextScreen(text: Rechtstexte.datenschutz)));

    expect(find.text('Datenschutz'), findsOneWidget);
    for (final abschnitt in Rechtstexte.datenschutz.abschnitte) {
      await hinScrollen(tester, find.text(abschnitt.titel));
      expect(find.text(abschnitt.titel), findsOneWidget);
    }
    // Kein Platzhalter, also auch kein Warnhinweis.
    expect(find.textContaining('noch nicht fertig'), findsNothing);
  });

  testWidgets('ein unvollständiger Text sagt es selbst', (tester) async {
    // Ein leeres Impressum fällt sonst erst jemand anderem auf — im
    // schlimmsten Fall einer Behörde.
    await tester.pumpWidget(
        const MaterialApp(home: RechtstextScreen(text: Rechtstexte.impressum)));

    expect(find.textContaining('noch nicht fertig'), findsOneWidget);
    expect(find.textContaining('‹Kontaktadresse›'), findsOneWidget);
  });

  testWidgets('alle drei Texte sind aus "Wie Smile funktioniert" erreichbar',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

    for (final text in Rechtstexte.alle) {
      await tester.scrollUntilVisible(find.text(text.titel), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text(text.titel), findsOneWidget);
    }

    await tester.tap(find.text('Haftung und Grenzen'));
    await tester.pumpAndSettle();

    await hinScrollen(tester, find.text('Kein Medizinprodukt'));
    expect(find.text('Kein Medizinprodukt'), findsOneWidget);
  });
}
