import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/features/home/components/zero_balance_account_popup_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/responsive_test_sizes.dart';

const _textScales = [0.85, 1.0, 1.15];

final _heading = find.byKey(const ValueKey('zeroBalancePopupHeading'));
final _description = find.byKey(const ValueKey('zeroBalancePopupDescription'));
final _maybeLater = find.byKey(const ValueKey('zeroBalancePopupMaybeLater'));
final _openAccount = find.byKey(const ValueKey('zeroBalancePopupOpenAccount'));
final _close = find.byKey(const ValueKey('zeroBalancePopupClose'));

/// Stateful stand-in for the Home screen: proves the route underneath stays
/// mounted and keeps its state while the popup is shown and dismissed.
class _HostScreen extends StatefulWidget {
  const _HostScreen({required this.rewardAmount, required this.onResult});

  final num rewardAmount;
  final ValueChanged<bool> onResult;

  @override
  State<_HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<_HostScreen> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('host taps: $_taps'),
          TextButton(
            onPressed: () => setState(() => _taps++),
            child: const Text('bump'),
          ),
          TextButton(
            onPressed: () async => widget.onResult(
              await showZeroBalanceAccountPopup(
                context,
                rewardAmount: widget.rewardAmount,
              ),
            ),
            child: const Text('open'),
          ),
        ],
      ),
    );
  }
}

