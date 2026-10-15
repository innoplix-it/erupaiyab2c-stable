// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/home/components/zero_balance_account_popup_view.dart';
import 'package:e_rupaiya/features/zero_balance_account/components/zero_balance_account_success_popup.dart';
import 'package:e_rupaiya/features/zero_balance_account/models/zero_balance_bank.dart';
import 'package:e_rupaiya/features/zero_balance_account/views/choose_your_bank_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/responsive_test_sizes.dart';

const _textScales = [0.85, 1.0, 1.15];
const _safeArea = EdgeInsets.only(top: 24, bottom: 16);

final _popup = find.byType(ZeroBalanceAccountSuccessPopup);
final _heading = find.byKey(const ValueKey('zeroBalanceSuccessHeading'));
final _message = find.byKey(const ValueKey('zeroBalanceSuccessMessage'));
final _reward = find.byKey(const ValueKey('zeroBalanceSuccessReward'));
final _rewardText = find.byKey(const ValueKey('zeroBalanceSuccessRewardText'));
final _rewardBg = find.byKey(const ValueKey('zeroBalanceSuccessRewardBg'));
final _badge = find.byKey(const ValueKey('zeroBalanceSuccessBadge'));
final _close = find.byKey(const ValueKey('zeroBalanceSuccessClose'));
final _done = find.byKey(const ValueKey('zeroBalanceSuccessDone'));
final _viewBalance =
    find.byKey(const ValueKey('zeroBalanceSuccessViewBalance'));
final _continue = find.byKey(const ValueKey('chooseBankContinue'));

Future<void> _pumpFlow(
  WidgetTester tester, {
  Size screen = const Size(360, 690),
  double textScale = 1.0,
  num? creditedRewardAmount,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(
    top: _safeArea.top,
    bottom: _safeArea.bottom,
  );
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  context.push(RouteConstants.zeroBalanceChooseBank),
              child: const Text('Home'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: RouteConstants.zeroBalanceChooseBank,
        builder: (context, _) =>
            ChooseYourBankView(creditedRewardAmount: creditedRewardAmount),
      ),
      GoRoute(
        path: RouteConstants.referAndEarnWallet,
        builder: (context, _) => const Scaffold(body: Text('Wallet screen')),
      ),
    ],
  );
  addTearDown(router.dispose);
  // Same ScreenUtil configuration as lib/main.dart.
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
  await tester.tap(find.text('Home'));
  await tester.pumpAndSettle();
}

Future<void> _selectAndContinue(WidgetTester tester, ZeroBalanceBank bank) async {
  final tile = find.byKey(ValueKey('chooseBank_${bank.id}'));
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pump();
  await tester.tap(_continue);
  await tester.pumpAndSettle();
}

String _plain(WidgetTester tester, Finder finder) {
  final widget = tester.widget(finder);
  if (widget is RichText) return widget.text.toPlainText();
  if (widget is Text) return widget.data ?? widget.textSpan!.toPlainText();
  throw StateError('Not a text widget: $widget');
}

