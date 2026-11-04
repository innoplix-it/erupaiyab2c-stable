import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// One pill inside [AppSearchModeToggle].
class AppSearchModeOption<T> {
  const AppSearchModeOption({required this.label, required this.value});

  final String label;
  final T value;
}

/// Two-state pill switch used in the trailing slot of [AppSearchBar]
/// (Mobile Prepaid "ABC / 123" search-mode switch, reused as-is elsewhere).
///
/// Everything is ScreenUtil-driven (.w/.h/.r/.sp), so the toggle keeps the
/// same proportions on every device. The visible chip stays 24 tall while an
/// invisible overlay grows the tap area to roughly 44x44.
class AppSearchModeToggle<T> extends StatelessWidget {
  const AppSearchModeToggle({
    super.key,
    required this.mode,
    required this.options,
    required this.onChanged,
    this.chipWidth,
  });

  final T mode;
  final List<AppSearchModeOption<T>> options;
  final ValueChanged<T> onChanged;

  /// Overrides the shared chip width when a label needs more room.
  final double? chipWidth;

  @override
  Widget build(BuildContext context) {
    Widget chip(AppSearchModeOption<T> option, double width) {
      final active = mode == option.value;
      return SizedBox(
        width: width,
        height: 24.h,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ~44x44 tap target without enlarging the visible chip.
            Positioned(
              top: -14.h,
              bottom: -14.h,
              left: -4.w,
              right: -4.w,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(option.value),
                child: const SizedBox.shrink(),
              ),
            ),
            InkWell(
              onTap: () => onChanged(option.value),
              borderRadius: BorderRadius.circular(90.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: width,
                height: 24.h,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFDD5428) : Colors.transparent,
                  borderRadius: BorderRadius.circular(90.r),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    option.label,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: active
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF000000),
                      fontWeight: FontWeight.w500,
                      fontSize: 11.sp,
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Both pills share one width so the track stays symmetrical.
    final width = chipWidth ?? 40.w;

    return Padding(
      // Figma: toggle sits inset from the field edge, not flush.
      padding: EdgeInsets.only(left: 4.w, right: 12.w, top: 8.h, bottom: 8.h),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x21DD5428),
          borderRadius: BorderRadius.circular(90.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options) chip(option, width),
          ],
        ),
      ),
    );
  }
}
