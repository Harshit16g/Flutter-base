import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class IAuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String displayName);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}

@Injectable(as: IAuthRemoteDataSource)
class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await _apiClient.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(response.data['user']);
  }

  @override
  Future<UserModel> register(
    String email,
    String password,
    String displayName,
  ) async {
    final response = await _apiClient.post('/auth/register', data: {
      'email': email,
      'password': password,
      'display_name': displayName,
    });
    return UserModel.fromJson(response.data['user']);
  }

  @override
  Future<void> logout() async {
    await _apiClient.post('/auth/logout');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      return null;
    }
  }
}
