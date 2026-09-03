/// Was eine Tarifposition in Alltagssprache bedeutet.
///
/// Auf der Rechnung steht "4.5800 Schmelzätzung und Anbringen des
/// Haftvermittlers". Das ist die Bezeichnung der Praxis, und sie sagt einem
/// Patienten nichts. Hier steht daneben, was dabei gemacht wurde.
///
/// Drei Dinge, die dieser Text nicht ist:
///
///   * **Keine Abschrift des Tarifs.** Die Saetze sind selbst geschrieben und
///     beschreiben allgemein bekannte zahnmedizinische Handgriffe. Die
///     Bezeichnung der Position kommt von der Rechnung des Nutzers, nicht aus
///     dem Katalog.
///   * **Keine Beurteilung.** Ob die Behandlung noetig oder richtig war, sagt
///     hier nichts. Es steht, was eine Position ueblicherweise umfasst.
///   * **Keine zahnmedizinische Beratung.** Wer wissen will, warum gerade bei
///     ihm so behandelt wurde, fragt die Praxis -- genau dafuer gibt es die
///     Rueckfrage.
///
/// Was fehlt, fehlt sichtbar: Zu einer unbekannten Position sagt die App, dass
/// sie keine Erklaerung hat, statt eine zu erfinden.
const Map<String, String> erklaerungen = {
  '4.0020': 'Ein kurzer Blick in den Mund, um festzustellen, was los ist — die '
      'übliche erste Position bei einem kurzfristigen Besuch oder einem Notfall.',
  '4.0300': 'Das Aufbereiten des Behandlungsplatzes: Flächen desinfizieren, '
      'Instrumente sterilisieren, Einwegmaterial bereitlegen. Fällt pro Behandlung an, '
      'unabhängig davon, was gemacht wurde.',
  '4.0500': 'Eine kleine Röntgenaufnahme, bei der der Sensor im Mund liegt. Sie zeigt, '
      'was von aussen nicht zu sehen ist — Karies zwischen den Zähnen und den Zustand '
      'der Wurzel.',
  '4.0650': 'Die örtliche Betäubung. Das Mittel wird neben dem Zahn in die Schleimhaut '
      'gespritzt und betäubt den Bereich um die Einstichstelle. Für die Behandlung '
      'eines Zahns reicht meist eine.',
  '4.2000': 'Das Ziehen eines Zahns ohne chirurgischen Eingriff — also ohne dass das '
      'Zahnfleisch aufgeklappt oder der Zahn zerteilt werden muss.',
  '4.5350': 'Eine Füllung aus zahnfarbenem Kunststoff (Komposit), die eine Fläche des '
      'Zahns wiederherstellt.',
  '4.5360': 'Jede weitere einflächige Füllung, die in derselben Sitzung im selben '
      'Kieferabschnitt gemacht wird. Sie kostet weniger als die erste, weil '
      'Vorbereitung und Betäubung schon da sind.',
  '4.5370': 'Eine Kunststofffüllung im Zwischenraum zweier Frontzähne — die Stelle, an '
      'der man Karies erst spät bemerkt.',
  '4.5390': 'Der Wiederaufbau einer abgebrochenen Ecke eines Frontzahns aus Kunststoff.',
  '4.5410': 'Eine Kunststofffüllung an einem kleinen Backenzahn, die zwei Flächen '
      'umfasst — meist die Kaufläche und eine Seitenfläche.',
  '4.5430': 'Eine Kunststofffüllung an einem grossen Backenzahn, die zwei Flächen '
      'umfasst — meist die Kaufläche und eine Seitenfläche.',
  '4.5450': 'Eine Kunststofffüllung an einem kleinen Backenzahn über drei Flächen. Je '
      'mehr Flächen, desto grösser der Schaden und desto aufwendiger der Aufbau.',
  '4.5470': 'Eine Kunststofffüllung an einem grossen Backenzahn über drei Flächen.',
  '4.5510': 'Ein Aufbau, der einen kleinen Backenzahn wieder in Form bringt — mehr als '
      'eine Füllung, weil ein Teil der Kaufläche neu modelliert wird.',
  '4.5530': 'Der Aufbau von ein bis zwei Höckern eines grossen Backenzahns. Höcker sind '
      'die Erhebungen der Kaufläche.',
  '4.5550': 'Der Aufbau von drei bis vier Höckern eines grossen Backenzahns — der Zahn '
      'wird praktisch neu geformt.',
  '4.5800': 'Der Zahnschmelz wird mit einem Gel kurz angeraut und gespült, damit der '
      'Kunststoff daran haftet. Gehört zu einer Kompositfüllung dazu und wird deshalb '
      'meist zusammen mit einer verrechnet.',
  '4.5810': 'Dasselbe für das weichere Zahnbein unter dem Schmelz: eine Grundierung, '
      'damit die Füllung auch dort hält.',
};

/// Die Erklaerung zu einem Code, oder null.
String? erklaerungZu(String code) => erklaerungen[code.trim()];
