// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/file_constants.dart';
import '../constants/routes_constant.dart';
import '../features/educationFees/controllers/education_fees_controller.dart';
import '../features/educationFees/models/education_fees_responses.dart';
import '../features/educationFees/views/education_payment_thank_you_view.dart';
import '../features/profile/models/transaction_history_entry.dart';
import '../services/logger_service.dart';
import 'k_dialog.dart';
import 'payment_processing_loader.dart';

void openEducationPaymentProcessing(Map<String, dynamic> extra) {
  var opened = false;

  void open() {
    if (opened) return;
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    opened = true;
    context.go(RouteConstants.paymentProcessing, extra: extra);
  }

  open();

  if (opened) return;
  if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
    WidgetsBinding.instance.addPostFrameCallback((_) => open());
    return;
  }

  late final AppLifecycleListener listener;
  listener = AppLifecycleListener(
    onResume: () {
      listener.dispose();
      open();
    },
  );
}

const _statusRetryInterval = Duration(seconds: 1);
const _processingTimeout = paymentProcessingDuration;

class PaymentProcessingWait<T> {
  const PaymentProcessingWait({this.value, this.timedOut = false});

  final T? value;
  final bool timedOut;
}

/// Shows the common processing overlay while [work] runs.
/// Completes early on success/result, or [timedOut] at 60 seconds.
Future<PaymentProcessingWait<T>> showPaymentProcessingWhile<T>({
  required Future<T> work,
  String message = 'Processing Your Payment',
}) async {
  final overlayState = navigatorKey.currentState?.overlay;
  OverlayEntry? entry;
  if (overlayState != null) {
    entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: ProcessingOverlay(
            isProcessing: true,
            message: message,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    overlayState.insert(entry);
  }

  final completer = Completer<PaymentProcessingWait<T>>();
  final timeout = Timer(_processingTimeout, () {
    if (!completer.isCompleted) {
      completer.complete(PaymentProcessingWait<T>(timedOut: true));
    }
  });

  unawaited(
    work.then((value) {
      if (!completer.isCompleted) {
        completer.complete(PaymentProcessingWait(value: value));
      }
    }).catchError((Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    }),
  );

  try {
    return await completer.future;
  } finally {
    timeout.cancel();
    entry?.remove();
  }
}

/// A reusable processing overlay that can be displayed over any child widget.
///
/// [isProcessing] controls whether the overlay is shown.
/// [message] is the processing title displayed in the bottom panel.
/// [child] is the underlying UI over which the overlay appears.
class ProcessingOverlay extends StatelessWidget {
  const ProcessingOverlay({
    super.key,
    required this.isProcessing,
    required this.message,
    required this.child,
  });

  final bool isProcessing;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isProcessing)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: _PaymentProcessingLayout(message: message),
            ),
          ),
      ],
    );
  }
}

