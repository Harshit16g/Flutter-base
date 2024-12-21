import '../models/user_model.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/local_storage_service.dart';

class AuthRepository {
  final ApiService _apiService;
  final LocalStorageService _storageService;

  AuthRepository(this._apiService, this._storageService);

  Future<UserModel> login(String email, String password) async {
    final response = await _apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    await _storageService.setString('token', response.data['token']);
    return UserModel.fromJson(response.data['user']);
  }

  Future<UserModel> register(
    String email,
    String password,
    String displayName,
  ) async {
    final response = await _apiService.post('/auth/register', {
      'email': email,
      'password': password,
      'display_name': displayName,
    });

    await _storageService.setString('token', response.data['token']);
    return UserModel.fromJson(response.data['user']);
  }

  Future<void> logout() async {
    await _storageService.removeKey('token');
  }

  Future<UserModel?> getCurrentUser() async {
    final token = _storageService.getString('token');
    if (token == null) return null;

    final response = await _apiService.get('/auth/me');
    return UserModel.fromJson(response.data);
  }
}
