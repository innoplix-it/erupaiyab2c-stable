// Regression coverage for the AUD-019 accessibility fix:
//   `AuthPinBoxes` / `AuthPinRowWithToggle` accept optional
//   `semanticsLabel` / `semanticsHint` overrides so two PIN rows shown
//   together (MPIN setup's "New PIN" and "Confirm PIN") can be told apart
//   by TalkBack / VoiceOver. Defaults must remain unchanged so no other
//   caller regresses.
import 'package:e_rupaiya/features/auth/components/auth_code_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester,
    Widget child,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 360, child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Semantics? findWrapperSemantics(WidgetTester tester, String label) {
    for (final element in tester.widgetList<Semantics>(find.byType(Semantics))) {
      if (element.properties.label == label) return element;
    }
    return null;
  }

  group('AuthPinBoxes semantics overrides', () {
    testWidgets('keeps default "PIN entry" label / "Enter your PIN" hint',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        AuthPinBoxes(controller: controller, length: 4),
      );

      final wrapper = findWrapperSemantics(tester, 'PIN entry');
      expect(wrapper, isNotNull,
          reason: 'default label must remain for existing call sites');
      expect(wrapper!.properties.hint, 'Enter your PIN');
      expect(wrapper.properties.textField, isTrue);
    });

    testWidgets('overrides label and hint when supplied', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        AuthPinBoxes(
          controller: controller,
          length: 4,
          semanticsLabel: 'New PIN',
          semanticsHint: 'Enter your new 4-digit PIN',
        ),
      );

      final overridden = findWrapperSemantics(tester, 'New PIN');
      expect(overridden, isNotNull);
      expect(overridden!.properties.hint, 'Enter your new 4-digit PIN');
      // Default label must no longer be present once overridden, otherwise
      // TalkBack would announce both the new and old label (duplicate).
      expect(findWrapperSemantics(tester, 'PIN entry'), isNull);
    });
  });

  group('AuthPinRowWithToggle forwards overrides', () {
    testWidgets('child AuthPinBoxes receives custom label / hint',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        AuthPinRowWithToggle(
          controller: controller,
          obscure: true,
          onToggle: () {},
          semanticsLabel: 'Confirm PIN',
          semanticsHint: 'Re-enter your PIN to confirm',
        ),
      );

      final forwarded = findWrapperSemantics(tester, 'Confirm PIN');
      expect(forwarded, isNotNull);
      expect(forwarded!.properties.hint, 'Re-enter your PIN to confirm');
      // Show/Hide toggle still exposes its own button semantics; that is
      // independent of the PIN field override path.
      final toggle = findWrapperSemantics(tester, 'Show PIN');
      expect(toggle, isNotNull);
    });
  });
}
