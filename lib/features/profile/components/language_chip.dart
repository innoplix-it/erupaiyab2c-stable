import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';

enum LanguageOption { english, hindi }

class LanguageChip extends StatelessWidget {
  const LanguageChip({
    super.key,
    required this.value,
    required this.onChanged,
    this.isInteractive = true,
  });

  const LanguageChip.englishOnly({
    super.key,
  })  : value = LanguageOption.english,
        onChanged = _noop,
        isInteractive = false;

  final LanguageOption value;
  final ValueChanged<LanguageOption> onChanged;
  final bool isInteractive;

  String get _label => value == LanguageOption.hindi ? 'Hindi' : 'English';

  static void _noop(LanguageOption _) {}

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (isInteractive) ...[
            SizedBox(width: 6.w),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18.r,
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
          ],
        ],
      ),
    );

    if (!isInteractive) return child;

    return PopupMenuButton<LanguageOption>(
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: LanguageOption.english,
          child: Text('English'),
        ),
        PopupMenuItem(
          value: LanguageOption.hindi,
          child: Text('Hindi'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      child: child,
    );
  }
}
