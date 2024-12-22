// lib/core/config/env_config.dart
//# Production
// flutter run \
//   --dart-define=API_KEY=prod_key \
//   --dart-define=FTP_HOST=ftp.production.com \
//   --dart-define=FTP_USERNAME=prod_user \
//   --dart-define=FTP_PASSWORD=prod_pass \
//   --dart-define=ENCRYPTION_KEY=prod_encryption_key
//
// # Development
// flutter run \
//   --dart-define=dev=true
//
// # Staging
// flutter run \
//   --dart-define=staging=true \
//   --dart-define=API_KEY=staging_key \
//   --dart-define=FTP_HOST=ftp.staging.com \
//   --dart-define=FTP_USERNAME=staging_user \
//   --dart-define=FTP_PASSWORD=staging_pass \
//   --dart-define=ENCRYPTION_KEY=staging_encryption_key
//USAGE :::
//void main() {
//   // Get configuration based on environment
//   final config = EnvConfigFactory.getConfig();
//
//   // Use configuration
//   print('API URL: ${config.apiUrl}');
//   print('Max Storage: ${config.maxStorageSize / StorageSizes.GB}GB');
// }


import 'package:injectable/injectable.dart';

/// Storage size constants
class StorageSizes {
  static const int KB = 1024;
  static const int MB = KB * 1024;
  static const int GB = MB * 1024;

  // Prevent instantiation
  StorageSizes._();
}

/// Environment names
class Environments {
  static const String dev = 'dev';
  static const String prod = 'prod';
  static const String staging = 'staging';

  // Prevent instantiation
  Environments._();
}

/// Environment variables names
class EnvVariables {
  static const String apiUrl = 'API_URL';
  static const String apiKey = 'API_KEY';
  static const String ftpHost = 'FTP_HOST';
  static const String ftpUsername = 'FTP_USERNAME';
  static const String ftpPassword = 'FTP_PASSWORD';
  static const String ftpPort = 'FTP_PORT';
  static const String encryptionKey = 'ENCRYPTION_KEY';

  // Prevent instantiation
  EnvVariables._();
}

/// Base paths for different environments
class BasePaths {
  static const String prod = '/storage/production';
  static const String dev = '/storage/development';
  static const String staging = '/storage/staging';

  // Prevent instantiation
  BasePaths._();
}

/// Abstract class defining configuration interface
abstract class EnvConfig {
  // API Configuration
  String get apiUrl;
  String get apiKey;
  Duration get apiTimeout;
  int get maxRetries;
  int get retryDelay;

  // FTP Configuration
  String get ftpHost;
  String get ftpUsername;
  String get ftpPassword;
  int get ftpPort;
  Duration get ftpTimeout;

  // Storage Configuration
  String get storageBasePath;
  double get maxStorageSize;

  // Cache Configuration
  Duration get cacheTimeout;
  int get maxCacheSize;

  // Security Configuration
  bool get enableSslPinning;
  List<String> get trustedHosts;
  String get encryptionKey;

  //analytics configuration
  bool get enableAnalytics;
  bool get enableCrashReporting;

  // Environment Information
  String get environment;
  bool get isProduction => environment == Environments.prod;
  bool get isDevelopment => environment == Environments.dev;
  bool get isStaging => environment == Environments.staging;

  // Debug Features
  bool get enableDebugLogging;
  bool get enablePerformanceMonitoring;
  bool get enableNetworkLogging;

  // Security Thresholds
  int get maxLoginAttempts;
  Duration get lockoutDuration;
  Duration get sessionTimeout;
  bool get requireBiometric;
  Duration get sessionDuration => const Duration(hours: 24);

  // Storage Limits
  int get maxFileSize;
  int get maxUploadSize;
  Duration get storageCleanupInterval;

  // Rate Limiting
  int get apiRateLimit;
  Duration get rateLimitWindow;
  int get maxConcurrentRequests;

  // Feature Flags
  Map<String, bool> get featureFlags;
  bool isFeatureEnabled(String featureKey);

  // Session Configuration



}

/// Production environment configuration
@Injectable(as: EnvConfig)
@prod
class ProdConfig implements EnvConfig {

  @override
  Duration get sessionDuration => const Duration(hours: 24);

  @override
  String get environment => Environments.prod;

  @override
  bool get isProduction => true;

  @override
  bool get isDevelopment => false;

  @override
  bool get isStaging => false;

  @override
  String get apiUrl => const String.fromEnvironment(
    EnvVariables.apiUrl,
    defaultValue: 'https://api.production.com',
  );

