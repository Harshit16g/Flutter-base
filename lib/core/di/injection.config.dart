// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:internet_connection_checker/internet_connection_checker.dart'
    as _i973;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/auth/data/datasources/auth_remote_datasource.dart'
    as _i161;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/login_usecase.dart' as _i188;
import '../../features/auth/domain/usecases/register_usecase.dart' as _i941;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../config/env_config.dart' as _i373;
import '../network/api_client.dart' as _i557;
import '../network/api_interceptor.dart' as _i724;
import '../network/network_info.dart' as _i932;
import '../storage/storage_service.dart' as _i865;
import '../utils/logger_service.dart' as _i146;
import 'register_module.dart' as _i291;

const String _dev = 'dev';
const String _prod = 'prod';

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final registerModule = _$RegisterModule();
  await gh.factoryAsync<_i460.SharedPreferences>(
    () => registerModule.prefs,
    preResolve: true,
  );
  gh.singleton<_i558.FlutterSecureStorage>(() => registerModule.secureStorage);
  gh.singleton<_i973.InternetConnectionChecker>(
      () => registerModule.internetConnectionChecker);
  gh.singleton<_i146.LoggerService>(() => _i146.LoggerService());
  gh.lazySingleton<_i557.ApiClient>(() => _i557.ApiClient());
  gh.factory<_i373.EnvConfig>(
    () => _i373.DevConfig(),
    registerFor: {_dev},
  );
  gh.factory<_i865.StorageService>(() => _i865.StorageServiceImpl(
        gh<_i558.FlutterSecureStorage>(),
        gh<_i460.SharedPreferences>(),
      ));
  gh.factory<_i161.IAuthRemoteDataSource>(
      () => _i161.AuthRemoteDataSource(gh<_i921.Apiclien>()));
  gh.factory<_i373.EnvConfig>(
    () => _i373.ProdConfig(),
    registerFor: {_prod},
  );
  gh.factory<_i932.NetworkInfo>(
      () => _i932.NetworkInfoImpl(gh<_i973.InternetConnectionChecker>()));
  gh.factory<_i724.ApiInterceptor>(
      () => _i724.ApiInterceptor(gh<_i865.StorageService>()));
  gh.factory<_i188.LoginUseCase>(
      () => _i188.LoginUseCase(gh<_i787.IAuthRepository>()));
  gh.factory<_i941.RegisterUseCase>(
      () => _i941.RegisterUseCase(gh<_i787.IAuthRepository>()));
  gh.factory<_i797.AuthBloc>(() => _i797.AuthBloc(
        gh<_i188.LoginUseCase>(),
        gh<_i941.RegisterUseCase>(),
      ));
  return getIt;
}

class _$RegisterModule extends _i291.RegisterModule {}

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
void configureDependencies() => init();

@module
abstract class AppModule {
  @singleton
  AuthRepository provideAuthRepository(
      LoggerService logger,
      // Add other dependencies
      ) {
    return AuthRepositoryImpl(logger); // Implement your concrete repository
  }

  @singleton
  AuthProvider provideAuthProvider(
      AuthRepository authRepository,
      LoggerService logger,
      ) {
    return AuthProvider(authRepository, logger);
  }
}