import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/file_constants.dart';

class ReferAndEarnAppBar extends HookWidget {
  const ReferAndEarnAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onHelp,
    this.height,
    this.body,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onHelp;

  /// Already ScreenUtil-scaled. Omitted height uses the 320 design-unit default once.
  final double? height;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final barHeight = height ?? 320.h;
    return SizedBox(
      height: barHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              FileConstants.bluebg,
              fit: BoxFit.cover,
              cacheWidth: (MediaQuery.sizeOf(context).width *
                      MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(1, 4096),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            child: Container(
              height: 36.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28.r),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.white),
                    onPressed: onHelp,
                  ),
                ],
              ),
            ),
          ),
          if (body != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 90.h,
              child: body!,
            ),
        ],
      ),
    );
  }
}
