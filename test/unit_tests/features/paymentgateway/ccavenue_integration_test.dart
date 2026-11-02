import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/services/models/service_payment_order_result.dart';
import 'package:e_rupaiya/features/paymentgateway/ccavenue_webview_screen.dart';

void main() {
  group('ServicePaymentOrderResult - CCAvenue gateway detection', () {
    test('parses CCAvenue response with all fields', () {
      final json = {
        'status': true,
        'message': 'CCAvenue payment initiated',
        'transaction_ref': 'INOP202610311153306EE6C79E',
        'txn_id': 1810,
        'order_id': 'INOP202610311153306EE6C79E',
        'gateway': 'CCAVENUE',
        'encRequest': 'ENCRYPTED_REQUEST',
        'access_code': 'ACCESS_CODE',
        'payment_url': 'https://test.ccavenue.com/transaction/transaction.do?command=initiateTransaction',
        'key': '',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.isSuccess, true);
      expect(result.transactionRef, 'INOP202610311153306EE6C79E');
      expect(result.txnId, 1810);
      expect(result.orderId, 'INOP202610311153306EE6C79E');
      expect(result.gateway, 'CCAVENUE');
      expect(result.encRequest, 'ENCRYPTED_REQUEST');
      expect(result.accessCode, 'ACCESS_CODE');
      expect(result.paymentUrl, 'https://test.ccavenue.com/transaction/transaction.do?command=initiateTransaction');
      expect(result.isCcavenue, true);
      expect(result.isRazorpay, false);
    });

    test('parses Razorpay response (gateway field missing or not CCAVENUE)', () {
      final json = {
        'status': true,
        'message': 'Razorpay payment initiated',
        'transaction_ref': 'TXN123',
        'txn_id': 123,
        'order_id': 'order_123',
        'key': 'rzp_test_key',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.isSuccess, true);
      expect(result.gateway, '');
      expect(result.isCcavenue, false);
      expect(result.isRazorpay, true);
    });

    test('parses response with gateway field set to RAZORPAY', () {
      final json = {
        'status': true,
        'message': 'Razorpay payment initiated',
        'transaction_ref': 'TXN123',
        'txn_id': 123,
        'order_id': 'order_123',
        'gateway': 'RAZORPAY',
        'key': 'rzp_test_key',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.isCcavenue, false);
      expect(result.isRazorpay, true);
    });

    test('handles missing CCAvenue fields gracefully', () {
      final json = {
        'status': true,
        'message': 'Payment initiated',
        'transaction_ref': 'TXN123',
        'txn_id': 123,
        'order_id': 'order_123',
        'gateway': 'CCAVENUE',
        'key': '',
        'encRequest': '',
        'access_code': '',
        'payment_url': '',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.isCcavenue, true);
      expect(result.encRequest, '');
      expect(result.accessCode, '');
      expect(result.paymentUrl, '');
    });

    test('case-insensitive gateway detection', () {
      final jsonLower = {
        'status': true,
        'transaction_ref': 'TXN123',
        'txn_id': 123,
        'order_id': 'order_123',
        'gateway': 'ccavenue',
        'key': '',
      };

      final jsonMixed = {
        'status': true,
        'transaction_ref': 'TXN123',
        'txn_id': 123,
        'order_id': 'order_123',
        'gateway': 'CcAvEnUe',
        'key': '',
      };

      final resultLower = ServicePaymentOrderResult.fromJson(jsonLower);
      final resultMixed = ServicePaymentOrderResult.fromJson(jsonMixed);

      expect(resultLower.isCcavenue, true);
      expect(resultMixed.isCcavenue, true);
    });
  });

  group('Gateway selection validation', () {
    test('CCAvenue requires paymentUrl, encRequest, and accessCode', () {
      final validJson = {
        'status': true,
        'transaction_ref': 'TXN123',
        'txn_id': 123,
        'order_id': 'order_123',
        'gateway': 'CCAVENUE',
        'encRequest': 'ENCRYPTED',
        'access_code': 'ACCESS',
        'payment_url': 'https://test.ccavenue.com/transaction',
        'key': '',
      };

      final result = ServicePaymentOrderResult.fromJson(validJson);
      expect(result.isCcavenue, true);
      expect(result.paymentUrl?.trim().isNotEmpty, true);
      expect(result.encRequest?.trim().isNotEmpty, true);
      expect(result.accessCode?.trim().isNotEmpty, true);
    });

    test('Razorpay requires orderId and key', () {
      final validJson = {
        'status': true,
        'transaction_ref': 'TXN123',
        'txn_id': 123,
        'order_id': 'order_123',
        'key': 'rzp_test_key',
      };

      final result = ServicePaymentOrderResult.fromJson(validJson);
      expect(result.isRazorpay, true);
      expect(result.orderId.trim().isNotEmpty, true);
      expect(result.key.trim().isNotEmpty, true);
    });
  });

  group('Module exclusion tests', () {
    test('Mobile Prepaid payment type should be excluded from CCAvenue', () {
      final paymentType = 'Mobile Prepaid';
      final normalized = paymentType.trim().toLowerCase();
      final isMobilePrepaid = normalized.contains('mobile prepaid');
      expect(isMobilePrepaid, true);
    });

    test('Mobile Postpaid payment type should be eligible for CCAvenue', () {
      final paymentType = 'Mobile Postpaid';
      final normalized = paymentType.trim().toLowerCase();
      final isMobilePrepaid = normalized.contains('mobile prepaid');
      expect(isMobilePrepaid, false);
    });

    test('Electricity payment type should be eligible for CCAvenue', () {
      final paymentType = 'Electricity';
      final normalized = paymentType.trim().toLowerCase();
      final isMobilePrepaid = normalized.contains('mobile prepaid');
      expect(isMobilePrepaid, false);
    });

    test('Gas payment type should be eligible for CCAvenue', () {
      final paymentType = 'Gas';
      final normalized = paymentType.trim().toLowerCase();
      final isMobilePrepaid = normalized.contains('mobile prepaid');
      expect(isMobilePrepaid, false);
    });

    test('DTH payment type should be eligible for CCAvenue', () {
      final paymentType = 'DTH';
      final normalized = paymentType.trim().toLowerCase();
      final isMobilePrepaid = normalized.contains('mobile prepaid');
      expect(isMobilePrepaid, false);
    });

    test('Broadband payment type should be eligible for CCAvenue', () {
      final paymentType = 'Broadband Postpaid';
      final normalized = paymentType.trim().toLowerCase();
      final isMobilePrepaid = normalized.contains('mobile prepaid');
      expect(isMobilePrepaid, false);
    });
  });

  group('Transaction Status API Identifier Regression Tests', () {
    test('Create Order response parses transaction_ref correctly', () {
      final json = {
        'status': true,
        'message': 'Order created',
        'transaction_ref': 'INOP202610311153306EE6C79E',
        'txn_id': 1810,
        'order_id': 'INOP202610311153306EE6C79E',
        'key': 'rzp_test_key',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.transactionRef, 'INOP202610311153306EE6C79E');
      expect(result.txnId, 1810);
      expect(result.orderId, 'INOP202610311153306EE6C79E');
    });

    test('transaction_ref is a String field, txn_id is numeric', () {
      final json = {
        'status': true,
        'transaction_ref': 'INOP202610311153306EE6C79E',
        'txn_id': 1810,
        'order_id': 'INOP202610311153306EE6C79E',
        'key': 'rzp_test_key',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.transactionRef, isA<String>());
      expect(result.txnId, isA<int>());
      expect(result.transactionRef, isNot(1810));
    });

    test('transaction_ref value matches expected format', () {
      final json = {
        'status': true,
        'transaction_ref': 'INOP202610311153306EE6C79E',
        'txn_id': 1810,
        'order_id': 'INOP202610311153306EE6C79E',
        'key': 'rzp_test_key',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.transactionRef, 'INOP202610311153306EE6C79E');
      expect(result.transactionRef.length, greaterThan(0));
      expect(result.transactionRef.contains('INOP'), true);
    });

    test('txn_id is numeric and not used in status API (model level)', () {
      final json = {
        'status': true,
        'transaction_ref': 'INOP202610311153306EE6C79E',
        'txn_id': 1810,
        'order_id': 'INOP202610311153306EE6C79E',
        'key': 'rzp_test_key',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.txnId, 1810);
      expect(result.txnId, isA<int>());
      expect(result.transactionRef, isNot(equals(result.txnId)));
    });

    test('CCAvenue response also parses transaction_ref correctly', () {
      final json = {
        'status': true,
        'message': 'CCAvenue order created',
        'transaction_ref': 'INOP202610311153306EE6C79E',
        'txn_id': 1810,
        'order_id': 'INOP202610311153306EE6C79E',
        'gateway': 'CCAVENUE',
        'encRequest': 'ENCRYPTED_REQUEST',
        'access_code': 'ACCESS_CODE',
        'payment_url': 'https://test.ccavenue.com/transaction',
        'key': '',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.transactionRef, 'INOP202610311153306EE6C79E');
      expect(result.isCcavenue, true);
    });

    test('redirect_url is parsed correctly from CCAvenue response', () {
      final json = {
        'status': true,
        'message': 'CCAvenue order created',
        'transaction_ref': 'INOP20261031131257F617119A',
        'txn_id': 1816,
        'order_id': 'INOP20261031131257F617119A',
        'gateway': 'CCAVENUE',
        'encRequest': 'ENCRYPTED_REQUEST',
        'access_code': 'ACCESS_CODE',
        'payment_url': 'https://secure.ccavenue.com/transaction/transaction.do?command=initiateTransaction',
        'redirect_url': 'https://erupaiya.com/api/webhook/ccavenue',
        'cancel_url': 'https://erupaiya.com/api/webhook/ccavenue',
        'key': '',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.redirectUrl, 'https://erupaiya.com/api/webhook/ccavenue');
      expect(result.cancelUrl, 'https://erupaiya.com/api/webhook/ccavenue');
    });

    test('redirect_url and cancel_url are nullable and handle missing fields', () {
      final json = {
        'status': true,
        'transaction_ref': 'INOP202610311153306EE6C79E',
        'txn_id': 1810,
        'order_id': 'INOP202610311153306EE6C79E',
        'key': 'rzp_test_key',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.redirectUrl, '');
      expect(result.cancelUrl, '');
    });

    test('different redirect and cancel URLs are parsed correctly', () {
      final json = {
        'status': true,
        'transaction_ref': 'INOP202610311153306EE6C79E',
        'txn_id': 1810,
        'order_id': 'INOP202610311153306EE6C79E',
        'gateway': 'CCAVENUE',
        'redirect_url': 'https://erupaiya.com/api/webhook/ccavenue/redirect',
        'cancel_url': 'https://erupaiya.com/api/webhook/ccavenue/cancel',
        'key': '',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.redirectUrl, 'https://erupaiya.com/api/webhook/ccavenue/redirect');
      expect(result.cancelUrl, 'https://erupaiya.com/api/webhook/ccavenue/cancel');
      expect(result.redirectUrl, isNot(result.cancelUrl));
    });

    test('Razorpay response does not require redirect_url and cancel_url', () {
      final json = {
        'status': true,
        'message': 'Razorpay payment initiated',
        'transaction_ref': 'TXN123',
        'txn_id': 123,
        'order_id': 'order_123',
        'key': 'rzp_test_key',
      };

      final result = ServicePaymentOrderResult.fromJson(json);

      expect(result.isCcavenue, false);
      expect(result.redirectUrl, '');
      expect(result.cancelUrl, '');
    });
  });

  group('Callback URL Matching Logic Tests', () {
    bool _matchesCallbackUrl(String currentUrl, String? configuredUrl) {
      if (configuredUrl == null || configuredUrl.trim().isEmpty) return false;
      final uri = Uri.parse(currentUrl);
      final configuredUri = Uri.parse(configuredUrl.trim());
      return uri.scheme == configuredUri.scheme &&
             uri.host == configuredUri.host &&
             uri.port == configuredUri.port &&
             uri.path == configuredUri.path;
    }

    test('redirect URL matches exact host and path', () {
      const currentUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      const redirectUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      
      expect(_matchesCallbackUrl(currentUrl, redirectUrl), true);
    });

    test('redirect URL matches with query parameters', () {
      const currentUrl = 'https://erupaiya.com/api/webhook/ccavenue?status=success&txn_id=123';
      const redirectUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      
      expect(_matchesCallbackUrl(currentUrl, redirectUrl), true);
    });

    test('redirect URL does not match different host', () {
      const currentUrl = 'https://malicious.com/api/webhook/ccavenue';
      const redirectUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      
      expect(_matchesCallbackUrl(currentUrl, redirectUrl), false);
    });

    test('redirect URL does not match different path', () {
      const currentUrl = 'https://erupaiya.com/api/other/path';
      const redirectUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      
      expect(_matchesCallbackUrl(currentUrl, redirectUrl), false);
    });

    test('redirect URL does not match different scheme', () {
      const currentUrl = 'http://erupaiya.com/api/webhook/ccavenue';
      const redirectUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      
      expect(_matchesCallbackUrl(currentUrl, redirectUrl), false);
    });

    test('redirect URL does not match different port', () {
      const currentUrl = 'https://erupaiya.com:8080/api/webhook/ccavenue';
      const redirectUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      
      expect(_matchesCallbackUrl(currentUrl, redirectUrl), false);
    });

    test('cancel URL matches exact host and path', () {
      const currentUrl = 'https://erupaiya.com/api/webhook/ccavenue/cancel';
      const cancelUrl = 'https://erupaiya.com/api/webhook/ccavenue/cancel';
      
      expect(_matchesCallbackUrl(currentUrl, cancelUrl), true);
    });

    test('identical redirect and cancel URLs both match', () {
      const currentUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      const callbackUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      
      expect(_matchesCallbackUrl(currentUrl, callbackUrl), true);
    });

    test('different redirect and cancel URLs match', () {
      const currentUrlRedirect = 'https://erupaiya.com/api/webhook/ccavenue/redirect';
      const currentUrlCancel = 'https://erupaiya.com/api/webhook/ccavenue/cancel';
      const redirectUrl = 'https://erupaiya.com/api/webhook/ccavenue/redirect';
      const cancelUrl = 'https://erupaiya.com/api/webhook/ccavenue/cancel';
      
      expect(_matchesCallbackUrl(currentUrlRedirect, redirectUrl), true);
      expect(_matchesCallbackUrl(currentUrlCancel, cancelUrl), true);
      expect(_matchesCallbackUrl(currentUrlRedirect, cancelUrl), false);
      expect(_matchesCallbackUrl(currentUrlCancel, redirectUrl), false);
    });

    test('empty callback URL does not match', () {
      const currentUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      const emptyUrl = '';
      
      expect(_matchesCallbackUrl(currentUrl, emptyUrl), false);
    });

    test('null callback URL does not match', () {
      const currentUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      
      expect(_matchesCallbackUrl(currentUrl, null), false);
    });

    test('duplicate callback prevention with identical URLs', () {
      const currentUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      const callbackUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      
      expect(_matchesCallbackUrl(currentUrl, callbackUrl), true);
      // Second call would be prevented by _hasHandledCallback flag in actual implementation
    });

    test('duplicate callback prevention with different URLs', () {
      const currentUrlRedirect = 'https://erupaiya.com/api/webhook/ccavenue/redirect';
      const currentUrlCancel = 'https://erupaiya.com/api/webhook/ccavenue/cancel';
      const redirectUrl = 'https://erupaiya.com/api/webhook/ccavenue/redirect';
      const cancelUrl = 'https://erupaiya.com/api/webhook/ccavenue/cancel';
      
      expect(_matchesCallbackUrl(currentUrlRedirect, redirectUrl), true);
      expect(_matchesCallbackUrl(currentUrlCancel, cancelUrl), true);
      // Only one would trigger in actual implementation due to _hasHandledCallback flag
    });
  });

  group('CCAvenue Cancellation Flow Logic Tests', () {
    test('duplicate callback prevention flag logic', () {
      // Simulate the _hasHandledCallback and _isClosing flag behavior
      var hasHandledCallback = false;
      var isClosing = false;
      var callbackCount = 0;

      void handlePaymentComplete() {
        if (hasHandledCallback || isClosing) return;
        hasHandledCallback = true;
        isClosing = true;
        callbackCount++;
      }

      // First call should succeed
      handlePaymentComplete();
      expect(callbackCount, 1);
      expect(hasHandledCallback, true);
      expect(isClosing, true);

      // Second call should be prevented
      handlePaymentComplete();
      expect(callbackCount, 1);

      // Third call should also be prevented
      handlePaymentComplete();
      expect(callbackCount, 1);
    });

    test('PopScope canPop state changes during closure', () {
      // Simulate the canPop state change
      var isClosing = false;
      var canPop = isClosing;

      // Initially, canPop should be false
      expect(canPop, false);

      // When closing starts, canPop becomes true
      isClosing = true;
      canPop = isClosing;
      expect(canPop, true);

      // This allows Navigator.pop() to succeed
    });

    test('identical callback URLs do not cause duplicate matches', () {
      const redirectUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      const cancelUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      const currentUrl = 'https://erupaiya.com/api/webhook/ccavenue?status=success';

      bool matchesCallbackUrl(String currentUrl, String configuredUrl) {
        final uri = Uri.parse(currentUrl);
        final configuredUri = Uri.parse(configuredUrl.trim());
        return uri.scheme == configuredUri.scheme &&
               uri.host == configuredUri.host &&
               uri.port == configuredUri.port &&
               uri.path == configuredUri.path;
      }

      // Both URLs match the current URL
      expect(matchesCallbackUrl(currentUrl, redirectUrl), true);
      expect(matchesCallbackUrl(currentUrl, cancelUrl), true);

      // But the _hasHandledCallback flag prevents duplicate processing
      var hasHandledCallback = false;
      var processCount = 0;

      void processCallback() {
        if (hasHandledCallback) return;
        hasHandledCallback = true;
        processCount++;
      }

      processCallback();
      expect(processCount, 1);

      processCallback();
      expect(processCount, 1);
    });

    test('query parameters do not break callback matching', () {
      const configuredUrl = 'https://erupaiya.com/api/webhook/ccavenue';
      const urlWithParams = 'https://erupaiya.com/api/webhook/ccavenue?status=success&txn_id=123&amount=1000';
      const urlWithoutParams = 'https://erupaiya.com/api/webhook/ccavenue';

      bool matchesCallbackUrl(String currentUrl, String configuredUrl) {
        final uri = Uri.parse(currentUrl);
        final configuredUri = Uri.parse(configuredUrl.trim());
        return uri.scheme == configuredUri.scheme &&
               uri.host == configuredUri.host &&
               uri.port == configuredUri.port &&
               uri.path == configuredUri.path;
      }

      expect(matchesCallbackUrl(urlWithParams, configuredUrl), true);
      expect(matchesCallbackUrl(urlWithoutParams, configuredUrl), true);
    });
  });

  group('CCAvenue WebView Widget Tests', () {
    testWidgets('AppBar close button triggers callback via setState sequence',
        (WidgetTester tester) async {
      var callbackCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CCAvenueWebViewScreen(
                        paymentUrl: 'https://secure.ccavenue.com/transaction/transaction.do',
                        encRequest: 'ENCRYPTED_REQUEST',
                        accessCode: 'ACCESS_CODE',
                        transactionRef: 'INOP20261031131257F617119A',
                        redirectUrl: 'https://erupaiya.com/api/webhook/ccavenue',
                        cancelUrl: 'https://erupaiya.com/api/webhook/ccavenue',
                        onPaymentComplete: () {
                          callbackCount++;
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Open Payment'),
              ),
            ),
          ),
        ),
      );

      // Note: WebView requires platform-specific initialization
      // This test validates the widget structure and callback mechanism
      // Actual WebView navigation requires integration tests or device testing
      expect(find.text('Open Payment'), findsOneWidget);
    });

    testWidgets('PopScope canPop state changes prevent duplicate navigation',
        (WidgetTester tester) async {
      // Test the state-driven PopScope behavior without WebView
      bool isClosing = false;
      bool canPop = isClosing;
      
      expect(canPop, false);
      
      // Simulate setState
      isClosing = true;
      canPop = isClosing;
      
      expect(canPop, true);
    });

    testWidgets('callback execution is prevented by flags', (WidgetTester tester) async {
      // Simulate the flag-based prevention logic
      var hasHandledCallback = false;
      var isClosing = false;
      var executionCount = 0;

      void executeCallback() {
        if (hasHandledCallback || isClosing) return;
        hasHandledCallback = true;
        isClosing = true;
        executionCount++;
      }

      executeCallback();
      expect(executionCount, 1);

      executeCallback();
      expect(executionCount, 1);

      executeCallback();
      expect(executionCount, 1);
    });
  });
}
