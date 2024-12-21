import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_constants.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // String operations
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  // Boolean operations
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // JSON operations
  Future<bool> setJSON(String key, Map<String, dynamic> json) async {
    return await _prefs.setString(key, jsonEncode(json));
  }

  Map<String, dynamic>? getJSON(String key) {
    final String? jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // User token management
  Future<bool> setAuthToken(String token) async {
    return await setString(StorageConstants.authToken, token);
  }

  String? getAuthToken() {
    return getString(StorageConstants.authToken);
  }

  // Clear operations
  Future<bool> removeKey(String key) async {
    return await _prefs.remove(key);
  }

  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
