# Referenz-Tarifdaten — Status und Herkunft

> 🚫 **Der grösste offene Punkt des Projekts.** Die Tarifdaten sind geprüft,
> aber die Nutzungsrechte sind ungeklärt — und das blockiert eine
> Veröffentlichung, nicht nur die Vollständigkeit.

## Was hinterlegt ist

`assets/reference-data/dentotar_seed.json` enthält **14 Tarifpositionen** sowie
10 standardisierte Behandlungsmuster aus der Thesis.

Der offizielle Katalog umfasst **rund 578 Positionen**. Wir haben also 2 % —
genug, um eine Füllungsbehandlung vollständig zu prüfen, für beliebige
Rechnungen bei weitem zu wenig.

## Die Rechtslage

Der Offline-Tarifbrowser der ZMT (Tarif 222, Version V2.00 / 01.01.2025)
enthält den vollständigen Leistungskatalog. Sein Nutzungshinweis sagt wörtlich:

> „Der im vorliegenden Offline-Tarifbrowser enthaltene Leistungskatalog des
> Zahnarzt-Tarifs ist im Sozialversicherungsbereich UV/MV/IV anwendbar und für
> die interessierte Öffentlichkeit frei einsehbar. […] **Eine weitergehende
> Nutzung des Offline-Browsers ist ausdrücklich untersagt.**"

Frei *einsehbar* ist nicht frei *verwendbar*. Nachschlagen, ob unsere Werte
stimmen, ist Einsicht. Den Katalog in eine App zu übernehmen und auszuliefern,
ist die untersagte weitergehende Nutzung. Dasselbe gilt für die CHM-Fassung —
gleicher Inhalt, gleiche Bedingungen.

Aus diesem Grund wurden 63 zuvor aus einem MTK-Dokument übernommene Positionen
wieder **entfernt**. Sie stammen aus derselben Dokumentenfamilie desselben
Herausgebers.

### Wen es zu fragen gilt

Nicht die ZMT, sondern die **SSO**. Der Katalog der ZMT gilt für die
Sozialversicherung (Unfall, Militär, Invalidenversicherung). Smile richtet
sich an **Privatpatienten** — dort gilt DENTOTAR®, herausgegeben von der
Schweizerischen Zahnärzte-Gesellschaft SSO, mit eigenen Nutzungsbestimmungen.
Die Anfrage muss also lauten: Darf eine patientenseitige App den
DENTOTAR-Katalog zur Rechnungsprüfung verwenden, und zu welchen Bedingungen?

## Prüfstand der 14 Positionen

Alle 14 Werte stimmen **exakt** mit der amtlichen Fassung überein. Der Weg
dorthin, weil er zeigt, wie belastbar die Werte sind:

1. Sieben Werte waren aus dem Klickdummy der Thesis exakt bekannt.
2. Für sie ergab die publizierte Tarifübersicht durchgehend dasselbe
   Verhältnis: `unterer Preis = TP × 0.85`, `oberer Preis = TP × 1.15`.
3. Damit liessen sich die übrigen sieben Taxpunkte zurückrechnen — sie lagen
   zuvor um 0.1 bis 0.4 TP daneben und wurden korrigiert.
4. Der amtliche Katalog bestätigt anschliessend **alle vierzehn**, inklusive
   der sieben rekonstruierten, und weist das 0.85/1.15-Band als
   `TP (PP) min` / `TP (PP) max` selbst aus.

## Rechenmodell und Taxpunktwerte

```
Preis = Taxpunkte (TP) × Taxpunktwert (TPW)
```

| Bereich | Taxpunktwert |
|---|---|
| Privatpatienten (DENTOTAR) | nach oben auf **1.70** begrenzt, nach unten frei |
| UV / MV / IV (Unfall, Militär, Invalidenversicherung) | fest **1.00** |
| Obligatorische Krankenpflegeversicherung (KVG) | fest **3.10**, nach einem älteren Katalog von 1994 |

Der Taxpunktwert für Privatpatienten ist **praxisabhängig und legitim**. Ein
hoher Taxpunktwert allein ist keine Auffälligkeit und darf nicht als solche
dargestellt werden — er ist Preisgestaltung, kein Fehler.

### Eine Mehrdeutigkeit, die sich nicht auflösen lässt

Publizierte Preisspannen entsprechen einem Band von etwa 0.85 bis 1.15, die
Obergrenze liegt bei 1.70. Der zulässige Bereich umfasst damit genau den
Faktor 2. Zum halben Taxpunktwert mit doppelten Mengen passt eine Rechnung
deshalb **rechnerisch immer genauso gut**.

Der Resolver erkennt diesen Fall und meldet ihn
(`ResolverWarning.taxpunktwertAmbiguous`). Er wählt dann den grösseren
Taxpunktwert, weil dieser die kleineren Mengen ergibt: lieber eine doppelte
Verrechnung übersehen als eine behaupten, die es nicht gibt.

## Gegenprobe am amtlichen Tarif (Tarif 222, V2.00 / 1.1.2025)

