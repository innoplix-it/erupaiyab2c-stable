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
    try {
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
      final payload = response.data as Map<String, dynamic>? ?? {};
      return EducationSaveBeneficiaryResponse.fromJson(payload);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          return EducationSaveBeneficiaryResponse.fromJson(data);
        }
      }
      logger.error('Failed to save beneficiary: $e', error: e);
      rethrow;
    }
  }
}
