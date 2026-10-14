// Responsive coverage for the auth dialogs: TemporaryBlockDialog and
// NewDeviceVerificationDialog.
//
// Uses the canonical `responsiveTestScreenSizes` matrix from
// test/helpers/responsive_test_sizes.dart - the device list is never
// duplicated here. No Figma reference exists for these dialogs, so these
// tests check layout safety and the existing button wiring only.

import 'package:e_rupaiya/config/temporary_block_debug_config.dart';
import 'package:e_rupaiya/features/auth/components/new_device_verification_dialog.dart';
import 'package:e_rupaiya/features/auth/components/temporary_block_dialog.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/responsive_test_sizes.dart';

/// Opens [dialog] through showDialog, so it gets the real dialog constraints.
Future<void> _showDialog(
  WidgetTester tester,
  Widget dialog, {
  Size size = const Size(360, 690),
  double textScale = 1.0,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: padding,
            viewPadding: padding,
          ),
          child: child!,
        ),
        home: const Scaffold(body: SizedBox.expand()),
      ),
    ),
  );
  showDialog<void>(
    context: tester.element(find.byType(Scaffold)),
    builder: (_) => dialog,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _expectDialogInsideScreen(
  WidgetTester tester,
  Size size, {
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  final dialog = tester.getRect(find.byType(Dialog));
  expect(dialog.left, greaterThanOrEqualTo(0));
  expect(dialog.right, lessThanOrEqualTo(size.width));
  expect(dialog.top, greaterThanOrEqualTo(padding.top));
  expect(dialog.bottom, lessThanOrEqualTo(size.height - padding.bottom));

  final buttons = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(CustomElevatedButton),
  );
  // Short phones scroll the dialog body, so the CTA must be reachable.
  await tester.ensureVisible(buttons.first);
  await tester.pump();
  for (final rect in tester.widgetList(buttons).map(
        (w) => tester.getRect(find.byWidget(w)),
      )) {
    expect(rect.top, greaterThanOrEqualTo(dialog.top));
    expect(rect.left, greaterThanOrEqualTo(dialog.left));
    expect(rect.right, lessThanOrEqualTo(dialog.right));
    expect(rect.bottom, lessThanOrEqualTo(dialog.bottom));
    // MediaQuery width sizing: 40px at 360, bounded to 40-56.
    expect(
      rect.height,
      closeTo((size.width * 40 / 360).clamp(40.0, 56.0), 0.01),
    );
  }
}

Widget _temporaryBlock(
  TemporaryBlockFlowType flowType, {
  VoidCallback? onPrimaryTap,
  VoidCallback? onSupportTap,
}) =>
    TemporaryBlockDialog(
      flowType: flowType,
      onPrimaryTap: onPrimaryTap ?? () {},
      onSupportTap: onSupportTap ?? () {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dialogs = <String, Widget Function()>{
    'TemporaryBlockDialog (no KYC)': () =>
        _temporaryBlock(TemporaryBlockFlowType.noKyc),
    'TemporaryBlockDialog (KYC verified)': () =>
        _temporaryBlock(TemporaryBlockFlowType.kycVerified),
    'NewDeviceVerificationDialog': () =>
        NewDeviceVerificationDialog(onPrimaryTap: () {}),
  };

  for (final entry in dialogs.entries) {
    group('${entry.key} across shared sizes', () {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height}', (tester) async {
          await _showDialog(tester, entry.value(), size: size);
          expect(tester.takeException(), isNull);
          await _expectDialogInsideScreen(tester, size);
        });
      }
    });

    group('${entry.key} with safe-area insets', () {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height}', (tester) async {
          const padding = EdgeInsets.only(top: 47, bottom: 34);
          await _showDialog(tester, entry.value(),
              size: size, padding: padding);
          expect(tester.takeException(), isNull);
          await _expectDialogInsideScreen(tester, size, padding: padding);
        });
      }
    });

    group('${entry.key} supported text scales', () {
      for (final scale in const [0.85, 1.15]) {
        for (final size in responsiveTestScreenSizes) {
          testWidgets('${size.width}x${size.height} @${scale}x',
              (tester) async {
            await _showDialog(tester, entry.value(),
                size: size, textScale: scale);
            expect(tester.takeException(), isNull);
            await _expectDialogInsideScreen(tester, size);
          });
        }
      }
    });
  }

  testWidgets('TemporaryBlockDialog keeps its flow-specific labels',
      (tester) async {
    await _showDialog(tester, _temporaryBlock(TemporaryBlockFlowType.noKyc));
    expect(find.text('COMPLETE KYC'), findsOneWidget);
    await _showDialog(
      tester,
      _temporaryBlock(TemporaryBlockFlowType.kycVerified),
    );
    expect(find.text('VERIFY NOW'), findsWidgets);
  });

  testWidgets('TemporaryBlockDialog buttons call their own callbacks',
      (tester) async {
    var primary = 0;
    var support = 0;
    await _showDialog(
      tester,
      _temporaryBlock(
        TemporaryBlockFlowType.noKyc,
        onPrimaryTap: () => primary++,
        onSupportTap: () => support++,
      ),
    );
    await tester.tap(find.text('Contact Support'));
    await tester.tap(find.byType(CustomElevatedButton));
    await tester.pump();
    expect(support, 1);
    expect(primary, 1);
  });

  testWidgets('NewDeviceVerificationDialog Verify Now calls back once',
      (tester) async {
    var taps = 0;
    await _showDialog(
      tester,
      NewDeviceVerificationDialog(onPrimaryTap: () => taps++),
    );
    await tester.tap(find.byType(CustomElevatedButton));
    await tester.pump();
    expect(taps, 1);
  });
}
