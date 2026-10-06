import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/common_service_svg_icon.dart';
import '../services/developer_options_detector.dart';

/// Developer Mode Enabled popup, matching the Figma reference exactly:
/// illustration -> title -> description -> "How to fix?" card ->
/// Close App / Open Settings buttons.
///
/// Pure UI: it never decides on its own when to show — the caller (security
/// check) presents it via [DeveloperModeSheet.show]. The two buttons only
/// terminate the app or open the system app-settings page.
///
/// Sizing follows the project's single-scaling architecture: Figma values are
/// authored on the 440px frame, so square/icon/radius metrics are
/// pre-compensated to the 360 design width and then scaled exactly once by
/// ScreenUtil (same helper style as HomeServiceCircle / AppSearchBar).
class DeveloperModeSheet extends StatelessWidget {
  const DeveloperModeSheet({super.key});

  /// Figma (440 frame) px -> ScreenUtil single-scaled value.
  static double _figmaW(double px) => (px * 360 / 440).w;
  static double _figmaR(double px) => (px * 360 / 440).r;

  static const String _description =
      'Developer Mode is currently enabled on your device. '
      'For security reasons, you cannot use this app while Developer Mode is '
      'turned on.';

  /// Shows the popup as a non-dismissible modal bottom sheet — the only two
  /// exits are the buttons below, per the security flow.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const DeveloperModeSheet(),
    );
  }

  void _closeApp() {
    SystemNavigator.pop();
  }

  Future<void> _openSettings() async {
    // Prefer opening the Android Developer Options screen directly
    // (Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS); fall back to the
    // generic app-settings page when that intent is unavailable.
    final bool opened =
        await const DeveloperOptionsDetector().openDeveloperSettings();
    if (opened) return;
    try {
      await openAppSettings();
    } catch (_) {
      // Platform without an app-settings page: stay on the popup so the
      // user can still close the app.
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets safePadding = MediaQuery.paddingOf(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        // Keep the sheet inside the viewport on short screens; the content
        // scrolls instead of overflowing.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_figmaR(28)),
              ),
              border: const Border(
                top: BorderSide(color: AppColors.primary, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Everything above the buttons scrolls on short screens or
                // at large text scales; the action row stays pinned so the
                // user can always reach Close App / Open Settings.
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      _figmaW(24),
                      _figmaW(32),
                      _figmaW(24),
                      0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Illustration(),
                        SizedBox(height: _figmaW(14)),
                        const _Title(),
                        SizedBox(height: _figmaW(6)),
                        const _Description(),
                        SizedBox(height: _figmaW(24)),
                        const _HowToFixCard(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    _figmaW(24),
                    _figmaW(24),
                    _figmaW(24),
                    _figmaW(24) + safePadding.bottom,
                  ),
                  child: _ActionButtons(
                    onCloseApp: _closeApp,
                    onOpenSettings: _openSettings,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen mandatory lock route mounted at `/developer-mode-enabled`.
///
/// Reuses the approved [DeveloperModeSheet] card so the UI stays
/// pixel-identical to the Figma reference, but presents it as a route over a
/// dimmed backdrop with
/// Android/Flutter back navigation disabled. The only exits are the two buttons;
/// turning Developer Options OFF lets the router guard unblock the app.
class DeveloperModeEnabledScreen extends StatelessWidget {
  const DeveloperModeEnabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // Swallow back gestures so the barrier never reveals a normal screen.
      // Re-check on the way back to the foreground is handled by the lifecycle
      // observer, which drives this route's exit through the router guard.
      onPopInvokedWithResult: (didPop, result) {
        // Intentionally empty: nothing pops while the app is locked.
      },
      child: const ColoredBox(
        color: Color(0x99000000),
        child: SafeArea(
          top: true,
          bottom: false,
          child: DeveloperModeSheet(),
        ),
      ),
    );
  }
}

/// 69x70 Figma illustration. The exported PNG is slightly wider than the
/// Figma box, so BoxFit.cover reproduces the design's crop.
class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DeveloperModeSheet._figmaR(69),
      height: DeveloperModeSheet._figmaR(70),
      child: Image.asset(
        'assets/images/png/developer_mode_illustration.png',
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => Icon(
          Icons.gpp_maybe_outlined,
          size: DeveloperModeSheet._figmaR(69),
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Developer Mode Enabled',
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        height: 1,
        letterSpacing: -0.02 * 18.sp,
        color: const Color(0xFF000000),
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description();

  @override
  Widget build(BuildContext context) {
    return Text(
      DeveloperModeSheet._description,
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 23 / 14,
        letterSpacing: -0.02 * 14.sp,
        color: const Color(0xFF000000),
      ),
    );
  }
}

/// Peach information card: circular info icon + "How to fix?" + support
/// text. Height follows the content (never fixed) so long text and larger
/// font scales stay inside the card.
class _HowToFixCard extends StatelessWidget {
  const _HowToFixCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(DeveloperModeSheet._figmaW(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFFCECE7),
        borderRadius: BorderRadius.circular(DeveloperModeSheet._figmaR(8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonServiceSvgIcon(
            assetPath: 'assets/images/svg/developer_mode_info_icon.svg',
            width: DeveloperModeSheet._figmaR(30),
            height: DeveloperModeSheet._figmaR(30),
          ),
          SizedBox(width: DeveloperModeSheet._figmaW(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to fix?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: -0.02 * 14.sp,
                    color: const Color(0xFF000000),
                  ),
                ),
                SizedBox(height: DeveloperModeSheet._figmaW(6)),
                Text(
                  DeveloperModeSheet._description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    height: 19 / 10,
                    letterSpacing: -0.02 * 10.sp,
                    color: const Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onCloseApp,
    required this.onOpenSettings,
  });

  final VoidCallback onCloseApp;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PopupButton(
            label: 'Close App',
            onPressed: onCloseApp,
          ),
        ),
        // Figma row math: 440 - 2x24 padding - 2x188 buttons = 16 gap.
        SizedBox(width: DeveloperModeSheet._figmaW(16)),
        Expanded(
          child: _PopupButton(
            label: 'Open Settings',
            filled: true,
            onPressed: onOpenSettings,
          ),
        ),
      ],
    );
  }
}

class _PopupButton extends StatelessWidget {
  const _PopupButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    // Figma auto-layout: 188x46 = 16 + 14 (text) + 16 padding on the 440
    // frame. The height is derived from that content (never a fixed box), so
    // larger text scales grow the button instead of clipping the label.
    // maximumSize lifts the Material-3 TextButton cap (168x40) which would
    // otherwise squash the pill; minimumSize keeps the >=40dp touch target.
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: filled ? AppColors.primary : const Color(0xFFFFFFFF),
        foregroundColor: filled ? const Color(0xFFFFFFFF) : AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1),
        maximumSize: const Size(double.infinity, double.infinity),
        minimumSize: Size(0, DeveloperModeSheet._figmaR(40)),
        padding: EdgeInsets.symmetric(vertical: DeveloperModeSheet._figmaW(16)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DeveloperModeSheet._figmaR(76)),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          height: 1,
          letterSpacing: 0,
        ),
      ),
      child: Text(label),
    );
  }
}
