import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

@Injectable(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl(
      this._remoteDataSource,
      this._networkInfo,
      this._secureStorage,
      );

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection')); // Updated
    }

    try {
      final userModel = await _remoteDataSource.login(email, password);
      await _storeAuthData(userModel);
      return Right(userModel);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message)); // Updated
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message)); // Updated
    } catch (e) {
      return Left(UnexpectedFailure(e.toString())); // Updated
    }
  }

  @override
  Future<Either<Failure, User>> register(
      String email,
      String password,
      String displayName,
      ) async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection')); // Updated
    }

    try {
      final userModel = await _remoteDataSource.register(
        email,
        password,
        displayName,
      );
      await _storeAuthData(userModel);
      return Right(userModel);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message)); // Updated
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message)); // Updated
    } catch (e) {
      return Left(UnexpectedFailure(e.toString())); // Updated
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      await _clearAuthData();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message)); // Updated
    } catch (e) {
      return Left(UnexpectedFailure(e.toString())); // Updated
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final cachedUser = await _getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser);
      }

      if (await _networkInfo.isConnected) {
        final userModel = await _remoteDataSource.getCurrentUser();
        if (userModel != null) {
          await _cacheUser(userModel);
        }
        return Right(userModel);
      } else {
        return Left(NetworkFailure('No internet connection')); // Updated
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message)); // Updated
    } catch (e) {
      return Left(UnexpectedFailure(e.toString())); // Updated
    }
  }

  @override
  Future<Either<Failure, User>> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read('refresh_token');
      if (refreshToken == null) {
        return Left(AuthFailure('No refresh token available')); // Updated
      }

      final userModel = await _remoteDataSource.refreshToken(refreshToken);
      await _storeAuthData(userModel);
      return Right(userModel);
    } on AuthException catch (e) {
      await _clearAuthData();
      return Left(AuthFailure(e.message)); // Updated
    } catch (e) {
      return Left(UnexpectedFailure(e.toString())); // Updated
    }
  }

  Future<void> _storeAuthData(UserModel user) async {
    await _secureStorage.write('auth_token', user.authToken ?? '');
    await _secureStorage.write('refresh_token', user.refreshToken ?? '');
    await _cacheUser(user);
  }

  Future<void> _clearAuthData() async {
    await _secureStorage.delete('auth_token');
    await _secureStorage.delete('refresh_token');
    await _secureStorage.delete('cached_user');
  }

  Future<void> _cacheUser(UserModel user) async {
    final userJson = json.encode(user.toJson());
    await _secureStorage.write('cached_user', userJson);
  }

  Future<UserModel?> _getCachedUser() async {
    try {
      final userJsonString = await _secureStorage.read('cached_user');
      if (userJsonString != null) {
        final userJson = json.decode(userJsonString) as Map<String, dynamic>;
        return UserModel.fromJson(userJson);
      }
    } catch (_) {
      await _secureStorage.delete('cached_user');
    }
    return null;
  }
}