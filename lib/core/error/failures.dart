import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);  // Updated constructor
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);  // Updated constructor
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(String message) : super(message);  // Updated constructor
}

class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);  // Updated constructor
}
