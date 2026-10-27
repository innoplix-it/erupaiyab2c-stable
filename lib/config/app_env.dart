class AppEnv {
  AppEnv._();

  static const bool isProduction = false;

  static const bool isDeveloperModeCheckEnabled = false;

  static const bool enableScreenshotProtection = true;

  static bool get enableLogs => !isProduction;
  static bool get enableNetworkPayloadLogs => !isProduction;
}
