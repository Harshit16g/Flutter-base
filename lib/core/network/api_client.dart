// lib/core/network/api_client.dart
//USAGE////
//// Example usage
//// Example usage
// final apiClient = getIt<ApiClient>();
//
// // Basic request with default options
// final response = await apiClient.get('/users');
//
// // Request with custom options
// final customResponse = await apiClient.get(
//   '/users',
//   options: ApiOptions(
//     headers: {'Custom-Header': 'value'},
//     responseType: ResponseType.json,
//     priority: RequestPriority.high,
//     maxRetries: 3,
//   ),
// );
//
// // Cached request
// final cachedResponse = await apiClient.get(
//   '/users',
//   options: apiClient.getCachedOptions(
//     maxAge: Duration(minutes: 10),
//   ),
// );
//
// // High priority request
// final priorityResponse = await apiClient.get(
//   '/important-endpoint',
//   options: apiClient.getPriorityOptions(RequestPriority.high),
// );
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../config/env_config.dart';
import '../constants/api_constants.dart';
import 'dio/interceptors/auth_interceptor.dart';
import 'dio/interceptors/error_interceptor.dart';
import 'dio/interceptors/logging_interceptor.dart';
import 'dio/interceptors/retry_interceptor.dart';
import '../utils/logger_service.dart';
import 'api_options.dart';

@singleton
class ApiClient {
  late final Dio _dio;
  final EnvConfig _config;
  final AuthInterceptor _authInterceptor;
  final ErrorInterceptor _errorInterceptor;
  final LoggingInterceptor _loggingInterceptor;
  final RetryInterceptor _retryInterceptor;
  final LoggerService _logger;

  ApiClient(
      this._config,
      this._authInterceptor,
      this._errorInterceptor,
      this._loggingInterceptor,
      this._retryInterceptor,
      this._logger,
      ) {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _config.apiUrl,
        connectTimeout: const Duration(seconds: ApiConstants.connectionTimeout),
        receiveTimeout: const Duration(seconds: ApiConstants.receiveTimeout),
        sendTimeout: const Duration(seconds: ApiConstants.sendTimeout),
        headers: getDefaultHeaders(),
      ),
    );

    _dio.interceptors.addAll([
      _authInterceptor,
      _errorInterceptor,
      _loggingInterceptor,
      _retryInterceptor,
    ]);

    _logger.info('API Client initialized', error: {
      'baseUrl': _config.apiUrl,
      'timeout': ApiConstants.connectionTimeout,
    });
  }

  Map<String, String> getDefaultHeaders() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }
  // HTTP Methods
  Future<Response<T>> get<T>(
      String path, {
        Map<String, dynamic>? queryParameters,
        ApiOptions? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      _logger.debug('Making GET request', error: {
        'path': path,
        'queryParameters': queryParameters,
        'options': options?.headers,
      });

      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options?.toDioOptions(),
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      _logger.info('GET request successful', error: {
        'path': path,
        'statusCode': response.statusCode,
      });

      return response;
    } catch (e, stackTrace) {
      _logger.error('GET request failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Response<T>> post<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        ApiOptions? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      _logger.debug('Making POST request', error: {
        'path': path,
        'data': data,
        'queryParameters': queryParameters,
        'options': options?.headers,
      });

      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options?.toDioOptions(),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      _logger.info('POST request successful', error: {
        'path': path,
        'statusCode': response.statusCode,
      });

      return response;
    } catch (e, stackTrace) {
      _logger.error('POST request failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  // Utility methods for ApiOptions
  ApiOptions getDefaultOptions() {
    return ApiOptions(
      headers: getDefaultHeaders(),
      contentType: 'application/json',
      responseType: ResponseType.json,
      connectTimeout: Duration(seconds: ApiConstants.connectionTimeout),
      receiveTimeout: Duration(seconds: ApiConstants.receiveTimeout),
      sendTimeout: Duration(seconds: ApiConstants.sendTimeout),
      maxRetries: 3,
      retryInterval: const Duration(seconds: 1),
    );
  }

  ApiOptions getCachedOptions({Duration? maxAge}) {
    return getDefaultOptions().copyWith(
      cacheMaxAge: maxAge ?? const Duration(minutes: 5),
      forceRefresh: false,
    );
  }

  ApiOptions getPriorityOptions(RequestPriority priority) {
    return getDefaultOptions().copyWith(
      priority: priority,
    );
  }

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
    _logger.info('Base URL updated', error: {'newBaseUrl': newBaseUrl});
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _logger.info('Auth token set');
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
    _logger.info('Auth token cleared');
  }

  Future<bool> checkConnection() async {
    try {
      final response = await get(
        '/health',
        options: getDefaultOptions().copyWith(
          priority: RequestPriority.high,
          maxRetries: 1,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      _logger.error('Health check failed', error: e);
      return false;
    }
  }
}