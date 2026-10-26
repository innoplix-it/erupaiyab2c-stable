// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';

import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../profile/models/support_latest_transaction.dart';
import '../../profile/utils/receipt_actions.dart';
import '../../profile/views/create_support_ticket_screen.dart';
import '../models/credit_card_transaction.dart';

class CreditCardTransactionDetailScreen extends StatelessWidget {
  const CreditCardTransactionDetailScreen({super.key, this.transaction});

  final CreditCardTransaction? transaction;

  @override
  Widget build(BuildContext context) {
    final tx = transaction ??
        const CreditCardTransaction(
          paymentStatus: '',
          billerName: '',
          maskedIdentifier: '',
          amount: '',
          platformFees: '',
          totalAmountCharged: '',
          paymentTransactionId: '',
          bankReferenceId: '',
          transactionTime: '',
          method: '',
          methodIcon: '',
          paymentMode: '',
          vpa: '',
          rrn: '',
          icon: '',
        );

    final status = tx.paymentStatus.trim().toUpperCase();
    final totalAmount =
        tx.totalAmountCharged.trim().isNotEmpty ? tx.totalAmountCharged : tx.amount;
    final statusMeta = _resolveStatusMeta(status, refundAmount: _fmtAmt(totalAmount));

    // Resolve masked card number: show as "**** **** **** XXXX"
    final rawMasked = tx.maskedIdentifier.trim();
    final digits = rawMasked.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : (rawMasked.length >= 4
            ? rawMasked.substring(rawMasked.length - 4)
            : rawMasked);
    final maskedCardDisplay =
        last4.isNotEmpty ? '**** **** **** $last4' : (rawMasked.isNotEmpty ? rawMasked : '—');

    // Header params: Payment to (biller) + Credit Card Number
    const primaryLabel = 'Payment to';
    final primaryValue = tx.billerName.isNotEmpty ? tx.billerName : '—';
    const secondaryLabel = 'Credit Card Number';
    final secondaryValue = maskedCardDisplay;

    // Detail rows: amount, method, IDs
    final paymentMethod =
        tx.method.trim().isNotEmpty ? tx.method.trim() : tx.paymentMode.trim();
    final pgTxnId = tx.paymentTransactionId.trim();
    final bankRefId = tx.bankReferenceId.trim();
    final rrn = tx.rrn.trim();
    final vpa = tx.vpa.trim();
    final paymentMode = tx.paymentMode.trim();

    final detailRows = <_DetailValueRow>[
      _DetailValueRow(label: 'Amount', value: _fmtAmt(tx.amount)),
      if (paymentMethod.isNotEmpty)
        _DetailValueRow(label: 'Payment Method', value: paymentMethod),
      if (pgTxnId.isNotEmpty)
        _DetailValueRow(label: 'Transaction ID', value: pgTxnId, copyable: true),
      if (bankRefId.isNotEmpty)
        _DetailValueRow(label: 'Bank Reference ID', value: bankRefId, copyable: true),
      if (rrn.isNotEmpty)
        _DetailValueRow(label: 'RRN', value: rrn, copyable: true),
      if (vpa.isNotEmpty && vpa != paymentMethod)
        _DetailValueRow(label: 'VPA', value: vpa, copyable: true),
      if (paymentMode.isNotEmpty && paymentMode != paymentMethod)
        _DetailValueRow(label: 'Payment Mode', value: paymentMode),
    ];

    // Breakdown rows
    final showPlatformFees = _hasPositiveAmount(tx.platformFees);
    final breakdownRows = <_DetailValueRow>[
      _DetailValueRow(label: 'Bill Amount', value: _fmtAmt(tx.amount)),
      if (showPlatformFees)
        _DetailValueRow(label: 'Platform Fees', value: _fmtAmt(tx.platformFees)),
      _DetailValueRow(
        label: 'Total',
        value: _fmtAmt(totalAmount),
        emphasize: true,
      ),
    ];

    // Support transaction
    final receiptId = pgTxnId.isNotEmpty ? pgTxnId : bankRefId;
    final supportTx = SupportLatestTransaction(
      id: receiptId,
      paymentType: 'Credit Card',
      billerName: tx.billerName.trim(),
      amount: totalAmount.trim(),
      status: tx.paymentStatus.trim(),
      date: tx.transactionTime.trim(),
      type: 'BBPS',
      transactionId: pgTxnId,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final hasMsg = statusMeta.message.isNotEmpty;
          final topPadding = MediaQuery.paddingOf(context).top;
          final headerTop = topPadding + 40.h;
          final hPad = 24.w;
          final sectionGap = 10.h;
          final headerWidth = constraints.maxWidth - (hPad * 2);

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
              TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10.5.sp);
          final msgStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    height: 1.45,
                    fontSize: 9.5.sp,
                  ) ??
              TextStyle(color: Colors.white, height: 1.45, fontSize: 9.5.sp);

