import 'dart:io';
import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRetryable;

  NetworkException({
    required this.message,
    this.statusCode,
    this.isRetryable = true,
  });

  @override
  String toString() => message;
}

class NetworkErrorHandler {
  static NetworkException handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return NetworkException(
        message: 'No internet connection',
        isRetryable: true,
      );
    } else {
      return NetworkException(
        message: 'Unexpected error occurred',
        isRetryable: false,
      );
    }
  }

  static NetworkException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          message: 'Connection timeout',
          isRetryable: true,
        );
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Server not responding',
          isRetryable: true,
        );
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response?.statusCode);
      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request cancelled',
          isRetryable: true,
        );
      default:
        return NetworkException(
          message: 'Network error occurred',
          isRetryable: true,
        );
    }
  }

  static NetworkException _handleResponseError(int? statusCode) {
    switch (statusCode) {
      case 400:
        return NetworkException(
          message: 'Bad request',
          statusCode: statusCode,
          isRetryable: false,
        );
      case 401:
        return NetworkException(
          message: 'Unauthorized',
          statusCode: statusCode,
          isRetryable: false,
        );
      case 403:
        return NetworkException(
          message: 'Forbidden',
          statusCode: statusCode,
          isRetryable: false,
        );
      case 404:
        return NetworkException(
          message: 'Resource not found',
          statusCode: statusCode,
          isRetryable: false,
        );
      case 500:
        return NetworkException(
          message: 'Server error',
          statusCode: statusCode,
          isRetryable: true,
        );
      default:
        return NetworkException(
          message: 'Unexpected error occurred',
          statusCode: statusCode,
          isRetryable: true,
        );
    }
  }
}
