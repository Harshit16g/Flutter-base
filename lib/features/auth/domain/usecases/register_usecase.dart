// lib/features/auth/domain/usecases/register_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

@injectable
class RegisterUseCase {
  final IAuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, User>> call(RegisterParams params) {
    return repository.register(
      params.email,
      params.password,
      params.displayName,
    );
  }
}

class RegisterParams {
  final String email;
  final String password;
  final String displayName;

  RegisterParams({
    required this.email,
    required this.password,
    required this.displayName,
  });
}
