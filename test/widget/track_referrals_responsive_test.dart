// Responsive + layout tests for the Track Your Referrals screen
// (TrackReferralsView).
//
// Uses the shared nine-size matrix from test/helpers/responsive_test_sizes.dart
// and a fake repository so the summary cards, member cards and fixed footer
// render with dynamic data without touching the network.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/refer_and_earn/repositories/referral_track_repository.dart';
import 'package:e_rupaiya/features/refer_and_earn/views/track_referrals_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

class _FakeTrackRepository extends ReferralTrackRepository {
  _FakeTrackRepository(this.response) : super(dio: Dio());

  final ReferralTrackResponse response;

  @override
  Future<ReferralTrackResponse> fetchTrack() async => response;
}

ReferralTrackResponse _response({
  int total = 12,
  int monthEarnings = 320,
  List<ReferralUser>? referrals,
}) {
  return ReferralTrackResponse(
    status: true,
    totalReferrals: total,
    thisMonthEarnings: monthEarnings,
    referrals: referrals ??
        const [
          ReferralUser(
            name: 'Ivanshu Patil',
            since: 'Sins. 1 Jan 2025',
            commission: 120000,
            badge: 'Super Referrer',
          ),
          ReferralUser(
            name: 'Monu Ali',
            since: 'Sins. 2 Feb 2025',
            commission: 500,
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

Future<void> _pumpTrack(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  ReferralTrackResponse? response,
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
              child: TrackReferralsView(
                repository: _FakeTrackRepository(response ?? _response()),
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
        await _pumpTrack(tester, size: size);
        expect(tester.takeException(), isNull);

        // Header, summary cards, heading and member cards all present.
        expect(find.text('Track Your Referrals'), findsOneWidget);
        expect(find.text('Total Referrals'), findsOneWidget);
        expect(find.text('This Month Earnings'), findsOneWidget);
        expect(find.text('12 Friends Joined'), findsOneWidget);
        expect(find.text('320 E-Coins'), findsOneWidget);
        expect(find.text('My Referrals'), findsOneWidget);
        expect(find.text('Ivanshu Patil'), findsOneWidget);
        expect(find.text('Monu Ali'), findsOneWidget);
        expect(find.text('Your Commission'), findsNWidgets(2));
        expect(find.text('120000 E-Coins'), findsOneWidget);
        expect(find.text('Super Referrer'), findsOneWidget);

        // Fixed footer stays inside the viewport on every size.
        final cta = find.text('Invite Using Whatsapp');
        expect(cta, findsOneWidget);
        expect(tester.getRect(cta).bottom, lessThanOrEqualTo(size.height));
      });
    }
  });

  testWidgets('title is horizontally centred below the nav row',
      (tester) async {
    const size = Size(390, 844);
    await _pumpTrack(tester, size: size);

    final title = find.text('Track Your Referrals');
    final titleRect = tester.getRect(title);
    expect((titleRect.center.dx - size.width / 2).abs(), lessThan(4));

    // Title sits below the back button row (own line, per Figma).
    final back = tester.getRect(find.byIcon(Icons.arrow_back));
    expect(titleRect.top, greaterThan(back.bottom));
  });

  testWidgets('total referrals label pluralizes correctly', (tester) async {
    await _pumpTrack(
      tester,
      size: const Size(390, 844),
      response: _response(total: 1),
    );
    expect(find.text('1 Friend Joined'), findsOneWidget);
    expect(find.text('1 Friends Joined'), findsNothing);
  });

  testWidgets('Super Referrer renders only for qualifying members',
      (tester) async {
    await _pumpTrack(tester, size: const Size(390, 844));
    // Two members, only the first carries the badge from the API.
    expect(find.text('Super Referrer'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('member cards scroll fully above the fixed footer',
      (tester) async {
    const size = Size(360, 640);
    await _pumpTrack(tester, size: size);

    final cta = find.text('Invite Using Whatsapp');
    final ctaRectBefore = tester.getRect(cta);

    final lastCard = find.text('500 E-Coins');
    await tester.dragUntilVisible(
      lastCard,
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    expect(lastCard, findsOneWidget);

    // The final commission pill is fully visible and not covered by the
    // fixed bottom bar.
    expect(tester.getRect(lastCard).bottom, lessThan(ctaRectBefore.top));

    // The footer never moves while content scrolls.
    expect(tester.getRect(cta), ctaRectBefore);
  });

  group('supported text scales', () {
    for (final scale in const [0.85, 1.0, 1.15]) {
      testWidgets('textScale $scale at 360x690', (tester) async {
        await _pumpTrack(tester, size: const Size(360, 690), textScale: scale);
        expect(tester.takeException(), isNull);
        expect(find.text('My Referrals'), findsOneWidget);
        expect(find.text('Invite Using Whatsapp'), findsOneWidget);
      });
    }
  });
}
