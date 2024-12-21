class ApiConstants {
  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String userProfile = '/user/profile';
  
  // API Headers
  static const String authHeader = 'Authorization';
  static const String contentType = 'Content-Type';
  static const String accept = 'Accept';
  
  // API Error Codes
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;
}
