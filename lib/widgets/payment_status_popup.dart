// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/file_constants.dart';

enum PaymentStatusType {
  success,
  error,
}

/// Reusable payment status popup component
/// Shows success or error status with customizable content
class PaymentStatusPopup extends StatelessWidget {
  const PaymentStatusPopup({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.amount,
    required this.statusTag,
    required this.subMessage,
    required this.onDone,
    this.onClose,
  });

  final PaymentStatusType type;
  final String title;
  final String message;
  final String amount;
  final String statusTag;
  final String subMessage;
  final VoidCallback onDone;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final iconSvg = type == PaymentStatusType.success
        ? FileConstants.successCheckmarkIconSvg
        : FileConstants.errorCrossIconSvg;

    final backgroundColor = type == PaymentStatusType.success
        ? const Color(0xFFB5FFDA).withOpacity(0.3)
        : const Color(0xFFFFE5E5).withOpacity(0.3);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Background with color overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button
                  if (onClose != null)
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: onClose,
                        child: const Icon(
                          Icons.close,
                          size: 24,
                          color: Color(0xFF71717A),
                        ),
                      ),
                    ),
                  // Icon
                  SvgPicture.asset(
                    iconSvg,
                    width: 88,
                    height: 88,
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: const Color(0xFF71717A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  Text(
                    amount,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Status tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: type == PaymentStatusType.success
                          ? const Color(0xFF058337).withOpacity(0.1)
                          : const Color(0xFF870002).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: type == PaymentStatusType.success
                            ? const Color(0xFF058337)
                            : const Color(0xFF870002),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      statusTag,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: type == PaymentStatusType.success
                            ? const Color(0xFF058337)
                            : const Color(0xFF870002),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sub message
                  Text(
                    subMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: const Color(0xFF71717A),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Done button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDD5428),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show the payment status popup
Future<void> showPaymentStatusPopup({
  required BuildContext context,
  required PaymentStatusType type,
  required String title,
  required String message,
  required String amount,
  required String statusTag,
  required String subMessage,
  VoidCallback? onDone,
  VoidCallback? onClose,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PaymentStatusPopup(
      type: type,
      title: title,
      message: message,
      amount: amount,
      statusTag: statusTag,
      subMessage: subMessage,
      onDone: () {
        Navigator.of(dialogContext).pop();
        onDone?.call();
      },
      onClose: onClose != null
          ? () {
              Navigator.of(dialogContext).pop();
              onClose();
            }
          : null,
    ),
  );
}
