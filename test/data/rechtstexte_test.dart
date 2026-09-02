import 'package:flutter_test/flutter_test.dart';
import 'package:smile/data/rechtstexte.dart';

void main() {
  group('Inhalt', () {
    test('jeder Text hat einen Titel, einen Kurzsatz und Abschnitte', () {
      for (final text in Rechtstexte.alle) {
        expect(text.titel, isNotEmpty);
        expect(text.kurz, isNotEmpty);
        expect(text.abschnitte, isNotEmpty, reason: text.titel);
        for (final a in text.abschnitte) {
          expect(a.titel, isNotEmpty, reason: text.titel);
          expect(a.text.trim().length, greaterThan(20), reason: '${text.titel}/${a.titel}');
        }
      }
    });

    test('der Datenschutztext sagt, was das Gerät verlässt — und wann', () {
      final text = Rechtstexte.datenschutz.abschnitte
          .map((a) => a.text)
          .join(' ');

      // Der ehrliche Teil: Die Rückfrage geht über die Mail-App des Nutzers
      // hinaus. Ein Datenschutztext, der nur "nichts verlässt das Gerät"
      // sagt, wäre in genau dem Moment falsch, auf den die App hinarbeitet.
      expect(text, contains('E-Mail-App'));
      expect(text, contains('Keychain'));
      expect(text, contains('besonders schützenswerte'));
    });

    test('der Haftungstext nennt die Grenzen der Prüfung', () {
      final text = Rechtstexte.haftung.abschnitte.map((a) => a.text).join(' ');

      expect(Rechtstexte.haftung.abschnitte.map((a) => a.titel),
          contains('"Kein Befund" heisst nicht "alles korrekt"'));
      expect(text, contains('keine App beurteilen'));
      // Unabhängigkeit von der SSO: Die App führt deren Ombudsstellen auf und
      // rechnet mit deren Tarif — das darf nicht nach Zusammenarbeit aussehen.
      expect(text, contains('keiner Verbindung zur Schweizerischen Zahnärzte-Gesellschaft'));
    });

    test('grobe Fahrlässigkeit wird nicht wegbedungen', () {
      // Ginge in der Schweiz ohnehin nicht (Art. 100 OR) — ein Text, der es
      // behauptet, ist an dieser Stelle unwirksam und wirkt unseriös.
      final haftung = Rechtstexte.haftung.abschnitte
          .firstWhere((a) => a.titel == 'Haftung')
          .text;

      expect(haftung, contains('grobe Fahrlässigkeit'));
      expect(haftung, contains('soweit das Gesetz das zulässt'));
    });
  });

  group('Platzhalter', () {
    test('das Impressum ist noch nicht ausgefüllt und sagt das', () {
      expect(Rechtstexte.impressum.hatPlatzhalter, isTrue);
      expect(Rechtstexte.impressum.platzhalter, contains('‹Kontaktadresse›'));
    });

    test('Datenschutz und Haftung stehen fertig da', () {
      expect(Rechtstexte.datenschutz.hatPlatzhalter, isFalse);
      expect(Rechtstexte.haftung.hatPlatzhalter, isFalse);
    });

    test('offenePunkte zählt genau das auf, was noch fehlt', () {
      // Diese Liste ist die Startlinie für die Veröffentlichung. Ist sie
      // leer, sind die Texte vollständig — nicht vorher.
      expect(Rechtstexte.offenePunkte, isNotEmpty);
      expect(Rechtstexte.veroeffentlichungsbereit, isFalse);
      for (final p in Rechtstexte.offenePunkte) {
        expect(p, startsWith('‹'));
        expect(p, endsWith('›'));
      }
    });
  });
}
