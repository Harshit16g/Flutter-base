import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../constants/api_constants.dart';

class ApiService {
  late Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectionTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {
        ApiConstants.contentType: 'application/json',
        ApiConstants.accept: 'application/json',
      },
    ));
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add auth token if available
        final token = locator<LocalStorageService>().getString(StorageConstants.authToken);
        if (token != null) {
          options.headers[ApiConstants.authHeader] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == ApiConstants.unauthorized) {
          // Handle token refresh here
        }
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, dynamic data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, dynamic data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return Exception('Connection timeout');
        case DioExceptionType.receiveTimeout:
          return Exception('Receive timeout');
        case DioExceptionType.sendTimeout:
          return Exception('Send timeout');
        case DioExceptionType.badResponse:
          return Exception('Bad response: ${error.response?.statusCode}');
        default:
          return Exception('Network error occurred');
      }
    }
    return Exception('Unexpected error occurred');
  }
}
