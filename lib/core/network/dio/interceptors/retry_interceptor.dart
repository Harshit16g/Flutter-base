// lib/core/network/dio/interceptors/retry_interceptor.dart

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../utils/logger_service.dart';
import '../../../config/env_config.dart';

@singleton
class RetryInterceptor extends Interceptor {
  final LoggerService _logger;
  final EnvConfig _config;

  // Using a completer to handle async retry operations
  late final Options _defaultOptions;
  final Map<String, int> _retryAttempts = {};

  RetryInterceptor({
    required LoggerService logger,
    required EnvConfig config,
  })  : _logger = logger,
        _config = config {
    _defaultOptions = Options(
      validateStatus: (status) => status != null && status < 500,
      sendTimeout: _config.apiTimeout,
      receiveTimeout: _config.apiTimeout,
    );
  }

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    // Initialize retry count for new requests
    final requestId = _getRequestId(options);
    _retryAttempts[requestId] = 0;

    await _logger.debug(
      'Starting request',
      error: {
        'path': options.path,
        'method': options.method,
        'requestId': requestId,
      },
    );

    return handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final requestId = _getRequestId(err.requestOptions);
    final currentAttempt = _retryAttempts[requestId] ?? 0;

    if (await _shouldRetry(err, currentAttempt)) {
      try {
        final response = await _performRetry(
          err.requestOptions,
          currentAttempt,
          requestId,
        );
        return handler.resolve(response);
      } catch (retryError, stackTrace) {
        await _logger.error(
          'Retry failed',
          error: {
            'attempt': currentAttempt + 1,
            'maxRetries': _config.maxRetries,
            'error': retryError.toString(),
          },
          stackTrace: stackTrace,
        );
      }
    }

    // Clean up retry attempts map
    _retryAttempts.remove(requestId);
    return handler.next(err);
  }

  Future<Response<dynamic>> _performRetry(
      RequestOptions options,
      int currentAttempt,
      String requestId,
      ) async {
    final nextAttempt = currentAttempt + 1;
    _retryAttempts[requestId] = nextAttempt;

    final delay = _calculateDelay(nextAttempt);

    await _logger.info(
      'Retrying request',
      error: {
        'path': options.path,
        'method': options.method,
        'attempt': nextAttempt,
        'delay': '${delay.inSeconds}s',
      },
    );

    await Future.delayed(delay);

    final retryOptions = Options(
      method: options.method,
      headers: {
        ...options.headers,
        'X-Retry-Attempt': nextAttempt.toString(),
      },
      extra: {
        ...options.extra,
        'retryCount': nextAttempt,
      },
      validateStatus: _defaultOptions.validateStatus,
      sendTimeout: _defaultOptions.sendTimeout,
      receiveTimeout: _defaultOptions.receiveTimeout,
      contentType: options.contentType,
      responseType: options.responseType,
      listFormat: options.listFormat,
    );

    try {
      final client = Dio(); // Create new client for retry
      final response = await client.request(
        options.path,
        data: options.data,
        queryParameters: options.queryParameters,
        options: retryOptions,
      );

      await _logger.info(
        'Retry successful',
        error: {
          'path': options.path,
          'method': options.method,
          'attempt': nextAttempt,
          'statusCode': response.statusCode,
        },
      );

      return response;
    } catch (e, stackTrace) {
      await _logger.error(
        'Retry attempt failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> _shouldRetry(DioException error, int currentAttempt) async {
    if (currentAttempt >= _config.maxRetries) {
      await _logger.warning(
        'Max retries reached',
        error: {
          'path': error.requestOptions.path,
          'attempts': currentAttempt,
          'maxRetries': _config.maxRetries,
        },
      );
      return false;
    }

    if (_isTimeout(error)) {
      await _logger.info(
        'Retrying timeout error',
        error: {
          'type': error.type.toString(),
          'path': error.requestOptions.path,
        },
      );
      return true;
    }

    if (_isServerError(error)) {
      await _logger.info(
        'Retrying server error',
        error: {
          'statusCode': error.response?.statusCode,
          'path': error.requestOptions.path,
        },
      );
      return true;
    }

    await _logger.debug(
      'Not retrying request',
      error: {
        'type': error.type.toString(),
        'statusCode': error.response?.statusCode,
        'path': error.requestOptions.path,
      },
    );
    return false;
  }

  bool _isTimeout(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  bool _isServerError(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode != null &&
        (statusCode == 408 || (statusCode >= 500 && statusCode < 600));
  }

  Duration _calculateDelay(int attempt) {
    // Exponential backoff with jitter
    final baseDelay = Duration(milliseconds: _config.retryDelay);
    final maxDelay = Duration(seconds: 30);
    final exponentialDelay = baseDelay * (1 << (attempt - 1));

    // Add jitter to prevent thundering herd
    final jitter = Duration(
      milliseconds: (DateTime.now().millisecondsSinceEpoch % 1000),
    );

    return exponentialDelay + jitter > maxDelay ? maxDelay : exponentialDelay + jitter;
  }

  String _getRequestId(RequestOptions options) {
    return '${options.method}:${options.path}:${DateTime.now().millisecondsSinceEpoch}';
  }
}