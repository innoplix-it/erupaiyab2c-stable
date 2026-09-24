import 'package:e_rupaiya/features/home/views/home_search_view.dart';
import 'package:e_rupaiya/widgets/processing_overlay.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'config/temporary_block_debug_config.dart';
import 'constants/routes_constant.dart';
import 'core/barrel_file.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/models/auth_state.dart';
import 'features/auth/models/otp_verification_args.dart';
import 'features/auth/views/login_view.dart';
import 'features/auth/views/otp_success_view.dart';
import 'features/auth/views/otp_verification_view.dart';
import 'features/auth/views/pin_setup_view.dart';
import 'features/auth/views/splash_view.dart';
import 'features/auth/views/temporary_block_identity_completion_view.dart';
import 'features/digital_gold/models/digital_gold_preview.dart';
import 'features/digital_gold/models/digital_gold_purchase_receipt.dart';
import 'features/digital_gold/models/digital_metal.dart';
import 'features/digital_gold/sip/views/sip_portfolio_view.dart';
import 'features/digital_gold/sip/views/sip_setup_view.dart';
import 'features/digital_gold/sip/views/sip_success_view.dart';
import 'features/digital_gold/views/digital_gold_details_view.dart';
import 'features/digital_gold/views/digital_gold_locker_view.dart';
import 'features/digital_gold/views/digital_gold_sell_confirm_view.dart';
import 'features/digital_gold/views/digital_gold_sell_success_view.dart';
import 'features/digital_gold/views/digital_gold_success_v2_view.dart';
import 'features/digital_gold/views/digital_gold_success_view.dart';
import 'features/digital_gold/views/digital_gold_summary_view.dart';
import 'features/digital_gold/views/digital_gold_view.dart';
import 'features/educationFees/views/education_fees_amount_view.dart';
import 'features/educationFees/views/education_fees_payment_view.dart';
import 'features/educationFees/views/education_fees_recipient_view.dart';
import 'features/educationFees/views/education_payment_thank_you_view.dart';
import 'features/home/views/home_view.dart';
import 'features/home/views/notifications_screen.dart';
import 'features/home/views/quick_actions_view.dart';
import 'features/kyc/views/kyc_verification_view.dart';
import 'features/mobile_prepaid/models/recharge_quick_action_payload.dart';
import 'features/mobile_prepaid/views/mobile_prepaid_view.dart';
import 'features/mobile_prepaid/views/mobile_recent_recharges_view.dart';
import 'features/onboarding/views/aadhaar_verification_view.dart';
import 'features/onboarding/views/kyc_overview_view.dart';
import 'features/onboarding/views/language_selection_view.dart';
import 'features/onboarding/views/pan_verification_view.dart';
import 'features/onboarding/views/verification_result_view.dart';
import 'features/profile/constants/policy_page_slugs.dart';
import 'features/profile/models/transaction_history_entry.dart';
import 'features/profile/views/about_app_screen.dart';
import 'features/profile/views/about_us_screen.dart';
import 'features/profile/views/faq_screen.dart';
import 'features/profile/views/help_center_chat_screen.dart';
import 'features/profile/views/help_support_screen.dart';
import 'features/profile/views/my_qr_screen.dart';
import 'features/profile/views/offers_view.dart';
import 'features/profile/views/policies_screen.dart';
import 'features/profile/views/policy_page_screen.dart';
import 'features/profile/views/preferences_security_views.dart';
import 'features/profile/views/settings_view.dart';
import 'features/profile/views/support_ticket_detail_screen.dart';
import 'features/profile/views/support_tickets_screen.dart';
import 'features/profile/views/transaction_detail_screen.dart';
import 'features/profile/views/transaction_history_screen.dart';
import 'features/refer_and_earn/views/refer_and_earn_view.dart';
import 'features/refer_and_earn/views/refer_and_earn_wallet_view.dart';
import 'features/refer_and_earn/views/referral_deeplink_view.dart';
import 'features/services/models/biller_detail_args.dart';
import 'features/services/models/biller_model.dart';
import 'features/services/models/credit_card_transaction.dart';
import 'features/services/views/biller_detail_view.dart';
import 'features/services/views/biller_listing_view.dart';
import 'features/services/views/credit_card_intro_view.dart';
import 'features/services/views/credit_card_listing_view.dart';
import 'features/services/views/credit_card_my_cards_view.dart';
import 'features/services/views/credit_card_pay_deeplink_view.dart';
import 'features/services/views/credit_card_transaction_detail_screen.dart';
import 'features/services/views/credit_card_transactions_screen.dart';
import 'features/spinandear/views/spin_and_win_view.dart';
import 'services/logger_service.dart';
import 'services/navigation_interaction_lock.dart';
import 'widgets/k_dialog.dart';
import 'widgets/payment_success_flow.dart';

