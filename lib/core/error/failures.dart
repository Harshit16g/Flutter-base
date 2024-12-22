import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server Error']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache Error']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network Error']) : super(message);
}
