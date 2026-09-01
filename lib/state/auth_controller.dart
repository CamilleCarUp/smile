import 'package:flutter/foundation.dart';

/// Isolierte Login/Registrierungs-Logik. Bewusst getrennt vom Rest des
/// App-Zustands, damit sie unabhaengig getestet werden kann und sich
/// spaeter leicht gegen ein echtes Auth-System austauschen laesst, ohne
/// den Rest der App anzufassen.
class AuthController extends ChangeNotifier {
  String registeredUsername = 'testuser';
  String registeredPassword = '1234';

  bool tryLogin(String username, String password) {
    return (username == 'testuser' && password == '1234') ||
        (username == registeredUsername && password == registeredPassword);
  }

  void register(String username, String password) {
    registeredUsername = username;
    registeredPassword = password;
    notifyListeners();
  }
}

final authController = AuthController();
