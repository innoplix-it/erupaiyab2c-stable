// Test-only helpers shared by the responsive widget tests.
//
// `responsiveTestScreenSizes` is the canonical device matrix for responsive
// widget tests in this repository. It exists purely to stop test files from
// duplicating the same size list.
//
// STRICTLY TEST-ONLY: never import this file from production code. Production
// widgets must keep sizing themselves with MediaQuery, LayoutBuilder and the
// project's Flutter ScreenUtil conventions (.w/.h/.r/.sp).
import 'dart:ui';

/// The supported device sizes every responsive widget test should cover,
/// spanning short and tall phones from the narrowest (320 pt) up to the
/// largest supported (458 pt) viewport.
const responsiveTestScreenSizes = [
  Size(320, 568), // iPhone SE 1st gen (compact)
  Size(360, 640), // Moto G / Android standard
  Size(360, 690), // Design base (ScreenUtil designSize)
  Size(360, 800), // Standard tall Android
  Size(375, 812), // iPhone X / 11 Pro / 12 mini
  Size(390, 844), // iPhone 12 / 13 / 14 Pro
  Size(412, 915), // Pixel 7
  Size(440, 956), // Large device (Figma 440 frame)
  Size(458, 1024), // Extra-tall Android
];
