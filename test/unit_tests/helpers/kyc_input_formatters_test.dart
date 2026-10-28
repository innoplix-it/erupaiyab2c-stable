import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/helpers/kyc_input_formatters.dart';

TextEditingValue _formatPan(String oldText, String newText, {int offset = -1}) {
  const formatter = PanInputFormatter();
  final end = offset < 0 ? newText.length : offset;
  return formatter.formatEditUpdate(
    TextEditingValue(text: oldText, selection: TextSelection.collapsed(offset: oldText.length)),
    TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: end),
    ),
  );
}

TextEditingValue _formatAadhaar(String oldText, String newText, {int offset = -1}) {
  const formatter = AadhaarInputFormatter();
  final end = offset < 0 ? newText.length : offset;
  return formatter.formatEditUpdate(
    TextEditingValue(text: oldText, selection: TextSelection.collapsed(offset: oldText.length)),
    TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: end),
    ),
  );
}

void main() {
  group('PanInputFormatter', () {
    test('uppercases the first five letters', () {
      final value = _formatPan('', 'abcde');
      expect(value.text, 'ABCDE');
    });

    test('accepts only digits in positions 6-9', () {
      var value = _formatPan('ABCDE', 'ABCDE1234');
      expect(value.text, 'ABCDE1234');
      value = _formatPan('ABCDE1234', 'ABCDE1234a');
      expect(value.text, 'ABCDE1234A');
    });

    test('rejects invalid characters for the current segment', () {
      expect(_formatPan('', '12345').text, isEmpty);
      expect(_formatPan('ABCDE', 'ABCDEabc').text, 'ABCDE');
      expect(_formatPan('ABCDE1234', 'ABCDE12345').text, 'ABCDE1234');
    });

    test('caps length at ten characters', () {
      final value = _formatPan('', 'ABCDE1234FGHI');
      expect(value.text, 'ABCDE1234F');
      expect(value.text.length, 10);
    });

    test('paste across segments produces a valid prefix', () {
      final value = _formatPan('', 'abcde1234f');
      expect(value.text, 'ABCDE1234F');
    });

    test('backspace across a boundary keeps valid text', () {
      final value = _formatPan('ABCDE1', 'ABCDE');
      expect(value.text, 'ABCDE');
    });
  });

  group('panKeyboardTypeForLength', () {
    test('updates at five-letter and nine-character boundaries', () {
      expect(panKeyboardTypeForLength(0), TextInputType.text);
      expect(panKeyboardTypeForLength(4), TextInputType.text);
      expect(panKeyboardTypeForLength(5), TextInputType.number);
      expect(panKeyboardTypeForLength(8), TextInputType.number);
      expect(panKeyboardTypeForLength(9), TextInputType.text);
    });
  });

  group('AadhaarInputFormatter', () {
    test('uses numeric-only content and groups with spaces', () {
      final value = _formatAadhaar('', '123456789012');
      expect(value.text, '1234 5678 9012');
    });

    test('rejects alphabetic and special characters', () {
      expect(_formatAadhaar('', '12ab34!!56').text, '1234 56');
    });

    test('limits to twelve digits', () {
      final value = _formatAadhaar('', '1234567890123456');
      expect(value.text.replaceAll(' ', ''), '123456789012');
    });

    test('preserves reasonable cursor position after edit', () {
      const formatter = AadhaarInputFormatter();
      final value = formatter.formatEditUpdate(
        const TextEditingValue(text: '1234 5678', selection: TextSelection.collapsed(offset: 9)),
        const TextEditingValue(text: '1234 56789', selection: TextSelection.collapsed(offset: 10)),
      );
      expect(value.text, '1234 5678 9');
      expect(value.selection.baseOffset, greaterThan(0));
    });
  });
}
