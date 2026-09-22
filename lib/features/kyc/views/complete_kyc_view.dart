// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../constants/file_constants.dart';
import 'kyc_verification_view.dart';

class CompleteKycView extends StatefulWidget {
  const CompleteKycView({super.key});

  @override
  State<CompleteKycView> createState() => _CompleteKycViewState();
}

class _CompleteKycViewState extends State<CompleteKycView> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await precacheImage(AssetImage(FileConstants.completeKycBg), context);
      if (!mounted) return;
      setState(() => _isLoaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Complete Your KYC',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: Colors.black),
          ),
        ],
      ),
      body: _isLoaded
          ? Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    FileConstants.completeKycBg,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 88.h),
                      child: Column(
                        children: [
                          SizedBox(height: 10.h),
                          Image.asset(
                            FileConstants.kycVerified,
                            width: 70.w,
                            height: 70.w,
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            'Complete Your KYC',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Verify your identity to unlock all\n'
                            'e-Rupaiya features.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.5,
                                ),
                          ),
                          SizedBox(height: 18.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                FileConstants.coin_3d,
                                width: 36.w,
                                height: 36.w,
                              ),
                              SizedBox(width: 10.w),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Up To',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    '100',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'Complete Your KYC And Get 100 E-\n'
                            'Coins Instantly.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: 18.h),
                          Text(
                            '100% Safe & Secure',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withOpacity(0.85),
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          SizedBox(height: 16.h),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _KycBenefitCard(
                                icon: Icons.verified_user_outlined,
                                label: 'Secure\nVerification',
                              ),
                              _KycBenefitCard(
                                icon: Icons.timer_outlined,
                                label: 'Takes Less Than\n2 Minutes',
                              ),
                              _KycBenefitCard(
                                icon: Icons.currency_rupee,
                                label: 'Get 100 E-\nCoins',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16.w,
                  right: 16.w,
                  bottom: 16.h,
                  child: SizedBox(height: 42.h,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const KycVerificationView(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(28.r),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE85A2C),
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                        child: Text(
                          'Complete KYC',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: SpinKitCircle(
                color: const Color(0xFFE85A2C),
                size: 48.w,
              ),
            ),
    );
  }
}

class _KycBenefitCard extends StatelessWidget {
  const _KycBenefitCard({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFF2B5EA6),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
