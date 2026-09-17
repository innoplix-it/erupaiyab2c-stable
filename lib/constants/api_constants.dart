class ApiConstants {
  static const String baseUrl = 'https://test.erupaiya.com';

  static const String loginEndpoint = '$baseUrl/api/auth/login';
  static const String checkLoginEndpoint = '$baseUrl/api/auth/check-login';
  static const String verifyOtpEndpoint = '$baseUrl/api/auth/verify-otp';
  static const String sendDeviceOtpEndpoint =
      '$baseUrl/api/auth/send-device-otp';
  static const String verifyDeviceOtpEndpoint =
      '$baseUrl/api/auth/verify-device-otp';
  static const String refreshTokenEndpoint = '$baseUrl/api/auth/refresh';
  static const String registerEndpoint = '$baseUrl/api/auth/register';
  static const String setPinEndpoint = '$baseUrl/api/auth/set-pin';
  static const String requestForgotPinOtpEndpoint =
      '$baseUrl/api/auth/request-forgot-pin-otp';
  static const String forgotPinEndpoint = '$baseUrl/api/auth/forgot-pin';
  static const String accountRecoverySendOtpEndpoint =
      '$baseUrl/api/account-recovery/send-otp';
  static const String accountRecoveryVerifyOtpEndpoint =
      '$baseUrl/api/account-recovery/verify-otp';
  static const String accountRecoveryVerifyKycEndpoint =
      '$baseUrl/api/account-recovery/verify-kyc';
  static const String pinLockEndpoint = '$baseUrl/api/auth/pin-lock';
  static const String shareDownloadReceiptEndpoint =
      '$baseUrl/api/bill/share-download-receipt';
  static const String quickActionsEndpoint = '$baseUrl/api/quick-actions';
  static const String quickActionsDueEndpoint =
      '$baseUrl/api/quick-actions/due';
  static const String billRemindersEndpoint = '$baseUrl/api/bill-reminders';
  static const String myCardsEndpoint = '$baseUrl/api/my-cards';
  static const String removeCardEndpoint = '$baseUrl/api/remove-card';
  static const String creditCardTransactionsEndpoint =
      '$baseUrl/api/credit-card-transactions';
  static const String profileEndpoint = '$baseUrl/api/user/profile';
  static const String profileUpdateEndpoint =
      '$baseUrl/api/user/profile/update';
  static const String completeProfileEndpoint =
      '$baseUrl/api/user/complete-profile';
  static const String completeProfileVerifyOtpEndpoint =
      '$baseUrl/api/user/verify-otp';
  static const String profileUpdateDeliveryInfoEndpoint =
      '$baseUrl/api/user/profile/update-delivery-info';
  static const String profileUpdateDeviceTokenEndpoint =
      '$baseUrl/api/user/profile/update-device-token';
  static const String profileVerifyContactUpdateEndpoint =
      '$baseUrl/api/user/profile/verify-contact-update';
  static const String educationValidateAmountEndpoint =
      '$baseUrl/api/education/validate-amount';
  static const String educationCheckMobileEndpoint =
      '$baseUrl/api/education/check-mobile';
  static const String educationVerifyPanEndpoint =
      '$baseUrl/api/education/verify-pan';
  static const String educationVerifyBankEndpoint =
      '$baseUrl/api/education/verify-bank';
  static const String educationCardListEndpoint =
      '$baseUrl/api/education/card/list';
  static const String educationBeneficiariesEndpoint =
      '$baseUrl/api/education/get-beneficiaries';
  static const String educationPaymentSummaryEndpoint =
      '$baseUrl/api/education/payment-summary';
  static const String educationCreateOrderEndpoint =
      '$baseUrl/api/education/create-order';
  static const String educationSaveBeneficiaryEndpoint =
      '$baseUrl/api/education/save-beneficiary';
  static String educationStatusEndpoint(String transactionRefId) =>
      '$baseUrl/api/education/status/$transactionRefId';
  static const String logoutEndpoint = '$baseUrl/api/auth/logout';
  static const String billersEndpoint = '$baseUrl/api/billers';
  static const String billerDetailsEndpoint = '$baseUrl/api/biller/details';
  static const String billerParamsEndpoint = '$baseUrl/api/biller/params';
  static const String billerIconBaseUrl = '$baseUrl/storage/billers';
  static const String offersBannerBaseUrl = '$baseUrl/storage/offers';
  static const String fetchBillEndpoint = '$baseUrl/api/bill/fetch';
  // static const String payBillEndpoint = '$baseUrl/api/bill/pay';
  static const String payBillAllServicesEndpoint =
      '$baseUrl/api/bill/create-order';
  static const String prepaidCheckOperatorEndpoint =
      '$baseUrl/api/prepaid/checkOprators';
  static const String prepaidFetchOperatorsEndpoint =
      '$baseUrl/api/prepaid/fetchOprators';
  static const String prepaidFetchRegionsEndpoint =
      '$baseUrl/api/prepaid/getAllRegions';
  static const String prepaidFetchPlansEndpoint =
      '$baseUrl/api/prepaid/fetchPlans';
  static const String prepaidRechargeEndpoint = '$baseUrl/api/prepaid/recharge';
  static const String rechargeCreateOrderEndpoint =
      '$baseUrl/api/recharge/create-order';
  static const String rechargeMyNumberEndpoint =
      '$baseUrl/api/recharge/my-number';
  static const String prepaidTransactionHistoryEndpoint =
      '$baseUrl/api/prepaid/transaction-history';
  static String transactionStatusEndpoint(String transactionId) =>
      '$baseUrl/api/transaction/status/$transactionId';
  static String rechargeStatusEndpoint(String transactionId) =>
      '$baseUrl/api/recharge/status/$transactionId';
  static const String ratingSubmitEndpoint = '$baseUrl/api/rating/submit';
  static const String spinEndpoint = '$baseUrl/api/spin';
  static const String spinOptionsEndpoint = '$baseUrl/api/spin/options';
  static const String offersEndpoint = '$baseUrl/api/offers';
  static const String notificationsEndpoint = '$baseUrl/api/notifications';
  static const String notificationRemindMeLaterEndpoint =
      '$baseUrl/api/notification/remind-me-later';
  static const String pushNotificationToggleEndpoint =
      '$baseUrl/api/user/push-notification-enable-disable';
  static const String sendDeleteAccountOtpEndpoint =
      '$baseUrl/api/user/send-delete-account-otp';
  static const String verifyDeleteAccountOtpEndpoint =
      '$baseUrl/api/user/verify-delete-account-otp';
  static const String referralGenerateLinkEndpoint =
      '$baseUrl/api/referral/generate-link';
  static const String referralRegisterEndpoint =
      '$baseUrl/api/referral/register';
  static const String referralTrackEndpoint = '$baseUrl/api/referral/track';
  static const String referralWalletSummaryEndpoint =
      '$baseUrl/api/wallet/summary';
  static const String digitalGoldProceedEndpoint =
      '$baseUrl/api/digital-gold/proceed';
  static const String digitalGoldCustomerCreateEndpoint =
      '$baseUrl/api/digital-gold/customer/create';
  static const String digitalGoldSendOtpEndpoint =
      '$baseUrl/api/digital-gold/send-otp';
  static const String digitalGoldBuyEndpoint = '$baseUrl/api/digital-gold/buy';
  static const String digitalGoldRecentPurchasesEndpoint =
      '$baseUrl/api/digital-gold/recent-purchases';
  static const String digitalGoldDashboardEndpoint =
      '$baseUrl/api/digital-gold/dashboard';
  static const String digitalGoldSummaryEndpoint =
      '$baseUrl/api/digital-gold/summary';
  static const String referralMilestonesEndpoint =
      '$baseUrl/api/referral/milestones';
  static const String withdrawEcoinsEndpoint =
      '$baseUrl/api/wallet/ecoins-withdraw-amount';
  static const String bankVerifyEndpoint = '$baseUrl/api/bank/verify';
  static const String bankListEndpoint = '$baseUrl/api/banks';
  static const String bankAddEndpoint = '$baseUrl/api/bank/add';
  static const String bankEditEndpoint = '$baseUrl/api/bank/update';
  static const String bankDeleteEndpoint = '$baseUrl/api/bank/delete';
  static const String bankAccountsEndpoint = '$baseUrl/api/bank/accounts';
  static const String kycPanVerifyEndpoint = '$baseUrl/api/kyc/pan/verify';
  static const String kycAadhaarSendOtpEndpoint =
      '$baseUrl/api/kyc/aadhaar/send-otp';
  static const String kycAadhaarVerifyOtpEndpoint =
      '$baseUrl/api/kyc/aadhaar/verify-otp';
  static String notificationReadEndpoint(String id) =>
      '$baseUrl/api/notification/read/$id';

  static String pageEndpoint(String slug) => '$baseUrl/api/pages/$slug';

  static const String supportLatestTransactionsEndpoint =
      '$baseUrl/api/support/tickets/latest-transactions';

  static String latestTransactionsEndpoint({required String service}) =>
      '$baseUrl/api/latest-transactions?service=${Uri.encodeQueryComponent(service)}';

  static const String faqsEndpoint = '$baseUrl/api/faqs';

  static const String supportCreateTicketEndpoint =
      '$baseUrl/api/support/ticket/create';

  static const String supportTicketsEndpoint = '$baseUrl/api/support/tickets';

  static String supportTicketDetailsEndpoint(String id) =>
      '$baseUrl/api/support/ticket/details/$id';

  static const String supportTicketReplyEndpoint =
      '$baseUrl/api/support/ticket/reply';

  static const String supportTicketCloseEndpoint =
      '$baseUrl/api/support/ticket/close';

  static String supportTicketReopenEndpoint(String id) =>
      '$baseUrl/api/support/ticket/reopen/$id';
}
