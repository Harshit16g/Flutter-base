import 'package:dio/dio.dart';
import '../cache/cache_manager.dart';

class CachedApiService {
  final Dio _dio;
  final CacheManager _cacheManager;

  CachedApiService(this._dio, this._cacheManager);

  Future<dynamic> getCached(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration? cacheDuration,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateCacheKey(path, queryParameters);
    
    if (!forceRefresh) {
      final cachedData = _cacheManager.getCache<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }

    final response = await _dio.get(path, queryParameters: queryParameters);
    await _cacheManager.setCache(
      cacheKey,
      response.data,
      validDuration: cacheDuration ?? const Duration(hours: 1),
    );

    return response.data;
  }

  String _generateCacheKey(String path, Map<String, dynamic>? queryParameters) {
    if (queryParameters?.isEmpty ?? true) {
      return path;
    }
    return '$path?${_mapToQueryString(queryParameters!)}';
  }

  String _mapToQueryString(Map<String, dynamic> params) {
    return params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
  }
}
