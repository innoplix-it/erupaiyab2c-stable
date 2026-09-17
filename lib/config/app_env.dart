class AppEnv {
  AppEnv._();

  static const bool isProduction = false;

  static bool get enableLogs => !isProduction;
  static bool get enableNetworkPayloadLogs => !isProduction;
}
