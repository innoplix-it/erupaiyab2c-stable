import 'dart:io';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/profile/models/api_response_model.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  ProfileRepository({Dio? dio}) : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<ProfileModel> fetchProfile() async {
    try {
      final response = await _dio.get(ApiConstants.profileEndpoint);
      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true;
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'Failed to fetch profile';
        throw Exception(message);
      }
      final data = payload?['data'] as Map<String, dynamic>? ?? {};
      return ProfileModel.fromJson(data);
    } catch (e) {
      logger.error('Failed to fetch profile: $e', error: e);
      rethrow;
    }
  }

  Future<ProfileModel> updateProfile({
    required String name,
    required String email,
    required String address,
    File? image,
  }) async {
    try {
      final fields = <String, dynamic>{
        'name': name,
        'email': email,
        'address': address,
      };
      if (image != null) {
        fields['profile_photo'] = await MultipartFile.fromFile(image.path);
      }
      final response = await _dio.post(
        ApiConstants.profileUpdateEndpoint,
        data: FormData.fromMap(fields),
        options: Options(contentType: 'multipart/form-data'),
      );
      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true ||
          (payload?['status']?.toString().toUpperCase() == 'SUCCESS');
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'Failed to update profile';
        throw Exception(message);
      }
      final data = payload?['data'] as Map<String, dynamic>? ??
          payload?['payload'] as Map<String, dynamic>? ??
          {};
      return ProfileModel.fromJson(data);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        final message = (data is Map ? data['message'] as String? : null) ??
            'Failed to update profile';
        logger.error('Failed to update profile: $message', error: e);
        throw Exception(message);
      }
      logger.error('Failed to update profile: $e', error: e);
      rethrow;
    }
  }

  Future<ProfileModel> updateProfileImage(File image) async {
    try {
      final formData = FormData.fromMap({
        'profile_photo': await MultipartFile.fromFile(image.path),
      });
      final response = await _dio.post(
        ApiConstants.profileUpdateEndpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true ||
          (payload?['status']?.toString().toUpperCase() == 'SUCCESS');
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'Failed to update profile image';
        throw Exception(message);
      }
      final data = payload?['data'] as Map<String, dynamic>? ??
          payload?['payload'] as Map<String, dynamic>? ??
          {};
      return ProfileModel.fromJson(data);
    } catch (e) {
      logger.error('Failed to update profile image: $e', error: e);
      rethrow;
    }
  }

  Future<ProfileModel> updateDeliveryInfo({
    required String billingAddressLine1,
    required String billingAddressLine2,
    required String billingCity,
    required String billingState,
    required String billingZip,
    required String billingCountry,
    required String billingMobile,
    required String deliveryAddressLine1,
    required String deliveryAddressLine2,
    required String deliveryCity,
    required String deliveryState,
    required String deliveryZip,
    required String deliveryCountry,
    required String deliveryMobile,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.profileUpdateDeliveryInfoEndpoint,
        data: {
          'billing_address_line1': billingAddressLine1,
          'billing_address_line2': billingAddressLine2,
          'billing_city': billingCity,
          'billing_state': billingState,
          'billing_zip': billingZip,
          'billing_country': billingCountry,
          'billing_mobile': billingMobile,
          'delivery_address_line1': deliveryAddressLine1,
          'delivery_address_line2': deliveryAddressLine2,
          'delivery_city': deliveryCity,
          'delivery_state': deliveryState,
          'delivery_zip': deliveryZip,
          'delivery_country': deliveryCountry,
          'delivery_mobile': deliveryMobile,
        },
        options: Options(contentType: 'application/json'),
      );
      final payload = response.data as Map<String, dynamic>?;
      final success = payload?['success'] == true ||
          (payload?['status']?.toString().toUpperCase() == 'SUCCESS');
      if (!success) {
        final message =
            payload?['message'] as String? ?? 'Failed to update delivery info';
        throw Exception(message);
      }
      final data = payload?['data'] as Map<String, dynamic>? ??
          payload?['payload'] as Map<String, dynamic>? ??
          {};
      return ProfileModel.fromJson(data);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        final message = (data is Map ? data['message'] as String? : null) ??
            'Failed to update delivery info';
        logger.error('Failed to update delivery info: $message', error: e);
        throw Exception(message);
      }
      logger.error('Failed to update delivery info: $e', error: e);
      rethrow;
    }
  }

  Future<ApiResponse> updateMobile(String mobileNo) async {
    final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/user/profile/request-contact-update',
        data: {
          'type': 'mobile',
          'value': mobileNo,
        });

    return ApiResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiResponse> verifyMobileOtp(String otp) async {
    final response = await _dio.post(
      ApiConstants.profileVerifyContactUpdateEndpoint,
      data: {
        'type': 'mobile',
        'otp': otp,
      },
    );

    return ApiResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiResponse> updateEmail(String email) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}/api/user/profile/request-contact-update',
      data: {
        'type': 'email',
        'value': email,
      },
    );

    return ApiResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiResponse> verifyEmailOtp(String otp) async {
    final response = await _dio.post(
      ApiConstants.profileVerifyContactUpdateEndpoint,
      data: {
        'type': 'email',
        'otp': otp,
      },
    );

    return ApiResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiResponse> updateDeviceToken(String token) async {
    final response = await _dio.post(
      ApiConstants.profileUpdateDeviceTokenEndpoint,
      data: {
        'device_token': token,
      },
    );

    return ApiResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiResponse> completeProfile({
    required String name,
    required String email,
    String type = 'manual',
    String? googleToken,
    @Deprecated('Use googleToken (maps to google_token).') String? idToken,
  }) async {
    final resolvedGoogleToken = (googleToken ?? idToken)?.trim();
    final response = await _dio.post(
      ApiConstants.completeProfileEndpoint,
      data: {
        'name': name,
        'email': email,
        'type': type,
        if (resolvedGoogleToken != null && resolvedGoogleToken.isNotEmpty)
          'google_token': resolvedGoogleToken,
      },
      options: Options(contentType: 'application/json'),
    );

    return ApiResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiResponse> verifyCompleteProfileOtp({
    required String otp,
  }) async {
    final response = await _dio.post(
      ApiConstants.completeProfileVerifyOtpEndpoint,
      data: {
        'otp': otp,
      },
      options: Options(contentType: 'application/json'),
    );

    return ApiResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
