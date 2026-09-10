enum AppEnv {
  development,
  production;

  bool get isDevelopment => this == AppEnv.development;

  bool get isProduction => this == AppEnv.production;

  String get label => switch (this) {
        AppEnv.development => 'Development',
        AppEnv.production => 'Production',
      };
}
