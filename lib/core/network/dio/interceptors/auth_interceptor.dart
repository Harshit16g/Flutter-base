// lib/core/network/interceptors/auth_interceptor.dart

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../storage/local_storage_service.dart';
import '../../../config/env_config.dart';
import '../../../utils/logger_service.dart';

@injectable
class AuthInterceptor extends Interceptor {
  final LocalStorageService _storage;
  final EnvConfig _config;
  final LoggerService _logger;

  AuthInterceptor({
    required LocalStorageService storage,
    required EnvConfig config,
    required LoggerService logger,
  })  : _storage = storage,
        _config = config,
        _logger = logger;

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    try {
      await _logger.debug(
        'Processing auth request',
        error: {
          'path': options.path,
          'method': options.method,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
//TODO::implement token validation
      final token = await _storage.getToken();

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        await _logger.info(
          'Added auth token to request',
          error: {
            'path': options.path,
            'method': options.method,
            'hasToken': true,
          },
        );
      } else {
        await _logger.warning(
          'No auth token available',
          error: {
            'path': options.path,
            'method': options.method,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          },
        );
      }

      options.headers['Api-Key'] = _config.apiKey;
      await _logger.debug(
        'Added API key to request',
        error: {
          'path': options.path,
          'method': options.method,
        },
      );

      return handler.next(options);
    } catch (e, stackTrace) {
      await _logger.error(
        'Error processing auth request',
        error: {
          'path': options.path,
          'method': options.method,
          'error': e.toString(),
        },
        stackTrace: stackTrace,
      );
      return handler.next(options);
    }
  }

  @override
  void onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    try {
      if (err.response?.statusCode == 401) {
        await _logger.warning(
          'Unauthorized request detected',
          error: {
            'path': err.requestOptions.path,
            'method': err.requestOptions.method,
            'statusCode': err.response?.statusCode,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          },
        );
//TODO::implement token deletion
        await _storage.deleteToken();
        await _logger.info(
          'Auth token deleted due to unauthorized request',
          error: {
            'path': err.requestOptions.path,
            'method': err.requestOptions.method,
          },
        );

        // You might want to trigger a refresh token flow here
        if (await _shouldAttemptTokenRefresh(err)) {
          await _handleTokenRefresh(err, handler);
          return;
        }
      }

      await _logger.debug(
        'Processing auth error',
        error: {
          'path': err.requestOptions.path,
          'method': err.requestOptions.method,
          'statusCode': err.response?.statusCode,
          'errorType': err.type.toString(),
        },
      );

      return handler.next(err);
    } catch (e, stackTrace) {
      await _logger.error(
        'Error handling auth error',
        error: {
          'originalError': err.toString(),
          'handlerError': e.toString(),
        },
        stackTrace: stackTrace,
      );
      return handler.next(err);
    }
  }

  @override
  void onResponse(
      Response response,
      ResponseInterceptorHandler handler,
      ) async {
    try {
      await _logger.debug(
        'Processing auth response',
        error: {
          'path': response.requestOptions.path,
          'method': response.requestOptions.method,
          'statusCode': response.statusCode,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      // Check for auth-related headers in response
      //TODO::implement token storage
      final newToken = response.headers.value('X-New-Token');
      if (newToken != null) {
        await _storage.saveToken(newToken);
        await _logger.info(
          'Updated auth token from response headers',
          error: {
            'path': response.requestOptions.path,
            'method': response.requestOptions.method,
          },
        );
      }

      return handler.next(response);
    } catch (e, stackTrace) {
      await _logger.error(
        'Error processing auth response',
        error: {
          'path': response.requestOptions.path,
          'method': response.requestOptions.method,
          'error': e.toString(),
        },
        stackTrace: stackTrace,
      );
      return handler.next(response);
    }
  }

  Future<bool> _shouldAttemptTokenRefresh(DioException error) async {
    try {
      //TODO::implement token refresh
      // Add your token refresh logic here
      // For example, check if refresh token exists and is valid
      final refreshToken = await _storage.getRefreshToken();
      return refreshToken != null;
    } catch (e, stackTrace) {
      await _logger.error(
        'Error checking token refresh eligibility',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> _handleTokenRefresh(
      DioException error,
      ErrorInterceptorHandler handler,
      ) async {
    try {
      await _logger.info(
        'Attempting token refresh',
        error: {
          'path': error.requestOptions.path,
          'method': error.requestOptions.method,
        },
      );

      // Add your token refresh implementation here
      // For example:
      // final newToken = await _refreshToken();
      // if (newToken != null) {
      //   await _storage.saveToken(newToken);
      //   // Retry the original request
      //   final response = await _retryRequest(error.requestOptions);
      //   return handler.resolve(response);
      // }

      await _logger.warning(
        'Token refresh not implemented',
        error: {
          'path': error.requestOptions.path,
          'method': error.requestOptions.method,
        },
      );

      return handler.next(error);
    } catch (e, stackTrace) {
      await _logger.error(
        'Error during token refresh',
        error: e,
        stackTrace: stackTrace,
      );
      return handler.next(error);
    }
  }
}