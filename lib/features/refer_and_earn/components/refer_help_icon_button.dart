import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import 'refer_and_earn_figma_metrics.dart';

/// Figma Refer & Earn help control: white circular `?` (20×20).
///
/// On light app bars pass [color] as black so the same asset stays visible.
class ReferHelpIconButton extends StatelessWidget {
  const ReferHelpIconButton({
    super.key,
    this.onPressed,
    this.color = Colors.white,
    this.size,
  });

  final VoidCallback? onPressed;

  /// Tint applied over the white SVG (white on dark headers, black on light).
  final Color color;

  /// Logical size before ScreenUtil `.r`. Defaults to Figma 20 on 440 frame.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final iconSize = context.referW(size ?? 20);
    return IconButton(
      onPressed: onPressed ?? () => context.push(RouteConstants.helpSupport),
      icon: ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: SvgPicture.asset(
          FileConstants.referHelpIconSvg,
          width: iconSize,
          height: iconSize,
        ),
      ),
    );
  }
}