Future<void> _pumpHost(
  WidgetTester tester, {
  Size screen = const Size(360, 690),
  double textScale = 1.0,
  EdgeInsets safeArea = EdgeInsets.zero,
  num rewardAmount = 100,
  ValueChanged<bool>? onResult,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(
    left: safeArea.left,
    top: safeArea.top,
    right: safeArea.right,
    bottom: safeArea.bottom,
  );
  addTearDown(tester.view.reset);
  // Same ScreenUtil configuration as lib/main.dart.
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (_, __) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: _HostScreen(
          rewardAmount: rewardAmount,
          onResult: onResult ?? (_) {},
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

String _plain(WidgetTester tester, Finder finder) {
  final widget = tester.widget(finder);
  if (widget is RichText) return widget.text.toPlainText();
  if (widget is Text) return widget.data ?? widget.textSpan!.toPlainText();
  throw StateError('Not a text widget: $widget');
}

void _expectAspect(WidgetTester tester, String asset, double ratio) {
  final finder = find.byWidgetPredicate(
    (w) =>
        w is SvgPicture &&
        w.bytesLoader is SvgAssetLoader &&
        (w.bytesLoader as SvgAssetLoader).assetName == asset,
  );
  expect(finder, findsOneWidget, reason: asset);
  final size = tester.getSize(finder);
  expect(size.width / size.height, closeTo(ratio, 0.01), reason: asset);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('responsive matrix', () {
    for (final screen in responsiveTestScreenSizes) {
      for (final scale in _textScales) {
        final label =
            '${screen.width.toInt()}x${screen.height.toInt()} @ text $scale';
        testWidgets(label, (tester) async {
          const safeArea = EdgeInsets.only(top: 24, bottom: 16);
          await _pumpHost(
            tester,
            screen: screen,
            textScale: scale,
            safeArea: safeArea,
          );
          await tester.tap(find.text('bump'));
          await tester.pump();
          await _open(tester);
          expect(tester.takeException(), isNull);

          // Popup (close icon + card) stays inside the safe area.
          final safeRect = Rect.fromLTRB(
            0,
            safeArea.top,
            screen.width,
            screen.height - safeArea.bottom,
          );
          final popupRect =
              tester.getRect(find.byType(ZeroBalanceAccountPopupView).first);
          final closeRect = tester.getRect(_close);
          final cardRect = tester.getRect(find.byType(ClipRRect).first);
          for (final rect in [closeRect, cardRect]) {
            expect(safeRect.contains(rect.topLeft), isTrue, reason: '$rect');
            expect(
              rect.bottom <= safeRect.bottom + 0.01 &&
                  rect.right <= popupRect.right + 0.01,
              isTrue,
              reason: '$rect',
            );
          }
          expect(cardRect.width, lessThanOrEqualTo(screen.width));

          // Same backend amount in heading and description.
          expect(_plain(tester, _heading), contains('₹100'));
          expect(_plain(tester, _description), contains('₹100'));

          _expectAspect(tester, FileConstants.airtelLogoSvg, 131 / 20);
          _expectAspect(tester, FileConstants.kotakLogoSvg, 100 / 50);
          _expectAspect(tester, FileConstants.zeroPercentBadgeSvg, 195 / 130);

          // Buttons and close icon are on-screen and hit-testable (the card
          // scrolls on the shortest phones, so bring them into view first).
          await tester.ensureVisible(_openAccount);
          await tester.pumpAndSettle();
          for (final target in [_maybeLater, _openAccount, _close]) {
            expect(target.hitTestable(), findsOneWidget);
            final rect = tester.getRect(target);
            expect(safeRect.contains(rect.center), isTrue);
            expect(rect.height, greaterThanOrEqualTo(40 - 0.01));
          }

          await tester.tap(_maybeLater);
          await tester.pumpAndSettle();
          expect(find.byType(ZeroBalanceAccountPopupView), findsNothing);
          expect(find.text('host taps: 1'), findsOneWidget);
        });
      }
    }
  });

  testWidgets('Open Account resolves true', (tester) async {
    bool? result;
    await _pumpHost(tester, onResult: (value) => result = value);
    await _open(tester);
    await tester.tap(_openAccount);
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byType(ZeroBalanceAccountPopupView), findsNothing);
  });

  testWidgets('close icon and barrier resolve false', (tester) async {
    bool? result;
    await _pumpHost(tester, onResult: (value) => result = value);
    await _open(tester);
    await tester.tap(_close);
    await tester.pumpAndSettle();
    expect(result, isFalse);

    result = null;
    await _open(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(find.byType(ZeroBalanceAccountPopupView), findsNothing);
  });

  testWidgets('heading and description use the same backend amount',
      (tester) async {
    await _pumpHost(tester, rewardAmount: 1250.5);
    await _open(tester);
    expect(_plain(tester, _heading), contains('₹1,250.5'));
    expect(_plain(tester, _description), contains('₹1,250.5'));
    expect(_plain(tester, _heading), isNot(contains('₹100')));
    expect(_plain(tester, _description), isNot(contains('₹100')));
  });

  // flutter_svg draws nothing for Figma's <pattern>-wrapped raster exports;
  // the assets must keep a direct <image> so they paint visible pixels.
  testWidgets('popup SVG assets paint visible pixels', (tester) async {
    for (final asset in [
      FileConstants.airtelLogoSvg,
      FileConstants.kotakLogoSvg,
      FileConstants.zeroPercentBadgeSvg,
      FileConstants.giftIconSvg,
      FileConstants.radioUnselectedIconSvg,
    ]) {
      final visible = await tester.runAsync(() async {
        final info = await vg.loadPicture(SvgAssetLoader(asset), null);
        final image = await info.picture.toImage(
          info.size.width.ceil(),
          info.size.height.ceil(),
        );
        final bytes = await image.toByteData();
        var count = 0;
        for (var i = 3; i < bytes!.lengthInBytes; i += 4) {
          if (bytes.getUint8(i) > 0) count++;
        }
        return count;
      });
      expect(visible, greaterThan(0), reason: asset);
    }
  });

  test('formats rewards with Indian grouping', () {
    expect(formatZeroBalanceReward(100), '₹100');
    expect(formatZeroBalanceReward(100.0), '₹100');
    expect(formatZeroBalanceReward(150000), '₹1,50,000');
    expect(formatZeroBalanceReward(49.999), '₹50');
  });
}
