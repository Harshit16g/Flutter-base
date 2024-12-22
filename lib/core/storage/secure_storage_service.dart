// lib/core/storage/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import '../constants/storage_constants.dart';

@singleton
class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  SecureStorageService() : _secureStorage = const FlutterSecureStorage();

  // Basic secure storage operations
  Future<void> write(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clear() async {
    await _secureStorage.deleteAll();
  }

  // Legacy method names for compatibility
  Future<void> writeSecureData(String key, String value) async {
    await write(key, value);
  }

  Future<String?> readSecureData(String key) async {
    return await read(key);
  }

  Future<void> deleteSecureData(String key) async {
    await delete(key);
  }

  Future<void> deleteAllSecureData() async {
    await clear();
  }

  // Specific secure storage methods
  Future<void> saveEncryptionKey(String key) async {
    await write(StorageConstants.encryptionKey, key);
  }

  Future<String?> getEncryptionKey() async {
    return await read(StorageConstants.encryptionKey);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await write(StorageConstants.biometricEnabled, enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final String? value = await read(StorageConstants.biometricEnabled);
    return value == 'true';
  }
}