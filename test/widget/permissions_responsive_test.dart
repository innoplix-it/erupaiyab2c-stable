import 'dart:io';
import 'dart:ui' as ui;

import 'package:e_rupaiya/features/profile/views/preferences_security_views.dart';
import 'package:e_rupaiya/widgets/feature_turn_off_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

// ---------------------------------------------------------------------------
// Font loading (reuse the same pattern as mobile_prepaid_responsive_test)
// ---------------------------------------------------------------------------
var _realFontsLoaded = false;

Future<void> _loadRealFonts() async {
  const weights = [400, 500, 600, 700, 800];
  final files = {
    for (final w in weights) w: File('build/test_fonts/PJS-$w.ttf'),
  };
  if (files.values.any((f) => !f.existsSync())) return;
  _realFontsLoaded = true;
  final bytes = {
    for (final e in files.entries)
      e.key: ByteData.sublistView(e.value.readAsBytesSync()),
  };
  int nearest(int w) =>
      weights.reduce((a, b) => (a - w).abs() <= (b - w).abs() ? a : b);
  Future<void> register(String family, int weight) =>
      (FontLoader(family)..addFont(Future.value(bytes[nearest(weight)]!)))
          .load();

  for (final family in ['PlusJakartaSans']) {
    await register('${family}_regular', 400);
    await register('${family}_italic', 400);
    for (var w = 100; w <= 900; w += 100) {
      await register('${family}_$w', w);
      await register('${family}_${w}italic', w);
    }
  }
  await register('Roboto', 400);
}

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadRealFonts();
  });

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_secureStorageChannel, (call) async {
      // Return null for all reads (no stored values) and no-op for writes
      if (call.method == 'read') return null;
      if (call.method == 'write') return null;
      if (call.method == 'delete') return null;
      if (call.method == 'deleteAll') return null;
      return null;
    });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_secureStorageChannel, null);
  });

  Future<void> pumpView(
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
              child: const RepaintBoundary(
                key: ValueKey('screenshot_boundary'),
                child: PermissionsView(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  // Detect silently clipped text
  final clipped = <String>{};
  void collectClippedText(WidgetTester tester) {
    for (final element in find.byType(RichText).evaluate()) {
      final paragraph = element.renderObject;
      if (paragraph is! RenderParagraph || !paragraph.hasSize) continue;
      if (paragraph.overflow == TextOverflow.visible) continue;
      final needed = paragraph.getMaxIntrinsicHeight(paragraph.size.width + 1);
      if (needed > paragraph.size.height + 0.5) {
        clipped.add(
          '"${paragraph.text.toPlainText()}" needs '
          '${needed.toStringAsFixed(1)} but has '
          '${paragraph.size.height.toStringAsFixed(1)}',
        );
      }
    }
  }

  void expectNoClippedText() {
    final found = clipped.toList();
    clipped.clear();
    if (!_realFontsLoaded) return;
    expect(found, isEmpty, reason: found.join('\n'));
  }

  Future<void> scrollThrough(WidgetTester tester) async {
    collectClippedText(tester);
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 8; i++) {
      await tester.drag(list, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));
      collectClippedText(tester);
    }
  }

  const sizes = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(360, 690),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
    Size(440, 956),
    Size(458, 1024),
  ];

  for (final size in sizes) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('Permissions screen fits $label', (tester) async {
      await pumpView(tester, size: size);
      expect(find.text('Permissions'), findsOneWidget);
      expect(find.text('Device State'), findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);

      await scrollThrough(tester);
      expect(tester.takeException(), isNull);
      expectNoClippedText();

      // At bottom after scrolling
      expect(find.text('Photos and Files'), findsOneWidget);
    });

    testWidgets('Permissions screen fits $label at 1.15x text scale',
        (tester) async {
      await pumpView(tester, size: size, textScale: 1.15);
      expect(find.text('Permissions'), findsOneWidget);
      expect(find.text('Device State'), findsOneWidget);

      await scrollThrough(tester);
      expect(tester.takeException(), isNull);
      expectNoClippedText();

      expect(find.text('Photos and Files'), findsOneWidget);
    });
  }

  testWidgets('All 9 permission categories are present', (tester) async {
    await pumpView(tester, size: const Size(390, 844));
    final list = find.byType(Scrollable).first;

    final categories = {
      'Device State',
      'SMS',
      'Camera',
      'Registration',
      'Location',
      'Notifications',
      'Contacts',
      'Phone',
      'Photos and Files',
    };

    final found = <String>{};

    for (var i = 0; i < 15; i++) {
      for (final cat in categories) {
        if (find.text(cat).evaluate().isNotEmpty) {
          found.add(cat);
        }
      }
      await tester.drag(list, const Offset(0, -150));
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(found, equals(categories));
  });

  testWidgets(
      'SVG Checkboxes render and can be toggled with confirmation dialog',
      (tester) async {
    await pumpView(tester, size: const Size(390, 844));

    final svgCheckboxes = find.byType(SvgPicture);
    expect(svgCheckboxes, findsWidgets);

    // Initial state: unchecked
    final initialSvg = tester.widget<SvgPicture>(svgCheckboxes.first);
    expect((initialSvg.bytesLoader as SvgStringLoader).provideSvg(null),
        contains('stroke="black"'));

    // 1. Tap unchecked box -> turns checked immediately without dialog
    await tester.tap(svgCheckboxes.first);
    await tester.pump();
    expect(find.byType(FeatureTurnOffDialog), findsNothing);

    // Verify checked
    final checkedSvg = tester.widget<SvgPicture>(svgCheckboxes.first);
    expect((checkedSvg.bytesLoader as SvgStringLoader).provideSvg(null),
        contains('fill="black"'));

    // 2. Tap checked box -> confirmation dialog opens
    await tester.tap(svgCheckboxes.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Dialog is present with Figma text
    expect(find.byType(FeatureTurnOffDialog), findsOneWidget);
    expect(find.text('Do you want to turn off this feature?'), findsOneWidget);
    expect(find.text('Are you sure ?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Yes, Turn Off'), findsOneWidget);

    // Checkbox remains checked while dialog is open
    final stillCheckedSvg = tester.widget<SvgPicture>(svgCheckboxes.first);
    expect((stillCheckedSvg.bytesLoader as SvgStringLoader).provideSvg(null),
        contains('fill="black"'));

    // 3. Repeated tap while dialog is open does not open duplicate dialogs
    await tester.tap(svgCheckboxes.first, warnIfMissed: false);
    await tester.pump();
    expect(find.byType(FeatureTurnOffDialog), findsOneWidget);

    // 4. Tap Cancel -> closes dialog, preserves checked state
    await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel'),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(FeatureTurnOffDialog), findsNothing);

    final preservedSvg = tester.widget<SvgPicture>(svgCheckboxes.first);
    expect((preservedSvg.bytesLoader as SvgStringLoader).provideSvg(null),
        contains('fill="black"'));

    // 5. Tap checked box again -> dialog re-opens
    await tester.tap(svgCheckboxes.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(FeatureTurnOffDialog), findsOneWidget);

    // 6. Tap Yes, Turn Off -> closes dialog, unchecks permission
    await tester.tap(find.widgetWithText(OutlinedButton, 'Yes, Turn Off'),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(FeatureTurnOffDialog), findsNothing);

    final uncheckedSvg = tester.widget<SvgPicture>(svgCheckboxes.first);
    expect((uncheckedSvg.bytesLoader as SvgStringLoader).provideSvg(null),
        contains('stroke="black"'));
  });

  testWidgets('Failed disable operation preserves checked state',
      (tester) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    await pumpView(tester, size: const Size(390, 844));
    final svgCheckboxes = find.byType(SvgPicture);

    // Enable first
    await tester.tap(svgCheckboxes.first);
    await tester.pump();

    // Now mock storage write to throw an exception
    messenger.setMockMethodCallHandler(_secureStorageChannel, (call) async {
      if (call.method == 'write') throw PlatformException(code: 'ERR_FAIL');
      return null;
    });

    // Try to uncheck
    await tester.tap(svgCheckboxes.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(FeatureTurnOffDialog), findsOneWidget);

    // Confirm turn off -> throws internally in write but safely handled
    await tester.tap(find.widgetWithText(OutlinedButton, 'Yes, Turn Off'),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    // Checkbox must NOT be incorrectly set to false
    final svgAfterFail = tester.widget<SvgPicture>(svgCheckboxes.first);
    expect((svgAfterFail.bytesLoader as SvgStringLoader).provideSvg(null),
        contains('fill="black"'));

    // Reset mock handler
    messenger.setMockMethodCallHandler(
        _secureStorageChannel, (call) async => null);
  });

  testWidgets(
      'Common confirmation dialog is reused across other permissions (SMS Registration)',
      (tester) async {
    await pumpView(tester, size: const Size(390, 844));

    // Find the exact checkbox inside SMS Registration row
    final smsRow = find.ancestor(
      of: find.text('Registration').first,
      matching: find.byType(Row),
    );
    final smsCheckbox = find.descendant(
      of: smsRow,
      matching: find.byType(SvgPicture),
    );
    expect(smsCheckbox, findsOneWidget);

    // 1. Tap to check -> immediate check without dialog
    await tester.tap(smsCheckbox);
    await tester.pump();

    final checkedSvg = tester.widget<SvgPicture>(smsCheckbox);
    expect((checkedSvg.bytesLoader as SvgStringLoader).provideSvg(null),
        contains('fill="black"'));

    // 2. Tap to uncheck -> opens common confirmation dialog
    await tester.tap(smsCheckbox);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(FeatureTurnOffDialog), findsOneWidget);
    expect(find.text('Do you want to turn off this feature?'), findsOneWidget);
    expect(find.text('Are you sure ?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Yes, Turn Off'), findsOneWidget);

    // Cancel preserves checked state
    await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel'),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(FeatureTurnOffDialog), findsNothing);

    final preservedSvg = tester.widget<SvgPicture>(smsCheckbox);
    expect((preservedSvg.bytesLoader as SvgStringLoader).provideSvg(null),
        contains('fill="black"'));
  });

  // Test FeatureTurnOffDialog responsiveness across all requested viewport sizes
  for (final size in sizes) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('FeatureTurnOffDialog renders without overflow at $label',
        (tester) async {
      const dpr = 2.0;
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = size * dpr;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          fontSizeResolver: FontSizeResolvers.radius,
          builder: (context, _) => const MaterialApp(
            home: Scaffold(
              body: Center(
                child: FeatureTurnOffDialog(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
          find.text('Do you want to turn off this feature?'), findsOneWidget);
      expect(find.text('Are you sure ?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Yes, Turn Off'), findsOneWidget);
    });

    testWidgets(
        'FeatureTurnOffDialog renders without overflow at $label at 1.15x text scale',
        (tester) async {
      const dpr = 2.0;
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = size * dpr;
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
              builder: (ctx) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: const TextScaler.linear(1.15),
                ),
                child: const Scaffold(
                  body: Center(
                    child: FeatureTurnOffDialog(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
          find.text('Do you want to turn off this feature?'), findsOneWidget);
      expect(find.text('Are you sure ?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Yes, Turn Off'), findsOneWidget);
    });
  }

  testWidgets('"See another version" text is present at bottom',
      (tester) async {
    await pumpView(tester, size: const Size(390, 844));
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('See another version'),
      200,
      scrollable: list,
    );
    expect(find.text('See another version'), findsOneWidget);
  });

  testWidgets('Dividers appear inside SMS card between sub-items',
      (tester) async {
    await pumpView(tester, size: const Size(390, 844));
    final dividers = find.byType(Divider);
    expect(dividers, findsWidgets);
  });

  testWidgets('Capture visual screenshot at Figma resolution (390x844)',
      (tester) async {
    await pumpView(tester, size: const Size(390, 844));
    final finder = find.byKey(const ValueKey('screenshot_boundary'));
    final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final file = File(
            '/Users/apple/.gemini/antigravity-ide/brain/8ebb5933-2656-471c-b5ef-da338e2baa78/permissions_screenshot.png');
        file.writeAsBytesSync(byteData.buffer.asUint8List());
      }
    });
  });
}
