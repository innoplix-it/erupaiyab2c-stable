class AppErrorMessages {
  AppErrorMessages._();

  static const String generic = 'Something went wrong. Please try again.';
  static const String timeout =
      'Network timeout. Please check your internet and try again.';
  static const String network =
      'Please check your internet connection.';
  static const String sessionExpired = 'Session Expired. Please login again.';
  static const String sessionRefreshFailed =
      'Session refresh failed. Please try again.';
  static const String secureConnection =
      'Secure connection failed. Please try again later.';
  static const String serverUnavailable =
      'Server unavailable. Please try again later.';
  static const String minAmount100 = 'Please add at least ₹100';
  static const String maxAmount100000 =
      'Maximum amount allowed is ₹1,00,000';
}
