// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/app_env.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/error_message_utils.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/k_dialog.dart';
import '../repositories/receipt_repository.dart';
import '../services/receipt_file_service.dart';
import '../utils/receipt_html_renderer.dart';
import '../views/receipt_viewer_screen.dart';

void _debugLog(String message) {
  if (!AppEnv.enableLogs || !kDebugMode) return;
  debugPrint(message);
}

enum ReceiptAction { share, download }

class ReceiptActions {
  ReceiptActions._();

  static final Map<String, Future<File>> _pendingPdfBuilds = {};

  static String resolveReceiptTransactionId({
    required String refId,
    required String txnId,
  }) {
    if (refId.trim().isNotEmpty) return refId.trim();
    return txnId.trim();
  }

  static Future<void> handleReceiptAction(
    BuildContext context, {
    required String transactionId,
    required ReceiptAction action,
  }) async {
    if (transactionId.trim().isEmpty) {
      AppSnackbar.show('Missing transaction id.');
      return;
    }

    BuildContext? dialogContext;
    try {
      if (action == ReceiptAction.share) {
        final cached = await ReceiptFileService.getCachedReceipt(transactionId);
        if (cached == null) {
          dialogContext = navigatorKey.currentContext;
          if (dialogContext != null && dialogContext.mounted) {
            showDialog(
              context: dialogContext,
              barrierDismissible: false,
              builder: (_) => const Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
            );
          }
        }
        final pdfFile = cached ??
            await _getOrBuildReceiptPdf(
              transactionId,
              preferWebViewOnAndroid: true,
            );
        _hideLoading(dialogContext);
        await Share.shareXFiles(
          [
            XFile(
              pdfFile.path,
              mimeType: 'application/pdf',
              name: 'receipt_$transactionId.pdf',
            ),
          ],
          text: 'Payment Receipt',
        );
        _debugLog('[Receipt] Share sheet invoked');
      } else {
        final cachedFile = await _getOrBuildReceiptPdf(
          transactionId,
          preferWebViewOnAndroid: Platform.isAndroid,
        );
        final bytes = await cachedFile.readAsBytes();
        final file = await ReceiptFileService.savePdfToDownloads(
          pdfBytes: bytes,
          transactionId: transactionId,
        );
        if (!context.mounted) return;
        await _showDownloadSuccessDialog(
          context,
          transactionId: transactionId,
          file: file,
          onOpen: () async {
            await _openReceiptPdfFile(
              context,
              transactionId: transactionId,
              file: cachedFile,
            );
          },
        );
      }
    } catch (e, t) {
      _debugLog('Receipt generation error: $e');
      _debugLog(t.toString());
      _hideLoading(dialogContext);
      AppSnackbar.show(
        ErrorMessageUtils.from(
          e,
          fallback: 'Failed to generate receipt. Please try again.',
        ),
        type: AppSnackbarType.error,
      );
    }
  }

