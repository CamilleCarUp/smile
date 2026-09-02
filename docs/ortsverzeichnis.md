# Ort der Praxis und zuständige Ombudsstelle

## Warum überhaupt

Findet die App etwas an einer Rechnung, ist die Ombudsstelle der nächste
Schritt. Es gibt 21 davon. Wer verunsichert ist, soll nicht 21 Einträge
durchsuchen, sondern die richtige zuoberst sehen.

Zuständig ist die Stelle im **Kanton der Zahnarztpraxis**, nicht am Wohnort
des Patienten — wer auswärts behandelt wird, käme sonst an die falsche
Adresse. Von Camille bestätigt; die App richtet sich danach.

## Woher der Kanton kommt

1. **Aus der Rechnung.** Der Parser liest den Adressblock der Praxis
   (`logic/invoice_parser.dart`), `logic/praxis_ort.dart` zieht daraus
   Postleitzahl und Ort. Bewusst nur aus dem Block der Praxis: Auf derselben
   Seite steht die Adresse des Patienten, und eine Suche über die ganze Seite
   würde früher oder später dessen Wohnort erwischen.
2. **Übersetzung in einen Kanton** über `data/plz_verzeichnis.dart`: zuerst
   über die Postleitzahl, ersatzweise über den Ortsnamen. Widersprechen sich
   die beiden, gibt es keine Antwort.
3. **Sonst:** die vollständige Liste, ohne Hervorhebung. Lieber nichts sagen
   als jemanden an die falsche Stelle schicken.

Bewusst kein Kanton im Profil als Notbehelf: Er stünde neben der Rechnung als
zweite, von Hand gepflegte Quelle — und könnte ihr nur widersprechen. Ein
Feld, das man ausfüllen muss und das im besten Fall dasselbe sagt wie die
Rechnung, ist eines zu viel.

Der ermittelte Kanton wird bei der Erfassung einmal bestimmt und mit der
Rechnung gespeichert. Ein später aktualisiertes Verzeichnis beantwortet eine
alte Rechnung damit nicht nachträglich anders.

## Die Datenquelle

Amtliches Ortschaftenverzeichnis von swisstopo
(`ch.swisstopo-vd.ortschaftenverzeichnis_plz`), rund 5700 Zeilen für rund 4000
Ortschaften, je Zeile eine Kombination aus Ortschaft und Gemeinde mit `PLZ4`,
`Ortschaftsname`, `Kantonskürzel` und `Adressenanteil`. swisstopo stellt
monatlich eine aktualisierte Fassung kostenlos zum Download bereit. Anders als
beim Tarifkatalog steht der Nutzung nichts entgegen.

Im Repository liegt nur die abgeleitete Tabelle
`assets/reference-data/plz_kantone.csv`, nicht der Originaldatensatz. Sie
enthält zwei Arten von Zeilen:

```
8005,ZH      Postleitzahl -> Kanton      (3147 Einträge)
zurich,ZH    Ortsname -> Kanton          (3937 Einträge)
```

### Warum auch der Ortsname

Weil das Ortschaftenverzeichnis die **Postfach-Postleitzahlen nicht kennt**.
`3000 Bern` und `1211 Genève` stehen nicht darin, auf Briefköpfen aber
sehr wohl. Über den Ortsnamen ist der Kanton trotzdem zu finden.

Verglichen wird nicht der Name, sondern seine Normalform
(`data/ort_schluessel.dart`): Kleinbuchstaben, Umlaute und Akzente aufgelöst,
alles übrige zu Leerzeichen. `8004 Zürich 4` und `Zürich` ergeben denselben
Schlüssel. Dieselbe Funktion erzeugt die Tabelle und liest sie in der App; ein
Test prüft, dass in der ausgelieferten Datei nur normalisierte Schlüssel
stehen.

### Widersprechen sich die beiden

Dann gibt es keine Antwort. Liest die Texterkennung `3005 Zürich`, sagt die
Postleitzahl Bern und der Ort Zürich — eine verdrehte Ziffer. Die App zeigt
dann die vollständige Liste, statt jemanden an die falsche Stelle zu schicken.

### Postleitzahlen über Kantonsgrenzen

169 der 3177 Postleitzahlen reichen über eine Kantonsgrenze. Dafür gibt es die
Spalte `Adressenanteil`: Aufgenommen wird ein Eintrag nur, wenn mindestens
90 Prozent der Adressen im selben Kanton liegen. So kommt `8500` als `TG` in
die Tabelle (Frauenfeld), während 30 wirklich geteilte Postleitzahlen und
20 geteilte Ortsnamen ganz wegbleiben — Weiler wie Jungfraujoch, Rigi Kaltbad
oder Sihlbrugg. Der Kopf der erzeugten Datei zählt sie namentlich auf.

### Tabelle erzeugen oder auffrischen

```
# Datensatz herunterladen und entpacken
https://data.geo.admin.ch/ch.swisstopo-vd.ortschaftenverzeichnis_plz/ortschaftenverzeichnis_plz/ortschaftenverzeichnis_plz_2056.csv.zip

# daraus die Tabelle bauen
dart run tool/plz_kantone_erzeugen.dart <pfad-zur-csv>
```

Das Werkzeug schreibt je Postleitzahl und je Ortsname eine Zeile und vermerkt
im Kopf der Datei, was es ausgelassen hat. Fehlt die Tabelle oder ist sie
leer, startet die App trotzdem und zeigt die vollständige Liste der
Ombudsstellen.

## Bekannte Grenzen

- **Postfach-Postleitzahlen fehlen** im Ortschaftenverzeichnis; die
  Dokumentation weist ausdrücklich darauf hin, dass es nicht für Postadressen
  gedacht ist. Aufgefangen wird das über den Ortsnamen — nur wenn auch der
  nicht zu lesen war, bleibt der Kanton offen.
- **Liechtenstein** steht ohne Kantonskürzel im Verzeichnis und fällt beim
  Erzeugen heraus.
- **Für Nidwalden, Obwalden und Uri** ist keine eigene Ombudsstelle bekannt.

## Entschieden

Ob die Stelle im Kanton der Praxis oder am Wohnort zuständig ist, war eine
Weile offen. Es ist die **Praxis**. Die App und der Hinweistext im
Ombudsstellen-Bildschirm sagen genau das.
