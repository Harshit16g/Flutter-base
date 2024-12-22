// lib/core/storage/local_storage_service.dart

import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_constants.dart';
import '../config/env_config.dart';
import '../utils/logger_service.dart';

@singleton
class LocalStorageService {
  final SharedPreferences _prefs;
  final EnvConfig _config;
  final LoggerService _logger;

  LocalStorageService({
    required SharedPreferences preferences,
    required EnvConfig config,
    required LoggerService logger,
  })  : _prefs = preferences,
        _config = config,
        _logger = logger {
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    try {
      if (!_prefs.containsKey(StorageConstants.initializationDate)) {
        await write<String>(
          StorageConstants.initializationDate,
          DateTime.now().toUtc().toIso8601String(),
        );
        await write<String>(
          StorageConstants.environment,
          _config.environment,
        );
        await _logger.info(
          'Storage initialized',
          error: {
            'environment': _config.environment,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to initialize storage',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // CRUD Operations
  Future<bool> write<T>(String key, T value) async {
    try {
      await _logger.debug(
        'Writing to storage',
        error: {
          'key': key,
          'type': T.toString(),
          'value': value.toString(),
        },
      );

      bool result = false;
      if (value is String) {
        result = await _prefs.setString(key, value);
      } else if (value is int) {
        result = await _prefs.setInt(key, value);
      } else if (value is double) {
        result = await _prefs.setDouble(key, value);
      } else if (value is bool) {
        result = await _prefs.setBool(key, value);
      } else if (value is List<String>) {
        result = await _prefs.setStringList(key, value);
      } else if (value is Map) {
        result = await _prefs.setString(key, jsonEncode(value));
      } else {
        throw UnsupportedError('Type ${T.toString()} is not supported');
      }

      if (result) {
        await _logger.info('Successfully wrote to storage: $key');
      } else {
        throw StateError('Failed to write to storage: $key');
      }

      return result;
    } catch (e, stackTrace) {
      await _logger.error(
        'Storage write failed',
        error: {'key': key, 'error': e.toString()},
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  T? read<T>(String key) {
    try {
      final value = _prefs.get(key);
      if (value == null) return null;

      _logger.debug(
        'Reading from storage',
        error: {
          'key': key,
          'type': T.toString(),
          'valueType': value.runtimeType.toString(),
        },
      );

      if (T == Map) {
        final stringValue = value as String;
        return jsonDecode(stringValue) as T;
      }

      return value as T;
    } catch (e, stackTrace) {
      _logger.error(
        'Storage read failed',
        error: {'key': key, 'error': e.toString()},
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> delete(String key) async {
    try {
      final result = await _prefs.remove(key);
      await _logger.info(
        'Deleted from storage',
        error: {'key': key, 'success': result},
      );
      return result;
    } catch (e, stackTrace) {
      await _logger.error(
        'Storage delete failed',
        error: {'key': key, 'error': e.toString()},
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      final result = await _prefs.clear();
      await _logger.warning(
        'Cleared all storage',
        error: {'success': result},
      );
      await _initializeStorage(); // Reinitialize after clear
      return result;
    } catch (e, stackTrace) {
      await _logger.error(
        'Storage clear failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
  // User Login Management
  Future<void> setUserLogin(String login) async {
    try {
      await write<String>(StorageConstants.userLogin, login);
      await write<String>(
        StorageConstants.lastLoginDate,
        DateTime.now().toUtc().toIso8601String(),
      );

      await _logger.info(
        'User login set',
        error: {
          'login': login,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'environment': _config.environment,
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to set user login',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String? getUserLogin() {
    try {
      final login = read<String>(StorageConstants.userLogin);

      _logger.debug(
        'Retrieved user login',
        error: {
          'login': login,
          'environment': _config.environment,
        },
      );

      return login;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get user login',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  DateTime? getLastLoginDate() {
    try {
      final dateStr = read<String>(StorageConstants.lastLoginDate);
      if (dateStr == null) return null;

      final date = DateTime.parse(dateStr);

      _logger.debug(
        'Retrieved last login date',
        error: {
          'date': date.toIso8601String(),
          'environment': _config.environment,
        },
      );

      return date;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get last login date',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> clearUserLogin() async {
    try {
      await delete(StorageConstants.userLogin);
      await delete(StorageConstants.lastLoginDate);

      await _logger.info(
        'User login cleared',
        error: {'environment': _config.environment},
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to clear user login',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Session Management
  Future<void> createSession({
    required String userId,
    required String token,
    Duration? customDuration,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final duration = customDuration ?? _getSessionDuration();
      final expiryDate = now.add(duration);

      final sessionData = {
        'userId': userId,
        'token': token,
        'createdAt': now.toIso8601String(),
        'expiresAt': expiryDate.toIso8601String(),
        'environment': _config.environment,
      };

      await write<Map>(StorageConstants.sessionData, sessionData);
      await write<String>(StorageConstants.lastLoginDate, now.toIso8601String());

      await _logger.info(
        'Session created',
        error: {
          'userId': userId,
          'expiryDate': expiryDate.toIso8601String(),
          'environment': _config.environment,
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Session creation failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  Future<void> setSessionData(Map<String, dynamic> sessionData) async {
    try {
      await _logger.debug(
        'Setting session data',
        error: {
          'environment': _config.environment,
        },
      );

      await writeJson(StorageConstants.sessionData, sessionData);
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to set session data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Map<String, dynamic>? getSessionData() {
    try {
      return readJson(StorageConstants.sessionData);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get session data',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Duration _getSessionDuration() {
    switch (_config.environment.toLowerCase()) {
      case 'production':
        return const Duration(hours: 1);
      case 'staging':
        return const Duration(hours: 4);
      default:
        return const Duration(hours: 24); // Development
    }
  }

  // Updated Session Validation
  bool isSessionValid() {
    try {
      final expiry = getSessionExpiry();
      if (expiry == null) {
        _logger.warning('No session expiry found');
        return false;
      }

      final sessionTimeout = _config.sessionTimeout;
      final now = DateTime.now().toUtc();
      final isValid = now.isBefore(expiry) &&
          now.difference(expiry) < sessionTimeout;

      _logger.debug(
        'Checking session validity',
        error: {
          'expiry': expiry.toIso8601String(),
          'isValid': isValid,
          'environment': _config.environment,
          'sessionTimeout': sessionTimeout.inMinutes,
        },
      );

      return isValid;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to check session validity',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }


  Future<void> extendSession(Duration extension) async {
    try {
      final sessionData = read<Map>(StorageConstants.sessionData);
      if (sessionData == null) throw StateError('No active session');

      final currentExpiry = DateTime.parse(sessionData['expiresAt'] as String);
      final newExpiry = currentExpiry.add(extension);
      sessionData['expiresAt'] = newExpiry.toIso8601String();

      await write<Map>(StorageConstants.sessionData, sessionData);
      await _logger.info(
        'Session extended',
        error: {
          'newExpiry': newExpiry.toIso8601String(),
          'extension': extension.inMinutes,
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Session extension failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> endSession() async {
    try {
      await delete(StorageConstants.sessionData);
      await _logger.info('Session ended');
    } catch (e, stackTrace) {
      await _logger.error(
        'Session end failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Cache Management
  Future<void> setCache(String key, dynamic data, Duration duration) async {
    try {
      final expiryDate = DateTime.now().toUtc().add(duration);
      final cacheData = {
        'data': data,
        'expiryDate': expiryDate.toIso8601String(),
      };

      await write<String>('cache_$key', jsonEncode(cacheData));
      await _logger.debug(
        'Cache set',
        error: {
          'key': key,
          'expiryDate': expiryDate.toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Cache set failed',
        error: {'key': key, 'error': e.toString()},
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  dynamic getCache(String key) {
    try {
      final cacheString = read<String>('cache_$key');
      if (cacheString == null) return null;

      final cacheData = jsonDecode(cacheString);
      final expiryDate = DateTime.parse(cacheData['expiryDate']);

      if (DateTime.now().toUtc().isAfter(expiryDate)) {
        delete('cache_$key'); // Clean up expired cache
        return null;
      }

      return cacheData['data'];
    } catch (e, stackTrace) {
      _logger.error(
        'Cache get failed',
        error: {'key': key, 'error': e.toString()},
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      final cacheKeys = _prefs.getKeys().where((key) => key.startsWith('cache_'));
      for (final key in cacheKeys) {
        await delete(key);
      }
      await _logger.info('Cache cleared');
    } catch (e, stackTrace) {
      await _logger.error(
        'Cache clear failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // User Preferences
  Future<void> setUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await _logger.info(
        'Setting user preferences',
        error: {
          'preferences': preferences,
          'environment': _config.environment,
        },
      );

      for (final entry in preferences.entries) {
        await write('pref_${entry.key}', entry.value);
      }
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to set user preferences',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Map<String, dynamic> getUserPreferences() {
    try {
      final Map<String, dynamic> preferences = {};
      final prefKeys = _prefs.getKeys().where((key) => key.startsWith('pref_'));

      for (final key in prefKeys) {
        preferences[key.replaceFirst('pref_', '')] = read(key);
      }

      _logger.debug(
        'Retrieved user preferences',
        error: {
          'preferences': preferences,
          'environment': _config.environment,
        },
      );

      return preferences;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get user preferences',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  // Theme preferences
  // Theme Management
  Future<void> setThemeMode(String mode) async {
    try {
      await write<String>(StorageConstants.themeMode, mode);
      await _logger.info(
        'Theme mode updated',
        error: {'mode': mode},
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to set theme mode',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String getThemeMode() {
    try {
      return read<String>(StorageConstants.themeMode) ?? 'system';
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get theme mode',
        error: e,
        stackTrace: stackTrace,
      );
      return 'system';
    }
  }
  // Language preferences
  Future<void> setLanguage(String languageCode) async {
    try {
      await _logger.info(
        'Setting language',
        error: {
          'languageCode': languageCode,
          'environment': _config.environment,
        },
      );

      await write<String>(StorageConstants.languageCode, languageCode);
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to set language',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String getLanguage() {
    try {
      final language = read<String>(StorageConstants.languageCode) ?? 'en';

      _logger.debug(
        'Retrieved language',
        error: {
          'language': language,
          'environment': _config.environment,
        },
      );

      return language;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get language',
        error: e,
        stackTrace: stackTrace,
      );
      return 'en';
    }
  }

  // Authentication
  // Auth Token Management
  Future<void> setAuthToken(String token) async {
    try {
      await write<String>(StorageConstants.authToken, token);
      await _logger.info(
        'Auth token updated',
        error: {'tokenLength': token.length},
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to set auth token',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String? getAuthToken() {
    try {
      return read<String>(StorageConstants.authToken);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get auth token',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> clearAuth() async {
    try {
      await _logger.warning(
        'Clearing auth data',
        error: {'environment': _config.environment},
      );

      await delete(StorageConstants.authToken);
      await delete(StorageConstants.sessionExpiry);
      await delete(StorageConstants.userLogin);
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to clear auth data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Session Management
  Future<void> setSessionExpiry(DateTime expiryDate) async {
    try {
      final adjustedExpiry = _config.isProduction
          ? expiryDate
          : expiryDate.add(const Duration(hours: 24));

      await _logger.info(
        'Setting session expiry',
        error: {
          'expiry': adjustedExpiry.toIso8601String(),
          'environment': _config.environment,
          'isExtended': !_config.isProduction,
        },
      );

      await write<String>(
        StorageConstants.sessionExpiry,
        adjustedExpiry.toUtc().toIso8601String(),
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to set session expiry',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  DateTime? getSessionExpiry() {
    try {
      final expiryStr = read<String>(StorageConstants.sessionExpiry);
      final expiry = expiryStr != null ? DateTime.parse(expiryStr) : null;

      _logger.debug(
        'Retrieved session expiry',
        error: {
          'expiry': expiry?.toIso8601String(),
          'environment': _config.environment,
        },
      );

      return expiry;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get session expiry',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }


  // App State
  Future<void> setAppVersion(String version) async {
    try {
      await _logger.info(
        'Setting app version',
        error: {
          'version': version,
          'environment': _config.environment,
        },
      );

      await write<String>(StorageConstants.appVersion, version);
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to set app version',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String? getAppVersion() {
    try {
      final version = read<String>(StorageConstants.appVersion);

      _logger.debug(
        'Retrieved app version',
        error: {
          'version': version,
          'environment': _config.environment,
        },
      );

      return version;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get app version',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  // Utility Methods
  Future<bool> hasKey(String key) async {
    try {
      final exists = _prefs.containsKey(key);
      await _logger.debug(
        'Checking key existence',
        error: {
          'key': key,
          'exists': exists,
          'environment': _config.environment,
        },
      );
      return exists;
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to check key existence',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<Set<String>> getAllKeys() async {
    try {
      final keys = _prefs.getKeys();
      await _logger.debug(
        'Retrieved all storage keys',
        error: {
          'count': keys.length,
          'environment': _config.environment,
        },
      );
      return keys;
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to get storage keys',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  // JSON Data Handling
  Future<void> writeJson(String key, Map<String, dynamic> json) async {
    try {
      final jsonString = jsonEncode(json);
      await write<String>(key, jsonString);

      await _logger.info(
        'Wrote JSON data to storage',
        error: {
          'key': key,
          'dataSize': jsonString.length,
          'environment': _config.environment,
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to write JSON data',
        error: {
          'key': key,
          'error': e.toString(),
        },
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Map<String, dynamic>? readJson(String key) {
    try {
      final jsonString = read<String>(key);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      _logger.debug(
        'Read JSON data from storage',
        error: {
          'key': key,
          'dataSize': jsonString.length,
          'environment': _config.environment,
        },
      );

      return json;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to read JSON data',
        error: {
          'key': key,
          'error': e.toString(),
        },
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // Date Time Operations
  Future<void> saveLastSyncTime(DateTime time) async {
    try {
      await write<String>(
        StorageConstants.lastSyncTime,
        time.toUtc().toIso8601String(),
      );

      await _logger.info(
        'Saved last sync time',
        error: {
          'time': time.toUtc().toIso8601String(),
          'environment': _config.environment,
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to save last sync time',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  DateTime? getLastSyncTime() {
    try {
      final timeStr = read<String>(StorageConstants.lastSyncTime);
      if (timeStr == null) return null;

      final time = DateTime.parse(timeStr);

      _logger.debug(
        'Retrieved last sync time',
        error: {
          'time': time.toUtc().toIso8601String(),
          'environment': _config.environment,
        },
      );

      return time;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get last sync time',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // User Preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await writeJson(StorageConstants.userPreferences, preferences);

      await _logger.info(
        'Saved user preferences',
        error: {
          'preferencesCount': preferences.length,
          'environment': _config.environment,
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to save user preferences',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }


  // Cache Management
  Future<void> invalidateCache(String key) async {
    try {
      await delete('${key}_cache');
      await delete('${key}_timestamp');

      await _logger.info(
        'Invalidated cache',
        error: {
          'key': key,
          'environment': _config.environment,
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to invalidate cache',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> invalidateAllCaches() async {
    try {
      final keys = await getAllKeys();
      final cacheKeys = keys.where((key) => key.endsWith('_cache'));

      for (final key in cacheKeys) {
        await delete(key);
        await delete('${key}_timestamp');
      }

      await _logger.info(
        'Invalidated all caches',
        error: {
          'count': cacheKeys.length,
          'environment': _config.environment,
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to invalidate all caches',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Data Migration
  Future<void> migrateData(String oldKey, String newKey) async {
    try {
      final data = read(oldKey);
      if (data != null) {
        await write(newKey, data);
        await delete(oldKey);
      }

      await _logger.info(
        'Migrated data',
        error: {
          'oldKey': oldKey,
          'newKey': newKey,
          'success': data != null,
          'environment': _config.environment,
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to migrate data',
        error: {
          'oldKey': oldKey,
          'newKey': newKey,
          'error': e.toString(),
        },
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Storage Space Management
  Future<int> getStorageSize() async {
    try {
      final keys = await getAllKeys();
      int totalSize = 0;

      for (final key in keys) {
        final value = _prefs.getString(key);
        if (value != null) {
          totalSize += key.length + value.length;
        }
      }

      await _logger.debug(
        'Calculated storage size',
        error: {
          'size': totalSize,
          'keyCount': keys.length,
          'environment': _config.environment,
        },
      );

      return totalSize;
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to calculate storage size',
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }
  // Environment Management
  Future<void> setEnvironment(String env) async {
    try {
      await write<String>(StorageConstants.environment, env);
      await _logger.info(
        'Environment updated',
        error: {'environment': env},
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to set environment',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String getEnvironment() {
    try {
      return read<String>(StorageConstants.environment) ?? _config.environment;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get environment',
        error: e,
        stackTrace: stackTrace,
      );
      return _config.environment;
    }
  }

  // Backup & Restore
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final keys = await getAllKeys();
      final backup = <String, dynamic>{};

      for (final key in keys) {
        backup[key] = _prefs.get(key);
      }

      await _logger.info(
        'Created storage backup',
        error: {
          'keyCount': keys.length,
          'environment': _config.environment,
        },
      );

      return backup;
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to create backup',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> restoreBackup(Map<String, dynamic> backup) async {
    try {
      await clear();

      for (final entry in backup.entries) {
        await write(entry.key, entry.value);
      }

      await _logger.info(
        'Restored storage backup',
        error: {
          'keyCount': backup.length,
          'environment': _config.environment,
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to restore backup',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Initialization Date Management
  Future<void> setInitializationDate() async {
    try {
      final now = DateTime.now().toUtc();
      await write<String>(
        StorageConstants.initializationDate,
        now.toIso8601String(),
      );
      await _logger.info(
        'Initialization date set',
        error: {'date': now.toIso8601String()},
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to set initialization date',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  DateTime? getInitializationDate() {
    try {
      final dateStr = read<String>(StorageConstants.initializationDate);
      return dateStr != null ? DateTime.parse(dateStr) : null;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get initialization date',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // Debug Methods
  Future<void> printStorageContents() async {
    if (!_config.isProduction) {
      try {
        final keys = await getAllKeys();
        final contents = <String, dynamic>{};

        for (final key in keys) {
          contents[key] = _prefs.get(key);
        }

        await _logger.debug(
          'Storage contents',
          error: {
            'contents': contents,
            'environment': _config.environment,
          },
        );
      } catch (e, stackTrace) {
        await _logger.error(
          'Failed to print storage contents',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }
  // Biometric Authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await write<bool>(StorageConstants.biometricEnabled, enabled);
      await _logger.info(
        'Biometric authentication setting updated',
        error: {'enabled': enabled},
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to update biometric setting',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  bool isBiometricEnabled() {
    try {
      return read<bool>(StorageConstants.biometricEnabled) ?? false;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get biometric setting',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
  // First Launch Check
  Future<void> setFirstLaunch(bool isFirst) async {
    try {
      await write<bool>(StorageConstants.isFirstLaunch, isFirst);
      await _logger.info(
        'First launch flag updated',
        error: {'isFirst': isFirst},
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to update first launch flag',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  bool isFirstLaunch() {
    try {
      return read<bool>(StorageConstants.isFirstLaunch) ?? true;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to get first launch flag',
        error: e,
        stackTrace: stackTrace,
      );
      return true;
    }
  }

  // Storage Metrics
  Future<void> recordMetric(String metricName, dynamic value) async {
    try {
      final metrics = readJson(StorageConstants.performanceMetrics) ?? {};
      metrics[metricName] = {
        'value': value,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      await writeJson(StorageConstants.performanceMetrics, metrics);

      await _logger.info(
        'Recorded metric',
        error: {
          'metric': metricName,
          'value': value,
        },
      );
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to record metric',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Storage Health Check
  Future<Map<String, dynamic>> checkStorageHealth() async {
    try {
      final storageSize = await getStorageSize();
      final keyCount = (await getAllKeys()).length;
      final initDate = getInitializationDate();

      final health = {
        'storageSize': storageSize,
        'keyCount': keyCount,
        'initializationDate': initDate?.toIso8601String(),
        'isHealthy': storageSize < _config.maxStorageSize,
        'utilizationPercentage': (storageSize / _config.maxStorageSize) * 100,
      };

      await _logger.info(
        'Storage health check completed',
        error: health,
      );

      return health;
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to check storage health',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Auto Cleanup
  Future<void> performAutoCleanup() async {
    try {
      final storageHealth = await checkStorageHealth();
      if ((storageHealth['utilizationPercentage'] as double) > 90) {
        await invalidateAllCaches();
        final keys = await getAllKeys();
        final oldestKeys = await _findOldestEntries(keys, 10);

        for (final key in oldestKeys) {
          await delete(key);
        }

        await _logger.warning(
          'Performed auto cleanup',
          error: {
            'removedKeys': oldestKeys.length,
            'newSize': await getStorageSize(),
          },
        );
      }
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to perform auto cleanup',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<String>> _findOldestEntries(Set<String> keys, int limit) async {
    final entries = <MapEntry<String, DateTime>>[];

    for (final key in keys) {
      final timestamp = read<String>('${key}_timestamp');
      if (timestamp != null) {
        entries.add(MapEntry(key, DateTime.parse(timestamp)));
      }
    }

    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries.take(limit).map((e) => e.key).toList();
  }
}
