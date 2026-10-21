import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../constants/routes_constant.dart';

/// Shared Figma help control: white circular badge with a tinted `?`.
///
/// Used on dark/colored headers (e.g. Refer & Earn) where [Icons.help_outline]
/// would not match the design.
class AppHelpBadgeButton extends StatelessWidget {
  const AppHelpBadgeButton({
    super.key,
    this.onPressed,
    this.badgeTint = const Color(0xFF084591),
    this.badgeSize,
    this.questionSize,
  });

  final VoidCallback? onPressed;

  /// Color of the `?` glyph (typically the header fill).
  final Color badgeTint;

  /// Logical badge diameter before ScreenUtil `.r` (Figma 28 on 440 frame →
  /// pass `(28 * 360 / 440)` when matching Refer & Earn).
  final double? badgeSize;

  /// Logical `?` font size before ScreenUtil `.sp`.
  final double? questionSize;

  @override
  Widget build(BuildContext context) {
    final badge = (badgeSize ?? 28).r;
    final qSize = (questionSize ?? 16).sp;
    return IconButton(
      onPressed: onPressed ?? () => context.push(RouteConstants.helpSupport),
      icon: Container(
        width: badge,
        height: badge,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Text(
          '?',
          style: TextStyle(
            color: badgeTint,
            fontWeight: FontWeight.w700,
            fontSize: qSize,
            height: 1,
          ),
        ),
      ),
    );
  }
}
