class AppEnv {
  AppEnv._();

  static const bool isProduction = false;


  ///
  /// true  -> the app checks Android Developer Options at startup/resume
  ///          and blocks all normal app access while they are enabled.
  /// false -> the developer-mode protection flow is completely bypassed.
  static const bool isDeveloperModeCheckEnabled = false;

  static bool get enableLogs => !isProduction;
  static bool get enableNetworkPayloadLogs => !isProduction;
}
