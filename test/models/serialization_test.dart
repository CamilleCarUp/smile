import 'package:flutter_test/flutter_test.dart';
import 'package:smile/models/finding.dart';
import 'package:smile/models/request.dart';
import 'package:smile/models/user_profile.dart';

void main() {
  group('DentalRequest überlebt eine Rundreise durch JSON', () {
    final original = DentalRequest(
      id: 42,
      filename: 'rechnung.jpg',
      files: [UploadedFile('rechnung.jpg', path: '/tmp/rechnung.jpg')],
      invoiceNumber: '112233',
      dentistName: 'Dr. med. dent. Max Muster',
      dentistAddress: 'Alte Gasse 13, 8005 Zürich',
      dentistEmail: 'test@zahnarzt.ch',
      dentistPostalCode: '8005',
      dentistCity: 'Zürich',
      dentistCanton: 'ZH',
      date: DateTime(2026, 2, 16),
      status: RequestStatus.sent,
      lines: const [
        TariffLine(
            code: '4.0650',
            description: 'Infiltrationsanästhesie',
            amountChf: 92.20,
            quantity: 2,
            taxpunkte: 38.4,
            taxpunkteFromCatalog: true),
      ],
      invoiceTotal: 320.20,
      referenceTotal: 320.20,
      factor: 1.20,
      statedTotal: 320.20,
      totalsMatch: true,
      isTrustworthy: true,
      wasPhotographedCrooked: true,
      findings: const [
        InvoiceFinding(
          kind: FindingKind.factorAboveTariffMaximum,
          title: 'Preisniveau über dem Höchstsatz',
          explanation: 'Faktor 2.46 statt höchstens 1.97.',
          observed: 2.46,
          allowed: 1.972,
          excessChf: 75.66,
        ),
      ],
    );

    late DentalRequest restored;
    setUp(() => restored = DentalRequest.fromJson(original.toJson()));

    test('Kopfdaten bleiben erhalten', () {
      expect(restored.id, 42);
      expect(restored.invoiceNumber, '112233');
      expect(restored.dentistEmail, 'test@zahnarzt.ch');
      // Der Kanton der Praxis wird mitgespeichert, damit eine alte Rechnung
      // nach einem Update des Verzeichnisses dieselbe Ombudsstelle nennt.
      expect(restored.dentistPostalCode, '8005');
      expect(restored.dentistCity, 'Zürich');
      expect(restored.dentistCanton, 'ZH');
      expect(restored.date, DateTime(2026, 2, 16));
      expect(restored.status, RequestStatus.sent);
    });

    test('Positionen samt Mengen und Herkunft bleiben erhalten', () {
      expect(restored.lines, hasLength(1));
      final line = restored.lines.single;
      expect(line.code, '4.0650');
      expect(line.quantity, 2);
      expect(line.taxpunkte, 38.4);
      expect(line.taxpunkteFromCatalog, isTrue);
      expect(line.amountChf, 92.20);
    });

    test('die Vertrauensangaben bleiben erhalten', () {
      // Ohne sie stünde nach einem Neustart eine unsichere Lesung da wie eine
      // sichere — genau die Verwechslung, die die App vermeiden soll.
      expect(restored.totalsMatch, isTrue);
      expect(restored.isTrustworthy, isTrue);
      expect(restored.wasPhotographedCrooked, isTrue);
      expect(restored.factor, 1.20);
    });

    test('Befunde bleiben erhalten', () {
      expect(restored.findings, hasLength(1));
      expect(restored.findings.single.kind, FindingKind.factorAboveTariffMaximum);
      expect(restored.findings.single.excessChf, closeTo(75.66, 0.01));
    });
  });

  group('UserProfile', () {
    test('überlebt eine Rundreise', () {
      const original = UserProfile(
          firstName: 'Toni',
          lastName: 'Maloni',
          email: 'toni@beispiel.ch');
      final restored = UserProfile.fromJson(original.toJson());
      expect(restored.firstName, 'Toni');
      expect(restored.lastName, 'Maloni');
      expect(restored.email, 'toni@beispiel.ch');
    });

    test('ein alter Eintrag mit Kanton stört nicht', () {
      // Frühere Fassungen haben einen Kanton gespeichert. Der Ort der Praxis
      // kommt heute aus der Rechnung; das alte Feld wird beim Lesen einfach
      // übergangen.
      final restored = UserProfile.fromJson({
        'firstName': 'Toni',
        'lastName': 'Maloni',
        'email': '',
        'canton': 'ZH',
      });
      expect(restored.fullName, 'Toni Maloni');
      expect(restored.isComplete, isTrue);
    });

    test('gilt erst mit Vor- UND Nachname als vollständig', () {
      // Der Brief an die Praxis siezt — darunter gehört ein ganzer Name.
      expect(const UserProfile().isComplete, isFalse);
      expect(const UserProfile(firstName: 'Toni').isComplete, isFalse);
      expect(const UserProfile(lastName: 'Maloni').isComplete, isFalse);
      expect(const UserProfile(firstName: 'Toni', lastName: 'Maloni').isComplete, isTrue);
    });

    test('die E-Mail bleibt freiwillig', () {
      const ohneMail = UserProfile(firstName: 'Toni', lastName: 'Maloni');
      expect(ohneMail.isComplete, isTrue);
      expect(ohneMail.wantsCopy, isFalse);
    });

    test('Leerzeichen zählen nicht als Angabe', () {
      const nurLeerzeichen =
          UserProfile(firstName: '  ', lastName: '   ', email: '  ');
      expect(nurLeerzeichen.isComplete, isFalse);
      expect(nurLeerzeichen.wantsCopy, isFalse);
    });

    test('fullName setzt die Unterschrift zusammen', () {
      const profil = UserProfile(firstName: ' Toni ', lastName: ' Maloni ');
      expect(profil.fullName, 'Toni Maloni');
    });

    test('ein früher gespeicherter einzelner Name geht nicht verloren', () {
      // Vor dieser Änderung gab es nur ein Feld "name". Wer die App aus jener
      // Zeit hat, soll seinen Eintrag behalten statt ihn neu tippen zu müssen.
      final alt = UserProfile.fromJson(
          {'name': 'Toni Maloni', 'email': 'toni@beispiel.ch'});
      expect(alt.firstName, 'Toni');
      expect(alt.lastName, 'Maloni');
      expect(alt.isComplete, isTrue);
      expect(alt.email, 'toni@beispiel.ch');
    });
  });
}
