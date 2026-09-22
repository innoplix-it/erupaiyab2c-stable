// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../models/digital_gold_preview.dart';
import '../models/digital_metal.dart';

class DigitalGoldSellConfirmView extends ConsumerStatefulWidget {
  const DigitalGoldSellConfirmView({
    super.key,
    required this.amount,
    required this.preview,
    required this.isSellingInRupees,
    this.metal = DigitalMetal.gold,
  });

  final double amount;
  final DigitalGoldPreview preview;
  final bool isSellingInRupees;
  final DigitalMetal metal;

  @override
  ConsumerState<DigitalGoldSellConfirmView> createState() =>
      _DigitalGoldSellConfirmViewState();
}

class _DigitalGoldSellConfirmViewState
    extends ConsumerState<DigitalGoldSellConfirmView> {
  int _selectedMethod = 0;

  @override
  Widget build(BuildContext context) {
    final theme = DigitalMetalTheme.of(widget.metal);

    final rupees =
        widget.isSellingInRupees ? widget.amount : (widget.preview.totalAmount);
    final grams = widget.isSellingInRupees
        ? (widget.preview.myGoldBalance)
        : widget.amount;

    final gramText = grams <= 0 ? '--' : '${grams.toStringAsFixed(4)}g';
    final rupeeText = rupees <= 0 ? '--' : '₹${rupees.toStringAsFixed(0)}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 12.w, 8.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Sell ${theme.label}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                    ),
                  ),
                  Image.asset(
                    FileConstants.bharatConnectColor,
                    height: 20.h,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 6.w),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1.h, color: AppColors.lightBorder.withOpacity(0.6)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 140.h),
              children: [
                Image.asset(
                  FileConstants.sellGoldBanner,
                  height: 60.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 14.h),
                Text(
                  'Withdrawing From Digital Gold',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 10.h),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                    children: [
                      TextSpan(text: gramText),
                      TextSpan(
                        text: ' for ',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(0.55),
                            ),
                      ),
                      TextSpan(text: rupeeText),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Selling at: ₹${widget.preview.totalAmount.toStringAsFixed(2)}/gm',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Saved Payment Methods',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: AppColors.lightBorder.withOpacity(0.6),
                    ),
                  ),
                  child: Column(
                    children: [
                      _UpiRow(
                        label: 'username@ybl',
                        selected: _selectedMethod == 0,
                        onTap: () => setState(() => _selectedMethod = 0),
                      ),
                      SizedBox(height: 12.h),
                      _UpiRow(
                        label: 'username@ybl',
                        selected: _selectedMethod == 1,
                        onTap: () => setState(() => _selectedMethod = 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: AppColors.lightBorder.withOpacity(0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 18.r,
                        offset: Offset(0.w, 10.h),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add a new UPI ID',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'you need to have a registered UPI ID',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black.withOpacity(0.55),
                                  ),
                            ),
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                Image.asset(
                                  FileConstants.upi,
                                  width: 18.r,
                                  height: 18.r,
                                ),
                                SizedBox(width: 8.w),
                                Image.asset(
                                  FileConstants.npci,
                                  width: 18.r,
                                  height: 18.r,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 22.r,
                        height: 22.r,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE85A2C),
                        ),
                        child: Icon(Icons.add,
                            color: Colors.white, size: 22.r),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Image.asset(
                      FileConstants.resetPinIcon,
                      width: 25.r,
                      height: 25.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Your Money Is Safe & Secure',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 16.h),
        child: SafeArea(
          top: false,
          child: CustomElevatedButton(
            onPressed: () => context.push(
              '${RouteConstants.digitalGoldSellSuccess}?metal=${theme.queryValue}',
            ),
            label: 'Confirm & Withdraw',
            uppercaseLabel: false,
            height: 40.h,
            backgroundColor: const Color(0xFFE85A2C),
          ),
        ),
      ),
    );
  }
}

class _UpiRow extends StatelessWidget {
  const _UpiRow({
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
        children: [
          Container(
            width: 30.r,
            height: 30.r,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6D28D9),
            ),
            child: const Center(
              child: Text(
                'पे',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
            ),
          ),
          Container(
            width: 18.r,
            height: 18.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? const Color(0xFFE85A2C)
                    : Colors.black.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10.r,
                      height: 10.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE85A2C),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
