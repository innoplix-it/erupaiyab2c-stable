import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/file_constants.dart';
import '../../models/bill_response_model.dart';
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
        SizedBox(height: 16.h),
        Row(
          children: [
            Text(
              'Bill Amount',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(width: 12.w),
            Container(
              width: 1,
              height: 16.h,
              color: AppColors.lightBorder,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                dueOn.isEmpty ? '' : 'Due on $dueOn',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFB77023),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _AmountField(
          controller: amountController,
          onChanged: (_) => onChanged(CreditCardPayNowAmountType.custom),
        ),
        SizedBox(height: 14.h),
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
            SizedBox(width: 12.w),
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
        SizedBox(height: 18.h),
        const _ConsentNote(
          text:
              'By Proceeding Further, You Allow Erupaiya To Fetch Your Current And Future Balances And Remind You',
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    final rounded = value.round();
    final asText = rounded.toString();
    return '₹$asText';
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          _ColonRow(label: 'Customer Name', value: customerName),
          _ColonRow(label: 'Bill Date', value: billDate),
          _ColonRow(
            label: 'Minimum Amount Due',
            value: minimumDue == null ? '' : '₹${minimumDue!.round()}',
          ),
          _ColonRow(
            label: 'Current Outstanding',
            value: '₹${totalOutstanding.round()}',
          ),
        ],
      ),
    );
  }
}

class _ColonRow extends StatelessWidget {
  const _ColonRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
          Text(
            ':',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixText: '₹ ',
        prefixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _ConsentNote extends StatelessWidget {
  const _ConsentNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Image.asset(
            FileConstants.bharatConnectColor,
            height: 16.h,
            width: 50.w,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  fontSize: 10.sp),
            ),
          ),
        ],
      ),
    );
  }
}