  @override
  String get apiKey => const String.fromEnvironment(EnvVariables.apiKey);

  @override
  Duration get apiTimeout => const Duration(seconds: 30);

  @override
  int get maxRetries => 5; // More retries in production

  @override
  int get retryDelay => 2000; // More conservative retry delay in production

  @override
  String get ftpHost => const String.fromEnvironment(
    EnvVariables.ftpHost,
    defaultValue: 'ftp.production.com',
  );

  @override
  String get ftpUsername => const String.fromEnvironment(EnvVariables.ftpUsername);

  @override
  String get ftpPassword => const String.fromEnvironment(EnvVariables.ftpPassword);

  @override
  int get ftpPort => const int.fromEnvironment(
    EnvVariables.ftpPort,
    defaultValue: 21,
  );

  @override
  Duration get ftpTimeout => const Duration(minutes: 5);

  @override
  String get storageBasePath => BasePaths.prod;

  @override
  double get maxStorageSize => StorageSizes.GB.toDouble(); // 1GB

  @override
  Duration get cacheTimeout => const Duration(hours: 24);

  @override
  int get maxCacheSize => 100 * StorageSizes.MB; // 100MB

  @override
  bool get enableSslPinning => true;

  @override
  List<String> get trustedHosts => const [
    'api.production.com',
    'ftp.production.com',
    'cdn.production.com',
  ];

  @override
  String get encryptionKey => const String.fromEnvironment(EnvVariables.encryptionKey);

  @override
  bool get enableAnalytics => true;

  @override
  bool get enableCrashReporting => true;

  @override
  bool get enableDebugLogging => false;

  @override
  bool get enablePerformanceMonitoring => true;

  @override
  bool get enableNetworkLogging => false;

  @override
  int get maxLoginAttempts => 5;

  @override
  Duration get lockoutDuration => const Duration(minutes: 30);

  @override
  Duration get sessionTimeout => const Duration(hours: 24);

  @override
  bool get requireBiometric => true;

  @override
  int get maxFileSize => 50 * StorageSizes.MB;

  @override
  int get maxUploadSize => 100 * StorageSizes.MB;

  @override
  Duration get storageCleanupInterval => const Duration(days: 7);

  @override
  int get apiRateLimit => 100;

  @override
  Duration get rateLimitWindow => const Duration(minutes: 1);

  @override
  int get maxConcurrentRequests => 10;

  @override
  Map<String, bool> get featureFlags => const {
    'newUI': true,
    'analytics': true,
    'push_notifications': true,
    'offline_mode': true,
  };

  @override
  bool isFeatureEnabled(String featureKey) => featureFlags[featureKey] ?? false;

}

/// Development environment configuration
@Injectable(as: EnvConfig)
@dev
class DevConfig implements EnvConfig {
  @override
  String get apiUrl => 'https://api.development.com';

  @override
  Duration get sessionDuration => const Duration(days: 7);

  @override
  String get apiKey => 'dev_api_key';

  @override
  Duration get apiTimeout => const Duration(minutes: 1);

  @override
  int get maxRetries => 2; // Less retries in dev environment

  @override
  int get retryDelay => 500; // Faster retries in dev environment

  @override
  String get ftpHost => 'ftp.development.com';

  @override
  String get ftpUsername => 'dev_user';

  @override
  String get ftpPassword => 'dev_password';

  @override
  int get ftpPort => 21;

  @override
  Duration get ftpTimeout => const Duration(minutes: 10);

  @override
  String get storageBasePath => BasePaths.dev;

  @override
  double get maxStorageSize => (2 * StorageSizes.GB).toDouble(); // 2GB

  @override
  Duration get cacheTimeout => const Duration(minutes: 30);

  @override
  int get maxCacheSize => 200 * StorageSizes.MB; // 200MB

  @override
  bool get enableSslPinning => false;

  @override
  List<String> get trustedHosts => [
    'api.development.com',
    'ftp.development.com',
    'localhost',
    '127.0.0.1',
  ];

  @override
  String get encryptionKey => 'dev_encryption_key';

  @override
  bool get enableAnalytics => false;

  @override
  bool get enableCrashReporting => true;

  @override
  String get environment => Environments.dev;

  @override
  bool get isProduction => false;

  @override
  bool get isDevelopment => true;

  @override
  bool get isStaging => false;


  @override
  bool get enableDebugLogging => false;

  @override
  bool get enablePerformanceMonitoring => true;

  @override
  bool get enableNetworkLogging => false;

