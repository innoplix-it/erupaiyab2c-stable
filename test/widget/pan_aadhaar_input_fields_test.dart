import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/widgets/pan_aadhaar_input_fields.dart';

void main() {
  testWidgets('PanInputField switches keyboard type at segment boundaries',
      (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PanInputField(controller: controller),
        ),
      ),
    );

    EditableText editable() => tester.widget(find.byType(EditableText));

    expect(editable().keyboardType, TextInputType.text);

    await tester.enterText(find.byType(EditableText), 'ABCDE');
    await tester.pump();

    expect(editable().keyboardType, TextInputType.number);

    await tester.enterText(find.byType(EditableText), 'ABCDE1234');
    await tester.pump();

    expect(editable().keyboardType, TextInputType.text);
  });

  testWidgets('AadhaarInputField uses the numeric keyboard', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AadhaarInputField(controller: controller),
        ),
      ),
    );

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
      TextInputType.number,
    );
  });
}