Der Offline-Tarifbrowser wurde eingesehen — was er ausdrücklich erlaubt.
Übernommen wurde nichts. Festgehalten sind hier nur Feststellungen über
unser eigenes Rechenmodell:

**Das Taxpunkte-Band für Privatpatienten ist bestätigt.** Der Tarif führt zu
jeder Position drei Werte: `TP (UV/MV/IV)` als Mittelwert sowie `TP (PP) max`
und `TP (PP) min`. Über die eingesehenen Positionen liegt das Verhältnis
konstant bei 1.150 nach oben und 0.850 nach unten — bei 4.0020
(Kurzbefundaufnahme, in unserem Seed mit 33.1) sind es 38.10 und 28.10, also
1.1511 und 0.8489. Unser `taxpunkteMaxAufschlag = 1.16` ist damit als
sichere Obergrenze belegt und nicht mehr geschätzt. Und die Beobachtung an
den echten Rechnungen — dieselbe Position einmal mit 181.3, einmal mit 208.5,
Verhältnis exakt 1.15 — ist der Tarif selbst, nicht ein Zufall.

**Die Qualifikationsstufen sind bestätigt.** Kapitel 02.03 führt vier
getrennte Positionen für dieselbe Arbeit, je nach behandelnder Person, alle
im Zeittarif pro 5 Minuten: Praktikantin PA, PA, Praktikantin DH, DH — mit
steigenden Taxpunkten. Die App sieht also am Code, welche Stufe verrechnet
wurde; wer tatsächlich am Stuhl stand, weiss nur der Patient.

**Die Zuständigkeit ist bestätigt.** Das Titelblatt hält fest, dass die SSO
Herausgeberin der Kalkulationshilfe für Privatpatienten (DENTOTAR®) ist und
dass deren Nutzungsbestimmungen über sso.ch erhältlich sind. Genau die
gehören vor die Anfrage — möglicherweise steht die Antwort dort schon.

## Die Lizenzlage — gefunden, nicht mehr vermutet

Das Titelblatt des amtlichen Tarifs verweist für die Nutzungsbestimmungen auf
sso.ch. Auf den öffentlichen Seiten stehen sie **nicht**; weder die
Tarif-Seite noch die DENTOTAR-Seite (dentotar.ch leitet dorthin um) nennen
Lizenz, Entgelt oder eine Stelle für Dritte. Sie stehen in der *Beilage zur
Beitrittserklärung zum Tarifvertrag DENTOTAR* — einem Lizenzvertrag, der über
die Suche auffindbar ist.

Was darin steht:

- **Der Tarif ist urheberrechtlich geschützt** (1.1). Das war zu erwarten,
  ist jetzt aber belegt statt angenommen.
- **Lizenzgeberin ist die SSO.** Lizenznehmer sind nur Zahnärztinnen und
  Zahnärzte in eigener fachlicher Verantwortung — SSO-Mitglieder oder
  ausdrücklich zugelassene Einzelkontrahenten (6.1).
- **Die Lizenz ist entgeltlich** und erlischt bei Nichtzahlung (2).
  Unterlizenzierung ist untersagt (3), inhaltliche Änderungen ebenso (4.1).
- **Und der entscheidende Punkt (1.3 a):** Der Tarif darf in „eigens
  erstellten, nicht kommerziell vertriebenen Programmen oder im Rahmen von
  Zahnarztpraxis-Software Lösungen Dritter" genutzt werden — sofern deren
  IT-Anbieter von der SSO berechtigt worden sind. Für diese gibt es eine
  eigene Kategorie: **„DENTOTAR® IT-Partner"**.

### Was das für Smile heisst

Es gibt einen benannten Weg, und er heisst nicht „Ausnahme erbitten", sondern
**IT-Partner**. Die Anfrage an die SSO kann sich darauf beziehen statt
allgemein um Erlaubnis zu bitten.

Der Haken ist ehrlich zu benennen: Die Kategorie ist für Praxissoftware
gedacht, hinter der ein lizenzierter Zahnarzt steht. Smile richtet sich an
Patienten; dort gibt es keinen Lizenznehmer, in dessen Rahmen die Nutzung
läuft. Die Frage lautet deshalb präzise: *Gibt es für eine patientenseitige
Anwendung eine Berechtigung analog zum DENTOTAR® IT-Partner — und zu welchen
Bedingungen?*

Das ist eine Geschäftsfrage, keine Bittstellerei. Die SSO lizenziert den
Tarif regelmässig und gegen Entgelt; es gibt einen Prozess und einen Preis.

## Regel 2 braucht keine Statistik, sondern den Tarif

Diese Feststellung korrigiert einen früheren Plan. Angenommen war, für Regel
2 brauche es erhobene Behandlungsmuster — wie oft eine Leistung *üblich*
ist. Der Tarif enthält stattdessen **harte Limitationen im Klartext**, je
Position:

- „Darf pro Patient innerhalb von 12 Monaten in der gleichen Praxis nur 1 mal
  verrechnet werden."
