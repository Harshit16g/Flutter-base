// lib/core/di/config_module.dart

import 'package:injectable/injectable.dart';
import '../config/env_config.dart';

@module
abstract class ConfigModule {
  @prod
  @Injectable(as: EnvConfig)
  ProdConfig get prodConfig => ProdConfig();

  @dev
  @Injectable(as: EnvConfig)
  DevConfig get devConfig => DevConfig();

  @Environment('staging')
  @Injectable(as: EnvConfig)
  StagingConfig get stagingConfig => StagingConfig();
}