TextSpan _spanWithText(WidgetTester tester, Finder finder, String text) {
  final root = (tester.widget(finder) as Text).textSpan!;
  TextSpan? match;
  root.visitChildren((span) {
    if (span is TextSpan && span.text == text) {
      match = span;
      return false;
    }
    return true;
  });
  return match!;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('responsive matrix', () {
    final banks = ZeroBalanceBank.partners;
    var run = 0;
    for (final screen in responsiveTestScreenSizes) {
      for (final scale in _textScales) {
        final bank = banks[run++ % banks.length];
        testWidgets(
            '${screen.width.toInt()}x${screen.height.toInt()} @ text $scale '
            '(${bank.name})', (tester) async {
          await _pumpFlow(tester, screen: screen, textScale: scale);
          await _selectAndContinue(tester, bank);
          expect(tester.takeException(), isNull);
          expect(_popup, findsOneWidget);

          expect(_plain(tester, _heading), 'Congratulations!');
          expect(
            _plain(tester, _message),
            'Your zero balance account with ${bank.name} is open.',
          );

          final safeRect = Rect.fromLTRB(
            0,
            _safeArea.top,
            screen.width,
            screen.height - _safeArea.bottom,
          );
          final closeRect = tester.getRect(_close);
          expect(safeRect.contains(closeRect.topLeft), isTrue);
          expect(safeRect.contains(closeRect.bottomRight), isTrue);
          expect(closeRect.width, greaterThanOrEqualTo(40));

          // Reward pill: 319 / 440 of the screen width (capped to the card),
          // at least 38 / 978 of its height, and its contents never overflow.
          await tester.ensureVisible(_reward);
          await tester.pumpAndSettle();
          final pill = tester.getRect(_reward);
          final card = tester.getRect(find.descendant(
            of: _popup,
            matching: find.byType(ClipRRect),
          ));
          expect(pill.width, lessThanOrEqualTo(screen.width * 319 / 440 + 0.01));
          expect(pill.left, greaterThanOrEqualTo(card.left));
          expect(pill.right, lessThanOrEqualTo(card.right));
          expect(
            pill.height,
            greaterThanOrEqualTo(screen.height * 38 / 978 - 0.01),
          );
          // SVG background covers the pill; the live text stays inside it.
          expect(tester.getRect(_rewardBg), pill);
          final r = tester.getRect(_rewardText);
          expect(r.left, greaterThanOrEqualTo(pill.left), reason: '$r');
          expect(r.right, lessThanOrEqualTo(pill.right), reason: '$r');
          expect(r.top, greaterThanOrEqualTo(pill.top), reason: '$r');
          expect(r.bottom, lessThanOrEqualTo(pill.bottom), reason: '$r');

          // Badge keeps the SVG's 1:1 aspect ratio.
          final badgeSize = tester.getSize(_badge);
          expect(badgeSize.width, closeTo(badgeSize.height, 0.01));

          // Buttons are fully on-screen inside the safe area once the card
          // is scrolled to them (short phones scroll the card).
          for (final button in [_done, _viewBalance]) {
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            final rect = tester.getRect(button);
            expect(safeRect.contains(rect.topLeft), isTrue, reason: '$rect');
            expect(rect.bottom, lessThanOrEqualTo(safeRect.bottom + 0.01));
            expect(rect.height, greaterThanOrEqualTo(40 - 0.01));
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('selected bank is propagated for each option', (tester) async {
    for (final bank in ZeroBalanceBank.partners) {
      await _pumpFlow(tester);
      await _selectAndContinue(tester, bank);
      final bankSpan = _spanWithText(tester, _message, bank.name);
      expect(bankSpan.style?.color, const Color(0xFFDD5428));
      await tester.tap(_close);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('reward shows ₹0 until the backend supplies an amount',
      (tester) async {
    await _pumpFlow(tester);
    await _selectAndContinue(tester, ZeroBalanceBank.partners.first);
    expect(
      _plain(tester, _rewardText),
      '₹0 has been added to your eRupaiya wallet',
    );
  });

  testWidgets('reward uses the backend amount and highlights it',
      (tester) async {
    await _pumpFlow(tester, creditedRewardAmount: 1250);
    await _selectAndContinue(tester, ZeroBalanceBank.partners.last);
    expect(
      _plain(tester, _rewardText),
      '₹1,250 has been added to your eRupaiya wallet',
    );
    final amount = _spanWithText(tester, _rewardText, '₹1,250').style!;
    expect(amount.color, const Color(0xFFDD5428));
    expect(amount.fontWeight, FontWeight.w700);
    final message = (tester.widget(_rewardText) as Text).textSpan!.style!;
    expect(message.color, const Color(0xFF000000));
  });

  testWidgets('reward pill matches the Figma 319 x 38 spec on a 440 frame',
      (tester) async {
    await _pumpFlow(tester, screen: const Size(440, 978));
    await _selectAndContinue(tester, ZeroBalanceBank.partners.first);
    expect(tester.getRect(_reward).width, closeTo(319, 0.01));

    // Test fonts (Ahem) are far wider than Plus Jakarta Sans and wrap the
    // message, so assert the 38 px rule itself rather than the laid-out
    // height.
    final pill = tester.widget<ConstrainedBox>(_reward);
    expect(pill.constraints.minHeight, closeTo(38, 0.01));

    final bg = tester.widget<SvgPicture>(_rewardBg);
    expect(
      (bg.bytesLoader as SvgAssetLoader).assetName,
      FileConstants.zeroBalanceRewardPillBgSvg,
    );
    expect(bg.fit, BoxFit.fill);

    final textLeft = tester.getRect(_rewardText).left;
    final textRight = tester.getRect(_rewardText).right;
    final pillRect = tester.getRect(_reward);
    expect(textLeft - pillRect.left,
        greaterThanOrEqualTo((17 * 360 / 440).w - 0.01));
    expect(pillRect.right - textRight,
        greaterThanOrEqualTo((17 * 360 / 440).w - 0.01));
  });

  testWidgets('reward pill SVG paints visible pixels', (tester) async {
    final visible = await tester.runAsync(() async {
      final info = await vg.loadPicture(
        SvgAssetLoader(FileConstants.zeroBalanceRewardPillBgSvg),
        null,
      );
      final image = await info.picture.toImage(319, 38);
      final bytes = await image.toByteData();
      var count = 0;
      for (var i = 3; i < bytes!.lengthInBytes; i += 4) {
        if (bytes.getUint8(i) > 0) count++;
      }
      return count;
    });
    expect(visible, greaterThan(0));
  });

  testWidgets('heading and message typography', (tester) async {
    await _pumpFlow(tester, screen: const Size(440, 956));
    await _selectAndContinue(tester, ZeroBalanceBank.partners.first);
    final heading = (tester.widget(_heading) as Text).style!;
    expect(heading.fontWeight, FontWeight.w700);
    expect(heading.fontStyle, FontStyle.italic);
    expect(heading.color, const Color(0xFF000000));
    expect(heading.height, closeTo(36 / 24, 0.001));
    expect(heading.letterSpacing, closeTo(heading.fontSize! * -0.02, 1e-6));

    final message = (tester.widget(_message) as Text).textSpan!.style!;
    expect(message.fontWeight, FontWeight.w500);
    expect(message.height, closeTo(24 / 14, 0.001));
    expect(message.letterSpacing, closeTo(message.fontSize! * -0.02, 1e-6));
  });

  testWidgets('reuses the success SVG and shared close button',
      (tester) async {
    await _pumpFlow(tester);
    await _selectAndContinue(tester, ZeroBalanceBank.partners.first);
    final badge = tester.widget<SvgPicture>(_badge);
    expect(
      (badge.bytesLoader as SvgAssetLoader).assetName,
      FileConstants.mpinSuccessBadge,
    );
    expect(
      find.ancestor(
        of: _close,
        matching: find.byType(ZeroBalancePopupCloseButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('close dismisses the popup and keeps Choose Your Bank',
      (tester) async {
    await _pumpFlow(tester);
    await _selectAndContinue(tester, ZeroBalanceBank.partners.first);
    await tester.tap(_close);
    await tester.pumpAndSettle();
    expect(_popup, findsNothing);
    expect(find.byType(ChooseYourBankView), findsOneWidget);
  });

  testWidgets('Done dismisses the popup and leaves the account flow',
      (tester) async {
    await _pumpFlow(tester);
    await _selectAndContinue(tester, ZeroBalanceBank.partners.first);
    await tester.ensureVisible(_done);
    await tester.pumpAndSettle();
    await tester.tap(_done);
    await tester.pumpAndSettle();
    expect(_popup, findsNothing);
    expect(find.byType(ChooseYourBankView), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('View Balance opens the existing wallet route', (tester) async {
    await _pumpFlow(tester);
    await _selectAndContinue(tester, ZeroBalanceBank.partners.first);
    await tester.ensureVisible(_viewBalance);
    await tester.pumpAndSettle();
    await tester.tap(_viewBalance);
    await tester.pumpAndSettle();
    expect(_popup, findsNothing);
    expect(find.text('Wallet screen'), findsOneWidget);
    expect(find.byType(ChooseYourBankView), findsNothing);
  });

  testWidgets('Choose Your Bank back arrow pops like MyAppBar',
      (tester) async {
    await _pumpFlow(tester);
    await tester.tap(find.byKey(const ValueKey('chooseBankBack')));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
