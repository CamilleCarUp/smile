import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/erklaerungen.dart';
import 'package:smile/models/request.dart';
import 'package:smile/screens/behandlung_screen.dart';
import 'package:smile/state/requests_repository.dart';

import '../support/fake_store.dart';

DentalRequest _request(List<TariffLine> lines) => DentalRequest(
      id: 1,
      filename: 'Rechnung',
      files: [UploadedFile('foto.jpg')],
      invoiceNumber: '112233',
      dentistName: 'Dr. med. dent. Max Muster',
      dentistAddress: '',
      date: DateTime(2026, 2, 17),
      lines: lines,
      invoiceTotal: lines.fold(0.0, (s, l) => s + l.amountChf),
      referenceTotal: 0,
      factor: 1.20,
      totalsMatch: true,
      isTrustworthy: true,
    );

void main() {
  setUp(() => requestsRepository = RequestsRepository(store: FakeStore()));
  tearDown(() => requestsRepository.currentRequest = null);

  Future<void> zeige(WidgetTester tester, List<TariffLine> lines) async {
    requestsRepository.currentRequest = _request(lines);
    await tester.pumpWidget(const MaterialApp(home: BehandlungScreen()));
  }

  Future<void> nachUnten(WidgetTester tester, Finder ziel) => tester
      .scrollUntilVisible(ziel, 300, scrollable: find.byType(Scrollable).first);

  testWidgets('erklärt jede Position in Alltagssprache', (tester) async {
    await zeige(tester, const [
      TariffLine(
          code: '4.5800',
          description: 'Schmelzätzung und Anbringen des Haftvermittlers',
          amountChf: 23.05,
          quantity: 1,
          taxpunkte: 19.2),
    ]);

    // Die Bezeichnung der Praxis bleibt stehen — daneben steht, was sie heisst.
    expect(find.text('Schmelzätzung und Anbringen des Haftvermittlers'), findsOneWidget);
    expect(find.textContaining('angeraut'), findsOneWidget);
  });

  testWidgets('zeigt den Rechenweg zu jedem Betrag', (tester) async {
    await zeige(tester, const [
      TariffLine(
          code: '4.0650',
          description: 'Infiltrationsanästhesie',
          amountChf: 92.20,
          quantity: 2,
          taxpunkte: 38.4),
    ]);

    await nachUnten(tester, find.textContaining('2 × 38.4 Taxpunkte'));
    expect(find.textContaining('2 × 38.4 Taxpunkte'), findsOneWidget);
    expect(find.textContaining('CHF 92.20'), findsWidgets);
  });

  testWidgets('erfindet nichts zu einer unbekannten Position', (tester) async {
    await zeige(tester, const [
      TariffLine(code: '4.9999', description: 'Irgendwas Neues', amountChf: 50),
    ]);

    expect(find.textContaining('keine Erklärung hinterlegt'), findsOneWidget);
  });

  testWidgets('gliedert die Rechnung nach Behandlungstagen', (tester) async {
    // Eine Rechnung ist ein Ablauf, keine Liste — zwei Termine, zwei Kapitel.
    await zeige(tester, [
      TariffLine(
          code: '4.0020',
          description: 'Kurzbefundaufnahme',
          amountChf: 39.70,
          date: DateTime(2026, 2, 3)),
      TariffLine(
          code: '4.5430',
          description: 'Komposit-Füllung, Molar, zweiflächig',
          amountChf: 250.20,
          date: DateTime(2026, 2, 12)),
    ]);

    expect(find.text('Behandlung vom 03.02.2026'), findsOneWidget);
    await nachUnten(tester, find.text('Behandlung vom 12.02.2026'));
    expect(find.text('Behandlung vom 12.02.2026'), findsOneWidget);
  });

  testWidgets('erklärt zuerst, wie der Preis überhaupt entsteht', (tester) async {
    await zeige(tester, const [
      TariffLine(code: '4.5350', description: 'Kompositfüllung', amountChf: 146.40),
    ]);

    expect(find.text('Wie der Preis entsteht'), findsOneWidget);
    expect(find.textContaining('1.20 Franken'), findsOneWidget);
  });

  testWidgets('sagt, was die Erklärungen nicht sind', (tester) async {
    // Ohne diesen Satz läse sich der Bildschirm wie eine Beurteilung der
    // Behandlung.
    await zeige(tester, const [
      TariffLine(code: '4.5350', description: 'Kompositfüllung', amountChf: 146.40),
    ]);

    await nachUnten(tester, find.textContaining('nicht, warum bei dir so behandelt'));
    expect(find.textContaining('nicht, warum bei dir so behandelt'), findsOneWidget);
  });

  test('zu jeder Position im Referenzkatalog gibt es eine Erklärung', () {
    // Der Katalog und die Erklärungen dürfen nicht auseinanderlaufen: Was
    // Smile nachrechnen kann, soll es auch erklären können.
    for (final code in const [
      '4.0020', '4.0650', '4.5350', '4.5370', '4.5390', '4.5410',
      '4.5430', '4.5450', '4.5470', '4.5510', '4.5530', '4.5550',
      '4.5800', '4.5810',
    ]) {
      expect(erklaerungZu(code), isNotNull, reason: 'Erklärung fehlt zu $code');
      expect(erklaerungZu(code)!.length, greaterThan(40), reason: code);
    }
  });
}
