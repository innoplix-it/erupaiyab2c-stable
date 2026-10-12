import 'package:e_rupaiya/core/barrel_file.dart';

import '../services/referral_share_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// The Figma frame is 440 x 956 while ScreenUtil's design size is 360 x 690.
// Figma pixel values are converted once here and then scaled exactly once by
// ScreenUtil (never both).
double _figmaW(double px) => (px * 360 / 440).w;
double _figmaH(double px) => (px * 690 / 956).h;
double _figmaR(double px) => (px * 360 / 440).r;
double _figmaSp(double px) => (px * 360 / 440).sp;

const Color _kOrange = Color(0xFFE85A2C);
const Color _kSharePink = Color(0xFFF7DCD2);

class ReferralShareActions extends HookWidget {
  const ReferralShareActions({super.key});

  @override
  Widget build(BuildContext context) {
    // Figma: both buttons are 56 high, fully rounded, with a 16 gap.
    final buttonHeight = _figmaH(56);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => ReferralShareService.shareWhatsApp(context),
            child: Container(
              height: buttonHeight,
              decoration: BoxDecoration(
                color: _kOrange,
                borderRadius: BorderRadius.circular(_figmaR(40)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: _figmaW(24),
                    height: _figmaW(24),
                    child: Image.asset(
                      FileConstants.whatsapp,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(width: _figmaW(14)),
                  Flexible(
                    child: Text(
                      'Refer On Whatsapp',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: _figmaSp(16),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: _figmaW(16)),
        GestureDetector(
          onTap: () => ReferralShareService.shareAny(context),
          child: Container(
            height: buttonHeight,
            width: _figmaW(90),
            decoration: BoxDecoration(
              color: _kSharePink,
              borderRadius: BorderRadius.circular(_figmaR(40)),
            ),
            child: Icon(
              Icons.share_outlined,
              color: _kOrange,
              size: _figmaR(24),
            ),
          ),
        ),
      ],
    );
  }
}