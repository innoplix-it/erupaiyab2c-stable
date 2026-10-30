import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// AUD-033 follow-up focused tests for the deeplink digit normalization in
// lib/features/services/views/credit_card_pay_deeplink_view.dart
// (_last4FromMasked, line 43).
//
// The method is private to the view's State class, so these tests combine
// behavioral checks of the exact (now fixed) expressions with source-level
// assertions that the fixed regex is what the app ships — the same convention
// used by test/unit_tests/features/services/credit_card_listing_last4_test.dart.
void main() {
  // Mirror of the fixed implementation:
  //   final digits = maskedIdentifier.replaceAll(RegExp(r'\D'), '');
  //   if (digits.length >= 4) return digits.substring(digits.length - 4);
  //   return digits;
  String last4FromMasked(String maskedIdentifier) {
    final digits = maskedIdentifier.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) return digits.substring(digits.length - 4);
    return digits;
  }

  group('AUD-033 follow-up deeplink digit normalization', () {
    test('removes hyphens: 4111-1111 -> 41111111', () {
      expect('4111-1111'.replaceAll(RegExp(r'\D'), ''), '41111111');
    });

    test('removes spaces: 4111 1111 -> 41111111', () {
      expect('4111 1111'.replaceAll(RegExp(r'\D'), ''), '41111111');
    });

    test('mixed separators: 1234-5678-9012 -> 123456789012', () {
      expect(
        '1234-56 78-9012'.replaceAll(RegExp(r'\D'), ''),
        '123456789012',
      );
    });

    test('numeric-only input stays unchanged', () {
      expect('9876543210'.replaceAll(RegExp(r'\D'), ''), '9876543210');
    });

    test('empty input normalizes to empty safely', () {
      expect(''.replaceAll(RegExp(r'\D'), ''), '');
      expect(last4FromMasked(''), '');
    });

    test('null is not accepted — signature requires non-null String', () {
      // The existing method signature is `String _last4FromMasked(String ...)`.
      // Router always supplies a non-null masked_identifier, and the widget
      // field is a required String, so empty-string is the degenerate case.
      String? maybeIdentifier;
      final safe = maybeIdentifier ?? '';
      expect(last4FromMasked(safe), '');
    });
  });

  group('AUD-033 follow-up last-four extraction', () {
    test('4111-1111 -> 1111', () {
      expect(last4FromMasked('4111-1111'), '1111');
    });

    test('4111 1111 -> 1111', () {
      expect(last4FromMasked('4111 1111'), '1111');
    });

    test('1234-5678-9012 -> 9012', () {
      expect(last4FromMasked('1234-5678-9012'), '9012');
    });

    test('9876543210 -> 3210', () {
      expect(last4FromMasked('9876543210'), '3210');
    });

    test('masked banner format 5298-****-****-5103 -> 5103', () {
      expect(last4FromMasked('5298-****-****-5103'), '5103');
    });

    test('short inputs keep existing behavior (returns digits, not empty)', () {
      // Existing code returns `digits` when fewer than 4 remain — preserved.
      expect(last4FromMasked('12'), '12');
      expect(last4FromMasked('1-2-3'), '123');
      expect(last4FromMasked('**'), '');
      expect(last4FromMasked('1234-'), '1234');
    });

    test('broken r\'\\\\D\' pattern leaves separators (regression proof)', () {
      // Documents the root cause: literal "\D" matches nothing in normal
      // identifiers, so separators survived normalization. A trailing
      // separator previously produced garbage last4 (e.g. "234-").
      final broken = RegExp(r'\\D');
      expect('1234-'.replaceAll(broken, ''), '1234-');
      final brokenDigits = '1234-'.replaceAll(broken, '');
      expect(brokenDigits.substring(brokenDigits.length - 4), '234-');
      // The fixed pattern normalizes deterministically.
      expect(last4FromMasked('1234-'), '1234');
    });
  });

  group('AUD-033 follow-up source guard', () {
    const viewPath =
        'lib/features/services/views/credit_card_pay_deeplink_view.dart';

    test('deeplink view uses the fixed regex and not the broken one', () {
      final source = _readSource(viewPath);
      expect(source, isNot(contains(r"RegExp(r'\\D')")));
      expect(
        source,
        contains("maskedIdentifier.replaceAll(RegExp(r'\\D'), '')"),
      );
    });

    test('short-input return path is unchanged', () {
      final source = _readSource(viewPath);
      expect(source, contains('if (digits.length >= 4) return digits'));
      expect(source, contains('return digits;'));
    });

    test('no full card number is logged or printed', () {
      final source = _readSource(viewPath);
      final logLines = source.split('\n').where(
            (line) => line.contains('debugPrint') || line.contains('print('),
          );
      expect(logLines, isEmpty);
    });

    test('deeplink flow still passes only last4 downstream', () {
      final source = _readSource(viewPath);
      expect(
        source,
        contains(
          'cardLast4: (match.last4Digit ?? \'\').trim().isNotEmpty',
        ),
      );
      expect(
        source,
        contains('_last4FromMasked(widget.maskedIdentifier)'),
      );
    });
  });
}

String _readSource(String relativePath) {
  final file = File(relativePath);
  if (!file.existsSync()) {
    throw StateError('Could not locate $relativePath from test working dir');
  }
  return file.readAsStringSync();
}
