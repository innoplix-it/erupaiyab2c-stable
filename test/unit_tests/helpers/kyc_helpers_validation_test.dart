import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/helpers/kyc_helpers.dart';

// ---------------------------------------------------------------------------
// Unit tests for the shared PAN / Aadhaar format validators.
//
// These validators are the single source of truth reused by every module that
// calls a PAN or Aadhaar API (Education Fees, KYC, Account Recovery). The
// tests prove the guard rules that keep an incomplete or malformed number from
// ever reaching the backend.
// ---------------------------------------------------------------------------

void main() {
  group('isValidPanFormat', () {
    // Requirement 1: 1-9 characters must never be treated as complete.
    test('rejects every partial PAN shorter than 10 characters', () {
      const partial = ['A', 'AB', 'ABC', 'ABCD', 'ABCDE', 'ABCDE1',
          'ABCDE12', 'ABCDE123', 'ABCDE1234'];
      for (final pan in partial) {
        expect(isValidPanFormat(pan), isFalse,
            reason: 'partial PAN "$pan" must be invalid');
      }
    });

    // Requirement 2: a complete-but-malformed PAN is invalid.
    test('rejects a full-length but malformed PAN', () {
      const malformed = [
        '1234567890', // digits only
        'ABCDEFGHIJ', // letters only
        'ABCDE123456', // wrong tail (digits where a letter is required)
        'ABC12345DE', // wrong letter/digit split
        'ABCDE1234', // 9 characters
        'ABCDE12345F', // 11 characters
        'ABCD12345E', // only 4 leading letters
      ];
      for (final pan in malformed) {
        expect(isValidPanFormat(pan), isFalse,
            reason: 'malformed PAN "$pan" must be invalid');
      }
    });

    // Requirement 3: a valid 10-character PAN is accepted, case-insensitively
    // and ignoring surrounding whitespace.
    test('accepts a well formed 10-character PAN', () {
      expect(isValidPanFormat('ABCDE1234F'), isTrue);
      expect(isValidPanFormat('abcde1234f'), isTrue);
      expect(isValidPanFormat('  ABCDE1234F  '), isTrue);
    });
  });

  group('isValidAadhaarNumber', () {
    // Requirement 5: fewer than 12 digits is invalid.
    test('rejects 1-11 digits', () {
      for (var len = 1; len <= 11; len++) {
        final digits = '12345678901'.substring(0, len);
        expect(isValidAadhaarNumber(digits), isFalse,
            reason: '$len-digit Aadhaar "$digits" must be invalid');
      }
    });

    // Requirement 6: more than 12 digits is rejected.
    test('rejects 13+ digits', () {
      expect(isValidAadhaarNumber('1234567890123'), isFalse);
      expect(isValidAadhaarNumber('12345678901234'), isFalse);
    });

    // Requirement 7: exactly 12 digits (with or without display spaces) is
    // accepted; non-digit content is rejected even when 12 characters long.
    test('accepts exactly 12 digits and ignores display-only spaces', () {
      expect(isValidAadhaarNumber('123456789012'), isTrue);
      expect(isValidAadhaarNumber('1234 5678 9012'), isTrue);
      expect(isValidAadhaarNumber('1234  5678  9012'), isTrue);
    });

    test('rejects 12 characters that are not all digits', () {
      expect(isValidAadhaarNumber('12345678901a'), isFalse);
      expect(isValidAadhaarNumber('12345 678901'), isFalse);
      expect(isValidAadhaarNumber('------------'), isFalse);
    });
  });
}
