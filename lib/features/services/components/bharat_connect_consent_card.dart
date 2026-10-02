import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';
import 'fetch_provider_metrics.dart';

/// Bharat Connect consent card from the Electricity Pay Now Figma frame
/// (440px wide, card 392 x 64 with 24px side margins).
class BharatConnectConsentCard extends StatelessWidget {
  const BharatConnectConsentCard({super.key});

  static const message =
      'By Proceeding Further, You Allow Erupaiya To Fetch Your Current And '
      'Future Balances And Remind You';

  static const _figmaFrameWidth = 440.0;
  static const _figmaSideMargin = 24.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    double x(double figmaPx) => figmaPx * screenWidth / _figmaFrameWidth;

    final cardWidth = screenWidth - 2 * x(_figmaSideMargin);
    final inset = x(16);
    final fontSize = FetchProviderMetrics.font(12, min: 10);

    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: Container(
          width: math.min(cardWidth, constraints.maxWidth),
          constraints: BoxConstraints(minHeight: FetchProviderMetrics.h(64)),
          padding: EdgeInsets.all(inset),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(FetchProviderMetrics.r(16)),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                FileConstants.bharatConnectColor,
                width: x(48),
                fit: BoxFit.contain,
              ),
              SizedBox(width: inset),
              Expanded(
                child: Text(
                  message,
                  softWrap: true,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w400,
                    fontSize: fontSize,
                    height: 16 / 12,
                    letterSpacing: 0,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
