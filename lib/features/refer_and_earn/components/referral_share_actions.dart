import 'package:e_rupaiya/core/barrel_file.dart';

import '../services/referral_share_service.dart';
import '../components/refer_and_earn_figma_metrics.dart';

const Color _kOrange = Color(0xFFDD5428);
const Color _kSharePink = Color(0xFFF7DCD2);

class ReferralShareActions extends HookWidget {
  const ReferralShareActions({super.key});

  @override
  Widget build(BuildContext context) {
    // Figma: both buttons are 56 high, fully rounded, with a 16 gap.
    final buttonHeight = context.referH(56);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => ReferralShareService.shareWhatsApp(context),
            child: Container(
              height: buttonHeight,
              decoration: BoxDecoration(
                color: _kOrange,
                borderRadius: BorderRadius.circular(context.referR(40)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.referW(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: context.referW(24),
                      height: context.referW(24),
                      child: Image.asset(
                        FileConstants.whatsapp,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: context.referW(10)),
                    Flexible(
                      child: Text(
                        'Invite Using Whatsapp',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: context.referSp(16),
                              letterSpacing: 0,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: context.referW(16)),
        GestureDetector(
          onTap: () => ReferralShareService.shareAny(context),
          child: Container(
            height: buttonHeight,
            width: buttonHeight,
            decoration: BoxDecoration(
              color: _kSharePink,
              borderRadius: BorderRadius.circular(context.referR(40)),
            ),
            child: Icon(
              Icons.share_outlined,
              color: _kOrange,
              size: context.referR(24),
            ),
          ),
        ),
      ],
    );
  }
}

/// The fixed bottom action container shared by the Refer & Earn screens:
/// white bar with the soft upward shadow, safe-area handling and the
/// WhatsApp + share buttons at Figma size. Kept visually identical to the
/// original inline bar on the Refer & Earn home.
///
/// [child] lets a screen reuse the exact same footer container/styling with
/// different actions (e.g. Withdraw E-Coins shows a single full-width
/// button). When omitted the standard WhatsApp + share row is rendered.
class ReferralShareFooter extends StatelessWidget {
  const ReferralShareFooter({super.key, this.child});

  final Widget? child;

  static List<BoxShadow> _shadows(BuildContext context) => [
        BoxShadow(
          color: const Color(0x1ACFCFCF),
          offset: Offset(0, -context.referH(3)),
          blurRadius: context.referR(7),
        ),
        BoxShadow(
          color: const Color(0x17CFCFCF),
          offset: Offset(0, -context.referH(13)),
          blurRadius: context.referR(13),
        ),
        BoxShadow(
          color: const Color(0x0DCFCFCF),
          offset: Offset(0, -context.referH(29)),
          blurRadius: context.referR(17),
        ),
        BoxShadow(
          color: const Color(0x03CFCFCF),
          offset: Offset(0, -context.referH(51)),
          blurRadius: context.referR(21),
        ),
        BoxShadow(
          color: const Color(0x00CFCFCF),
          offset: Offset(0, -context.referH(80)),
          blurRadius: context.referR(22),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: _shadows(context),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // Figma footer: ~20 side inset, 56-tall actions, ~20 vertical pad.
          padding: EdgeInsets.fromLTRB(
            context.referW(20),
            context.referH(20),
            context.referW(20),
            context.referH(20),
          ),
          child: SizedBox(
            height: context.referH(56),
            child: child ?? const ReferralShareActions(),
          ),
        ),
      ),
    );
  }
}