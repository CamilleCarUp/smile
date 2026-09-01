# Smile

Mobile App (Android + iOS), mit der Patientinnen und Patienten in der Schweiz
ihre **Zahnarztrechnung auf Nachvollziehbarkeit prüfen** können: Rechnung
fotografieren oder als PDF importieren, Tarifpositionen erkennen, gegen
Referenzwerte abgleichen, auffällige Positionen markieren und daraus eine
höfliche Rückfrage an die Zahnarztpraxis erzeugen.

Grundlage ist die MAS-Thesis von Cédric Eichmann (ETH Zürich), *„Design and
Evaluation of a Patient-Centered Platform for Dental Invoice Transparency in
Switzerland"*, sowie der daraus entstandene HTML-Klickdummy.

## Leitprinzip: Local-First

Rechnungsdaten sind Gesundheitsdaten. Die App verarbeitet sie deshalb
**vollständig auf dem Gerät** — Texterkennung, PDF-Rendering und Abgleich
laufen offline. Es gibt (bewusst) keinen Backend-Server, der Rechnungen
entgegennimmt. Die Rückfrage-E-Mail wird über die Mail-App des Nutzers
verschickt, nicht über einen Server von uns.

## Aktueller Stand

| Bereich | Stand |
|---|---|
| UI-Grundgerüst (14 Screens, Design aus dem Klickdummy) | ✅ fertig |
| Kamera, Galerie-Mehrfachauswahl, PDF-Import | ✅ fertig, läuft auf echtem Gerät |
| On-Device-Texterkennung (Google ML Kit) | ✅ fertig |
| Tarifcode-Erkennung & Abgleich mit Referenzdaten | ⏳ Demo-Daten, echtes Parsing = Phase 2 |
| Rückfrage-E-Mail (mailto-Entwurf) | ✅ fertig |
| Ombudsstellen-Verzeichnis (21 Kantone) | ✅ fertig |
| Kostenschätzung (Taxpunkte × Taxpunktwert) | ✅ fertig |
| Mehrsprachigkeit DE/FR/IT | ⏳ offen |
| Store-Veröffentlichung | ⏳ offen |

Details siehe [docs/roadmap.md](docs/roadmap.md).

## Schnellstart

```bash
flutter pub get
flutter test          # 18 Tests, kein Gerät nötig, wenige Sekunden
flutter run           # auf verbundenem Gerät/Emulator
```

Einrichtung der Entwicklungsumgebung (Flutter, Android SDK, NDK, kabelloses
Debugging): [docs/entwicklung.md](docs/entwicklung.md).

## Dokumentation

- [docs/architektur.md](docs/architektur.md) — Modulaufbau, wo was liegt und warum
- [docs/entwicklung.md](docs/entwicklung.md) — Setup, Tests, bekannte Stolpersteine
- [docs/roadmap.md](docs/roadmap.md) — Phasen 0–7
- [docs/tarifdaten.md](docs/tarifdaten.md) — Herkunft und Status der Referenzdaten ⚠️ vor Veröffentlichung lesen

## Lizenz / Vertraulichkeit

Dieses Repository ist vorerst **privat**. Es enthält aus der Thesis
abgeleitete Tarifdaten, deren Verwendungsrechte noch nicht geklärt sind —
siehe [docs/tarifdaten.md](docs/tarifdaten.md).
