import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/widgets/pan_aadhaar_input_fields.dart';

Future<void> _pump(WidgetTester tester, Widget field) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: field)),
  );
}

void main() {
  testWidgets('PanInputField switches keyboard type at segment boundaries',
      (tester) async {
    final controller = TextEditingController();
    await _pump(tester, PanInputField(controller: controller));

    EditableText editable() => tester.widget(find.byType(EditableText));

    expect(editable().keyboardType, TextInputType.text);

    await tester.enterText(find.byType(EditableText), 'ABCDE');
    await tester.pump();
    expect(editable().keyboardType, TextInputType.number);

    await tester.enterText(find.byType(EditableText), 'ABCDE1234');
    await tester.pump();
    expect(editable().keyboardType, TextInputType.text);
  });

  testWidgets('PanInputField uppercases letters and keeps the valid pattern',
      (tester) async {
    final controller = TextEditingController();
    await _pump(tester, PanInputField(controller: controller));

    await tester.enterText(find.byType(EditableText), 'abcde');
    await tester.pump();
    expect(controller.text, 'ABCDE');

    await tester.enterText(find.byType(EditableText), 'abcde1234f');
    await tester.pump();
    expect(controller.text, 'ABCDE1234F');
  });

  testWidgets('PanInputField rejects out-of-position characters and caps at 10',
      (tester) async {
    final controller = TextEditingController();
    await _pump(tester, PanInputField(controller: controller));

    // Digits are not valid in the leading 5 letter slots, so only the trailing
    // letters survive.
    await tester.enterText(find.byType(EditableText), '1234567890ABCDE');
    await tester.pump();
    expect(controller.text, 'ABCDE');

    // Extra characters beyond the 10-character PAN are dropped.
    await tester.enterText(find.byType(EditableText), 'ABCDE1234FGHIJ');
    await tester.pump();
    expect(controller.text, 'ABCDE1234F');
    expect(controller.text.length, 10);
  });

  testWidgets('PanInputField honours textInputAction and fires onSubmitted',
      (tester) async {
    final controller = TextEditingController();
    var submitted = '';
    await _pump(
      tester,
      PanInputField(
        controller: controller,
        textInputAction: TextInputAction.next,
        onSubmitted: (value) => submitted = value,
      ),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).textInputAction,
      TextInputAction.next,
    );

    await tester.enterText(find.byType(EditableText), 'ABCDE1234F');
    await tester.pump();
    await tester.showKeyboard(find.byType(EditableText));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(submitted, 'ABCDE1234F');
  });

  testWidgets('AadhaarInputField uses the numeric keyboard', (tester) async {
    final controller = TextEditingController();
    await _pump(tester, AadhaarInputField(controller: controller));

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
      TextInputType.number,
    );
  });

  testWidgets('AadhaarInputField keeps digits only and caps at 12 digits',
      (tester) async {
    final controller = TextEditingController();
    await _pump(tester, AadhaarInputField(controller: controller));

    await tester.enterText(find.byType(EditableText), '12ab34cd56789012345');
    await tester.pump();

    expect(controller.text, '1234 5678 9012');
    expect(controller.text.replaceAll(RegExp(r'\D'), '').length, 12);
  });

  testWidgets('AadhaarInputField fires onSubmitted on done', (tester) async {
    final controller = TextEditingController();
    var submitted = '';
    await _pump(
      tester,
      AadhaarInputField(
        controller: controller,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => submitted = value,
      ),
    );

    await tester.enterText(find.byType(EditableText), '123456789012');
    await tester.pump();
    await tester.showKeyboard(find.byType(EditableText));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, '1234 5678 9012');
  });

  testWidgets(
      'PanInputField restores the right keyboard when backspacing '
      'across stage boundaries', (tester) async {
    final controller = TextEditingController();
    await _pump(tester, PanInputField(controller: controller));

    TextInputType keyboard() =>
        tester.widget<EditableText>(find.byType(EditableText)).keyboardType;

    // 5 letters + 4 digits -> stage 2 (final letter, alphabetic).
    await tester.enterText(find.byType(EditableText), 'ABCDE1234');
    await tester.pump();
    expect(keyboard(), TextInputType.text);

    // Delete the 4 digits -> back to stage 1 (numeric) at 5 letters.
    await tester.enterText(find.byType(EditableText), 'ABCDE');
    await tester.pump();
    expect(keyboard(), TextInputType.number);

    // Delete one more letter -> stage 0 (alphabetic).
    await tester.enterText(find.byType(EditableText), 'ABCD');
    await tester.pump();
    expect(keyboard(), TextInputType.text);
  });

  testWidgets('PanInputField keeps focus and text across keyboard switches',
      (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    await _pump(
      tester,
      PanInputField(controller: controller, focusNode: focus),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    for (final entry in ['ABCDE', 'ABCDE1234', 'ABCDE1234F']) {
      await tester.enterText(find.byType(EditableText), entry);
      // The stage switch schedules an unfocus -> requestFocus re-attach that
      // resolves over the following frames, so settle before asserting.
      await tester.pumpAndSettle();
      // Focus survives the re-attach and the value is intact.
      expect(focus.hasFocus, isTrue, reason: 'lost focus at "$entry"');
      expect(controller.text, entry);
    }

    focus.dispose();
  });
}
