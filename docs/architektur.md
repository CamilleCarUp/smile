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
- `ocr_service.dart` — Google ML Kit Texterkennung, komplett offline
- `pdf_service.dart` — rendert PDF-Seiten via `pdfx` zu PNGs (2×-Auflösung),
  damit die OCR sie lesen kann

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

- **Kein Backend.** Siehe Local-First im README. Ein Server würde die
  datenschutzrechtliche Lage grundlegend ändern.
- **Keine Datenbank.** Anfragen leben aktuell nur im Speicher. Persistenz
  (z. B. `sqflite` oder verschlüsselte Dateien) ist ein eigener Schritt.
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

### Bearbeitbarkeit

Erfasste Anfragen lassen sich ändern, gesendete nicht
(`RequestsRepository.updateCaptured`). Konkret korrigierbar ist die
E-Mail-Adresse der Praxis — dort klemmt es in der Praxis, weil die
Texterkennung Adressen nicht zuverlässig liest und die Rückfrage ohne
richtige Adresse ins Leere geht. Was einmal gesendet ist, bleibt wie es war:
Die Praxis hat den Text bereits.

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

- **Kein Backend.** Siehe Local-First im README. Ein Server würde die
  datenschutzrechtliche Lage grundlegend ändern.
- **Keine Datenbank.** Anfragen leben aktuell nur im Speicher. Persistenz
  (z. B. `sqflite` oder verschlüsselte Dateien) ist ein eigener Schritt.
- **Kein State-Management-Framework.** Erst sinnvoll, wenn der Zustand
  komplexer wird als jetzt.
- **Keine Anmeldung, keine Konten.** Es gab einmal Anmelde- und
  Registrierungsbildschirme aus dem Klickdummy — mit `testuser`/`1234` fest im
  Code. Sie sind entfernt, und zwar nicht aus Bequemlichkeit: Ein Login
  schützt den Zugang zu etwas. Smile hat keinen Server, kein Konto und bewahrt
  nichts auf. Ein Passwort läge im selben Speicher wie die Daten, die es
  schützen soll, und ohne Server gäbe es keinen Weg, es zurückzusetzen. Dazu
  kämen Pflichten (Passwörter halten, Auskunfts- und Löschrechte nach DSG) für
  einen Schutz, den es gar nicht gibt. Eine grundlose Hürde vor einer App, die
  Hemmschwellen abbauen soll, ist zudem genau die falsche erste Begegnung.
- **Keine Persistenz.** Erfasste Anfragen leben nur, solange die App offen
  ist. Das ist eine bewusste Entscheidung, keine Lücke: Zahnarztrechnungen
  sind Gesundheitsdaten, und was nicht gespeichert wird, kann nicht abfliessen.
  Die Anfrage lebt nach dem Senden in der Mail-App des Nutzers weiter.
  Soll die Historie doch erhalten bleiben, gehören zwei Dinge zusammen:
  verschlüsselte lokale Speicherung **und** eine Gerätesperre (Fingerabdruck
  oder Gerätecode über das Betriebssystem) — aber weiterhin kein Konto.
