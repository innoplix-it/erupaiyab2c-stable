import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';

/// Simulated eRupaiya verification overlay (UI only — no API).
const Duration kEducationSimulatedVerificationDuration = Duration(seconds: 2);

const double _kFigmaLoaderSize = 70.0;
const double _kFigmaW = 448.0;

/// One full turn of the rupee arc around the orange circle.
const Duration _kArcSpinPeriod = Duration(milliseconds: 800);

/// Cross-fade duration used when [label] changes while the overlay is up.
const Duration _kLabelChangeDuration = Duration(milliseconds: 350);

class EducationErupaiyaVerifyingOverlay extends HookWidget {
  const EducationErupaiyaVerifyingOverlay({
    super.key,
    this.duration = kEducationSimulatedVerificationDuration,
    this.onCompleted,
    this.label = 'Verifying on eRupaiya',
    this.subtitle = 'Do not close or go back.',
  });

  final Duration duration;
  final VoidCallback? onCompleted;

  /// Main line under the spinner; may change while visible (the overlay
  /// cross-fades to the new text).
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);
    final completed = useRef(false);

    useEffect(() {
      void listener(AnimationStatus status) {
        if (status == AnimationStatus.completed &&
            onCompleted != null &&
            !completed.value) {
          completed.value = true;
          onCompleted!();
        }
      }

      controller.addStatusListener(listener);
      controller.forward();
      return () => controller.removeStatusListener(listener);
    }, [controller, onCompleted]);

    // Continuous smooth spin for the rupee arc, independent of [duration].
    final spinController = useAnimationController(duration: _kArcSpinPeriod);
    useEffect(() {
      spinController.repeat();
      return null;
    }, [spinController]);
    final spin = useAnimation(spinController);

    final size = MediaQuery.sizeOf(context);
    final scale = size.width.clamp(320.0, 560.0) / _kFigmaW;
    final loaderSize = _kFigmaLoaderSize * scale;

    return Material(
      color: const Color(0xCC000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: loaderSize,
              height: loaderSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    FileConstants.erupaiyaVerifyingCircleSvg,
                    width: loaderSize,
                    height: loaderSize,
                    fit: BoxFit.contain,
                  ),
                  // eRupaiya glyph centred inside the circle (Figma SVG).
                  SvgPicture.asset(
                    FileConstants.erupaiyaVerifyingLogoSvg,
                    width: loaderSize,
                    height: loaderSize,
                    fit: BoxFit.contain,
                  ),
                  Transform.rotate(
                    // Repeat-driven arc: keeps turning smoothly the whole
                    // time the overlay is visible.
                    angle: spin * 2 * math.pi,
                    child: SvgPicture.asset(
                      FileConstants.erupaiyaVerifyingRupeeArcSvg,
                      width: loaderSize,
                      height: loaderSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.028),
            AnimatedSwitcher(
              duration: _kLabelChangeDuration,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.35),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                key: ValueKey(label),
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.012),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1,
                color: const Color(0xFFD4D4D8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
