// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
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

    final topics = state.helpTopics
        .where((topic) => topic.title.trim().toLowerCase() != 'test')
        .toList();
    final videoTopics = state.helpTopics.where((topic) {
      final video = topic.video?.trim();
      return video != null && video.isNotEmpty;
    }).toList();
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width * 0.041;
    final gap = width * 0.035;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: 'Help & Support',
            titleStyle: MyAppBar.sharedTitleStyle(context),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.fetch,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: gap),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _TicketsCard(
                        onTap: () =>
                            context.push(RouteConstants.supportTickets),
                      ),
                    ),
                    SizedBox(height: gap * 1.15),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _SectionTitle(
                        text: 'Bill Details',
                        fontSize: width * 0.044 - 2,
                      ),
                    ),
                    SizedBox(height: gap * 0.7),
                    _BillDetailsCarousel(
                      state: state,
                      onTransaction: (transaction) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecentPaymentHelpScreen(
                              transaction: transaction,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: gap),
                    const _EndpointDivider(),
                    SizedBox(height: gap),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            text: 'Help Topics',
                            fontSize: width * 0.044 - 2,
                          ),
                          SizedBox(height: gap * 0.45),
                          if (state.isLoading && topics.isEmpty)
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
                          else if (topics.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: gap),
                              child: Center(
                                child: Text(
                                  'No help topics available',
                                  style: _pj(
                                    width * 0.034,
                                    color:
                                        AppColors.textPrimary.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...topics.map(
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
                        ],
                      ),
                    ),
                    if (topics.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _SectionTitle(
                          text: 'Recommended Videos',
                          fontSize: 16 * (width / 418),
                          weight: FontWeight.w700,
                          height: 26 / 16,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: width * (12 / 418)),
                      _VideoCarousel(
                        topics: videoTopics.isNotEmpty ? videoTopics : topics,
                        onTopic: (topic) {
                          final video = topic.video?.trim();
                          if (video != null && video.isNotEmpty) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HelpTopicDetailView(topic: topic),
                            ),
                          );
                        },
                      ),
                    ],
                    SizedBox(height: width * (16 / 418)),
                    const _ContactHelpCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _pj(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = Colors.black,
  double height = 1.35,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.text,
    required this.fontSize,
    this.weight = FontWeight.w700,
    this.height = 1.2,
    this.letterSpacing = 0,
  });

  final String text;
  final double fontSize;
  final FontWeight weight;
  final double height;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: Colors.black,
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
    final width = MediaQuery.sizeOf(context).width;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: width * (14 / 418)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: _pj(
                  width * (15 / 418),
                  weight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(width: width * (8 / 418)),
            Icon(
              Icons.chevron_right,
              color: Colors.black,
              size: width * (18 / 418),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillDetailsCarousel extends StatelessWidget {
  const _BillDetailsCarousel({
    required this.state,
    required this.onTransaction,
  });

  final HelpSupportState state;
  final ValueChanged<SupportLatestTransaction> onTransaction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.maxWidth;
        final scale = viewport / 418;
        final hPad = viewport * 0.041;
        final gap = 10 * scale;
        final cardWidth = 269 * scale;

        if (state.isLoading && state.latestTransactions.isEmpty) {
          return Skeletonizer(
            enabled: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    SupportTransactionCard(
                      transaction: _HelpSupportSkeletons.tx,
                      helpLayout: true,
                      width: cardWidth,
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        if (state.latestTransactions.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: gap),
            child: Text(
              'No recent transactions',
              style: _pj(
                viewport * 0.034,
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0;
                  index < state.latestTransactions.length;
                  index++) ...[
                if (index > 0) SizedBox(width: gap),
                SupportTransactionCard(
                  transaction: state.latestTransactions[index],
                  helpLayout: true,
                  width: cardWidth,
                  onTap: () => onTransaction(state.latestTransactions[index]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VideoCarousel extends StatelessWidget {
  const _VideoCarousel({
    required this.topics,
    required this.onTopic,
  });

  final List<HelpTopic> topics;
  final ValueChanged<HelpTopic> onTopic;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.maxWidth;
        final scale = viewport / 418;
        final hPad = viewport * 0.041;
        final gap = 12 * scale;
        final cardWidth = 190 * scale;
        final cardHeight = 90 * scale;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < topics.length; index++) ...[
                if (index > 0) SizedBox(width: gap),
                _VideoTopicCard(
                  topic: topics[index],
                  width: cardWidth,
                  height: cardHeight,
                  onOpen: () => onTopic(topics[index]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EndpointDivider extends StatelessWidget {
  const _EndpointDivider();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final lineWidth = width * (397 / 418);
    final height = width * (6 / 418);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Center(
        child: CustomPaint(
          size: Size(lineWidth, height),
          painter: const _CapLinePainter(),
        ),
      ),
    );
  }
}

class _CapLinePainter extends CustomPainter {
  const _CapLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE9E9E9)
      ..style = PaintingStyle.fill;
    final radius = size.height * (2.667 / 6);
    final cy = size.height / 2;
    final thickness = size.height * (1 / 6);
    canvas.drawCircle(Offset(radius, cy), radius, paint);
    canvas.drawCircle(Offset(size.width - radius, cy), radius, paint);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, cy),
        width: size.width - (radius * 2),
        height: thickness,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bar = constraints.maxWidth;
        final height = bar * (56 / 392);
        final radius = bar * (8 / 392);
        return Material(
          color: const Color(0xFF058337),
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: bar * (16 / 392)),
                child: Row(
                  children: [
                    SvgPicture.string(
                      _ticketIconSvg,
                      width: bar * (17 / 392),
                      height: bar * (14 / 392),
                    ),
                    SizedBox(width: bar * (14 / 392)),
                    Expanded(
                      child: Text(
                        'Tickets',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _pj(
                          bar * (14 / 392),
                          weight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                    SvgPicture.string(
                      _ticketArrowSvg,
                      width: bar * (16 / 392),
                      height: bar * (16 / 392),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VideoTopicCard extends StatelessWidget {
  const _VideoTopicCard({
    required this.topic,
    required this.width,
    required this.height,
    required this.onOpen,
  });

  final HelpTopic topic;
  final double width;
  final double height;
  final VoidCallback onOpen;

  Future<void> _open() async {
    final raw = topic.video?.trim();
    final key = topic.videoKey;
    final resolved = raw != null && raw.isNotEmpty
        ? Uri.tryParse(raw)
        : (key != null
            ? Uri.parse('https://www.youtube.com/watch?v=$key')
            : null);
    if (resolved == null) {
      onOpen();
      return;
    }
    await launchUrl(resolved, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 418;
    final radius = 16 * scale;
    final play = 27 * scale;
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: const Color(0xFFDD5428),
            width: 0.5,
          ),
          color: const Color(0xFFFFE0D7),
        ),
        child: SvgPicture.string(
          _videoPlaySvg,
          key: const Key('recommended-video-play'),
          width: play,
          height: play,
        ),
      ),
    );
  }
}

class _ContactHelpCard extends StatelessWidget {
  const _ContactHelpCard();

  static const supportEmail = 'support@erupaiya.com';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    double u(double framePx) => width * (framePx / 440);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        u(24),
        u(36),
        u(24),
        u(32) + bottomInset,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(u(28))),
        gradient: const LinearGradient(
          begin: Alignment(0, -1.2072),
          end: Alignment(0, 1.0806),
          colors: [Color(0xFFFF8F6B), Color(0xFF823218)],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Quick Contact',
            textAlign: TextAlign.center,
            style: _pj(
              u(20),
              weight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          SizedBox(height: u(18)),
          const _ContactRow(
            icon: Icons.email_outlined,
            text: supportEmail,
          ),
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
    final width = MediaQuery.sizeOf(context).width;
    double u(double framePx) => width * (framePx / 440);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: u(16)),
        SizedBox(width: u(8)),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _pj(
              u(14),
              weight: FontWeight.w500,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class HelpTopicDetailView extends HookWidget {
  const HelpTopicDetailView({
    super.key,
    required this.topic,
  });

  final HelpTopic topic;

  static const _frameW = 464.0;

  @override
  Widget build(BuildContext context) {
    final selectedReaction = useState<_HelpfulnessReaction?>(null);
    final screen = MediaQuery.sizeOf(context);
    final width = screen.width;
    double u(double px) => width * (px / _frameW);
    final hPad = u(26);
    final cardWidth = width - (hPad * 2);
    final videoHeight = cardWidth * (152 / 410);
    final radius = cardWidth * (16 / 410);
    final playSize = cardWidth * (46 / 410);
    final helpfulFont = u(16) - 2;

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

    final imageUrl = topic.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasVideo =
        (topic.video?.trim().isNotEmpty ?? false) || topic.videoKey != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: '',
            titleStyle: MyAppBar.sharedTitleStyle(context),
            showHelp: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                hPad,
                screen.height * (16 / 1024),
                hPad,
                screen.height * (24 / 1024),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: _pj(
                      u(18),
                      weight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: screen.height * (24 / 1024)),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('help-topic-video-preview'),
                      onTap: hasVideo ? openVideo : null,
                      borderRadius: BorderRadius.circular(radius),
                      child: Ink(
                        height: videoHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0D7),
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: const Color(0xFFDD5428),
                            width: 0.5,
                          ),
                          image: hasImage
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Container(
                            height: playSize,
                            width: playSize,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDD5428),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: playSize * 0.62,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screen.height * (24 / 1024)),
                  Text(
                    topic.description,
                    style: _pj(
                      u(14),
                      weight: FontWeight.w500,
                      color: const Color(0xFF2B2B2B),
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: screen.height * (40 / 1024)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: u(16),
                      vertical: screen.height * (28 / 1024),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.circular(u(16)),
                      border: Border.all(color: const Color(0xFFE4E4E4)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Was This Information Helpful ?',
                          textAlign: TextAlign.center,
                          style: _pj(
                            helpfulFont,
                            weight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: screen.height * (18 / 1024)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ReactionButton(
                              buttonKey: const Key('help-topic-thumb-up'),
                              icon: Icons.thumb_up,
                              diameter: u(42),
                              isSelected: selectedReaction.value ==
                                  _HelpfulnessReaction.up,
                              onTap: () {
                                selectedReaction.value =
                                    _HelpfulnessReaction.up;
                              },
                            ),
                            SizedBox(width: u(18)),
                            _ReactionButton(
                              buttonKey: const Key('help-topic-thumb-down'),
                              icon: Icons.thumb_down,
                              diameter: u(42),
                              isSelected: selectedReaction.value ==
                                  _HelpfulnessReaction.down,
                              onTap: () {
                                if (selectedReaction.value ==
                                    _HelpfulnessReaction.down) {
                                  return;
                                }
                                selectedReaction.value =
                                    _HelpfulnessReaction.down;
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
          ),
        ],
      ),
    );
  }
}

enum _HelpfulnessReaction { up, down }

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.buttonKey,
    required this.icon,
    required this.diameter,
    required this.isSelected,
    required this.onTap,
  });

  final Key buttonKey;
  final IconData icon;
  final double diameter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: diameter,
        width: diameter,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE4E4E4),
          ),
        ),
        child: Icon(
          icon,
          size: diameter * 0.46,
          color: const Color(0xFFFBD767),
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
    useListenable(controller);
    final screen = MediaQuery.sizeOf(context);
    final width = screen.width;
    final height = screen.height;
    double u(double px) => width * (px / 470);
    double v(double px) => height * (px / 1024);
    final count = controller.text.length;
    final typed = controller.text.trim().isNotEmpty;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final homeInset = MediaQuery.viewPaddingOf(context).bottom;
    final figmaSheet = height * (422 / 1024);
    final maxSheet = height - keyboard - homeInset;
    final wanted = figmaSheet - homeInset;
    final sheetHeight = (wanted < maxSheet ? wanted : maxSheet).clamp(
      0.0,
      maxSheet,
    );

    return SizedBox(
      height: sheetHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          u(24),
          v(18),
          u(24),
          v(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'What Didn\'t Work For You?',
                    style: _pj(
                      u(16),
                      weight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                ),
                GestureDetector(
                  key: const Key('feedback-close'),
                  onTap: () => Navigator.of(context).pop(),
                  child: SvgPicture.string(
                    _feedbackCloseSvg,
                    width: u(32),
                    height: u(32),
                  ),
                ),
              ],
            ),
            SizedBox(height: v(14)),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xB2DFDFDF),
            ),
            SizedBox(height: v(16)),
            Text(
              'Feedback',
              style: _pj(
                u(14),
                weight: FontWeight.w500,
                color: const Color(0xFF000000),
                height: 1,
              ),
            ),
            SizedBox(height: v(14)),
            Expanded(
              child: TextField(
                controller: controller,
                expands: true,
                minLines: null,
                maxLines: null,
                maxLength: 400,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                style: _pj(
                  u(14),
                  weight: FontWeight.w500,
                  color: const Color(0xFF7C7C7C),
                  height: 1.3,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Feedback',
                  hintStyle: _pj(
                    u(14),
                    weight: FontWeight.w500,
                    color: const Color(0xFF7C7C7C),
                    height: 1,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(u(12)),
                    borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(u(12)),
                    borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(u(12)),
                    borderSide: const BorderSide(color: Color(0xFFDD5428)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: u(14),
                    vertical: v(14),
                  ),
                ),
              ),
            ),
            SizedBox(height: v(12)),
            Text(
              '$count / 400',
              style: _pj(
                u(12),
                weight: FontWeight.w500,
                color: const Color(0xFF7C7C7C),
                height: 1,
              ),
            ),
            SizedBox(height: v(28)),
            SizedBox(
              width: double.infinity,
              height: v(60),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      typed ? const Color(0xFFDD5428) : const Color(0xFFF2A98E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(u(28)),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: _pj(
                    u(15),
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _feedbackCloseSvg = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="0.5" y="0.5" width="31" height="31" rx="15.5" fill="white"/>
<rect x="0.5" y="0.5" width="31" height="31" rx="15.5" stroke="#DBDBDB"/>
<path d="M15.9999 17.4157L19.5353 20.951C19.7229 21.1386 19.9773 21.244 20.2426 21.244C20.5079 21.244 20.7623 21.1386 20.9499 20.951C21.1375 20.7635 21.2429 20.509 21.2429 20.2437C21.2429 19.9784 21.1375 19.724 20.9499 19.5364L17.4133 16.001L20.9493 12.4657C21.0421 12.3728 21.1158 12.2626 21.166 12.1412C21.2162 12.0199 21.2421 11.8898 21.242 11.7585C21.242 11.6271 21.2161 11.4971 21.1658 11.3758C21.1155 11.2545 21.0418 11.1442 20.9489 11.0514C20.8561 10.9585 20.7458 10.8849 20.6244 10.8347C20.5031 10.7844 20.373 10.7586 20.2417 10.7586C20.1104 10.7587 19.9803 10.7846 19.859 10.8348C19.7377 10.8851 19.6275 10.9588 19.5346 11.0517L15.9999 14.587L12.4646 11.0517C12.3724 10.9562 12.2621 10.8799 12.1401 10.8275C12.0181 10.775 11.8869 10.7474 11.7542 10.7461C11.6214 10.7449 11.4897 10.7702 11.3668 10.8204C11.2438 10.8706 11.1322 10.9448 11.0382 11.0387C10.9443 11.1325 10.87 11.2441 10.8196 11.367C10.7693 11.4899 10.7439 11.6215 10.745 11.7543C10.7461 11.8871 10.7736 12.0183 10.826 12.1403C10.8783 12.2624 10.9545 12.3728 11.0499 12.4651L14.5866 16.001L11.0506 19.5371C10.9551 19.6293 10.879 19.7397 10.8267 19.8618C10.7743 19.9838 10.7468 20.115 10.7457 20.2478C10.7446 20.3806 10.77 20.5122 10.8203 20.6351C10.8706 20.758 10.945 20.8696 11.0389 20.9634C11.1328 21.0573 11.2445 21.1315 11.3674 21.1817C11.4904 21.2319 11.622 21.2572 11.7548 21.256C11.8876 21.2547 12.0188 21.2271 12.1408 21.1746C12.2628 21.1222 12.3731 21.0459 12.4653 20.9504L15.9999 17.4157Z" fill-rule="evenodd" clip-rule="evenodd" fill="black"/>
</svg>
''';

const _ticketIconSvg = '''
<svg width="17" height="14" viewBox="0 0 17 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M1.66667 0C1.22464 0 0.800716 0.175595 0.488155 0.488155C0.175595 0.800716 0 1.22464 0 1.66667V5C0.442027 5 0.865951 5.17559 1.17851 5.48816C1.49107 5.80072 1.66667 6.22464 1.66667 6.66667C1.66667 7.10869 1.49107 7.53262 1.17851 7.84518C0.865951 8.15774 0.442027 8.33333 0 8.33333V11.6667C0 12.1087 0.175595 12.5326 0.488155 12.8452C0.800716 13.1577 1.22464 13.3333 1.66667 13.3333H15C15.442 13.3333 15.8659 13.1577 16.1785 12.8452C16.4911 12.5326 16.6667 12.1087 16.6667 11.6667V8.33333C16.2246 8.33333 15.8007 8.15774 15.4882 7.84518C15.1756 7.53262 15 7.10869 15 6.66667C15 6.22464 15.1756 5.80072 15.4882 5.48816C15.8007 5.17559 16.2246 5 16.6667 5V1.66667C16.6667 1.22464 16.4911 0.800716 16.1785 0.488155C15.8659 0.175595 15.442 0 15 0H1.66667ZM1.66667 1.66667H15V3.78333C13.9667 4.375 13.3333 5.475 13.3333 6.66667C13.3333 7.85833 13.9667 8.95833 15 9.55V11.6667H1.66667V9.55C2.7 8.95833 3.33333 7.85833 3.33333 6.66667C3.33333 5.475 2.7 4.375 1.66667 3.78333V1.66667Z" fill="white"/>
</svg>
''';

const _ticketArrowSvg = '''
<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M14.5927 0.0105237C14.808 0.0106577 15.0144 0.0962497 15.1667 0.248499C15.3189 0.400748 15.4045 0.607205 15.4046 0.822517L15.4146 11.537C15.4165 11.6449 15.397 11.7521 15.357 11.8523C15.3171 11.9525 15.2576 12.0438 15.182 12.1207C15.1064 12.1977 15.0163 12.2589 14.9168 12.3007C14.8173 12.3424 14.7105 12.364 14.6026 12.364C14.4947 12.3641 14.3879 12.3426 14.2884 12.301C14.1889 12.2593 14.0987 12.1982 14.023 12.1213C13.9474 12.0444 13.8878 11.9532 13.8477 11.853C13.8077 11.7528 13.788 11.6456 13.7899 11.5378L13.7814 2.78433L1.38779 15.1948C1.23562 15.3474 1.02907 15.4333 0.813584 15.4336C0.598095 15.4338 0.391319 15.3485 0.238742 15.1963C0.0861654 15.0442 0.000287999 14.8376 7.25897e-07 14.6221C-0.000286547 14.4067 0.0850392 14.1999 0.237209 14.0473L12.6347 1.63451L3.87663 1.62609C3.76876 1.62791 3.6616 1.60823 3.56142 1.5682C3.46123 1.52817 3.37002 1.46858 3.29311 1.39293C3.2162 1.31727 3.15513 1.22705 3.11345 1.12754C3.07178 1.02802 3.05035 0.921205 3.0504 0.813318C3.05045 0.705431 3.07198 0.598635 3.11375 0.49916C3.15552 0.399686 3.21668 0.309525 3.29366 0.23394C3.37064 0.158354 3.46191 0.0988565 3.56213 0.0589196C3.66235 0.0189826 3.76953 -0.000594673 3.87739 0.00133049L14.5927 0.0105237Z" fill-rule="evenodd" clip-rule="evenodd" fill="white"/>
</svg>
''';

const _videoPlaySvg = '''
<svg width="27" height="27" viewBox="0 0 27 27" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M13.3333 0C10.6963 0 8.11839 0.781986 5.92574 2.24707C3.73308 3.71216 2.02411 5.79454 1.01495 8.23089C0.00577712 10.6672 -0.258267 13.3481 0.256202 15.9345C0.770672 18.521 2.04055 20.8967 3.90525 22.7614C5.76995 24.6261 8.14572 25.896 10.7321 26.4105C13.3185 26.9249 15.9994 26.6609 18.4358 25.6517C20.8721 24.6426 22.9545 22.9336 24.4196 20.7409C25.8847 18.5483 26.6667 15.9704 26.6667 13.3333C26.6667 11.5824 26.3218 9.84856 25.6517 8.23089C24.9817 6.61321 23.9995 5.14336 22.7614 3.90524C21.5233 2.66713 20.0535 1.685 18.4358 1.01494C16.8181 0.344877 15.0843 0 13.3333 0ZM10.6667 19.3333V7.33333L18.6667 13.3333L10.6667 19.3333Z" fill="#DD5428"/>
</svg>
''';
