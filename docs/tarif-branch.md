# Branch `tarif-mit-rechten`

Dieser Branch nimmt an, dass die Nutzungsrechte am Zahnarzttarif SSO
vorliegen. Er existiert, damit die Rechtefrage die Entwicklung nicht
aufhält — **nicht**, um sie zu umgehen.

## Die eine Regel

**Auf diesem Branch liegen keine Tarifdaten.** Ein Branch macht das Kopieren
nicht zulässig, und was einmal in der Git-Historie steht, steht dort für
immer — auch auf GitHub, auch nach einem `git rm`.

Gebaut ist deshalb alles ausser den Daten:

| Vorhanden | Fehlt bis zur Lizenz |
|---|---|
| Datenmodell (Bandbreite, Limitationen, Kumulationsverbote, „Beinhaltet") | die Katalogdatei selbst |
| Regelwerk `logic/tarif_regeln.dart` | |
| Tests gegen einen **erfundenen** Katalog (Codes 9.xxxx) | |
| `.gitignore`-Eintrag für die erzeugte Datei | das Erzeugungswerkzeug |

Dasselbe Muster wie beim Ortschaftenverzeichnis: Werkzeug im Repository,
Datei lokal.

## Was der Branch prüfbar macht

Vier Regeln, die alle **ausformulierte Vorschriften** des Tarifs prüfen und
sie im Befund wörtlich zitieren können — keine Erwartungswerte:

1. **Höchstsatz je Position.** Bisher wird ein Faktor für die ganze Rechnung
   hergeleitet und mit dem Maximum verglichen. Der Tarif nennt je Position
   ihr eigenes `TP (PP) max`. Eine einzelne überteuerte Position, die im
   Durchschnitt untergeht, wird damit sichtbar. Gerechnet wird aus Betrag,
   Menge und Faktor zurück — nicht aus den Taxpunkten der Zeile, die aus dem
   Katalog stammen könnten und die Grenze dann gar nicht überschreiten
   *könnten*.
2. **Menge je Sitzung.** „Maximal 6 mal pro Sitzung verrechenbar." Prüfbar,
   seit das Zeilendatum gelesen wird — und ohne dieses Datum wäre es ein
   Fehlalarm, sobald eine Rechnung zwei Termine umfasst.
3. **Kumulationsverbote.** „Leistung X ist nicht kumulierbar mit Y." Das
   Verbot steht in beiden Einträgen; gemeldet wird es einmal.
4. **Wiederholung innert Frist.** „Darf innerhalb von 12 Monaten in der
   gleichen Praxis nur 1 mal verrechnet werden." **Das kann sonst niemand
   prüfen** — der Verlauf liegt auf dem Gerät des Patienten, und keine
   Praxissoftware und kein Versicherer sieht die Rechnungen eines Menschen
   über Jahre hinweg. „In der gleichen Praxis" wird dabei ernst genommen:
   Zwei Praxen, die nichts voneinander wissen, dürfen einander nicht
   angelastet werden.

## Sicherungen

- Ohne vollständigen Katalog prüft `TarifRegeln` **nichts**. Der
  mitgelieferte Seed enthält nur Taxpunkte; `TariffCatalog.istVollstaendig`
  bleibt falsch, und es bleibt bei Regel 1. Lieber keine Aussage als eine auf
  leeren Daten.
- Dieselbe Vorbedingung wie bei Regel 1: Wurde die Rechnung nicht belastbar
  gelesen, wird nichts behauptet.

## Demonstration vor der WiKo (22.10.2026)

Für die Vorführung liegen zwei Dinge **lokal** bereit, beide in `.gitignore`:

- `assets/reference-data/tarif_vollstaendig.json` — 12 Positionen von rund
  578. Die Taxpunkte der zehn Positionen, die auf vorliegenden Rechnungen
  aufgedruckt sind, stammen von dort. Die Bandbreite für Privatpatienten ist
  nicht abgeschrieben, sondern aus dem am Tarif überprüften Verhältnis
  (1.15 / 0.85) gerechnet. Zwei Positionen samt dem Wortlaut ihrer
  Limitationen wurden dem amtlichen Tarif entnommen, ausschliesslich um das
  Regelwerk vorführen zu können.
- `demo/` — zwei erzeugte Belege, unmissverständlich als
  Demonstrationsbelege gekennzeichnet, mit erfundener Praxis und erfundener
  Patientin.

Das ist Absicht und gehört auf eine Folie: Wir zeigen an zwölf Positionen,
was mit dem ganzen Katalog möglich wäre — und genau darum bitten wir. Ein
Prototyp, der bereits 578 Positionen enthielte, würde in diesem Raum die
falsche erste Frage auslösen.

## Vor dem Zusammenführen

1. Lizenz der SSO liegt vor (siehe [tarifdaten.md](tarifdaten.md)).
2. Das Erzeugungswerkzeug ist gebaut und die Katalogdatei lokal erzeugt.
3. Die Erklärungstexte sind für die häufigsten Positionen nachgezogen.
4. `flutter test` grün — auch mit vollständigem Katalog.

Bis dahin bleibt `main` veröffentlichungsfähig: Was dort läuft, stützt sich
auf vierzehn Positionen aus belegbaren Quellen.
