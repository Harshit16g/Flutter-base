// lib/core/network/interceptors/logging_interceptor.dart

import 'package:dio/dio.dart';
import '../../../utils/logger_service.dart';
import '../../../config/env_config.dart';

class LoggingInterceptor extends Interceptor {
  final LoggerService logger;
  final EnvConfig config;

  LoggingInterceptor({
    required this.logger,
    required this.config,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.info(
      'API Request',
      error: {
        'url': options.uri.toString(),
        'method': options.method,
        'headers': options.headers,
        'queryParameters': options.queryParameters,
        'data': options.data,
      },
    );
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.info(
      'API Response',
      error: {
        'url': response.requestOptions.uri.toString(),
        'statusCode': response.statusCode,
        'data': response.data,
      },
    );
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.error(
      'API Error',
      error: {
        'url': err.requestOptions.uri.toString(),
        'method': err.requestOptions.method,
        'statusCode': err.response?.statusCode,
        'error': err.message,
        'data': err.response?.data,
      },
    );
    return handler.next(err);
  }
}
