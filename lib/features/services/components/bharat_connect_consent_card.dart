import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';
import 'fetch_provider_metrics.dart';

class BharatConnectConsentCard extends StatelessWidget {
  const BharatConnectConsentCard({super.key});

  static const message =
      'By Proceeding Further, You Allow Erupaiya To Fetch Your Current And '
      'Future Balances And Remind You';

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final inset = FetchProviderMetrics.w(16);
    final logoWidth = FetchProviderMetrics.w(48);
    final fontSize = FetchProviderMetrics.font(12, min: 10);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxCardWidth = constraints.maxWidth;
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: maxCardWidth,
            constraints:
                BoxConstraints(minHeight: FetchProviderMetrics.h(64)),
            padding: EdgeInsets.all(inset),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius:
                  BorderRadius.circular(FetchProviderMetrics.r(16)),
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
