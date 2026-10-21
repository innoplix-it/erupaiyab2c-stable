import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';
import 'credit_card/credit_card_figma_metrics.dart';
import 'fetch_provider_metrics.dart';

class BharatConnectConsentCard extends StatelessWidget {
  const BharatConnectConsentCard({super.key, this.useCreditCardFigma = false});

  /// Credit Card bill screens use [CreditCardFigmaMetrics] (440 frame, no
  /// ScreenUtil double-scale).
  final bool useCreditCardFigma;

  static const message =
      'By Proceeding Further, You Allow Erupaiya To Fetch Your Current And '
      'Future Balances And Remind You';

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final inset = useCreditCardFigma
        ? CreditCardFigmaMetrics.s(context, 16)
        : FetchProviderMetrics.w(16);
    final logoWidth = useCreditCardFigma
        ? CreditCardFigmaMetrics.s(context, 48)
        : FetchProviderMetrics.w(48);
    final fontSize = useCreditCardFigma
        ? CreditCardFigmaMetrics.s(context, 12).clamp(10.0, 12.0)
        : FetchProviderMetrics.font(12, min: 10);
    final minHeight = useCreditCardFigma
        ? CreditCardFigmaMetrics.s(context, 64)
        : FetchProviderMetrics.h(64);
    final radius = useCreditCardFigma
        ? CreditCardFigmaMetrics.s(context, 16)
        : FetchProviderMetrics.r(16);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxCardWidth = constraints.maxWidth;
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: maxCardWidth,
            constraints: BoxConstraints(minHeight: minHeight),
            padding: EdgeInsets.all(inset),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  FileConstants.bharatConnectColor,
                  width: narrow ? logoWidth * 0.92 : logoWidth,
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
        );
      },
    );
  }
}
