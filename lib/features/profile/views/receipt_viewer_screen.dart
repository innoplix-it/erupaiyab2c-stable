// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/my_app_bar.dart';

class ReceiptViewerScreen extends StatefulWidget {
  const ReceiptViewerScreen({
    super.key,
    required this.pdfBytes,
    required this.transactionId,
  });

  final Uint8List pdfBytes;
  final String transactionId;

  @override
  State<ReceiptViewerScreen> createState() => _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends State<ReceiptViewerScreen> {
  bool _isBusy = false;

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.storage.status;
    if (status.isGranted) return true;
    final result = await Permission.storage.request();
    return result.isGranted;
  }

  Future<String> _resolveDownloadPath(String fileName) async {
    if (Platform.isAndroid) {
      const downloadDir = '/storage/emulated/0/Download';
      final dir = Directory(downloadDir);
      if (await dir.exists()) {
        return '$downloadDir/$fileName';
      }
    }
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }

  Future<File> _saveFile() async {
    final fileName = 'receipt_${widget.transactionId}.pdf';
    final path = await _resolveDownloadPath(fileName);
    final file = File(path);
    return file.writeAsBytes(widget.pdfBytes, flush: true);
  }

  Future<void> _handleShare() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final file = await _saveFile();
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      AppSnackbar.show('Failed to share receipt.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleDownload() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      if (Platform.isAndroid) {
        final granted = await _ensureStoragePermission();
        if (!granted) {
          AppSnackbar.show('Storage permission required to download.');
          return;
        }
      }
      final file = await _saveFile();
      AppSnackbar.show('Receipt saved to ${file.path}');
    } catch (_) {
      AppSnackbar.show('Failed to download receipt.');
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
          // Common app-bar title typography, white on the orange bar.
          style: MyAppBar.sharedTitleStyle(context, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _isBusy ? null : _handleShare,
            icon: Icon(
              Icons.share,
              color: _isBusy ? Colors.white54 : Colors.white,
            ),
          ),
          IconButton(
            onPressed: _isBusy ? null : _handleDownload,
            icon: Icon(
              Icons.download,
              color: _isBusy ? Colors.white54 : Colors.white,
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: PdfPreview(
        build: (_) async => widget.pdfBytes,
        allowSharing: false,
        allowPrinting: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
