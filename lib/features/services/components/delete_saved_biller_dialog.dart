import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';
import 'fetch_provider_metrics.dart';

const _deleteAccountCloseSvg = 'assets/images/svg/delete_account_close.svg';
const _accent = Color(0xFFDD5428);
const _figmaFrameWidth = 440.0;
const _maxDialogWidth = 480.0;

/// Shows the Fetch Your Provider "Delete Account" confirmation and resolves to
/// `true` only when the user taps Yes.
Future<bool> showDeleteSavedBillerDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const DeleteSavedBillerDialog(),
  );
  return confirmed ?? false;
}

/// Horizontal Figma values scale with the real screen width (MediaQuery);
/// vertical values, radii and fonts go through ScreenUtil.
class _DialogSpec {
  _DialogSpec(BuildContext context)
      : screenWidth = MediaQuery.sizeOf(context).width;

  final double screenWidth;

  double x(double figmaPx) => figmaPx * screenWidth / _figmaFrameWidth;
  double y(double figmaPx) => FetchProviderMetrics.h(figmaPx);
  double r(double figmaPx) => FetchProviderMetrics.r(figmaPx);
  double font(double figmaPx, {required double min}) =>
      FetchProviderMetrics.font(figmaPx, min: min);

  // (440 - 391) / 2: the 391px Figma popup centred in the 440px frame.
  double get sideInset => x(24.5);
  double get dialogWidth =>
      math.min(screenWidth - 2 * sideInset, _maxDialogWidth);
}

class DeleteSavedBillerDialog extends StatelessWidget {
  const DeleteSavedBillerDialog({super.key});

  static const message =
      'Do You Want To Remove This Account From Your Saved Billers?';

  @override
  Widget build(BuildContext context) {
    final spec = _DialogSpec(context);
    final titleSize = spec.font(16, min: 13);
    final messageSize = spec.font(14, min: 12);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: spec.sideInset),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: spec.dialogWidth,
          padding: EdgeInsets.fromLTRB(
            spec.x(24),
            spec.y(20),
            spec.x(24),
            spec.y(20),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(spec.r(16)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A000000),
                offset: Offset(0, spec.r(4)),
                blurRadius: spec.r(16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: spec.y(40)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      FileConstants.deleteAccountSvg,
                      width: spec.x(24),
                      height: spec.x(24),
                    ),
                    SizedBox(width: spec.x(10)),
                    Expanded(
                      child: Text(
                        'Delete Account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: titleSize,
                          height: 1,
                          letterSpacing: -0.02 * titleSize,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ),
                    SizedBox(width: spec.x(8)),
                    Semantics(
                      button: true,
                      label: 'Close',
                      child: InkResponse(
                        key: const ValueKey('delete-account-close'),
                        onTap: () => Navigator.of(context).pop(false),
                        radius: spec.x(20),
                        child: SizedBox(
                          width: spec.x(24),
                          height: spec.x(24),
                          child: SvgPicture.asset(_deleteAccountCloseSvg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spec.y(12)),
              Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  fontSize: messageSize,
                  height: 21 / 14,
                  letterSpacing: -0.02 * messageSize,
                  color: const Color(0xFF000000),
                ),
              ),
              SizedBox(height: spec.y(13)),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE0E0E0),
              ),
              SizedBox(height: spec.y(16)),
              Row(
                children: [
                  // Figma widths 162.5 and 164.5 share the row in that ratio.
                  Expanded(
                    flex: 1625,
                    child: _DialogButton(
                      spec: spec,
                      label: 'No',
                      filled: true,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  SizedBox(width: spec.x(16)),
                  Expanded(
                    flex: 1645,
                    child: _DialogButton(
                      spec: spec,
                      label: 'Yes',
                      filled: false,
                      onTap: () => Navigator.of(context).pop(true),
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

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.spec,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final _DialogSpec spec;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(spec.r(50));
    final fontSize = spec.font(14, min: 12);
    return Material(
      color: filled ? _accent : const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: filled ? BorderSide.none : const BorderSide(color: _accent),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          // Grows with large text instead of clipping the label.
          constraints: BoxConstraints(minHeight: spec.y(38)),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spec.x(12),
              vertical: spec.y(10),
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize,
                  height: 1,
                  letterSpacing: -0.02 * fontSize,
                  color: filled ? const Color(0xFFFFFFFF) : _accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
