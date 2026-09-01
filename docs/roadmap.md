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

## Phase 3 — Bewertung

Grundsatz: **keine Verdachtsäusserung, sondern eine Rückfrage.** Die App stellt
fest, was sie belegen kann — sie unterstellt keine Absicht. Die beiden Fehler
sind nicht gleich teuer: Eine übersehene Doppelverrechnung kostet ein paar
Franken, ein Fehlalarm schickt jemanden mit einem unbegründeten Vorwurf zu
seinem Zahnarzt.

### Regel 1 — Preisniveau über dem tariflichen Höchstsatz ✅

Gebaut. Rein rechnerisch belegbar, ohne zahnmedizinisches Urteil: Der Tarif
begrenzt für Privatpatienten die Taxpunkte auf das 1.15-fache (`TP (PP) max`)
und den Taxpunktwert auf 1.70. Mehr als rund das **1.97-fache** der Taxpunkte
lässt er nicht zu.

Beim Bauen zeigte sich eine strukturelle Hürde: Halbiert man den Faktor und
verdoppelt alle Mengen, passt jede Rechnung rechnerisch genauso gut. Da jeder
Faktor über 1.70 halbiert noch über der Untergrenze 0.85 liegt, wäre **jede**
überteuerte Rechnung mehrdeutig — und die Regel könnte nie auslösen. Gelöst
über die Mengenspalte: Rechnungen drucken ihre Anzahl mit, und die widerlegt
die konkurrierende Lesart. Fehlt sie, bleibt es mehrdeutig und die App
schweigt.

### Regel 2 — Menge über dem Behandlungsmuster ⏳ OFFEN

**Das ist der Fall aus der Thesis** (Infiltrationsanästhesie zweimal bei einer
einflächigen Füllung) und der eigentliche Kern des ursprünglichen Konzepts.

Was schon da ist: Der Resolver ermittelt die Mengen zuverlässig — auf der
Testrechnung erkennt er die zweifache Anästhesie korrekt, auch ohne
Referenzdatenbank.

**Was fehlt: die erwarteten Mengen je Behandlungsmuster.** Die Referenzdatei
listet zu jedem Muster die Codes, aber nicht, wie oft jeder davon vorgesehen
ist. Diese Zahlen dürfen nicht geschätzt werden — sie müssen aus der Thesis
oder von zahnmedizinischer Seite kommen.

Voraussetzungen, bevor gebaut wird:
1. Erwartete Mengen je Muster, belastbar belegt
2. Geklärte Nutzungsrechte am Tarif (siehe [tarifdaten.md](tarifdaten.md))

Der Platz im Code ist markiert: `lib/logic/invoice_rules.dart`, unterhalb von
Regel 1. Die Markierung erklärt dort auch, warum die Regel absichtlich fehlt —
damit sie niemand versehentlich als Versäumnis „repariert".

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
