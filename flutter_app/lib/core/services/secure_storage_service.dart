import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  
  static const _keyApiKey = 'groq_api_key_secure';

  static Future<void> saveApiKey(String key) async {
    await _storage.write(key: _keyApiKey, value: key);
  }

  static Future<String?> getApiKey() async {
    return await _storage.read(key: _keyApiKey);
  }

  static Future<void> deleteApiKey() async {
    await _storage.delete(key: _keyApiKey);
  }
}
