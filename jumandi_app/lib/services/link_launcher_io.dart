import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrl(String url) async {
  final uri = Uri.parse(url);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> openPhoneDialer(String telUri) async {
  return launchUrl(Uri.parse(telUri));
}
