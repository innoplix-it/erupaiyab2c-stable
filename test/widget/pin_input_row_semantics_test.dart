// Semantics tests for PinInputRow widget.
import 'package:e_rupaiya/features/auth/components/pin_input_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PinInputRow semantics', () {
    testWidgets('has PIN entry label and hint', (tester) async {
      final controllers = List.generate(4, (_) => TextEditingController());
      final focusNodes = List.generate(4, (_) => FocusNode());

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          fontSizeResolver: FontSizeResolvers.radius,
          builder: (context, _) => MaterialApp(
            home: Scaffold(
              body: PinInputRow(
                controllers: controllers,
                focusNodes: focusNodes,
              ),
            ),
          ),
        ),
      );

      expect(find.byWidgetPredicate((widget) {
        if (widget is! Semantics) return false;
        return widget.properties.label == 'PIN entry' &&
               widget.properties.hint == 'Enter your 4-digit PIN';
      }), findsOneWidget);

      for (final controller in controllers) {
        controller.dispose();
      }
      for (final node in focusNodes) {
        node.dispose();
      }
    });

    testWidgets('hint reflects PIN length', (tester) async {
      final controllers = List.generate(6, (_) => TextEditingController());
      final focusNodes = List.generate(6, (_) => FocusNode());

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          fontSizeResolver: FontSizeResolvers.radius,
          builder: (context, _) => MaterialApp(
            home: Scaffold(
              body: PinInputRow(
                controllers: controllers,
                focusNodes: focusNodes,
              ),
            ),
          ),
        ),
      );

      expect(find.byWidgetPredicate((widget) {
        if (widget is! Semantics) return false;
        return widget.properties.label == 'PIN entry' &&
               widget.properties.hint == 'Enter your 6-digit PIN';
      }), findsOneWidget);

      for (final controller in controllers) {
        controller.dispose();
      }
      for (final node in focusNodes) {
        node.dispose();
      }
    });

    testWidgets('semantics tree never exposes entered PIN digits',
        (tester) async {
      const pin = '1234';
      final controllers = [
        for (final digit in pin.split('')) TextEditingController(text: digit),
      ];
      final focusNodes = List.generate(4, (_) => FocusNode());

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          fontSizeResolver: FontSizeResolvers.radius,
          builder: (context, _) => MaterialApp(
            home: Scaffold(
              body: PinInputRow(
                controllers: controllers,
                focusNodes: focusNodes,
              ),
            ),
          ),
        ),
      );
      final handle = tester.ensureSemantics();
      await tester.pumpAndSettle();

      // Measured node structure: the Semantics wrapper publishes one merged
      // node per field (label 'PIN entry' + length hint, empty value), while
      // each EditableText node carries only its own digit as `value` with no
      // label/hint. Assert no announced label/hint embeds an entered digit
      // and the full PIN never appears anywhere.
      final wrapper = tester.getSemantics(
        find.byWidgetPredicate((widget) =>
            widget is Semantics &&
            widget.properties.label == 'PIN entry' &&
            widget.properties.hint == 'Enter your 4-digit PIN'),
      );
      expect(wrapper.label, 'PIN entry');
      expect(wrapper.hint, 'Enter your 4-digit PIN');
      expect(wrapper.value, isEmpty);
      for (final text in [wrapper.label, wrapper.hint, wrapper.value]) {
        expect(text, isNot(contains(pin)));
        // The only allowed digit is the PIN length inside the fixed hint.
        expect(
          text.replaceAll('Enter your 4-digit PIN', ''),
          isNot(matches(RegExp(r'\d'))),
        );
      }

      final editables = find.byType(EditableText);
      expect(editables, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        final field = tester.getSemantics(editables.at(i));
        expect(field.label, isEmpty);
        expect(field.hint, isEmpty);
        expect(field.value, isNot(contains(pin)));
        // Visible (non-obscured) single-digit fields legitimately expose
        // only their own digit as the announced value.
        expect(field.value, pin[i]);
      }

      final fieldNodes = find.byType(TextField);
      expect(fieldNodes, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        final merged = tester.getSemantics(fieldNodes.at(i));
        expect(merged.value, isNot(contains(pin)));
        expect(
          '${merged.label}${merged.hint}'.replaceAll('Enter your 4-digit PIN', ''),
          isNot(matches(RegExp(r'\d'))),
        );
      }

      handle.dispose();
      for (final controller in controllers) {
        controller.dispose();
      }
      for (final node in focusNodes) {
        node.dispose();
      }
    });
  });
}
