import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/support_transaction_card.dart';
import '../controllers/recent_payment_help_controller.dart';
import '../models/support_faq_item.dart';
import '../models/support_latest_transaction.dart';
import 'create_support_ticket_screen.dart';

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

    final bottomButtonHeight = 42.h;
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: CustomElevatedButton(
            height: bottomButtonHeight,
            label: 'Still need help?',
            uppercaseLabel: false,
            showArrow: false,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateSupportTicketScreen(
                    transaction: transaction,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      body: Column(
        children: [
          const MyAppBar(title: ''),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.fetch,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  12.h,
                  16.w,
                  24.h + bottomButtonHeight + 24.h,
                ),
                children: [
                  Text(
                    'Need help with your recent payment?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  SizedBox(height: 12.h),
                  SupportTransactionCard(
                    transaction: transaction,
                    width: double.infinity,
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    "FAQ’s",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  SizedBox(height: 8.h),
                  if (state.isLoading && state.items.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      child: Center(
                        child: SizedBox(height: 26.r,
                          width: 26.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  else if (state.items.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      child: Center(
                        child: Text(
                          'No FAQs available',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.6),
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
                  SizedBox(height: 18.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                          color: AppColors.textPrimary.withOpacity(0.75),
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
