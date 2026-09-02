# Architektur

Ziel des Aufbaus: **Änderungen sollen lokal bleiben.** Wer die Analyse-Logik
ändert, soll keinen Screen anfassen müssen — und umgekehrt.

## Schichten

```
lib/
├── models/          Datenstrukturen, keine Logik
├── logic/           reine Geschäftslogik, KEINE Flutter-Abhängigkeit
├── data/            Referenzdaten und verschlüsselte Ablage
├── services/        Zugriff auf Gerätefunktionen (OCR, PDF)
├── state/           App-Zustand, drei getrennte Controller
├── screens/         UI (14 Screens)
├── widgets/         geteilte UI-Bausteine
└── theme/           Farben & Material-Theme aus dem Klickdummy
```

### `models/request.dart`
`UploadedFile`, `TariffLine`, `DentalRequest`, `OmbudsmanContact`,
`RequestStatus`. Reine Datenhaltung mit ein paar abgeleiteten Gettern
(`flaggedLines`, `difference`).

### `logic/invoice_matcher.dart` — das Herzstück
Hat **bewusst keinen Flutter-Import**. Dadurch in Millisekunden testbar, ohne
Emulator oder Widget-Baum. Liefert aktuell feste Demo-Daten
(`analyzeInvoiceDemo()`); in Phase 2 wird der Rumpf durch echtes Parsen des
OCR-Texts plus Abgleich mit den Referenzdaten ersetzt. **Die Signatur bleibt
dabei gleich** (Dateien/Text rein, `InvoiceAnalysisResult` raus), damit weder
Screens noch bestehende Tests angefasst werden müssen.

### `logic/rechnungs_trenner.dart`

Sitzt **vor** dem Parser und gruppiert nur Seiten, ohne sie zu lesen. Ein PDF
aus der Praxis enthält oft mehrere Rechnungen; alles zusammen auszuwerten
ergäbe eine Summe, die es nie gab — und die richtig aussieht.

Getrennt wird nach Referenznummer, ersatzweise nach Seitenzähler
(`Seite: 1/2`). Fehlt beides, wird zusammengelassen: Eine fälschlich
zerrissene Rechnung fällt bei der Summenprobe auf und wird als unsicher
gemeldet, eine fälschlich zusammengefasste nicht.

Aus jeder Gruppe wird ein eigener Eintrag im Verlauf, benannt nach seiner
eigenen Referenznummer. Der Ergebnis-Bildschirm sagt, wenn es mehrere waren.

### `state/` — getrennte Controller statt eines Monolithen
Ursprünglich gab es eine einzige `AppState`-Klasse für alles. Die wurde
aufgeteilt, weil ein zentraler Zustand jede Änderung riskant macht und sich
kaum isoliert testen lässt:

| Datei | Zuständigkeit |
|---|---|
| `upload_controller.dart` | Ausgewählte Dateien, OCR-Ergebnisse, Anstoss der Auswertung. |
| `requests_repository.dart` | Verlauf der Anfragen (erfasst / gesendet / abgeschlossen), inklusive Speichern und Laden. |
| `profile_controller.dart` | Die Angaben des Nutzers über sich selbst. |

Beide sind `ChangeNotifier` mit je einer globalen Instanz
(`uploadController`, `requestsRepository`). Bewusst einfach
gehalten — ein Umbau auf Provider/Riverpod ist möglich, aber für die aktuelle
Grösse nicht nötig.

> **Fallstrick, der uns schon einmal getroffen hat:** Wer einen Wert aus einem
> Controller in `build()` liest, muss den betroffenen Widget-Teil in einen
> `AnimatedBuilder` (o. ä.) einwickeln. Sonst friert der Zustand vom ersten
> Build ein. Genau das hatte den „Rechnung analysieren"-Button dauerhaft
> deaktiviert. Der Regressionstest dafür liegt in
> `test/screens/upload_screen_test.dart`.

### `services/`

`ocr_service` (ML Kit), `pdf_service` (Seiten zu Bildern) und `fehlertexte`
(Meldungen, die dem Nutzer sagen, was er tun kann).

Zu den Fehlerwegen drei Entscheide:

- **Die Meldung nennt den Ausweg.** Statt `PlatformException(camera_access_denied)`
  steht da, wo man den Zugriff freigibt — und dass die Galerie auch geht. Die
  technische Ursache bleibt dran, klein und am Schluss.
- **Höchstens 20 PDF-Seiten.** Ein 40-seitiges Dokument wären gut hundert
  Megabyte Zwischenbilder und einige Minuten Texterkennung, während derer die
  App stumm dasteht. Was aufbereitet wurde, sagt sie; ein Fortschritt
  ("Seite 7 von 20") zeigt, dass sie noch lebt.
