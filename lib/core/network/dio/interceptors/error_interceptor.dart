
// lib/core/network/interceptors/error_interceptor.dart

import 'package:dio/dio.dart';
import '../../../utils/logger_service.dart';

class ErrorInterceptor extends Interceptor {
  final LoggerService logger;

  ErrorInterceptor({required this.logger});

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