  @override
  int get maxLoginAttempts => 5;

  @override
  Duration get lockoutDuration => const Duration(minutes: 30);

  @override
  Duration get sessionTimeout => const Duration(hours: 24);

  @override
  bool get requireBiometric => true;

  @override
  int get maxFileSize => 50 * StorageSizes.MB;

  @override
  int get maxUploadSize => 100 * StorageSizes.MB;

  @override
  Duration get storageCleanupInterval => const Duration(days: 7);

  @override
  int get apiRateLimit => 100;

  @override
  Duration get rateLimitWindow => const Duration(minutes: 1);

  @override
  int get maxConcurrentRequests => 10;

  @override
  Map<String, bool> get featureFlags => const {
    'newUI': true,
    'analytics': true,
    'push_notifications': true,
    'offline_mode': true,
  };

  @override
  bool isFeatureEnabled(String featureKey) => featureFlags[featureKey] ?? false;

}

/// Staging environment configuration
@Injectable(as: EnvConfig)
@Environment(Environments.staging)
class StagingConfig implements EnvConfig {
  @override
  String get apiUrl => const String.fromEnvironment(
    EnvVariables.apiUrl,
    defaultValue: 'https://api.staging.com',
  );

  @override
  Duration get sessionDuration => const Duration(days: 3);

  @override
  String get apiKey => const String.fromEnvironment(EnvVariables.apiKey);

  @override
  Duration get apiTimeout => const Duration(seconds: 45);

  @override
  int get maxRetries => 3;

  @override
  int get retryDelay => 1000;

  @override
  String get ftpHost => const String.fromEnvironment(
    EnvVariables.ftpHost,
    defaultValue: 'ftp.staging.com',
  );

  @override
  String get ftpUsername => const String.fromEnvironment(EnvVariables.ftpUsername);

  @override
  String get ftpPassword => const String.fromEnvironment(EnvVariables.ftpPassword);

  @override
  int get ftpPort => const int.fromEnvironment(
    EnvVariables.ftpPort,
    defaultValue: 21,
  );

  @override
  Duration get ftpTimeout => const Duration(minutes: 7);

  @override
  String get storageBasePath => BasePaths.staging;

  @override
  double get maxStorageSize => (1.5 * StorageSizes.GB).toDouble(); // 1.5GB

  @override
  Duration get cacheTimeout => const Duration(hours: 12);

  @override
  int get maxCacheSize => 150 * StorageSizes.MB; // 150MB

  @override
  bool get enableSslPinning => true;

  @override
  List<String> get trustedHosts => const [
    'api.staging.com',
    'ftp.staging.com',
    'cdn.staging.com',
  ];

  @override
  String get encryptionKey => const String.fromEnvironment(EnvVariables.encryptionKey);

  @override
  bool get enableAnalytics => false;

  @override
  bool get enableCrashReporting => true;

  @override
  String get environment => Environments.staging;

  @override
  bool get isProduction => false;

  @override
  bool get isDevelopment => false;

  @override
  bool get isStaging => true;


  @override
  bool get enableDebugLogging => false;

  @override
  bool get enablePerformanceMonitoring => true;

  @override
  bool get enableNetworkLogging => false;

  @override
  int get maxLoginAttempts => 5;

  @override
  Duration get lockoutDuration => const Duration(minutes: 30);

  @override
  Duration get sessionTimeout => const Duration(hours: 24);

  @override
  bool get requireBiometric => true;

  @override
  int get maxFileSize => 50 * StorageSizes.MB;

  @override
  int get maxUploadSize => 100 * StorageSizes.MB;

  @override
  Duration get storageCleanupInterval => const Duration(days: 7);

  @override
  int get apiRateLimit => 100;

  @override
  Duration get rateLimitWindow => const Duration(minutes: 1);

  @override
  int get maxConcurrentRequests => 10;

  @override
  Map<String, bool> get featureFlags => const {
    'newUI': true,
    'analytics': true,
    'push_notifications': true,
    'offline_mode': true,
  };

  @override
  bool isFeatureEnabled(String featureKey) => featureFlags[featureKey] ?? false;

}

/// Factory for creating environment-specific configurations
@singleton
class EnvConfigFactory {
  final EnvConfig config;

  EnvConfigFactory(@prod this.config);

  static EnvConfig getConfig() {
    if (const bool.fromEnvironment(Environments.dev)) {
      return DevConfig();
    } else if (const bool.fromEnvironment(Environments.staging)) {
      return StagingConfig();
    }
    return ProdConfig();
  }
}