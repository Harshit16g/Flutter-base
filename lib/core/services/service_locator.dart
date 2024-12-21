import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/local_storage_service.dart';
import '../network/api_service.dart';
import '../network/ftp_service.dart';
import 'firebase_service.dart';
import 'analytics_service.dart';

final GetIt locator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Singletons
  final sharedPrefs = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(sharedPrefs);
  
  // Services
  locator.registerLazySingleton<LocalStorageService>(() => LocalStorageService());
  locator.registerLazySingleton<ApiService>(() => ApiService());
  locator.registerLazySingleton<FtpService>(() => FtpService());
  locator.registerLazySingleton<FirebaseService>(() => FirebaseService());
  locator.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
}
