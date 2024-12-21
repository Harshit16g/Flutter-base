import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  SecureStorageService() : _secureStorage = const FlutterSecureStorage();

  Future<void> writeSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> deleteAllSecureData() async {
    await _secureStorage.deleteAll();
  }
  // Specific secure storage methods
  Future<void> saveEncryptionKey(String key) async {
    await writeSecureData(StorageConstants.encryptionKey, key);
  }

  Future<String?> getEncryptionKey() async {
    return await readSecureData(StorageConstants.encryptionKey);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await writeSecureData(StorageConstants.biometricEnabled, enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final String? value = await readSecureData(StorageConstants.biometricEnabled);
    return value == 'true';
  }
}
