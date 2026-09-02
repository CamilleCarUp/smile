import 'package:local_auth/local_auth.dart';

/// Zugang zur Geraetesperre (Fingerabdruck, Gesicht, Code).
///
/// Als Schnittstelle, nicht als direkter Aufruf von `local_auth`: Im Test gibt
/// es keinen Sensor. So laesst sich jeder Ausgang durchspielen -- erkannt,
/// abgelehnt, gar kein Sensor vorhanden -- ohne Geraet.
abstract class Biometrie {
  /// Kann dieses Geraet ueberhaupt sperren? Falsch, wenn weder Biometrie noch
  /// Code eingerichtet ist. Ohne das darf die Sperre nicht eingeschaltet
  /// werden, sonst sperrt sich der Nutzer selbst aus.
  Future<bool> istMoeglich();

  /// Fragt den Nutzer. Wahr nur bei erfolgreicher Erkennung.
  Future<bool> pruefen(String grund);
}

class EchteBiometrie implements Biometrie {
  final LocalAuthentication _auth;

  EchteBiometrie([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> istMoeglich() async {
    try {
      // isDeviceSupported() deckt auch den Geraetecode ab. Wer keinen
      // Fingerabdruck hinterlegt hat, aber eine PIN, soll die Sperre
      // trotzdem nutzen koennen.
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> pruefen(String grund) async {
    try {
      return await _auth.authenticate(
        localizedReason: grund,
        options: const AuthenticationOptions(
          // Ausdruecklich nicht nur Biometrie: Ein nasser Finger oder ein
          // defekter Sensor darf niemanden aus seinem eigenen Verlauf
          // aussperren -- der Geraetecode bleibt der Weg zurueck.
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

/// Absichtlich `var`: Im Test tritt eine Attrappe an diese Stelle.
Biometrie biometrie = EchteBiometrie();
