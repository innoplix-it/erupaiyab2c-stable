import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/app_colors.dart';
import '../../models/bill_response_model.dart';
import '../credit_card/credit_card_figma_metrics.dart';
import 'credit_card_pay_now_option_card.dart';

enum CreditCardPayNowAmountType {
  total,
  minimum,
  custom,
}

class CreditCardPayNowSection extends StatelessWidget {
  const CreditCardPayNowSection({
    super.key,
    required this.bill,
    required this.totalOutstanding,
    required this.minimumDue,
    required this.selected,
    required this.onChanged,
    required this.amountController,
  });

  final BillResponse bill;
  final double totalOutstanding;
  final double? minimumDue;
  final CreditCardPayNowAmountType selected;
  final ValueChanged<CreditCardPayNowAmountType> onChanged;
  final TextEditingController amountController;

  @override
  Widget build(BuildContext context) {
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    final dueOn = _formatDueOn(bill.dueDate);
    final billDate = _formatLongDate(bill.billDate);
    final customerName = bill.accountHolderName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CreditCardBillInfoCard(
          customerName: customerName,
          billDate: billDate,
          minimumDue: minimumDue,
          totalOutstanding: totalOutstanding,
        ),
        SizedBox(height: sx(20)),
        Row(
          children: [
            Text(
              'Bill Amount',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: sx(14),
              ),
            ),
            SizedBox(width: sx(10)),
            Container(
              width: 1,
              height: sx(14),
              color: AppColors.lightBorder,
            ),
            SizedBox(width: sx(10)),
            Expanded(
              child: Text(
                // Figma: "Due on 11 May" (day + month, no year).
                dueOn.isEmpty ? '' : 'Due on $dueOn',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: sx(13),
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: sx(10)),
        _AmountField(
          controller: amountController,
          onChanged: (_) => onChanged(CreditCardPayNowAmountType.custom),
        ),
        SizedBox(height: sx(12)),
        Row(
          children: [
            Expanded(
              child: CreditCardPayNowOptionCard(
                title: 'Minimum Due',
                amount: _formatCurrency(minimumDue ?? 0),
                isSelected: selected == CreditCardPayNowAmountType.minimum,
                onTap: minimumDue == null
                    ? null
                    : () => onChanged(CreditCardPayNowAmountType.minimum),
              ),
            ),
            SizedBox(width: sx(12)),
            Expanded(
              child: CreditCardPayNowOptionCard(
                title: 'Total Amount',
                amount: _formatCurrency(totalOutstanding),
                isSelected: selected == CreditCardPayNowAmountType.total,
                onTap: () => onChanged(CreditCardPayNowAmountType.total),
              ),
            ),
          ],
        ),
        // Consent lives above the fixed Proceed CTA (BharatConnectConsentCard).
      ],
    );
  }

  String _formatCurrency(double value) {
    final rounded = value.round();
    final asText = rounded.toString();
    final withCommas = asText.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₹$withCommas';
  }

  String _formatDueOn(String raw) {
    final parsed = _tryParseDate(raw);
    if (parsed == null) return raw.trim();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${parsed.day} ${months[parsed.month - 1]}';
  }

  String _formatLongDate(String raw) {
    final parsed = _tryParseDate(raw);
    if (parsed == null) return raw.trim();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  DateTime? _tryParseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final normalized =
        value.contains(' ') ? value.replaceFirst(' ', 'T') : value;
    return DateTime.tryParse(normalized) ?? DateTime.tryParse(value);
  }
}

class _CreditCardBillInfoCard extends StatelessWidget {
  const _CreditCardBillInfoCard({
    required this.customerName,
    required this.billDate,
    required this.minimumDue,
    required this.totalOutstanding,
  });

  final String customerName;
  final String billDate;
  final double? minimumDue;
  final double totalOutstanding;

  @override
  Widget build(BuildContext context) {
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    double sy(double v) => CreditCardFigmaMetrics.sy(context, v);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: sx(16), vertical: sy(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sx(12)),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: sx(8),
            offset: Offset(0, sx(2)),
          ),
        ],
      ),
      child: Column(
        children: [
          _ColonRow(label: 'Customer Name', value: customerName),
          _ColonRow(label: 'Bill Date', value: billDate),
          _ColonRow(
            label: 'Minimum Amount Due',
            value: minimumDue == null ? '' : _rupee(minimumDue!),
          ),
          _ColonRow(
            label: 'Current Outstanding...',
            value: _rupee(totalOutstanding),
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _rupee(double value) {
    final asText = value.round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₹$asText';
  }
}

class _ColonRow extends StatelessWidget {
  const _ColonRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : sx(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF71717A),
                fontWeight: FontWeight.w500,
                fontSize: sx(12),
              ),
            ),
          ),
          Text(
            ' :  ',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: sx(12),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: sx(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    double sy(double v) => CreditCardFigmaMetrics.sy(context, v);
    // Figma bill amount field: 18px base + 10px per product request.
    final amountFontSize = sx(28);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixText: '₹ ',
        prefixStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: amountFontSize,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(sx(12)),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(sx(12)),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(sx(12)),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: sx(16), vertical: sy(16)),
      ),
      style: GoogleFonts.plusJakartaSans(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: amountFontSize,
      ),
    );
  }
}
