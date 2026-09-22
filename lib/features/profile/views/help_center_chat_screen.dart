// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../components/help_center_option_chip.dart';
import '../models/help_center_option.dart';

class HelpCenterChatScreen extends StatelessWidget {
  const HelpCenterChatScreen({super.key});

  static const List<Map<String, dynamic>> _mockOptions = [
    {'id': 'payment', 'label': 'Payment & Transaction Issues'},
    {'id': 'app', 'label': 'App, Account, Or Login Issues'},
    {'id': 'biller', 'label': 'Bill/Biller Listing Issues'},
    {'id': 'refund', 'label': 'Refund Status Or Query'},
    {'id': 'other', 'label': 'Something Else'},
  ];

  @override
  Widget build(BuildContext context) {
    final options = HelpCenterOption.fromJsonList(_mockOptions);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F3),
      body: Stack(
        children: [
          const _HelpCenterBackground(),
          SafeArea(
            child: Column(
              children: [
                const _HelpCenterHeader(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        Text(
                          'Hello, John',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimary
                                        .withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'How We Can Help You ?',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        SizedBox(height: 24.h),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: options
                                  .map(
                                    (option) => Padding(
                                      padding: EdgeInsets.only(bottom: 12.h),
                                      child: HelpCenterOptionChip(
                                        label: option.label,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const _HelpCenterInputBar(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCenterBackground extends StatelessWidget {
  const _HelpCenterBackground();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120.h,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFE2D7), Color(0xFFFFF7F3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const Expanded(
          child: ColoredBox(color: Color(0xFFFFF7F3)),
        ),
      ],
    );
  }
}

class _HelpCenterHeader extends StatelessWidget {
  const _HelpCenterHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 6.h, 16.w, 6.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back, color: Colors.black, size: 22.sp),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              'Help Center (Chat With Us)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCenterInputBar extends StatelessWidget {
  const _HelpCenterInputBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
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
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type Here',
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.5),
                    ),
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Icon(
              Icons.send,
              size: 18.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
