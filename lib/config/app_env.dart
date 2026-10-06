class AppEnv {
  AppEnv._();

  static const bool isProduction = true;

  static bool get enableLogs => !isProduction;
  static bool get enableNetworkPayloadLogs => !isProduction;
}
