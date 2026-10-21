import 'dart:io';

import 'package:e_rupaiya/features/refer_and_earn/components/refer_and_earn_app_bar.dart';
import 'package:e_rupaiya/features/refer_and_earn/components/refer_help_icon_button.dart';
import 'package:e_rupaiya/features/refer_and_earn/providers/referral_link_provider.dart';
import 'package:e_rupaiya/features/refer_and_earn/repositories/referral_repository.dart';
import 'package:e_rupaiya/features/refer_and_earn/views/refer_and_earn_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../helpers/responsive_test_sizes.dart';

/// The nine sizes required for this Refer & Earn Figma pass.
const _referEarnTestSizes = <Size>[
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

const _fakeLink = ReferralLinkResponse(
  status: true,
  referralCode: 'ERU123',
  referralLink: 'https://erupaiya.com/user/ERU123',
  rewardCoins: 100,
);

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

Future<void> _pumpView(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  bool linkFails = false,
  double bottomInset = 0.0,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (bottomInset > 0) {
    tester.view.padding = FakeViewPadding(bottom: bottomInset * dpr);
    addTearDown(tester.view.resetPadding);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        referralLinkProvider.overrideWith((ref) async {
          if (linkFails) {
            throw Exception('network');
          }
          return _fakeLink;
        }),
      ],
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
              child: const ReferAndEarnView(),
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

  for (final size in _referEarnTestSizes) {
    testWidgets(
      'renders Figma Refer & Earn without overflow at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _pumpView(tester, size: size);
        expect(tester.takeException(), isNull);

        expect(find.text('One Refer = 100 eCoins'), findsOneWidget);
        expect(find.text('My Wallet & Referrals'), findsOneWidget);
        expect(find.text('How It Works'), findsOneWidget);
        expect(find.text('Invite Your Friends'), findsOneWidget);
        expect(find.text('They join eRupaiya'), findsOneWidget);
        expect(find.text('First Eligible Payment'), findsOneWidget);
        expect(find.text('You get the matching reward'), findsOneWidget);
        expect(find.text('My Referral QR'), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.byKey(const ValueKey('refer-earn-url')), findsOneWidget);
        expect(find.text('Download'), findsOneWidget);
        expect(find.text('share'), findsOneWidget);
        expect(find.textContaining('Your Coins.'), findsOneWidget);
        expect(find.text('Invite Using Whatsapp'), findsOneWidget);

        final buttonRect = tester.getRect(find.text('Invite Using Whatsapp'));
        expect(buttonRect.bottom, lessThanOrEqualTo(size.height));
        expect(buttonRect.top, greaterThanOrEqualTo(0));
      },
    );

    testWidgets(
      'hero panel overlap stays continuous at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _pumpView(tester, size: size);
        expect(tester.takeException(), isNull);

        final hero =
            tester.getRect(find.byKey(const ValueKey('refer-earn-hero')));
        final panel =
            tester.getRect(find.byKey(const ValueKey('refer-earn-panel')));
        final title =
            tester.getRect(find.byKey(const ValueKey('refer-earn-hero-title')));

        expect(hero.bottom, greaterThanOrEqualTo(panel.top - 2));
        expect(title.top, greaterThan(0));
        expect(panel.top, lessThan(size.height * 0.55));
      },
    );
  }

  testWidgets('supports large text scaling without overflow', (tester) async {
    await _pumpView(
      tester,
      size: const Size(360, 690),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Invite Using Whatsapp'), findsOneWidget);
    expect(find.text('How It Works'), findsOneWidget);
  });

  testWidgets('reuses the common ReferAndEarnAppBar', (tester) async {
    await _pumpView(tester, size: const Size(390, 844));
    expect(find.byType(ReferAndEarnAppBar), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    // Figma help control: white circular badge with "?".
    expect(find.byType(ReferHelpIconButton), findsOneWidget);
  });

  testWidgets(
    'Figma spacing: panel inset 22, wallet h 54, step tile 56 at 440x956',
    (tester) async {
      const size = Size(440, 956);
      await _pumpView(tester, size: size);
      expect(tester.takeException(), isNull);

      final panel =
          tester.getRect(find.byKey(const ValueKey('refer-earn-panel')));
      final walletRing =
          tester.getRect(find.byKey(const ValueKey('refer-earn-wallet-ring')));
      final walletPill =
          tester.getRect(find.byKey(const ValueKey('refer-earn-wallet-pill')));
      final stepTile = tester.getRect(
        find.byKey(const ValueKey('refer-earn-step-tile-1')),
      );

      // Outer ring inset ≈ 22 on the 440 Figma frame.
      expect(walletRing.left - panel.left, closeTo(22, 1.5));
      expect(panel.right - walletRing.right, closeTo(22, 1.5));
      // Wallet pill height ≈ 54.
      expect(walletPill.height, closeTo(54, 1.5));
      // Top pad before wallet ring ≈ 27.
      expect(walletRing.top - panel.top, closeTo(27, 2.0));
      // Step icon tile 58×58 (Figma).
      expect(stepTile.width, closeTo(58, 2.0));
      expect(stepTile.height, closeTo(58, 2.0));
    },
  );

  testWidgets('shows QR error state when referral link fails', (tester) async {
    await _pumpView(
      tester,
      size: const Size(360, 690),
      linkFails: true,
    );
    await tester.pump();
    expect(find.text('Failed to load referral link.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('hero title uses dynamic rewardCoins from API', (tester) async {
    const dpr = 2.0;
    const size = Size(360, 690);
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = size * dpr;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          referralLinkProvider.overrideWith(
            (ref) async => const ReferralLinkResponse(
              status: true,
              referralCode: 'X',
              referralLink: 'https://erupaiya.com/user/X',
              rewardCoins: 250,
            ),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, _) => const MaterialApp(
            home: ReferAndEarnView(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('One Refer = 250 eCoins'), findsOneWidget);
    expect(find.text('One Refer = 100 eCoins'), findsNothing);
  });

  testWidgets('QR card uses Figma border and Download/Share alignment',
      (tester) async {
    const size = Size(440, 956);
    await _pumpView(tester, size: size);
    expect(tester.takeException(), isNull);

    final card = tester.widget<Container>(
      find.byKey(const ValueKey('refer-earn-qr-card')),
    );
    final decoration = card.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.top.color, const Color(0xFFF1F1F1));
    expect(border.top.width, 2);

    final download = tester.getRect(find.text('Download'));
    final share = tester.getRect(find.text('share'));
    expect(download.center.dy, closeTo(share.center.dy, 2));
    expect(share.left, greaterThan(download.right));
  });

  testWidgets('canonical helper still includes the nine required sizes',
      (tester) async {
    for (final size in _referEarnTestSizes) {
      expect(responsiveTestScreenSizes, contains(size));
    }
  });

  testWidgets('footer stays pinned while content scrolls independently',
      (tester) async {
    const size = Size(360, 640);
    await _pumpView(tester, size: size);

    final footer = find.byKey(const ValueKey('refer-earn-sticky-footer'));
    final panel = find.byKey(const ValueKey('refer-earn-panel'));
    final footerBefore = tester.getRect(footer);
    final panelTopBefore = tester.getRect(panel).top;

    // Drag the scrolling content region upward.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();

    // The shared footer did not move: it is pinned, not part of the scroll.
    expect(tester.getRect(footer), footerBefore);
    expect(tester.getRect(footer).bottom, lessThanOrEqualTo(size.height));
    // The content scrolled independently (panel moved up under the footer).
    expect(tester.getRect(panel).top, lessThan(panelTopBefore));
  });

  testWidgets('last content clears the pinned footer when scrolled to end',
      (tester) async {
    const size = Size(360, 640);
    await _pumpView(tester, size: size);

    final footer = find.byKey(const ValueKey('refer-earn-sticky-footer'));
    final lastCopy = find.textContaining('real value for your everyday');
    expect(lastCopy, findsOneWidget);

    // Scroll to the very bottom of the content.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();

    // Nothing is hidden behind the footer: the final paragraph sits above it.
    expect(
      tester.getRect(lastCopy).bottom,
      lessThanOrEqualTo(tester.getRect(footer).top + 1),
    );
  });

  testWidgets('footer respects the bottom safe-area inset', (tester) async {
    const size = Size(390, 844);
    const inset = 34.0;
    await _pumpView(tester, size: size, bottomInset: inset);

    final button = tester.getRect(find.text('Invite Using Whatsapp'));
    // The share action must sit above the home-indicator inset, never under it.
    expect(button.bottom, lessThanOrEqualTo(size.height - inset));
  });

  testWidgets('sticky wallet pill appears on scroll and hides at rest',
      (tester) async {
    const size = Size(360, 640);
    await _pumpView(tester, size: size);

    // At rest only the in-flow panel pill exists (Figma position preserved).
    expect(find.text('My Wallet & Referrals'), findsOneWidget);

    // Scroll well past the hero: the sticky copy is pinned to the top.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('My Wallet & Referrals'), findsNWidgets(2));

    final appBar = tester.getRect(
      find.byKey(const ValueKey('refer-earn-sticky-app-bar')),
    );
    expect(appBar.top, 0);
    final tops = find.text('My Wallet & Referrals').evaluate().map(
          (e) => (e.renderObject! as RenderBox)
              .localToGlobal(Offset.zero)
              .dy,
        );
    expect(
      tops.any((t) => t >= appBar.bottom - 1 && t < appBar.bottom + 120),
      isTrue,
      reason: 'a wallet pill should sit under the pinned app bar',
    );

    // Back to the top: the sticky overlay is removed again.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('My Wallet & Referrals'), findsOneWidget);
  });
}
