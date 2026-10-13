
// Test-only helpers shared by responsive widget tests.
//
// `responsiveTestScreenSizes` is the canonical device matrix for responsive
// widget tests in this repository, ordered from the smallest to the largest
// portrait viewport (logical pixels).
//
// STRICTLY TEST-ONLY: Never import this file from production code.

import 'dart:ui';

const responsiveTestScreenSizes = [
  // --- Very small / compact phones ---
  Size(280, 653), // Galaxy Z Fold cover screen (narrowest)
  Size(320, 480), // Very small / old Android (shortest)
  Size(320, 568), // iPhone SE 1st generation

  // --- Standard Android ---
  Size(360, 640), // Moto G / Android standard
  Size(360, 690), // Design base (ScreenUtil designSize)
  Size(360, 740), // Galaxy S8 / S9
  Size(360, 800), // Standard tall Android

  // --- iPhones / Pixels (mid-size) ---
  Size(375, 667), // iPhone 8 / iPhone SE 2nd & 3rd generation
  Size(375, 812), // iPhone X / 11 Pro / 12 mini
  Size(390, 844), // iPhone 12 / 13 / 14 Pro
  Size(393, 852), // iPhone 15 / Pixel 8
  Size(411, 731), // Pixel 2 (short, wide)
  Size(412, 915), // Pixel 7

  // --- Large phones ---
  Size(414, 896), // iPhone 11 / XR
  Size(428, 926), // iPhone 14 Plus
  Size(430, 932), // iPhone 15 Pro Max
  Size(440, 956), // Large device (Figma 440 frame)
  Size(458, 1024), // Extra-tall Android

  // --- Tablets / foldables (open) ---
  Size(600, 960), // Small tablet / foldable open
  Size(768, 1024), // iPad portrait
  Size(820, 1180), // iPad Air
  Size(1024, 1366), // iPad Pro 12.9-inch
];
