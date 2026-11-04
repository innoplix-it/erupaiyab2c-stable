import '../models/education_fees_responses.dart';
import '../services/education_fees_service.dart';

class EducationFeesRepository {
  EducationFeesRepository({EducationFeesService? service})
      : _service = service ?? EducationFeesService();

  final EducationFeesService _service;

  Future<EducationValidateAmountResponse> validateAmount(int amount) {
    return _service.validateAmount(amount);
  }

  Future<EducationCheckMobileResponse> checkMobile(String mobile) {
    return _service.checkMobile(mobile);
  }

  Future<EducationTutorVerifyResponse> verifyTutor(String mobile) {
    return _service.verifyTutor(mobile);
  }

  Future<EducationTutorDetailsResponse> fetchTutorDetails({
    required String mobile,
    required int amount,
  }) {
    return _service.fetchTutorDetails(mobile: mobile, amount: amount);
  }

  Future<EducationTutorSendRequestResponse> sendTutorRequest({
    required String mobile,
    required int amount,
    required String subject,
  }) {
    return _service.sendTutorRequest(
      mobile: mobile,
      amount: amount,
      subject: subject,
    );
  }

  Future<EducationTutorRequestStatusResponse> fetchTutorRequestStatus(
    String requestReference,
  ) {
    return _service.fetchTutorRequestStatus(requestReference);
  }

  Future<EducationTutorReceivedRequestsResponse> fetchTutorReceivedRequests({
    required int page,
    required int perPage,
    String? status,
  }) {
    return _service.fetchTutorReceivedRequests(
      page: page,
      perPage: perPage,
      status: status,
    );
  }

  Future<EducationTutorRespondToRequestResponse> respondToTutorRequest({
    required String requestReference,
    required String action,
  }) {
    return _service.respondToTutorRequest(
      requestReference: requestReference,
      action: action,
    );
  }

  Future<EducationTutorVerifyPanResponse> verifyTutorPan(String pan) {
    return _service.verifyTutorPan(pan);
  }

  Future<EducationTutorVerifyBankResponse> verifyTutorBank({
    required String recipientReference,
    required String accountNo,
    required String ifsc,
  }) {
    return _service.verifyTutorBank(
      recipientReference: recipientReference,
      accountNo: accountNo,
      ifsc: ifsc,
    );
  }

  Future<EducationVerifyPanResponse> verifyPan({
    required String name,
    required String pan,
    required String deviceId,
  }) {
    return _service.verifyPan(
      name: name,
      pan: pan,
      deviceId: deviceId,
    );
  }

  Future<EducationVerifyBankResponse> verifyBank({
    required String accountNo,
    required String ifsc,
    required String recipientName,
  }) {
    return _service.verifyBank(
      accountNo: accountNo,
      ifsc: ifsc,
      recipientName: recipientName,
    );
  }

  Future<EducationPaymentSummaryResponse> fetchPaymentSummary({
    required int amount,
    int? walletUsed,
    double? gstRate,
  }) {
    return _service.fetchPaymentSummary(
      amount: amount,
      walletUsed: walletUsed,
      gstRate: gstRate,
    );
  }

  Future<EducationCardListResponse> fetchCardList() {
    return _service.fetchCardList();
  }

  Future<EducationCreateOrderResponse> createOrder({
    required String recipientName,
    required String accountNo,
    required String ifsc,
    required double amount,
    String? feeType,
    String? accountNoUnmasked,
  }) {
    return _service.createOrder(
      recipientName: recipientName,
      accountNo: accountNo,
      accountNoUnmasked: accountNoUnmasked,
      ifsc: ifsc,
      amount: amount,
      feeType: feeType,
    );
  }

  Future<EducationPaymentStatusResponse> fetchPaymentStatus({
    required String transactionRefId,
  }) {
    return _service.fetchPaymentStatus(transactionRefId: transactionRefId);
  }

  Future<EducationBeneficiariesResponse> fetchBeneficiaries() {
    return _service.fetchBeneficiaries();
  }

  Future<EducationSaveBeneficiaryResponse> saveBeneficiary({
    required String name,
    required String mobile,
    required String pan,
    required String accountType,
    required String accountNo,
    required String ifsc,
  }) {
    return _service.saveBeneficiary(
      name: name,
      mobile: mobile,
      pan: pan,
      accountType: accountType,
      accountNo: accountNo,
      ifsc: ifsc,
    );
  }

  Future<EducationTutorSaveBeneficiaryResponse> saveTutorBeneficiary({
    required String recipientReference,
  }) {
    return _service.saveTutorBeneficiary(
      recipientReference: recipientReference,
    );
  }

  Future<EducationTutorSaveBeneficiaryRegisteredResponse>
      saveTutorBeneficiaryRegistered({
    required String requestReference,
  }) {
    return _service.saveTutorBeneficiaryRegistered(
      requestReference: requestReference,
    );
  }
}
