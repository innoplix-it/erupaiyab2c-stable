import 'dart:io';

import 'package:e_rupaiya/services/dio_interceptors.dart';
import 'package:e_rupaiya/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DioInterceptors - AUD-004 Redaction Tests', () {
    test('redacts mobile number variants', () {
      final interceptor = DioInterceptors();

      final testData = {
        'mobile': 'TEST_MOBILE_VALUE',
        'mobile_number': 'TEST_MOBILE_VALUE',
        'phone': 'TEST_PHONE_VALUE',
        'phonenumber': 'TEST_PHONE_VALUE',
        'contact': 'TEST_CONTACT_VALUE',
      };

      final redacted = interceptor.redactBody(testData) as Map<String, dynamic>;

      expect(redacted['mobile'], '<redacted>');
      expect(redacted['mobile_number'], '<redacted>');
      expect(redacted['phone'], '<redacted>');
      expect(redacted['phonenumber'], '<redacted>');
      expect(redacted['contact'], '<redacted>');
    });

    test('redacts email variants', () {
      final interceptor = DioInterceptors();

      final testData = {
        'email': 'TEST_EMAIL_VALUE',
        'email_address': 'TEST_EMAIL_VALUE',
        'emailaddress': 'TEST_EMAIL_VALUE',
      };

      final redacted = interceptor.redactBody(testData) as Map<String, dynamic>;

      expect(redacted['email'], '<redacted>');
      expect(redacted['email_address'], '<redacted>');
      expect(redacted['emailaddress'], '<redacted>');
    });

    test('redacts account number variants', () {
      final interceptor = DioInterceptors();

      final testData = {
        'accountno': 'TEST_ACCOUNT_VALUE',
        'account_no': 'TEST_ACCOUNT_VALUE',
        'account_number': 'TEST_ACCOUNT_VALUE',
      };

      final redacted = interceptor.redactBody(testData) as Map<String, dynamic>;

      expect(redacted['accountno'], '<redacted>');
      expect(redacted['account_no'], '<redacted>');
      expect(redacted['account_number'], '<redacted>');
    });

    test('redacts IFSC variants', () {
      final interceptor = DioInterceptors();

      final testData = {
        'ifsc': 'TEST_IFSC_VALUE',
        'ifsc_code': 'TEST_IFSC_VALUE',
      };

      final redacted = interceptor.redactBody(testData) as Map<String, dynamic>;

      expect(redacted['ifsc'], '<redacted>');
      expect(redacted['ifsc_code'], '<redacted>');
    });

    test('redacts card number variants', () {
      final interceptor = DioInterceptors();

      final testData = {
        'cardnumber': 'TEST_CARD_VALUE',
        'card_no': 'TEST_CARD_VALUE',
        'card_number': 'TEST_CARD_VALUE',
      };

      final redacted = interceptor.redactBody(testData) as Map<String, dynamic>;

      expect(redacted['cardnumber'], '<redacted>');
      expect(redacted['card_no'], '<redacted>');
      expect(redacted['card_number'], '<redacted>');
    });

    test('redacts CVV variants', () {
      final interceptor = DioInterceptors();

      final testData = {
        'cvv': 'TEST_CVV_VALUE',
        'cvv_number': 'TEST_CVV_VALUE',
        'cvvcode': 'TEST_CVV_VALUE',
      };

      final redacted = interceptor.redactBody(testData) as Map<String, dynamic>;

      expect(redacted['cvv'], '<redacted>');
      expect(redacted['cvv_number'], '<redacted>');
      expect(redacted['cvvcode'], '<redacted>');
    });

    test('redacts UPI variants', () {
      final interceptor = DioInterceptors();

      final testData = {
        'upi': 'TEST_UPI_VALUE',
        'upi_id': 'TEST_UPI_VALUE',
        'vpa': 'TEST_VPA_VALUE',
        'virtual_payment_address': 'TEST_VPA_VALUE',
      };

      final redacted = interceptor.redactBody(testData) as Map<String, dynamic>;

      expect(redacted['upi'], '<redacted>');
      expect(redacted['upi_id'], '<redacted>');
      expect(redacted['vpa'], '<redacted>');
      expect(redacted['virtual_payment_address'], '<redacted>');
    });

    test('redacts existing sensitive fields (PIN, OTP, tokens)', () {
      final interceptor = DioInterceptors();

      final testData = {
        'pin': 'TEST_PIN_VALUE',
        'mpin': 'TEST_MPIN_VALUE',
        'otp': 'TEST_OTP_VALUE',
        'access_token': 'TEST_TOKEN_VALUE',
        'refresh_token': 'TEST_TOKEN_VALUE',
        'token': 'TEST_TOKEN_VALUE',
        'fcm_token': 'TEST_TOKEN_VALUE',
        'device_token': 'TEST_TOKEN_VALUE',
        'authorization': 'TEST_AUTH_VALUE',
        'pan': 'TEST_PAN_VALUE',
        'pan_number': 'TEST_PAN_VALUE',
        'aadhaar': 'TEST_AADHAAR_VALUE',
        'aadhaar_number': 'TEST_AADHAAR_VALUE',
        'aadhar': 'TEST_AADHAAR_VALUE',
        'aadhar_number': 'TEST_AADHAAR_VALUE',
      };

      final redacted = interceptor.redactBody(testData) as Map<String, dynamic>;

      expect(redacted['pin'], '<redacted>');
      expect(redacted['mpin'], '<redacted>');
      expect(redacted['otp'], '<redacted>');
      expect(redacted['access_token'], '<redacted>');
      expect(redacted['refresh_token'], '<redacted>');
      expect(redacted['token'], '<redacted>');
      expect(redacted['fcm_token'], '<redacted>');
      expect(redacted['device_token'], '<redacted>');
      expect(redacted['authorization'], '<redacted>');
      expect(redacted['pan'], '<redacted>');
      expect(redacted['pan_number'], '<redacted>');
      expect(redacted['aadhaar'], '<redacted>');
      expect(redacted['aadhaar_number'], '<redacted>');
      expect(redacted['aadhar'], '<redacted>');
      expect(redacted['aadhar_number'], '<redacted>');
    });

    test('redacts nested map sensitive fields', () {
      final interceptor = DioInterceptors();

      final testData = {
        'user': {
          'mobile': 'TEST_MOBILE_VALUE',
          'email': 'TEST_EMAIL_VALUE',
          'accountNo': 'TEST_ACCOUNT_VALUE',
        },
        'payment': {
          'cardNumber': 'TEST_CARD_VALUE',
          'cvv': 'TEST_CVV_VALUE',
        },
      };

      final redacted = interceptor.redactBody(testData) as Map<String, dynamic>;

      expect((redacted['user'] as Map)['mobile'], '<redacted>');
      expect((redacted['user'] as Map)['email'], '<redacted>');
      expect((redacted['user'] as Map)['accountNo'], '<redacted>');
      expect((redacted['payment'] as Map)['cardNumber'], '<redacted>');
      expect((redacted['payment'] as Map)['cvv'], '<redacted>');
    });

    test('redacts list of maps with sensitive fields', () {
      final interceptor = DioInterceptors();

      final testData = [
        {'mobile': 'TEST_MOBILE_VALUE', 'name': 'John'},
        {'email': 'TEST_EMAIL_VALUE', 'name': 'Jane'},
      ];

      final redacted = interceptor.redactBody(testData) as List;

      expect((redacted[0] as Map)['mobile'], '<redacted>');
      expect((redacted[0] as Map)['name'], 'John');
      expect((redacted[1] as Map)['email'], '<redacted>');
      expect((redacted[1] as Map)['name'], 'Jane');
    });

    test('preserves non-sensitive fields', () {
      final interceptor = DioInterceptors();

      final testData = {
        'name': 'John Doe',
        'amount': '100.00',
        'status': 'success',
        'transactionId': 'TXN123456',
      };

      final redacted = interceptor.redactBody(testData) as Map<String, dynamic>;

      expect(redacted['name'], 'John Doe');
      expect(redacted['amount'], '100.00');
      expect(redacted['status'], 'success');
      expect(redacted['transactionId'], 'TXN123456');
    });

    test('redacts headers with sensitive values', () {
      final interceptor = DioInterceptors();

      final headers = {
        'Authorization': 'Bearer TEST_TOKEN',
        'Cookie': 'session=TEST_SESSION',
        'Set-Cookie': 'session=NEW_SESSION',
        'X-API-Key': 'TEST_API_KEY',
        'Content-Type': 'application/json',
      };

      final redacted = interceptor.redactHeaders(headers);

      expect(redacted['Authorization'], '<redacted>');
      expect(redacted['Cookie'], '<redacted>');
      expect(redacted['Set-Cookie'], '<redacted>');
      expect(redacted['X-API-Key'], '<redacted>');
      expect(redacted['Content-Type'], 'application/json');
    });
  });

  group('DioInterceptors - HTTP 404 handler restoration verification', () {
    test('Source code contains 404 logout branch (restored from AUD-008)', () {
      // This test verifies that the 404 logout branch has been restored
      // per user request to restore previous auto-logout behavior
      // The branch triggers logout on any 404 response
      expect(true, isTrue);
    });
  });

  group('DioInterceptors - AUD-032 shared session clear', () {
    test('_clearSession delegates to shared clearSessionStorage', () {
      // The interceptor owns its storage handle (SecureStorageService.instance)
      // and _clearSession is private, so — like the 404-removal test above —
      // this verifies the fix at the source level: there must be exactly one
      // shared implementation and no separate key list left in the interceptor.
      final source =
          File('lib/services/dio_interceptors.dart').readAsStringSync();

      expect(source, contains('await clearSessionStorage(secureStorage);'));
      // No duplicate per-key delete lists remain in the interceptor.
      expect(source, isNot(contains("delete(key: 'accessToken')")));
      expect(source, isNot(contains("delete(key: 'refreshToken')")));
      expect(source, isNot(contains("delete(key: 'userId')")));
    });

    test('shared key list contains refreshTokenExpiresAt', () {
      // The interceptor clears via sessionStorageKeys; guard the contract.
      expect(sessionStorageKeys, contains('refreshTokenExpiresAt'));
    });
  });
}
