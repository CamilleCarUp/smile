# Referenz-Tarifdaten — Status und Herkunft

> ⚠️ **Vor jeder Veröffentlichung lesen.** Die aktuell hinterlegten Daten sind
> provisorisch und rechtlich nicht geklärt.

## Was hinterlegt ist

`assets/reference-data/dentotar_seed.json` enthält:

- **14 Tarifpositionen** mit Taxpunkte-Werten
- **10 standardisierte Behandlungsmuster** aus der Thesis

## Woher die Werte stammen

| Quelle | Zuverlässigkeit |
|---|---|
| Taxpunkte direkt aus dem Klickdummy (Kap. 4.4.2 der Thesis) | belastbar |
| Aus CHF-Beträgen der Thesis (Tabelle 3) zurückgerechnet, Annahme TPW = 1.20 | **Annahme**, nicht verifiziert |

Die zurückgerechneten Werte sind eine Rekonstruktion. Stimmt der angenommene
Taxpunktwert nicht, sind sie systematisch falsch.

## Rechenmodell

```
Preis = Taxpunkte (TP) × Taxpunktwert (TPW)
```

Der **Taxpunktwert ist praxisabhängig** und liegt üblicherweise zwischen 1.0
und 1.7. Er ist damit kein Fehler im System, sondern ein legitimer
Preisgestaltungsspielraum — ein hoher TPW allein ist **keine** Auffälligkeit
und darf auch nicht als solche dargestellt werden.

## Was vor einer Veröffentlichung nötig ist

1. **Vollständiger DENTOTAR-Katalog** statt 14 Positionen. Der offizielle
   Tarif umfasst ein Vielfaches davon; mit 14 Codes ist keine echte Rechnung
   vollständig prüfbar.
2. **Klärung der Nutzungsrechte** mit der SSO bzw. über
   [mtk-ctm.ch](https://www.mtk-ctm.ch). Der Tarif ist ein gepflegtes Werk —
   ob und wie er in einer App abgebildet werden darf, ist offen und muss vor
   einer Store-Veröffentlichung geklärt sein.
3. **Verifikation** der zurückgerechneten Werte gegen die Originalquelle.
4. **Versionierung**: Tarife ändern sich. Die Datei braucht ein Stand-Datum,
   und die App muss veraltete Daten kenntlich machen.

## Haltung der App

Die App vergleicht eine Rechnung mit einem Referenzmuster und macht auf
Abweichungen aufmerksam. Sie stellt **keine** Behauptung über Richtigkeit oder
Absicht auf. Diese Unterscheidung ist nicht nur juristisch relevant, sondern
auch für die Akzeptanz bei Zahnärztinnen und Zahnärzten entscheidend — die
Thesis identifiziert die Anreizstruktur, nicht die Technik, als grösste Hürde.
