import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/models/request.dart';
import 'package:smile/screens/results_screen.dart';
import 'package:smile/state/requests_repository.dart';

DentalRequest _request({
  required bool trustworthy,
  bool totalsMatch = true,
  bool crooked = false,
}) {
  return DentalRequest(
    id: 1,
    filename: 'foto.jpg',
    files: [UploadedFile('foto.jpg')],
    invoiceNumber: '112233',
    dentistName: 'Dr. med. dent. Max Muster',
    dentistAddress: 'Alte Gasse 13, 8005 Zürich',
    date: DateTime(2026, 2, 16),
    lines: const [
      TariffLine(
          code: '4.0020',
          description: 'Kurzbefundaufnahme',
          amountChf: 39.70,
          quantity: 1,
          taxpunkte: 33.1,
          taxpunkteFromCatalog: true),
    ],
    invoiceTotal: 39.70,
    referenceTotal: 39.70,
    statedTotal: totalsMatch ? 39.70 : 320.20,
    totalsMatch: totalsMatch,
    isTrustworthy: trustworthy,
    wasPhotographedCrooked: crooked,
  );
}

void main() {
  tearDown(() => requestsRepository.currentRequest = null);

  Future<void> zeige(WidgetTester tester, DentalRequest req) async {
    requestsRepository.currentRequest = req;
    await tester.pumpWidget(MaterialApp(home: const ResultsScreen()));
  }

  testWidgets('bei sicherem Ergebnis führt der Hauptknopf zur Rückfrage', (tester) async {
    await zeige(tester, _request(trustworthy: true));

    expect(find.text('Rückfrage vorbereiten'), findsOneWidget);
    expect(find.text('Rechnung neu aufnehmen'), findsNothing);
    expect(find.text('Diese Rechnung konnte nicht sicher gelesen werden'), findsNothing);
  });

  testWidgets('bei unsicherem Ergebnis steht die neue Aufnahme ohne Scrollen da', (tester) async {
    // Eine Rückfrage auf Grundlage einer falsch gelesenen Rechnung wäre
    // schlimmer als gar keine — deshalb tritt sie in den Hintergrund. Und der
    // Hauptknopf muss sichtbar sein, ohne dass man erst an allem vorbeiscrollt,
    // worauf man sich gerade nicht verlassen soll.
    await zeige(tester, _request(trustworthy: false, totalsMatch: false));

    expect(find.text('Diese Rechnung konnte nicht sicher gelesen werden'), findsOneWidget);
    expect(find.text('Rechnung neu aufnehmen'), findsOneWidget);
  });

  testWidgets('die Rückfrage bleibt als Nebenhandlung erreichbar', (tester) async {
    await zeige(tester, _request(trustworthy: false, totalsMatch: false));

    await tester.scrollUntilVisible(
      find.text('Trotzdem Rückfrage vorbereiten'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Trotzdem Rückfrage vorbereiten'), findsOneWidget);
  });

  testWidgets('die Hinweise nennen den erkannten Grund', (tester) async {
    await zeige(tester, _request(trustworthy: false, totalsMatch: false));

    // Summenprobe ging nicht auf -> Hinweis auf die fehlende Totalzeile.
    expect(find.textContaining('Totalzeile'), findsOneWidget);
    expect(find.textContaining('PDF-Import'), findsOneWidget);
  });

  testWidgets('bei schiefer Aufnahme wird genau das gesagt', (tester) async {
    await zeige(tester,
        _request(trustworthy: false, totalsMatch: false, crooked: true));

    expect(find.textContaining('schief aufgenommen'), findsOneWidget);
  });

  testWidgets('die Gradzahl wird nicht genannt', (tester) async {
    // "9 Grad" sagt niemandem etwas — "schief" schon.
    await zeige(tester,
        _request(trustworthy: false, totalsMatch: false, crooked: true));

    expect(find.textContaining('Grad'), findsNothing);
  });
}