final routerProvider = Provider<GoRouter>(
  (ref) {
    final navigationInteractionLock =
        ref.watch(navigationInteractionLockProvider);
    final router = GoRouter(
      navigatorKey: navigatorKey,
      observers: [navigationInteractionLock],
      initialLocation: RouteConstants.splash,
      redirect: (context, state) {
        logger.info('Redirecting to ${state.matchedLocation}');
        final authState = ref.read(authControllerProvider);
        final location = state.matchedLocation;

        // Always let the in-app splash render on cold start/reopen.
        // SplashView itself decides whether to continue to Home or Login
        // after the lottie animation and auth check finish.
        if (location == RouteConstants.splash) return null;

        // While still checking stored tokens, don't redirect.
        if (authState.isLoading) return null;

        final isAuthenticated = authState.isAuthenticated;
        final hasTemporaryAccess = authState.hasTemporaryAccess;

        // Auth screens that unauthenticated users may visit.
        const authRoutes = [
          RouteConstants.login,
          RouteConstants.register,
          RouteConstants.otp,
          RouteConstants.temporaryBlockOtp,
          RouteConstants.otpSuccess,
          RouteConstants.addPin,
        ];
        final isOnAuthRoute = authRoutes.contains(location);
        final isReferralRoute = location.startsWith(RouteConstants.referral);
        const temporaryAccessRoutes = [
          RouteConstants.login,
          RouteConstants.temporaryBlockOtp,
          RouteConstants.temporaryBlockIdentityCompletion,
          RouteConstants.kycVerification,
          RouteConstants.helpSupport,
          RouteConstants.helpCenterChat,
          RouteConstants.supportTickets,
          RouteConstants.supportTicketDetail,
        ];
        final isOnTemporaryAccessRoute =
            temporaryAccessRoutes.contains(location);

        // If authenticated and on an auth screen → send to home.
        if (isAuthenticated && isOnAuthRoute) {
          return RouteConstants.home;
        }

        if (!isAuthenticated && hasTemporaryAccess) {
          if (isOnTemporaryAccessRoute || isOnAuthRoute || isReferralRoute) {
            return null;
          }
          return RouteConstants.login;
        }

        // If not authenticated and on a protected screen → send to login.
        if (!isAuthenticated && !isOnAuthRoute && !isReferralRoute) {
          return RouteConstants.login;
        }

        return null;
      },
      routes: <GoRoute>[
        GoRoute(
          path: RouteConstants.splash,
          builder: (context, state) => SplashView(key: state.pageKey),
        ),
        GoRoute(
          path: RouteConstants.home,
          builder: (context, state) => const HomeView(),
        ),
        GoRoute(
          path: RouteConstants.homeSearchView,
          builder: (context, state) => const HomeSearchView(),
        ),
        GoRoute(
          path: RouteConstants.login,
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: RouteConstants.register,
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: RouteConstants.otp,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is OtpVerificationArgs) {
              return OtpVerificationView(args: extra);
            }
            return OtpVerificationView(
              args: OtpVerificationArgs(phoneNumber: extra as String?),
            );
          },
        ),
        GoRoute(
          path: RouteConstants.temporaryBlockOtp,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is OtpVerificationArgs) {
              return OtpVerificationView(args: extra);
            }
            final flow = state.uri.queryParameters['flow'];
            final phone = state.uri.queryParameters['phone'];
            if (flow != null && flow.isNotEmpty) {
              final flowType = switch (flow) {
                'noKyc' => TemporaryBlockFlowType.noKyc,
                'deviceVerification' =>
                  TemporaryBlockFlowType.deviceVerification,
                _ => TemporaryBlockFlowType.kycVerified,
              };
              final successRoute = flowType == TemporaryBlockFlowType.noKyc
                  ? RouteConstants.kycVerification
                  : (flowType == TemporaryBlockFlowType.deviceVerification
                      ? RouteConstants.login
                      : RouteConstants.temporaryBlockIdentityCompletion);
              return OtpVerificationView(
                args: OtpVerificationArgs(
                  phoneNumber: phone,
                  title: 'Verify Your Identity',
                  heading: 'Verify Your Identity',
                  description:
                      'Enter the OTPs sent to your registered mobile number and email address to verify your identity.',
                  primaryButtonLabel: 'Verify & Continue',
                  successDialogTitle:
                      flowType == TemporaryBlockFlowType.deviceVerification
                          ? 'Device Verified'
                          : 'Mobile and Email verified successfully',
                  successDialogMessage:
                      'This device has been successfully verified and added to your trusted devices. You can now access your account securely.',
                  successButtonLabel:
                      flowType == TemporaryBlockFlowType.deviceVerification
                          ? 'Continue to Login'
                          : 'Complete KYC',
                  successRoute: successRoute,
                  successRouteExtra:
                      successRoute == RouteConstants.kycVerification
                          ? false
                          : null,
                  successRouteUseGo:
                      flowType == TemporaryBlockFlowType.deviceVerification,
                  clearTemporaryAccessOnSuccess: false,
                  deviceVerificationId:
                      state.uri.queryParameters['verification_id'],
                  temporaryBlockFlowType: flowType,
                ),
              );
            }
            return OtpVerificationView(
              args: OtpVerificationArgs(phoneNumber: extra as String?),
            );
          },
        ),
        GoRoute(
          path: RouteConstants.otpSuccess,
          builder: (context, state) => const OtpSuccessView(),
        ),
        GoRoute(
          path: RouteConstants.temporaryBlockIdentityCompletion,
          builder: (context, state) =>
              const TemporaryBlockIdentityCompletionView(),
        ),
        GoRoute(
          path: RouteConstants.addPin,
          builder: (context, state) => const PinSetupView(),
        ),
        GoRoute(
          path: RouteConstants.languageSelection,
          builder: (context, state) => const LanguageSelectionView(),
        ),
        GoRoute(
          path: RouteConstants.kycOverview,
          builder: (context, state) => KycOverviewView(
            selectedLanguage: state.extra as String?,
          ),
        ),
        GoRoute(
          path: RouteConstants.kycVerification,
          builder: (context, state) => KycVerificationView(
            startFromAadhaar: state.extra is bool ? state.extra as bool : false,
          ),
        ),
        GoRoute(
          path: RouteConstants.panVerification,
          builder: (context, state) => const PanVerificationView(),
        ),
        GoRoute(
          path: RouteConstants.aadhaarVerification,
          builder: (context, state) => const AadhaarVerificationView(),
        ),
        GoRoute(
          path: RouteConstants.verificationResult,
          builder: (context, state) => VerificationResultView(
            isSuccess: state.extra as bool? ?? false,
          ),
        ),
        GoRoute(
          path: RouteConstants.billerListing,
          builder: (context, state) => BillerListingView(
            categoryName: state.extra as String? ?? '',
          ),
        ),
        GoRoute(
          path: RouteConstants.billerDetail,
          builder: (context, state) {
            final extra = state.extra;
            BillerDetailArgs? args;
            if (extra is BillerDetailArgs) {
              args = extra;
            } else if (extra is Biller) {
              args = BillerDetailArgs(
                biller: extra,
                isCreditCard: false,
                paymentType: null,
              );
            }
            return BillerDetailView(args: args);
          },
        ),
        GoRoute(
          path: RouteConstants.educationFeesAmount,
          builder: (context, state) => EducationFeesAmountView(
            feeType: state.extra as String?,
          ),
        ),
        GoRoute(
          path: RouteConstants.educationFeesRecipient,
          builder: (context, state) => const EducationFeesRecipientView(),
        ),
        GoRoute(
          path: RouteConstants.educationFeesPayment,
          builder: (context, state) => const EducationFeesPaymentView(),
        ),
        GoRoute(
          path: RouteConstants.paymentProcessing,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage<void>(
              key: state.pageKey,
              opaque: true,
              barrierDismissible: false,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) => child,
              child: PaymentProcessingOverlay(
                transactionRefId: extra['transactionRefId'] as String? ?? '',
                paymentType:
                    extra['paymentType'] as String? ?? 'Education Fees',
                recipientName: extra['recipientName'] as String? ?? '',
                maskedAccount: extra['maskedAccount'] as String? ?? '',
                fallbackAmount: extra['fallbackAmount'] as String? ?? '',
                paymentId: extra['paymentId'] as String? ?? '',
              ),
            );
          },
        ),
        GoRoute(
          path: RouteConstants.educationPaymentThankYou,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return EducationPaymentThankYouView(
              amount: extra['amount'] as String? ?? '',
              payableAmount: extra['payableAmount'] as String? ?? '',
              transactionTime: extra['transactionTime'] as String? ?? '',
              bannerImage: extra['bannerImage'] as String? ?? '',
              paymentType: extra['paymentType'] as String? ?? '',
            );
          },
        ),
        GoRoute(
          path: RouteConstants.paymentThankYou,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? const {};
            final entry = extra['entry'] as TransactionHistoryEntry?;
            return PaymentThankYouScreen(
              title: (extra['title'] as String?) ?? 'Thank You',
              subtitle: (extra['subtitle'] as String?) ?? '',
              highlightedSubtitleText:
                  extra['highlightedSubtitleText'] as String?,
              autoNavigateAfter: const Duration(seconds: 2),
              onAutoNavigate: (screenContext) {
                if (entry == null) {
                  screenContext.go(RouteConstants.home);
                  return;
                }
                screenContext.pushReplacement(
                  RouteConstants.transactionDetailForStatus(
                    entry.paymentStatus,
                  ),
                  extra: entry,
                );
              },
            );
          },
        ),
        GoRoute(
          path: RouteConstants.creditCardIntro,
          builder: (context, state) => const CreditCardIntroView(),
        ),
        GoRoute(
          path: RouteConstants.creditCardListing,
          builder: (context, state) => const CreditCardListingView(),
        ),
        GoRoute(
          path: RouteConstants.creditCardMyCards,
          builder: (context, state) => const CreditCardMyCardsView(),
        ),
        GoRoute(
          path: RouteConstants.creditCardPay,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? const {};
            String read(String key) => (extra[key] ?? '').toString();
            double? readDouble(String key) {
              final raw = extra[key];
              if (raw is num) return raw.toDouble();
              return double.tryParse((raw ?? '').toString());
            }

            return CreditCardPayDeeplinkView(
              billerName: read('biller_name'),
              maskedIdentifier: read('masked_identifier'),
              customerMobile: read('customer_mobile'),
              amount: readDouble('amount'),
              iconUrl: read('icon'),
            );
          },
        ),
        GoRoute(
          path: RouteConstants.creditCardTransactions,
          builder: (context, state) => CreditCardTransactionsScreen(
            maskedIdentifier: state.extra as String? ?? '',
          ),
        ),
        GoRoute(
          path: RouteConstants.creditCardTransactionDetail,
          builder: (context, state) => CreditCardTransactionDetailScreen(
            transaction: state.extra as CreditCardTransaction?,
          ),
        ),
        GoRoute(
          path: RouteConstants.spinAndWin,
          builder: (context, state) => const SpinAndWinView(),
        ),
        GoRoute(
          path: RouteConstants.mobileRecentRecharges,
          builder: (context, state) => const MobileRecentRechargesView(),
        ),
        GoRoute(
          path: RouteConstants.mobilePrepaid,
          builder: (context, state) => MobilePrepaidView(
            quickAction: state.extra as RechargeQuickActionPayload?,
          ),
        ),
        GoRoute(
          path: RouteConstants.policies,
          builder: (context, state) => const PoliciesScreen(),
        ),
        GoRoute(
          path: RouteConstants.refundPolicy,
          builder: (context, state) => const PolicyPageScreen(
            slug: PolicyPageSlugs.refundPolicy,
            title: 'Refund Policy',
          ),
        ),
        GoRoute(
          path: RouteConstants.grievance,
          builder: (context, state) => const PolicyPageScreen(
            slug: PolicyPageSlugs.grievance,
            title: 'Grievance',
          ),
        ),
        GoRoute(
          path: RouteConstants.aboutUs,
          builder: (context, state) => const AboutUsScreen(),
        ),
        GoRoute(
          path: RouteConstants.aboutApp,
          builder: (context, state) => const AboutAppScreen(),
        ),
        GoRoute(
          path: RouteConstants.termsPrivacy,
          builder: (context, state) => const PolicyPageScreen(
            slug: PolicyPageSlugs.termsAndConditions,
            title: 'Terms & Conditions',
            showEnglishOnlyChip: true,
          ),
        ),
        GoRoute(
          path: RouteConstants.privacyPolicy,
          builder: (context, state) => const PolicyPageScreen(
            slug: PolicyPageSlugs.privacyPolicy,
            title: 'Privacy Policy',
          ),
        ),
        GoRoute(
          path: RouteConstants.helpSupport,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
            child: const HelpSupportScreen(),
          ),
        ),
        GoRoute(
          path: RouteConstants.helpCenterChat,
          builder: (context, state) => const HelpCenterChatScreen(),
        ),
        GoRoute(
          path: RouteConstants.faq,
          builder: (context, state) => const FaqScreen(),
        ),
        GoRoute(
          path: RouteConstants.supportTickets,
          builder: (context, state) => const SupportTicketsScreen(),
        ),
        GoRoute(
          path: RouteConstants.supportTicketDetail,
          builder: (context, state) => SupportTicketDetailScreen(
            ticketId: state.extra as String? ?? '',
          ),
        ),
        GoRoute(
          path: RouteConstants.transactions,
          builder: (context, state) => const TransactionHistoryScreen(),
        ),
        GoRoute(
          path: RouteConstants.transactionDetailSuccess,
          builder: (context, state) => _transactionDetailFromState(context, state),
        ),
        GoRoute(
          path: RouteConstants.transactionDetailFailed,
          builder: (context, state) => _transactionDetailFromState(context, state),
        ),
        GoRoute(
          path: RouteConstants.transactionDetailPending,
          builder: (context, state) => _transactionDetailFromState(context, state),
        ),
        GoRoute(
          path: RouteConstants.transactionDetail,
          builder: (context, state) => _transactionDetailFromState(context, state),
        ),
        GoRoute(
          path: RouteConstants.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: RouteConstants.myQr,
          builder: (context, state) => const MyQrScreen(),
        ),
        GoRoute(
          path: RouteConstants.quickActions,
          builder: (context, state) => const QuickActionsView(),
        ),
        GoRoute(
          path: RouteConstants.offers,
          builder: (context, state) => const OffersView(),
        ),
        GoRoute(
          path: RouteConstants.settings,
          builder: (context, state) => const SettingsView(),
        ),
        GoRoute(
          path: RouteConstants.preferences,
          builder: (context, state) => const PreferencesView(),
        ),
        GoRoute(
          path: RouteConstants.security,
          builder: (context, state) => const SecurityView(),
        ),
        GoRoute(
          path: RouteConstants.profilePermissions,
          builder: (context, state) => const PermissionsView(),
        ),
        GoRoute(
          path: RouteConstants.locationAccess,
          builder: (context, state) => const LocationAccessView(),
        ),
        GoRoute(
          path: RouteConstants.biometricScreenLock,
          builder: (context, state) => const BiometricScreenLockView(),
        ),
        GoRoute(
          path: RouteConstants.referAndEarn,
          builder: (context, state) => const ReferAndEarnView(),
        ),
        GoRoute(
          path: RouteConstants.referAndEarnWallet,
          builder: (context, state) => const ReferAndEarnWalletView(),
        ),
        GoRoute(
          path: RouteConstants.digitalGold,
          builder: (context, state) {
            final mode = state.uri.queryParameters['mode'] == 'sell'
                ? GoldTradeMode.sell
                : GoldTradeMode.buy;
            final metal =
                DigitalMetalTheme.fromQuery(state.uri.queryParameters['metal']);
            final validateRegistration =
                state.uri.queryParameters['entry'] == 'home';
            final useLegacyDashboard =
                state.uri.queryParameters['legacy'] == '1';
            return DigitalGoldView(
              mode: mode,
              metal: metal,
              validateRegistration: validateRegistration,
              useLegacyDashboard: useLegacyDashboard,
            );
          },
        ),
        GoRoute(
          path: RouteConstants.digitalGoldDetails,
          builder: (context, state) {
            final metal =
                DigitalMetalTheme.fromQuery(state.uri.queryParameters['metal']);
            final extra = state.extra as Map<String, dynamic>?;
            return DigitalGoldDetailsView(
              amount: extra?['amount'] as int? ?? 0,
              metal: metal,
              preview: extra?['preview'] as DigitalGoldPreview?,
              redirectToGoldOnSuccess:
                  state.uri.queryParameters['postRegToGold'] == '1',
            );
          },
        ),
        GoRoute(
          path: RouteConstants.digitalGoldSummary,
          builder: (context, state) {
            final metal =
                DigitalMetalTheme.fromQuery(state.uri.queryParameters['metal']);
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return DigitalGoldSummaryView(
              amount: (extra['amount'] as num? ?? 0).toDouble(),
              metal: metal,
              isBuyingInRupees: extra['isBuyingInRupees'] as bool? ?? true,
              preview: extra['preview'] as DigitalGoldPreview? ??
                  const DigitalGoldPreview(
                    kycStatus: true,
                    isUserRegistered: true,
                    myGoldBalance: 0,
                    taxAmt1: 0,
                    taxAmt2: 0,
                    preTaxAmount: 0,
                    totalAmount: 0,
                  ),
            );
          },
        ),
        GoRoute(
          path: RouteConstants.digitalGoldSuccess,
          builder: (context, state) {
            final metal =
                DigitalMetalTheme.fromQuery(state.uri.queryParameters['metal']);
            final useLegacy = state.uri.queryParameters['legacy'] == '1';
            return useLegacy
                ? DigitalGoldSuccessView(metal: metal)
                : DigitalGoldSuccessV2View(metal: metal);
          },
        ),
        GoRoute(
          path: RouteConstants.digitalGoldSellConfirm,
          builder: (context, state) {
            final metal =
                DigitalMetalTheme.fromQuery(state.uri.queryParameters['metal']);
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return DigitalGoldSellConfirmView(
              amount: (extra['amount'] as num? ?? 0).toDouble(),
              preview: extra['preview'] as DigitalGoldPreview? ??
                  const DigitalGoldPreview(
                    kycStatus: true,
                    isUserRegistered: true,
                    myGoldBalance: 0,
                    taxAmt1: 0,
                    taxAmt2: 0,
                    preTaxAmount: 0,
                    totalAmount: 0,
                  ),
              isSellingInRupees: extra['isBuyingInRupees'] as bool? ?? true,
              metal: metal,
            );
          },
        ),
        GoRoute(
          path: RouteConstants.digitalGoldSellSuccess,
          builder: (context, state) {
            final metal =
                DigitalMetalTheme.fromQuery(state.uri.queryParameters['metal']);
            return DigitalGoldSellSuccessView(metal: metal);
          },
        ),
        GoRoute(
          path: RouteConstants.digitalGoldLocker,
          builder: (context, state) {
            final metal =
                DigitalMetalTheme.fromQuery(state.uri.queryParameters['metal']);
            return DigitalGoldLockerView(metal: metal);
          },
        ),
        GoRoute(
          path: RouteConstants.digitalGoldSipSetup,
          builder: (context, state) => const DigitalGoldSipSetupView(),
        ),
        GoRoute(
          path: RouteConstants.digitalGoldSipPortfolio,
          builder: (context, state) => const DigitalGoldSipPortfolioView(),
        ),
        GoRoute(
          path: RouteConstants.digitalGoldSipSuccess,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return DigitalGoldSipSuccessView(
              receipt: extra?['receipt'] as DigitalGoldPurchaseReceipt?,
            );
          },
        ),
        GoRoute(
          path: RouteConstants.referral,
          builder: (context, state) => ReferralDeepLinkView(
            referralCode: state.uri.queryParameters['code'] ?? '',
          ),
        ),
      ],
    );

    ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => router.refresh(),
    );

    return router;
  },
);

TransactionDetailScreen _transactionDetailFromState(
  BuildContext context,
  GoRouterState state,
) {
  final extra = state.extra;
  TransactionHistoryEntry? entry;
  var fromPaymentFlow = false;
  if (extra is TransactionHistoryEntry) {
    entry = extra;
  } else if (extra is Map) {
    final mapped = extra.map((key, value) => MapEntry(key.toString(), value));
    entry = mapped['entry'] as TransactionHistoryEntry?;
    fromPaymentFlow = mapped['fromPaymentFlow'] == true;
  }
  if (fromPaymentFlow) {
    return TransactionDetailScreen(
      entry: entry,
      doneLabel: 'View Transaction History',
      onBack: () => context.go(RouteConstants.transactions),
      onDone: () => context.go(RouteConstants.transactions),
    );
  }
  return TransactionDetailScreen(entry: entry);
}

