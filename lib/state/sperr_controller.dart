import 'package:flutter/foundation.dart';

import '../services/biometrie.dart';

/// Ob die App gerade gesperrt ist.
///
/// Getrennt vom Bildschirm, damit sich die Abfolge testen laesst: gesperrt
/// starten, entsperren, in den Hintergrund, wieder gesperrt.
class SperrController extends ChangeNotifier {
  final Biometrie _biometrie;

  /// [sensor] heisst nicht `biometrie`, damit der Parameter die globale
  /// Instanz gleichen Namens nicht verdeckt.
  SperrController({Biometrie? sensor}) : _biometrie = sensor ?? biometrie;

  bool _gesperrt = false;
  bool get istGesperrt => _gesperrt;

  /// Laeuft gerade eine Abfrage? Verhindert, dass der Rueckkehr-aus-dem-
  /// Hintergrund-Fall die eigene Abfrage erneut ausloest -- der Systemdialog
  /// schiebt die App selbst in den Hintergrund.
  bool _fragtGerade = false;
  bool get fragtGerade => _fragtGerade;

  Future<bool> istMoeglich() => _biometrie.istMoeglich();

  /// Beim Start: Ist die Sperre eingeschaltet, beginnt die App gesperrt.
  void beimStart({required bool aktiv}) {
    _gesperrt = aktiv;
    notifyListeners();
  }

  /// Beim Wechsel in den Hintergrund wieder zusperren. Wer sein Telefon aus
  /// der Hand gibt, hat die App meist nicht vorher geschlossen.
  void inDenHintergrund({required bool aktiv}) {
    if (!aktiv || _fragtGerade || _gesperrt) return;
    _gesperrt = true;
    notifyListeners();
  }

  Future<bool> entsperren(
      {String grund = 'Smile entsperren'}) async {
    if (_fragtGerade) return false;
    _fragtGerade = true;
    notifyListeners();
    try {
      final erkannt = await _biometrie.pruefen(grund);
      if (erkannt) _gesperrt = false;
      return erkannt;
    } finally {
      _fragtGerade = false;
      notifyListeners();
    }
  }
}

/// Absichtlich `var`: Im Test tritt eine eigene Instanz an diese Stelle.
SperrController sperrController = SperrController();
