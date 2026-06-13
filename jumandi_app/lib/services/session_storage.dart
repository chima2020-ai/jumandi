import 'session_storage_io.dart'
    if (dart.library.html) 'session_storage_web.dart' as platform;

/// Persists auth tokens on mobile (secure storage) and web (localStorage).
class SessionStorage {
  Future<String?> read(String key) => platform.readStorage(key);

  Future<void> write(String key, String value) => platform.writeStorage(key, value);

  Future<void> delete(String key) => platform.deleteStorage(key);
}
