// Auth Continue/Verify buttons must have no visible rim: the Material button
// fills the whole coloured pill and is not tinted when disabled or loading.
// Uses the canonical `responsiveTestScreenSizes` matrix.

import 'package:e_rupaiya/features/auth/components/auth_step_parts.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/responsive_test_sizes.dart';

Future<void> _pump(WidgetTester tester, Widget button, Size size) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: button,
            ),
          ),
        ),
      ),
    ),
  );
}

void _expectNoRim(WidgetTester tester) {
  final pill = find
      .descendant(
        of: find.byType(CustomElevatedButton),
        matching: find.byType(DecoratedBox),
      )
      .first;
  final material = find
      .descendant(
        of: find.byType(ElevatedButton),
        matching: find.byType(Material),
      )
      .first;
  expect(tester.getRect(material), tester.getRect(pill));
  final paint = tester.widget<Material>(material);
  expect(paint.color?.a ?? 0, 0, reason: 'no tint over the pill');
  expect(paint.elevation, 0);
  final shape = paint.shape;
  expect(shape, isA<OutlinedBorder>());
  expect((shape! as OutlinedBorder).side, BorderSide.none);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final states = <String, Widget>{
    'enabled': AuthPrimaryButton(
      label: 'Continue',
      enabled: true,
      onPressed: () {},
    ),
    'disabled': const AuthPrimaryButton(
      label: 'Continue',
      enabled: false,
      onPressed: null,
    ),
    'loading': AuthPrimaryButton(
      label: 'Continue',
      enabled: true,
      isLoading: true,
      onPressed: () {},
    ),
    'fixed-height dialog button': const AuthButtonTheme(
      child: CustomElevatedButton(
        onPressed: null,
        label: 'Verify Now',
        height: 42,
      ),
    ),
  };

  for (final MapEntry(key: state, value: button) in states.entries) {
    group('Continue button has no border when $state', () {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height}', (tester) async {
          await _pump(tester, button, size);
          expect(tester.takeException(), isNull);
          _expectNoRim(tester);
        });
      }
    });
  }

  testWidgets('keeps the 48dp pill height', (tester) async {
    await _pump(
      tester,
      AuthPrimaryButton(label: 'Continue', enabled: true, onPressed: () {}),
      const Size(390, 844),
    );
    expect(tester.getSize(find.byType(CustomElevatedButton)).height, 48);
  });
}
