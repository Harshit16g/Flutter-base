import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/local_storage_service.dart';
import '../storage/secure_storage_service.dart';

@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @singleton
  InternetConnectionChecker get internetConnectionChecker => 
      InternetConnectionChecker();

  @singleton
  LocalStorageService get localStorage => 
      LocalStorageService(get<SharedPreferences>());

  @singleton
  SecureStorageService get secureStorageService => 
      SecureStorageService(get<FlutterSecureStorage>());
}
