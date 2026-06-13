import 'dart:html' as html;

Future<String?> readStorage(String key) async => html.window.localStorage[key];

Future<void> writeStorage(String key, String value) async {
  html.window.localStorage[key] = value;
}

Future<void> deleteStorage(String key) async {
  html.window.localStorage.remove(key);
}
