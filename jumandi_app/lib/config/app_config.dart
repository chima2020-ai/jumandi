/// App-wide configuration. Update [apiBaseUrl] for your backend.
class AppConfig {
  AppConfig._();

  static const String appName = 'Jumandi';

  /// Production backend (Render)
  static const String apiBaseUrl = 'https://jumandi.onrender.com';

  /// Local dev (Android emulator: use 10.0.2.2 instead of localhost)
  // static const String apiBaseUrl = 'http://10.0.2.2:8000';

  static String get wsBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  static const String tokenKey = 'jumandi_token';
  static const String userKey = 'jumandi_user';
}
