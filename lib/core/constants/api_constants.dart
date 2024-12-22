// lib/core/constants/api_constants.dart

class ApiConstants {
  // Timeout configurations
  static const int connectionTimeout = 30; // 30 seconds
  static const int receiveTimeout = 30; // 30 seconds
  static const int sendTimeout = 30; // 30 seconds
  static const int retryAttempts = 3;

  // HTTP Status codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusInternalServerError = 500;

  // Headers
  static const String contentType = 'Content-Type';
  static const String accept = 'Accept';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';

  // Content types
  static const String applicationJson = 'application/json';
  static const String multipartFormData = 'multipart/form-data';

  // Error messages
  static const String connectionError = 'Connection error';
  static const String unauthorizedError = 'Unauthorized';
  static const String serverError = 'Server error';
}