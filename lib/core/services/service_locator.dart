// lib/core/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meta/meta.dart';
import '../network/dio/interceptors/interceptors.dart';
import '../storage/local_storage_service.dart';
import '../network/api_client.dart';
import '../network/ftp_service.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import '../utils/logger_service.dart';
import '../config/env_config.dart';

final GetIt locator = GetIt.instance;

@InjectableInit(
  initializerName: 'initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
@singleton
class ServiceLocator {
  static bool _isInitialized = false;
  static final _logger = LoggerService(EnvConfigFactory.getConfig());

  static Future<void> init() async {
    if (_isInitialized) {
      _logger.warning('ServiceLocator is already initialized');
      return;
    }

    try {
      _logger.info('Initializing ServiceLocator');

      await _registerDependencies();
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

  static Future<void> _registerDependencies() async {
    await _registerCore();
    await _registerServices();
    await _registerNetworking();
  }

  static Future<void> _registerCore() async {
    try {
      // Register synchronous dependencies first
      locator.registerSingleton<EnvConfig>(EnvConfigFactory.getConfig());
      locator.registerSingleton<LoggerService>(_logger);

      // Register asynchronous dependencies
      final sharedPrefs = await SharedPreferences.getInstance();
      locator.registerSingleton<SharedPreferences>(sharedPrefs);

      // Register services that depend on core dependencies
      locator.registerLazySingleton<LocalStorageService>(
            () => LocalStorageService(
          preferences: locator<SharedPreferences>(),
          config: locator<EnvConfig>(),
          logger: locator<LoggerService>(),
        ),
      );

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

  static Future<void> _registerNetworking() async {
    try {
      // Register interceptors
      locator.registerLazySingleton<DioInterceptors>(
            () => DioInterceptors(
          logger: locator<LoggerService>(),
          config: locator<EnvConfig>(),
          storage: locator<LocalStorageService>(),
        ),
      );

      // Register networking clients
      locator.registerLazySingleton<ApiClient>(
            () => ApiClient(
          config: locator<EnvConfig>(),
          logger: locator<LoggerService>(),
          interceptors: locator<DioInterceptors>(),
        ),
      );

      locator.registerLazySingleton<FtpService>(
            () => FtpService(
          config: locator<EnvConfig>(),
          logger: locator<LoggerService>(),
        ),
      );

      _logger.info('Networking dependencies registered successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to register networking dependencies',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> _registerServices() async {
    try {
      // Register analytics first as other services might depend on it
      locator.registerLazySingleton<AnalyticsService>(
            () => AnalyticsService(
          config: locator<EnvConfig>(),
          logger: locator<LoggerService>(),
        ),
      );

      // Register services that depend on analytics
      locator.registerLazySingleton<FirebaseService>(
            () => FirebaseService(
          config: locator<EnvConfig>(),
          logger: locator<LoggerService>(),
          analytics: locator<AnalyticsService>(),
        ),
      );

      _logger.info('Services registered successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to register services',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> _validateRegistrations() async {
    final requiredServices = <Type, String>{
      SharedPreferences: 'SharedPreferences',
      EnvConfig: 'EnvConfig',
      LoggerService: 'LoggerService',
      LocalStorageService: 'LocalStorageService',
      DioInterceptors: 'DioInterceptors',
      ApiClient: 'ApiClient',
      FtpService: 'FtpService',
      AnalyticsService: 'AnalyticsService',
      FirebaseService: 'FirebaseService',
    };

    try {
      for (final entry in requiredServices.entries) {
        if (!locator.isRegistered<Object>(type: entry.key)) {
          throw ServiceLocatorException(
            'Required service ${entry.value} is not registered',
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

      // Initialize services that require async initialization
      await Future.wait([
        _initializeFirebase(),
        _initializeFtp(),
        _initializeApi(),
        _initializeAnalytics(),
      ], eagerError: true);

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

  static Future<void> _initializeFirebase() async {
    try {
      await locator<FirebaseService>().initialize();
      _logger.info('Firebase initialized successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Firebase initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> _initializeFtp() async {
    try {
      await locator<FtpService>().checkConnection();
      _logger.info('FTP connection verified');
    } catch (e, stackTrace) {
      _logger.error(
        'FTP connection check failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> _initializeApi() async {
    try {
      final isConnected = await locator<ApiClient>().checkConnection();
      if (!isConnected) {
        throw ServiceLocatorException('API health check failed');
      }
      _logger.info('API connection verified');
    } catch (e, stackTrace) {
      _logger.error(
        'API connection check failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> _initializeAnalytics() async {
    try {
      await locator<AnalyticsService>().initialize();
      _logger.info('Analytics initialized successfully');
    } catch (e, stackTrace) {
      _logger.error(
        'Analytics initialization failed',
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
      locator.reset();
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