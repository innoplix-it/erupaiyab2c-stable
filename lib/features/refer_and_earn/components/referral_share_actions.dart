import 'package:e_rupaiya/core/barrel_file.dart';

import '../services/referral_share_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReferralShareActions extends HookWidget {
  const ReferralShareActions({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonHeight = 40.h;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => ReferralShareService.shareWhatsApp(context),
            child: Container(
              height: buttonHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFE85A2C),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20.w,
                    height: 20.w,
                    child: Image.asset(FileConstants.whatsapp,
                        fit: BoxFit.contain),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Refer On Whatsapp',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        GestureDetector(
          onTap: () => ReferralShareService.shareAny(context),
          child: Container(
            height: buttonHeight,
            width: buttonHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF7DCD2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: const Icon(Icons.share_outlined, color: Color(0xFFB44B2F)),
          ),
        ),
      ],
    );
  }
}
