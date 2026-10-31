import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/widgets/pan_aadhaar_input_fields.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PanInputField', () {
    testWidgets('pre-filled controller text survives first build', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'ABCDE1234Z');
      await tester.pumpWidget(_wrap(PanInputField(controller: controller)));
      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(find.text('ABCDE1234Z'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('uppercase-only input is normalized and capped at 10 chars', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_wrap(PanInputField(controller: controller)));
      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'abcde1234x9999Z');
      await tester.pump();

      // 'x' lands on the final-letter slot (valid) and caps the field at 10
      // chars, so the trailing digits and 'Z' are dropped by the formatter.
      expect(controller.text, 'ABCDE1234X');

      controller.dispose();
    });

    testWidgets('digits-only input in letter slots is rejected', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_wrap(PanInputField(controller: controller)));
      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();

      expect(controller.text, '');

      controller.dispose();
    });

    testWidgets('switches to number keyboard after 5 letters are entered', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'ABCDE');
      await tester.pumpWidget(_wrap(PanInputField(controller: controller)));
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Segment state is derived from controller length; after the letters
      // stage the field must accept digits.
      await tester.enterText(find.byType(TextField), 'ABCDE1');
      await tester.pump();

      expect(controller.text, 'ABCDE1');

      controller.dispose();
    });

    test('panKeyboardSegmentForLength maps the three PAN stages', () {
      expect(panKeyboardSegmentForLength(0), 0);
      expect(panKeyboardSegmentForLength(4), 0);
      expect(panKeyboardSegmentForLength(5), 1);
      expect(panKeyboardSegmentForLength(8), 1);
      expect(panKeyboardSegmentForLength(9), 2);
      expect(panKeyboardSegmentForLength(10), 2);
    });
  });

  group('AadhaarInputField', () {
    testWidgets('uses numeric keyboard and hides the counter', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(AadhaarInputField(controller: controller)),
      );

      final textField =
          tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.number);
      expect(textField.decoration?.counterText, '');
      expect(textField.maxLength, 14);

      controller.dispose();
    });

    testWidgets('groups digits as "1234 5678 9012" and caps at 12 digits', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(AadhaarInputField(controller: controller)),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '1234567890123456');
      await tester.pump();

      expect(controller.text, '1234 5678 9012');

      controller.dispose();
    });

    testWidgets('non-digit characters are stripped', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(AadhaarInputField(controller: controller)),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '12ab34!@56');
      await tester.pump();

      expect(controller.text, '1234 56');

      controller.dispose();
    });
  });
}
