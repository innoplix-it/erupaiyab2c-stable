// ignore_for_file: deprecated_member_use

import 'dart:async';

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
    double x(double value) => (value * 360 / 440).w;
    double y(double value) => (value * 360 / 440).h;
    double r(double value) => (value * 360 / 440).r;
    double s(double value) => (value * 360 / 440).sp;
    final sheetTop = x(314);
    final imageHeight = x(343);
    final contentWidth = x(353);

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
                bottomLeft: Radius.circular(r(12)),
                bottomRight: Radius.circular(r(12)),
              ),
              child: Image.asset(
                FileConstants.processingStatic,
                width: 1.sw,
                height: imageHeight,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: sheetTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(r(20)),
                  topRight: Radius.circular(r(20)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1AC2C2C2),
                    offset: Offset(0, -x(7)),
                    blurRadius: x(16),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0x17C2C2C2),
                    offset: Offset(0, -x(30)),
                    blurRadius: x(30),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0x0DC2C2C2),
                    offset: Offset(0, -x(67)),
                    blurRadius: x(40),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0x03C2C2C2),
                    offset: Offset(0, -x(120)),
                    blurRadius: x(48),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0x00C2C2C2),
                    offset: Offset(0, -x(187)),
                    blurRadius: x(52),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(x(44), y(51), x(44), y(24)),
                  child: Column(
                    children: [
                      SizedBox(
                        width: contentWidth,
                        child: Column(
                          children: [
                            SizedBox(
                              width: x(158),
                              height: x(158),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: Color(0x1ADD5428),
                                  shape: BoxShape.circle,
                                ),
                                child: PaymentProcessingLoader(
                                  key: const ValueKey(
                                    'payment-processing-lottie',
                                  ),
                                  size: x(158),
                                ),
                              ),
                            ),
                            SizedBox(height: y(24)),
                            SizedBox(
                              width: contentWidth,
                              child: Text(
                                message,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.black,
                                  fontSize: s(20),
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ),
                            SizedBox(height: y(24)),
                            SizedBox(
                              width: contentWidth,
                              child: Text(
                                'Your payment is currently being processed. Please wait a moment and keep the app open. Do not close the app or use the back button until the payment is completed.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF7C7C7C),
                                  fontSize: s(12),
                                  fontWeight: FontWeight.w400,
                                  height: 22.h / 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: y(47)),
                      SizedBox(
                        width: contentWidth,
                        child: Column(
                          children: [
                            Container(
                              width: contentWidth,
                              padding: EdgeInsets.fromLTRB(
                                x(16),
                                y(14),
                                x(16),
                                y(14),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F7F7),
                                borderRadius: BorderRadius.circular(r(12)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    color: const Color(0xFF2BB673),
                                    size: x(22),
                                  ),
                                  SizedBox(width: x(10)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your Security Matters',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.black,
                                            fontSize: s(12),
                                            fontWeight: FontWeight.w700,
                                            height: 1,
                                          ),
                                        ),
                                        SizedBox(height: y(6)),
                                        Text(
                                          'Your transaction is being processed securely through our trusted payment partners.',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.black,
                                            fontSize: s(10),
                                            fontWeight: FontWeight.w400,
                                            height: 19.h / 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: y(40)),
                            SizedBox(
                              width: contentWidth,
                              height: y(64),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: _TrustItem(
                                        asset: FileConstants.securePayments,
                                        label: 'Secure\nPayments',
                                        size: x(107),
                                        iconSize: x(24),
                                        fontSize: s(12),
                                      ),
                                    ),
                                  ),
                                  _TrustDivider(height: y(40)),
                                  Expanded(
                                    child: Center(
                                      child: _TrustItem(
                                        asset: FileConstants.rbiCompliant,
                                        label: 'RBI Compliant\nPlatform',
                                        size: x(107),
                                        iconSize: x(24),
                                        fontSize: s(12),
                                      ),
                                    ),
                                  ),
                                  _TrustDivider(height: y(40)),
                                  Expanded(
                                    child: Center(
                                      child: _TrustItem(
                                        asset: FileConstants.trustedBy,
                                        label: 'Trusted By\nMillions',
                                        size: x(107),
                                        iconSize: x(24),
                                        fontSize: s(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.asset,
    required this.label,
    required this.size,
    required this.iconSize,
    required this.fontSize,
  });

  final String asset;
  final String label;
  final double size;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            asset,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
          SizedBox(height: fontSize * 10 / 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.black,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
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
          context.go(
            RouteConstants.educationPaymentThankYou,
            extra: <String, dynamic>{
              'amount': result.amount,
              'payableAmount': result.payableAmount,
              'transactionTime': result.updatedAt,
              'bannerImage': result.bannerImage,
              'paymentType': result.paymentType.trim().isNotEmpty
                  ? result.paymentType
                  : paymentType,
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
