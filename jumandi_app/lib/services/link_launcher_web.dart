import 'dart:html' as html;

Future<bool> openExternalUrl(String url) async {
  html.window.open(url, '_blank');
  return true;
}

Future<bool> openPhoneDialer(String telUri) async {
  html.window.location.href = telUri;
  return true;
}
