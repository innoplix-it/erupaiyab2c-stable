import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/payment_success_flow.dart';

class EducationPaymentThankYouView extends StatefulWidget {
  const EducationPaymentThankYouView({
    super.key,
    required this.amount,
    this.payableAmount = '',
    this.transactionTime = '',
    this.bannerImage = '',
    this.paymentType = '',
  });

  final String amount;
  final String payableAmount;
  final String transactionTime;
  final String bannerImage;
  final String paymentType;

  @override
  State<EducationPaymentThankYouView> createState() =>
      _EducationPaymentThankYouViewState();
}

class _EducationPaymentThankYouViewState
    extends State<EducationPaymentThankYouView> {
  @override
  void initState() {
    super.initState();
    // Play the existing project success sound exactly once on confirmed success.
    // Reuses PaymentSoundController — same singleton used by PaymentThankYouScreen
    // and PaymentResultScreen. Guard inside controller prevents duplicate play.
    PaymentSoundController.play();
  }

  @override
  void dispose() {
    PaymentSoundController.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _displayApiAmount(
      widget.amount.trim().isNotEmpty ? widget.amount : widget.payableAmount,
    );
    final formattedDate = _formatHeaderDate(widget.transactionTime);
    final imageUrl = widget.bannerImage.trim();
    final title = _thankYouTitle(widget.paymentType);

    // Figma frame width = 441. Single scaling only (no .w/.h/.sp mixing).
    final sx = 1.sw / 441.0;
    double x(double value) => value * sx;

    // Local fallback shown in the ad slot when the API returns no banner image
    // or the remote image fails to load.
    final fallbackBanner = Image.asset(
      FileConstants.thankYouScreenBanner,
      width: x(392),
      height: x(450),
      fit: BoxFit.cover,
    );

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(RouteConstants.home);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            // ---------- Green arc (Ellipse 838 x 756) ----------
            Positioned(
              top: x(-409),
              left: x(-199),
              child: Container(
                width: x(838),
                height: x(756),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(x(838) / 2, x(756) / 2),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF004C1E),
                      Color(0xFF149248),
                      Color(0xFF136E3C),
                      Color(0xFF007340),
                    ],
                    stops: [0.0, 0.3446, 0.9055, 1.0],
                  ),
                ),
              ),
            ),

            // ---------- Header ----------
            Positioned(
              top: x(99),
              left: x(24),
              right: x(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    FileConstants.successIcon,
                    width: x(52),
                    height: x(52),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: x(16)),

                  // Title (two lines with spacing between them)
                  SizedBox(
                    width: x(287),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFFFFFFF),
                        fontWeight: FontWeight.w600,
                        fontSize: x(20),
                        height: 1.3, // gap between the two lines
                      ),
                    ),
                  ),
                  SizedBox(height: x(16)),

                  // Amount badge (glass morphism, min 106x34 / r17 as per Figma)
                  _GlassBadge(
                    text: formattedAmount,
                    x: x,
                  ),
                  SizedBox(height: x(16)),

                  // Date / time
                  Text(
                    formattedDate,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xE6FFFFFF),
                      fontWeight: FontWeight.w400,
                      fontSize: x(10.5),
                      height: 1.2,
                    ),
                  ),
                  // Gap below the date (towards the arc edge)
                  SizedBox(height: x(48)),
                ],
              ),
            ),

            // ---------- Ad banner ----------
            Positioned(
              top: x(376),
              left: x(24),
              child: SizedBox(
                width: x(392),
                height: x(450),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(x(12)),
                      child: SizedBox(
                        width: x(392),
                        height: x(450),
                        child: imageUrl.isEmpty
                            ? fallbackBanner
                            : AppNetworkImage(
                          url: imageUrl,
                          width: x(392),
                          height: x(450),
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(x(12)),
                          errorWidget: fallbackBanner,
                        ),
                      ),
                    ),
                    Positioned(
                      top: x(20),
                      right: 0,
                      child: Container(
                        width: x(43),
                        height: x(28),
                        padding: EdgeInsets.fromLTRB(x(12), x(5), x(12), x(5)),
                        decoration: BoxDecoration(
                          color: const Color(0x4D000000),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(x(50)),
                            bottomLeft: Radius.circular(x(50)),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Ad',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w600,
                            fontSize: x(11),
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------- Done + powered by ----------
            Positioned(
              left: x(24),
              right: x(24),
              bottom: x(32) + bottomInset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomElevatedButton(
                    onPressed: () => context.go(RouteConstants.transactions),
                    label: 'Done',
                    uppercaseLabel: false,
                    showArrow: false,
                  ),
                  SizedBox(height: x(16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'powered by',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.black,
                          fontSize: x(10),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: x(4)),
                      Image.asset(
                        FileConstants.bharatConnectColor,
                        width: x(52),
                        height: x(24),
                        fit: BoxFit.contain,
                      ),
                    ],
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

/// Amount pill with glass morphism (Figma: height 34, radius 17, white @ 10%).
/// Width = content width (min 106 as per Figma), never stretches to parent.
class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.text, required this.x});

  final String text;
  final double Function(double) x;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(x(17));
    return UnconstrainedBox(
      // Stops the parent Column's full width from reaching the badge.
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: x(106)),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: x(8), sigmaY: x(8)),
            child: Container(
              height: x(34),
              padding: EdgeInsets.symmetric(horizontal: x(16)),
              decoration: BoxDecoration(
                borderRadius: radius,
                color: const Color(0x1AFFFFFF), // white @ 10%
              ),
              foregroundDecoration: _GradientBorderDecoration(
                radius: x(17),
                strokeWidth: x(1),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x66FFFFFF),
                    Color(0x0DFFFFFF),
                    Color(0x33FFFFFF),
                  ],
                ),
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFFFFFFF),
                    fontWeight: FontWeight.w800,
                    fontSize: x(14),
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a gradient stroke around a rounded rectangle.
class _GradientBorderDecoration extends Decoration {
  const _GradientBorderDecoration({
    required this.radius,
    required this.strokeWidth,
    required this.gradient,
  });

  final double radius;
  final double strokeWidth;
  final Gradient gradient;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _GradientBorderPainter(
        radius: radius,
        strokeWidth: strokeWidth,
        gradient: gradient,
      );
}

class _GradientBorderPainter extends BoxPainter {
  _GradientBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.gradient,
  });

  final double radius;
  final double strokeWidth;
  final Gradient gradient;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final rect = offset & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(rect);
    canvas.drawRRect(rrect, paint);
  }
}

String _thankYouTitle(String paymentType) {
  final raw = paymentType.trim();
  if (raw.isEmpty) return 'Thank You';
  final lower = raw.toLowerCase();
  if (lower.contains('thank you')) return raw;
  if (lower.endsWith(' payment')) return 'Thank You for\n$raw';
  return 'Thank You for\n$raw Payment';
}

String _displayApiAmount(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.startsWith('₹') ? trimmed : '₹$trimmed';
}

String _formatHeaderDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  final normalized = value.contains(' ') ? value.replaceFirst(' ', 'T') : value;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return value;
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final day = parsed.day.toString();
  final month = months[parsed.month - 1];
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final ampm = parsed.hour >= 12 ? 'pm' : 'am';
  return '$day $month ${parsed.year}, $hour.$minute$ampm';
}