- **Aufgeräumt wird vor dem nächsten Import, nicht nach dem laufenden.**
  Solange die App läuft, zeigen die erfassten Seiten noch auf diese Dateien.
  So bleibt höchstens ein Import lang etwas liegen.

Was nicht gelesen werden konnte, steht im Ergebnis: gescheitertes Speichern
(sonst ist der Verlauf nach dem Schliessen weg, ohne Warnung) und einzelne
unlesbare Seiten (sonst sähe ein unvollständiges Ergebnis vollständig aus).

### `data/ombudsman_data.dart`
Die 21 kantonalen SSO-Ombudsstellen als Konstante.

Jede Stelle nennt die Kantone, für die sie zuständig ist. Welcher Kanton das
ist, kommt aus der Rechnung: `logic/praxis_ort.dart` liest Postleitzahl und
Ort der Praxis aus dem Adressblock, `data/plz_verzeichnis.dart` übersetzt die
Postleitzahl in ein Kantonskürzel. Details und die Datenquelle stehen in
[ortsverzeichnis.md](ortsverzeichnis.md).

## Tests

```
test/
├── logic/invoice_matcher_test.dart      Analyse-Logik (Summen, Markierungen)
├── models/request_test.dart             Getter der Datenmodelle
├── state/upload_controller_test.dart    Controller-Logik ohne UI
├── screens/upload_screen_test.dart      Widget-Test + Regressionstest
└── widget_test.dart                     Smoke-Test: App startet
```

`flutter test` — kein Gerät nötig.

`test/support/fake_store.dart` hält eine Ablage im Speicher bereit. Ohne sie
hängen alle Bildschirme mit Speicherzugriff am echten Keystore, den es im
Test nicht gibt — der Zugriff scheitert dann zu einem unvorhersehbaren
Zeitpunkt und macht Tests unzuverlässig. Aus demselben Grund sind
`profileController` und `requestsRepository` bewusst veränderbar (`var` statt
`final`), damit Tests eine eigene Instanz einsetzen können.

Die Aufteilung folgt der Schichtung: alles unterhalb von `screens/` lässt sich
ohne Flutter-Testframework prüfen und läuft entsprechend schnell. Widget-Tests
gibt es nur dort, wo das Zusammenspiel von Zustand und UI die eigentliche
Fehlerquelle ist.

## Bewusste Nicht-Entscheidungen

**Kein Dunkelmodus.** Zahnmedizin hat ein helles Bild, und die Farben stammen
aus dem A/B-Test der Thesis. Ein halber Dunkelmodus wäre schlechter als
keiner: Die Palette steckt an 132 Stellen fest im Code, ein dunkles Theme
würde die Material-Widgets umfärben und unseren eigenen Text dunkelgrau auf
dunkelgrau lassen. `themeMode: ThemeMode.light` hält die Entscheidung fest.

- **Kein Backend.** Siehe Local-First im README. Ein Server würde die
  datenschutzrechtliche Lage grundlegend ändern.
