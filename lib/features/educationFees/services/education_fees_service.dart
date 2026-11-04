import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../../../services/payment_device_context_service.dart';
import '../models/education_fees_responses.dart';

class EducationFeesService {
  EducationFeesService({Dio? dio}) : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<EducationValidateAmountResponse> validateAmount(int amount) async {
    try {
      final response = await _dio.post(
        ApiConstants.educationValidateAmountEndpoint,
        data: {
          'amount': amount,
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationValidateAmountResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationValidateAmountResponse.fromJson(data);
        }
      }
      logger.error('Failed to validate amount: $e', error: e);
      rethrow;
    }
  }

  Future<EducationCheckMobileResponse> checkMobile(String mobile) async {
    try {
      final response = await _dio.post(
        ApiConstants.educationCheckMobileEndpoint,
        data: {
          'mobile': mobile,
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationCheckMobileResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationCheckMobileResponse.fromJson(data);
        }
      }
      logger.error('Failed to check mobile: $e', error: e);
      rethrow;
    }
  }

  Future<EducationTutorVerifyResponse> verifyTutor(String mobile) async {
    try {
      final response = await _dio.post(
        ApiConstants.educationTutorVerifyEndpoint,
        data: {
          'mobile': mobile,
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationTutorVerifyResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationTutorVerifyResponse.fromJson(data);
        }
      }
      logger.error('Failed to verify tutor: $e', error: e);
      rethrow;
    }
  }