class _PaymentProcessingLayout extends StatelessWidget {
  const _PaymentProcessingLayout({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;
        final bottomInset = MediaQuery.paddingOf(context).bottom;

        // Top banner / white sheet split driven by the banner image's
        // intrinsic aspect ratio (processingbanner.png is 440x343): at the
        // full available width the banner is laid out at its natural height,
        // so it is never stretched or distorted. The natural height is
        // bounded proportionally to the measured viewport (raw runtime
        // values only - ScreenUtil is not re-applied on top of the
        // constraints, so no double scaling, no hardcoded pixel clamps) so
        // the white sheet keeps enough breathing room on short/compact
        // screens. When the cap engages, BoxFit.cover with top alignment
        // only trims the bottom edge, which stays hidden behind the sheet.
        const bannerAspect = 440 / 343;
        final naturalBannerHeight = availableWidth / bannerAspect;
        final imageHeight = naturalBannerHeight.clamp(
          availableHeight * 0.24,
          availableHeight * 0.42,
        );
        // The sheet overlaps the banner's bottom edge by the design gap.
        final sheetOverlap = math.min(24.r, imageHeight * 0.12);
        final sheetTop = imageHeight - sheetOverlap;
        final sheetHeight = availableHeight - sheetTop;

        // Effective inner height for content inside the sheet
        final contentHeight = math.max(0.0, sheetHeight - bottomInset);

        // Circular loader diameter: derived from the available screen WIDTH
        // (a single isotropic scale applied to both axes since it is square),
        // bounded in raw logical pixels so ScreenUtil is not re-applied on top
        // of the measured constraint (no double scaling). 0.25 keeps the
        // design-size (360w) appearance identical while stopping the loader
        // from growing on larger-width phones.
        final loaderSize = (availableWidth * 0.25).clamp(64.0, 120.0);

        // Content horizontal constraint matching Image 1's ~75-80% width with margins.
        final contentMaxWidth = math.min(availableWidth - 44.w, 340.w);

        // Dynamic spacing proportional to inner sheet height. Per the Figma
        // reference the loader floats slightly below the white panel's top
        // edge (~5.5% of the panel height), with the leftover space staying
        // below the trust row (FittedBox anchored to topCenter).
        // The four content gaps below were measured directly from the
        // Figma 440x956 frame: loader->title ~30px, title->description
        // ~20px, description->card ~50px, trust row->panel bottom ~50px
        // (above the ~34px home-indicator safe area). Measured
        // contentHeight on that frame is ~608px, so each ratio reproduces
        // the Figma gap exactly there; the raw logical-pixel upper bounds
        // pin the gaps at the design values so taller screens never
        // enlarge them beyond the Figma proportions, while shorter screens
        // scale them down adaptively. Bounds are raw logical pixels (same
        // convention as loaderSize) - ScreenUtil is not re-applied on top
        // of the measured constraint, so no double scaling.
        final gapTop = (contentHeight * 0.055).clamp(14.0, 44.h);
        final gapAfterLoader = (contentHeight * 0.0493).clamp(10.0, 30.0);
        final gapAfterTitle = (contentHeight * 0.0329).clamp(6.0, 20.0);
        final gapAfterDesc = (contentHeight * 0.0822).clamp(12.0, 50.0);
        final gapAfterCard = (contentHeight * 0.04).clamp(6.0, 26.h);
        final gapBottom = (contentHeight * 0.0822).clamp(12.0, 50.0);

        return ColoredBox(
          color: Colors.white,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: imageHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                  child: Image.asset(
                    FileConstants.processingBanner,
                    width: availableWidth,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              // Clean banner presentation: no overlay badge or extra text is
              // rendered on top of the processing banner.
              Positioned(
                top: sheetTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x1AC2C2C2),
                        offset: Offset(0, -7.h),
                        blurRadius: 16.r,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: const Color(0x17C2C2C2),
                        offset: Offset(0, -30.h),
                        blurRadius: 30.r,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: const Color(0x0DC2C2C2),
                        offset: Offset(0, -67.h),
                        blurRadius: 40.r,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: const Color(0x03C2C2C2),
                        offset: Offset(0, -120.h),
                        blurRadius: 48.r,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        SizedBox(
                          height: contentHeight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            // Anchor to the top so the loader keeps only
                            // `gapTop` below the panel edge; leftover space
                            // stays below the trust row.
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: availableWidth - 40.w,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: gapTop),
                                  // 1. Processing indicator
                                  SizedBox(
                                    width: loaderSize,
                                    height: loaderSize,
                                    child: DecoratedBox(
                                      decoration: const BoxDecoration(
                                        color: Color(0x1ADD5428),
                                        shape: BoxShape.circle,
                                      ),
                                      child: PaymentProcessingLoader(
                                        key: const ValueKey(
                                          'payment-processing-lottie',
                                        ),
                                        size: loaderSize,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: gapAfterLoader),
                                  // 2. Title
                                  Text(
                                    message,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.black,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: gapAfterTitle),
                                  // 3. Description
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                                    child: Text(
                                      'Your payment is currently being processed. Please wait a moment and keep the app open. Do not close the app or use the back button until the payment is completed.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF7C7C7C),
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w400,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: gapAfterDesc),
                                  // 4. Security information card
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14.w,
                                        vertical: 11.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F7F7),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.verified_user,
                                            color: const Color(0xFF2BB673),
                                            size: 22.r,
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Your Security Matters',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    color: Colors.black,
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.2,
                                                  ),
                                                ),
                                                SizedBox(height: 5.h),
                                                Text(
                                                  'Your transaction is being processed securely through our trusted payment partners.',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    color: Colors.black,
                                                    fontSize: 10.sp,
                                                    fontWeight: FontWeight.w400,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: gapAfterCard),
                                  // 5. Bottom trust indicators
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _TrustItem(
                                            asset: FileConstants.securePayments,
                                            label: 'Secure\nPayments',
                                            iconSize: 22.r,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                        _TrustDivider(height: 34.h),
                                        Expanded(
                                          child: _TrustItem(
                                            asset: FileConstants.rbiCompliant,
                                            label: 'RBI Compliant\nPlatform',
                                            iconSize: 22.r,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                        _TrustDivider(height: 34.h),
                                        Expanded(
                                          child: _TrustItem(
                                            asset: FileConstants.trustedBy,
                                            label: 'Trusted By\nMillions',
                                            iconSize: 22.r,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: gapBottom),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: bottomInset),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.asset,
    required this.label,
    required this.iconSize,
    required this.fontSize,
  });

  final String asset;
  final String label;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          asset,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 7.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _TrustDivider extends StatelessWidget {
  const _TrustDivider({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        width: 1.w,
        height: height,
        color: const Color(0xFFE6E6E6),
      ),
    );
  }
}

/// A full-screen, back-locked payment status checker.
class PaymentProcessingOverlay extends HookConsumerWidget {
  const PaymentProcessingOverlay({
    super.key,
    required this.transactionRefId,
    this.paymentType = 'Education Fees',
    this.recipientName = '',
    this.maskedAccount = '',
    this.fallbackAmount = '',
    this.paymentId = '',
    this.message = 'Processing Your Payment',
  });

  final String transactionRefId;
  final String paymentType;
  final String recipientName;
  final String maskedAccount;
  final String fallbackAmount;
  final String paymentId;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      var cancelled = false;
      var completed = false;
      Timer? countdownTimer;
      EducationPaymentStatusResponse? lastResult;

      void complete(VoidCallback action) {
        if (cancelled || completed) return;
        completed = true;
        countdownTimer?.cancel();
        if (!context.mounted) return;
        action();
      }

      void goToSuccess(EducationPaymentStatusResponse result) {
        complete(() {
          logger.info(
            'Payment SUCCESS for ${transactionRefId.trim()}',
          );
          final dynamicPaymentName = result.paymentType.trim().isNotEmpty
              ? result.paymentType.trim()
              : paymentType.trim().isNotEmpty
                  ? paymentType.trim()
                  : '';
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EducationPaymentThankYouView(
                amount: result.amount.isNotEmpty ? result.amount : fallbackAmount,
                payableAmount: result.amount.isNotEmpty ? result.amount : fallbackAmount,
                transactionTime: result.updatedAt.isNotEmpty ? result.updatedAt : DateTime.now().toIso8601String(),
                paymentType: dynamicPaymentName,
              ),
            ),
          );
        });
      }

      bool isTerminalStatus(EducationPaymentStatusResponse result) {
        final value =
            result.paymentStatus.trim().toUpperCase().replaceAll('-', '_');
        if (result.isSuccess || result.isFailed) return true;
        if (value.contains('REFUND')) return true;
        return false;
      }

      void goToStatusScreen(EducationPaymentStatusResponse result) {
        if (result.isSuccess) {
          goToSuccess(result);
          return;
        }
        complete(() {
          final referenceId = transactionRefId.trim();
          logger.info(
            'Payment ${result.paymentStatus} for $referenceId',
          );
          context.go(
            RouteConstants.transactionDetailForStatus(result.paymentStatus),
            extra: <String, dynamic>{
              'entry': _buildTransactionEntry(
                result: result,
                transactionRefId: referenceId,
                paymentType: paymentType,
                recipientName: recipientName,
                maskedAccount: maskedAccount,
                fallbackAmount: fallbackAmount,
                paymentId: paymentId,
              ),
              'fromPaymentFlow': true,
            },
          );
        });
      }

      void goToPending() {
        complete(() {
          final referenceId = transactionRefId.trim();
          final result = lastResult ??
              EducationPaymentStatusResponse(
                status: true,
                message: '',
                transactionId: referenceId,
                paymentStatus: 'PENDING',
                amount: fallbackAmount,
                updatedAt: DateTime.now().toIso8601String(),
                paymentType: paymentType,
              );
          final pendingResult = EducationPaymentStatusResponse(
            status: result.status,
            message: result.message,
            transactionId: result.transactionId.isNotEmpty
                ? result.transactionId
                : referenceId,
            paymentStatus: 'PENDING',
            amount: result.amount.isNotEmpty ? result.amount : fallbackAmount,
            updatedAt: result.updatedAt.isNotEmpty
                ? result.updatedAt
                : DateTime.now().toIso8601String(),
            paymentType: result.paymentType,
            serviceCharge: result.serviceCharge,
            gstOnServiceCharge: result.gstOnServiceCharge,
            payableAmount: result.payableAmount,
            bannerImage: result.bannerImage,
          );
          logger.info('Payment PENDING timeout for $referenceId');
          context.go(
            RouteConstants.transactionDetailForStatus('PENDING'),
            extra: <String, dynamic>{
              'entry': _buildTransactionEntry(
                result: pendingResult,
                transactionRefId: referenceId,
                paymentType: paymentType,
                recipientName: recipientName,
                maskedAccount: maskedAccount,
                fallbackAmount: fallbackAmount,
                paymentId: paymentId,
              ),
              'fromPaymentFlow': true,
            },
          );
        });
      }

      Future<void> pollStatus() async {
        final referenceId = transactionRefId.trim();
        if (referenceId.isEmpty) {
          logger.error('Payment reference is missing');
          complete(() {
            if (context.mounted) {
              context.go(RouteConstants.transactions);
            }
          });
          return;
        }

        final repository = ref.read(educationFeesRepositoryProvider);
        while (!cancelled && !completed) {
          try {
            final result = await repository.fetchPaymentStatus(
              transactionRefId: referenceId,
            );
            if (cancelled || completed) return;
            lastResult = result;
            if (result.isSuccess) {
              goToSuccess(result);
              return;
            }
            if (isTerminalStatus(result)) {
              goToStatusScreen(result);
              return;
            }
          } catch (error, stackTrace) {
            if (cancelled || completed) return;
            logger.error(
              'Payment verification failed: $error',
              error: error,
              stackTrace: stackTrace,
            );
          }

          if (cancelled || completed) return;
          await Future<void>.delayed(_statusRetryInterval);
        }
      }

      var remaining = _processingTimeout.inSeconds;
      countdownTimer = Timer.periodic(_statusRetryInterval, (timer) {
        if (cancelled || completed) {
          timer.cancel();
          return;
        }
        remaining -= 1;
        if (remaining <= 0) {
          timer.cancel();
          goToPending();
        }
      });

      unawaited(Future<void>.microtask(pollStatus));
      return () {
        cancelled = true;
        countdownTimer?.cancel();
      };
    }, const []);

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.white,
        child: ProcessingOverlay(
          isProcessing: true,
          message: message,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

TransactionHistoryEntry _buildTransactionEntry({
  required EducationPaymentStatusResponse result,
  required String transactionRefId,
  required String paymentType,
  required String recipientName,
  required String maskedAccount,
  required String fallbackAmount,
  required String paymentId,
}) {
  final transactionId =
      result.transactionId.isNotEmpty ? result.transactionId : transactionRefId;
  final rawAmount = result.amount.isNotEmpty ? result.amount : fallbackAmount;
  final amount = _formatAmount(rawAmount);
  final resolvedPaymentType = result.paymentType.trim().isNotEmpty
      ? result.paymentType.trim()
      : (paymentType.trim().isEmpty ? 'Education Fees' : paymentType.trim());
  final payableAmount = result.payableAmount.trim().isNotEmpty
      ? _formatAmount(result.payableAmount)
      : amount;

  return TransactionHistoryEntry(
    paymentStatus: result.paymentStatus.trim().toUpperCase(),
    paymentType: resolvedPaymentType,
    // The caller passes the order's fee type here (education/rent flow sends
    // state.feeType, e.g. "House Rent"). Populate feeType so the immediate
    // status detail resolves the same LEFT Recipient Name / RIGHT Fee Type as
    // the persisted history row, instead of falling back to a generic param.
    feeType: paymentType.trim().isNotEmpty ? paymentType.trim() : null,
    billerName:
        recipientName.trim().isEmpty ? resolvedPaymentType : recipientName,
    maskedIdentifier:
        maskedAccount.trim().isEmpty ? transactionId : maskedAccount,
    amount: amount,
    platformFees: '',
    totalAmountCharged: payableAmount,
    customerMobile: '',
    iconUrl: '',
    pgTransactionId: paymentId.trim().isEmpty ? transactionId : paymentId,
    ecoinsTransactionId: '',
    transactionId: transactionId,
    bankReferenceId: '',
    referenceId: transactionRefId,
    transactionTime: result.updatedAt.isNotEmpty
        ? result.updatedAt
        : DateTime.now().toIso8601String(),
    method: 'Razorpay / Online',
    methodIcon: '',
    paymentMode: 'Online',
    vpa: '',
    rrn: '',
    customerParams: ensurePaymentTypeCustomerParam(
      params: [
        TransactionCustomerParam(
          label: 'Payment to',
          value: recipientName.trim().isEmpty
              ? resolvedPaymentType
              : recipientName.trim(),
        ),
      ],
      paymentType: resolvedPaymentType,
    ),
    amountBreakdown: composeTransactionAmountBreakdown(
      source: {
        'amount': amount,
        'service_charge': result.serviceCharge,
        'gst_on_service_charge': result.gstOnServiceCharge,
        'payable_amount': result.payableAmount,
      },
      fallbackBillAmount: amount,
      fallbackTotal: payableAmount,
      billAmountLabel: 'Bill Amount',
    ),
  );
}

String _formatAmount(String raw) {
  final value = raw.trim();
  final parsed = double.tryParse(value.replaceAll(',', ''));
  if (parsed == null) return value;
  return parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 2);
}
