enum Environment { dev, staging, prod }

class EnvConfig {
  static Environment environment = Environment.dev;
  
  static Map<String, dynamic> get config {
    switch (environment) {
      case Environment.dev:
        return {
          'apiUrl': 'https://dev-api.example.com',
          'enableLogging': true,
          'enableDebugTools': true,
        };
      case Environment.staging:
        return {
          'apiUrl': 'https://staging-api.example.com',
          'enableLogging': true,
          'enableDebugTools': false,
        };
      case Environment.prod:
        return {
          'apiUrl': 'https://api.example.com',
          'enableLogging': false,
          'enableDebugTools': false,
        };
    }
  }
}
