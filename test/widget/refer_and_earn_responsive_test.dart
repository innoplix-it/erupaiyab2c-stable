import 'dart:io';

import 'package:e_rupaiya/features/refer_and_earn/components/refer_and_earn_app_bar.dart';
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
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
        expect(find.text('My Wallet & Referals'), findsOneWidget);
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
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets(
    'Figma spacing: panel inset 32, wallet h 54, step tile 56 at 440x956',
    (tester) async {
      const size = Size(440, 956);
      await _pumpView(tester, size: size);
      expect(tester.takeException(), isNull);

      final panel =
          tester.getRect(find.byKey(const ValueKey('refer-earn-panel')));
      final wallet =
          tester.getRect(find.byKey(const ValueKey('refer-earn-wallet-pill')));
      final stepTile = tester.getRect(
        find.byKey(const ValueKey('refer-earn-step-tile-1')),
      );

      // Side inset ≈ 32 on the 440 Figma frame (ScreenUtil round-trip).
      expect(wallet.left - panel.left, closeTo(32, 1.5));
      expect(panel.right - wallet.right, closeTo(32, 1.5));
      // Wallet pill height ≈ 54.
      expect(wallet.height, closeTo(54, 1.5));
      // Top pad before wallet ≈ 38.
      expect(wallet.top - panel.top, closeTo(38, 2.0));
      // Step icon tile 56×56 (square via width scale).
      expect(stepTile.width, closeTo(56, 1.5));
      expect(stepTile.height, closeTo(56, 1.5));
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

  testWidgets('canonical helper still includes the nine required sizes',
      (tester) async {
    for (final size in _referEarnTestSizes) {
      expect(responsiveTestScreenSizes, contains(size));
    }
  });
}
