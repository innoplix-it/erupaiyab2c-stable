import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';

// ---------------------------------------------------------------------------
// Controller-level tests for the Education Fees PAN verification trigger.
//
// Proves the verify-pan API is only reached once the PAN is complete and
// well formed, and that a slow response for a previously entered PAN is never
// applied after the user has moved on (stale-response safety).
// ---------------------------------------------------------------------------

class _FakeEducationRepository extends EducationFeesRepository {
  _FakeEducationRepository() : super();

  int verifyPanCallCount = 0;
  String? lastPanRequested;

  /// When true, each verifyPan call parks on its own completer (added to
  /// [inFlight]) so tests can control the order responses land in.
  bool hangNext = false;
  final inFlight = <Completer<EducationVerifyPanResponse>>[];

  @override
  Future<EducationCheckMobileResponse> checkMobile(String mobile) async {
    return const EducationCheckMobileResponse(status: true, exists: false);
  }

  @override
  Future<EducationVerifyPanResponse> verifyPan({
    required String name,
    required String pan,
    required String deviceId,
  }) async {
    verifyPanCallCount++;
    lastPanRequested = pan;
    if (hangNext) {
      final completer = Completer<EducationVerifyPanResponse>();
      inFlight.add(completer);
      return completer.future;
    }
    return const EducationVerifyPanResponse(status: true);
  }
}

void main() {
  late _FakeEducationRepository repository;
  late EducationFeesController controller;

  setUp(() {
    repository = _FakeEducationRepository();
    controller = EducationFeesController(repository: repository);
    controller.updateMobileInput('9876543210');
    controller.updateRecipientName('Ravi Kumar');
  });

  tearDown(() {
    controller.dispose();
  });

  group('PAN API is not called for incomplete or invalid input', () {
    // Requirement 1: 1-9 characters never trigger the API.
    test('partial PAN (1-9 chars) does not call verify-pan', () async {
      const partial = ['A', 'AB', 'ABC', 'ABCD', 'ABCDE', 'ABCDE1',
          'ABCDE12', 'ABCDE123', 'ABCDE1234'];
      for (final pan in partial) {
        controller.updatePan(pan);
        await controller.verifyPan();
      }
      expect(repository.verifyPanCallCount, 0);
    });

    // Requirement 2: a complete-but-malformed PAN does not call the API.
    test('complete but invalid PAN does not call verify-pan', () async {
      const malformed = ['1234567890', 'ABCDEFGHIJ', 'ABCDE12345F',
          'ABCD12345E'];
      for (final pan in malformed) {
        controller.updatePan(pan);
        await controller.verifyPan();
      }
      expect(repository.verifyPanCallCount, 0);
      expect(controller.state.panVerified, isFalse);
    });

    test('empty recipient name blocks the call even for a valid PAN', () async {
      controller.updateRecipientName('');
      controller.updatePan('ABCDE1234F');
      await controller.verifyPan();
      expect(repository.verifyPanCallCount, 0);
    });
  });

  group('valid PAN triggers the API', () {
    // Requirement 3: a complete, valid PAN calls the API at the right point.
    test('valid 10-character PAN calls verify-pan and marks verified', () async {
      controller.updatePan('abcde1234f'); // lower case input is normalised
      await controller.verifyPan();
      expect(repository.verifyPanCallCount, 1);
      expect(repository.lastPanRequested, 'ABCDE1234F');
      expect(controller.state.panVerified, isTrue);
      expect(controller.state.isVerifyingPan, isFalse);
    });

    // Requirement 4 (controller view): repeated identical callbacks while a
    // verification is already running do not spawn extra in-flight requests.
    test('in-flight edit to a new valid PAN replaces the old request',
        () async {
      repository.hangNext = true;
      controller.updatePan('ABCDE1234F');
      final first = controller.verifyPan();
      controller.updatePan('XYZAB1234C');
      final second = controller.verifyPan();

      expect(repository.verifyPanCallCount, 2);
      expect(repository.inFlight.length, 2);

      // Newest request succeeds, then the stale one fails.
      repository.inFlight[0].complete(
        const EducationVerifyPanResponse(status: false, message: 'stale'),
      );
      repository.inFlight[1].complete(
        const EducationVerifyPanResponse(status: true),
      );
      await first;
      await second;

      // Requirement 9: the stale failure for the previous PAN must not
      // overwrite the result of the current PAN.
      expect(controller.state.panVerified, isTrue);
      expect(controller.state.panErrorMessage, isNull);
      expect(controller.state.isVerifyingPan, isFalse);
    });
  });

  group('stale response safety', () {
    // Requirement 9: a late response for an abandoned PAN is discarded.
    test('slow response for a previous PAN never flips the current result',
        () async {
      repository.hangNext = true;

      controller.updatePan('ABCDE1234F');
      final first = controller.verifyPan();
      controller.updatePan('LMNOP5678Q');
      final second = controller.verifyPan();

      // Resolve the newest first, then the stale one with a failure.
      repository.inFlight[1].complete(
        const EducationVerifyPanResponse(status: true),
      );
      await pumpPending();
      repository.inFlight[0].complete(
        const EducationVerifyPanResponse(status: false, message: 'boom'),
      );

      await first;
      await second;

      expect(controller.state.panVerified, isTrue,
          reason: 'stale failure must not clear the verified newest PAN');
      expect(controller.state.panErrorMessage, isNull);
    });
  });
}

// Lets queued microtasks/futures settle between completions.
Future<void> pumpPending() => Future<void>.delayed(Duration.zero);
