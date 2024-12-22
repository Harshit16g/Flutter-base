enum Flavor { dev, staging, prod }

class FlavorConfig {
  final Flavor flavor;
  final String apiBaseUrl;
  final bool enableLogging;

  const FlavorConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.enableLogging,
  });

  static late FlavorConfig _instance;
  
  static void initialize(FlavorConfig config) {
    _instance = config;
  }

  static FlavorConfig get instance => _instance;
}
