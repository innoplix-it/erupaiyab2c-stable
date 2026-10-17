// Responsive + layout tests for the Wallet screen (ReferAndEarnWalletView).
//
// Uses the shared nine-size matrix from test/helpers/responsive_test_sizes.dart
// and a fake repository so every card, tab and team row renders with dynamic
// data without touching the network.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/refer_and_earn/components/refer_and_earn_app_bar.dart';
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
    myTeam: const [
      TeamMember(
          name: 'Ivanshu Patil', since: 'Sins. 1 Jan 2025', earnings: 120),
      TeamMember(name: 'Monu Ali', since: 'Sins. 2 Feb 2025', earnings: 50),
      TeamMember(
          name: 'Surpiya Ithappully', since: 'Sins. 3 Mar 2025', earnings: 100),
    ],
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

Future<void> _pumpWallet(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  ReferralWalletSummary? summary,
  Object? instanceId,
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
              child: ReferAndEarnWalletView(
                // A distinct key resets hook state (useMemoized caches the
                // first future otherwise) when a test pumps twice.
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

        // Header, balance block and sheet content all present.
        expect(find.text('Wallet'), findsOneWidget);
        expect(find.text('Total Balance'), findsOneWidget);
        expect(find.text('Withdraw'), findsOneWidget);
        expect(find.text('Unlock Your Next Milestone'), findsOneWidget);
        expect(find.text('View Milestones'), findsOneWidget);
        expect(find.text('Track Your Referrals'), findsOneWidget);
        expect(find.text('Total Earnings'), findsOneWidget);
        expect(find.text('My Team'), findsOneWidget);
        expect(find.text('Recent Referrals'), findsOneWidget); // tab label
        expect(find.text('Total Team Earnings'), findsOneWidget);
        expect(find.text('View All'), findsOneWidget);

        // Dynamic values from the repository, not Figma sample literals.
        expect(find.text('50.00'), findsOneWidget);
        expect(find.text('1200 E-Coins'), findsOneWidget);
        expect(find.text('1850 E-Coins'), findsOneWidget);

        // Five configured milestones render 01..05 evenly.
        for (final label in ['01', '02', '03', '04', '05']) {
          expect(find.text(label), findsOneWidget);
        }

        // Fixed bottom CTA is visible and inside the viewport.
        expect(find.text('Invite Using Whatsapp'), findsOneWidget);
        expect(
          tester.getRect(find.text('Invite Using Whatsapp')).bottom,
          lessThanOrEqualTo(size.height),
        );
      });
    }
  });

  group('wallet title is screen-centred', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('at ${size.width}x${size.height}', (tester) async {
        await _pumpWallet(tester, size: size);
        final title = tester.getRect(find.text('Wallet'));
        expect(
          (title.center.dx - size.width / 2).abs(),
          lessThan(4),
        );
        // The balance block sits close under the nav row, not floating
        // halfway down the hero.
        final balance = tester.getRect(find.text('Total Balance'));
        expect(balance.top - title.bottom, lessThan(size.height * 0.12));
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
    // Backward compatibility: without centerTitle the text keeps its
    // original leading alignment next to the back button.
    expect(title.left, lessThan(size.width / 3));
  });

  testWidgets('Track Your Referrals stays on one line', (tester) async {
    await _pumpWallet(tester, size: const Size(440, 956));
    final size = tester.getSize(find.text('Track Your Referrals'));
    // Single line: height is bounded by one (scaled) line box.
    expect(size.height, lessThan(30));
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
    // With milestones 1-4 completed, #05 is the active one.
    await _pumpWallet(tester, size: const Size(390, 844), instanceId: 'a');
    Text label(String name) => tester.widget<Text>(find.text(name));
    expect(label('05').style?.color, const Color(0xFFDD5428));
    expect(label('05').style?.fontWeight, FontWeight.w700);
    expect(label('01').style?.color, const Color(0xFF000000));
    expect(label('01').style?.fontWeight, FontWeight.w500);

    // When the first milestone is still pending, the selection (and the
    // orange/bold styling) moves to #01 and #02 reverts to normal.
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

  testWidgets('team rows scroll into view above the fixed CTA', (tester) async {
    const size = Size(360, 640);
    await _pumpWallet(tester, size: size);

    final cta = find.text('Invite Using Whatsapp');
    final ctaRectBefore = tester.getRect(cta);

    final lastMember = find.text('Surpiya Ithappully');
    await tester.dragUntilVisible(
      lastMember,
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    expect(lastMember, findsOneWidget);

    // The row is fully visible and not covered by the fixed bottom bar.
    final row = tester.getRect(lastMember);
    expect(row.bottom, lessThan(ctaRectBefore.top));

    // The CTA never moves while content scrolls.
    expect(tester.getRect(cta), ctaRectBefore);
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
        expect(find.text('Withdraw'), findsOneWidget);
      });
    }
  });
}
