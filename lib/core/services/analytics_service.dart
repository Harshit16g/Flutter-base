// lib/core/services/analytics_service.dart

import 'package:injectable/injectable.dart';
import '../config/env_config.dart';
import '../utils/logger_service.dart';

@singleton
class AnalyticsService {
  final EnvConfig _config;
  final LoggerService _logger;
  bool _isInitialized = false;

  AnalyticsService({
    required EnvConfig config,
    required LoggerService logger,
  })  : _config = config,
        _logger = logger;

  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        await _logger.warning('Analytics service is already initialized');
        return;
      }

      await _logger.info(
        'Initializing Analytics Service',
        error: {
          'enableAnalytics': _config.enableAnalytics,
          'enableCrashReporting': _config.enableCrashReporting,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      // TODO: Initialize your analytics platform here (Firebase Analytics, Mixpanel, etc.)

      _isInitialized = true;
      await _logger.info('Analytics Service initialized successfully');
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to initialize Analytics Service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> logEvent(
      String eventName, {
        Map<String, dynamic>? parameters,
        bool forceSend = false,
      }) async {
    if (!_config.enableAnalytics && !forceSend) {
      await _logger.debug(
        'Analytics event skipped (disabled)',
        error: {
          'eventName': eventName,
          'parameters': parameters,
        },
      );
      return;
    }

    try {
      await _logger.info(
        'Logging analytics event',
        error: {
          'eventName': eventName,
          'parameters': parameters,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      // TODO: Implement your analytics event logging logic here
      // Example: await FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);

    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to log analytics event',
        error: {
          'eventName': eventName,
          'parameters': parameters,
          'error': e.toString(),
        },
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> logError(
      String errorMessage, {
        Map<String, dynamic>? parameters,
        StackTrace? stackTrace,
        bool forceSend = false,
      }) async {
    if (!_config.enableCrashReporting && !forceSend) {
      await _logger.debug(
        'Error logging skipped (disabled)',
        error: {
          'errorMessage': errorMessage,
          'parameters': parameters,
        },
      );
      return;
    }

    try {
      await _logger.error(
        'Logging error to analytics',
        error: {
          'errorMessage': errorMessage,
          'parameters': parameters,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
        stackTrace: stackTrace,
      );

      // TODO: Implement your error logging logic here
      // Example: await FirebaseCrashlytics.instance.recordError(errorMessage, stackTrace, reason: parameters?['reason']);

    } catch (e, trace) {
      await _logger.error(
        'Failed to log error to analytics',
        error: {
          'originalError': errorMessage,
          'loggingError': e.toString(),
          'parameters': parameters,
        },
        stackTrace: trace,
      );
    }
  }

  Future<void> setUserProperties({
    required String userId,
    Map<String, dynamic>? properties,
    bool forceSend = false,
  }) async {
    if (!_config.enableAnalytics && !forceSend) {
      await _logger.debug(
        'User properties update skipped (disabled)',
        error: {
          'userId': userId,
          'properties': properties,
        },
      );
      return;
    }

    try {
      await _logger.info(
        'Setting user properties',
        error: {
          'userId': userId,
          'properties': properties,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      // TODO: Implement your user properties setting logic here
      // Example: await FirebaseAnalytics.instance.setUserProperty(name: key, value: value);

    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to set user properties',
        error: {
          'userId': userId,
          'properties': properties,
          'error': e.toString(),
        },
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_config.enableAnalytics) {
      await _logger.debug(
        'Screen view logging skipped (disabled)',
        error: {
          'screenName': screenName,
          'screenClass': screenClass,
        },
      );
      return;
    }

    try {
      await _logger.info(
        'Logging screen view',
        error: {
          'screenName': screenName,
          'screenClass': screenClass,
          'parameters': parameters,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      // TODO: Implement your screen view logging logic here
      // Example: await FirebaseAnalytics.instance.logScreenView(screenName: screenName, screenClass: screenClass);

    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to log screen view',
        error: {
          'screenName': screenName,
          'screenClass': screenClass,
          'error': e.toString(),
        },
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> logUserAction({
    required String action,
    required String category,
    String? label,
    int? value,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_config.enableAnalytics) {
      await _logger.debug(
        'User action logging skipped (disabled)',
        error: {
          'action': action,
          'category': category,
        },
      );
      return;
    }

    try {
      await _logger.info(
        'Logging user action',
        error: {
          'action': action,
          'category': category,
          'label': label,
          'value': value,
          'parameters': parameters,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      // TODO: Implement your user action logging logic here

    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to log user action',
        error: {
          'action': action,
          'category': category,
          'error': e.toString(),
        },
        stackTrace: stackTrace,
      );
    }
  }

  bool get isInitialized => _isInitialized;

  Future<void> reset() async {
    try {
      _isInitialized = false;
      await _logger.info('Analytics Service reset');
      await initialize();
    } catch (e, stackTrace) {
      await _logger.error(
        'Failed to reset Analytics Service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}