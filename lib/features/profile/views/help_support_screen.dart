// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/policy_banner_card.dart';
import '../components/policy_section_title.dart';
import '../components/support_transaction_card.dart';
import '../controllers/help_support_controller.dart';
import '../models/help_topic.dart';
import '../models/support_latest_transaction.dart';
import 'recent_payment_help_screen.dart';

class HelpSupportScreen extends HookConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(helpSupportControllerProvider);
    final controller = ref.read(helpSupportControllerProvider.notifier);

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

    final videoTopics =
        state.helpTopics.where((t) => t.videoKey != null).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const MyAppBar(title: 'Help & Support'),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.fetch,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(0.w, 4.h, 0.w, 0.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12.h),
                                _TicketsCard(
                                  onTap: () => context
                                      .push(RouteConstants.supportTickets),
                                ),
                                SizedBox(height: 18.h),
                                Text(
                                  'Latest Transactions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                SizedBox(height: 12.h),
                                SizedBox(height: 90.h,
                                  child: state.isLoading &&
                                          state.latestTransactions.isEmpty
                                      ? Skeletonizer(
                                          enabled: true,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: 3,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(width: 12.w),
                                            itemBuilder: (_, __) =>
                                                const SupportTransactionCard(
                                              transaction:
                                                  _HelpSupportSkeletons.tx,
                                            ),
                                          ),
                                        )
                                      : state.latestTransactions.isEmpty
                                          ? Center(
                                              child: Text(
                                                'No recent transactions',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppColors
                                                          .textPrimary
                                                          .withOpacity(0.6),
                                                    ),
                                              ),
                                            )
                                          : ListView.separated(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: state
                                                  .latestTransactions.length,
                                              separatorBuilder: (_, __) =>
                                                  SizedBox(width: 12.w),
                                              itemBuilder: (_, index) =>
                                                  SupportTransactionCard(
                                                transaction: state
                                                    .latestTransactions[index],
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          RecentPaymentHelpScreen(
                                                        transaction: state
                                                                .latestTransactions[
                                                            index],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                ),
                                SizedBox(height: 20.h),
                                PolicyBannerCard(
                                  imageAsset: FileConstants.homeBanner12,
                                ),
                                SizedBox(height: 16.h),
                                const PolicySectionTitle(text: 'Help Topics'),
                                SizedBox(height: 10.h),
                                if (state.isLoading && state.helpTopics.isEmpty)
                                  Skeletonizer(
                                    enabled: true,
                                    child: IgnorePointer(
                                      child: Column(
                                        children: List.generate(
                                          6,
                                          (index) => _HelpTopicTile(
                                            title: 'Loading help topic',
                                            onTap: () {},
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else if (state.helpTopics.isEmpty)
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16.h),
                                    child: Center(
                                      child: Text(
                                        'No help topics available',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textPrimary
                                                  .withOpacity(0.6),
                                            ),
                                      ),
                                    ),
                                  )
                                else
                                  ...state.helpTopics.map(
                                    (topic) => _HelpTopicTile(
                                      title: topic.title,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => HelpTopicDetailView(
                                              topic: topic,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                if (videoTopics.isNotEmpty) ...[
                                  SizedBox(height: 18.h),
                                  const PolicySectionTitle(
                                    text: 'Recommended Videos',
                                  ),
                                  SizedBox(height: 10.h),
                                  SizedBox(height: 108.h,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: videoTopics.length,
                                      separatorBuilder: (_, __) =>
                                          SizedBox(width: 10.w),
                                      itemBuilder: (_, index) =>
                                          _VideoTopicCard(
                                        topic: videoTopics[index],
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(height: 20.h),
                              ],
                            ),
                          ),
                          _ContactHelpCard(
                            onTap: () =>
                                context.push(RouteConstants.helpCenterChat),
                          ),
                        ],
                      ),
                    ),
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

class _HelpTopicTile extends StatelessWidget {
  const _HelpTopicTile({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textPrimary.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSupportSkeletons {
  const _HelpSupportSkeletons._();

  static const tx = SupportLatestTransaction(
    id: '0',
    paymentType: 'Recharge',
    billerName: 'Biller',
    amount: '0',
    status: 'Pending',
    date: '2026-01-01 00:00:00',
    type: 'BBPS',
    transactionId: '',
  );
}

class _TicketsCard extends StatelessWidget {
  const _TicketsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFF0B7D3B),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              color: Colors.white,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Tickets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const Icon(Icons.arrow_outward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _VideoTopicCard extends StatelessWidget {
  const _VideoTopicCard({required this.topic});

  final HelpTopic topic;

  String? get _thumbnailUrl {
    final key = topic.videoKey;
    if (key == null) return null;
    return 'https://img.youtube.com/vi/$key/hqdefault.jpg';
  }

  Future<void> _open() async {
    final raw = topic.video?.trim();
    final key = topic.videoKey;
    final resolved = raw != null && raw.isNotEmpty
        ? Uri.tryParse(raw)
        : (key != null
            ? Uri.parse('https://www.youtube.com/watch?v=$key')
            : null);
    if (resolved == null) return;
    await launchUrl(resolved, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _thumbnailUrl;
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 220.w,
        height: 108.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.lightBorder),
          color: const Color(0xFFF4F4F4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFFEFEFEF)),
                  errorWidget: (_, __, ___) =>
                      Container(color: const Color(0xFFEFEFEF)),
                )
              else
                Container(color: const Color(0xFFEFEFEF)),
              Container(
                alignment: Alignment.center,
                child: Container(
                  height: 36.h,
                  width: 36.h,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEA5A30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
              Positioned(
                left: 10.w,
                right: 10.w,
                bottom: 8.h,
                child: Text(
                  topic.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        blurRadius: 10.r,
                        color: Colors.black54,
                        offset: Offset(0.w, 2.h),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactHelpCard extends StatelessWidget {
  const _ContactHelpCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        gradient: const LinearGradient(
          colors: [Color(0xFFF28C5C), Color(0xFF8C3B1D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Quick Contact',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 18.h),
          const _ContactRow(
            icon: Icons.email_outlined,
            text: 'support@erupaiya.com',
          ),
          SizedBox(height: 10.h),
          const _ContactRow(
            icon: Icons.call_outlined,
            text: '+917350735046',
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              const _DividerDot(),
              Expanded(
                child: Divider(
                  color: Colors.white.withOpacity(0.2),
                  thickness: 1,
                ),
              ),
              const _DividerDot(),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Need Help? We\u2019ve Got You',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            'We Are Here To Help You!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          //TO:DO: Implement chat support and uncomment below code
          // SizedBox(height: 12.h),
          // SizedBox(
          //   height: 36.h,
          //   child: OutlinedButton(
          //     onPressed: onTap,
          //     style: OutlinedButton.styleFrom(
          //       backgroundColor: Colors.white.withOpacity(0.15),
          //       side: BorderSide(color: Colors.white.withOpacity(0.6)),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(20.r),
          //       ),
          //     ),
          //     child: Text(
          //       'Chat With Us',
          //       style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //             color: Colors.white,
          //             fontWeight: FontWeight.w700,
          //           ),
          //     ),
          //   ),
          // ),
          // SizedBox(height: 12.h),
          // SizedBox(
          //   height: 36.h,
          //   child: OutlinedButton(
          //     onPressed: onTap,
          //     style: OutlinedButton.styleFrom(
          //       backgroundColor: Colors.white.withOpacity(0.15),
          //       side: BorderSide(color: Colors.white.withOpacity(0.6)),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(20.r),
          //       ),
          //     ),
          //     child: Text(
          //       'Chat With Us',
          //       style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //             color: Colors.white,
          //             fontWeight: FontWeight.w700,
          //           ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 18.r),
        SizedBox(width: 10.w),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _DividerDot extends StatelessWidget {
  const _DividerDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      width: 6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        shape: BoxShape.circle,
      ),
    );
  }
}

class HelpTopicDetailView extends HookWidget {
  const HelpTopicDetailView({
    super.key,
    required this.topic,
  });

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    final selectedReaction = useState<_HelpfulnessReaction?>(null);

    Future<void> openVideo() async {
      final raw = topic.video?.trim();
      final key = topic.videoKey;
      final resolved = raw != null && raw.isNotEmpty
          ? Uri.tryParse(raw)
          : (key != null
              ? Uri.parse('https://www.youtube.com/watch?v=$key')
              : null);
      if (resolved == null) return;
      await launchUrl(resolved, mode: LaunchMode.externalApplication);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MyAppBar(
        title: 'Help & Support',
        showHelp: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 14.h),
            if (topic.imageUrl != null && topic.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: AspectRatio(
                  aspectRatio: 343 / 150,
                  child: CachedNetworkImage(
                    imageUrl: topic.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: const Color(0xFFF0F0F0)),
                    errorWidget: (_, __, ___) =>
                        Container(color: const Color(0xFFF0F0F0)),
                  ),
                ),
              )
            else if (topic.videoKey != null)
              InkWell(
                onTap: openVideo,
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  height: 150.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE1D6),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFE7B6A8)),
                  ),
                  child: Center(
                    child: Container(
                      height: 36.h,
                      width: 36.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA5A30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 12.h),
            Text(
              topic.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.75),
                    height: 1.5,
                  ),
            ),
            SizedBox(height: 18.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  Text(
                    'Was this information helpful ?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ReactionButton(
                        icon: Icons.thumb_up_alt_outlined,
                        isSelected:
                            selectedReaction.value == _HelpfulnessReaction.up,
                        onTap: () {
                          selectedReaction.value = _HelpfulnessReaction.up;
                        },
                      ),
                      SizedBox(width: 16.w),
                      _ReactionButton(
                        icon: Icons.thumb_down_alt_outlined,
                        isSelected:
                            selectedReaction.value == _HelpfulnessReaction.down,
                        onTap: () {
                          selectedReaction.value = _HelpfulnessReaction.down;
                          KDialog.instance.openSheet(
                            dialog: const _FeedbackSheet(),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _HelpfulnessReaction { up, down }

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        height: 38.h,
        width: 38.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 18.r,
          color: isSelected
              ? AppColors.primary
              : AppColors.textPrimary.withOpacity(0.7),
        ),
      ),
    );
  }
}

class _FeedbackSheet extends HookWidget {
  const _FeedbackSheet();

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'What Didn\'t Work For You?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Feedback',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: controller,
            minLines: 4,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: 'Feedback',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2A98E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
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
