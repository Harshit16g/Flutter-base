// lib/core/storage/storage_service.dart

import 'package:injectable/injectable.dart';
import 'local_storage_service.dart';
import 'secure_storage_service.dart';

abstract class StorageService {
  Future<void> saveSecure(String key, String value);
  Future<String?> getSecure(String key);
  Future<void> removeSecure(String key);

  Future<void> save<T>(String key, T value);
  T? get<T>(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

@Injectable(as: StorageService)
class StorageServiceImpl implements StorageService {
  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;

  StorageServiceImpl(
      this._localStorage,
      this._secureStorage,
      );

  @override
  Future<void> saveSecure(String key, String value) async {
    await _secureStorage.write(key, value);
  }

  @override
  Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key);
  }

  @override
  Future<void> removeSecure(String key) async {
    await _secureStorage.delete(key);
  }

  @override
  Future<void> save<T>(String key, T value) async {
    await _localStorage.write<T>(key, value);
  }

  @override
  T? get<T>(String key) {
    return _localStorage.read<T>(key);
  }

  @override
  Future<void> remove(String key) async {
    await _localStorage.delete(key);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _localStorage.clear(),
      _secureStorage.clear(),
    ]);
  }
}