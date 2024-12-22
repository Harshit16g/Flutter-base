// lib/core/utils/logger_service.dart
//USAGE ::
//void example() async {
//   final logger = LoggerService(localStorage, config);
//
//   // Log with context
//   await logger.info(
//     'User action performed',
//     metadata: {
//       'action': 'login',
//       'timestamp': '2024-12-22 18:25:07',
//       'userId': 'Harshit16g',
//     },
//   );
//
//   // Get statistics
//   final stats = await logger.getLogStatistics(
//     startTime: DateTime.now().subtract(const Duration(days: 1)),
//   );
//   print('Error count in last 24h: ${stats['errorCount']}');
//
//   // Export logs
//   final jsonLogs = await logger.exportLogsAsJson();
//   final csvLogs = await logger.exportLogsAsCsv();
//
//   // Check logger health
//   final health = await logger.checkLoggerHealth();
//   print('Logger status: ${health['status']}');
// }


import 'dart:convert';
import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../storage/local_storage_service.dart';
import '../constants/storage_constants.dart';
import '../config/env_config.dart';

enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  wtf, // What a Terrible Failure
}

class LogConfiguration {
  final bool enableFileLogging;
  final bool enableConsoleLogging;
  final bool enableStorageSaving;
  final int maxFileSize;
  final int maxStoredLogs;
  final List<LogLevel> enabledLevels;
  final String logFilePrefix;
  final Duration logRetentionPeriod;

  const LogConfiguration({
    required this.enableFileLogging,
    required this.enableConsoleLogging,
    required this.enableStorageSaving,
    required this.maxFileSize,
    required this.maxStoredLogs,
    required this.enabledLevels,
    this.logFilePrefix = 'app_log_',
    this.logRetentionPeriod = const Duration(days: 7),
  });

  factory LogConfiguration.fromEnvironment(EnvConfig config) {
    if (config.isProduction) {
      return LogConfiguration(
        enableFileLogging: true,
        enableConsoleLogging: false,
        enableStorageSaving: true,
        maxFileSize: 5 * 1024 * 1024, // 5MB
        maxStoredLogs: 100,
        enabledLevels: [
          LogLevel.info,
          LogLevel.warning,
          LogLevel.error,
          LogLevel.wtf,
        ],
        logRetentionPeriod: const Duration(days: 30),
      );
    } else if (config.isStaging) {
      return LogConfiguration(
        enableFileLogging: true,
        enableConsoleLogging: true,
        enableStorageSaving: true,
        maxFileSize: 10 * 1024 * 1024, // 10MB
        maxStoredLogs: 200,
        enabledLevels: LogLevel.values,
        logRetentionPeriod: const Duration(days: 14),
      );
    } else {
      return LogConfiguration(
        enableFileLogging: true,
        enableConsoleLogging: true,
        enableStorageSaving: true,
        maxFileSize: 20 * 1024 * 1024, // 20MB
        maxStoredLogs: 500,
        enabledLevels: LogLevel.values,
        logRetentionPeriod: const Duration(days: 7),
      );
    }
  }
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? userLogin;
  final String environment;
  final String? error;
  final String? stackTrace;
  final Map<String, dynamic>? metadata;
  final String? deviceInfo;
  final String? appVersion;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.userLogin,
    required this.environment,
    this.error,
    this.stackTrace,
    this.metadata,
    this.deviceInfo,
    this.appVersion,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: LogLevel.values.firstWhere(
            (e) => e.toString() == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'] as String,
      userLogin: json['userLogin'] as String?,
      environment: json['environment'] as String,
      error: json['error'] as String?,
      stackTrace: json['stackTrace'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      deviceInfo: json['deviceInfo'] as String?,
      appVersion: json['appVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toUtc().toIso8601String(),
    'level': level.toString(),
    'message': message,
    'userLogin': userLogin,
    'environment': environment,
    'error': error,
    'stackTrace': stackTrace,
    'metadata': metadata,
    'deviceInfo': deviceInfo,
    'appVersion': appVersion,
  };

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toUtc().toIso8601String()}] ');
    buffer.write('[${level.toString().toUpperCase()}] ');
    if (userLogin != null) buffer.write('[$userLogin] ');
    if (appVersion != null) buffer.write('[$appVersion] ');
    buffer.write(message);
    if (error != null) buffer.write('\nError: $error');
    if (stackTrace != null) buffer.write('\nStackTrace: $stackTrace');
    if (metadata != null && metadata!.isNotEmpty) {
      buffer.write('\nMetadata: $metadata');
    }
    if (deviceInfo != null) buffer.write('\nDevice: $deviceInfo');
    return buffer.toString();
  }
}

