class AppConfig {
  static const String appName = 'Flutter Base';
  static const String apiUrl = 'https://api.example.com'; // Replace with your API URL
  static const String ftpHost = 'ftp.example.com'; // Replace with your FTP host
  
  // API Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  
  // Cache configuration
  static const int cacheMaxAge = 7; // days
  static const int cacheMaxSize = 50; // MB
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
}
