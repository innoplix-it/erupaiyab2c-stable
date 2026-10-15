import 'dart:math' as math;

import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/zero_balance_account/models/zero_balance_bank.dart';
import 'package:e_rupaiya/features/zero_balance_account/views/choose_your_bank_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/responsive_test_sizes.dart';

const _textScales = [0.85, 1.0, 1.15];

final _continue = find.byKey(const ValueKey('chooseBankContinue'));
final _rewardHeading = find.byKey(const ValueKey('chooseBankRewardHeading'));
Finder _bank(String id) => find.byKey(ValueKey('chooseBank_$id'));

Future<void> _pump(
  WidgetTester tester, {
  Size screen = const Size(360, 690),
  double textScale = 1.0,
  Object? extra,
  ValueChanged<ZeroBalanceBank>? onContinue,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push(
              RouteConstants.zeroBalanceChooseBank,
              extra: extra,
            ),
            child: const Text('Zero Balance Account'),
          ),
        ),
      ),
      GoRoute(
        path: RouteConstants.zeroBalanceChooseBank,
        builder: (context, state) => state.extra is num
            ? ChooseYourBankView(
                rewardAmount: state.extra as num,
                onContinue: onContinue,
              )
            : ChooseYourBankView(onContinue: onContinue),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (_, __) => MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.tap(find.text('Zero Balance Account'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('responsive matrix', () {
    for (final screen in responsiveTestScreenSizes) {
      for (final scale in _textScales) {
        testWidgets(
            '${screen.width.toInt()}x${screen.height.toInt()} @ text $scale',
            (tester) async {
          await _pump(tester, screen: screen, textScale: scale);
          expect(tester.takeException(), isNull);
          expect(find.byType(ChooseYourBankView), findsOneWidget);

          final continueRect = tester.getRect(_continue);
          expect(continueRect.bottom, lessThanOrEqualTo(screen.height - 16));
          expect(continueRect.width, lessThanOrEqualTo(screen.width));

          // Figma bottom bar: Continue sits 31 px under the panel top, the
          // hint 10 px under Continue and 30 px above the screen bottom (or
          // just above the safe-area inset when that is larger). All through
          // .r, so the rhythm is identical on every device.
          final hint = find.byKey(const ValueKey('chooseBankContinueHint'));
          final hintRect = tester.getRect(hint);
          final gap = hintRect.top - continueRect.bottom;
          expect(gap, closeTo((10 * 360 / 440).r, 0.01));

          expect(hintRect.center.dx, closeTo(continueRect.center.dx, 0.5));
          final bottomSpace = math.max(
            (30 * 360 / 440).r,
            16 + (8 * 360 / 440).r,
          );
          expect(
            hintRect.bottom,
            closeTo(screen.height - bottomSpace, 0.01),
          );

          // 24 px side margins on the 440 frame, as a share of the width.
          expect(continueRect.left, closeTo(screen.width * 24 / 440, 0.01));
          expect(continueRect.right,
              closeTo(screen.width - screen.width * 24 / 440, 0.01));

          for (final bank in ZeroBalanceBank.partners) {
            await tester.ensureVisible(_bank(bank.id));
            await tester.pumpAndSettle();
            expect(tester.getRect(_bank(bank.id)).right,
                lessThanOrEqualTo(screen.width));
          }
        });
      }
    }
  });

  testWidgets('Continue is inert until a bank is selected', (tester) async {
    ZeroBalanceBank? picked;
    await _pump(tester, onContinue: (bank) => picked = bank);
    expect(find.text('Select a bank to continue'), findsOneWidget);

    await tester.tap(_continue);
    await tester.pump();
    expect(picked, isNull);

    await tester.tap(_bank('kotak_811'));
    await tester.pump();
    // The hint stays under the button after a selection, as in Figma.
    expect(find.text('Select a bank to continue'), findsOneWidget);

    await tester.tap(_continue);
    await tester.pump();
    expect(picked?.id, 'kotak_811');
  });

  testWidgets('reward heading uses the backend amount when provided',
      (tester) async {
    await _pump(tester, extra: 1500);
    expect(
      (tester.widget(_rewardHeading) as Text).data,
      'Earn Up to ₹1,500 to in Rewards',
    );
  });

  testWidgets('reward heading falls back to the default amount',
      (tester) async {
    await _pump(tester);
    expect(
      (tester.widget(_rewardHeading) as Text).data,
      'Earn Up to ₹100 to in Rewards',
    );
  });

  testWidgets('text styles match the Figma spec', (tester) async {
    await _pump(tester, screen: const Size(440, 956));
    TextStyle style(Finder f) => (tester.widget(f) as Text).style!;
    TextStyle styleOf(String text) => style(find.text(text));
    const black = Color(0xFF000000);
    const zinc600 = Color(0xFF52525B);

    expect(style(find.byKey(const ValueKey('chooseBankTitle'))).fontWeight,
        FontWeight.w700);
    expect(style(_rewardHeading).fontWeight, FontWeight.w700);
    for (final bank in ZeroBalanceBank.partners) {
      expect(styleOf(bank.name).fontWeight, FontWeight.w600);
    }

    final body = style(find.byKey(const ValueKey('chooseBankRewardBody')));
    expect(body.fontWeight, FontWeight.w400);
    expect(body.color, black);

    final terms = style(find.byKey(const ValueKey('chooseBankRewardTerms')));
    expect(terms.fontWeight, FontWeight.w400);
    expect(terms.color, black);

    final hint = style(find.byKey(const ValueKey('chooseBankContinueHint')));
    expect(hint.color, zinc600);

    expect(terms.fontSize! / body.fontSize!, closeTo(10 / 14, 0.001));

    // 10 px gap between Continue and the hint.
    final buttonRect = tester.getRect(_continue);
    final hintRect =
        tester.getRect(find.byKey(const ValueKey('chooseBankContinueHint')));
    expect(
      hintRect.top - buttonRect.bottom,
      closeTo((10 * 360 / 440).r, 0.01),
    );
  });

  testWidgets('back arrow returns to the previous route', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('chooseBankBack')));
    await tester.pumpAndSettle();
    expect(find.byType(ChooseYourBankView), findsNothing);
    expect(find.text('Zero Balance Account'), findsOneWidget);
  });
}
