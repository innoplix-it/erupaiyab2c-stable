class AppEnv {
  AppEnv._();

  static const bool isProduction = true;

  static const bool isDeveloperModeCheckEnabled = true;

  static const bool enableScreenshotProtection = true;

  static bool get enableLogs => !isProduction;
  static bool get enableNetworkPayloadLogs => !isProduction;
}
