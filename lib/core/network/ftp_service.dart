// lib/core/services/ftp_service.dart
//USAGE EXAMPLE::
//void main() async {
//   final config = EnvConfigFactory.getConfig();
//   final logger = LoggerService(/* dependencies */);
//   final analytics = AnalyticsService(config);
//   final ftpService = FtpService(config, logger, analytics);
//
//   // Upload file with analytics tracking
//   final success = await ftpService.uploadFile(
//     '/local/path/file.txt',
//     '/remote/path/file.txt',
//   );
//
//   // The analytics events will be automatically logged for:
//   // - Connection attempt
//   // - Upload start
//   // - Upload completion/failure
//   // - Disconnection
// }

import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:ftpconnect/ftpconnect.dart';
import '../config/env_config.dart';
import '../utils/logger_service.dart';
import '../services/analytics_service.dart';

@singleton
class FtpService {
  late FTPConnect _ftpConnect;
  final EnvConfig _config;
  final LoggerService _logger;
  final AnalyticsService _analytics;
  bool _isConnected = false;

  FtpService(
      this._config,
      this._logger,
      this._analytics,
      );

  Future<bool> connect() async {
    try {
      if (_isConnected) {
        await _logger.info('FTP already connected');
        return true;
      }

      _ftpConnect = FTPConnect(
        _config.ftpHost,
        user: _config.ftpUsername,
        pass: _config.ftpPassword,
        port: _config.ftpPort,
        timeout: _config.ftpTimeout.inSeconds,
      );

      await _ftpConnect.connect();
      _isConnected = true;

      await _logger.info(
        'FTP connection established',
        error: {
          'host': _config.ftpHost,
          'port': _config.ftpPort,
          'username': _config.ftpUsername,
        },
      );

      _analytics.logEvent('ftp_connected', parameters: {
        'host': _config.ftpHost,
        'port': _config.ftpPort,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      return true;
    } catch (e, stackTrace) {
      _isConnected = false;
      await _logger.error(
        'FTP connection failed',
        error: e,
        stackTrace: stackTrace,
      );

      _analytics.logError(
        'FTP Connection Failed',
        parameters: {
          'error': e.toString(),
          'host': _config.ftpHost,
          'port': _config.ftpPort,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      return false;
    }
  }

  Future<void> disconnect() async {
    if (!_isConnected) return;

    try {
      await _ftpConnect.disconnect();
      _isConnected = false;
      await _logger.info('FTP connection closed');

      _analytics.logEvent('ftp_disconnected', parameters: {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e, stackTrace) {
      await _logger.error(
        'FTP disconnect error',
        error: e,
        stackTrace: stackTrace,
      );

      _analytics.logError(
        'FTP Disconnect Failed',
        parameters: {
          'error': e.toString(),
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    }
  }

  Future<bool> uploadFile(
      String localPath,
      String remotePath, {
        Function(int, int)? onProgress,
      }) async {
    try {
      if (!await connect()) return false;

      final file = File(localPath);
      if (!await file.exists()) {
        throw FileSystemException('Local file does not exist', localPath);
      }

      final fileSize = await file.length();
      await _logger.info(
        'Starting FTP file upload',
        error: {
          'localPath': localPath,
          'remotePath': remotePath,
          'fileSize': fileSize,
        },
      );

      _analytics.logEvent('ftp_upload_started', parameters: {
        'localPath': localPath,
        'remotePath': remotePath,
        'fileSize': fileSize,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await _ftpConnect.uploadFile(
        file,
        sRemoteName: remotePath,
      );

      await _logger.info(
        'FTP file upload completed',
        error: {
          'localPath': localPath,
          'remotePath': remotePath,
          'fileSize': fileSize,
        },
      );

      _analytics.logEvent('ftp_upload_completed', parameters: {
        'localPath': localPath,
        'remotePath': remotePath,
        'fileSize': fileSize,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await disconnect();
      return true;
    } catch (e, stackTrace) {
      await _logger.error(
        'FTP upload failed',
        error: e,
        stackTrace: stackTrace,
      );

      _analytics.logError(
        'FTP Upload Failed',
        parameters: {
          'error': e.toString(),
          'localPath': localPath,
          'remotePath': remotePath,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      await disconnect();
      return false;
    }
  }

  Future<bool> downloadFile(
      String remotePath,
      String localPath, {
        Function(int, int)? onProgress,
      }) async {
    try {
      if (!await connect()) return false;

      final file = File(localPath);
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await _logger.info(
        'Starting FTP file download',
        error: {
          'remotePath': remotePath,
          'localPath': localPath,
        },
      );

      _analytics.logEvent('ftp_download_started', parameters: {
        'remotePath': remotePath,
        'localPath': localPath,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await _ftpConnect.downloadFile(
        remotePath,
        file,
      );

      final fileSize = await file.length();
      await _logger.info(
        'FTP file download completed',
        error: {
          'remotePath': remotePath,
          'localPath': localPath,
          'fileSize': fileSize,
        },
      );

      _analytics.logEvent('ftp_download_completed', parameters: {
        'remotePath': remotePath,
        'localPath': localPath,
        'fileSize': fileSize,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await disconnect();
      return true;
    } catch (e, stackTrace) {
      await _logger.error(
        'FTP download failed',
        error: e,
        stackTrace: stackTrace,
      );

      _analytics.logError(
        'FTP Download Failed',
        parameters: {
          'error': e.toString(),
          'remotePath': remotePath,
          'localPath': localPath,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      await disconnect();
      return false;
    }
  }

  Future<List<String>> listDirectory(String directory) async {
    try {
      if (!await connect()) return [];

      await _logger.info(
        'Listing FTP directory',
        error: {'directory': directory},
      );

      _analytics.logEvent('ftp_list_directory_started', parameters: {
        'directory': directory,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      final files = await _ftpConnect.listDirectoryContent();
      final fileNames = files.map((file) => file.toString()).toList();

      await _logger.info(
        'FTP directory listing completed',
        error: {
          'directory': directory,
          'fileCount': fileNames.length,
        },
      );

      _analytics.logEvent('ftp_list_directory_completed', parameters: {
        'directory': directory,
        'fileCount': fileNames.length,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await disconnect();
      return fileNames;
    } catch (e, stackTrace) {
      await _logger.error(
        'FTP list directory failed',
        error: e,
        stackTrace: stackTrace,
      );

      _analytics.logError(
        'FTP List Directory Failed',
        parameters: {
          'error': e.toString(),
          'directory': directory,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      await disconnect();
      return [];
    }
  }

  Future<bool> deleteFile(String remotePath) async {
    try {
      if (!await connect()) return false;

      await _logger.info(
        'Deleting FTP file',
        error: {'remotePath': remotePath},
      );

      _analytics.logEvent('ftp_delete_started', parameters: {
        'remotePath': remotePath,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await _ftpConnect.deleteFile(remotePath);

      await _logger.info(
        'FTP file deleted',
        error: {'remotePath': remotePath},
      );

      _analytics.logEvent('ftp_delete_completed', parameters: {
        'remotePath': remotePath,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await disconnect();
      return true;
    } catch (e, stackTrace) {
      await _logger.error(
        'FTP delete failed',
        error: e,
        stackTrace: stackTrace,
      );

      _analytics.logError(
        'FTP Delete Failed',
        parameters: {
          'error': e.toString(),
          'remotePath': remotePath,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      await disconnect();
      return false;
    }
  }

  Future<bool> createDirectory(String remotePath) async {
    try {
      if (!await connect()) return false;

      await _logger.info(
        'Creating FTP directory',
        error: {'remotePath': remotePath},
      );

      _analytics.logEvent('ftp_create_directory_started', parameters: {
        'remotePath': remotePath,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await _ftpConnect.makeDirectory(remotePath);

      await _logger.info(
        'FTP directory created',
        error: {'remotePath': remotePath},
      );

      _analytics.logEvent('ftp_create_directory_completed', parameters: {
        'remotePath': remotePath,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await disconnect();
      return true;
    } catch (e, stackTrace) {
      await _logger.error(
        'FTP create directory failed',
        error: e,
        stackTrace: stackTrace,
      );

      _analytics.logError(
        'FTP Create Directory Failed',
        parameters: {
          'error': e.toString(),
          'remotePath': remotePath,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      await disconnect();
      return false;
    }
  }

  Future<bool> checkConnection() async {
    try {
      _analytics.logEvent('ftp_check_connection_started', parameters: {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      final result = await connect();

      _analytics.logEvent('ftp_check_connection_completed', parameters: {
        'success': result,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      return result;
    } finally {
      await disconnect();
    }
  }
}