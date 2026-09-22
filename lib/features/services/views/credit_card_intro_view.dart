// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreditCardIntroView extends StatelessWidget {
  const CreditCardIntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final headerHeight = constraints.maxHeight * 0.6;
          final curveHeight = headerHeight * 0.5;
          final cardHeight = headerHeight * 0.5;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Image.asset(
                  FileConstants.curve,
                  height: curveHeight,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: curveHeight - (cardHeight / 2.5),
                child: Center(
                  child: Image.asset(
                    FileConstants.creditcard,
                    height: cardHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Add New Card',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.help_outline,
                            color: Colors.white,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: curveHeight + 70,
                child: Column(
                  children: [
                    Text(
                      'No Cards Linked Yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Link your cards to E-Rupaiya for fast\nand secure digital payments.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: CustomElevatedButton(
                  onPressed: () =>
                      context.push(RouteConstants.creditCardListing),
                  label: 'Add New Card',
                  showArrow: false,
                  uppercaseLabel: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
