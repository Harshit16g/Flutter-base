// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../config/env_config.dart';
import '../constants/api_constants.dart';
import 'dio/interceptors/auth_interceptor.dart';
import 'dio/interceptors/error_interceptor.dart';
import 'dio/interceptors/logging_interceptor.dart';
import 'dio/interceptors/retry_interceptor.dart';
import '../utils/logger_service.dart';

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

  Future<Response<T>> get<T>(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      _logger.debug('Making GET request', error: {
        'path': path,
        'queryParameters': queryParameters,
      });

      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      _logger.info('GET request successful', error: {
        'path': path,
        'statusCode': response.statusCode,
      });

      return response;
    } catch (e, stackTrace) {
      _logger.error(
        'GET request failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Response<T>> post<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      _logger.debug('Making POST request', error: {
        'path': path,
        'data': data,
        'queryParameters': queryParameters,
      });

      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
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
      _logger.error(
        'POST request failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Response<T>> put<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      _logger.debug('Making PUT request', error: {
        'path': path,
        'data': data,
        'queryParameters': queryParameters,
      });

      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      _logger.info('PUT request successful', error: {
        'path': path,
        'statusCode': response.statusCode,
      });

      return response;
    } catch (e, stackTrace) {
      _logger.error(
        'PUT request failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Response<T>> delete<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      _logger.debug('Making DELETE request', error: {
        'path': path,
        'data': data,
        'queryParameters': queryParameters,
      });

      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      _logger.info('DELETE request successful', error: {
        'path': path,
        'statusCode': response.statusCode,
      });

      return response;
    } catch (e, stackTrace) {
      _logger.error(
        'DELETE request failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
    _logger.info('Base URL updated', error: {'newBaseUrl': newBaseUrl});
  }

  void addHeader(String key, String value) {
    _dio.options.headers[key] = value;
    _logger.debug('Header added', error: {'key': key, 'value': value});
  }

  void removeHeader(String key) {
    _dio.options.headers.remove(key);
    _logger.debug('Header removed', error: {'key': key});
  }

  void setAuthToken(String token) {
    addHeader('Authorization', 'Bearer $token');
    _logger.info('Auth token set');
  }

  void clearAuthToken() {
    removeHeader('Authorization');
    _logger.info('Auth token cleared');
  }

  Future<bool> checkConnection() async {
    try {
      final response = await get('/health');
      return response.statusCode == 200;
    } catch (e) {
      _logger.error('Health check failed', error: e);
      return false;
    }
  }
}