import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/payment_success_flow.dart';
import '../education_fees_typography.dart';

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
  // Figma frame base width.
  static const double _figmaWidth = 441;
  // Banner aspect (392 x 450).
  static const double _bannerAspect = 392 / 450;

  @override
  void initState() {
    super.initState();
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

    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final topInset = mq.padding.top;
    final bottomInset = mq.padding.bottom;

    // Single scale factor: everything (arc, gaps, fonts, banner) scales
    // from the Figma 441 wide frame, so proportions never distort.
    final s = screenWidth / _figmaWidth;

    final bannerPng = Image.asset(
      FileConstants.educationThankYouBannerPng,
      fit: BoxFit.cover,
    );

    return EducationFeesTheme(
      child: MediaQuery(
      // Keep header safe against huge accessibility font sizes.
      data: mq.copyWith(
        textScaler: mq.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.15,
        ),
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go(RouteConstants.home);
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ---------- Green arc: Figma Ellipse 30 ----------
              // W 838, H 756, Top -409, Left -199 (on 441 frame).
              Positioned(
                top: -409 * s,
                left: -199 * s,
                child: ClipOval(
                  child: Container(
                    width: 838 * s,
                    height: 756 * s,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
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
              ),

              // ---------- Content ----------
              Positioned.fill(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: fixed height = Figma banner top (377).
                    // Arc bottom is at 347, so date -> arc -> banner gaps
                    // match the design on every device.
                    SizedBox(
                      height: 377 * s,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: topInset + 50 * s,
                          left: 24 * s,
                          right: 24 * s,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              FileConstants.successIcon,
                              width: 46 * s,
                              height: 46 * s,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: 14 * s),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18 * s,
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 14 * s),
                            _GlassBadge(text: formattedAmount, s: s),
                            SizedBox(height: 14 * s),
                            Text(
                              formattedDate,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xE6FFFFFF),
                                fontWeight: FontWeight.w400,
                                fontSize: 10 * s,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Banner region: takes remaining height, keeps aspect,
                    // max width = Figma 392 (scaled). Shrinks on short
                    // screens, never overflows.
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.5 * s),
                        child: LayoutBuilder(
                          builder: (context, c) {
                            double w = c.maxWidth;
                            double h = w / _bannerAspect;
                            if (h > c.maxHeight) {
                              h = c.maxHeight;
                              w = h * _bannerAspect;
                            }
                            return Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: w,
                                height: h,
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(10 * s),
                                        child: imageUrl.isEmpty
                                            ? bannerPng
                                            : AppNetworkImage(
                                          url: imageUrl,
                                          fit: BoxFit.cover,
                                          borderRadius:
                                          BorderRadius.circular(
                                              10 * s),
                                          errorWidget: bannerPng,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10 * s,
                                      right: 0,
                                      child: SvgPicture.string(
                                        FileConstants.adBadgeSvg,
                                        width: 48 * s,
                                        height: 33 * s,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Bottom: Done + powered by.
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24 * s,
                        14 * s,
                        24 * s,
                        bottomInset + 20 * s,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomElevatedButton(
                            onPressed: () =>
                                context.go(RouteConstants.transactions),
                            label: 'Done',
                            uppercaseLabel: false,
                            showArrow: false,
                          ),
                          SizedBox(height: 10 * s),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'powered by',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.black,
                                  fontSize: 9 * s,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 3 * s),
                              Image.asset(
                                FileConstants.bharatConnectColor,
                                width: 46 * s,
                                height: 22 * s,
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
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Amount pill with glass morphism (white @ 10%, gradient stroke).
class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.text, required this.s});

  final String text;
  final double s;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14 * s);
    return UnconstrainedBox(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 90 * s),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.5, sigmaY: 6.5),
            child: Container(
              height: 30 * s,
              padding: EdgeInsets.symmetric(horizontal: 14 * s),
              decoration: BoxDecoration(
                borderRadius: radius,
                color: const Color(0x1AFFFFFF),
              ),
              foregroundDecoration: _GradientBorderDecoration(
                radius: 14 * s,
                strokeWidth: 1,
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
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12 * s,
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
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final day = parsed.day.toString();
  final month = months[parsed.month - 1];
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final ampm = parsed.hour >= 12 ? 'pm' : 'am';
  return '$day $month ${parsed.year}, $hour.$minute$ampm';
}