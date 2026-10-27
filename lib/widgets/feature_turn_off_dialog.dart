import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A reusable confirmation dialog matching Figma specifications for turning off
/// or revoking features / permissions.
///
/// Features:
/// - Clean white card with rounded corners and subtle elevation shadow.
/// - Left-aligned bold title ("Do you want to turn off this feature?")
/// - Left-aligned subtitle ("Are you sure ?")
/// - Two side-by-side pill buttons:
///   - [cancelLabel] (Primary filled orange button on the left)
///   - [confirmLabel] (Secondary white button with orange border on the right)
/// - Proportional responsive sizing following MediaQuery guidelines.
class FeatureTurnOffDialog extends StatelessWidget {
  const FeatureTurnOffDialog({
    super.key,
    this.title = 'Do you want to turn off this feature?',
    this.subtitle = 'Are you sure ?',
    this.cancelLabel = 'Cancel',
    this.confirmLabel = 'Yes, Turn Off',
    this.onCancel,
    this.onConfirm,
  });

  final String title;
  final String subtitle;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  /// Displays the [FeatureTurnOffDialog] centrally over the current screen.
  ///
  /// Returns `true` if the user confirmed ([confirmLabel] tapped),
  /// or `false` if cancelled ([cancelLabel] tapped or dialog dismissed).
  static Future<bool> show(
    BuildContext context, {
    String title = 'Do you want to turn off this feature?',
    String subtitle = 'Are you sure ?',
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Yes, Turn Off',
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => FeatureTurnOffDialog(
        title: title,
        subtitle: subtitle,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Responsive scaling ratio based on standard 390px width
    final textScaleRatio = (screenWidth / 390.0).clamp(0.85, 1.2);

    // Proportional dialog width: ~86% of screen width clamped to safe range
    final dialogWidth = (screenWidth * 0.86).clamp(275.0, 340.0);

    // Proportional padding (~5.5% of dialog width, approx 16-20px)
    final paddingH = (dialogWidth * 0.058).clamp(16.0, 20.0);
    final paddingV = (dialogWidth * 0.058).clamp(16.0, 20.0);

    // Typography
    final titleFontSize = (18.0 * textScaleRatio).clamp(16.0, 19.5);
    final subtitleFontSize = (13.5 * textScaleRatio).clamp(12.0, 15.0);
    final buttonFontSize = (13.5 * textScaleRatio).clamp(12.0, 14.5);

    // Spacing
    final titleSubtitleSpacing = (dialogWidth * 0.024).clamp(6.0, 8.0);
    final subtitleButtonSpacing = (dialogWidth * 0.052).clamp(16.0, 20.0);
    final buttonGap = (dialogWidth * 0.035).clamp(10.0, 14.0);

    // Button sizing
    final buttonHeight = (screenHeight * 0.05).clamp(38.0, 42.0);
    final buttonRadius = BorderRadius.circular(24.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: ((screenWidth - dialogWidth) / 2).clamp(12.0, 40.0),
        vertical: 24.0,
      ),
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24.0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          paddingH,
          paddingV,
          paddingH,
          paddingV,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title: "Do you want to turn off this feature?"
              Text(
                title,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF09090B),
                          fontSize: titleFontSize,
                          height: 1.25,
                          letterSpacing: -0.2,
                        ) ??
                    TextStyle(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF09090B),
                      fontSize: titleFontSize,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
              ),
              SizedBox(height: titleSubtitleSpacing),
              // Subtitle: "Are you sure ?"
              Text(
                subtitle,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF52525B),
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ) ??
                    TextStyle(
                      color: const Color(0xFF52525B),
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
              ),
              SizedBox(height: subtitleButtonSpacing),
              // Action Buttons Row: [Cancel (filled)] | [Yes, Turn Off (outlined)]
              Row(
                children: [
                  // Cancel (Primary action in Figma: filled orange pill)
                  Expanded(
                    child: SizedBox(
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed:
                            onCancel ?? () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: buttonRadius,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            cancelLabel,
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: buttonGap),
                  // Yes, Turn Off (Secondary action in Figma: white pill with orange border)
                  Expanded(
                    child: SizedBox(
                      height: buttonHeight,
                      child: OutlinedButton(
                        onPressed:
                            onConfirm ?? () => Navigator.of(context).pop(true),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: buttonRadius,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            confirmLabel,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
