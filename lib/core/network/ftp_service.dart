import 'package:ftpconnect/ftpconnect.dart';
import '../config/app_config.dart';

class FtpService {
  late FTPConnect _ftpConnect;
  
  Future<void> connect() async {
    _ftpConnect = FTPConnect(
      AppConfig.ftpHost,
      user: 'your_username',
      pass: 'your_password',
      port: 21,
    );
    await _ftpConnect.connect();
  }

  Future<bool> uploadFile(String localPath, String remotePath) async {
    try {
      await connect();
      final file = File(localPath);
      await _ftpConnect.uploadFile(file, sRemoteName: remotePath);
      await _ftpConnect.disconnect();
      return true;
    } catch (e) {
      print('FTP Upload Error: $e');
      return false;
    }
  }

  Future<bool> downloadFile(String remotePath, String localPath) async {
    try {
      await connect();
      final file = File(localPath);
      await _ftpConnect.downloadFile(remotePath, file);
      await _ftpConnect.disconnect();
      return true;
    } catch (e) {
      print('FTP Download Error: $e');
      return false;
    }
  }

  Future<List<String>> listFiles(String directory) async {
    try {
      await connect();
      final files = await _ftpConnect.listDirectoryContent();
      await _ftpConnect.disconnect();
      return files.map((file) => file.name).toList();
    } catch (e) {
      print('FTP List Error: $e');
      return [];
    }
  }
}
