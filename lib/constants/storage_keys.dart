class StorageKeys {
  static const String pendingReferralCode = 'pendingReferralCode';
  static const String deviceToken = 'deviceToken';
  static const String locationAccessEnabled = 'locationAccessEnabled';
  static const String themeMode = 'themeMode';
  static const String tempAccessToken = 'tempAccessToken';
  static const String guestInstallationId = 'guestInstallationId';
  static const String guestDeviceRegistered = 'guestDeviceRegistered';
  static const String guestRegisteredFcmToken = 'guestRegisteredFcmToken';

  /// JSON list of tutor-request refs awaiting Received popup after background
  /// FCM verification. Contains only request_reference + display fields.
  static const String pendingTutorRequestPopups = 'pendingTutorRequestPopups';
}
