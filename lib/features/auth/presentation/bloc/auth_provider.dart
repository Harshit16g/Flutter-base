import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/utils/logger_service.dart';
class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final LoggerService _logger;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastAuthCheck;

  AuthProvider(this._authRepository, this._logger);

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  DateTime? get lastAuthCheck => _lastAuthCheck;

  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authRepository.login(email, password);
      _currentUser = user;
      _lastAuthCheck = DateTime.now();

      await _logger.info(
        'User logged in successfully',
        metadata: {
          'userId': user.id,
          'email': user.email,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      return true;
    } catch (e, stackTrace) {
      _handleError('Login failed', e, stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authRepository.register(email, password, displayName);
      _currentUser = user;
      _lastAuthCheck = DateTime.now();

      await _logger.info(
        'User registered successfully',
        metadata: {
          'userId': user.id,
          'email': user.email,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      return true;
    } catch (e, stackTrace) {
      _handleError('Registration failed', e, stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(true);
      _clearError();

      final userId = _currentUser?.id;
      await _authRepository.logout();
      _currentUser = null;
      _lastAuthCheck = DateTime.now();

      await _logger.info(
        'User logged out successfully',
        metadata: {
          'userId': userId,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      _handleError('Logout failed', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      _setLoading(true);
      _clearError();

      _currentUser = await _authRepository.getCurrentUser();
      _lastAuthCheck = DateTime.now();

      await _logger.debug(
        'Auth status checked',
        metadata: {
          'isAuthenticated': isAuthenticated,
          'userId': _currentUser?.id,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      _handleError('Auth status check failed', e, stackTrace);
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authRepository.sendPasswordResetEmail(email);

      await _logger.info(
        'Password reset email sent',
        metadata: {
          'email': email,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      return true;
    } catch (e, stackTrace) {
      _handleError('Failed to send password reset email', e, stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      final updatedUser = _currentUser!.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
        metadata: metadata,
      );

      await _authRepository.updateUserProfile(updatedUser);
      _currentUser = updatedUser;

      await _logger.info(
        'User profile updated',
        metadata: {
          'userId': updatedUser.id,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      return true;
    } catch (e, stackTrace) {
      _handleError('Failed to update profile', e, stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      final userId = _currentUser!.id;
      await _authRepository.deleteAccount();
      _currentUser = null;

      await _logger.warning(
        'User account deleted',
        metadata: {
          'userId': userId,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      return true;
    } catch (e, stackTrace) {
      _handleError('Failed to delete account', e, stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _handleError(String message, Object error, StackTrace stackTrace) {
    _error = error.toString();
    _logger.error(
      message,
      error: error,
      stackTrace: stackTrace,
      metadata: {
        'userId': _currentUser?.id,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
    notifyListeners();
  }
}