  Future<EducationTutorDetailsResponse> fetchTutorDetails({
    required String mobile,
    required int amount,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.educationTutorDetailsEndpoint,
        data: {
          'mobile': mobile,
          'amount': amount,
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationTutorDetailsResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationTutorDetailsResponse.fromJson(data);
        }
      }
      logger.error('Failed to fetch tutor details: $e', error: e);
      rethrow;
    }
  }

  Future<EducationTutorSendRequestResponse> sendTutorRequest({
    required String mobile,
    required int amount,
    required String subject,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.educationTutorSendRequestEndpoint,
        data: {
          'mobile': mobile,
          'amount': amount,
          'subject': subject,
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationTutorSendRequestResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationTutorSendRequestResponse.fromJson(data);
        }
      }
      logger.error('Failed to send tutor request: $e', error: e);
      rethrow;
    }
  }

  Future<EducationTutorRequestStatusResponse> fetchTutorRequestStatus(
    String requestReference,
  ) async {
    try {
      final response = await _dio.get(
        ApiConstants.educationTutorRequestStatusEndpoint(requestReference),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationTutorRequestStatusResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationTutorRequestStatusResponse.fromJson(data);
        }
      }
      logger.error('Failed to fetch tutor request status: $e', error: e);
      rethrow;
    }
  }

  Future<EducationTutorReceivedRequestsResponse> fetchTutorReceivedRequests({
    required int page,
    required int perPage,
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await _dio.get(
        ApiConstants.educationTutorReceivedRequestsEndpoint,
        queryParameters: queryParameters,
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationTutorReceivedRequestsResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationTutorReceivedRequestsResponse.fromJson(data);
        }
      }
      logger.error('Failed to fetch tutor received requests: $e', error: e);
      rethrow;
    }
  }

  Future<EducationTutorRespondToRequestResponse> respondToTutorRequest({
    required String requestReference,
    required String action,
  }) async {
    try {
      final request = EducationTutorRespondToRequestRequest(
        requestReference: requestReference,
        action: action,
      );
      final response = await _dio.post(
        ApiConstants.educationTutorRespondToRequestEndpoint(requestReference),
        data: request.toJson(),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationTutorRespondToRequestResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationTutorRespondToRequestResponse.fromJson(data);
        }
      }
      logger.error('Failed to respond to tutor request: $e', error: e);
      rethrow;
    }
  }

  Future<EducationTutorVerifyPanResponse> verifyTutorPan(String pan) async {
    try {
      final request = EducationTutorVerifyPanRequest(pan: pan);
      final response = await _dio.post(
        ApiConstants.educationTutorVerifyPanEndpoint,
        data: request.toJson(),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationTutorVerifyPanResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationTutorVerifyPanResponse.fromJson(data);
        }
        logger.error(
          'Failed to verify tutor PAN: type=${e.type.name} '
          'httpStatus=${e.response?.statusCode}',
        );
      } else {
        logger.error('Failed to verify tutor PAN: ${e.runtimeType}');
      }
      rethrow;
    }
  }

  /// Tutor recipient bank verification
  /// (`POST /api/education/tutor/recipient/verify-bank`).
  ///
  /// All three values arrive dynamically from the flow: the
  /// [recipientReference] stored by a successful PAN verification and the
  /// account number / IFSC from the form. Raw account numbers are never
  /// interpolated into logs — the failure log carries only the Dio exception
  /// type and HTTP status, never the request or response body.
  Future<EducationTutorVerifyBankResponse> verifyTutorBank({
    required String recipientReference,
    required String accountNo,
    required String ifsc,
  }) async {
    try {
      final request = EducationTutorVerifyBankRequest(
        recipientReference: recipientReference,
        accountNo: accountNo,
        ifsc: ifsc,
      );
      final response = await _dio.post(
        ApiConstants.educationTutorVerifyBankEndpoint,
        data: request.toJson(),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationTutorVerifyBankResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationTutorVerifyBankResponse.fromJson(data);
        }
        logger.error(
          'Failed to verify tutor bank: type=${e.type.name} '
          'httpStatus=${e.response?.statusCode}',
        );
      } else {
        logger.error('Failed to verify tutor bank: ${e.runtimeType}');
      }
      rethrow;
    }
  }

  Future<EducationVerifyPanResponse> verifyPan({
    required String name,
    required String pan,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.educationVerifyPanEndpoint,
        data: {
          'name': name,
          'pan': pan,
          'device_id': deviceId,
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationVerifyPanResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationVerifyPanResponse.fromJson(data);
        }
      }
      logger.error('Failed to verify PAN: $e', error: e);
      rethrow;
    }
  }

  Future<EducationVerifyBankResponse> verifyBank({
    required String accountNo,
    required String ifsc,
    required String recipientName,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.educationVerifyBankEndpoint,
        data: {
          'account_no': accountNo,
          'ifsc': ifsc,
          'receipient_name': recipientName,
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationVerifyBankResponse.fromJson(payload);
    } catch (e) {
      logger.error('Failed to verify bank: $e', error: e);
      rethrow;
    }
  }

  Future<EducationPaymentSummaryResponse> fetchPaymentSummary({
    required int amount,
    int? walletUsed,
    double? gstRate,
  }) async {
    try {
      final data = <String, dynamic>{'amount': amount};
      if (walletUsed != null) {
        data['wallet_used'] = walletUsed;
      }
      if (gstRate != null) {
        data['gst_rate'] = gstRate;
      }
      final response = await _dio.post(
        ApiConstants.educationPaymentSummaryEndpoint,
        data: data,
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationPaymentSummaryResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationPaymentSummaryResponse.fromJson(data);
        }
      }
      logger.error('Failed to fetch payment summary: $e', error: e);
      rethrow;
    }
  }

  Future<EducationCardListResponse> fetchCardList() async {
    try {
      final response = await _dio.get(
        ApiConstants.educationCardListEndpoint,
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationCardListResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationCardListResponse.fromJson(data);
        }
      }
      logger.error('Failed to fetch card list: $e', error: e);
      rethrow;
    }
  }

  Future<EducationCreateOrderResponse> createOrder({
    required String recipientName,
    required String accountNo,
    required String ifsc,
    required double amount,
    String? feeType,
    String? accountNoUnmasked,
  }) async {
    try {
      final deviceContext = await const PaymentDeviceContextService().collect();
      final requestObj = EducationCreateOrderRequest(
        recipientName: recipientName,
        accountNo: accountNo,
        ifsc: ifsc,
        amount: amount,
        accountNoUnmasked: accountNoUnmasked,
      );
      final data = requestObj.toJson();
      data.addAll(deviceContext);
      final trimmedFeeType = feeType?.trim();
      if (trimmedFeeType != null && trimmedFeeType.isNotEmpty) {
        data['fee_type'] = trimmedFeeType;
        // House/Shop Rent must carry an explicit payment_type ("House Rent" /
        // "Shop Rent") so the backend records the correct service type instead
        // of defaulting to biller_name (e.g. "Education Fee Payment"). Real
        // education fee types are intentionally left untouched to preserve
        // their existing flow.
        final lowerFeeType = trimmedFeeType.toLowerCase();
        if (lowerFeeType.contains('house rent') ||
            lowerFeeType.contains('shop rent')) {
          data['payment_type'] = trimmedFeeType;
        }
      }
      final response = await _dio.post(
        ApiConstants.educationCreateOrderEndpoint,
        data: data,
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationCreateOrderResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationCreateOrderResponse.fromJson(data);
        }
      }
      logger.error('Failed to create education order: $e', error: e);
      rethrow;
    }
  }

  Future<EducationPaymentStatusResponse> fetchPaymentStatus({
    required String transactionRefId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.educationStatusEndpoint(transactionRefId),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationPaymentStatusResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationPaymentStatusResponse.fromJson(data);
        }
      }
      logger.error('Failed to fetch education payment status: $e', error: e);
      rethrow;
    }
  }

  Future<EducationBeneficiariesResponse> fetchBeneficiaries() async {
    try {
      final response = await _dio.get(
        ApiConstants.educationBeneficiariesEndpoint,
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationBeneficiariesResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationBeneficiariesResponse.fromJson(data);
        }
      }
      logger.error('Failed to fetch beneficiaries: $e', error: e);
      rethrow;
    }
  }

  Future<EducationSaveBeneficiaryResponse> saveBeneficiary({
    required String name,
    required String mobile,
    required String pan,
    required String accountType,
    required String accountNo,
    required String ifsc,
  }) async {
    logger.info('EDU_SAVE SERVICE_CALLED');
    try {
      logger.info('EDU_SAVE DIO_REQUEST_ATTEMPTED');
      final response = await _dio.post(
        ApiConstants.educationSaveBeneficiaryEndpoint,
        data: {
          'name': name,
          'mobile': mobile,
          'pan': pan,
          'account_type': accountType,
          'account_no': accountNo,
          'ifsc': ifsc,
        },
      );
      logger.info(
        'EDU_SAVE DIO_RESPONSE_RECEIVED httpStatus=${response.statusCode}',
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationSaveBeneficiaryResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        logger.info(
          'EDU_SAVE DIO_RESPONSE_RECEIVED '
          'httpStatus=${e.response?.statusCode} error=${e.type.name}',
        );
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationSaveBeneficiaryResponse.fromJson(data);
        }
      }
      logger.error('Failed to save beneficiary: $e', error: e);
      rethrow;
    }
  }

  /// Tutor recipient save beneficiary for unverified tutor flow
  /// (`POST /api/education/save-beneficiary`).
  ///
  /// The [recipientReference] is the exact value stored by a successful tutor
  /// PAN verification; it is never hardcoded, reconstructed or replaced by the
  /// beneficiary id. Raw account numbers are never interpolated into logs.
  Future<EducationTutorSaveBeneficiaryResponse> saveTutorBeneficiary({
    required String recipientReference,
  }) async {
    logger.info('EDU_TUTOR_SAVE SERVICE_CALLED');
    try {
      final request = EducationTutorSaveBeneficiaryRequest(
        recipientReference: recipientReference,
      );
      final response = await _dio.post(
        ApiConstants.educationSaveBeneficiaryEndpoint,
        data: request.toJson(),
      );
      logger.info(
        'EDU_TUTOR_SAVE DIO_RESPONSE_RECEIVED httpStatus=${response.statusCode}',
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationTutorSaveBeneficiaryResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        logger.info(
          'EDU_TUTOR_SAVE DIO_RESPONSE_RECEIVED '
          'httpStatus=${e.response?.statusCode} error=${e.type.name}',
        );
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationTutorSaveBeneficiaryResponse.fromJson(data);
        }
      }
      logger.error('Failed to save tutor beneficiary: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Registered/verified tutor Save Beneficiary API
  /// (`POST /api/education/save-beneficiary`).
  ///
  /// The [requestReference] MUST come from the Tutor Send Request response
  /// (`data.request_reference`). It is never hardcoded, reconstructed or replaced
  /// by recipient_reference or beneficiary_id. Raw account numbers are never
  /// interpolated into logs.
  Future<EducationTutorSaveBeneficiaryRegisteredResponse>
      saveTutorBeneficiaryRegistered({
    required String requestReference,
  }) async {
    logger.info('EDU_TUTOR_SAVE_REGISTERED SERVICE_CALLED');
    try {
      final request = EducationTutorSaveBeneficiaryRegisteredRequest(
        requestReference: requestReference,
      );
      final response = await _dio.post(
        ApiConstants.educationSaveBeneficiaryEndpoint,
        data: request.toJson(),
      );
      logger.info(
        'EDU_TUTOR_SAVE_REGISTERED DIO_RESPONSE_RECEIVED '
        'httpStatus=${response.statusCode}',
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationTutorSaveBeneficiaryRegisteredResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        logger.info(
          'EDU_TUTOR_SAVE_REGISTERED DIO_RESPONSE_RECEIVED '
          'httpStatus=${e.response?.statusCode} error=${e.type.name}',
        );
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationTutorSaveBeneficiaryRegisteredResponse.fromJson(data);
        }
      }
      logger.error('Failed to save registered tutor beneficiary: ${e.runtimeType}');
      rethrow;
    }
  }
}
