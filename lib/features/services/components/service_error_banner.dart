import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ServiceErrorBanner extends StatelessWidget {
  const ServiceErrorBanner({
    super.key,
    required this.message,
    this.onClose,
  });

  final String message;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFDB0101),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 16.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
            ),
          ),
          if (onClose != null) ...[
            SizedBox(width: 10.w),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999.r),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
