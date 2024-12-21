import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<int> retryStatusCodes;
  final Duration retryDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryStatusCodes = const [408, 500, 502, 503, 504],
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    int retryCount = 0;
    RequestOptions requestOptions = err.requestOptions;

    if (_shouldRetry(err, retryCount)) {
      retryCount++;
      await Future.delayed(retryDelay * retryCount);

      try {
        final response = await dio.request(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
          ),
        );
        return handler.resolve(response);
      } catch (e) {
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException error, int retryCount) {
    return retryCount < maxRetries &&
        error.type != DioExceptionType.cancel &&
        (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            (error.response != null &&
                retryStatusCodes.contains(error.response?.statusCode)));
  }
}
