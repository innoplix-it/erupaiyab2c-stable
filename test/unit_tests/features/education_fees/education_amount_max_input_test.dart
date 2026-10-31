import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/educationFees/views/education_fees_amount_view.dart';

/// Applies the same formatter chain the amount field uses:
/// digits-only first, then the ₹2,00,000 value cap.
TextEditingValue _type(String oldText, String newRaw) {
  final digits = FilteringTextInputFormatter.digitsOnly;
  const cap = MaxAmountInputFormatter(kMaxTuitionAmount);
  final old = TextEditingValue(
    text: oldText,
    selection: TextSelection.collapsed(offset: oldText.length),
  );
  final raw = TextEditingValue(
    text: newRaw,
    selection: TextSelection.collapsed(offset: newRaw.length),
  );
  final digitOnly = digits.formatEditUpdate(old, raw);
  return cap.formatEditUpdate(old, digitOnly);
}

void main() {
  group('Amount field max-limit input guard (₹2,00,000)', () {
    test('kMaxTuitionAmount is 2,00,000', () {
      expect(kMaxTuitionAmount, 200000);
    });

    test('allows amounts at or below the cap', () {
      expect(_type('', '2000').text, '2000');
      expect(_type('2000', '20000').text, '20000');
      expect(_type('20000', '200000').text, '200000');
    });

    test('blocks the keystroke that would exceed the cap', () {
      // Typing one more digit past 2,00,000 keeps the previous valid value.
      expect(_type('200000', '2000001').text, '200000');
      // A leading digit that already overshoots (e.g. 3 -> 300000) is rejected.
      expect(_type('20000', '300000').text, '20000');
    });

    test('strips non-digits before applying the cap', () {
      expect(_type('', '20a00').text, '2000');
    });

    test('permits clearing the field to empty', () {
      expect(_type('2000', '').text, '');
    });
  });
}
