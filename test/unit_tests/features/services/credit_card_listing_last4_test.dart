import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// AUD-033 focused tests for the credit-card last-four digit extraction in
// lib/features/services/views/credit_card_listing_view.dart
// (openBillerFromRecent, lines 78-82).
//
// The extraction is an inline closure inside the view's build, so — like the
// session-cleanup audit in test/unit_tests/features/auth/
// auth_invalid_session_test.dart — these tests combine:
//   1) behavioral checks of the exact (now fixed) expressions, and
//   2) source-level assertions that the fixed regex is what the app ships.
void main() {
  // Mirror of the fixed implementation:
  //   final digits = txn.serviceNo.replaceAll(RegExp(r'\D'), '');
  //   final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : '';
  String normalizeDigits(String serviceNo) =>
      serviceNo.replaceAll(RegExp(r'\D'), '');

  String extractLast4(String serviceNo) {
    final digits = normalizeDigits(serviceNo);
    return digits.length >= 4 ? digits.substring(digits.length - 4) : '';
  }

  group('AUD-033 digits-only normalization', () {
    test('removes hyphens: 4111-1111 -> 41111111', () {
      expect(normalizeDigits('4111-1111'), '41111111');
    });

    test('removes hyphens across a full card number', () {
      expect(
        normalizeDigits('4111-2222-3333-4444'),
        '4111222233334444',
      );
    });

    test('removes spaces: 1234 5678 9012 3456 -> 1234567890123456', () {
      expect(
        normalizeDigits('1234 5678 9012 3456'),
        '1234567890123456',
      );
    });

    test('already-numeric input stays unchanged', () {
      expect(normalizeDigits('9876543210'), '9876543210');
    });

    test('empty input stays empty (safe existing behavior)', () {
      expect(normalizeDigits(''), '');
    });
  });

  group('AUD-033 last-four extraction', () {
    test('audit acceptance case: 4111-1111 -> 1111', () {
      expect(extractLast4('4111-1111'), '1111');
    });

    test('4111-2222-3333-4444 -> 4444', () {
      expect(extractLast4('4111-2222-3333-4444'), '4444');
    });

    test('1234 5678 9012 3456 -> 3456', () {
      expect(extractLast4('1234 5678 9012 3456'), '3456');
    });

    test('9876543210 -> 3210', () {
      expect(extractLast4('9876543210'), '3210');
    });

    test('empty and short inputs return empty string (safe behavior)', () {
      expect(extractLast4(''), ''); // empty
      expect(extractLast4('12'), ''); // shorter than 4
      expect(extractLast4('ab-12'), ''); // non-digits collapse to short
      expect(extractLast4('1234-'), '1234'); // exactly 4 after normalize
    });

    test('null-backed mobile path: (null ?? \'\') normalizes safely', () {
      // Mirrors the line-82 mobile expression.
      String? mobile;
      expect((mobile ?? '').replaceAll(RegExp(r'\D'), ''), '');
      mobile = '987-654-3210';
      expect((mobile ?? '').replaceAll(RegExp(r'\D'), ''), '9876543210');
    });
  });

  group('AUD-033 regression guard', () {
    test('the broken r\'\\\\D\' pattern would NOT strip separators', () {
      // Documents the root cause: literal backslash-D matches nothing here,
      // so hyphens/spaces survive — which broke canAutoFetch/last4.
      final broken = RegExp(r'\\D');
      expect('4111-1111'.replaceAll(broken, ''), '4111-1111');
      expect('4111-1111'.replaceAll(broken, '').length >= 4, true);
      // And with the broken pattern the view's last4 was wrong for inputs
      // containing literal "\D"-like sequences only; for normal hyphenated
      // cards digits.length included the hyphens, producing garbage last4
      // (e.g. substring of "4111-1111" -> "1111" only by luck of position,
      // while "4111 11 1-"-style inputs mismatch). The fixed pattern below
      // is deterministic.
      expect('4111-1111'.replaceAll(RegExp(r'\D'), ''), '41111111');
    });

    test('listing view no longer contains the broken regex', () {
      final source = _readSource(
        'lib/features/services/views/credit_card_listing_view.dart',
      );
      expect(source, isNot(contains(r"RegExp(r'\\D')")));
      // Both fixed call sites present.
      expect(
        source,
        contains("txn.serviceNo.replaceAll(RegExp(r'\\D'), '')"),
      );
      expect(
        source,
        contains(
          "(profileState.profile?.mobile ?? '').replaceAll(RegExp(r'\\D'), '')",
        ),
      );
    });

    test('view never logs or exposes the full card number', () {
      final source = _readSource(
        'lib/features/services/views/credit_card_listing_view.dart',
      );
      // Only last4 (4 chars) is passed downstream; serviceNo itself must not
      // appear in any debugPrint/log line.
      final logLines = source.split('\n').where(
            (line) => line.contains('debugPrint') || line.contains('print('),
          );
      for (final line in logLines) {
        expect(line.contains('serviceNo'), false, reason: 'leak: $line');
      }
      // Downstream payload uses cardLast4 only.
      expect(source, contains('cardLast4: last4.length == 4 ? last4 : null'));
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
