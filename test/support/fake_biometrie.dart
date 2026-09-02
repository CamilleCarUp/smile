import 'package:smile/services/biometrie.dart';

/// Sensor-Attrappe: Im Test gibt es keinen Fingerabdruck. Damit lassen sich
/// alle drei Ausgaenge durchspielen -- erkannt, abgelehnt, gar kein Sensor.
class FakeBiometrie implements Biometrie {
  bool moeglich;
  bool erkennt;

  /// Wie oft gefragt wurde. Zeigt, ob die App den Nutzer in Ruhe laesst.
  int abfragen = 0;
  String? letzterGrund;

  FakeBiometrie({this.moeglich = true, this.erkennt = true});

  @override
  Future<bool> istMoeglich() async => moeglich;

  @override
  Future<bool> pruefen(String grund) async {
    abfragen++;
    letzterGrund = grund;
    return erkennt;
  }
}
