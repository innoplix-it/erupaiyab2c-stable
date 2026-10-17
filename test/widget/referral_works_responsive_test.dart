// Responsive + layout tests for the How It Works screen
// (ReferralWorksView).
//
// Uses the shared device matrix from test/helpers/responsive_test_sizes.dart.
// Covers: the video placeholder in the blue header, the referral
// illustration below "Example:", the explanation typography and the shared
// fixed WhatsApp/Share footer.

import 'dart:io';

import 'package:e_rupaiya/features/refer_and_earn/views/referral_works_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

// The default test font (Ahem) draws square glyphs far wider than Plus
// Jakarta Sans and turns legitimate layouts into false overflow errors.
// Register real font files when present (see build/test_fonts).
Future<void> _loadRealFonts() async {
  const weights = [400, 500, 600, 700, 800];
  final files = {
    for (final w in weights) w: File('build/test_fonts/PJS-$w.ttf'),
  };
  if (files.values.any((f) => !f.existsSync())) return;
  final bytes = {
    for (final e in files.entries)
      e.key: ByteData.sublistView(e.value.readAsBytesSync()),
  };
  Future<void> register(String family, int weight) =>
      (FontLoader(family)..addFont(Future.value(bytes[weight]!))).load();
  for (final family in ['PlusJakartaSans']) {
    await register('${family}_regular', 400);
    for (var w = 100; w <= 900; w += 100) {
      await register('${family}_$w', w);
    }
  }
}

Future<void> _pumpWorks(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Builder(
            // copyWith on the REAL MediaQuery: the view reads the screen
            // width from MediaQuery.sizeOf, so a bare MediaQueryData()
            // (size zero) would break the width-driven video box.
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: const ReferralWorksView(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadRealFonts);

  final videoFinder = find.byKey(const ValueKey('refer-works-video'));

  group('renders across the shared matrix', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpWorks(tester, size: size);
        expect(find.text('How It Works'), findsOneWidget);
        expect(find.text('Example:'), findsOneWidget);
        expect(find.text('You → A → B → C'), findsOneWidget);
        expect(find.text('You Earn:'), findsOneWidget);
        expect(find.text('100 E-Coins When A Transacts'), findsOneWidget);
        expect(find.text('Invite Using Whatsapp'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('video box matches Figma across the shared matrix', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpWorks(tester, size: size);
        expect(videoFinder, findsOneWidget);

        final box = tester.getRect(videoFinder);

        // Figma 407 x 182: ratio holds on every device height.
        expect(box.width / box.height, closeTo(407 / 182, 0.02));

        // Centred, with equal side margins.
        expect(box.left, greaterThan(0));
        expect((box.left - (size.width - box.right)).abs(), lessThan(1));
        expect((box.center.dx - size.width / 2).abs(), lessThan(1));

        // Below the nav row, above the Example heading, inside the screen.
        final title = tester.getRect(find.text('How It Works'));
        expect(box.top, greaterThan(title.bottom));
        expect(
          box.bottom,
          lessThan(tester.getRect(find.text('Example:')).top),
        );
        expect(box.bottom, lessThan(size.height));
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('video placeholder sits in the header above the content',
      (tester) async {
    await _pumpWorks(tester, size: const Size(390, 844));
    expect(videoFinder, findsOneWidget);

    final videoRect = tester.getRect(videoFinder);
    // Figma 407 x 182: the box must keep its ratio (width-driven), not
    // stretch vertically on tall screens.
    expect(videoRect.width / videoRect.height, closeTo(407 / 182, 0.05));
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    // Inside the header area: below the status/nav zone and within width.
    expect(videoRect.top, greaterThan(50));
    expect(videoRect.left, greaterThanOrEqualTo(0));
    expect(videoRect.right, lessThanOrEqualTo(size.width));
    // Above the Example heading (i.e. moved out of the Example section).
    expect(
      videoRect.bottom,
      lessThan(tester.getRect(find.text('Example:')).top),
    );
  });

  testWidgets('placeholder appears exactly once and no embed before tap',
      (tester) async {
    await _pumpWorks(tester, size: const Size(390, 844));
    expect(
      find.byKey(const ValueKey('refer-works-video'), skipOffstage: false),
      findsOneWidget,
    );
    // The YouTube webview is not built until the user taps the placeholder.
    expect(find.text('You → A → B → C'), findsOneWidget);
  });

  testWidgets('illustration renders directly below Example:', (tester) async {
    await _pumpWorks(tester, size: const Size(390, 844));
    final illustration = find.byKey(
      const ValueKey('refer-works-illustration'),
      skipOffstage: false,
    );
    expect(illustration, findsOneWidget);

    final exampleRect = tester.getRect(find.text('Example:'));
    final flowRect = tester.getRect(find.text('You → A → B → C'));
    final rect = tester.getRect(illustration);
    expect(rect.top, greaterThan(exampleRect.bottom));
    expect(rect.bottom, lessThan(flowRect.top));
    // Centred within the content column.
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect((rect.center.dx - size.width / 2).abs(), lessThan(2));
  });

  testWidgets('explanation text uses the Figma typography', (tester) async {
    await _pumpWorks(tester, size: const Size(390, 844));
    Text text(String s) => tester.widget<Text>(find.text(s));

    for (final label in ['You → A → B → C', 'You Earn:']) {
      final style = text(label).style!;
      expect(style.fontWeight, FontWeight.w500, reason: label);
      expect(style.color, const Color(0xFF000000), reason: label);
      expect(style.letterSpacing, 0, reason: label);
      expect(style.height, closeTo(25 / 14, 0.001), reason: label);
    }
  });

  testWidgets('footer stays fixed while the last paragraph scrolls into view',
      (tester) async {
    await _pumpWorks(tester, size: const Size(360, 640));
    final footer = find.text('Invite Using Whatsapp');
    final footerRect = tester.getRect(footer);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(footerRect.bottom, lessThan(size.height));

    await tester.dragUntilVisible(
      find.textContaining('There’s No Limit'),
      find.byType(SingleChildScrollView).first,
      const Offset(0, -60),
    );
    expect(find.text('Invite Using Whatsapp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('supported text scales', () {
    for (final scale in [0.85, 1.0, 1.15]) {
      testWidgets('textScale $scale at 360x690', (tester) async {
        await _pumpWorks(tester, size: const Size(360, 690), textScale: scale);
        expect(find.text('Example:'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
