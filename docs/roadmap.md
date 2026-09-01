# Roadmap

## Phase 0 — UI-Grundgerüst ✅
Alle 14 Screens aus dem Klickdummy als echte Flutter-App, Navigation,
Farbpalette und Theme übernommen. Zustand noch komplett simuliert.

## Phase 1 — Erfassung & Texterkennung ✅
- Kamera-Aufnahme, Galerie-Mehrfachauswahl
- PDF-Import inkl. Aufteilung mehrseitiger Dokumente in Einzelseiten
- On-Device-Texterkennung via Google ML Kit
- Debug-Ansicht für den erkannten Rohtext

Erkenntnis aus dem ersten Praxistest: Ein **Foto vom Bildschirm** liefert
unbrauchbare Ergebnisse (die Werkzeugleiste des PDF-Betrachters landet im
Text). Deshalb der direkte PDF-Import.

## Phase 2 — Echte Tarifcode-Erkennung ⏳ *als Nächstes*
Der eigentliche inhaltliche Kern.

Zentrale technische Anforderung: **Die Positionsdaten von ML Kit müssen
genutzt werden, nicht der flache Text.** Rechnungen sind Tabellen; im
flachgeklopften `.text`-String verlieren Betrag und Tarifcode ihren Bezug
zueinander. ML Kit liefert pro Textblock Bounding Boxes — daraus lassen sich
Zeilen und Spalten rekonstruieren.

Schritte:
1. Zeilen-/Spaltenrekonstruktion aus den Bounding Boxes
2. Tarifcodes per Muster erkennen (`4.xxxx`)
3. Beträge der jeweiligen Zeile zuordnen
4. Abgleich gegen die Referenzdaten (siehe [tarifdaten.md](tarifdaten.md))
5. Taxpunktwert aus der Rechnung ableiten oder erfragen

Alles davon steckt in `lib/logic/invoice_matcher.dart` — Screens und Tests
bleiben unangetastet.

## Phase 3 — Abgleich & Bewertung
Verfeinerung der Auffälligkeits-Erkennung: Mehrfachverrechnung, Positionen
ausserhalb des typischen Behandlungsmusters, ungewöhnlicher Taxpunktwert.
Wichtig: **keine Verdachtsäusserung, sondern eine Rückfrage.** Die App stellt
fest, was vom Referenzmuster abweicht — sie unterstellt keine Absicht.

## Phase 4 — Rückfrage an die Praxis ✅ (Grundfunktion)
Automatisch erzeugter, höflich formulierter E-Mail-Entwurf über die Mail-App
des Nutzers. Ergänzend: Verzeichnis der kantonalen SSO-Ombudsstellen.

Offen: Vorlagen-Varianten, Nachfass-Erinnerung.

## Phase 5 — Mehrsprachigkeit & Onboarding
DE / FR / IT. Für die Schweiz keine Kür, sondern Voraussetzung. Dazu ein
Onboarding, das den Zweck der App erklärt — inklusive der Aussage, dass Daten
das Gerät nicht verlassen.

## Phase 6 — Store-Reife
- Persistenz der Anfragen
- Datenschutzerklärung, App-Store-Angaben zur Datennutzung
- Icons, Screenshots, Store-Texte
- iOS-Build und -Test (bisher ausschliesslich auf Android getestet)
- Apple Developer Program: 99 USD/Jahr; Google Play: 25 USD einmalig

## Phase 7 — Optional: Ausbau
Funktionen mit Nutzen für beide Seiten (z. B. Kostenvoranschlag-Vergleich),
mögliche Innosuisse-Förderung.
