import 'package:flutter/services.dart' show PlatformException;

/// Fehlermeldungen, die dem Nutzer sagen, was er tun kann.
///
/// Vorher stand da "PlatformException(camera_access_denied, ...)". Das ist
/// eine Meldung fuer Entwickler: Sie nennt die Ursache in einer Sprache, die
/// niemand liest, und verschweigt den einzigen Satz, der hilft -- naemlich
/// wo man den Zugriff freigibt.
///
/// Reines Dart mit einer Ausnahme (PlatformException), damit die Zuordnung
/// ohne Geraet testbar bleibt.

/// Was der Nutzer eigentlich wissen will, wenn die Kamera nicht aufgeht.
String kameraFehlerText(Object fehler) {
  final code = _code(fehler);
  switch (code) {
    case 'camera_access_denied':
      return 'Smile darf nicht auf die Kamera zugreifen. Gib den Zugriff in den '
          'Einstellungen deines Geräts unter "Apps → Smile → Berechtigungen" frei — '
          'oder wähle die Rechnung stattdessen aus der Galerie.';
    case 'no_available_camera':
      return 'Auf diesem Gerät ist keine Kamera verfügbar. Wähle die Rechnung aus '
          'der Galerie oder importiere sie als PDF.';
    case 'already_active':
      return 'Die Kamera ist noch mit der letzten Aufnahme beschäftigt. Versuch es '
          'gleich nochmals.';
    default:
      return 'Die Kamera liess sich nicht öffnen. Versuch es nochmals, oder wähle '
          'die Rechnung aus der Galerie.${_anhang(fehler)}';
  }
}

String galerieFehlerText(Object fehler) {
  final code = _code(fehler);
  if (code == 'photo_access_denied') {
    return 'Smile darf nicht auf deine Fotos zugreifen. Gib den Zugriff in den '
        'Einstellungen deines Geräts frei — oder nimm die Rechnung direkt mit der '
        'Kamera auf.';
  }
  return 'Die Galerie liess sich nicht öffnen. Versuch es nochmals, oder nimm die '
      'Rechnung direkt mit der Kamera auf.${_anhang(fehler)}';
}

String pdfFehlerText(Object fehler) {
  final text = fehler.toString().toLowerCase();
  if (text.contains('password') || text.contains('encrypted')) {
    return 'Dieses PDF ist geschützt und lässt sich nicht öffnen. Entferne den '
        'Schutz, oder fotografiere die Rechnung ab.';
  }
  if (text.contains('no space') || text.contains('enospc')) {
    return 'Auf dem Gerät ist kein Platz mehr, um die Seiten aufzubereiten. Schaff '
        'etwas Speicher frei und versuch es nochmals.';
  }
  return 'Das PDF liess sich nicht lesen. Möglicherweise ist die Datei beschädigt — '
      'fotografiere die Rechnung im Zweifel ab.${_anhang(fehler)}';
}

String? _code(Object fehler) =>
    fehler is PlatformException ? fehler.code : null;

/// Die technische Ursache bleibt dran, aber klein und am Schluss: Sie hilft
/// beim Nachfragen, ohne die Meldung zu beherrschen.
String _anhang(Object fehler) {
  final code = _code(fehler);
  if (code != null && code.isNotEmpty) return ' ($code)';
  return '';
}
