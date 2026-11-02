import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

typedef CCAvenuePaymentCallback = void Function();

class CCAvenueWebViewScreen extends StatefulWidget {
  const CCAvenueWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.encRequest,
    required this.accessCode,
    required this.transactionRef,
    required this.onPaymentComplete,
    this.redirectUrl,
    this.cancelUrl,
  });

  final String paymentUrl;
  final String encRequest;
  final String accessCode;
  final String transactionRef;
  final CCAvenuePaymentCallback onPaymentComplete;
  final String? redirectUrl;
  final String? cancelUrl;

  @override
  State<CCAvenueWebViewScreen> createState() => _CCAvenueWebViewScreenState();
}

class _CCAvenueWebViewScreenState extends State<CCAvenueWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasHandledCallback = false;
  bool _isClosing = false;

  static const List<String> _upiSchemes = [
    'phonepe://',
    'tez://',
    'paytmmp://',
    'bhim://',
    'credpay://',
    'upi://',
  ];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkForCallback(url);
          },
          onWebResourceError: (WebResourceError error) {
            // Log resource errors but do not trigger payment completion
            // Only actual callback URLs or manual close should trigger verification
            // Network errors during external app switching are handled by onPageFinished
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            
            // Check for UPI app intents
            for (final scheme in _upiSchemes) {
              if (url.startsWith(scheme)) {
                _launchExternalApp(url);
                return NavigationDecision.prevent;
              }
            }
            
            // Check for callback URLs in navigation
            _checkForCallback(url);
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'CcavenueCallback',
        onMessageReceived: (JavaScriptMessage message) {
          // Handle JavaScript-based callbacks if any
          _handlePaymentComplete();
        },
      )
      ..loadRequest(
        _buildPostRequest(),
      );
  }

  void _checkForCallback(String url) {
    if (_hasHandledCallback) return;
    
    // Use backend-provided callback URLs only
    final redirectUrl = widget.redirectUrl?.trim();
    final cancelUrl = widget.cancelUrl?.trim();
    
    // If no callback URLs provided, do not trigger callback
    if ((redirectUrl == null || redirectUrl.isEmpty) && (cancelUrl == null || cancelUrl.isEmpty)) {
      return;
    }
    
    final uri = Uri.parse(url);
    
    // Check if current URL matches redirect URL (scheme, host, port, path; ignore query params)
    if (redirectUrl != null && redirectUrl.isNotEmpty) {
      final redirectUri = Uri.parse(redirectUrl);
      if (uri.scheme == redirectUri.scheme &&
          uri.host == redirectUri.host &&
          uri.port == redirectUri.port &&
          uri.path == redirectUri.path) {
        _handlePaymentComplete();
        return;
      }
    }
    
    // Check if current URL matches cancel URL (scheme, host, port, path; ignore query params)
    if (cancelUrl != null && cancelUrl.isNotEmpty) {
      final cancelUri = Uri.parse(cancelUrl);
      if (uri.scheme == cancelUri.scheme &&
          uri.host == cancelUri.host &&
          uri.port == cancelUri.port &&
          uri.path == cancelUri.path) {
        _handlePaymentComplete();
        return;
      }
    }
  }

  Uri _buildPostRequest() {
    final postData = Uri(
      queryParameters: {
        'command': 'initiateTransaction',
        'encRequest': widget.encRequest,
        'access_code': widget.accessCode,
      },
    );
    
    return Uri.parse(widget.paymentUrl).replace(
      query: postData.query,
    );
  }

  Future<void> _launchExternalApp(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          // External app launch failed - continue in WebView
          // Do not mark transaction as failed
        }
      }
    } catch (e) {
      // Handle launch failure gracefully
      // Do not crash or mark transaction as failed
    }
  }

  void _handlePaymentComplete() {
    if (_hasHandledCallback || _isClosing) return;
    
    setState(() {
      _hasHandledCallback = true;
      _isClosing = true;
    });
    
    // Navigate after state update is applied
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPaymentComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isClosing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isClosing) {
          // User pressed Android hardware Back or system gesture
          // Trigger verification - actual status determined by transaction status API
          _handlePaymentComplete();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // User manually closed via AppBar button
              // Trigger verification - actual status determined by transaction status API
              _handlePaymentComplete();
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
