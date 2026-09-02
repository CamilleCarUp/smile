import 'package:flutter_test/flutter_test.dart';
import 'package:smile/logic/invoice_matcher.dart';
import 'package:smile/models/request.dart';
import 'package:smile/models/user_profile.dart';
import 'package:smile/state/profile_controller.dart';
import 'package:smile/state/requests_repository.dart';

import '../support/fake_store.dart';

void main() {
  group('Verlauf übersteht einen Neustart', () {
    late FakeStore store;

    setUp(() => store = FakeStore());

    Future<RequestsRepository> mitEinerAnfrage() async {
      final repo = RequestsRepository(store: store);
      repo.createFromAnalysis(
        files: [UploadedFile('rechnung.jpg')],
        analysis: analyzeInvoiceDemo(),
      );
      // Speichern läuft nebenher; kurz warten, bis es durch ist.
      await Future<void>.delayed(Duration.zero);
      return repo;
    }

    test('eine erfasste Anfrage wird gespeichert und kommt zurück', () async {
      await mitEinerAnfrage();

      final nachNeustart = RequestsRepository(store: store);
      expect(nachNeustart.requests, isEmpty);
      await nachNeustart.load();

      expect(nachNeustart.requests, hasLength(1));
      expect(nachNeustart.requests.single.lines, isNotEmpty);
      expect(nachNeustart.requests.single.status, RequestStatus.captured);
    });

    test('der Rechnungszähler läuft nicht zurück', () async {
      final repo = await mitEinerAnfrage();
      final ersteNummer = repo.requests.single.invoiceNumber;

      final nachNeustart = RequestsRepository(store: store);
      await nachNeustart.load();
      nachNeustart.createFromAnalysis(
        files: [UploadedFile('zweite.jpg')],
        analysis: analyzeInvoiceDemo(),
      );

      expect(nachNeustart.requests.first.invoiceNumber, isNot(ersteNummer));
    });

    test('ein unlesbarer Verlauf hindert die App nicht am Starten', () async {
      store.inhalt['requests'] = {'requests': 'kaputt'};
      final repo = RequestsRepository(store: store);

      await repo.load();

      expect(repo.requests, isEmpty);
      expect(store.inhalt.containsKey('requests'), isFalse,
          reason: 'Die kaputte Ablage wird verworfen statt immer wieder zu scheitern.');
    });
  });

  group('Erfasste Anfragen bleiben bearbeitbar', () {
    late FakeStore store;
    late RequestsRepository repo;
    late DentalRequest req;

    setUp(() {
      store = FakeStore();
      repo = RequestsRepository(store: store);
      req = repo.createFromAnalysis(
        files: [UploadedFile('rechnung.jpg')],
        analysis: analyzeInvoiceDemo(),
      );
    });

    test('die Empfängeradresse lässt sich korrigieren', () {
      // Die Texterkennung liest E-Mail-Adressen nicht immer richtig, und ohne
      // richtige Adresse geht die Rückfrage ins Leere.
      final ok = repo.updateCaptured(req.id, dentistEmail: 'praxis@beispiel.ch');

      expect(ok, isTrue);
      expect(repo.requests.single.dentistEmail, 'praxis@beispiel.ch');
    });

    test('eine gesendete Anfrage lässt sich nicht mehr ändern', () {
      // Was einmal raus ist, hat die Praxis bereits gelesen.
      repo.submitCurrentRequest();

      final ok = repo.updateCaptured(req.id, dentistEmail: 'zu@spaet.ch');

      expect(ok, isFalse);
      expect(repo.requests.single.dentistEmail, isNot('zu@spaet.ch'));
    });
  });

  group('Profil', () {
    test('wird gespeichert und kommt nach einem Neustart zurück', () async {
      final store = FakeStore();

      await ProfileController(store: store).save(const UserProfile(
          firstName: 'Toni', lastName: 'Maloni', email: 'toni@beispiel.ch'));

      final nachNeustart = ProfileController(store: store);
      await nachNeustart.load();

      expect(nachNeustart.profile.fullName, 'Toni Maloni');
      expect(nachNeustart.profile.wantsCopy, isTrue);
    });

    test('leeres Profil bleibt leer', () async {
      final controller = ProfileController(store: FakeStore());
      await controller.load();
      expect(controller.profile.isComplete, isFalse);
    });
  });
}
