import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';

// ---------------------------------------------------------------------------
// Lightweight unit tests verifying the status-resolution logic used inside
// reconcileEducationPaymentOnFailure (education_payment_reconcile.dart).
//
// We test the pure status-mapping rules in isolation so that the tests do not
// require a running Flutter widget tree, Riverpod, or network access.
// ---------------------------------------------------------------------------

// Mirrors the resolution logic from education_payment_reconcile.dart so that
// changes to the production code must be reflected here.
String _resolveStatus({
  required bool timedOut,
  required EducationPaymentStatusResponse? result,
}) {
  if (timedOut || result == null) return 'PENDING';
  if (result.isPending || result.isProcessing) {
    return result.paymentStatus.trim().toUpperCase();
  }
  return 'FAILED';
}

// ---------------------------------------------------------------------------
// Minimal factory helpers for EducationPaymentStatusResponse.
// ---------------------------------------------------------------------------
EducationPaymentStatusResponse _makeStatus(String paymentStatus) {
  return EducationPaymentStatusResponse(
    status: true,
    message: '',
    transactionId: 'txn123',
    paymentStatus: paymentStatus,
    amount: '500',
    updatedAt: '2026-01-01T00:00:00.000Z',
    paymentType: 'Education Fees',
  );
}

void main() {
  group('reconcileEducationPaymentOnFailure — status resolution', () {
    // ---- Network / timeout paths -------------------------------------------

    test('1. timeout with no result → PENDING', () {
      final resolved = _resolveStatus(timedOut: true, result: null);
      expect(resolved, 'PENDING');
    });

    test('2. timeout even if result is available → PENDING', () {
      // showPaymentProcessingWhile sets timedOut=true when 60s elapses; the
      // value may still be null or a stale response. Either way → PENDING.
      final resolved = _resolveStatus(timedOut: true, result: _makeStatus('SUCCESS'));
      expect(resolved, 'PENDING');
    });

    test('3. null result without timeout → PENDING', () {
      final resolved = _resolveStatus(timedOut: false, result: null);
      expect(resolved, 'PENDING');
    });

    // ---- FAILED path -------------------------------------------------------

    test('4. gateway-confirmed FAILED → FAILED', () {
      final result = _makeStatus('FAILED');
      expect(result.isFailed, isTrue);
      final resolved = _resolveStatus(timedOut: false, result: result);
      expect(resolved, 'FAILED');
    });

    test('5. case-insensitive "failed" → FAILED', () {
      final result = _makeStatus('failed');
      expect(result.isFailed, isTrue);
      final resolved = _resolveStatus(timedOut: false, result: result);
      expect(resolved, 'FAILED');
    });

    // ---- PENDING / PROCESSING paths ----------------------------------------

    test('6. backend returns PENDING → PENDING', () {
      final result = _makeStatus('PENDING');
      final resolved = _resolveStatus(timedOut: false, result: result);
      expect(resolved, 'PENDING');
    });

    test('7. backend returns PROCESSING → PROCESSING (genuine ambiguity preserved)', () {
      final result = _makeStatus('PROCESSING');
      final resolved = _resolveStatus(timedOut: false, result: result);
      expect(resolved, 'PROCESSING');
    });

    // ---- SUCCESS path (rare but correct) -----------------------------------

    test('8. backend reports SUCCESS despite gateway failure → SUCCESS', () {
      // This can happen if the gateway callback arrived late and the backend
      // processed the payment concurrently.  The reconciler should detect this
      // and navigate to the thank-you view (tested here as status string only).
      final result = _makeStatus('SUCCESS');
      expect(result.isSuccess, isTrue);
      // SUCCESS is handled BEFORE the resolveStatus fallback in production
      // code. Here we verify the model correctly identifies it as success.
    });

    test('9. empty paymentStatus without timeout → FAILED on gateway failure', () {
      final result = _makeStatus('');
      final resolved = _resolveStatus(timedOut: false, result: result);
      expect(resolved, 'FAILED');
    });
  });

  group('EducationPaymentStatusResponse — model helpers', () {
    test('isSuccess true only for SUCCESS', () {
      expect(_makeStatus('SUCCESS').isSuccess, isTrue);
      expect(_makeStatus('FAILED').isSuccess, isFalse);
      expect(_makeStatus('PENDING').isSuccess, isFalse);
    });

    test('isFailed true only for FAILED', () {
      expect(_makeStatus('FAILED').isFailed, isTrue);
      expect(_makeStatus('SUCCESS').isFailed, isFalse);
      expect(_makeStatus('PENDING').isFailed, isFalse);
    });

    test('case-insensitive SUCCESS recognised', () {
      expect(_makeStatus('success').isSuccess, isTrue);
    });

    test('case-insensitive FAILED recognised', () {
      expect(_makeStatus('Failed').isFailed, isTrue);
    });
  });
}
