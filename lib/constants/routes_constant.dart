class RouteConstants {
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String temporaryBlockOtp = '/temporary-block/otp';
  static const String splash = '/splash';
  static const String home = '/';
  static const String homeSearchView = '/home-search';
  static const String otpSuccess = '/otp-success';
  static const String temporaryBlockIdentityCompletion =
      '/temporary-block/identity-completion';
  static const String addPin = '/add-pin';
  static const String languageSelection = '/language';
  static const String kycOverview = '/kyc';
  static const String panVerification = '/kyc/pan';
  static const String aadhaarVerification = '/kyc/aadhaar';
  static const String verificationResult = '/kyc/result';
  static const String kycVerification = '/kyc/verification';
  static const String billerListing = '/billers';
  static const String billerDetail = '/billers/detail';
  static const String educationFeesAmount = '/education-fees';
  static const String educationFeesRecipient = '/education-fees/recipient';
  static const String educationFeesPayment = '/education-fees/payment';
  static const String paymentProcessing = '/education-fees/payment-processing';
  static const String educationPaymentThankYou =
      '/education-fees/payment-thank-you';
  static const String paymentThankYou = '/payment-thank-you';
  static const String creditCardIntro = '/credit-card';
  static const String creditCardListing = '/credit-card/billers';
  static const String creditCardMyCards = '/credit-card/cards';
  static const String creditCardPay = '/credit-card/pay';
  static const String creditCardTransactions = '/credit-card/transactions';
  static const String creditCardTransactionDetail =
      '/credit-card/transactions/detail';
  static const String spinAndWin = '/spin-and-win';
  static const String mobilePrepaid = '/mobile-prepaid';
  static const String mobileRecentRecharges = '/mobile-prepaid/recent';
  static const String policies = '/policies';
  static const String refundPolicy = '/refund-policy';
  static const String grievance = '/grievance';
  static const String aboutUs = '/about-us';
  static const String aboutApp = '/about-app';
  static const String termsPrivacy = '/terms-privacy';
  static const String privacyPolicy = '/privacy-policy';
  static const String helpSupport = '/help-support';
  static const String helpCenterChat = '/help-center/chat';
  static const String faq = '/faq';
  static const String supportTickets = '/support/tickets';
  static const String supportTicketDetail = '/support/tickets/detail';
  static const String transactions = '/transactions';
  static const String transactionDetail = '/transactions/detail';
  static const String transactionDetailSuccess =
      '/transactions/detail/success';
  static const String transactionDetailFailed = '/transactions/detail/failed';
  static const String transactionDetailPending =
      '/transactions/detail/pending';
  static const String notifications = '/notifications';
  static const String myQr = '/my-qr';
  static const String quickActions = '/quick-actions';
  static const String offers = '/offers';
  static const String settings = '/settings';
  static const String preferences = '/preferences';
  static const String security = '/security';
  static const String profilePermissions = '/profile-permissions';
  static const String locationAccess = '/location-access';
  static const String biometricScreenLock = '/biometric-screen-lock';
  static const String referral = '/referral';
  static const String referAndEarn = '/refer-and-earn';
  static const String referAndEarnWallet = '/refer-and-earn/wallet';
  static const String digitalGold = '/digital-gold';
  static const String digitalGoldDetails = '/digital-gold/details';
  static const String digitalGoldSummary = '/digital-gold/summary';
  static const String digitalGoldSuccess = '/digital-gold/success';
  static const String digitalGoldSellConfirm = '/digital-gold/sell/confirm';
  static const String digitalGoldSellSuccess = '/digital-gold/sell/success';
  static const String digitalGoldLocker = '/digital-gold/locker';
  static const String digitalGoldAlerts = '/digital-gold/alerts';
  static const String digitalGoldSipSetup = '/digital-gold/sip/setup';
  static const String digitalGoldSipPortfolio = '/digital-gold/sip/portfolio';
  static const String digitalGoldSipSuccess = '/digital-gold/sip/success';

  static String transactionDetailForStatus(String paymentStatus) {
    final value = paymentStatus.trim().toUpperCase().replaceAll('-', '_');
    if (value.contains('REFUND')) {
      return transactionDetailFailed;
    }
    if (value.contains('FAIL')) {
      return transactionDetailFailed;
    }
    if (value == 'PROCESSING' || value.contains('PROCESS')) {
      return transactionDetailPending;
    }
    if (value == 'PENDING' || value.contains('PENDING')) {
      return transactionDetailPending;
    }
    return transactionDetailSuccess;
  }
}
