import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'credit_card/credit_card_figma_metrics.dart';

class ServiceErrorBanner extends StatelessWidget {
  const ServiceErrorBanner({
    super.key,
    required this.message,
    this.onClose,
    this.useCreditCardFigma = false,
  });

  final String message;
  final VoidCallback? onClose;

  /// Figma 440 credit-card error strip (no ScreenUtil double-scale).
  final bool useCreditCardFigma;

  @override
  Widget build(BuildContext context) {
    final hPad = useCreditCardFigma
        ? CreditCardFigmaMetrics.s(context, 16)
        : 12.w;
    final vPad = useCreditCardFigma
        ? CreditCardFigmaMetrics.s(context, 12)
        : 10.h;
    final gap = useCreditCardFigma
        ? CreditCardFigmaMetrics.s(context, 10)
        : 10.w;
    final iconSize = useCreditCardFigma
        ? CreditCardFigmaMetrics.s(context, 16)
        : 16.sp;
    final radius = useCreditCardFigma
        ? CreditCardFigmaMetrics.s(context, 12)
        : 12.r;
    final fontSize = useCreditCardFigma
        ? CreditCardFigmaMetrics.s(context, 12)
        : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: const Color(0xFFDB0101),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!useCreditCardFigma)
            Icon(
              Icons.info_outline,
              color: Colors.white,
              size: iconSize,
            ),
          if (!useCreditCardFigma) SizedBox(width: gap),
          Expanded(
            child: Text(
              message.trim(),
              maxLines: useCreditCardFigma ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: useCreditCardFigma
                  ? GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: fontSize,
                      height: 1.35,
                    )
                  : Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
            ),
          ),
          if (onClose != null) ...[
            SizedBox(width: gap),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: EdgeInsets.all(
                  useCreditCardFigma
                      ? CreditCardFigmaMetrics.s(context, 4)
                      : 4.w,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
