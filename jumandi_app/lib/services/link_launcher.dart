import 'link_launcher_io.dart'
    if (dart.library.html) 'link_launcher_web.dart' as platform;

/// Opens URLs and phone dialer links — uses browser APIs on web (no plugin).
class LinkLauncher {
  LinkLauncher._();

  static Future<bool> openUrl(String url) => platform.openExternalUrl(url);

  static Future<bool> openTel(String telUri) => platform.openPhoneDialer(telUri);
}
