// lib/core/error/route_exception.dart
class RouteException implements Exception {
  final String message;
  
  RouteException(this.message);
  
  @override
  String toString() => message;
}
