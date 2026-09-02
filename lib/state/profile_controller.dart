import 'package:flutter/foundation.dart';
import '../data/secure_store.dart';
import '../models/user_profile.dart';

/// Haelt die Angaben des Nutzers ueber sich selbst.
///
/// Getrennt von allem anderen, weil es das Einzige ist, was die App ueber
/// ihren Nutzer weiss -- und das soll man an einer Stelle nachlesen koennen.
class ProfileController extends ChangeNotifier {
  static const _storeName = 'profile';

  final SecureStore _store;
  ProfileController({SecureStore? store}) : _store = store ?? secureStore;

  UserProfile profile = const UserProfile();

  /// Sichtbar statt verschwiegen: Wenn die Ablage nicht erreichbar ist,
  /// gelten die Angaben fuer diese Sitzung, sind aber nicht gespeichert.
  bool saveFailed = false;

  Future<void> load() async {
    try {
      final data = await _store.read(_storeName);
      if (data != null) profile = UserProfile.fromJson(data);
    } catch (_) {
      // Ein unlesbares Profil darf die App nicht am Starten hindern.
    }
    notifyListeners();
  }

  Future<void> save(UserProfile updated) async {
    profile = updated;
    notifyListeners();
    try {
      await _store.write(_storeName, updated.toJson());
      saveFailed = false;
    } catch (_) {
      saveFailed = true;
    }
  }

  /// Loescht die hinterlegten Angaben.
  Future<void> clear() async {
    profile = const UserProfile();
    notifyListeners();
    await _store.delete(_storeName);
  }
}

/// Bewusst veraenderbar statt `final`: Tests setzen hier eine Instanz mit
/// Ablage im Speicher ein. Sonst haengen Widget-Tests am echten Keystore, den
/// es dort nicht gibt.
ProfileController profileController = ProfileController();
