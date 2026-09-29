// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';

class SupportExperienceSheet extends HookWidget {
  const SupportExperienceSheet({
    super.key,
    required this.onContinue,
  });

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final selected = useState<int>(3);
    final feedbackController = useTextEditingController();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'How Was Your Support Experience?',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding: EdgeInsets.all(6.r),
                  child: Icon(Icons.close, size: 20.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Your Feedback Helps Us Improve Faster And\nServe You Better.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              _faces.length,
              (index) => _FaceOption(
                label: _faces[index].label,
                inactiveAsset: _faces[index].inactiveAsset,
                activeAsset: _faces[index].activeAsset,
                selected: selected.value == index,
                onTap: () => selected.value = index,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Feedback',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: feedbackController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Feedback',
              hintStyle: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.45),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            height: 40.h,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
                elevation: 0,
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportThankYouSheet extends StatelessWidget {
  const SupportThankYouSheet({
    super.key,
    required this.onContinue,
  });

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Spacer(),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding: EdgeInsets.all(6.r),
                  child: Icon(Icons.close, size: 20.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            height: 74.w,
            width: 74.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE1D6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFC0AA)),
            ),
            alignment: Alignment.center,
            child: Text(
              '😍',
              style: TextStyle(fontSize: 34.sp),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'Thank You For Your\nFeedback! 🎉',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            'We’re Glad We Could Resolve Your Issue Smoothly.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            height: 40.h,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
                elevation: 0,
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceOption extends StatelessWidget {
  const _FaceOption({
    required this.label,
    required this.inactiveAsset,
    required this.activeAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String inactiveAsset;
  final String? activeAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final assetPath = selected ? (activeAsset ?? inactiveAsset) : inactiveAsset;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 6.h),
        child: Column(
          children: [
            Image.asset(
              assetPath,
              height: 44.w,
              width: 44.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.sp,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Face {
  const _Face({
    required this.label,
    required this.inactiveAsset,
    this.activeAsset,
  });

  final String label;
  final String inactiveAsset;
  final String? activeAsset;
}

final List<_Face> _faces = [
  _Face(
    label: 'Worst',
    inactiveAsset: FileConstants.worstIcon,
    activeAsset: FileConstants.worstGif,
  ),
  _Face(
    label: 'Not Good',
    inactiveAsset: FileConstants.fineIcon,
    activeAsset: FileConstants.notGoodGif,
  ),
  _Face(
    label: 'Neutral',
    inactiveAsset: FileConstants.neutralIcon,
    activeAsset: FileConstants.neutralGif,
  ),
  _Face(
    label: 'Good',
    inactiveAsset: FileConstants.goodIcon,
    activeAsset: FileConstants.goodGif,
  ),
  _Face(
    label: 'Excellent',
    inactiveAsset: FileConstants.loveIcon,
    activeAsset: FileConstants.loveGif,
  ),
];
