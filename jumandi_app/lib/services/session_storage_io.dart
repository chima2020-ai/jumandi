import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _secure = FlutterSecureStorage();

Future<String?> readStorage(String key) => _secure.read(key: key);

Future<void> writeStorage(String key, String value) =>
    _secure.write(key: key, value: value);

Future<void> deleteStorage(String key) => _secure.delete(key: key);