- **Keine Datenbank.** Der Verlauf liegt als verschlüsselte Datei auf dem
  Gerät, nicht in einer Datenbank — siehe [Speicherung](#speicherung). Für ein
  paar Dutzend Anfragen wäre ein Datenbankschema mehr Wartung als Nutzen.
- **Kein State-Management-Framework.** Erst sinnvoll, wenn der Zustand
  komplexer wird als jetzt.
- **Keine Anmeldung, keine Konten.** Es gab einmal Anmelde- und
  Registrierungsbildschirme aus dem Klickdummy — mit `testuser`/`1234` fest im
  Code. Sie sind entfernt, und zwar nicht aus Bequemlichkeit: Ein Login
  schützt den Zugang zu etwas. Smile hat keinen Server. Ein Passwort läge im
  selben Speicher wie die Daten, die es schützen soll, und ohne Server gäbe es
  keinen Weg, es zurückzusetzen. Dazu kämen Pflichten (Passwörter halten,
  Auskunfts- und Löschrechte nach DSG) für einen Schutz, den es gar nicht
  gibt. Eine grundlose Hürde vor einer App, die Hemmschwellen abbauen soll,
  ist zudem die falsche erste Begegnung.

## Speicherung

Anfragen und Nutzerangaben bleiben erhalten — **verschlüsselt und
ausschliesslich auf dem Gerät.** Drei Teile, die zusammengehören:

### 1. Gerätesicherung abgeschaltet

`android/app/src/main/res/xml/data_extraction_rules.xml` plus
`allowBackup="false"` im Manifest.

Das ist der wichtigste Handgriff und ohne ihn wäre alles andere umsonst:
Android sichert App-Daten **standardmässig** nach Google Drive und überträgt
sie bei einem Gerätewechsel. Zahnarztrechnungen wären damit in der Cloud
gelandet, und das Versprechen der App wäre eine Lüge gewesen. Beides ist
vollständig ausgeschlossen. Der Preis: Bei einem Gerätewechsel beginnt der
Nutzer mit einer leeren Liste.

### 2. Verschlüsselte Ablage

`lib/data/secure_store.dart`. Ein zufälliger Schlüssel wird einmalig erzeugt
und im Keystore (Android) bzw. der Keychain (iOS) hinterlegt — dort schützt
ihn das Betriebssystem hardwaregestützt. Die Nutzdaten liegen
AES-GCM-verschlüsselt als Datei im privaten Verzeichnis der App. GCM erkennt
Manipulation, statt still Falsches zu entschlüsseln.

Lässt sich eine Datei nicht lesen — etwa weil nach einer Neuinstallation der
Schlüssel fehlt —, wird sie verworfen statt einen Fehler nach oben zu
reichen. Ein unlesbarer Verlauf darf die App nicht am Starten hindern.

**Was das nicht leistet:** Schutz gegen jemanden, der das entsperrte Gerät in
der Hand hält. Dafür bräuchte es eine Sperre in der App selbst (Fingerabdruck
über `local_auth`). Offener Punkt.

### 3. Nutzerangaben

Vor- und Nachname sind beim ersten Start Pflicht, die E-Mail freiwillig.

Der Name steht als **Unterschrift** unter der Rückfrage. Der Brief an die
Praxis siezt; ein unsignierter Brief wirkt unseriös und bleibt oft
unbeantwortet. Deshalb einmal vorher fragen statt hinterher feststellen.

Die E-Mail wird für den Versand **nicht** gebraucht: Die App verschickt nicht
selbst, sondern öffnet über `mailto:` die Mail-App des Nutzers. Der Absender
kommt von dort, und die gesendete Nachricht liegt anschliessend in dessen
Ordner „Gesendet". Die Adresse dient allein einer Kopie an sich selbst (CC)
und bleibt deshalb freiwillig.

### 4. App-Sperre (freiwillig)

Die Verschlüsselung schützt die Datei, nicht den Blick auf ein entsperrtes
Gerät, das man aus der Hand gibt. Dafür die Sperre: `services/biometrie.dart`
kapselt `local_auth`, `state/sperr_controller.dart` hält den Zustand,
`screens/sperr_screen.dart` zeigt ihn.

Drei Entscheide, die dahinterstehen:

- **Nicht nur Biometrie.** `biometricOnly: false` — ein nasser Finger oder ein
  defekter Sensor darf niemanden aus seinem eigenen Verlauf aussperren. Der
  Gerätecode bleibt der Weg zurück.
- **Einschalten nur, wenn das Gerät sperren kann.** Ohne Fingerabdruck *und*
  ohne Code bleibt der Schalter aus, mit einer Erklärung statt einer Falle.
- **Als Überlagerung, nicht als Route.** Läge die Sperre als eigene Route im
  Navigator, bliebe ein bereits geöffneter Bildschirm darüber stehen — und
  damit sichtbar. Sie liegt deshalb im `builder` der `MaterialApp` über allem.

Zugesperrt wird beim Start und beim Wechsel in den Hintergrund, aber nicht bei
`inactive`: Das kurze `inactive` beim Herunterziehen der
Benachrichtigungsleiste wäre sonst schon ein Grund. Und die laufende Abfrage
sperrt sich nicht selbst zu — der Systemdialog schiebt die App selbst kurz in
den Hintergrund.

Der Sensor steckt hinter einer Schnittstelle, weil es im Test keinen gibt:
`FakeBiometrie` spielt alle drei Ausgänge durch — erkannt, abgelehnt, gar kein
Sensor.

### Bearbeitbarkeit

Erfasste Anfragen lassen sich ändern, gesendete nicht
(`RequestsRepository.updateCaptured`). Konkret korrigierbar ist die
E-Mail-Adresse der Praxis — dort klemmt es in der Praxis, weil die
Texterkennung Adressen nicht zuverlässig liest und die Rückfrage ohne
richtige Adresse ins Leere geht. Was einmal gesendet ist, bleibt wie es war:
Die Praxis hat den Text bereits.
