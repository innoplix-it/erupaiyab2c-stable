import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/features/mobile_prepaid/components/recharge_quick_action_card.dart';
import 'package:e_rupaiya/features/services/components/fetch_provider_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/responsive_test_sizes.dart';

/// Nine portrait sizes from [responsiveTestScreenSizes] (no duplicate matrix).
final _nineSizes = responsiveTestScreenSizes.where((s) {
  const allowed = <String>{
    '320x568',
    '360x640',
    '360x690',
    '360x800',
    '375x812',
    '390x844',
    '412x915',
    '440x956',
    '458x1024',
  };
  return allowed.contains('${s.width.toInt()}x${s.height.toInt()}');
}).toList(growable: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder changeButton() =>
      find.byKey(const ValueKey('simple-quick-action-change'));

  Future<void> pumpCard(
    WidgetTester tester,
    Size size, {
    double textScale = 1.0,
    VoidCallback? onAction,
  }) async {
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
        builder: (context, _) => MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: FetchProviderMetrics.w(24),
                    vertical: FetchProviderMetrics.h(20),
                  ),
                  child: SimpleQuickActionCard(
                    title: 'Maharashtra State Electricity Distribution Co. Ltd',
                    subtitle: '',
                    leadingAsset: FileConstants.bharatConnectColor,
                    actionLabel: 'Change',
                    operatorStyle: true,
                    showShadow: true,
                    onAction: onAction ?? () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Change button first-frame size', () {
    testWidgets('correct height on the initial rendered frame', (tester) async {
      await pumpCard(tester, const Size(390, 844));
      // First frame only — do not pumpAndSettle (that hides the glitch).
      final size0 = tester.getSize(changeButton());
      final expectedH = FetchProviderMetrics.h(28);
      expect(size0.height, moreOrLessEquals(expectedH, epsilon: 0.5));
      // Must not stretch toward the viewport (the prior glitch was ~full height).
      expect(size0.height, lessThan(80));
      expect(
          size0.width, greaterThanOrEqualTo(FetchProviderMetrics.w(72) - 0.5));
    });

    testWidgets('dimensions stay stable across subsequent pumps',
        (tester) async {
      await pumpCard(tester, const Size(390, 844));
      final first = tester.getSize(changeButton());
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final next = tester.getSize(changeButton());
        expect(next.height, moreOrLessEquals(first.height, epsilon: 0.01));
        expect(next.width, moreOrLessEquals(first.width, epsilon: 0.01));
      }
      await tester.pumpAndSettle();
      final settled = tester.getSize(changeButton());
      expect(settled.height, moreOrLessEquals(first.height, epsilon: 0.01));
      expect(settled.width, moreOrLessEquals(first.width, epsilon: 0.01));
    });

    testWidgets('tapping Change still fires onAction', (tester) async {
      var taps = 0;
      await pumpCard(tester, const Size(390, 844), onAction: () => taps++);
      await tester.pump();
      await tester.tap(changeButton());
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('Change button responsive stability', () {
    for (final size in _nineSizes) {
      for (final textScale in const [0.85, 1.15]) {
        testWidgets(
          '${size.width.toInt()}x${size.height.toInt()} @ $textScale',
          (tester) async {
            await pumpCard(tester, size, textScale: textScale);
            final first = tester.getSize(changeButton());
            expect(first.height,
                moreOrLessEquals(FetchProviderMetrics.h(28), epsilon: 0.5));
            expect(first.height, lessThan(80));
            expect(tester.takeException(), isNull);

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));
            final next = tester.getSize(changeButton());
            expect(next.height, moreOrLessEquals(first.height, epsilon: 0.01));
            expect(next.width, moreOrLessEquals(first.width, epsilon: 1.0));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
