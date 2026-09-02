/// Die rechtlichen Texte der App.
///
/// Bewusst als Daten und nicht in die Bildschirme geschrieben: So laesst sich
/// pruefen, was drinsteht -- und was noch fehlt. Vor einer Veroeffentlichung
/// duerfen keine Platzhalter mehr uebrig sein; [Rechtstexte.offenePunkte]
/// zaehlt sie auf, und der Impressums-Bildschirm sagt es sichtbar.
///
/// Kein Anwaltsersatz. Die Texte beschreiben, was die App tatsaechlich tut;
/// vor der Veroeffentlichung gehoeren sie einer Fachperson vorgelegt (siehe
/// docs/veroeffentlichung.md).
class Rechtsabschnitt {
  final String titel;
  final String text;
  const Rechtsabschnitt(this.titel, this.text);
}

class Rechtstext {
  final String titel;

  /// Ein Satz zuoberst, der das Wesentliche sagt.
  final String kurz;
  final List<Rechtsabschnitt> abschnitte;

  const Rechtstext({required this.titel, required this.kurz, required this.abschnitte});

  /// Alles, was noch auszufuellen ist, steht in ‹spitzen Klammern›.
  bool get hatPlatzhalter => _platzhalter.hasMatch(kurz) ||
      abschnitte.any((a) => _platzhalter.hasMatch(a.text) || _platzhalter.hasMatch(a.titel));

  List<String> get platzhalter => [
        for (final m in _platzhalter.allMatches(
            [kurz, for (final a in abschnitte) '${a.titel} ${a.text}'].join(' ')))
          m.group(0)!,
      ];
}

final RegExp _platzhalter = RegExp('‹[^›]+›');

class Rechtstexte {
  const Rechtstexte._();

  static const datenschutz = Rechtstext(
    titel: 'Datenschutz',
    kurz: 'Smile erhebt keine Daten über dich. Es gibt keinen Server, kein Konto '
        'und keine Anmeldung.',
    abschnitte: [
      Rechtsabschnitt(
        'Was auf deinem Gerät bleibt',
        'Deine Fotos und PDFs, der daraus erkannte Text, der Verlauf deiner Anfragen '
            'sowie Vor- und Nachname und die freiwillige E-Mail-Adresse. Das alles liegt '
            'verschlüsselt in einer Datei dieser App; der Schlüssel steckt im gesicherten '
            'Speicher deines Geräts (Android Keystore, iOS Keychain). Die automatische '
            'Gerätesicherung und die Übertragung auf ein neues Gerät sind abgeschaltet — '
            'sonst lägen Gesundheitsdaten in einer Cloud-Sicherung. Bei einem '
            'Gerätewechsel beginnst du deshalb mit einer leeren Liste.',
      ),
      Rechtsabschnitt(
        'Was dein Gerät verlässt',
        'Von selbst: nichts. Kein Upload, keine Nutzungsstatistik, keine Werbung, keine '
            'Analysewerkzeuge Dritter.\n\n'
            'Erst wenn du eine Rückfrage abschickst, verlässt ihr Text dein Gerät — über '
            'deine eigene E-Mail-App, an die von dir gewählte Adresse. Ab da gelten die '
            'Bedingungen deines E-Mail-Anbieters und der Empfängerin. Dasselbe gilt, wenn '
            'du aus der App heraus eine Ombudsstelle anrufst oder anschreibst: Es öffnet '
            'sich dein Telefon- oder Mailprogramm, den Rest bestimmst du.',
      ),
      Rechtsabschnitt(
        'Texterkennung',
        'Die Erkennung läuft auf deinem Gerät (Google ML Kit, On-Device). Deine Bilder '
            'werden nicht übertragen. Auf Android kann das Erkennungsmodell einmalig über '
            'die Google-Play-Dienste nachgeladen werden — dabei geht es um die Software, '
            'nicht um deine Rechnung.',
      ),
      Rechtsabschnitt(
        'Gesundheitsdaten',
        'Angaben zu einer Zahnbehandlung sind nach dem Schweizer Datenschutzgesetz '
            'besonders schützenswerte Personendaten. Sie werden ausschliesslich lokal '
            'verarbeitet und bleiben unter deiner Kontrolle.',
      ),
      Rechtsabschnitt(
        'Berechtigungen',
        'Kamera: nur, um eine Rechnung zu fotografieren. Fotos und Dateien: nur die '
            'Datei, die du auswählst. Fingerabdruck oder Gesicht: nur, um die App zu '
            'entsperren, falls du die Sperre einschaltest — die Merkmale selbst sieht '
            'Smile nie, das prüft dein Betriebssystem.',
      ),
      Rechtsabschnitt(
        'Löschen',
        'Unter "Meine Angaben" löschst du mit "Alle Daten löschen" den Verlauf und deine '
            'Angaben unwiderruflich. Beim Deinstallieren der App verschwindet ebenfalls '
            'alles. Da wir nichts über dich erheben, gibt es nichts, worüber wir Auskunft '
            'geben oder was wir für dich löschen könnten.',
      ),
    ],
  );

