# Architektur

Ziel des Aufbaus: **Änderungen sollen lokal bleiben.** Wer die Analyse-Logik
ändert, soll keinen Screen anfassen müssen — und umgekehrt.

## Schichten

```
lib/
├── models/          Datenstrukturen, keine Logik
├── logic/           reine Geschäftslogik, KEINE Flutter-Abhängigkeit
├── data/            statische Referenzdaten
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

### `state/` — drei Controller statt eines Monolithen
Ursprünglich gab es eine einzige `AppState`-Klasse für alles. Die wurde
aufgeteilt, weil ein zentraler Zustand jede Änderung riskant macht und sich
kaum isoliert testen lässt:

| Datei | Zuständigkeit |
|---|---|
| `auth_controller.dart` | Login/Registrierung. Austauschbar gegen ein echtes Auth-System, ohne den Rest anzufassen. |
| `upload_controller.dart` | Ausgewählte Dateien, OCR-Ergebnisse, Anstoss der Auswertung. |
| `requests_repository.dart` | Verlauf der Anfragen (erfasst / gesendet / abgeschlossen). |

Alle drei sind `ChangeNotifier` mit je einer globalen Instanz
(`authController`, `uploadController`, `requestsRepository`). Bewusst einfach
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

## Tests

```
test/
├── logic/invoice_matcher_test.dart      Analyse-Logik (Summen, Markierungen)
├── models/request_test.dart             Getter der Datenmodelle
├── state/upload_controller_test.dart    Controller-Logik ohne UI
├── screens/upload_screen_test.dart      Widget-Test + Regressionstest
└── widget_test.dart                     Smoke-Test: App startet
```

`flutter test` — 18 Tests, kein Gerät nötig.

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
