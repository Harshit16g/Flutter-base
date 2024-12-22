import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String displayName);
  Future<UserModel?> getCurrentUser();
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updateUserProfile(UserModel user);
  Future<void> deleteAccount();
}