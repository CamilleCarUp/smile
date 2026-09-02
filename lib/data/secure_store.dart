import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Verschluesselte Ablage auf dem Geraet.
///
/// Warum ueberhaupt verschluesseln, wo die App doch ohnehin in ihrem eigenen
/// Sandkasten liegt und moderne Telefone im Ruhezustand verschluesselt sind?
/// Weil Zahnarztrechnungen Gesundheitsdaten sind und die Schutzschichten
/// unterschiedlich verlaesslich sind: Der Sandkasten faellt auf einem
/// gerooteten Geraet, und eine Datei ohne eigenen Schutz liegt in einem
/// Datei-Abbild offen da.
///
/// Aufbau: Ein zufaelliger Schluessel wird einmalig erzeugt und im
/// Keystore (Android) bzw. der Keychain (iOS) hinterlegt -- also dort, wo das
/// Betriebssystem ihn hardwaregestuetzt schuetzt. Die Nutzdaten liegen
/// AES-GCM-verschluesselt als Datei im privaten Verzeichnis der App. GCM
/// bringt eine Integritaetspruefung mit: Manipulierte Daten werden nicht
/// stillschweigend falsch entschluesselt, sondern abgelehnt.
///
/// Was das NICHT leistet: Schutz gegen jemanden, der das entsperrte Geraet in
/// der Hand haelt. Dafuer braeuchte es eine Geraetesperre in der App
/// (Fingerabdruck) -- siehe docs/architektur.md.
class SecureStore {
  static const _keyName = 'smile_data_key_v1';

  final FlutterSecureStorage _keyStorage;
  final AesGcm _cipher = AesGcm.with256bits();

  SecureStore({FlutterSecureStorage? keyStorage})
      : _keyStorage = keyStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  SecretKey? _cached;

  Future<SecretKey> _key() async {
    final cached = _cached;
    if (cached != null) return cached;

    final stored = await _keyStorage.read(key: _keyName);
    if (stored != null) {
      return _cached = SecretKey(base64Decode(stored));
    }

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    await _keyStorage.write(key: _keyName, value: base64Encode(bytes));
    return _cached = SecretKey(bytes);
  }

  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name.smile');
  }

  /// Speichert [data] verschluesselt unter [name].
  Future<void> write(String name, Map<String, dynamic> data) async {
    final key = await _key();
    final plain = utf8.encode(jsonEncode(data));
    final box = await _cipher.encrypt(plain, secretKey: key);

    // Nonce und Pruefsumme gehoeren zum Geheimtext und werden mitgeschrieben.
    final envelope = jsonEncode({
      'v': 1,
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'data': base64Encode(box.cipherText),
    });
    await (await _file(name)).writeAsString(envelope, flush: true);
  }

  /// Liest die Daten unter [name]. Null, wenn nichts gespeichert ist.
  ///
  /// Laesst sich die Datei nicht entschluesseln -- etwa weil der Schluessel
  /// weg ist, nachdem die App neu installiert wurde -- wird sie verworfen
  /// statt einen Fehler nach oben zu reichen. Ein unlesbarer Verlauf darf die
  /// App nicht am Starten hindern.
  Future<Map<String, dynamic>?> read(String name) async {
    try {
      final file = await _file(name);
      if (!await file.exists()) return null;

      final envelope = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final box = SecretBox(
        base64Decode(envelope['data'] as String),
        nonce: base64Decode(envelope['nonce'] as String),
        mac: Mac(base64Decode(envelope['mac'] as String)),
      );
      final plain = await _cipher.decrypt(box, secretKey: await _key());
      return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    } catch (_) {
      await delete(name);
      return null;
    }
  }

  Future<void> delete(String name) async {
    try {
      final file = await _file(name);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Nichts zu tun -- die Datei ist entweder weg oder nicht zu erreichen.
    }
  }
}

final secureStore = SecureStore();