@singleton
class LoggerService {
  final LocalStorageService _localStorage;
  final EnvConfig _config;
  late final LogConfiguration _logConfig;
  String? _currentUserLogin;
  String? _currentDeviceInfo;
  String? _currentAppVersion;
  final String _logFileName = 'logs.txt';

  // File handle for the current log file
  File? _currentLogFile;
  DateTime? _currentLogFileCreationDate;

  LoggerService(this._localStorage,
      this._config,) {
    _initializeLogger();
  }

  Future<void> _initializeLogger() async {
    _logConfig = LogConfiguration.fromEnvironment(_config);
    _currentUserLogin = _localStorage.getUserLogin();
    await _initializeLogFile();
    await _cleanupOldLogs();
  }

  Future<void> _initializeLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName = '${_logConfig.logFilePrefix}${now
          .toIso8601String()}.log';
      _currentLogFile = File('${directory.path}/$fileName');
      _currentLogFileCreationDate = now;

      // Create the file if it doesn't exist
      if (!await _currentLogFile!.exists()) {
        await _currentLogFile!.create();
        await _writeLogHeader();
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize log file: $e');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> _writeLogHeader() async {
    if (_currentLogFile == null) return;

    final header = '''
==========================================================
Log File Created: ${DateTime.now().toUtc().toIso8601String()}
Environment: ${_config.environment}
App Version: $_currentAppVersion
Device Info: $_currentDeviceInfo
==========================================================

''';
    await _currentLogFile!.writeAsString(header);
  }

  Future<void> log(String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    // Check if this log level is enabled
    if (!_logConfig.enabledLevels.contains(level)) return;

    final entry = LogEntry(
      timestamp: DateTime.now().toUtc(),
      level: level,
      message: message,
      userLogin: _currentUserLogin,
      environment: _config.environment,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
      metadata: metadata,
      deviceInfo: _currentDeviceInfo,
      appVersion: _currentAppVersion,
    );

    // Console logging
    if (_logConfig.enableConsoleLogging) {
      _printToConsole(entry);
    }

    // File logging
    if (_logConfig.enableFileLogging) {
      await _writeToFile(entry);
    }

    // Storage saving for important logs
    if (_logConfig.enableStorageSaving &&
        (level == LogLevel.error || level == LogLevel.wtf)) {
      await _saveToStorage(entry);
    }
  }

  void _printToConsole(LogEntry entry) {
    final colors = {
      LogLevel.verbose: '\x1B[37m', // White
      LogLevel.debug: '\x1B[36m', // Cyan
      LogLevel.info: '\x1B[32m', // Green
      LogLevel.warning: '\x1B[33m', // Yellow
      LogLevel.error: '\x1B[31m', // Red
      LogLevel.wtf: '\x1B[35m', // Magenta
    };

    final resetCode = '\x1B[0m';
    final color = colors[entry.level] ?? resetCode;

    debugPrint('$color${entry.toString()}$resetCode');
  }

  Future<void> _writeToFile(LogEntry entry) async {
    if (_currentLogFile == null) return;

    try {
      // Check if we need to rotate the log file
      if (await _shouldRotateLogFile()) {
        await _rotateLogFile();
      }

      // Write the log entry
      await _currentLogFile!.writeAsString(
        '${entry.toString()}\n',
        mode: FileMode.append,
      );
    } catch (e, stackTrace) {
      debugPrint('Failed to write to log file: $e');
      debugPrint(stackTrace.toString());
    }
  }

  Future<bool> _shouldRotateLogFile() async {
    if (_currentLogFile == null || !await _currentLogFile!.exists())
      return true;

    final fileSize = await _currentLogFile!.length();
    if (fileSize >= _logConfig.maxFileSize) return true;

    // Also rotate if the file is older than the retention period
    if (_currentLogFileCreationDate != null) {
      final age = DateTime.now().difference(_currentLogFileCreationDate!);
      if (age >= _logConfig.logRetentionPeriod) return true;
    }

    return false;
  }

  Future<void> _rotateLogFile() async {
    if (_currentLogFile == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final newFileName =
          '${_logConfig.logFilePrefix}${now.toIso8601String()}.log';

      // Archive the current log file
      final archiveDir = Directory('${directory.path}/archived_logs');
      if (!await archiveDir.exists()) {
        await archiveDir.create();
      }

      if (await _currentLogFile!.exists()) {
        final archivePath = '${archiveDir.path}/${_currentLogFile!.uri
            .pathSegments.last}';
        await _currentLogFile!.copy(archivePath);
        await _currentLogFile!.delete();
      }

      // Create new log file
      _currentLogFile = File('${directory.path}/$newFileName');
      _currentLogFileCreationDate = now;
      await _writeLogHeader();
    } catch (e, stackTrace) {
      debugPrint('Failed to rotate log file: $e');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> _saveToStorage(LogEntry entry) async {
    try {
      final List<LogEntry> logs = await getRecentLogs();
      logs.add(entry);

      // Keep only recent logs based on configuration
      while (logs.length > _logConfig.maxStoredLogs) {
        logs.removeAt(0);
      }

      final List<Map<String, dynamic>> serializedLogs =
      logs.map((log) => log.toJson()).toList();

      await _localStorage.write(
        StorageConstants.errorLogs,
        jsonEncode(serializedLogs),
      );
    } catch (e, stackTrace) {
      debugPrint('Failed to save to storage: $e');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> _cleanupOldLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final archiveDir = Directory('${directory.path}/archived_logs');

      if (await archiveDir.exists()) {
        final files = await archiveDir
            .list()
            .where((entity) =>
        entity is File &&
            entity.path.contains(_logConfig.logFilePrefix))
            .toList();

        for (final file in files) {
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);

          if (age >= _logConfig.logRetentionPeriod) {
            await file.delete();
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to cleanup old logs: $e');
      debugPrint(stackTrace.toString());
    }
  }

  // Helper methods for different log levels
  Future<void> verbose(String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      message,
      level: LogLevel.verbose,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  Future<void> debug(String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      message,
      level: LogLevel.debug,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  Future<void> info(String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      message,
      level: LogLevel.info,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  Future<void> warning(String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      message,
      level: LogLevel.warning,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  Future<void> error(String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      message,
      level: LogLevel.error,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  Future<void> wtf(String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      message,
      level: LogLevel.wtf,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  // Utility methods
  Future<List<LogEntry>> getRecentLogs() async {
    try {
      final String? logsJson = _localStorage.read<String>(
          StorageConstants.errorLogs);
      if (logsJson == null) return [];

      final List<dynamic> logs = jsonDecode(logsJson);
      return logs
          .map((log) => LogEntry.fromJson(log as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to get recent logs: $e');
      return [];
    }
  }

// ... (continuing from previous implementation)

  // Context Management
  void updateCurrentUser(String? userLogin) {
    _currentUserLogin = userLogin;
    debug(
      'Current user updated',
      metadata: {
        'newUser': userLogin,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  void updateDeviceInfo(String deviceInfo) {
    _currentDeviceInfo = deviceInfo;
    debug(
      'Device info updated',
      metadata: {'deviceInfo': deviceInfo},
    );
  }

  void updateAppVersion(String version) {
    _currentAppVersion = version;
    debug(
      'App version updated',
      metadata: {'version': version},
    );
  }

  // Advanced Query Methods
  Future<List<LogEntry>> getFilteredLogs({
    DateTime? startTime,
    DateTime? endTime,
    List<LogLevel>? levels,
    String? userLogin,
    String? contains,
    String? deviceInfo,
    String? appVersion,
  }) async {
    final logs = await getRecentLogs();
    return logs.where((entry) {
      if (startTime != null && entry.timestamp.isBefore(startTime))
        return false;
      if (endTime != null && entry.timestamp.isAfter(endTime)) return false;
      if (levels != null && !levels.contains(entry.level)) return false;
      if (userLogin != null && entry.userLogin != userLogin) return false;
      if (contains != null &&
          !entry.message.toLowerCase().contains(contains.toLowerCase())) {
        return false;
      }
      if (deviceInfo != null && entry.deviceInfo != deviceInfo) return false;
      if (appVersion != null && entry.appVersion != appVersion) return false;
      return true;
    }).toList();
  }

  // Statistics and Analytics
// Statistics and Analytics
  Future<Map<String, dynamic>> getLogStatistics({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final logs = await getFilteredLogs(
      startTime: startTime,
      endTime: endTime,
    );

    final stats = {
      'totalCount': logs.length,
      'levelCounts': <String, int>{},
      'userCounts': <String, int>{},
      'deviceCounts': <String, int>{},
      'errorCount': 0,
      'uniqueUsers': <String>{},
      'uniqueDevices': <String>{},
      'timeRange': {
        'start': logs.isEmpty ? null : logs.first.timestamp.toIso8601String(),
        'end': logs.isEmpty ? null : logs.last.timestamp.toIso8601String(),
      },
    };

    for (final entry in logs) {
      // Count by level
      final levelKey = entry.level.toString();
      stats['levelCounts'] as Map<String, int>; // Cast to correct type
      (stats['levelCounts'] as Map<String, int>)[levelKey] =
          ((stats['levelCounts'] as Map<String, int>)[levelKey] ?? 0) + 1;

      // Count by user
      if (entry.userLogin != null) {
        stats['userCounts'] as Map<String, int>; // Cast to correct type
        (stats['userCounts'] as Map<String, int>)[entry.userLogin!] =
            ((stats['userCounts'] as Map<String, int>)[entry.userLogin!] ?? 0) +
                1;
        (stats['uniqueUsers'] as Set<String>).add(entry.userLogin!);
      }

      // Count by device
      if (entry.deviceInfo != null) {
        stats['deviceCounts'] as Map<String, int>; // Cast to correct type
        (stats['deviceCounts'] as Map<String, int>)[entry.deviceInfo!] =
            ((stats['deviceCounts'] as Map<String, int>)[entry.deviceInfo!] ??
                0) + 1;
        (stats['uniqueDevices'] as Set<String>).add(entry.deviceInfo!);
      }

      // Count errors
      if (entry.level == LogLevel.error || entry.level == LogLevel.wtf) {
        stats['errorCount'] = (stats['errorCount'] as int) + 1;
      }
    }

    // Convert sets to lists for JSON serialization
    stats['uniqueUsers'] = (stats['uniqueUsers'] as Set<String>).toList();
    stats['uniqueDevices'] = (stats['uniqueDevices'] as Set<String>).toList();

    return stats;
  }

  // Export Methods
  Future<String> exportLogsAsJson({
    DateTime? startTime,
    DateTime? endTime,
    List<LogLevel>? levels,
  }) async {
    final logs = await getFilteredLogs(
      startTime: startTime,
      endTime: endTime,
      levels: levels,
    );

    return jsonEncode({
      'exportTime': DateTime.now().toUtc().toIso8601String(),
      'environment': _config.environment,
      'appVersion': _currentAppVersion,
      'deviceInfo': _currentDeviceInfo,
      'logCount': logs.length,
      'timeRange': {
        'start': startTime?.toIso8601String(),
        'end': endTime?.toIso8601String(),
      },
      'logs': logs.map((e) => e.toJson()).toList(),
    });
  }

  Future<String> exportLogsAsCsv({
    DateTime? startTime,
    DateTime? endTime,
    List<LogLevel>? levels,
  }) async {
    final logs = await getFilteredLogs(
      startTime: startTime,
      endTime: endTime,
      levels: levels,
    );

    final buffer = StringBuffer();

    // Write CSV header
    buffer.writeln(
        'Timestamp,Level,User,Message,Error,StackTrace,DeviceInfo,AppVersion,Environment,Metadata'
    );

    // Write log entries
    for (final entry in logs) {
      buffer.writeln([
        entry.timestamp.toIso8601String(),
        entry.level.toString(),
        entry.userLogin ?? '',
        _escapeCsvField(entry.message),
        _escapeCsvField(entry.error ?? ''),
        _escapeCsvField(entry.stackTrace ?? ''),
        _escapeCsvField(entry.deviceInfo ?? ''),
        entry.appVersion ?? '',
        entry.environment,
        _escapeCsvField(jsonEncode(entry.metadata ?? {})),
      ].join(','));
    }

    return buffer.toString();
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // Cleanup Methods
  Future<void> clearLogs() async {
    try {
      // Clear stored logs
      await _localStorage.write(StorageConstants.errorLogs, jsonEncode([]));

      // Clear current log file
      if (_currentLogFile != null && await _currentLogFile!.exists()) {
        await _currentLogFile!.delete();
      }

      // Initialize new log file
      await _initializeLogFile();

      await info('Logs cleared successfully');
    } catch (e, stackTrace) {
      debugPrint('Failed to clear logs: $e');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> archiveLogs() async {
    try {
      final now = DateTime.now().toUtc();
      final logs = await getRecentLogs();

      if (logs.isEmpty) return;

      final directory = await getApplicationDocumentsDirectory();
      final archiveDir = Directory('${directory.path}/log_archives');

      if (!await archiveDir.exists()) {
        await archiveDir.create();
      }

      final archiveFile = File(
          '${archiveDir.path}/archive_${now.toIso8601String()}.json'
      );

      await archiveFile.writeAsString(await exportLogsAsJson());
      await clearLogs();

      await info(
        'Logs archived successfully',
        metadata: {'archiveFile': archiveFile.path},
      );
    } catch (e, stackTrace) {
      error(
        'Failed to archive logs',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Health Check Method
  Future<int> _getDirectoryTotalSpace(Directory directory) async {
    try {
      if (Platform.isAndroid) {
        // For Android, we can use StatFs to get storage information
        // This would require platform-specific code
        return 0; // Implement platform-specific code as needed
      } else if (Platform.isIOS) {
        // For iOS, we can use NSFileSystemAttributes
        // This would require platform-specific code
        return 0; // Implement platform-specific code as needed
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getDirectoryFreeSpace(Directory directory) async {
    try {
      if (Platform.isAndroid) {
        // For Android, we can use StatFs to get storage information
        // This would require platform-specific code
        return 0; // Implement platform-specific code as needed
      } else if (Platform.isIOS) {
        // For iOS, we can use NSFileSystemAttributes
        // This would require platform-specific code
        return 0; // Implement platform-specific code as needed
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Update the checkLoggerHealth method
  Future<Map<String, dynamic>> checkLoggerHealth() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final currentFileSize = _currentLogFile != null &&
          await _currentLogFile!.exists() ?
      await _currentLogFile!.length() : 0;

      final stats = await getLogStatistics(
        startTime: DateTime.now().subtract(const Duration(days: 1)),
      );

      return {
        'status': 'healthy',
        'currentLogFile': {
          'path': _currentLogFile?.path,
          'size': currentFileSize,
          'creationDate': _currentLogFileCreationDate?.toIso8601String(),
          'utilizationPercentage':
          (currentFileSize / _logConfig.maxFileSize) * 100,
        },
        'storage': {
          'available': await _getDirectoryFreeSpace(directory),
          'total': await _getDirectoryTotalSpace(directory),
        },
        'statistics': stats,
        'configuration': {
          'environment': _config.environment,
          'maxFileSize': _logConfig.maxFileSize,
          'maxStoredLogs': _logConfig.maxStoredLogs,
          'enabledLevels': _logConfig.enabledLevels
              .map((e) => e.toString())
              .toList(),
        },
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
    } catch (e, stackTrace) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
    }
  }

}

//TODO::For more accurate disk space information, you would need to implement platform-specific code using method channels.
// Platform-specific code for getting storage information
//static const platform = MethodChannel('com.app/storage');
//
// Future<int> _getDirectoryTotalSpace(Directory directory) async {
//   try {
//     final int result = await platform.invokeMethod('getTotalSpace', {
//       'path': directory.path,
//     });
//     return result;
//   } on PlatformException catch (e) {
//     debugPrint('Failed to get total space: ${e.message}');
//     return 0;
//   }
// }
//
// Future<int> _getDirectoryFreeSpace(Directory directory) async {
//   try {
//     final int result = await platform.invokeMethod('getFreeSpace', {
//       'path': directory.path,
//     });
//     return result;
//   } on PlatformException catch (e) {
//     debugPrint('Failed to get free space: ${e.message}');
//     return 0;
//   }
// }

//You would then need to implement these methods in your Android and iOS native code:


// For Android (Kotlin):
//private fun getTotalSpace(path: String): Long {
//     val stat = StatFs(path)
//     return stat.totalBytes
// }
//
// private fun getFreeSpace(path: String): Long {
//     val stat = StatFs(path)
//     return stat.availableBytes
// }

//**For iOS (Swift):**
//private func getTotalSpace(path: String) -> Int64 {
//     do {
//         let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
//         return (attributes[.systemSize] as? NSNumber)?.int64Value ?? 0
//     } catch {
//         return 0
//     }
// }
//
// private func getFreeSpace(path: String) -> Int64 {
//     do {
//         let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
//         return (attributes[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
//     } catch {
//         return 0
//     }
// }