import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/app_colors.dart';
import '../credit_card/credit_card_figma_metrics.dart';

class CreditCardPayNowOptionCard extends StatelessWidget {
  const CreditCardPayNowOptionCard({
    super.key,
    required this.title,
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String amount;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    final borderColor = isSelected ? AppColors.primary : AppColors.lightBorder;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(sx(12)),
      child: Container(
        constraints: BoxConstraints(minHeight: sx(68)),
        padding: EdgeInsets.fromLTRB(sx(12), sx(10), sx(10), sx(10)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sx(12)),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: sx(11),
                    ),
                  ),
                  SizedBox(height: sx(6)),
                  Text(
                    amount,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: sx(15),
                    ),
                  ),
                ],
              ),
            ),
            _RadioDot(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    final borderColor =
        isSelected ? AppColors.primary : const Color(0xFFD4D4D8);
    return Container(
      width: sx(18),
      height: sx(18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: Center(
        child: Container(
          width: sx(9),
          height: sx(9),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
