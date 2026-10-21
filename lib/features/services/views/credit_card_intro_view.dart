// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../components/credit_card/credit_card_figma_metrics.dart';

class CreditCardIntroView extends StatelessWidget {
  const CreditCardIntroView({super.key});

  @override
  Widget build(BuildContext context) {
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    double sy(double v) => CreditCardFigmaMetrics.sy(context, v);
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
                    padding: EdgeInsets.symmetric(horizontal: sx(12)),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        SizedBox(width: sx(4)),
                        Expanded(
                          child: Text(
                            'Add New Card',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
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
                left: sx(24),
                right: sx(24),
                top: curveHeight + sy(70),
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
                    SizedBox(height: sy(8)),
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
                left: sx(24),
                right: sx(24),
                bottom: sy(24) + MediaQuery.paddingOf(context).bottom,
                child: CustomElevatedButton(
                  onPressed: () =>
                      context.push(RouteConstants.creditCardListing),
                  label: 'Add New Card',
                  showArrow: false,
                  uppercaseLabel: false,
                  height: CreditCardFigmaMetrics.primaryButtonHeight(context),
                  labelStyle: CreditCardFigmaMetrics.primaryButtonLabelStyle(
                    context,
                  ),
                  borderRadius: CreditCardFigmaMetrics.s(context, 28),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
