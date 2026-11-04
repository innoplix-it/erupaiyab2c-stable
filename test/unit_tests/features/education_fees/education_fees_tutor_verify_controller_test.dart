import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';

class _FakeVerifyRepository extends EducationFeesRepository {
  _FakeVerifyRepository({this.verifyResponse, this.detailsResponse, this.error});

  EducationTutorVerifyResponse? verifyResponse;
  EducationTutorDetailsResponse? detailsResponse;
  final Object? error;

  final calls = <String>[];

  @override
  Future<EducationTutorVerifyResponse> verifyTutor(String mobile) async {
    calls.add('verify:$mobile');
    if (error != null) throw error!;
    return verifyResponse ??
        const EducationTutorVerifyResponse(
          status: false,
          verificationStatus: EducationTutorVerificationStatus.unknown,
        );
  }

  @override
  Future<EducationTutorDetailsResponse> fetchTutorDetails({
    required String mobile,
    required int amount,
  }) async {
    calls.add('details:$mobile:$amount');
    if (error != null) throw error!;
    return detailsResponse ??
        const EducationTutorDetailsResponse(
          status: false,
          verificationStatus: EducationTutorVerificationStatus.unknown,
        );
  }
}

void main() {
  const verified = EducationTutorVerifyResponse(
    status: true,
    verificationStatus: EducationTutorVerificationStatus.verified,
    message: 'Mobile number verified successfully.',
  );

  group('EducationFeesController.verifyTutor', () {
    test('returns the VERIFIED outcome for a registered, KYC-complete tutor',
        () async {
      final repo = _FakeVerifyRepository(verifyResponse: verified);
      final controller = EducationFeesController(repository: repo);

      final response = await controller.verifyTutor('8055851920');

      expect(repo.calls, ['verify:8055851920']);
      expect(response, isNotNull);
      expect(response!.status, isTrue);
      expect(response.verificationStatus,
          EducationTutorVerificationStatus.verified);
      expect(response.confirmsVerifiedTutor, isTrue);
    });

    test('NOT_VERIFIED and NOT_FOUND are returned untouched', () async {
      final repo = _FakeVerifyRepository();
      final controller = EducationFeesController(repository: repo);

      repo.verifyResponse = const EducationTutorVerifyResponse(
        status: true,
        verificationStatus: EducationTutorVerificationStatus.notVerified,
        message: 'This user is registered but KYC is not completed.',
      );
      final notVerified = await controller.verifyTutor('8055851920');
      expect(
        notVerified!.verificationStatus,
        EducationTutorVerificationStatus.notVerified,
      );
      expect(notVerified.confirmsVerifiedTutor, isFalse);

      repo.verifyResponse = const EducationTutorVerifyResponse(
        status: true,
        verificationStatus: EducationTutorVerificationStatus.notFound,
        message: 'This mobile number is not registered in eRupaiya.',
      );
      final notFound = await controller.verifyTutor('8055851920');
      expect(
        notFound!.verificationStatus,
        EducationTutorVerificationStatus.notFound,
      );
      expect(notFound.message,
          'This mobile number is not registered in eRupaiya.');
    });

    test('mobile is normalised to 10 digits before the POST', () async {
      final repo = _FakeVerifyRepository(verifyResponse: verified);
      final controller = EducationFeesController(repository: repo);

      await controller.verifyTutor('+91 80558-51920');

      expect(repo.calls, ['verify:8055851920']);
    });

    test('incomplete mobile does not call the API', () async {
      final repo = _FakeVerifyRepository(verifyResponse: verified);
      final controller = EducationFeesController(repository: repo);

      final response = await controller.verifyTutor('80558519');

      expect(response, isNull);
      expect(repo.calls, isEmpty);
    });

    test('network failure returns null instead of a guessed status', () async {
      final repo = _FakeVerifyRepository(error: Exception('timeout'));
      final controller = EducationFeesController(repository: repo);

      final response = await controller.verifyTutor('8055851920');

      expect(response, isNull);
      expect(repo.calls, ['verify:8055851920']);
    });

    test('status false and unknown status are surfaced for the caller',
        () async {
      final repo = _FakeVerifyRepository();
      final controller = EducationFeesController(repository: repo);

      repo.verifyResponse = const EducationTutorVerifyResponse(
        status: false,
        verificationStatus: EducationTutorVerificationStatus.verified,
        message: 'Invalid request',
      );
      final failedRequest = await controller.verifyTutor('8055851920');
      expect(failedRequest!.status, isFalse);
      expect(failedRequest.confirmsVerifiedTutor, isFalse);

      repo.verifyResponse = const EducationTutorVerifyResponse(
        status: true,
        verificationStatus: EducationTutorVerificationStatus.unknown,
      );
      final unknown = await controller.verifyTutor('8055851920');
      expect(unknown!.hasKnownVerificationStatus, isFalse);
    });
  });

  group('EducationFeesController.fetchTutorDetails', () {
    const detailsData = EducationTutorDetailsData(
      tutorId: 1,
      tutorName: 'John Doe',
      accountNumber: '1234567890123456',
      bankName: 'HDFC Bank',
      bankLogo: 'https://example.com/bank-logo.png',
      accountHolderName: 'John Doe',
      ifsc: 'HDFC0001234',
      amount: 2000,
    );

    const detailsResponse = EducationTutorDetailsResponse(
      status: true,
      verificationStatus: EducationTutorVerificationStatus.verified,
      data: detailsData,
    );

    test('calls Tutor Details API with correct mobile and amount', () async {
      final repo = _FakeVerifyRepository(detailsResponse: detailsResponse);
      final controller = EducationFeesController(repository: repo);

      final response = await controller.fetchTutorDetails(
        mobile: '8055851920',
        amount: 2000,
      );

      expect(repo.calls, ['details:8055851920:2000']);
      expect(response, isNotNull);
      expect(response!.status, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!.tutorName, 'John Doe');
    });

    test('mobile is normalised to 10 digits before the POST', () async {
      final repo = _FakeVerifyRepository(detailsResponse: detailsResponse);
      final controller = EducationFeesController(repository: repo);

      await controller.fetchTutorDetails(
        mobile: '+91 80558-51920',
        amount: 2000,
      );

      expect(repo.calls, ['details:8055851920:2000']);
    });

    test('incomplete mobile does not call the API', () async {
      final repo = _FakeVerifyRepository(detailsResponse: detailsResponse);
      final controller = EducationFeesController(repository: repo);

      final response = await controller.fetchTutorDetails(
        mobile: '80558519',
        amount: 2000,
      );

      expect(response, isNull);
      expect(repo.calls, isEmpty);
    });

    test('network failure rethrows the error', () async {
      final repo = _FakeVerifyRepository(error: Exception('timeout'));
      final controller = EducationFeesController(repository: repo);

      await expectLater(
        controller.fetchTutorDetails(mobile: '8055851920', amount: 2000),
        throwsA(isA<Exception>()),
      );

      expect(repo.calls, ['details:8055851920:2000']);
    });
  });
}
