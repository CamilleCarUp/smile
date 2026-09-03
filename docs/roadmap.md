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

**Was fehlt, ist nur das Recht — nicht das Wissen.** Der amtliche Tarif
enthält je Position ausformulierte Limitationen: „nur 1 mal innerhalb von 12
Monaten", „maximal 6 mal pro Sitzung", „nicht kumulierbar mit Leistung X".
Das sind prüfbare Regeln, keine Erwartungswerte — Regel 2 wird damit
deterministisch und belegbar, von derselben Art wie Regel 1. Eine Erhebung
über „übliche" Mengen braucht es dafür nicht.

Voraussetzung, bevor gebaut wird:
1. Geklärte Nutzungsrechte am Tarif, **einschliesslich der Limitationen und
   Kumulationsverbote** (siehe [tarifdaten.md](tarifdaten.md))

Der Platz im Code ist markiert: `lib/logic/invoice_rules.dart`, unterhalb von
Regel 1. Die Markierung erklärt dort auch, warum die Regel absichtlich fehlt —
damit sie niemand versehentlich als Versäumnis „repariert".

#### Was ohne Tarifrechte schon geht

Die Mengenregel steckt zu einem guten Teil in der **Bezugsgrösse** der
Position: pro Zahn, pro Fläche, pro Kanal, pro Sextant, pro Sitzung, pro
Zeiteinheit. Wo die Praxis sie mit ausdruckt, steht sie im Text der Rechnung —
und der gehört dem Nutzer, an ihm hängt keine Nutzungsbeschränkung.
`lib/logic/bezugsgroesse.dart` liest sie dort heraus.

Zwei Auswertungen bauen darauf auf, beide ohne Referenzdaten und ohne
geschätzte Schwellenwerte:

- **Zeitprobe.** Anzahl mal Takt ergibt die verrechnete Behandlungszeit. Das
  ist eine Addition, keine Schätzung — und der Nutzer ist der Einzige, der
  weiss, wie lange er tatsächlich im Stuhl sass.
- **Wer hat behandelt.** Der Tarif führt dieselbe Leistung unter verschiedenen
  Nummern, je nach Qualifikation (DH teurer als PA). Die App sieht, was
  verrechnet wurde; wer am Stuhl stand, weiss allein der Nutzer.

Beide sind Rückfragen an den Nutzer, keine Vorwürfe an die Praxis. Sie sind
die einzige Stelle, an der eine Rückfrage wirklich gerechtfertigt ist: Die
Antwort kann nirgends sonst herkommen.

**Ernüchterung aus der Testrechnung:** Diese Praxissoftware druckt
Kurzbezeichnungen *ohne* Bezugsgrösse — nur „einflächig" ist zu holen. Wie oft
Einheiten mitgedruckt werden, lässt sich erst mit mehr echten Rechnungen
sagen. Wo nichts dasteht, behauptet die App nichts.

Reine Obergrenzen (pro Sitzung höchstens 1, pro Sextant höchstens 6) sind
bewusst *nicht* gebaut: Eine Rechnung kann mehrere Sitzungen umfassen, und
dann sind sie schlicht falsch. Belastbar würden sie erst mit einem Datum je
Zeile — das wäre ein eigener Schritt in der Erkennung.

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
