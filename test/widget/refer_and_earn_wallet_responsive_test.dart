// Responsive + layout tests for the Wallet screen (ReferAndEarnWalletView).
//
// Uses the shared nine-size matrix from test/helpers/responsive_test_sizes.dart
// and a fake repository so milestone and referral rows render without network.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/refer_and_earn/components/refer_and_earn_app_bar.dart';
import 'package:e_rupaiya/features/refer_and_earn/components/referral_share_actions.dart';
import 'package:e_rupaiya/features/refer_and_earn/repositories/referral_wallet_repository.dart';
import 'package:e_rupaiya/features/refer_and_earn/views/refer_and_earn_wallet_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

class _FakeWalletRepository extends ReferralWalletRepository {
  _FakeWalletRepository(this.summary) : super(dio: Dio());

  final ReferralWalletSummary summary;

  @override
  Future<ReferralWalletSummary> fetchSummary() async => summary;
}

ReferralMilestone _milestone(int target, int reward, {bool completed = false}) {
  return ReferralMilestone(
    targetReferrals: target,
    rewardCoins: reward,
    completed: completed,
    status: completed ? 'completed' : 'pending',
  );
}

final _fiveMilestones = [
  _milestone(5, 50, completed: true),
  _milestone(10, 100, completed: true),
  _milestone(15, 200, completed: true),
  _milestone(20, 500, completed: true),
  _milestone(30, 1000),
];

ReferralWalletSummary _summary({List<ReferralMilestone>? milestones}) {
  return ReferralWalletSummary(
    status: true,
    walletBalance: '50.00',
    totalEarnings: 1200,
    milestones: milestones ?? _fiveMilestones,
    teamCount: 5,
    totalTeamEarnings: 1850,
    myTeam: const [],
    recentReferrals: const [
      RecentReferral(
        name: 'Rekha Joshi',
        joinedMessage: 'Joined today',
        earnings: 40,
        joinedOn: '1 Apr 2025',
      ),
    ],
  );
}

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

Future<void> _pumpWallet(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  ReferralWalletSummary? summary,
  Object? instanceId,
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
              child: ReferAndEarnWalletView(
                key: instanceId == null ? null : ValueKey(instanceId),
                repository: _FakeWalletRepository(summary ?? _summary()),
              ),
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

  group('wallet renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpWallet(tester, size: size);
        expect(tester.takeException(), isNull);

        expect(find.byType(ReferAndEarnAppBar), findsOneWidget);
        expect(find.text('Total Balance'), findsOneWidget);
        expect(find.text('50.00'), findsOneWidget);
        expect(find.text('Unlock Your Next Milestone'), findsOneWidget);
        expect(find.text('View Milestones'), findsOneWidget);
        expect(find.text('Recent Referrals'), findsOneWidget);
        expect(find.text('Rekha Joshi'), findsOneWidget);
        expect(find.text('40 eCoins'), findsOneWidget);

        for (final label in ['01', '02', '03', '04', '05']) {
          expect(find.text(label), findsOneWidget);
        }

        expect(find.text('Invite Using Whatsapp'), findsOneWidget);
        expect(find.byType(ReferralShareFooter), findsOneWidget);
        expect(
          tester.getRect(find.text('Invite Using Whatsapp')).bottom,
          lessThanOrEqualTo(size.height),
        );
      });
    }
  });

  group('hero balance sits under the app bar', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('at ${size.width}x${size.height}', (tester) async {
        await _pumpWallet(tester, size: size);
        final back = tester.getRect(find.byIcon(Icons.arrow_back));
        final balance = tester.getRect(find.text('Total Balance'));
        expect(balance.top, greaterThan(back.bottom));
        expect(balance.top, lessThan(size.height * 0.45));
      });
    }
  });

  testWidgets('default app bar title stays leading-aligned', (tester) async {
    const size = Size(390, 844);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = size * 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ScreenUtilInit(
        designSize: Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        child: MaterialApp(
          home: Scaffold(
            body: ReferAndEarnAppBar(title: 'Refer Friends & Earn Coins'),
          ),
        ),
      ),
    );
    final title = tester.getRect(find.text('Refer Friends & Earn Coins'));
    expect(title.left, lessThan(size.width / 3));
  });

  testWidgets('Recent Referrals section title stays on one line', (tester) async {
    await _pumpWallet(tester, size: const Size(440, 956));
    final size = tester.getSize(find.text('Recent Referrals'));
    expect(size.height, lessThan(40));
  });

  testWidgets('milestone count follows the API, no fabricated rows',
      (tester) async {
    final four = _fiveMilestones.take(4).toList();
    await _pumpWallet(
      tester,
      size: const Size(390, 844),
      summary: _summary(milestones: four),
    );
    expect(find.text('04'), findsOneWidget);
    expect(find.text('05'), findsNothing);
  });

  testWidgets('selected milestone label styling is dynamic', (tester) async {
    await _pumpWallet(tester, size: const Size(390, 844), instanceId: 'a');
    Text label(String name) => tester.widget<Text>(find.text(name));
    expect(label('05').style?.color, const Color(0xFFDD5428));
    expect(label('05').style?.fontWeight, FontWeight.w700);
    expect(label('01').style?.color, const Color(0xFF000000));
    expect(label('01').style?.fontWeight, FontWeight.w500);

    final pendingFirst = [
      _milestone(5, 50),
      ..._fiveMilestones.take(3),
    ];
    await _pumpWallet(
      tester,
      size: const Size(390, 844),
      summary: _summary(milestones: pendingFirst),
      instanceId: 'b',
    );
    expect(label('01').style?.color, const Color(0xFFDD5428));
    expect(label('01').style?.fontWeight, FontWeight.w700);
    expect(label('02').style?.color, const Color(0xFF000000));
    expect(label('02').style?.fontWeight, FontWeight.w500);
  });

  testWidgets('referral list scrolls above the fixed CTA', (tester) async {
    const size = Size(360, 640);
    await _pumpWallet(tester, size: size);

    final cta = find.text('Invite Using Whatsapp');
    final ctaRectBefore = tester.getRect(cta);

    final referralRow = find.text('Rekha Joshi');
    await tester.dragUntilVisible(
      referralRow,
      find.byType(Scrollable).first,
      const Offset(0, -120),
    );
    expect(referralRow, findsOneWidget);

    final row = tester.getRect(referralRow);
    expect(row.bottom, lessThanOrEqualTo(ctaRectBefore.top + 2));

    expect(tester.getRect(cta), ctaRectBefore);
  });

  testWidgets('footer respects the bottom safe-area inset', (tester) async {
    const size = Size(390, 844);
    const inset = 34.0;
    await _pumpWallet(tester, size: size, bottomInset: inset);

    final cta = find.text('Invite Using Whatsapp');
    // The pinned footer's action sits above the home-indicator inset.
    expect(tester.getRect(cta).bottom, lessThanOrEqualTo(size.height - inset));
  });

  group('supported text scales', () {
    for (final scale in [0.85, 1.0, 1.15]) {
      testWidgets('textScale $scale at 360x690', (tester) async {
        await _pumpWallet(
          tester,
          size: const Size(360, 690),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Total Balance'), findsOneWidget);
        expect(find.text('Invite Using Whatsapp'), findsOneWidget);
      });
    }
  });
}
