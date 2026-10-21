// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../components/credit_card/credit_card_figma_metrics.dart';
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
            height: CreditCardFigmaMetrics.sy(context, 150),
            backgroundColor: meta.color,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(CreditCardFigmaMetrics.s(context, 16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(CreditCardFigmaMetrics.s(context, 24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCard(tx: tx),
                    SizedBox(height: CreditCardFigmaMetrics.sy(context, 12)),
                    _InfoSection(title: 'Payment Details', rows: infoRows),
                    SizedBox(height: CreditCardFigmaMetrics.sy(context, 12)),
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
      padding: EdgeInsets.all(CreditCardFigmaMetrics.s(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CreditCardFigmaMetrics.s(context, 16)),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: CreditCardFigmaMetrics.s(context, 12),
            offset: Offset(CreditCardFigmaMetrics.s(context, 0), CreditCardFigmaMetrics.sy(context, 6)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: CreditCardFigmaMetrics.s(context, 48),
            width: CreditCardFigmaMetrics.s(context, 48),
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
          SizedBox(width: CreditCardFigmaMetrics.s(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.billerName.isNotEmpty ? tx.billerName : 'Card',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: CreditCardFigmaMetrics.sy(context, 4)),
                Text(
                  tx.transactionTime,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Text(
              _formatAmount(tx.amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
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
        SizedBox(height: CreditCardFigmaMetrics.sy(context, 8)),
        ...rows.map(
          (row) => Padding(
            padding: EdgeInsets.only(bottom: CreditCardFigmaMetrics.sy(context, 8)),
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
        SizedBox(width: CreditCardFigmaMetrics.s(context, 12)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
        ),
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
      padding: EdgeInsets.only(bottom: CreditCardFigmaMetrics.sy(context, 10)),
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
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
