import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/language_chip.dart';
import '../components/policy_section_title.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const MyAppBar(title: 'About E-Rupaiya'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'About e-Rupaiya',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      const LanguageChip.englishOnly(),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  _AboutParagraph(
                    'e-Rupaiya is a smart and rewarding digital payments '
                    'platform designed to make your everyday bill payments '
                    'simple, fast, and beneficial.',
                  ),
                  _AboutParagraph(
                    'From mobile recharges and utility bills to other essential '
                    'payments, e-Rupaiya ensures a seamless experience with a '
                    'user-friendly interface built for everyone.',
                  ),
                  _AboutParagraph(
                    'Our mission is to transform routine transactions into '
                    'rewarding experiences. With every payment you make, you '
                    'earn coins that can be used for future bill payments, '
                    'giving you real value back on your spending.',
                  ),
                  _AboutParagraph(
                    'We believe payments should not just be easy, they should '
                    'also give something back to the user.',
                  ),
                  _AboutParagraph(
                    'At e-Rupaiya, security and trust are our top priorities. '
                    'We use reliable systems and secure processes to ensure '
                    'that your data and transactions remain safe at all times.',
                  ),
                  _AboutParagraph(
                    'You can confidently manage your payments knowing your '
                    'information is protected.',
                  ),
                  SizedBox(height: 12.h),
                  const PolicySectionTitle(text: 'Why e-Rupaiya?'),
                  SizedBox(height: 8.h),
                  const _Bullet('Quick and hassle-free payments'),
                  const _Bullet('Rewards on every transaction'),
                  const _Bullet('Simple, clean and easy-to-use interface'),
                  const _Bullet('Secure & reliable'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutParagraph extends StatelessWidget {
  const _AboutParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.75),
              height: 1.5,
            ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 6.w,
            height: 6.w,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