  static Future<void> openReceiptViewer(
    BuildContext context, {
    required String transactionId,
  }) async {
    if (transactionId.trim().isEmpty) {
      AppSnackbar.show('Missing transaction id.');
      return;
    }

    BuildContext? dialogContext;
    try {
      final cached = await ReceiptFileService.getCachedReceipt(transactionId);
      if (cached != null) {
        if (!context.mounted) return;
        await _openReceiptPdfFile(
          context,
          transactionId: transactionId,
          file: cached,
        );
        return;
      }

      dialogContext = navigatorKey.currentContext;
      if (dialogContext != null && dialogContext.mounted) {
        showDialog(
          context: dialogContext,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: SpinKitCircle(
              color: AppColors.primary,
              size: 48,
            ),
          ),
        );
      }
      final file = await _getOrBuildReceiptPdf(
        transactionId,
        preferWebViewOnAndroid: Platform.isAndroid,
      );
      _hideLoading(dialogContext);
      if (!context.mounted) return;
      await _openReceiptPdfFile(
        context,
        transactionId: transactionId,
        file: file,
      );
    } catch (e, t) {
      _debugLog('Receipt view error: $e');
      _debugLog(t.toString());
      _hideLoading(dialogContext);
      AppSnackbar.show(
        ErrorMessageUtils.from(
          e,
          fallback: 'Failed to open receipt. Please try again.',
        ),
        type: AppSnackbarType.error,
      );
    }
  }

  static const Duration _shareRenderTimeout = Duration(seconds: 15);

  static Future<_SharePdfResult> _buildSharePdfBytes(String html) async {
    var usedFallback = false;
    final startedAt = DateTime.now();
    _debugLog('[Receipt] Share render start');
    try {
      final renderFuture = ReceiptFileService.buildPdfBytesFromHtml(html);
      final fallbackFuture = Future<Uint8List>.delayed(
        _shareRenderTimeout,
        () async {
          usedFallback = true;
          _debugLog(
            '[Receipt] Share render timed out after ${_shareRenderTimeout.inSeconds}s, using fallback',
          );
          return ReceiptFileService.buildSimplePdfFromHtml(html);
        },
      );
      final bytes = await Future.any<Uint8List>([
        renderFuture,
        fallbackFuture,
      ]);
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      _debugLog(
        '[Receipt] Share render completed in ${elapsedMs}ms (fallback=$usedFallback, bytes=${bytes.length})',
      );
      return _SharePdfResult(bytes: bytes, usedFallback: usedFallback);
    } catch (e) {
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      _debugLog('[Receipt] Share render failed after ${elapsedMs}ms: $e');
      final bytes = await ReceiptFileService.buildSimplePdfFromHtml(html);
      return _SharePdfResult(bytes: bytes, usedFallback: true);
    }
  }

  static Future<String> _fetchReceiptHtml(String transactionId) async {
    final repo = ReceiptRepository();
    final html = await repo.fetchReceiptHtml(transactionId: transactionId);
    if (html.trim().isEmpty) {
      throw Exception('Empty receipt content.');
    }
    return html;
  }

  static Future<void> _openReceiptPdfFile(
    BuildContext context, {
    required String transactionId,
    required File file,
  }) async {
    final pdfBytes = await file.readAsBytes();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptViewerScreen(
          pdfBytes: pdfBytes,
          transactionId: transactionId,
        ),
      ),
    );
  }

  static Future<File> _getOrBuildReceiptPdf(
    String transactionId, {
    required bool preferWebViewOnAndroid,
  }) async {
    final cached = await ReceiptFileService.getCachedReceipt(transactionId);
    if (cached != null) {
      return cached;
    }

    final existing = _pendingPdfBuilds[transactionId];
    if (existing != null) {
      return existing;
    }

    final future = _buildAndCacheReceiptPdf(
      transactionId,
      preferWebViewOnAndroid: preferWebViewOnAndroid,
    );
    _pendingPdfBuilds[transactionId] = future;
    try {
      return await future;
    } finally {
      if (identical(_pendingPdfBuilds[transactionId], future)) {
        _pendingPdfBuilds.remove(transactionId);
      }
    }
  }

  static Future<File> _buildAndCacheReceiptPdf(
    String transactionId, {
    required bool preferWebViewOnAndroid,
  }) async {
    final html = await _fetchReceiptHtml(transactionId);

    if (Platform.isAndroid && preferWebViewOnAndroid) {
      _debugLog('[Receipt] Android WebView PDF build start: $transactionId');
      try {
        final generated =
            await ReceiptFileService.buildPdfFileFromHtmlViaWebView(
          html: html,
          transactionId: transactionId,
        );
        final bytes = await generated.readAsBytes();
        return ReceiptFileService.savePdfToCache(
          pdfBytes: bytes,
          transactionId: transactionId,
        );
      } catch (e) {
        _debugLog('[Receipt] Native WebView PDF failed: $e');
      }
    }

    if (Platform.isAndroid) {
      final shareResult = await _buildSharePdfBytes(html);
      if (shareResult.usedFallback) {
        AppSnackbar.show(
          'Using a basic receipt because full rendering is unavailable.',
        );
      }
      return ReceiptFileService.savePdfToCache(
        pdfBytes: shareResult.bytes,
        transactionId: transactionId,
      );
    }

    final pdfBytes = await ReceiptHtmlRenderer.toPdfBytes(html);
    return ReceiptFileService.savePdfToCache(
      pdfBytes: pdfBytes,
      transactionId: transactionId,
    );
  }

  static void _hideLoading(BuildContext? dialogContext) {
    if (dialogContext == null) return;
    if (Navigator.of(dialogContext).canPop()) {
      Navigator.of(dialogContext).pop();
    }
  }

  static Future<void> _showDownloadSuccessDialog(
    BuildContext context, {
    required String transactionId,
    required File file,
    required Future<void> Function() onOpen,
  }) async {
    final savedToDownloads = file.path.contains('/Download/');
    final locationLabel = savedToDownloads
        ? 'Downloads'
        : (Platform.isIOS ? 'Files' : 'device storage');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Receipt Downloaded'),
          content: Text(
            'Your receipt has been saved to $locationLabel. You can open it now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await onOpen();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
    _debugLog('[Receipt] Saved file path: ${file.path} for $transactionId');
  }
}

class _SharePdfResult {
  const _SharePdfResult({required this.bytes, required this.usedFallback});

  final Uint8List bytes;
  final bool usedFallback;
}
