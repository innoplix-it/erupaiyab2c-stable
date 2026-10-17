import 'dart:io';

import 'package:e_rupaiya/features/refer_and_earn/components/referral_share_actions.dart';
import 'package:e_rupaiya/features/refer_and_earn/views/withdraw_e_coins_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

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

Future<void> _pumpWithdraw(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  String balance = '600',
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
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: WithdrawECoinsView(walletBalance: balance),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadRealFonts();
  });

  group('renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpWithdraw(tester, size: size);
        expect(tester.takeException(), isNull);

        expect(find.text('Withdraw E-Coins'), findsOneWidget);
        expect(find.text('600'), findsOneWidget);
        expect(find.text('Current Balance'), findsOneWidget);
        // The conversion badge is now one static SVG (pill + coin + text).
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.text('Enter Coins'), findsOneWidget);
        expect(find.text('Min: 100 Coins | Max: 600 Coins'), findsOneWidget);
        expect(find.text('25%'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        expect(find.text('You Will Receive'), findsOneWidget);
        expect(find.text('Withdraw Now'), findsOneWidget);
      });
    }
  });

  group('chips stay inside the screen on every shared size', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpWithdraw(tester, size: size);
        for (final label in ['25%', '50%', '75%', '100%']) {
          final rect = tester.getRect(find.text(label));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
        }
      });
    }
  });

  testWidgets('max coins use Indian grouping like Figma (3,00,000)',
      (tester) async {
    await _pumpWithdraw(
      tester,
      size: const Size(390, 844),
      balance: '300000',
    );
    expect(find.text('3,00,000'), findsOneWidget);
    expect(find.text('Min: 100 Coins | Max: 3,00,000 Coins'), findsOneWidget);
  });

  testWidgets('balance amount reuses the Refer & Earn amount typography',
      (tester) async {
    await _pumpWithdraw(tester, size: const Size(360, 690));
    final amount = tester.widget<Text>(find.text('600'));
    expect(amount.style?.fontSize, 34.sp);
    expect(amount.style?.fontWeight, FontWeight.w800);
    expect(amount.style?.fontFamily, 'Plus Jakarta Sans');
    expect(amount.style?.height, 1.0);
    expect(amount.style?.letterSpacing, 0);
    expect(amount.style?.color, Colors.white);
  });

  testWidgets('percentage filter updates input and received amount',
      (tester) async {
    await _pumpWithdraw(tester, size: const Size(390, 844));

    await tester.tap(find.text('50%'));
    await tester.pump(const Duration(milliseconds: 100));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '300');
    expect(find.text('₹300'), findsOneWidget);

    // Figma: the selected chip fills with #E7E5E5.
    Color chipFill(String label) {
      // The chip's fill lives on its nearest Material ancestor.
      final chip = tester.widget<Material>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Material))
            .first,
      );
      return chip.color!;
    }

    expect(chipFill('50%'), const Color(0xFFE7E5E5));
    expect(chipFill('25%'), Colors.white);

    await tester.tap(find.text('100%'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('₹600'), findsOneWidget);
    expect(chipFill('100%'), const Color(0xFFE7E5E5));
    expect(chipFill('50%'), Colors.white);
  });

  testWidgets('input amount reuses the Refer & Earn amount typography',
      (tester) async {
    await _pumpWithdraw(tester, size: const Size(360, 690));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.fontSize, 16.sp);
    expect(field.style?.fontWeight, FontWeight.w600);
    expect(field.style?.color, const Color(0xFF000000));
    expect(field.style?.height, 1.0);
    expect(field.style?.letterSpacing, 0);
  });

  testWidgets(
      'footer is the shared Refer & Earn container with only '
      'Withdraw Now', (tester) async {
    await _pumpWithdraw(tester, size: const Size(390, 844));
    expect(find.byType(ReferralShareFooter), findsOneWidget);
    // No WhatsApp/Share actions on this screen.
    expect(find.text('Invite Using Whatsapp'), findsNothing);
    expect(find.text('Refer On Whatsapp'), findsNothing);
    expect(find.byType(ReferralShareActions), findsNothing);
    expect(find.text('Withdraw Now'), findsOneWidget);
    // Full-width: the button spans the footer's inner width.
    final button = tester.getRect(find.text('Withdraw Now')).center;
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(button.dx, closeTo(screen.width / 2, 1));
  });

  testWidgets('below-minimum input shows the validation message',
      (tester) async {
    await _pumpWithdraw(tester, size: const Size(390, 844));
    await tester.enterText(find.byType(TextField), '50');
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text('Enter at least 100 E-Coins to withdraw.'),
      findsOneWidget,
    );
  });

  testWidgets('conversion badge renders as the single static Figma SVG',
      (tester) async {
    await _pumpWithdraw(tester, size: const Size(360, 690));
    // Old hand-drawn glass pill + separate coin/text widgets are gone; the
    // badge is now one SvgPicture (withdraw_glass_badge.svg).
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('1 = ₹1 | Get Real Cash Instant'), findsNothing);
    // It stays inside the header width (not clipped/overflowing).
    final rect = tester.getRect(find.byType(SvgPicture));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(screen.width));
  });

  testWidgets('fixed footer stays visible while notes scroll into view',
      (tester) async {
    await _pumpWithdraw(tester, size: const Size(320, 480));
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getRect(find.text('Withdraw Now')).bottom,
        lessThan(size.height));

    await tester.dragUntilVisible(
      find.text('Once A Withdrawal Request Is Submitted, It Cannot Be '
          'Cancelled.'),
      find.byType(SingleChildScrollView).first,
      const Offset(0, -60),
    );
    expect(find.text('Withdraw Now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('supported text scales', () {
    for (final scale in [0.85, 1.0, 1.15]) {
      testWidgets('textScale $scale at 360x690', (tester) async {
        await _pumpWithdraw(
          tester,
          size: const Size(360, 690),
          textScale: scale,
        );
        expect(find.text('Enter Coins'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
