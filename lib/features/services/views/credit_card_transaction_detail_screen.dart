// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/my_app_bar.dart';
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
    final meta = _statusMeta(tx.paymentStatus.trim().toUpperCase());
    final totalAmount = tx.totalAmountCharged.trim().isNotEmpty
        ? tx.totalAmountCharged
        : tx.amount;
    final showPlatformFees = _hasAmount(tx.platformFees);
    final infoRows = <_InfoRow>[
      _InfoRow(label: 'Bill Amount', value: _formatAmount(tx.amount)),
      if (showPlatformFees)
        _InfoRow(label: 'Platform Fees', value: _formatAmount(tx.platformFees)),
      _InfoRow(
        label: 'Total Amount',
        value: _formatAmount(totalAmount),
        emphasize: true,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: meta.label,
            height: 150.h,
            backgroundColor: meta.color,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCard(tx: tx),
                    SizedBox(height: 12.h),
                    _InfoSection(title: 'Payment Details', rows: infoRows),
                    SizedBox(height: 12.h),
                    if (tx.bankReferenceId.trim().isNotEmpty)
                      _CopyRow(
                        label: 'Bank Reference ID',
                        value: tx.bankReferenceId,
                      ),
                    if (tx.paymentTransactionId.trim().isNotEmpty)
                      _CopyRow(
                        label: 'Transaction ID',
                        value: tx.paymentTransactionId,
                      ),
                    if (tx.paymentMode.trim().isNotEmpty)
                      _InfoRow(
                        label: 'Payment Mode',
                        value: tx.paymentMode,
                      ),
                    if (tx.vpa.trim().isNotEmpty)
                      _InfoRow(label: 'VPA', value: tx.vpa),
                    if (tx.rrn.trim().isNotEmpty)
                      _InfoRow(label: 'RRN', value: tx.rrn),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.tx});

  final CreditCardTransaction tx;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48.r,
            width: 48.r,
            decoration: BoxDecoration(
              color: AppColors.lightBorder.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: tx.icon.trim().isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      tx.icon,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.credit_card),
                    ),
                  )
                : const Icon(Icons.credit_card),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.billerName.isNotEmpty ? tx.billerName : 'Card',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  tx.transactionTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          Text(
            _formatAmount(tx.amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        ...rows.map(
          (row) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: row,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusMeta {
  const _StatusMeta(this.label, this.color);

  final String label;
  final Color color;
}

_StatusMeta _statusMeta(String status) {
  switch (status) {
    case 'SUCCESS':
      return const _StatusMeta('Success', Color(0xFF0F8A4B));
    case 'FAILED':
    case 'FAIL':
      return const _StatusMeta('Failed', Color(0xFFD84315));
    case 'PENDING':
    case 'PROCESSING':
      return const _StatusMeta('Pending', Color(0xFFF6A623));
    default:
      return const _StatusMeta('Pending', Color(0xFFF6A623));
  }
}

bool _hasAmount(String raw) {
  final value = double.tryParse(raw) ?? 0;
  return value > 0;
}

String _formatAmount(String raw) {
  final value = double.tryParse(raw) ?? 0;
  return '₹${value.toStringAsFixed(2)}';
}
