# Vor der Veröffentlichung

Was noch fehlt, bevor Smile in einen Store darf. Getrennt in *blockiert*
(geht nicht ohne), *auszufüllen* (nur Arbeit) und *zu prüfen* (braucht eine
Fachperson).

## Blockiert

- **Nutzungsrechte am Tarif.** Der Offline-Tarifbrowser ist „frei einsehbar",
  eine weitergehende Nutzung ist „ausdrücklich untersagt". Ohne Klärung mit
  der SSO bleibt der Referenzkatalog bei 14 Positionen. Siehe
  [tarifdaten.md](tarifdaten.md). In derselben Anfrage: die kommerzielle
  Nutzung, die Bezugsgrösse je Position und die Frage, ob die behandelnde
  Person auf der Rechnung auszuweisen ist.

## Auszufüllen

- **Impressum.** `lib/data/rechtstexte.dart` enthält Platzhalter in ‹spitzen
  Klammern›. `Rechtstexte.offenePunkte` zählt sie auf, ein Test hält fest,
  dass sie noch da sind, und der Bildschirm sagt es sichtbar. Verlangt wird
  die Anbieterkennzeichnung nach UWG Art. 3 lit. s: Name oder Firma, Adresse,
  eine erreichbare E-Mail-Adresse.
- **Datenschutzerklärung als Webseite.** Apple und Google verlangen eine URL,
  unabhängig davon, dass die App nichts erhebt. Der Text aus
  `Rechtstexte.datenschutz` kann eins zu eins dorthin.
- **Store-Formulare.** Apple „App Privacy" und Google „Datensicherheit":
  überall *keine Datenerhebung*. Falsche Angaben dort sind der häufigste
  Rückweisungsgrund. Zu erwähnen ist einzig, dass ML Kit auf Android sein
  Erkennungsmodell über die Google-Play-Dienste nachlädt — Software, keine
  Nutzerdaten.
- **Store-Beschreibung.** Nicht „findet überhöhte Rechnungen" versprechen.
  Smile macht eine Rechnung lesbar und prüft, was sich belegen lässt — das
  hält sie ein, das andere nicht.
- **Name und Marke.** „Smile" vor dem Launch in Swissreg und in beiden Stores
  auf Kollisionen prüfen. DENTOTAR ist eine Marke der SSO und gehört weder in
  den App-Namen noch in die Beschreibung.
- **App-Symbol, Startbild, Altersfreigabe** (keine Einschränkung nötig, die
  App richtet sich an Erwachsene, enthält aber Gesundheitsbezug).

## Zu prüfen

Ich bin kein Anwalt. Vorlegen lassen sollte man:

- die drei Texte in `lib/data/rechtstexte.dart`,
- den Haftungsausschluss im Besonderen — in der Schweiz lässt sich die Haftung
  für Absicht und grobe Fahrlässigkeit nicht wegbedingen (Art. 100 OR); der
  Text behauptet das auch nicht,
- die Aussage „kein Medizinprodukt". Smile beurteilt Rechnungen, keine
  Befunde; die MepV dürfte nicht greifen. Das sollte einmal jemand bestätigen,
  bevor es jemand anders bestreitet.

## Was bereits stimmt

- Keine Konten, kein Server, keine Analysewerkzeuge, keine Werbung.
- Verschlüsselte Ablage, Schlüssel im Keystore/Keychain.
- Gerätesicherung und Gerätewechsel-Übertragung abgeschaltet — sonst lägen
  Gesundheitsdaten in einer Cloud-Sicherung.
- Ein Löschweg, der die Zusage im Datenschutztext einhält: „Alle Daten
  löschen" unter *Meine Angaben* entfernt Verlauf und Angaben und stellt den
  Zustand nach der Installation her.
- Freiwillige App-Sperre über Fingerabdruck, Gesicht oder Gerätecode.
