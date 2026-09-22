import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constants/app_colors.dart';

class SipAmountStepper extends StatelessWidget {
  const SipAmountStepper({
    super.key,
    required this.valueText,
    required this.onDecrement,
    required this.onIncrement,
    this.decrementEnabled = true,
    this.incrementEnabled = true,
  });

  final String valueText;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool decrementEnabled;
  final bool incrementEnabled;

  @override
  Widget build(BuildContext context) {
    Widget circleButton({
      required IconData icon,
      required VoidCallback onTap,
      required bool enabled,
    }) {
      return InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999.r),
        child: Container(
          width: 28.r,
          height: 28.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? const Color(0xFFFDE7DE) : const Color(0xFFF3F4F6),
            border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
          ),
          child: Icon(
            icon,
            size: 16.r,
            color: enabled ? const Color(0xFFE85A2C) : Colors.black26,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circleButton(
          icon: Icons.remove,
          onTap: onDecrement,
          enabled: decrementEnabled,
        ),
        SizedBox(width: 14.w),
        Text(
          valueText,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
        ),
        SizedBox(width: 14.w),
        circleButton(
          icon: Icons.add,
          onTap: onIncrement,
          enabled: incrementEnabled,
        ),
      ],
    );
  }
}

