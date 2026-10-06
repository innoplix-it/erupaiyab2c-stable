// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../models/support_latest_transaction.dart';
import '../models/transaction_history_entry.dart';
import '../utils/receipt_actions.dart';
import 'create_support_ticket_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({
    super.key,
    this.entry,
    this.doneLabel = 'Done',
    this.onDone,
    this.onBack,
    this.navigateHomeOnExit = false,
  });

  final TransactionHistoryEntry? entry;
  final String doneLabel;
  final VoidCallback? onDone;
  final VoidCallback? onBack;
  final bool navigateHomeOnExit;

  @override
  Widget build(BuildContext context) {
    final tx = entry ??
        const TransactionHistoryEntry(
          paymentStatus: '',
          paymentType: '',
          billerName: '',
          maskedIdentifier: '',
          amount: '',
          platformFees: '',
          totalAmountCharged: '',
          customerMobile: '',
          iconUrl: '',
          pgTransactionId: '',
          ecoinsTransactionId: '',
          transactionId: '',
          bankReferenceId: '',
          referenceId: '',
          transactionTime: '',
          method: '',
          methodIcon: '',
          paymentMode: '',
          vpa: '',
          rrn: '',
          customerParams: [],
          amountBreakdown: {},
        );

    final status = tx.paymentStatus.trim().toUpperCase();
    final paymentMethod =
        tx.method.trim().isNotEmpty ? tx.method.trim() : 'UPI/GPay';
    final totalAmount = tx.totalAmountCharged.trim().isNotEmpty
        ? tx.totalAmountCharged
        : tx.amount;
    final statusMeta = _statusMeta(
      status,
      refundAmount: _formatAmount(totalAmount),
    );
    final txnId = tx.transactionId.trim();
    final pgTxnId = tx.pgTransactionId.trim();
    final walletTxnId = tx.ecoinsTransactionId.trim();
    final bankRefId = tx.bankReferenceId.trim();
    final refId = tx.referenceId.trim();
    final receiptId = _resolveReceiptTransactionId(refId: refId, txnId: txnId);
    final supportTransaction = SupportLatestTransaction(
      id: refId.isNotEmpty ? refId : txnId,
      paymentType: tx.paymentType.trim(),
      billerName: tx.billerName.trim(),
      amount: totalAmount.trim(),
      status: tx.paymentStatus.trim(),
      date: tx.transactionTime.trim(),
      type: _resolveSupportTransactionType(tx),
      transactionId: txnId,
    );
    final resolvedParams = _resolveHeaderParams(tx);
    final primaryParam = resolvedParams.first;
    final secondaryParam =
        resolvedParams.length > 1 ? resolvedParams[1] : resolvedParams.first;
    final breakdownRows = _resolveBreakdownRows(tx);
    final detailRows = <_DetailValueRow>[
      _DetailValueRow(label: 'Amount', value: _formatAmount(totalAmount)),
      _DetailValueRow(label: 'Payment Method', value: paymentMethod),
      if (pgTxnId.isNotEmpty)
        _DetailValueRow(
          label: 'PG Transaction ID',
          value: pgTxnId,
          copyable: true,
        ),
      if (walletTxnId.isNotEmpty)
        _DetailValueRow(
          label: 'Wallet Transaction ID',
          value: walletTxnId,
          copyable: true,
        ),
      if (refId.isNotEmpty)
        _DetailValueRow(
          label: 'Reference ID',
          value: refId,
          copyable: true,
        ),
      if (bankRefId.isNotEmpty)
        _DetailValueRow(
          label: 'Bank Reference ID',
          value: bankRefId,
          copyable: true,
        ),
    ];

    Future<void> handleExitToHome() async {
      final navigator = Navigator.of(context, rootNavigator: true);
      navigator.popUntil((route) => route.isFirst);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final rootContext = navigatorKey.currentContext;
        if (rootContext != null && rootContext.mounted) {
          rootContext.go(RouteConstants.home);
        }
      });
    }

    final effectiveOnDone = navigateHomeOnExit
        ? () {
            handleExitToHome();
          }
        : onDone;
    final effectiveOnBack = navigateHomeOnExit
        ? () {
            handleExitToHome();
          }
        : onBack;

    final screen = Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final hasStatusMessage = statusMeta.message.isNotEmpty;
          final topPadding = MediaQuery.paddingOf(context).top;
          final headerTop = topPadding + 40.h;
          final headerHorizontalPadding = 24.w;
          final sectionGap = 10.h;
          final titleToDateGap = 4.h;
          final headerWidth =
              constraints.maxWidth - (headerHorizontalPadding * 2);
          final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17.sp,
                  ) ??
              TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17.sp,
              );
          final dateStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10.5.sp,
                  ) ??
              TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10.5.sp,
              );
          final messageStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    height: 1.45,
                    fontSize: 9.5.sp,
                  ) ??
              TextStyle(
                color: Colors.white,
                height: 1.45,
                fontSize: 9.5.sp,
              );
          final messageTitleStyle =
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5.sp,
                      ) ??
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5.sp,
                  );
          final titleHeight = _measureTextHeight(
            context,
            text: statusMeta.title,
            style: titleStyle,
            maxWidth: headerWidth,
          );
          final dateHeight = _measureTextHeight(
            context,
            text: _formatHeaderDate(tx.transactionTime),
            style: dateStyle,
            maxWidth: headerWidth,
          );
          final messageHeight = hasStatusMessage
              ? _measureTextHeight(
                  context,
                  text: statusMeta.message,
                  style: messageStyle,
                  maxWidth: headerWidth - 24.w,
                )
              : 0.0;
          final messageTitleHeight =
              hasStatusMessage && statusMeta.messageTitle.isNotEmpty
                  ? _measureTextHeight(
                      context,
                      text: statusMeta.messageTitle,
                      style: messageTitleStyle,
                      maxWidth: headerWidth - 42.w,
                    )
                  : 0.0;
          final messageContainerHeight = hasStatusMessage
              ? messageHeight +
                  (statusMeta.messageTitle.isNotEmpty
                      ? messageTitleHeight + 8.h
                      : 0.0) +
                  18.h
              : 0.0;
          final headerContentHeight = 52.h +
              sectionGap +
              titleHeight +
              titleToDateGap +
              dateHeight +
              (hasStatusMessage ? sectionGap + messageContainerHeight : 0.0);
          final cardTop = headerTop + headerContentHeight + sectionGap;
          final minHeaderHeight = 220.h;
          final computedHeaderHeight = cardTop + 24.h;
          final headerHeight = computedHeaderHeight < minHeaderHeight
              ? minHeaderHeight
              : computedHeaderHeight;

          return Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: headerHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28.r),
                        bottomRight: Radius.circular(28.r),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28.r),
                        bottomRight: Radius.circular(28.r),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: statusMeta.gradient,
                            stops: statusMeta.gradient.length == 4
                                ? const [0.0, 0.3446, 0.9055, 1.0]
                                : null,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: ColoredBox(color: Colors.white),
                  ),
                ],
              ),
              Positioned(
                left: 12.w,
                top: MediaQuery.paddingOf(context).top + 8.h,
                child: IconButton(
                  onPressed: effectiveOnBack ??
                      () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                left: headerHorizontalPadding,
                right: headerHorizontalPadding,
                top: headerTop,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Green check seal is only the backdrop for the raster
                        // (success) icon. The new failed/pending icons are
                        // self-contained white SVGs with a cut-out glyph, so
                        // they render straight on the status gradient and the
                        // glyph picks up the correct red/amber color.
                        if (!statusMeta.iconAsset.endsWith('.svg'))
                          SvgPicture.asset(
                            FileConstants.successVectorIcon,
                            width: 50.r,
                            height: 50.r,
                            fit: BoxFit.contain,
                          ),
                        if (statusMeta.iconAsset.endsWith('.svg'))
                          SvgPicture.asset(
                            statusMeta.iconAsset,
                            width: 52.r,
                            height: 52.r,
                            fit: BoxFit.contain,
                          )
                        else
                          Image.asset(
                            statusMeta.iconAsset,
                            width: 52.r,
                            height: 52.r,
                            fit: BoxFit.contain,
                          ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      statusMeta.title,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                    SizedBox(height: titleToDateGap),
                    Text(
                      _formatHeaderDate(tx.transactionTime),
                      textAlign: TextAlign.center,
                      style: dateStyle,
                    ),
                    if (statusMeta.message.isNotEmpty) ...[
                      SizedBox(height: sectionGap),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 9.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusMeta.messageBackgroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          children: [
                            if (statusMeta.messageTitle.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8.r,
                                    height: 8.r,
                                    decoration: BoxDecoration(
                                      gradient: statusMeta
                                              .messageIndicatorGradient
                                              .isNotEmpty
                                          ? LinearGradient(
                                              colors: statusMeta
                                                  .messageIndicatorGradient,
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            )
                                          : null,
                                      color: statusMeta
                                              .messageIndicatorGradient.isEmpty
                                          ? Colors.white
                                          : null,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Flexible(
                                    child: Text(
                                      statusMeta.messageTitle,
                                      textAlign: TextAlign.center,
                                      style: messageTitleStyle,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                            ],
                            Text(
                              statusMeta.message,
                              textAlign: TextAlign.center,
                              style: messageStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 22.w,
                right: 22.w,
                top: cardTop,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: 18.h),
                          child: Column(
                            children: [
                              _TransactionResultCard(
                                primaryParam: primaryParam,
                                secondaryParam: secondaryParam,
                                detailRows: detailRows,
                                breakdownRows: breakdownRows,
                              ),
                              SizedBox(height: 14.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ResultActionButton(
                                    icon: Icons.headset_mic_outlined,
                                    label: 'Contact Support',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CreateSupportTicketScreen(
                                            transaction: supportTransaction,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _ResultActionButton(
                                    icon: Icons.share_outlined,
                                    label: 'Share Receipt',
                                    onTap: () =>
                                        ReceiptActions.handleReceiptAction(
                                      context,
                                      transactionId: receiptId,
                                      action: ReceiptAction.share,
                                    ),
                                  ),
                                  _ResultActionButton(
                                    icon: Icons.receipt_long_outlined,
                                    label: 'Download Receipt',
                                    onTap: () =>
                                        ReceiptActions.handleReceiptAction(
                                      context,
                                      transactionId: receiptId,
                                      action: ReceiptAction.download,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      CustomElevatedButton(
                        onPressed: effectiveOnDone ?? () => context.pop(),
                        label: doneLabel,
                        uppercaseLabel: false,
                        showArrow: false,
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'powered by',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.black,
                                    ),
                          ),
                          SizedBox(width: 6.w),
                          Image.asset(
                            FileConstants.bharatConnectColor,
                            height: 16.h,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (effectiveOnBack == null) {
      return screen;
    }

    return WillPopScope(
      onWillPop: () async {
        effectiveOnBack.call();
        return false;
      },
      child: screen,
    );
  }
}

List<TransactionCustomerParam> _resolveHeaderParams(
    TransactionHistoryEntry tx) {
  final paymentType = tx.paymentType.trim().toLowerCase();
  final billerName = tx.billerName.trim();
  final customerMobile = tx.customerMobile.trim();
  final maskedIdentifier = tx.maskedIdentifier.trim();

  // Credit Card transaction flow:
  // Extract and display "Registered Mobile Number" and "Credit Card Number" (masked with only last 4 digits).
  if (paymentType.contains('credit')) {
    // 1. Resolve Registered Mobile Number dynamically
    String mobileValue = '';
    for (final param in tx.customerParams) {
      final l = param.label.trim().toLowerCase();
      if (l.contains('mobile') ||
          l.contains('phone') ||
          l.contains('registered')) {
        mobileValue = param.value.trim();
        break;
      }
    }
    if (mobileValue.isEmpty && customerMobile.isNotEmpty) {
      mobileValue = customerMobile;
    }
    if (mobileValue.isEmpty &&
        maskedIdentifier.length == 10 &&
        RegExp(r'^\d{10}$').hasMatch(maskedIdentifier)) {
      mobileValue = maskedIdentifier;
    }
    if (mobileValue.isEmpty) {
      mobileValue = billerName.isNotEmpty ? billerName : '-';
    }

    // 2. Resolve Credit Card Number dynamically and mask with only last 4 digits visible
    String cardRaw = '';
    for (final param in tx.customerParams) {
      final l = param.label.trim().toLowerCase();
      if (l.contains('card') ||
          l.contains('credit') ||
          l.contains('last 4') ||
          l.contains('last4') ||
          l.contains('account')) {
        cardRaw = param.value.trim();
        break;
      }
    }
    if (cardRaw.isEmpty &&
        maskedIdentifier.isNotEmpty &&
        maskedIdentifier != mobileValue) {
      cardRaw = maskedIdentifier;
    }

    final cardDigits = cardRaw.replaceAll(RegExp(r'\D'), '');
    final last4 = cardDigits.length >= 4
        ? cardDigits.substring(cardDigits.length - 4)
        : (cardDigits.isNotEmpty
            ? cardDigits
            : (cardRaw.length >= 4
                ? cardRaw.substring(cardRaw.length - 4)
                : cardRaw.trim()));

    final maskedCardNumber = last4.isNotEmpty
        ? '**** **** **** $last4'
        : '**** **** **** ****';

    return [
      TransactionCustomerParam(
        label: 'Registered Mobile Number',
        value: mobileValue,
      ),
      TransactionCustomerParam(
        label: 'Credit Card Number',
        value: maskedCardNumber,
      ),
    ];
  }

  // FASTag transaction flow:
  // Extract and display "Registered Mobile Number" and "Vehicle Registration Number" (or dynamic FASTag param).
  final isFastag = paymentType.contains('fastag') ||
      paymentType.contains('fasttag') ||
      paymentType.contains('fas tag') ||
      billerName.toLowerCase().contains('fastag') ||
      billerName.toLowerCase().contains('fasttag');
  if (isFastag) {
    // 1. Resolve Registered Mobile Number dynamically
    String mobileValue = '';
    for (final param in tx.customerParams) {
      final l = param.label.trim().toLowerCase();
      if (l.contains('mobile') ||
          l.contains('phone') ||
          l.contains('registered')) {
        mobileValue = param.value.trim();
        break;
      }
    }
    if (mobileValue.isEmpty && customerMobile.isNotEmpty) {
      mobileValue = customerMobile;
    }
    if (mobileValue.isEmpty &&
        maskedIdentifier.length == 10 &&
        RegExp(r'^\d{10}$').hasMatch(maskedIdentifier)) {
      mobileValue = maskedIdentifier;
    }

    // 2. Resolve Vehicle Registration Number / Tag ID dynamically
    String vehicleValue = '';
    String vehicleLabel = 'Vehicle Registration Number';
    for (final param in tx.customerParams) {
      final l = param.label.trim().toLowerCase();
      if (l.contains('vehicle') ||
          l.contains('registration') ||
          l.contains('reg') ||
          l.contains('chassis') ||
          l.contains('car') ||
          l.contains('tag') ||
          l.contains('vrn')) {
        vehicleValue = param.value.trim();
        vehicleLabel = param.label.trim();
        break;
      }
    }
    if (vehicleValue.isEmpty) {
      for (final param in tx.customerParams) {
        if (param.value.trim() != mobileValue) {
          vehicleValue = param.value.trim();
          vehicleLabel = param.label.trim();
          break;
        }
      }
    }
    if (vehicleValue.isEmpty &&
        maskedIdentifier.isNotEmpty &&
        maskedIdentifier != mobileValue) {
      vehicleValue = maskedIdentifier;
    }

    final result = <TransactionCustomerParam>[];
    if (mobileValue.isNotEmpty) {
      result.add(
        TransactionCustomerParam(
          label: 'Registered Mobile Number',
          value: mobileValue,
        ),
      );
    }
    if (vehicleValue.isNotEmpty) {
      result.add(
        TransactionCustomerParam(
          label: vehicleLabel,
          value: vehicleValue,
        ),
      );
    }
    if (result.length >= 2) {
      return result;
    }
    if (result.length == 1) {
      return [
        result.first,
        TransactionCustomerParam(
          label: 'Payment to',
          value: billerName.isNotEmpty ? billerName : 'FASTag Recharge',
        ),
      ];
    }
  }

  // Tuition Fee transaction flow:
  // Extract and display Tuition Fee parameters (e.g. Recipient / Tutor Name, Account Number, Student Details) dynamically without raw Map/List.
  final feeType = (tx.feeType ?? '').trim().toLowerCase();
  final isTuitionFee = paymentType.contains('tuition') ||
      paymentType.contains('tution') ||
      feeType.contains('tuition') ||
      feeType.contains('tution');
  if (isTuitionFee) {
    final explicit = tx.customerParams
        .where((p) => p.label.trim().isNotEmpty && p.value.trim().isNotEmpty)
        .toList();

    if (explicit.length >= 2) {
      return explicit;
    }

    String primaryLabel = '';
    String primaryValue = '';
    if (explicit.isNotEmpty) {
      primaryLabel = explicit.first.label;
      primaryValue = explicit.first.value;
    } else if (billerName.isNotEmpty) {
      primaryLabel = 'Recipient Name';
      primaryValue = billerName;
    }

    String secondaryLabel = '';
    String secondaryValue = '';

    if (maskedIdentifier.isNotEmpty && maskedIdentifier != primaryValue) {
      secondaryLabel = RegExp(r'^\d{10}$').hasMatch(maskedIdentifier)
          ? 'Registered Mobile Number'
          : 'Account Number';
      secondaryValue = maskedIdentifier;
    } else if (customerMobile.isNotEmpty && customerMobile != primaryValue) {
      secondaryLabel = 'Registered Mobile Number';
      secondaryValue = customerMobile;
    } else {
      secondaryLabel = 'Fee Type';
      // Use actual payment_type from API — do NOT hardcode 'Tuition Fee'
      secondaryValue = tx.paymentType.trim().isNotEmpty ? tx.paymentType.trim() : '';
    }

    final result = <TransactionCustomerParam>[];
    if (primaryValue.isNotEmpty) {
      result.add(
        TransactionCustomerParam(
          label: primaryLabel.isNotEmpty ? primaryLabel : 'Recipient Name',
          value: primaryValue,
        ),
      );
    }
    if (secondaryValue.isNotEmpty) {
      result.add(
        TransactionCustomerParam(
          label: secondaryLabel,
          value: secondaryValue,
        ),
      );
    }
    if (result.length >= 2) return result;
    if (result.length == 1) {
      // Use actual payment_type from API — do NOT hardcode 'Tuition Fee'
      final feeTypeValue = tx.paymentType.trim();
      if (feeTypeValue.isNotEmpty) {
        return [
          result.first,
          TransactionCustomerParam(
            label: 'Fee Type',
            value: feeTypeValue,
          ),
        ];
      }
      return [result.first, result.first];
    }
  }

  // Electricity transaction flow:
  // LEFT  → "Payment to"  = biller_name (dynamic operator name from API)
  // RIGHT → "Consumer No" = service_no_full (full consumer number from API)
  // Do NOT call ensurePaymentTypeCustomerParam here — it inserts "Payment Type"
  // at index 1 which would push "Consumer No" to index 2 and break the right
  // side of the header card.
  final isElectricity = paymentType.contains('electric') ||
      paymentType.contains('power') ||
      paymentType.contains('energy') ||
      paymentType.contains('discom') ||
      paymentType.contains('bijli') ||
      billerName.toLowerCase().contains('electric') ||
      billerName.toLowerCase().contains('power') ||
      billerName.toLowerCase().contains('energy') ||
      billerName.toLowerCase().contains('discom') ||
      billerName.toLowerCase().contains('bijli') ||
      billerName.toLowerCase().contains('msedcl') ||
      billerName.toLowerCase().contains('mahavitaran') ||
      billerName.toLowerCase().contains('maharashtra state') ||
      billerName.toLowerCase().contains('cesc') ||
      billerName.toLowerCase().contains('bescom') ||
      billerName.toLowerCase().contains('torrent') ||
      billerName.toLowerCase().contains('bses') ||
      billerName.toLowerCase().contains('tneb') ||
      billerName.toLowerCase().contains('uppcl') ||
      billerName.toLowerCase().contains('dhbvn') ||
      billerName.toLowerCase().contains('uhbvn') ||
      billerName.toLowerCase().contains('pspcl') ||
      (tx.serviceNoFull != null &&
          tx.serviceNoFull!.trim().isNotEmpty &&
          tx.serviceNoFull!.trim().toLowerCase() != 'null');
  if (isElectricity) {
    final full = tx.serviceNoFull?.trim();
    final consumerNo = (full != null &&
            full.isNotEmpty &&
            full.toLowerCase() != 'null')
        ? full
        : (tx.serviceNo?.trim().isNotEmpty == true
            ? tx.serviceNo!.trim()
            : tx.primaryConsumerNumber);
    final operatorName = billerName.isNotEmpty ? billerName : 'Electricity';

    return [
      TransactionCustomerParam(
        label: 'Payment to',
        value: operatorName,
      ),
      TransactionCustomerParam(
        label: 'Consumer No',
        value: consumerNo.isNotEmpty
            ? consumerNo
            : (maskedIdentifier.isNotEmpty ? maskedIdentifier : '-'),
      ),
    ];
  }

  // Mobile Recharge transaction flow:
  // LEFT  → "Operator Name"  = biller_name (operator from API, e.g. Jio, Airtel)
  // RIGHT → "Mobile Number"  = customerMobile or maskedIdentifier (existing mobile number)
  final isRecharge = paymentType.contains('recharge') ||
      paymentType.contains('prepaid') ||
      paymentType.contains('postpaid') ||
      tx.customerParams.any((p) => p.label.trim().toLowerCase() == 'customer_mobile');
  if (isRecharge) {
    // Resolve operator name from biller_name (API key: biller_name)
    final operatorName = billerName.isNotEmpty ? billerName : '';

    // Resolve mobile number: prefer customerMobile, fallback to maskedIdentifier
    String mobileValue = customerMobile;
    if (mobileValue.isEmpty && maskedIdentifier.isNotEmpty) {
      mobileValue = maskedIdentifier;
    }
    // Also check customerParams for a mobile/phone entry
    if (mobileValue.isEmpty) {
      for (final param in tx.customerParams) {
        final l = param.label.trim().toLowerCase();
        if (l.contains('mobile') || l.contains('phone') || l.contains('number')) {
          mobileValue = param.value.trim();
          break;
        }
      }
    }

    return [
      TransactionCustomerParam(
        label: 'Operator Name',
        value: operatorName.isNotEmpty ? operatorName : '-',
      ),
      TransactionCustomerParam(
        label: 'Mobile Number',
        value: mobileValue.isNotEmpty ? mobileValue : '-',
      ),
    ];
  }

  // Education transaction flow (School Fee / College Fee):
  // LEFT  → "Recipient Name" = billerName (existing recipient/institution name)
  // RIGHT → "Fee Type"       = paymentType (API key: payment_type, e.g. School Fee)
  final feeTypeLower = (tx.feeType ?? '').trim().toLowerCase();
  final isEducation = paymentType.contains('school') ||
      paymentType.contains('college') ||
      paymentType.contains('education') ||
      feeTypeLower.contains('school') ||
      feeTypeLower.contains('college') ||
      feeTypeLower.contains('education');
  if (isEducation) {
    // Resolve recipient name from customer_params where label == "Recipient Name"
    String recipientName = '';
    final TransactionCustomerParam fallbackParam = TransactionCustomerParam(label: '', value: '');
    final TransactionCustomerParam recipientParam = tx.customerParams.firstWhere(
      (p) => p.label.trim().toLowerCase() == 'recipient name',
      orElse: () => fallbackParam,
    );
    if (recipientParam.value.trim().isNotEmpty) {
      recipientName = recipientParam.value.trim();
    }
    // Fallback to maskedIdentifier if still empty
    if (recipientName.isEmpty && maskedIdentifier.isNotEmpty) {
      recipientName = maskedIdentifier;
    }

    // Fee Type from payment_type field (API key: payment_type)
    final feeTypeDisplay = tx.paymentType.trim();

    return [
      TransactionCustomerParam(
        label: 'Recipient Name',
        value: recipientName.isNotEmpty ? recipientName : '-',
      ),
      TransactionCustomerParam(
        label: 'Fee Type',
        value: feeTypeDisplay.isNotEmpty ? feeTypeDisplay : '-',
      ),
    ];
  }

  // Generic flow for other transaction types:
  final explicit = tx.customerParams
      .where(
        (item) => item.label.trim().isNotEmpty && item.value.trim().isNotEmpty,
      )
      .toList();
  final withPaymentType = ensurePaymentTypeCustomerParam(
    params: explicit,
    paymentType: tx.paymentType,
  );
  if (withPaymentType.isNotEmpty) return withPaymentType;

  return [
    TransactionCustomerParam(
      label: 'Payment to',
      value: billerName.isNotEmpty ? billerName : 'Transaction',
    ),
    TransactionCustomerParam(
      label: 'Payment Type',
      value: tx.paymentType.trim().isNotEmpty
          ? tx.paymentType.trim()
          : (billerName.isNotEmpty ? billerName : 'Transaction'),
    ),
  ];
}

List<_DetailValueRow> _resolveBreakdownRows(TransactionHistoryEntry tx) {
  final composed = composeTransactionAmountBreakdown(
    source: {
      'payment_type': tx.paymentType,
      'amount': tx.amount,
      'platform_fees': tx.platformFees,
      'total_amount_charged': tx.totalAmountCharged,
      'payable_amount': tx.amountBreakdown['payable_amount'] ??
          tx.amountBreakdown['Payable Amount'] ??
          tx.amountBreakdown['Total'] ??
          tx.totalAmountCharged,
      'service_charge': tx.amountBreakdown['service_charge'] ??
          tx.amountBreakdown['Service Charge'],
      'gst_on_service_charge': tx.amountBreakdown['gst_on_service_charge'] ??
          tx.amountBreakdown['GST on Service Charge'],
    },
    existingBreakdown: tx.amountBreakdown,
    fallbackBillAmount: tx.amount,
    fallbackTotal: tx.totalAmountCharged.trim().isNotEmpty
        ? tx.totalAmountCharged
        : tx.amount,
    billAmountLabel: tx.paymentType.trim().toLowerCase().contains('recharge')
        ? 'Recharge Amount'
        : 'Bill Amount',
  );

  String mappedValue(List<String> labels) {
    for (final label in labels) {
      for (final entry in composed.entries) {
        if (entry.key.trim().toLowerCase() == label.toLowerCase()) {
          return _formatBreakdownValue(entry.value);
        }
      }
    }
    return '';
  }

  final isRecharge = tx.paymentType.trim().toLowerCase().contains('recharge');
  final reserved = {
    'bill amount',
    'recharge amount',
    'service charge',
    'gst on service charge',
    'total',
    'payable_amount',
    'payable amount',
  };

  return [
    _DetailValueRow(
      label: isRecharge ? 'Recharge Amount' : 'Bill Amount',
      value: mappedValue(['Bill Amount', 'Recharge Amount']),
    ),
    _DetailValueRow(
      label: 'Service Charge',
      value: mappedValue(['Service Charge']),
    ),
    _DetailValueRow(
      label: 'GST on Service Charge',
      value: mappedValue(['GST on Service Charge']),
    ),
    ...composed.entries
        .where(
          (entry) => !reserved.contains(entry.key.trim().toLowerCase()),
        )
        .map(
          (entry) => _DetailValueRow(
            label: entry.key,
            value: _formatBreakdownValue(entry.value),
          ),
        ),
    _DetailValueRow(
      label: 'Total',
      value: mappedValue(['Total', 'payable_amount', 'Payable Amount']),
      emphasize: true,
    ),
  ];
}

class _TransactionResultCard extends StatelessWidget {
  const _TransactionResultCard({
    required this.primaryParam,
    required this.secondaryParam,
    required this.detailRows,
    required this.breakdownRows,
  });

  final TransactionCustomerParam primaryParam;
  final TransactionCustomerParam secondaryParam;
  final List<_DetailValueRow> detailRows;
  final List<_DetailValueRow> breakdownRows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: 18.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CardHeading(
                  label: primaryParam.label,
                  value: primaryParam.value,
                  alignEnd: false,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _CardHeading(
                  label: secondaryParam.label,
                  value: secondaryParam.value,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(color: AppColors.lightBorder.withOpacity(0.75), height: 1),
          SizedBox(height: 6.h),
          ...detailRows.map(
            (row) => _CardDetailRow(
              row: row,
              fullWidthValueAlignment: true,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Amount Breakdown',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5.sp,
                ),
          ),
          SizedBox(height: 4.h),
          ...breakdownRows.map(
            (row) => _CardDetailRow(
              row: row,
              fullWidthValueAlignment: true,
              showTopDivider: row.emphasize,
              horizontalInset: row.emphasize ? 0 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({
    required this.label,
    required this.value,
    required this.alignEnd,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.75),
                fontSize: 9.5.sp,
              ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11.5.sp,
              ),
        ),
      ],
    );
  }
}

class _CardDetailRow extends StatelessWidget {
  const _CardDetailRow({
    required this.row,
    this.fullWidthValueAlignment = false,
    this.showTopDivider = false,
    this.horizontalInset,
  });

  final _DetailValueRow row;
  final bool fullWidthValueAlignment;
  final bool showTopDivider;
  final double? horizontalInset;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: row.emphasize
                        ? AppColors.textPrimary
                        : AppColors.textPrimary.withOpacity(0.85),
                    fontWeight:
                        row.emphasize ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10.5.sp,
                  ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight:
                              row.emphasize ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 10.5.sp,
                        ),
                  ),
                ),
                if (row.copyable) ...[
                  SizedBox(width: 4.w),
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: row.value));
                      AppSnackbar.show('Copied to clipboard');
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 13.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final rowWidget = showTopDivider
        ? Column(
            children: [
              Divider(
                color: AppColors.lightBorder.withOpacity(0.75),
                height: 12.h,
                thickness: 1,
              ),
              content,
            ],
          )
        : content;

    if (horizontalInset == null) return rowWidget;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset!),
      child: rowWidget,
    );
  }
}

class _ResultActionButton extends StatelessWidget {
  const _ResultActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(width: 96.w,
        child: Column(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFE8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x0F000000),
                    blurRadius: 10.r,
                    offset: Offset(0.w, 4.h),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 18.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 9.sp,
                    height: 1.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailValueRow {
  const _DetailValueRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool copyable;
  final bool emphasize;
}

double _measureTextHeight(
  BuildContext context, {
  required String text,
  required TextStyle style,
  required double maxWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: maxWidth);
  return painter.size.height;
}

class _StatusMeta {
  const _StatusMeta({
    required this.title,
    required this.iconAsset,
    required this.gradient,
    this.message = '',
    this.messageTitle = '',
    this.messageIndicatorGradient = const [],
    this.messageBackgroundColor = const Color(0xFF09301A),
  });

  final String title;
  final String iconAsset;
  final List<Color> gradient;
  final String message;
  final String messageTitle;
  final List<Color> messageIndicatorGradient;
  final Color messageBackgroundColor;
}

_StatusMeta _statusMeta(
  String status, {
  required String refundAmount,
}) {
  final value = status.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (value.contains('SUCCESS')) {
    return _StatusMeta(
      title: 'Transaction Successful',
      iconAsset: FileConstants.successIcon,
      gradient: const [
        Color(0xFF004C1E),
        Color(0xFF149248),
        Color(0xFF136E3C),
        Color(0xFF007340),
      ],
    );
  }

  if (value.contains('PROCESS') ||
      (value.contains('PENDING') && !value.contains('REFUND'))) {
    return _StatusMeta(
      title: 'Transaction Pending',
      iconAsset: FileConstants.pendingIcon,
      gradient: const [
        Color(0xFFD3A30E),
        Color(0xFFD3A30E),
        Color(0xFF844E07),
        Color(0xFFD3A30E),
      ],
      message:
          'Your transaction is currently pending. Please wait a few moments while we confirm your payment status. If the amount has been deducted, it will be updated shortly.',
      messageBackgroundColor: const Color(0xFF5D3A00),
    );
  }

  if (value.contains('REFUND') &&
      (value.contains('PENDING') || value == 'REFUND' || value.contains('INITIAT'))) {
    return _StatusMeta(
      title: 'Transaction Failed',
      iconAsset: FileConstants.failedIcon,
      gradient: const [
        Color(0xFFFF5D5D),
        Color(0xFFC04242),
        Color(0xFF981919),
        Color(0xFF8E0303),
      ],
      messageTitle: 'Refund Initiated',
      message:
          'Your transaction failed. A refund of $refundAmount has been initiated and is expected to be credited within 3–5 business days.',
      messageIndicatorGradient: const [
        Color(0xFFFB8A67),
        Color(0xFFDD5428),
      ],
      messageBackgroundColor: const Color(0xFF6D120E),
    );
  }

  if (value.contains('REFUND')) {
    return _StatusMeta(
      title: 'Transaction Failed',
      iconAsset: FileConstants.failedIcon,
      gradient: const [
        Color(0xFFFF5D5D),
        Color(0xFFC04242),
        Color(0xFF981919),
        Color(0xFF8E0303),
      ],
      messageTitle: 'Refund Completed',
      message:
          '$refundAmount has been successfully refunded to your original payment method. No further action is required.',
      messageIndicatorGradient: const [
        Color(0xFF60EB97),
        Color(0xFF058337),
      ],
      messageBackgroundColor: const Color(0xFF6D120E),
    );
  }

  if (value.contains('FAIL')) {
    return _StatusMeta(
      title: 'Transaction Failed',
      iconAsset: FileConstants.failedIcon,
      gradient: const [
        Color(0xFFFF5D5D),
        Color(0xFFC04242),
        Color(0xFF981919),
        Color(0xFF8E0303),
      ],
      message:
          'Unfortunately, your transaction could not be completed. Please check your payment details or try again.',
      messageBackgroundColor: const Color(0xFF6D120E),
    );
  }

  return _StatusMeta(
    title: 'Transaction Details',
    iconAsset: FileConstants.successIcon,
    gradient: const [
      Color(0xFF004C1E),
      Color(0xFF149248),
      Color(0xFF136E3C),
      Color(0xFF007340),
    ],
  );
}

String _resolveReceiptTransactionId({
  required String refId,
  required String txnId,
}) {
  return ReceiptActions.resolveReceiptTransactionId(refId: refId, txnId: txnId);
}

String _resolveSupportTransactionType(TransactionHistoryEntry tx) {
  final paymentType = tx.paymentType.trim().toLowerCase();
  if (paymentType.contains('education')) return 'EDUCATION';
  if (paymentType.contains('gold') ||
      paymentType.contains('silver') ||
      paymentType.contains('metal')) {
    return 'METAL';
  }
  return 'BBPS';
}

String _formatAmount(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.startsWith('₹') ? trimmed : '₹$trimmed';
}

String _formatBreakdownValue(dynamic raw) {
  if (raw == null) return '';
  if (raw is num) {
    final value =
        raw % 1 == 0 ? raw.toStringAsFixed(0) : raw.toStringAsFixed(2);
    return '₹$value';
  }
  final trimmed = raw.toString().trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('₹')) return trimmed;
  final parsed = double.tryParse(trimmed.replaceAll(',', ''));
  if (parsed == null) return trimmed;
  final value =
      parsed % 1 == 0 ? parsed.toStringAsFixed(0) : parsed.toStringAsFixed(2);
  return '₹$value';
}

String _formatHeaderDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  final normalized = value.contains(' ') ? value.replaceFirst(' ', 'T') : value;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return value;
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final day = parsed.day.toString();
  final month = months[parsed.month - 1];
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final ampm = parsed.hour >= 12 ? 'pm' : 'am';
  return '$day $month ${parsed.year}, $hour:$minute$ampm';
}