  static const haftung = Rechtstext(
    titel: 'Haftung und Grenzen',
    kurz: 'Smile hilft dir, eine Rechnung zu verstehen. Es ist keine Rechts- und keine '
        'zahnmedizinische Beratung.',
    abschnitte: [
      Rechtsabschnitt(
        '"Kein Befund" heisst nicht "alles korrekt"',
        'Die hinterlegten Referenzdaten decken bisher nur einen kleinen Teil des '
            'Zahnarzttarifs ab. Smile beurteilt nur, was sich daraus belegen lässt — '
            'derzeit im Wesentlichen das Preisniveau. Ob eine Behandlung nötig oder '
            'richtig war, kann keine App beurteilen.',
      ),
      Rechtsabschnitt(
        'Erkennungsfehler',
        'Aus einem Foto gelesene Zahlen können falsch sein. Smile prüft sich selbst, '
            'indem es die Positionen gegen das ausgewiesene Total rechnet, und sagt es, '
            'wenn ein Ergebnis nicht belastbar ist. Ausschliessen lässt sich ein Irrtum '
            'trotzdem nicht. Sieh die Angaben durch, bevor du sie verwendest.',
      ),
      Rechtsabschnitt(
        'Die Rückfrage ist deine Nachricht',
        'Smile bereitet einen Text vor und öffnet deine Mail-App. Abgeschickt wird er '
            'von dir, in deinem Namen. Prüfe ihn vor dem Senden.',
      ),
      Rechtsabschnitt(
        'Haftung',
        'Die App wird ohne Zusicherung bestimmter Eigenschaften bereitgestellt. Eine '
            'Haftung für Schäden aus ihrer Nutzung ist ausgeschlossen, soweit das Gesetz '
            'das zulässt; für Absicht und grobe Fahrlässigkeit bleibt es bei der '
            'gesetzlichen Haftung.',
      ),
      Rechtsabschnitt(
        'Kein Medizinprodukt',
        'Smile beurteilt Rechnungen, nicht Befunde, und dient keinem medizinischen '
            'Zweck im Sinne der Medizinprodukteverordnung.',
      ),
      Rechtsabschnitt(
        'Unabhängigkeit',
        'Smile steht in keiner Verbindung zur Schweizerischen Zahnärzte-Gesellschaft SSO '
            'und wird von ihr weder herausgegeben noch geprüft. DENTOTAR ist eine Marke '
            'der SSO. Die Angaben zu den Ombudsstellen stammen aus öffentlich '
            'zugänglichen Quellen und sind ohne Gewähr.',
      ),
    ],
  );

  static const impressum = Rechtstext(
    titel: 'Impressum',
    kurz: 'Verantwortlich für diese App:',
    abschnitte: [
      Rechtsabschnitt(
        'Anbieterin',
        '‹Vor- und Nachname oder Firma›\n‹Strasse und Nummer›\n‹PLZ und Ort›\nSchweiz',
      ),
      Rechtsabschnitt(
        'Kontakt',
        'E-Mail: ‹Kontaktadresse›',
      ),
      Rechtsabschnitt(
        'Herkunft',
        'Smile ist aus der MAS-Arbeit von Cédric Eichmann an der ETH Zürich '
            'hervorgegangen und wird als eigenständiges Projekt weiterentwickelt.',
      ),
    ],
  );

  static const alle = [datenschutz, haftung, impressum];

  /// Was vor einer Veroeffentlichung noch auszufuellen ist.
  static List<String> get offenePunkte =>
      [for (final t in alle) ...t.platzhalter];

  static bool get veroeffentlichungsbereit => offenePunkte.isEmpty;
}
