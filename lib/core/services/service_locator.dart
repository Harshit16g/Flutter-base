// lib/core/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core imports
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../storage/secure_storage_service.dart';
import '../utils/logger_service.dart';
import '../config/env_config.dart';

// Network interceptors
import '../network/dio/interceptors/auth_interceptor.dart';
import '../network/dio/interceptors/error_interceptor.dart';
import '../network/dio/interceptors/logging_interceptor.dart';
import '../network/dio/interceptors/retry_interceptor.dart';

// Features imports
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/register.dart';
import '../../features/auth/domain/usecases/refresh_token.dart';

final GetIt locator = GetIt.instance;

@InjectableInit(
  initializerName: 'initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
void configureDependencies() => initGetIt(locator);

class ServiceLocator {
  static bool _isInitialized = false;
  static late final LoggerService _logger;

  static Future<void> init() async {
    if (_isInitialized) {
      _logger.warning('ServiceLocator is already initialized');
      return;
    }

    try {
      await _registerCore();
      await _registerNetwork();
      await _registerAuth();
      await _validateRegistrations();
      await _initializeServices();

      _isInitialized = true;
      _logger.info('ServiceLocator initialized successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to initialize ServiceLocator',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> _registerCore() async {
    try {
      final config = EnvConfigFactory.getConfig();
      locator.registerSingleton<EnvConfig>(config);

      _logger = LoggerService(config: config);
      locator.registerSingleton<LoggerService>(_logger);

      locator.registerSingleton<SecureStorageService>(
        SecureStorageService(),
      );

      final sharedPrefs = await SharedPreferences.getInstance();
      locator.registerSingleton<SharedPreferences>(sharedPrefs);

      _logger.info('Core dependencies registered successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to register core dependencies',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> _registerNetwork() async {
    try {
      locator.registerLazySingleton<NetworkInfo>(
            () => NetworkInfoImpl(logger: locator<LoggerService>()), // Ensure correct argument passed
      );

      locator.registerLazySingleton<AuthInterceptor>(
            () => AuthInterceptor(
          secureStorage: locator<SecureStorageService>(),
          logger: locator<LoggerService>(),
        ),
      );

      locator.registerLazySingleton<ErrorInterceptor>(
            () => ErrorInterceptor(
          logger: locator<LoggerService>(),
        ),
      );

      locator.registerLazySingleton<LoggingInterceptor>(
            () => LoggingInterceptor(
          logger: locator<LoggerService>(),
        ),
      );

      locator.registerLazySingleton<RetryInterceptor>(
            () => RetryInterceptor(
          logger: locator<LoggerService>(),
        ),
      );

      locator.registerLazySingleton<ApiClient>(
            () => ApiClient(
          locator<EnvConfig>(),
          locator<AuthInterceptor>(),
          locator<ErrorInterceptor>(),
          locator<LoggingInterceptor>(),
          locator<RetryInterceptor>(),
          locator<LoggerService>(),
        ),
      );

      _logger.info('Network dependencies registered successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to register network dependencies',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> _registerAuth() async {
    try {
      locator.registerLazySingleton<IAuthRemoteDataSource>(
            () => AuthRemoteDataSource(locator<ApiClient>()),
      );

      locator.registerLazySingleton<IAuthRepository>(
            () => AuthRepositoryImpl(
          locator<IAuthRemoteDataSource>(),
          locator<NetworkInfo>(),
          locator<SecureStorageService>(),
        ),
      );

      locator.registerLazySingleton(
            () => Login(locator<IAuthRepository>()),
      );
      locator.registerLazySingleton(
            () => Register(locator<IAuthRepository>()),
      );
      locator.registerLazySingleton(
            () => Logout(locator<IAuthRepository>()),
      );
      locator.registerLazySingleton(
            () => GetCurrentUser(locator<IAuthRepository>()),
      );
      locator.registerLazySingleton(
            () => RefreshToken(locator<IAuthRepository>()),
      );

      _logger.info('Auth dependencies registered successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to register auth dependencies',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> _validateRegistrations() async {
    final requiredServices = <Type>[
      EnvConfig,
      LoggerService,
      SecureStorageService,
      SharedPreferences,
      NetworkInfo,
      ApiClient,
      IAuthRemoteDataSource,
      IAuthRepository,
    ];

    try {
      for (final type in requiredServices) {
        if (!locator.isRegistered<Object>(instanceName: type.toString())) {
          throw ServiceLocatorException(
            'Required service $type is not registered',
          );
        }
      }
      _logger.info('All required services are registered');
    } catch (e, stackTrace) {
      _logger.error(
        'Service validation failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> _initializeServices() async {
    try {
      _logger.info('Starting service initialization');

      final isApiConnected = await locator<ApiClient>().checkConnection();
      if (!isApiConnected) {
        throw ServiceLocatorException('API health check failed');
      }

      _logger.info('All services initialized successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Service initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @visibleForTesting
  static Future<void> reset() async {
    try {
      _logger.info('Resetting ServiceLocator');
      await locator.reset();
      _isInitialized = false;
      _logger.info('ServiceLocator reset successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to reset ServiceLocator',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static bool get isInitialized => _isInitialized;
}

class ServiceLocatorException implements Exception {
  final String message;
  ServiceLocatorException(this.message);

  @override
  String toString() => 'ServiceLocatorException: $message';
}