- „Maximal 6 mal pro Sitzung verrechenbar."
- „Maximal 30 Minuten pro Sitzung; maximal 4 mal pro Jahr verrechenbar."
- „Leistung X ist nicht kumulierbar mit Leistung Y."

Das sind prüfbare Regeln, keine Erwartungswerte. Regel 2 wird damit
deterministisch und belegbar — von derselben Art wie Regel 1, nicht von der
Art „das kommt uns viel vor". Was fehlt, ist ausschliesslich das Recht, diese
Angaben zu verwenden.

Für die Anfrage heisst das: Die Limitationen und Kumulationsverbote sind
genauso wichtig wie Positionsnummer und Taxpunkte — und sie liegen bereits
strukturiert vor.

## Wenn die Rechte da sind: zwei Dinge, nicht eines

Mit den Nutzungsrechten kommt der **Katalog** — Code, Bezeichnung, Taxpunkte,
und hoffentlich die Bezugsgrösse je Position. Das ist ein Import wie beim
Ortschaftenverzeichnis: ein Werkzeug unter `tool/`, das die Quelle in eine
abgeleitete Tabelle verwandelt, plus ein Test gegen die ausgelieferte Datei.
Damit wird das Nachrechnen vollständig statt exemplarisch.

Die **Erklärungen in `lib/data/erklaerungen.dart` kommen nicht mit.** Der
Tarif sagt „Schmelzätzung und Anbringen des Haftvermittlers"; der Satz „der
Zahnschmelz wird mit einem Gel angeraut, damit der Kunststoff hält" muss
weiterhin jemand schreiben — abschreiben dürften wir ihn ohnehin nicht, und
er wäre auch keine Erklärung.

Die App verträgt dieses Gefälle: Zu einer Position ohne Erklärung sagt sie
das, statt eine zu erfinden. Reihenfolge beim Nachziehen:

1. die häufigsten Positionen — Konsultation, Röntgen, Anästhesie, Füllungen,
   Dentalhygiene, Extraktion,
2. was auf echten Rechnungen tatsächlich auftaucht (der beste Filter, den wir
   haben),
3. der Rest, nach Bedarf.

Zwei Dutzend davon einmal von einer Fachperson gegenlesen zu lassen, wäre
dieselbe Gelegenheit wie bei den Behandlungsmustern für Regel 2.

## Was vor einer Veröffentlichung nötig ist

1. **Nutzungsrechte mit der SSO klären.** Ohne das geht nichts weiter — siehe
   oben. Dieser Punkt entscheidet, ob Smile in dieser Form erscheinen kann.
2. **Katalog vervollständigen** — erst nach Punkt 1, und auf dem Weg, den die
   SSO dafür vorsieht.
3. **Versionierung einführen.** Tarife ändern sich; die geltende Fassung ist
   seit 01.01.2025 in Kraft. Die Datei braucht ein Stand-Datum, und die App
   muss veraltete Daten kenntlich machen.
4. **Die Lücke sichtbar machen.** Mit 14 von 578 Positionen darf ein „keine
   Abweichung gefunden" nicht wie ein Freispruch aussehen. Fehlende Daten und
   fehlende Auffälligkeiten sind zwei verschiedene Aussagen.

### Falls die Rechte nicht zu bekommen sind

Es gibt einen Ausweg, der ohne Katalog auskommt: **Rechnungen drucken ihre
Taxpunkte selbst mit.** Auf der Testrechnung stehen sie in einer eigenen
Spalte. Der Resolver braucht nur Taxpunkte und Zeilenbetrag — beides steht auf
dem Papier. Die Referenzdatenbank wäre dann nicht mehr nötig, um zu *rechnen*,
sondern nur noch, um zu *beurteilen*, ob eine Position zur Behandlung passt.
Das ist weniger, aber es wäre eine App, die niemandes Rechte berührt.

## Haltung der App

Die App vergleicht eine Rechnung mit einem Referenzmuster und macht auf
Abweichungen aufmerksam. Sie stellt **keine** Behauptung über Richtigkeit oder
Absicht auf. Diese Unterscheidung ist nicht nur juristisch relevant, sondern
auch für die Akzeptanz bei Zahnärztinnen und Zahnärzten entscheidend — die
Thesis identifiziert die Anreizstruktur, nicht die Technik, als grösste Hürde.

## Quellen

- [SSO Zahnarzttarif / DENTOTAR](https://www.sso.ch/de/zahnarzttarif)
- [MTK — Zahnarzttarif SSO (Tarif 222)](https://www.mtk-ctm.ch/de/tarife/zahnarzttarif-sso/)
- [MTK — Zahnarzttarif UV/MV/IV, Vergleich neu/alt 2018 (PDF)](https://www.mtk-ctm.ch/application/files/3317/6760/4591/ZahnarztTarif_2018_UV-MV-IV_Vergleich_neu-alt.pdf)
- [Publizierte Tarifübersicht mit Preisspannen (PDF)](https://www.beobachter.ch/sites/default/files/zahnarzttarife.pdf)
- Klickdummy und Tabelle 3 der MAS-Thesis (Eichmann, ETH Zürich)
