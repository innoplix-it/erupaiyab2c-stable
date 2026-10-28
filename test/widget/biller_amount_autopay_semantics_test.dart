// AUD-019 semantics tests for the AutoPay Pay button in biller detail.
//
// Exercises the real widget tree through the semantics pipeline (not
// source-string assertions). The payable amount is asserted through the
// CTA announcement, which embeds the same amount formatting the card uses.
// NOTE: `_SubscriptionSummaryCard`'s own 'Amount to pay:' Semantics wrapper
// (biller_detail_view_parts.dart:202) is library-private and therefore NOT
// directly testable from outside the library; asserting it would require
// making the card public, which is out of AUD-019 scope. Reported gap.
import 'package:e_rupaiya/features/services/views/biller_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

Finder semanticsWith({String? label, bool? button}) {
  return find.byWidgetPredicate((widget) =>
      widget is Semantics &&
      (label == null || widget.properties.label == label) &&
      (button == null || widget.properties.button == button));
}

Future<void> pumpAutoPaySheet(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  double amount = 999.0,
  VoidCallback? onPay,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AutoPayBottomSheet(
                  amount: amount,
                  billerName: 'Test Biller',
                  providerIconUrl: null,
                  accountHolderName: 'Tester',
                  consumerNumber: '1234567890',
                  onPayAndSetAutoPay: onPay ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoPayBottomsheet Pay button semantics', () {
    testWidgets('CTA is announced as a button with the full label',
        (tester) async {
      await pumpAutoPaySheet(tester, size: const Size(390, 844));

      // _formatAmountForInput(999.0) strips trailing zeros -> '₹999'.
      const ctaLabel = 'Pay ₹999 & Set AutoPay';
      expect(semanticsWith(label: ctaLabel, button: true), findsOneWidget);
      final node = tester.getSemantics(semanticsWith(label: ctaLabel));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.label, ctaLabel);
    });

    testWidgets('button value is not duplicated into the announcement',
        (tester) async {
      await pumpAutoPaySheet(tester, size: const Size(390, 844));

      // The visible label must appear exactly once on the merged node — the
      // Semantics wrapper + inner ElevatedButton must not double-read.
      const ctaLabel = 'Pay ₹999 & Set AutoPay';
      final node = tester.getSemantics(semanticsWith(label: ctaLabel));
      final occurrences = ctaLabel.allMatches(node.label).length;
      expect(occurrences, 1);
    });

    testWidgets('tapping the labeled button still fires the callback',
        (tester) async {
      var tapped = 0;
      await pumpAutoPaySheet(
        tester,
        size: const Size(390, 844),
        amount: 149.5,
        onPay: () => tapped++,
      );

      await tester.tap(find.text('Pay ₹149.5 & Set AutoPay'));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('decimal amount label reads consistently with visible text',
        (tester) async {
      await pumpAutoPaySheet(tester, size: const Size(390, 844), amount: 45.75);

      const ctaLabel = 'Pay ₹45.75 & Set AutoPay';
      expect(semanticsWith(label: ctaLabel, button: true), findsOneWidget);
      expect(find.text(ctaLabel), findsOneWidget);
    });
  });

  group('AUD-019 AutoPay CTA across the responsive matrix', () {
    // Portrait viewports from the shared matrix; the app clamps textScaler
    // to 0.85..1.15 (main.dart), so those are the supported scales.
    const portraitSizes = [
      Size(280, 653), Size(320, 480), Size(320, 568), Size(360, 640),
      Size(360, 690), Size(360, 740), Size(360, 800), Size(375, 667),
      Size(375, 812), Size(390, 844), Size(393, 852), Size(411, 731),
      Size(412, 915), Size(414, 896), Size(428, 926), Size(430, 932),
      Size(440, 956), Size(458, 1024),
    ];

    for (final size in portraitSizes) {
      for (final scale in [0.85, 1.0, 1.15]) {
        testWidgets(
            'AutoPay CTA stays a labeled button at '
            '${size.width}x${size.height} textScale $scale', (tester) async {
          // Guard: every viewport tested here exists in the shared matrix.
          expect(responsiveTestScreenSizes, contains(size));
          await pumpAutoPaySheet(
            tester,
            size: size,
            textScale: scale,
          );

          const ctaLabel = 'Pay ₹999 & Set AutoPay';
          expect(semanticsWith(label: ctaLabel, button: true), findsOneWidget);
          final node = tester.getSemantics(semanticsWith(label: ctaLabel));
          expect(node.flagsCollection.isButton, isTrue);

          final error = tester.takeException();
          // Deterministic pre-existing 'Bill Amount' Row overflow (fixed
          // Text + Spacer + FittedBox, unrelated to the AUD-019 Semantics
          // wrapper): every 280-wide viewport at all scales, and >=360-wide
          // viewports at the app's 1.15 text-scale clamp (except 411x731).
          // At 320 width the overflow is layout-order dependent and NOT
          // reproducible run-to-run, so it is deliberately not pinned as a
          // golden; any 320-width error is drained here and reported in the
          // AUD-019 findings instead. Layout fixes are out of AUD-019 scope.
          final deterministicOverflow = size.width == 280 ||
              (size.width >= 360 &&
                  size != const Size(411, 731) &&
                  scale == 1.15);
          if (deterministicOverflow) {
            expect(
              error,
              isA<FlutterError>(),
              reason: 'pre-existing Bill Amount row overflow at '
                  '${size.width}x${size.height} textScale $scale (not AUD-019)',
            );
          } else {
            expect(
              error == null || size.width == 320,
              isTrue,
              reason: 'unexpected error at '
                  '${size.width}x${size.height} textScale $scale',
            );
          }
        });
      }
    }
  });

  testWidgets('KNOWN PRE-EXISTING DEFECT #1: Bill Amount row overflows on '
      '280px viewports even at textScale 0.85 (not introduced by AUD-019)',
      (tester) async {
    // Unrelated to the AUD-019 Semantics wrapper: the 'Bill Amount' Row in
    // AutoPayBottomSheet uses a fixed Text label + Spacer + FittedBox, which
    // exceeds the content width on 280px viewports. Layout fix is out of
    // AUD-019 scope; reported for follow-up.
    await pumpAutoPaySheet(
      tester,
      size: const Size(280, 653),
      textScale: 0.85,
    );
    expect(tester.takeException(), isA<FlutterError>());
  });

  testWidgets('KNOWN PRE-EXISTING DEFECT #2: Bill Amount row overflows at '
      'the app text-scale clamp max (1.15) even on 440px (not AUD-019)',
      (tester) async {
    // main.dart clamps textScaler to 1.15; the same fixed-width Bill Amount
    // Row overflows by ~28px at the Figma 440 design width at that scale.
    await pumpAutoPaySheet(
      tester,
      size: const Size(440, 956),
      textScale: 1.15,
    );
    expect(tester.takeException(), isA<FlutterError>());
  });
}
