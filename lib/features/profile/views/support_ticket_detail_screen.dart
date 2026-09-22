// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/support_feedback_sheets.dart';
import '../components/support_reply_sheet.dart';
import '../controllers/support_ticket_detail_controller.dart';
import '../models/support_ticket_detail.dart';

class SupportTicketDetailScreen extends HookConsumerWidget {
  const SupportTicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportTicketDetailControllerProvider(ticketId));
    final controller =
        ref.read(supportTicketDetailControllerProvider(ticketId).notifier);

    useEffect(() {
      Future.microtask(controller.fetch);
      return null;
    }, const []);

    final lastError = useRef<String?>(null);
    useEffect(() {
      if (state.errorMessage != null && state.errorMessage != lastError.value) {
        lastError.value = state.errorMessage;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red.shade400,
            ),
          );
        });
      }
      return null;
    }, [state.errorMessage]);

    final ticket = state.ticket;
    final isOpenTicket = ticket != null && _isOpenTicketStatus(ticket.status);
    final isClosedTicket =
        ticket != null && _isClosedTicketStatus(ticket.status);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const MyAppBar(title: 'Tickets'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.fetch,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
                children: [
                  if (state.isLoading && ticket == null)
                    Skeletonizer(
                      enabled: true,
                      child: IgnorePointer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _HeaderRow(
                                ticket: _SupportTicketDetailSkeletons.ticket),
                            SizedBox(height: 12.h),
                            const _MetaGrid(
                                ticket: _SupportTicketDetailSkeletons.ticket),
                            SizedBox(height: 14.h),
                            const _DotDivider(),
                            SizedBox(height: 14.h),
                            const _SectionTitle(title: 'Issue Description'),
                            SizedBox(height: 10.h),
                            const _IssueDescriptionCard(
                              ticket: _SupportTicketDetailSkeletons.ticket,
                            ),
                            SizedBox(height: 14.h),
                            const _AdminReplyCard(
                              message:
                                  _SupportTicketDetailSkeletons.adminMessage,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (ticket == null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 28.h),
                      child: Center(
                        child: Text(
                          'Ticket not found',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.6),
                              ),
                        ),
                      ),
                    )
                  else ...[
                    _HeaderRow(ticket: ticket),
                    SizedBox(height: 12.h),
                    _MetaGrid(ticket: ticket),
                    SizedBox(height: 14.h),
                    const _DotDivider(),
                    SizedBox(height: 14.h),
                    const _SectionTitle(title: 'Issue Description'),
                    SizedBox(height: 10.h),
                    _IssueDescriptionCard(ticket: ticket),
                    SizedBox(height: 14.h),
                    if (ticket.messages.isNotEmpty)
                      for (final message in ticket.messages) ...[
                        if (message.isAdmin)
                          _AdminReplyCard(message: message)
                        else
                          _UserReplyCard(
                            message: message,
                            username: ticket.username,
                          ),
                        SizedBox(height: 12.h),
                      ],
                    if (isClosedTicket) ...[
                      SizedBox(height: 4.h),
                      _SupportExperiencePrompt(
                        onTap: () => _openSupportExperienceSheet(context),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.black.withOpacity(0.06),
              ),
            ),
          ),
          child: Row(
            children: [
              if (isOpenTicket) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleDone(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ] else ...[
                if (isClosedTicket) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isClosing
                          ? null
                          : () => _openReopenSheet(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text('Reopen Ticket'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: ticket == null || !ticket.isReplyButtonEnabled
                          ? null
                          : () => KDialog.instance.openSheet(
                                dialog: SupportReplySheet(ticketId: ticketId),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.lightBorder,
                        disabledForegroundColor:
                            AppColors.textPrimary.withOpacity(0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text('Send Reply'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openReopenSheet(BuildContext context) {
    KDialog.instance.openSheet(
      dialog: _ReopenTicketSheet(
        ticketId: ticketId,
      ),
    );
  }

  void _handleDone(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go(RouteConstants.supportTickets);
  }

  void _openSupportExperienceSheet(BuildContext context) {
    KDialog.instance.openSheet(
      dialog: SupportExperienceSheet(
        onContinue: () {
          KDialog.instance.openSheet(
            dialog: SupportThankYouSheet(
              onContinue: () {},
            ),
          );
        },
      ),
    );
  }
}

bool _isClosedTicketStatus(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized == 'closed' || normalized == 'resolved';
}

bool _isOpenTicketStatus(String status) {
  return status.trim().toLowerCase() == 'open';
}

class _SupportExperiencePrompt extends StatelessWidget {
  const _SupportExperiencePrompt({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rate your support experience.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final face in _supportExperienceFaces) ...[
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Image.asset(
                    face.assetPath,
                    height: 28.w,
                    width: 28.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
            ],
          ],
        ),
      ],
    );
  }
}

class _SupportExperienceFace {
  const _SupportExperienceFace(this.assetPath);

  final String assetPath;
}

final List<_SupportExperienceFace> _supportExperienceFaces = [
  _SupportExperienceFace(FileConstants.worstIcon),
  _SupportExperienceFace(FileConstants.fineIcon),
  _SupportExperienceFace(FileConstants.neutralIcon),
  _SupportExperienceFace(FileConstants.goodIcon),
  _SupportExperienceFace(FileConstants.loveIcon),
];

class _ReopenTicketSheet extends HookConsumerWidget {
  const _ReopenTicketSheet({
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
    final controller =
        ref.read(supportTicketDetailControllerProvider(ticketId).notifier);
    final selectedReason = useState<String?>(null);
    final otherController = useTextEditingController();
    final otherText = useState('');
    final screenshot = useState<File?>(null);
    final isOtherSelected = selectedReason.value == 'Other';
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
    final isSubmitting = ref.watch(
      supportTicketDetailControllerProvider(ticketId).select(
        (state) => state.isClosing,
      ),
    );

    final canSubmit = selectedReason.value != null &&
        (!isOtherSelected || otherText.value.trim().isNotEmpty) &&
        !isSubmitting;

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

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Reopen Ticket',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Icon(Icons.close, size: 18.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            'Reason For Reopening',
            style: sectionTitleStyle,
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
          if (isOtherSelected) ...[
            SizedBox(height: 14.h),
            Text(
              'Other',
              style: sectionTitleStyle,
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: otherController,
              maxLines: 4,
              onChanged: (value) => otherText.value = value,
              style: fieldTextStyle,
              decoration: InputDecoration(
                hintText: 'Describe Your Concern...',
                hintStyle: fieldTextStyle?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.42),
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
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
            ),
          ],
          SizedBox(height: 14.h),
          Text(
            'Attachment',
            style: sectionTitleStyle,
          ),
          SizedBox(height: 8.h),
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
          Text(
            'Please note: File size should be lesser than 20MB',
            style: helperTextStyle,
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: canSubmit
                      ? () async {
                          final reason = isOtherSelected
                              ? otherText.value.trim()
                              : (selectedReason.value ?? '').trim();
                          final ok = await controller.reopenTicketWithReason(
                            reason: reason,
                            screenshot: screenshot.value,
                          );
                          if (!ok || !context.mounted) return;
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.lightBorder,
                    disabledForegroundColor:
                        AppColors.textPrimary.withOpacity(0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    isSubmitting ? 'Please wait...' : 'Reopen Ticket',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.ticket});

  final SupportTicketDetail ticket;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Ticket ID: ${ticket.id}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        _TicketStatusChip(status: ticket.status),
      ],
    );
  }
}

class _SupportTicketDetailSkeletons {
  const _SupportTicketDetailSkeletons._();

  static const ticket = SupportTicketDetail(
    id: '000000',
    transactionId: 'TXN000000',
    service: 'BBPS',
    status: 'Open',
    issueType: 'Recharge',
    description: 'Loading ticket details…',
    createdAt: '2026-01-01 00:00:00',
    username: 'User',
    screenshot: null,
    messages: [],
    isReplyButtonEnabled: true,
  );

  static const adminMessage = SupportTicketMessage(
    senderType: 'admin',
    message: 'Loading reply…',
    createdAt: '2026-01-01 00:00:00',
  );
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.ticket});

  final SupportTicketDetail ticket;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetaItem(
                label: 'Category',
                value: _serviceLabel(ticket.service),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetaItem(
                label: 'Created On',
                value: ticket.createdAt,
                alignRight: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _MetaItem(
                label: 'Topic Of Query',
                value: ticket.issueType,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetaItem(
                label: 'Transaction ID',
                value: ticket.transactionId,
                alignRight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 4.h),
        Text(
          value.isEmpty ? '-' : value,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

class _IssueDescriptionCard extends StatelessWidget {
  const _IssueDescriptionCard({required this.ticket});

  final SupportTicketDetail ticket;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(ticket.username);
    final screenshot = ticket.screenshot?.trim() ?? '';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialAvatar(text: initials),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Issue Description',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      ticket.createdAt,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.55),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(
            color: Colors.black.withOpacity(0.08),
            thickness: 1,
            height: 1,
          ),
          SizedBox(height: 12.h),
          _QuestionText(text: ticket.description),
          if (screenshot.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _ScreenshotAttachment(
              imageUrl: screenshot,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionText extends StatelessWidget {
  const _QuestionText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3.w,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserReplyCard extends StatelessWidget {
  const _UserReplyCard({
    required this.message,
    required this.username,
  });

  final SupportTicketMessage message;
  final String username;

  @override
  Widget build(BuildContext context) {
    final displayName = username.trim().isEmpty ? 'User' : username.trim();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialAvatar(text: _initials(displayName)),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      message.createdAt,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.55),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(
            color: Colors.black.withOpacity(0.08),
            thickness: 1,
            height: 1,
          ),
          SizedBox(height: 12.h),
          _QuestionText(text: message.message),
        ],
      ),
    );
  }
}

class _AdminReplyCard extends StatelessWidget {
  const _AdminReplyCard({required this.message});

  final SupportTicketMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.lightBorder),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team eRupaiya',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                SizedBox(height: 3.h),
                Text(
                  message.createdAt,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.55),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 10.h),
                Text(
                  message.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotAttachment extends StatelessWidget {
  const _ScreenshotAttachment({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final fileName = _fileNameFromUrl(imageUrl);

    return InkWell(
      onTap: () => _openImagePreview(context, imageUrl),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.image_outlined,
              size: 20.sp,
              color: AppColors.textPrimary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            SizedBox(width: 10.w),
            Icon(
              Icons.remove_red_eye_outlined,
              size: 20.sp,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  void _openImagePreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16.w),
          backgroundColor: Colors.black87,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(12.w),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AppNetworkImage(
                      url: url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8.h,
                right: 8.w,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DotDivider extends StatelessWidget {
  const _DotDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DividerDot(size: 5.r),
        Expanded(
          child: Divider(
            color: Colors.black.withOpacity(0.12),
            thickness: 1,
            height: 1,
          ),
        ),
        _DividerDot(size: 5.r),
      ],
    );
  }
}

class _DividerDot extends StatelessWidget {
  const _DividerDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.w,
      height: 34.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

class _TicketStatusChip extends StatelessWidget {
  const _TicketStatusChip({required this.status});

  final String status;

  Color get _color {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'resolved') {
      return const Color(0xFF0E8B3E);
    }
    if (normalized == 'closed') {
      return Colors.red;
    }
    if (normalized == 'in_progress' || normalized == 'in progress') {
      return const Color(0xFF9C6A00);
    }
    return const Color(0xFFB07B00);
  }

  String get _label {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return 'Open';
    if (normalized == 'in_progress') return 'In Progress';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        _label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

String _serviceLabel(String raw) {
  final code = raw.trim().toUpperCase();
  switch (code) {
    case 'BBPS':
      return 'Utility Payments';
    case 'EDUCATION':
      return 'Education Payments';
    case 'METAL':
      return 'Metal Payments';
    default:
      return raw.isEmpty ? 'Service' : raw;
  }
}

String _fileNameFromUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri != null && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.last;
  }
  return raw.trim().isEmpty ? 'Attachment' : raw.trim();
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\\s+')).where((e) => e.isNotEmpty);
  final letters = parts.take(2).map((e) => e[0].toUpperCase()).join();
  return letters.isEmpty ? 'U' : letters;
}
