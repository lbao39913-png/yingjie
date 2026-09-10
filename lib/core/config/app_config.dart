import 'env.dart';
export 'env.dart';

/// App-level constants. Switch environment here, not in UI code.
class AppConfig {
  AppConfig._();

  static const String appName = '影界';
  static const String packageName = 'com.yingjie.yingjie';
  static const String versionName = '1.0.0';
  static const int versionCode = 1;

  /// Change this single value to switch Development / Production.
  static const AppEnv env = AppEnv.development;

  static bool get useMockApi => env.isDevelopment;
}
