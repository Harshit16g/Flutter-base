// lib/core/network/dio/interceptors/interceptors.dart

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../utils/logger_service.dart';
import '../../../config/env_config.dart';
import '../../../storage/local_storage_service.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'logging_interceptor.dart';
import 'retry_interceptor.dart';

@singleton
class DioInterceptors {
  final LoggerService _logger;
  final EnvConfig _config;
  final LocalStorageService _storage;
  late final AuthInterceptor _authInterceptor;
  late final ErrorInterceptor _errorInterceptor;
  late final LoggingInterceptor _loggingInterceptor;
  late final RetryInterceptor _retryInterceptor;
  bool _isInitialized = false;

  DioInterceptors({
    required LoggerService logger,
    required EnvConfig config,
    required LocalStorageService storage,
  })  : _logger = logger,
        _config = config,
        _storage = storage {
    _initializeInterceptors();
  }

  void _initializeInterceptors() {
    if (_isInitialized) return;

    try {
      _authInterceptor = AuthInterceptor(
        storage: _storage,
        logger: _logger,
        config: _config,
      );

      _errorInterceptor = ErrorInterceptor(
        logger: _logger,
      );

      _loggingInterceptor = LoggingInterceptor(
        logger: _logger,
        config: _config,
      );

      _retryInterceptor = RetryInterceptor(
        logger: _logger,
        config: _config,
      );

      _isInitialized = true;

      _logger.info(
        'DioInterceptors initialized successfully',
        error: {
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'interceptors': [
            'AuthInterceptor',
            'ErrorInterceptor',
            'LoggingInterceptor',
            'RetryInterceptor',
          ],
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to initialize interceptors',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  List<Interceptor> getInterceptors({
    bool includeAuth = true,
    bool includeError = true,
    bool includeLogging = true,
    bool includeRetry = true,
  }) {
    if (!_isInitialized) {
      throw StateError('Interceptors not initialized. Call _initializeInterceptors first.');
    }

    final interceptors = <Interceptor>[];

    if (includeAuth) interceptors.add(_authInterceptor);
    if (includeError) interceptors.add(_errorInterceptor);
    if (includeLogging) interceptors.add(_loggingInterceptor);
    if (includeRetry) interceptors.add(_retryInterceptor);

    return interceptors;
  }

  // Default interceptors getter
  List<Interceptor> get interceptors => getInterceptors();

  // Individual interceptor getters with null safety
  AuthInterceptor? get auth => _isInitialized ? _authInterceptor : null;
  ErrorInterceptor? get error => _isInitialized ? _errorInterceptor : null;
  LoggingInterceptor? get logging => _isInitialized ? _loggingInterceptor : null;
  RetryInterceptor? get retry => _isInitialized ? _retryInterceptor : null;

  // Utility method to check initialization status
  bool get isInitialized => _isInitialized;

  // Method to apply interceptors to a Dio instance
  void applyTo(Dio dio, {
    bool includeAuth = true,
    bool includeError = true,
    bool includeLogging = true,
    bool includeRetry = true,
  }) {
    if (!_isInitialized) {
      throw StateError('Interceptors not initialized. Call _initializeInterceptors first.');
    }

    try {
      final interceptorsToApply = getInterceptors(
        includeAuth: includeAuth,
        includeError: includeError,
        includeLogging: includeLogging,
        includeRetry: includeRetry,
      );

      dio.interceptors.addAll(interceptorsToApply);

      _logger.info(
        'Applied interceptors to Dio instance',
        error: {
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'appliedInterceptors': [
            if (includeAuth) 'AuthInterceptor',
            if (includeError) 'ErrorInterceptor',
            if (includeLogging) 'LoggingInterceptor',
            if (includeRetry) 'RetryInterceptor',
          ],
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to apply interceptors to Dio instance',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Method to reset all interceptors
  void reset() {
    _isInitialized = false;
    _initializeInterceptors();
    _logger.info('Interceptors reset successfully');
  }

  // Optional: Method to get configuration status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'activeInterceptors': [
        if (_isInitialized) ...[
          'AuthInterceptor',
          'ErrorInterceptor',
          'LoggingInterceptor',
          'RetryInterceptor',
        ],
      ],
      'config': {
        'maxRetries': _config.maxRetries,
        'retryDelay': _config.retryDelay,
      },
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }
}