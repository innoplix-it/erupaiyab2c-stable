// Responsive + layout tests for the Referral Milestones screen
// (ReferralMilestonesView).
//
// Uses the shared nine-size matrix from test/helpers/responsive_test_sizes.dart
// and a fake repository so the timeline, cards, progress bars and fixed
// footer render with dynamic data without touching the network.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/refer_and_earn/repositories/referral_milestones_repository.dart';
import 'package:e_rupaiya/features/refer_and_earn/views/referral_milestones_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

class _FakeMilestonesRepository extends ReferralMilestonesRepository {
  _FakeMilestonesRepository(this.response) : super(dio: Dio());

  final ReferralMilestonesResponse response;

  @override
  Future<ReferralMilestonesResponse> fetchMilestones() async => response;
}

// Sample milestone data built from the const model constructors.
const List<ReferralMilestoneItem> _sampleMilestones = [
  ReferralMilestoneItem(
    title: 'Refer 5 Friends',
    reward: '100 E-Coins',
    progressText: '5 / 5 Completed',
    progressCurrent: 5,
    progressTarget: 5,
    completed: true,
    status: 'completed',
  ),
  ReferralMilestoneItem(
    title: 'Refer 20 Friends',
    reward: '500 E-Coins',
    progressText: '5 / 20 Completed',
    progressCurrent: 5,
    progressTarget: 20,
    completed: false,
    status: 'in-progress',
  ),
  ReferralMilestoneItem(
    title: 'Refer 30 Friends',
    reward: '500 E-Coins + Bonus',
    progressText: '20 / 30 Completed',
    progressCurrent: 20,
    progressTarget: 30,
    completed: false,
    status: 'in-progress',
  ),
];

ReferralMilestonesResponse _sampleResponse() {
  return const ReferralMilestonesResponse(
    status: true,
    totalReferrals: 5,
    milestones: _sampleMilestones,
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

Future<void> _pumpMilestones(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  ReferralMilestonesResponse? response,
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
              child: ReferralMilestonesView(
                repository:
                    _FakeMilestonesRepository(response ?? _sampleResponse()),
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

  group('renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpMilestones(tester, size: size);
        expect(tester.takeException(), isNull);

        expect(find.text('Referral Milestones'), findsOneWidget);
        expect(
          find.text('Complete Referral Milestones And Unlock Bonus E-Coins.'),
          findsOneWidget,
        );
        // All three milestone cards render from the API-shaped data.
        expect(find.text('Refer 5 Friends'), findsOneWidget);
        expect(find.text('Refer 20 Friends'), findsOneWidget);
        expect(find.text('Refer 30 Friends'), findsOneWidget);
        expect(find.text('Reward 100 E-Coins'), findsOneWidget);
        expect(find.text('Reward 500 E-Coins + Bonus'), findsOneWidget);
        expect(find.text('5 / 5 Completed'), findsOneWidget);
        expect(find.text('20 / 30 Completed'), findsOneWidget);
        // Remaining text is computed from the data (30 - 20 = 10).
        expect(
          find.text('10 More Referrals To Unlock The Rewards'),
          findsOneWidget,
        );

        final cta = find.text('Refer On Whatsapp');
        expect(cta, findsOneWidget);
        expect(tester.getRect(cta).bottom, lessThanOrEqualTo(size.height));
      });
    }
  });

  testWidgets('title is horizontally centred below the nav row',
      (tester) async {
    const size = Size(390, 844);
    await _pumpMilestones(tester, size: size);

    final titleRect = tester.getRect(find.text('Referral Milestones'));
    expect((titleRect.center.dx - size.width / 2).abs(), lessThan(4));

    final back = tester.getRect(find.byIcon(Icons.arrow_back));
    expect(titleRect.top, greaterThan(back.bottom));
  });

  testWidgets('completed state drives colors, not the screenshot sample',
      (tester) async {
    await _pumpMilestones(tester, size: const Size(390, 844));
    Text status(String text) => tester.widget<Text>(find.text(text));

    // Completed milestone uses the Figma green; incomplete stays grey.
    expect(status('5 / 5 Completed').style?.color, const Color(0xFF058337));
    expect(status('20 / 30 Completed').style?.color, const Color(0xFF7C7C7C));

    // Completed card shows no remaining-referrals message.
    expect(find.text('0 More Referrals To Unlock The Rewards'), findsNothing);
  });

  testWidgets('marker ring is orange only for completed milestones',
      (tester) async {
    await _pumpMilestones(tester, size: const Size(390, 844));
    Color ringColor(int index) {
      final container = tester.widget<Container>(
        find.byKey(ValueKey('milestone-ring-$index')),
      );
      return ((container.decoration!) as BoxDecoration).border!.top.color;
    }

    // Sample data: only milestone 0 is completed.
    expect(ringColor(0), const Color(0xFFDD5428));
    expect(ringColor(1), const Color(0xFFE1E1E1));
    expect(ringColor(2), const Color(0xFFE1E1E1));
  });

  testWidgets('progress bars use the Figma fill and track colors',
      (tester) async {
    await _pumpMilestones(tester, size: const Size(390, 844));
    final bars = tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bars.length, 3);
    for (final bar in bars) {
      expect(bar.valueColor!.value, const Color(0xFFDD5428));
      expect(bar.backgroundColor, const Color(0xFFD0D0D0));
    }
    // Fills reflect the real ratios from the data, not the screenshot.
    expect(bars.first.value, 1.0); // 5 / 5
    expect(bars.elementAt(1).value, closeTo(5 / 20, 0.001));
    expect(bars.elementAt(2).value, closeTo(20 / 30, 0.001));
  });

  testWidgets('zero target is guarded and renders without overflow',
      (tester) async {
    await _pumpMilestones(
      tester,
      size: const Size(360, 690),
      response: const ReferralMilestonesResponse(
        status: true,
        totalReferrals: 0,
        milestones: [
          ReferralMilestoneItem(
            title: 'Refer 0 Friends',
            reward: '0 E-Coins',
            progressText: '',
            progressCurrent: 0,
            progressTarget: 0,
            completed: false,
            status: 'pending',
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Refer 0 Friends'), findsOneWidget);
    // Fallback progress text derived from the counts.
    expect(find.text('0 / 0 Completed'), findsOneWidget);
  });

  testWidgets('footer stays fixed while the last card scrolls above it',
      (tester) async {
    const size = Size(360, 640);
    await _pumpMilestones(tester, size: size);

    final cta = find.text('Refer On Whatsapp');
    final ctaRectBefore = tester.getRect(cta);

    final lastCardText = find.text('10 More Referrals To Unlock The Rewards');
    await tester.dragUntilVisible(
      lastCardText,
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    expect(tester.getRect(lastCardText).bottom, lessThan(ctaRectBefore.top));
    expect(tester.getRect(cta), ctaRectBefore);
  });

  group('supported text scales', () {
    for (final scale in const [0.85, 1.0, 1.15]) {
      testWidgets('textScale $scale at 360x690', (tester) async {
        await _pumpMilestones(
          tester,
          size: const Size(360, 690),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(
          find.text('Complete Referral Milestones And Unlock Bonus E-Coins.'),
          findsOneWidget,
        );
        expect(find.text('Refer On Whatsapp'), findsOneWidget);
      });
    }
  });
}
