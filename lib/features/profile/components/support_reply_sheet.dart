// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/app_colors.dart';
import '../controllers/support_ticket_detail_controller.dart';

class SupportReplySheet extends HookConsumerWidget {
  const SupportReplySheet({
    super.key,
    required this.ticketId,
  });

  final String ticketId;

  static const _reasons = [
    'Issue Still Not Resolved',
    'Refund Not Received',
    'Payment Still Pending',
    'Incorrect Resolution Provided',
    'Need Additional Clarification',
    'Other',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportTicketDetailControllerProvider(ticketId));
    final controller =
        ref.read(supportTicketDetailControllerProvider(ticketId).notifier);

    final messageController = useTextEditingController();
    final screenshot = useState<File?>(null);
    final selectedReason = useState<String?>(null);
    final sectionTitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        );
    final fieldTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        );
    final helperTextStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textPrimary.withOpacity(0.6),
        );

    Future<void> pickScreenshot() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);
      final bytes = await file.length();
      if (bytes > 20 * 1024 * 1024) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('File size must be less than 20MB'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        return;
      }
      screenshot.value = file;
    }

    Future<void> sendReply() async {
      final reason = selectedReason.value?.trim() ?? '';
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a reason'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        return;
      }
      final message = messageController.text.trim();
      if (message.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter your message'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        return;
      }
      final ok = await controller.reply(
        reason: reason,
        message: message,
        screenshot: screenshot.value,
      );
      if (!ok || !context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply sent successfully'),
          backgroundColor: AppColors.green,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Send A Reply',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
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
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reason For Reply',
              style: sectionTitleStyle,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            value: selectedReason.value,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Select',
              hintStyle: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.45),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
            ),
            items: _reasons
                .map(
                  (reason) => DropdownMenuItem<String>(
                    value: reason,
                    child: Text(
                      reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fieldTextStyle,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => selectedReason.value = value,
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Your Reply',
              style: sectionTitleStyle,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: messageController,
            maxLines: 5,
            style: fieldTextStyle,
            decoration: InputDecoration(
              hintText: 'Message',
              hintStyle: fieldTextStyle?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.45),
                fontWeight: FontWeight.w500,
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
          SizedBox(height: 12.h),
          InkWell(
            onTap: pickScreenshot,
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file_outlined),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      screenshot.value == null
                          ? 'Upload Screenshot (Optional)'
                          : (screenshot.value!.uri.pathSegments.isEmpty
                              ? 'Screenshot selected'
                              : screenshot.value!.uri.pathSegments.last),
                      style: fieldTextStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_upward,
                    color: AppColors.textPrimary.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Please note: File size should be lesser than 20MB',
              style: helperTextStyle,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: state.isReplying ? null : sendReply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
                elevation: 0,
              ),
              child: state.isReplying
                  ? SizedBox(height: 22.r,
                      width: 22.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send Reply'),
            ),
          ),
        ],
      ),
    );
  }
}
