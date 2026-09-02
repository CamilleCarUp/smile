import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/models/request.dart';
import 'package:smile/models/user_profile.dart';
import 'package:smile/screens/ombudsman_screen.dart';
import 'package:smile/screens/profile_screen.dart';
import 'package:smile/screens/results_screen.dart';
import 'package:smile/screens/sperr_screen.dart';
import 'package:smile/screens/upload_screen.dart';
import 'package:smile/screens/welcome_screen.dart';
import 'package:smile/state/profile_controller.dart';
import 'package:smile/state/requests_repository.dart';
import 'package:smile/state/sperr_controller.dart';
import 'package:smile/state/upload_controller.dart';
import 'package:smile/theme/app_theme.dart';

import '../support/fake_biometrie.dart';
import '../support/fake_store.dart';

/// Grosse Systemschrift ist der Normalfall, nicht der Sonderfall.
///
/// Die Zielgruppe dieser App sind auch ältere Patienten; 150 bis 200 Prozent
/// sind auf deren Geräten üblich eingestellt. Zweimal ist uns schon ein Knopf
/// unter das Sichtfeld gerutscht — beide Male hat es ein Test gefunden, aber
/// nur zufällig. Dieser sucht danach.
///
/// Überläuft ein Layout, wirft Flutter einen Fehler, den das Testgerüst
/// aufsammelt: `tester.takeException()` fängt ihn.
void main() {
  late DentalRequest request;

  setUp(() {
    profileController = ProfileController(store: FakeStore())
      ..profile = const UserProfile(firstName: 'Toni', lastName: 'Maloni');
    requestsRepository = RequestsRepository(store: FakeStore());
    sperrController = SperrController(sensor: FakeBiometrie());
    uploadController.reset();

    request = DentalRequest(
      id: 1,
      filename: '112233 Dr. med. dent. Max Muster',
      files: [UploadedFile('foto.jpg')],
      invoiceNumber: '112233',
      dentistName: 'Dr. med. Dr. med. dent. Maximiliane Musterfrau-Beispiel',
      dentistAddress: 'Alte Gasse 13, 8005 Zürich',
      date: DateTime(2026, 2, 16),
      lines: const [
        TariffLine(
            code: '4.5800',
            description: 'Schmelzätzung und Anbringen des Haftvermittlers',
            amountChf: 23.05,
            quantity: 1,
            taxpunkte: 19.2,
            taxpunkteFromCatalog: true),
        TariffLine(
            code: '4.5360',
            description:
                'Komposit-Füllung, einflächig, jede weitere in der gleichen Sitzung und im gleichen Sextant',
            amountChf: 184.10,
            quantity: 2,
            taxpunkte: 76.7),
      ],
      invoiceTotal: 207.15,
      referenceTotal: 207.15,
      statedTotal: 207.15,
      totalsMatch: true,
      isTrustworthy: true,
    );
    requestsRepository.currentRequest = request;
  });

  tearDown(() => requestsRepository.currentRequest = null);

  /// Ein gewöhnliches Telefon: 360 x 780 logische Pixel.
  Future<void> zeige(WidgetTester tester, Widget screen, double faktor) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(faktor)),
        child: screen,
      ),
    ));
    await tester.pump();
  }

  final bildschirme = <String, Widget Function()>{
    'Start': () => const WelcomeScreen(),
    'Meine Angaben': () => const ProfileScreen(),
    'Erster Start': () => const ProfileScreen(firstRun: true),
    'Rechnung prüfen': () => const UploadScreen(),
    'Ergebnis': () => const ResultsScreen(),
    'Ombudsstelle': () => const OmbudsmanScreen(praxisKanton: 'ZH', praxisOrt: '8005 Zürich'),
    'Gesperrt': () => const SperrScreen(),
  };

  for (final faktor in const [1.5, 2.0]) {
    group('bei ${(faktor * 100).round()} Prozent Schriftgrösse', () {
      bildschirme.forEach((name, bauen) {
        testWidgets('$name läuft nicht über', (tester) async {
          await zeige(tester, bauen(), faktor);

          expect(tester.takeException(), isNull,
              reason: '$name überläuft bei ${(faktor * 100).round()} Prozent Schrift');
        });
      });
    });
  }

  testWidgets('der Weiter-Knopf ist bei grosser Schrift erreichbar und wirkt', (tester) async {
    // Genau der Fehler, der uns zweimal passiert ist: Der Knopf steht unten
    // in einer scrollenden Liste und rutscht aus dem Bild.
    //
    // Geprüft wird über die Wirkung, nicht über eine Fehlermeldung: Bei 200
    // Prozent Schrift ist ein Eingabefeld weiter unten gar nicht erst gebaut,
    // und was nicht gebaut ist, kann nichts anzeigen. Dass es weitergeht,
    // beweist beides — der Knopf ist erreichbar und er löst aus.
    profileController.profile =
        const UserProfile(firstName: 'Toni', lastName: 'Maloni');

    await zeige(tester, const ProfileScreen(firstRun: true), 2.0);

    expect(find.text("Los geht's"), findsOneWidget);
    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
