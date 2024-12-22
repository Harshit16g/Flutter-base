// lib/core/constants/storage_constants.dart

class StorageConstants {
  // User Authentication & Session
  static const String userLogin = 'user_login';
  static const String lastLoginDate = 'last_login_date';
  static const String sessionExpiry = 'session_expiry';
  static const String refreshToken = 'refresh_token';
  static const String accessToken = 'access_token';
  static const String userProfile = 'user_profile';
  static const String lastSyncTime = 'last_sync_time';

  // App State & Preferences
  static const String isDarkMode = 'is_dark_mode';
  static const String languageCode = 'language_code';
  static const String isFirstLaunch = 'is_first_launch';
  static const String appVersion = 'app_version';
  static const String deviceId = 'device_id';
  static const String userPreferences = 'user_preferences';

  // Security & Authentication
  static const String encryptionKey = 'encryption_key';
  static const String biometricEnabled = 'biometric_enabled';
  static const String pinEnabled = 'pin_enabled';
  static const String pinHash = 'pin_hash';
  static const String securityLevel = 'security_level';
  static const String lastPasswordChange = 'last_password_change';

  // Settings & Configuration
  static const String notificationsEnabled = 'notifications_enabled';
  static const String analyticsOptIn = 'analytics_opt_in';
  static const String pushToken = 'push_token';
  static const String themeCustomization = 'theme_customization';
  static const String fontScale = 'font_scale';

  // Cache Keys
  static const String apiCache = 'api_cache';
  static const String imageCache = 'image_cache';
  static const String offlineData = 'offline_data';
  static const String searchHistory = 'search_history';
  static const String recentItems = 'recent_items';

  // Feature Flags
  static const String experimentalFeatures = 'experimental_features';
  static const String betaAccess = 'beta_access';
  static const String featureFlags = 'feature_flags';

  // Analytics & Logging
  static const String errorLogs = 'error_logs';
  static const String analyticsEvents = 'analytics_events';
  static const String crashReports = 'crash_reports';
  static const String userBehavior = 'user_behavior';
  static const String performanceMetrics = 'performance_metrics';

  // Timestamps
  static const String lastBackup = 'last_backup';
  static const String lastUpdate = 'last_update';
  static const String lastCleanup = 'last_cleanup';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  // Prefixes for dynamic keys
  static const String cachePrefix = 'cache_';
  static const String settingPrefix = 'setting_';
  static const String userDataPrefix = 'user_data_';
  static const String tempDataPrefix = 'temp_';

  // Key Patterns
  static final RegExp cachePattern = RegExp(r'^cache_.*$');
  static final RegExp settingPattern = RegExp(r'^setting_.*$');
  static final RegExp userDataPattern = RegExp(r'^user_data_.*$');
  static final RegExp tempDataPattern = RegExp(r'^temp_.*$');

  // Utility Methods
  static String getCacheKey(String identifier) => '$cachePrefix$identifier';
  static String getSettingKey(String identifier) => '$settingPrefix$identifier';
  static String getUserDataKey(String identifier) => '$userDataPrefix$identifier';
  static String getTempDataKey(String identifier) => '$tempDataPrefix$identifier';

  // Validation Methods
  static bool isCacheKey(String key) => cachePattern.hasMatch(key);
  static bool isSettingKey(String key) => settingPattern.hasMatch(key);
  static bool isUserDataKey(String key) => userDataPattern.hasMatch(key);
  static bool isTempDataKey(String key) => tempDataPattern.hasMatch(key);

  // Additional Session & Auth Constants
  static const String authToken = 'auth_token';
  static const String environment = 'environment';
  static const String initializationDate = 'initialization_date';
  static const String sessionData = 'session_data';
  static const String themeMode = 'theme_mode';


  static const String storageHealth = 'storage_health';
  static const String cleanupTimestamp = 'cleanup_timestamp';

  // Storage Thresholds
  static const double criticalStorageThreshold = 0.9; // 90%
  static const double warningStorageThreshold = 0.7; // 70%

  // Cleanup Settings
  static const int cleanupBatchSize = 10;
  static const Duration cleanupInterval = Duration(days: 7);

  // Groups of Related Keys
  static const List<String> securityKeys = [
    encryptionKey,
    biometricEnabled,
    pinEnabled,
    pinHash,
    securityLevel,
    lastPasswordChange,
  ];

  static const List<String> userSessionKeys = [
    userLogin,
    sessionExpiry,
    refreshToken,
    accessToken,
  ];

  static const List<String> analyticsKeys = [
    analyticsOptIn,
    analyticsEvents,
    crashReports,
    userBehavior,
    performanceMetrics,
  ];

  static const List<String> preferencesKeys = [
    isDarkMode,
    languageCode,
    notificationsEnabled,
    themeCustomization,
    fontScale,
  ];


  // Version Information
  static const String currentSchemaVersion = '1.0.0';
  static const String storageVersion = 'storage_version';

  // Private constructor to prevent instantiation
  const StorageConstants._();
}