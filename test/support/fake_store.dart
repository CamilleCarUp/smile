import 'package:smile/data/secure_store.dart';

/// Ablage im Speicher statt auf der Platte.
///
/// Die echte braucht Keystore und Dateisystem — beides gibt es im Test nicht,
/// und ein Zugriff darauf haengt oder scheitert zu einem unvorhersehbaren
/// Zeitpunkt. Damit werden Tests, die auf das Speichern warten, unzuverlaessig.
class FakeStore extends SecureStore {
  final Map<String, Map<String, dynamic>> inhalt = {};

  @override
  Future<void> write(String name, Map<String, dynamic> data) async =>
      inhalt[name] = data;

  @override
  Future<Map<String, dynamic>?> read(String name) async => inhalt[name];

  @override
  Future<void> delete(String name) async => inhalt.remove(name);
}
