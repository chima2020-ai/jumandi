import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth tokens on mobile (secure storage) and web (shared preferences).
class SessionStorage {
  SessionStorage({FlutterSecureStorage? secureStorage})
      : _secure = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _webPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String?> read(String key) async {
    if (kIsWeb) {
      return (await _webPrefs).getString(key);
    }
    return _secure.read(key: key);
  }

  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      await (await _webPrefs).setString(key, value);
      return;
    }
    await _secure.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      await (await _webPrefs).remove(key);
      return;
    }
    await _secure.delete(key: key);
  }
}
