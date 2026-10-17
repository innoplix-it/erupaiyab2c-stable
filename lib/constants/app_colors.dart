import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFDD5428);
  static const Color primaryDark = Color(0xFFC64818);
  static const Color gradientStart = Color(0xFFFFC9B8);
  static const Color gradientMid = Color(0xFFFFA47A);
  static const Color gradientEnd = Color(0xFFDD5428);

  static const Color inputGradientStart = Color(0xFFFFF5EF);
  static const Color inputGradientEnd = Color(0xFFFFE4D3);
  static const Color phoneFieldStart = Color(0xFFF2F2F2);
  static const Color phoneFieldEnd = Color(0xFFE8E8E8);

  static const Color cardShadow = Color(0x1A000000);
  static const Color textPrimary = Color(0xFF3A1D12);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color red = Colors.redAccent;
  static const Color green = Colors.green;
  static const Color lightBorder = Color(0xFFE4DFDA);
  static const Color lightBorder2 = Color(0xFFE2E2E2);

  static const LinearGradient authBackgroundGradient = LinearGradient(
    colors: [gradientStart, gradientMid, gradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Login mobile step: Peach Coral → white (Figma).
  /// `linear-gradient(179.93deg, #DD5428 -13.84%, #FFFFFF 96.21%)`
  static const Color loginPeachCoral = Color(0xFFDD5428);

// Sampled from the supplied Login screenshot.
  static const Color loginBackgroundPeach = Color(0xFFF2AA91);

  static const LinearGradient loginPeachCoralGradient =
  LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment(0, 0.20),
    colors: [
      loginBackgroundPeach,
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 1.0],
  );

  static const LinearGradient onboardingBackground =
  LinearGradient(
    colors: [
      Color(0xFFFFE8DF),
      Color(0xFFFFF4ED),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient otpSuccessBackground = LinearGradient(
    colors: [
      Color.fromRGBO(255, 131, 92, 0.28),
      Color.fromRGBO(255, 255, 255, 0.28),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroTextGradient = LinearGradient(
    colors: [
      Color(0xFFFFF0E8),
      Color(0xFFFFD0BF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
