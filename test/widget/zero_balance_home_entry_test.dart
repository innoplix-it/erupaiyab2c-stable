import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/home/components/home_icon_tile.dart';
import 'package:e_rupaiya/features/home/components/zero_balance_account_popup_view.dart';
import 'package:e_rupaiya/features/home/views/home_view.dart';
import 'package:e_rupaiya/features/zero_balance_account/models/zero_balance_bank.dart';
import 'package:e_rupaiya/features/zero_balance_account/views/choose_your_bank_view.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/responsive_test_sizes.dart';

const _textScales = [0.85, 1.0, 1.15];
const _safeArea = EdgeInsets.only(top: 24, bottom: 16);
const _reward = 250;

final _tile = find.text('Zero Balance\nAccount');
final _offer = find.byType(ZeroBalanceAccountPopupView);
final _openAccount = find.byKey(const ValueKey('zeroBalancePopupOpenAccount'));
final _maybeLater = find.byKey(const ValueKey('zeroBalancePopupMaybeLater'));
final _offerClose = find.byKey(const ValueKey('zeroBalancePopupClose'));
final _chooseBank = find.byType(ChooseYourBankView);

/// Home stand-in hosting the real investment-row tile, wired to the same
/// entry point HomeView uses. The counter proves Home keeps its state.
class _HomeHost extends StatefulWidget {
  const _HomeHost();

  @override
  State<_HomeHost> createState() => _HomeHostState();
}

class _HomeHostState extends State<_HomeHost> {
  int _bumps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('home bumps: $_bumps'),
          TextButton(
            onPressed: () => setState(() => _bumps++),
            child: const Text('bump'),
          ),
          debugHomeInvestmentRow(
            onZeroBalanceTap: () =>
                openZeroBalanceAccountOffer(context, rewardAmount: _reward),
          ),
        ],
      ),
    );
  }
}

Future<void> _settle(WidgetTester tester) async {
  // The row's Lottie loops forever, so pumpAndSettle would never return.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpHome(
  WidgetTester tester, {
  Size screen = const Size(360, 690),
  double textScale = 1.0,
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
      GoRoute(path: '/', builder: (_, __) => const _HomeHost()),
      GoRoute(
        path: RouteConstants.zeroBalanceOffer,
        pageBuilder: buildZeroBalanceOfferPage,
      ),
      GoRoute(
        path: RouteConstants.zeroBalanceChooseBank,
        builder: (context, state) => state.extra is num
            ? ChooseYourBankView(rewardAmount: state.extra as num)
            : const ChooseYourBankView(),
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
  await _settle(tester);
}

Future<void> _openOffer(WidgetTester tester) async {
  await tester.tap(_tile);
  await _settle(tester);
}

Future<void> _tapOpenAccount(WidgetTester tester) async {
  await tester.ensureVisible(_openAccount);
  await _settle(tester);
  await tester.tap(_openAccount);
  await _settle(tester);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Home -> offer popup -> Choose Your Bank', () {
    for (final screen in responsiveTestScreenSizes) {
      for (final scale in _textScales) {
        testWidgets(
            '${screen.width.toInt()}x${screen.height.toInt()} @ text $scale',
            (tester) async {
          await _pumpHome(tester, screen: screen, textScale: scale);
          await _openOffer(tester);
          expect(tester.takeException(), isNull);

          // Popup over a dimmed, still-mounted Home.
          expect(_offer, findsOneWidget);
          expect(find.byType(HomeServiceCircle), findsWidgets);
          final barriers = tester
              .widgetList<ModalBarrier>(find.byType(ModalBarrier))
              .where((b) => b.color != null && b.color!.a > 0);
          expect(barriers, isNotEmpty);

          await _tapOpenAccount(tester);
          expect(tester.takeException(), isNull);
          expect(_offer, findsNothing);
          expect(_chooseBank, findsOneWidget);
          for (final bank in ZeroBalanceBank.partners) {
            expect(find.text(bank.name), findsOneWidget);
          }
          // Backend reward carried over from Home into Choose Your Bank.
          expect(
            (tester.widget(find.byKey(
                        const ValueKey('chooseBankRewardHeading'))) as Text)
                .data,
            contains('₹$_reward'),
          );
        });
      }
    }
  });

  testWidgets('Home keeps its state after Maybe Later and close',
      (tester) async {
    await _pumpHome(tester);
    await tester.tap(find.text('bump'));
    await tester.pump();

    await _openOffer(tester);
    await tester.ensureVisible(_maybeLater);
    await _settle(tester);
    await tester.tap(_maybeLater);
    await _settle(tester);
    expect(_offer, findsNothing);
    expect(_chooseBank, findsNothing);
    expect(find.text('home bumps: 1'), findsOneWidget);

    await _openOffer(tester);
    await tester.tap(_offerClose);
    await _settle(tester);
    expect(_offer, findsNothing);
    expect(_chooseBank, findsNothing);
    expect(find.text('home bumps: 1'), findsOneWidget);
  });

  testWidgets('a second tap while the offer is open opens nothing extra',
      (tester) async {
    await _pumpHome(tester);
    await tester.tap(_tile);
    await tester.tap(_tile, warnIfMissed: false);
    await _settle(tester);
    expect(_offer, findsOneWidget);

    await _tapOpenAccount(tester);
    expect(_chooseBank, findsOneWidget);
  });

  testWidgets('back from Choose Your Bank returns to Home without the popup',
      (tester) async {
    await _pumpHome(tester);
    await _openOffer(tester);
    await _tapOpenAccount(tester);
    await tester.tap(find.byKey(const ValueKey('chooseBankBack')));
    await _settle(tester);
    expect(_chooseBank, findsNothing);
    expect(_offer, findsNothing);
    expect(_tile, findsOneWidget);
  });

  testWidgets('both banks selectable; Continue inert until one is picked',
      (tester) async {
    await _pumpHome(tester);
    await _openOffer(tester);
    await _tapOpenAccount(tester);
    final continueBtn = find.byKey(const ValueKey('chooseBankContinue'));

    await tester.tap(continueBtn);
    await _settle(tester);
    expect(find.text('Congratulations!'), findsNothing);

    for (final bank in ZeroBalanceBank.partners) {
      final tile = find.byKey(ValueKey('chooseBank_${bank.id}'));
      await tester.ensureVisible(tile);
      await _settle(tester);
      await tester.tap(tile);
      await tester.pump();
      final semantics = tester.getSemantics(tile);
      expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
    }
  });

  testWidgets('offer popup is the GoRouter zero-balance offer route',
      (tester) async {
    await _pumpHome(tester);
    await _openOffer(tester);
    final router = GoRouter.of(tester.element(_offer));
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      RouteConstants.zeroBalanceOffer,
    );

    // Barrier tap dismisses back to Home, nothing else opens.
    await tester.tapAt(const Offset(4, 300));
    await _settle(tester);
    expect(_offer, findsNothing);
    expect(_chooseBank, findsNothing);
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation, '/');

    // The flow can be reopened after a dismissal.
    await _openOffer(tester);
    expect(_offer, findsOneWidget);
  });
}
