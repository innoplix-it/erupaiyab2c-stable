// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';

class MyQrScreen extends StatelessWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F3),
      body: Stack(
        children: [
          const _MyQrBackground(),
          SafeArea(
            child: Column(
              children: [
                const _MyQrHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 24.h),
                    child: Column(
                      children: [
                        _QrCard(),
                        SizedBox(height: 18.h),
                        CustomElevatedButton(
                          onPressed: () {},
                          label: 'Send',
                          height: 48.h,
                          uppercaseLabel: false,
                        ),
                        SizedBox(height: 18.h),
                        const _InviteSection(),
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

class _MyQrBackground extends StatelessWidget {
  const _MyQrBackground();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 180.h,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFD6C7), Color(0xFFFFF7F3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const Expanded(child: ColoredBox(color: Color(0xFFFFF7F3))),
      ],
    );
  }
}

class _MyQrHeader extends StatelessWidget {
  const _MyQrHeader();

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
          Text(
            'Back',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '₹',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'e-ruppaiya',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColors.lightBorder),
          SizedBox(height: 14.h),
          Container(
            width: 230.w,
            height: 230.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Center(
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 140.sp,
                color: AppColors.textPrimary.withOpacity(0.2),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'ERUPAIYA1234567890',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Show This QR Code To Receive\nE-Coins In Your Wallet.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _InviteSection extends StatelessWidget {
  const _InviteSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: AppColors.lightBorder),
        SizedBox(height: 16.h),
        Text(
          'Invite Now',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 14.h),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InviteIcon(icon: Icons.whatshot),
            _InviteIcon(icon: Icons.camera_alt),
            _InviteIcon(icon: Icons.facebook),
            _InviteIcon(icon: Icons.message),
            _InviteIcon(icon: Icons.more_horiz),
          ],
        ),
      ],
    );
  }
}

class _InviteIcon extends StatelessWidget {
  const _InviteIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: const BoxDecoration(
          color: Color(0xFF0B4EA2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }
}
