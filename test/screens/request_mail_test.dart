import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/models/finding.dart';
import 'package:smile/models/request.dart';
import 'package:smile/models/user_profile.dart';
import 'package:smile/screens/request_screen.dart';
import 'package:smile/state/profile_controller.dart';
import 'package:smile/state/requests_repository.dart';

import '../support/fake_store.dart';

/// Was am Ende bei einer Zahnarztpraxis auf dem Schreibtisch landet.
///
/// Geprüft wird der sichtbare Entwurf: Er steht im Anfrage-Bildschirm zum
/// Gegenlesen, bevor der Nutzer ihn absendet.
DentalRequest _request(List<InvoiceFinding> findings) => DentalRequest(
      id: 1,
      filename: 'Rechnung',
      files: [UploadedFile('foto.jpg')],
      invoiceNumber: '20244',
      dentistName: 'Dr. med. dent. Max Muster',
      dentistAddress: 'Musterweg 11, 8134 Adliswil',
      dentistEmail: 'praxis@musterpraxis.example',
      date: DateTime(2026, 8, 19),
      lines: const [
        TariffLine(
            code: '4.5430',
            description: 'Komposit-Füllung, Molar, zweiflächig',
            amountChf: 288.00,
            quantity: 1,
            taxpunkte: 240.0),
      ],
      invoiceTotal: 413.55,
      referenceTotal: 375.55,
      factor: 1.20,
      statedTotal: 413.55,
      totalsMatch: true,
      isTrustworthy: true,
      findings: findings,
    );

const _zuHoherTaxpunkt = InvoiceFinding(
  kind: FindingKind.positionAboveMaximum,
  title: 'Komposit-Füllung, Molar, zweiflächig: über dem Höchstsatz',
  explanation: 'Für diese Position lässt der Tarif höchstens 208.5 Taxpunkte zu.',
  frage: 'Bei Position 4.5430 «Komposit-Füllung, Molar, zweiflächig» sind 240.0 '
      'Taxpunkte verrechnet. Nach meinem Verständnis lässt der Tarif für '
      'Privatpatienten hier höchstens 208.5 Taxpunkte zu; das ergäbe rund '
      'CHF 250.20 statt der verrechneten CHF 288.00.',
  observed: 240.0,
  allowed: 208.5,
  excessChf: 37.80,
);

const _zweiterBefund = InvoiceFinding(
  kind: FindingKind.quantityAboveLimit,
  title: 'Plaqueanfärbung: 8 mal verrechnet',
  explanation: 'Der Tarif hält fest: «Maximal 6 mal pro Sitzung verrechenbar.»',
  frage: 'Position 4.1010 «Plaqueanfärbung, pro Sextant» ist 8 mal verrechnet. '
      'Der Tarif hält dazu fest: «Maximal 6 mal pro Sitzung verrechenbar.»',
);

void main() {
  setUp(() {
    requestsRepository = RequestsRepository(store: FakeStore());
    profileController = ProfileController(store: FakeStore())
      ..profile = const UserProfile(firstName: 'Silvia', lastName: 'Brunner');
  });
  tearDown(() => requestsRepository.currentRequest = null);

  Future<void> zeige(WidgetTester tester, DentalRequest req) async {
    // Hohes Testfenster: Der Entwurf steht in einer scrollenden Liste, und
    // was nicht sichtbar ist, ist dort auch nicht gebaut. Geprüft wird hier
    // der Text, nicht das Layout — dafür gibt es grosse_schrift_test.dart.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    requestsRepository.currentRequest = req;
    await tester.pumpWidget(const MaterialApp(home: RequestScreen()));
    await tester.pump();
  }

  testWidgets('der Befund steht beim Namen im Entwurf', (tester) async {
    await zeige(tester, _request(const [_zuHoherTaxpunkt]));

    // Position, verrechneter Wert, zulässiger Wert und die Folge in Franken —
    // alles vier, sonst kann die Praxis die Frage nicht beantworten.
    expect(find.textContaining('4.5430'), findsWidgets);
    expect(find.textContaining('240.0 Taxpunkte verrechnet'), findsOneWidget);
    expect(find.textContaining('höchstens 208.5'), findsOneWidget);
    expect(find.textContaining('CHF 250.20 statt der verrechneten CHF 288.00'),
        findsOneWidget);
  });

  testWidgets('der Entwurf fragt, statt zu behaupten', (tester) async {
    // Die Praxis kennt womöglich einen Grund, den die App nicht kennt.
    await zeige(tester, _request(const [_zuHoherTaxpunkt]));

    expect(find.textContaining('Nach meinem Verständnis'), findsOneWidget);
    expect(find.textContaining('Könnten Sie mir erläutern'), findsOneWidget);
  });

  testWidgets('mehrere Befunde kommen alle vor, nummeriert', (tester) async {
    // Wer zwei Punkte hat und nur einen anspricht, muss ein zweites Mal
    // schreiben.
    await zeige(tester, _request(const [_zuHoherTaxpunkt, _zweiterBefund]));

    expect(find.textContaining('folgende Punkte'), findsOneWidget);
    expect(find.textContaining('1. Bei Position 4.5430'), findsOneWidget);
    expect(find.textContaining('2. Position 4.1010'), findsOneWidget);
  });

  testWidgets('ohne Befund bleibt es bei der Bitte um Erläuterung', (tester) async {
    await zeige(tester, _request(const []));

    expect(find.textContaining('bitte Sie um eine kurze Erläuterung'), findsOneWidget);
  });

  testWidgets('der Brief ist unterschrieben', (tester) async {
    await zeige(tester, _request(const [_zuHoherTaxpunkt]));

    expect(find.textContaining('Silvia Brunner'), findsWidgets);
  });
}