          final titleH = _measureTextH(
            context,
            text: statusMeta.title,
            style: titleStyle,
            maxWidth: headerWidth,
          );
          final dateH = _measureTextH(
            context,
            text: _formatHeaderDate(tx.transactionTime),
            style: dateStyle,
            maxWidth: headerWidth,
          );
          final msgH = hasMsg
              ? _measureTextH(
                  context,
                  text: statusMeta.message,
                  style: msgStyle,
                  maxWidth: headerWidth - 24.w,
                )
              : 0.0;
          final msgContainerH = hasMsg ? msgH + 18.h : 0.0;
          final headerContentH = 52.h +
              sectionGap +
              titleH +
              4.h +
              dateH +
              (hasMsg ? sectionGap + msgContainerH : 0.0);
          final cardTop = headerTop + headerContentH + sectionGap;
          final minH = 220.h;
          final computedH = cardTop + 24.h;
          final headerHeight = computedH < minH ? minH : computedH;

          return Stack(
            children: [
              // ── Background: gradient header + white body
              Column(
                children: [
                  Container(
                    height: headerHeight,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
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
                  const Expanded(child: ColoredBox(color: Colors.white)),
                ],
              ),

              // ── Back button
              Positioned(
                left: 12.w,
                top: MediaQuery.paddingOf(context).top + 8.h,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),

              // ── Header content: icon + title + date + optional message
              Positioned(
                left: hPad,
                right: hPad,
                top: headerTop,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
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
                    Text(statusMeta.title,
                        textAlign: TextAlign.center, style: titleStyle),
                    SizedBox(height: 4.h),
                    Text(_formatHeaderDate(tx.transactionTime),
                        textAlign: TextAlign.center, style: dateStyle),
                    if (hasMsg) ...[
                      SizedBox(height: sectionGap),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 9.h),
                        decoration: BoxDecoration(
                          color: statusMeta.messageBackgroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(statusMeta.message,
                            textAlign: TextAlign.center, style: msgStyle),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Scrollable content card
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
                              _CcResultCard(
                                primaryLabel: primaryLabel,
                                primaryValue: primaryValue,
                                secondaryLabel: secondaryLabel,
                                secondaryValue: secondaryValue,
                                detailRows: detailRows,
                                breakdownRows: breakdownRows,
                              ),
                              SizedBox(height: 14.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ActionButton(
                                    icon: Icons.headset_mic_outlined,
                                    label: 'Contact Support',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CreateSupportTicketScreen(
                                            transaction: supportTx,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (receiptId.isNotEmpty) ...[
                                    _ActionButton(
                                      icon: Icons.share_outlined,
                                      label: 'Share Receipt',
                                      onTap: () => ReceiptActions
                                          .handleReceiptAction(
                                        context,
                                        transactionId: receiptId,
                                        action: ReceiptAction.share,
                                      ),
                                    ),
                                    _ActionButton(
                                      icon: Icons.receipt_long_outlined,
                                      label: 'Download Receipt',
                                      onTap: () => ReceiptActions
                                          .handleReceiptAction(
                                        context,
                                        transactionId: receiptId,
                                        action: ReceiptAction.download,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      CustomElevatedButton(
                        onPressed: () => context.pop(),
                        label: 'Done',
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
  }
}

// ─── Result card ─────────────────────────────────────────────────────────────

class _CcResultCard extends StatelessWidget {
  const _CcResultCard({
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.detailRows,
    required this.breakdownRows,
  });

  final String primaryLabel;
  final String primaryValue;
  final String secondaryLabel;
  final String secondaryValue;
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
                    label: primaryLabel,
                    value: primaryValue,
                    alignEnd: false),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _CardHeading(
                    label: secondaryLabel,
                    value: secondaryValue,
                    alignEnd: true),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(
              color: AppColors.lightBorder.withOpacity(0.75), height: 1),
          SizedBox(height: 6.h),
          ...detailRows.map(
            (row) => _CardDetailRow(row: row, fullWidthValueAlignment: true),
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

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

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
              children: [
                Flexible(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: row.emphasize
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 10.5.sp,
                        ),
                  ),
                ),
                if (row.copyable) ...[
                  SizedBox(width: 4.w),
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(
                          ClipboardData(text: row.value));
                      AppSnackbar.show('Copied to clipboard');
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: Icon(Icons.copy_rounded,
                          size: 13.sp, color: AppColors.textPrimary),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
      child: SizedBox(
        width: 96.w,
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
              child: Icon(icon, color: AppColors.primary, size: 18.sp),
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

// ─── Data model ──────────────────────────────────────────────────────────────

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

// ─── Status meta ─────────────────────────────────────────────────────────────

class _CcStatusMeta {
  const _CcStatusMeta({
    required this.title,
    required this.iconAsset,
    required this.gradient,
    this.message = '',
    this.messageBackgroundColor = const Color(0xFF09301A),
  });

  final String title;
  final String iconAsset;
  final List<Color> gradient;
  final String message;
  final Color messageBackgroundColor;
}

_CcStatusMeta _resolveStatusMeta(
  String status, {
  required String refundAmount,
}) {
  final s = status.trim().toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');

  if (s.contains('SUCCESS')) {
    return _CcStatusMeta(
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

  if (s.contains('PROCESS') ||
      (s.contains('PENDING') && !s.contains('REFUND'))) {
    return _CcStatusMeta(
      title: 'Transaction Pending',
      iconAsset: FileConstants.pendingIcon,
      gradient: const [
        Color(0xFFD3A30E),
        Color(0xFFD3A30E),
        Color(0xFF844E07),
        Color(0xFFD3A30E),
      ],
      message:
          'Your transaction is currently pending. Please wait a few moments while we confirm your payment status.',
      messageBackgroundColor: const Color(0xFF5D3A00),
    );
  }

  if (s.contains('FAIL')) {
    return _CcStatusMeta(
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

  // Default: treat as successful
  return _CcStatusMeta(
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

// ─── Helpers ─────────────────────────────────────────────────────────────────

bool _hasPositiveAmount(String raw) {
  final v = double.tryParse(raw.trim()) ?? 0;
  return v > 0;
}

String _fmtAmt(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final parsed = double.tryParse(trimmed);
  if (parsed == null) return trimmed.startsWith('₹') ? trimmed : '₹$trimmed';
  return '₹${parsed.toStringAsFixed(2)}';
}

double _measureTextH(
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

String _formatHeaderDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  final normalized =
      value.contains(' ') ? value.replaceFirst(' ', 'T') : value;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return value;
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final day = parsed.day.toString();
  final month = months[parsed.month - 1];
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final ampm = parsed.hour >= 12 ? 'pm' : 'am';
  return '$day $month ${parsed.year}, $hour:$minute$ampm';
}
