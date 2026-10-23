import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/my_app_bar.dart';
import '../controllers/recent_payment_help_controller.dart';
import '../models/support_faq_item.dart';
import '../models/support_latest_transaction.dart';
import 'create_support_ticket_screen.dart';

/// Figma frame of the recent-payment help screen, measured from the
/// reference export (448×986). Width ratios use the frame width and height
/// ratios use the frame height so the two axes do not share one scale.
const double _frameW = 448;
const double _frameH = 986;

class RecentPaymentHelpScreen extends HookConsumerWidget {
  const RecentPaymentHelpScreen({
    super.key,
    required this.transaction,
  });

  final SupportLatestTransaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(recentPaymentHelpControllerProvider(transaction.faqCategory));
    final controller = ref.read(
      recentPaymentHelpControllerProvider(transaction.faqCategory).notifier,
    );

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

    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final hPad = width * (28 / _frameW);
    final buttonHeight = height * (47 / _frameH);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            height * (12 / _frameH),
            hPad,
            height * (12 / _frameH),
          ),
          child: SizedBox(
            height: buttonHeight,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateSupportTicketScreen(
                      transaction: transaction,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFDD5428),
                foregroundColor: Colors.white,
                minimumSize: Size(0, buttonHeight),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonHeight / 2),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: width * (16 / _frameW),
                ),
              ),
              child: Text(
                'Still need help?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: width * (15 / _frameW),
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          MyAppBar(
            title: '',
            titleStyle: MyAppBar.sharedTitleStyle(context),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.fetch,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  height * (16 / _frameH),
                  hPad,
                  height * (16 / _frameH),
                ),
                children: [
                  Text(
                    'Need help with your recent payment?',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: width * (16 / _frameW),
                      height: 1.3,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: height * (18 / _frameH)),
                  _RecentPaymentCard(transaction: transaction),
                  SizedBox(height: height * (28 / _frameH)),
                  Text(
                    "FAQ's",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: width * (15 / _frameW),
                      height: 1.2,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: height * (12 / _frameH)),
                  if (state.isLoading && state.items.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: height * (14 / _frameH),
                      ),
                      child: Center(
                        child: SizedBox(
                          height: width * (22 / _frameW),
                          width: width * (22 / _frameW),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  else if (state.items.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: height * (14 / _frameH),
                      ),
                      child: Center(
                        child: Text(
                          'No FAQs available',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.black.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                            fontSize: width * (13 / _frameW),
                          ),
                        ),
                      ),
                    )
                  else
                    ...state.items.map(
                      (item) => _FaqTile(
                        item: item,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _FaqDetailView(item: item),
                          ),
                        ),
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

class _RecentPaymentCard extends StatelessWidget {
  const _RecentPaymentCard({required this.transaction});

  final SupportLatestTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardHeight = width * (85 / _frameW);
    final headerHeight = width * (35 / _frameW);
    final radius = width * (12 / _frameW);
    final pad = width * (12 / _frameW);
    final iconBox = width * (28 / _frameW);
    final amount = transaction.amount.trim();
    final amountLabel =
        amount.isEmpty ? '' : (amount.startsWith('₹') ? amount : '₹$amount');

    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: headerHeight,
            padding: EdgeInsets.symmetric(horizontal: pad),
            color: const Color(0xFFF0F0F0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    transaction.paymentType.isNotEmpty
                        ? transaction.paymentType
                        : 'Transaction',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: width * (13 / _frameW),
                      height: 1.1,
                    ),
                  ),
                ),
                SizedBox(width: width * (8 / _frameW)),
                Container(
                  height: width * (16 / _frameW),
                  padding: EdgeInsets.symmetric(
                    horizontal: width * (8 / _frameW),
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _statusColor(transaction.status),
                    borderRadius: BorderRadius.circular(width * (4 / _frameW)),
                  ),
                  child: Text(
                    _statusLabel(transaction.status),
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: width * (9 / _frameW),
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: Row(
                children: [
                  Container(
                    height: iconBox,
                    width: iconBox,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1EB),
                      borderRadius:
                          BorderRadius.circular(width * (6 / _frameW)),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: const Color(0xFFEA5A30),
                      size: iconBox * 0.62,
                    ),
                  ),
                  SizedBox(width: width * (8 / _frameW)),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.billerName.isNotEmpty
                              ? transaction.billerName
                              : '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: width * (12 / _frameW),
                            height: 1.15,
                          ),
                        ),
                        Text(
                          _formatDate(transaction),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.black.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w500,
                            fontSize: width * (10 / _frameW),
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: width * (8 / _frameW)),
                  Text(
                    amountLabel,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: width * (14 / _frameW),
                      height: 1.1,
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

Color _statusColor(String raw) {
  final status = raw.trim().toLowerCase();
  if (status == 'success' || status == 'successful' || status == 'paid') {
    return const Color(0xFF0E8B3E);
  }
  if (status == 'failed' || status == 'failure') {
    return const Color(0xFFBF0609);
  }
  return const Color(0xFFF6A623);
}

String _statusLabel(String raw) {
  final status = raw.trim().toLowerCase();
  if (status.isEmpty || status == 'pending' || status == 'processing') {
    return 'Pending';
  }
  if (status == 'success' || status == 'successful' || status == 'paid') {
    return 'Success';
  }
  if (status == 'failed' || status == 'failure') return 'Failed';
  return raw.trim().isEmpty
      ? 'Pending'
      : raw.trim()[0].toUpperCase() + raw.trim().substring(1).toLowerCase();
}

String _formatDate(SupportLatestTransaction transaction) {
  final dt = transaction.dateTime;
  if (dt == null) return transaction.date;
  return DateFormat("d MMM''yy").format(dt);
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.onTap,
  });

  final SupportFaqItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: height * (10 / _frameH)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: width * (14 / _frameW),
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
            ),
            SizedBox(width: width * (8 / _frameW)),
            Icon(
              Icons.chevron_right,
              color: Colors.black.withValues(alpha: 0.85),
              size: width * (18 / _frameW),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqDetailView extends StatelessWidget {
  const _FaqDetailView({required this.item});

  final SupportFaqItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const MyAppBar(title: 'FAQ'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.75),
                          height: 1.5,
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
