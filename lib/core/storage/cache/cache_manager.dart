import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration validDuration;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.validDuration,
  });

  bool get isValid => DateTime.now().difference(timestamp) < validDuration;

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'validDuration': validDuration.inSeconds,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      validDuration: Duration(seconds: json['validDuration']),
    );
  }
}

class CacheManager {
  final SharedPreferences _prefs;
  static const String _cachePrefix = 'cache_';

  CacheManager(this._prefs);

  Future<bool> setCache(
    String key,
    dynamic data, {
    Duration validDuration = const Duration(hours: 1),
  }) async {
    final entry = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      validDuration: validDuration,
    );

    return await _prefs.setString(
      _cachePrefix + key,
      jsonEncode(entry.toJson()),
    );
  }

  T? getCache<T>(String key) {
    final data = _prefs.getString(_cachePrefix + key);
    if (data == null) return null;

    try {
      final entry = CacheEntry.fromJson(jsonDecode(data));
      if (!entry.isValid) {
        _prefs.remove(_cachePrefix + key);
        return null;
      }
      return entry.data as T;
    } catch (e) {
      _prefs.remove(_cachePrefix + key);
      return null;
    }
  }

  Future<void> clearCache() async {
    final keys = _prefs.getKeys();
    final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));
    for (final key in cacheKeys) {
      await _prefs.remove(key);
    }
  }

  Future<void> removeCache(String key) async {
    await _prefs.remove(_cachePrefix + key);
  }
}
