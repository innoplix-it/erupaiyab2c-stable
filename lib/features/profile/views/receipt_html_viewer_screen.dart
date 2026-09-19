import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/error_message_utils.dart';
import '../../../widgets/app_snackbar.dart';
import '../services/receipt_file_service.dart';

class ReceiptHtmlViewerScreen extends StatefulWidget {
  const ReceiptHtmlViewerScreen({
    super.key,
    required this.html,
    required this.transactionId,
  });

  final String html;
  final String transactionId;

  @override
  State<ReceiptHtmlViewerScreen> createState() =>
      _ReceiptHtmlViewerScreenState();
}

class _ReceiptHtmlViewerScreenState extends State<ReceiptHtmlViewerScreen> {
  late final WebViewController _controller;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final normalizedHtml = ReceiptFileService.normalizeHtml(widget.html);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(normalizedHtml);
  }

  Future<void> _handleShare() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final cached =
          await ReceiptFileService.getCachedReceipt(widget.transactionId);
      final pdfFile = cached ??
          await (() async {
            if (Platform.isAndroid) {
              final generated =
                  await ReceiptFileService.buildPdfFileFromHtmlViaWebView(
                html: widget.html,
                transactionId: widget.transactionId,
              );
              final bytes = await generated.readAsBytes();
              return ReceiptFileService.savePdfToCache(
                pdfBytes: bytes,
                transactionId: widget.transactionId,
              );
            }
            final pdfBytes =
                await ReceiptFileService.buildPdfBytesFromHtml(widget.html);
            return ReceiptFileService.savePdfToCache(
              pdfBytes: pdfBytes,
              transactionId: widget.transactionId,
            );
          })();
      await Share.shareXFiles(
        [
          XFile(
            pdfFile.path,
            mimeType: 'application/pdf',
            name: 'receipt_${widget.transactionId}.pdf',
          ),
        ],
        text: 'Payment Receipt',
      );
    } catch (e) {
      AppSnackbar.show(
        ErrorMessageUtils.from(
          e,
          fallback: 'Failed to share receipt. Please try again.',
        ),
        type: AppSnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Receipt',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            onPressed: _isBusy ? null : _handleShare,
            icon: Icon(
              Icons.share,
              color: _isBusy ? Colors.white54 : Colors.white,
            ),
          ),
          // IconButton(
          //   onPressed: _isBusy ? null : _handleDownload,
          //   icon: Icon(
          //     Icons.download,
          //     color: _isBusy ? Colors.white54 : Colors.white,
          //   ),
          // ),
          SizedBox(width: 4.w),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
