// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../models/transaction_history_filter.dart';

class TransactionFilterScreen extends StatefulWidget {
  const TransactionFilterScreen({
    super.key,
    this.initialFilter,
  });

  final TransactionHistoryFilter? initialFilter;

  @override
  State<TransactionFilterScreen> createState() =>
      _TransactionFilterScreenState();
}

class _TransactionFilterScreenState extends State<TransactionFilterScreen> {
  String? _status;
  String? _paymentType;
  String? _month;
  DateTime? _fromDate;
  DateTime? _toDate;

  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilter;
    _status = initial?.status == 'ALL' ? null : initial?.status;
    _paymentType =
        initial?.paymentType == 'ALL' ? null : initial?.paymentType;
    _month = initial?.month;
    _fromDate = initial?.fromDate;
    _toDate = initial?.toDate;
    _fromController.text = _fromDate == null ? '' : _formatDate(_fromDate!);
    _toController.text = _toDate == null ? '' : _formatDate(_toDate!);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year}';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDate: initial ?? now,
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        _fromController.text = _formatDate(picked);
      } else {
        _toDate = picked;
        _toController.text = _formatDate(picked);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _status = null;
      _paymentType = null;
      _month = null;
      _fromDate = null;
      _toDate = null;
      _fromController.clear();
      _toController.clear();
    });
  }

  void _apply() {
    final filter = TransactionHistoryFilter(
      status: _status,
      paymentType: _paymentType,
      month: _month,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    Navigator.of(context).pop(filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Filter',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(
                      'Clear',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Payment Status'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: [
                        _ChoiceChip(
                          label: 'All',
                          selected: _status == null,
                          onTap: () => setState(() => _status = null),
                        ),
                        _ChoiceChip(
                          label: 'Success',
                          selected: _status == 'SUCCESS',
                          onTap: () => setState(() => _status = 'SUCCESS'),
                        ),
                        _ChoiceChip(
                          label: 'Failed',
                          selected: _status == 'FAILED',
                          onTap: () => setState(() => _status = 'FAILED'),
                        ),
                        _ChoiceChip(
                          label: 'Pending',
                          selected: _status == 'PENDING',
                          onTap: () => setState(() => _status = 'PENDING'),
                        ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    const _SectionTitle('Payment Type'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: [
                        _ChoiceChip(
                          label: 'All',
                          selected: _paymentType == null,
                          onTap: () => setState(() => _paymentType = null),
                        ),
                        _ChoiceChip(
                          label: 'UPI',
                          selected: _paymentType == 'UPI',
                          onTap: () => setState(() => _paymentType = 'UPI'),
                        ),
                        _ChoiceChip(
                          label: 'E-Coins',
                          selected: _paymentType == 'E-COINS',
                          onTap: () => setState(() => _paymentType = 'E-COINS'),
                        ),
                      ],
                    ),
                    SizedBox(height: 22.h),
                    const _SectionTitle('Month'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 14.w,
                      runSpacing: 10.h,
                      children: _monthOptions().map((option) {
                        final selected = _month == option.value;
                        return _MonthCheck(
                          label: option.label,
                          selected: selected,
                          onTap: () => setState(() => _month = option.value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 22.h),
                    const _SectionTitle('By Date Range'),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            controller: _fromController,
                            onTap: () => _pickDate(isFrom: true),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _DateField(
                            controller: _toController,
                            onTap: () => _pickDate(isFrom: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 16.h),
              child: SizedBox(
                width: double.infinity,
                height: 40.h,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_MonthOption> _monthOptions() {
    const labels = [
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
    final now = DateTime.now();
    return List.generate(now.month, (index) {
      final month = (index + 1).toString().padLeft(2, '0');
      final yearSuffix = now.year.toString().substring(2);
      return _MonthOption(
        label: '${labels[index]} $yearSuffix',
        value: '${now.year}-$month',
      );
    });
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.lightBorder;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _MonthCheck extends StatelessWidget {
  const _MonthCheck({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18.w,
            height: 18.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.lightBorder,
              ),
              color: selected ? AppColors.primary : Colors.white,
            ),
            child: selected
                ? Icon(Icons.check, size: 12.r, color: Colors.white)
                : null,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.onTap,
  });

  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: 'mm/dd/yy',
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: onTap,
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
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }
}

class _MonthOption {
  const _MonthOption({required this.label, required this.value});
  final String label;
  final String value;
}
