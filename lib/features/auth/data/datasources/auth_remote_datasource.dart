import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_options.dart'; // Add this import
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class IAuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String displayName);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<UserModel> refreshToken(String refreshToken);
}

@Injectable(as: IAuthRemoteDataSource)
class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}'); // Fixed constructor call
    }
  }

  @override
  Future<UserModel> register(
      String email,
      String password,
      String displayName,
      ) async {
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        'display_name': displayName,
      });
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      throw AuthException('Registration failed: ${e.toString()}'); // Fixed constructor call
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      throw AuthException('Logout failed: ${e.toString()}'); // Fixed constructor call
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      // For getCurrentUser, we return null instead of throwing an exception
      // as this is often used to check authentication status
      return null;
    }
  }

  @override
  Future<UserModel> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: ApiOptions( // Fixed ApiOptions usage
          headers: {'Authorization': 'Bearer $refreshToken'},
          priority: RequestPriority.high, // Add priority for token refresh
          maxRetries: 2, // Add retry attempts for token refresh
        ),
      );

      if (response.data['user'] == null) {
        throw AuthException('Token refresh failed: Invalid response'); // Fixed constructor call
      }

      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      throw AuthException('Token refresh failed: ${e.toString()}'); // Fixed constructor call
    }
  }
}