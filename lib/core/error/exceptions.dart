class ServerException implements Exception {
  final String message;
  ServerException(this.message);  // Changed to positional parameter
}

class AuthenticationException extends AuthException {
  AuthenticationException(String message) : super(message);
}

class TokenRefreshException extends AuthException {
  TokenRefreshException(String message) : super(message);
}

class NetworkAuthException extends AuthException {
  NetworkAuthException(String message) : super(message);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache Error']);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);  // Changed to positional parameter
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message); // Changed to positional parameter

  @override
  String toString() => message;
}
