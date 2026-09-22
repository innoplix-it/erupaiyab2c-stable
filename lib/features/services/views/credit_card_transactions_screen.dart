// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/search_textfield.dart';
import '../controllers/credit_card_transactions_controller.dart';
import '../models/credit_card_transaction.dart';

class CreditCardTransactionsScreen extends ConsumerStatefulWidget {
  const CreditCardTransactionsScreen({
    super.key,
    required this.maskedIdentifier,
  });

  final String maskedIdentifier;

  @override
  ConsumerState<CreditCardTransactionsScreen> createState() =>
      _CreditCardTransactionsScreenState();
}

class _CreditCardTransactionsScreenState
    extends ConsumerState<CreditCardTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(creditCardTransactionsControllerProvider.notifier)
          .fetchTransactions(
            maskedIdentifier: widget.maskedIdentifier,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creditCardTransactionsControllerProvider);
    final query = _searchController.text.trim().toLowerCase();
    final items = query.isEmpty
        ? state.items
        : state.items.where((item) {
            final haystack =
                '${item.billerName} ${item.paymentStatus} ${item.amount}'
                    .toLowerCase();
            return haystack.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: 'Card Transactions',
            showHelp: true,
            onBack: () => context.pop(),
            onHelp: () {},
          ),
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: SpinKitCircle(
                      color: AppColors.primary,
                      size: 48,
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                        sliver: SliverToBoxAdapter(
                          child: SearchTextfield(
                            hintText: 'Search Transactions',
                            controller: _searchController,
                            onChange: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      if (items.isEmpty)
                        const SliverToBoxAdapter(
                          child: _EmptyState(),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = items[index];
                              return Padding(
                                padding:
                                    EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 12.h),
                                child: _TransactionTile(
                                  item: item,
                                  onTap: () => context.push(
                                    RouteConstants.creditCardTransactionDetail,
                                    extra: item,
                                  ),
                                ),
                              );
                            },
                            childCount: items.length,
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 24.h),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item, required this.onTap});

  final CreditCardTransaction item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = item.paymentStatus.trim().toUpperCase();
    final meta = _statusMeta(status);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Container(
                height: 42.r,
                width: 42.r,
                decoration: BoxDecoration(
                  color: meta.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: item.icon.trim().isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          item.icon,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.credit_card,
                            color: meta.color,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.credit_card,
                        color: meta.color,
                      ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.billerName.isNotEmpty ? item.billerName : 'Card',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.transactionTime,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(item.amount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: meta.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      meta.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: meta.color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Text(
        'No transactions found',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary.withOpacity(0.6),
            ),
      ),
    );
  }
}

class _StatusMeta {
  const _StatusMeta(this.label, this.color);

  final String label;
  final Color color;
}

_StatusMeta _statusMeta(String status) {
  switch (status) {
    case 'SUCCESS':
      return const _StatusMeta('Success', Color(0xFF0F8A4B));
    case 'FAILED':
    case 'FAIL':
      return const _StatusMeta('Failed', Color(0xFFD84315));
    case 'PENDING':
    case 'PROCESSING':
      return const _StatusMeta('Pending', Color(0xFFF6A623));
    default:
      return const _StatusMeta('Pending', Color(0xFFF6A623));
  }
}

String _formatAmount(String raw) {
  final value = double.tryParse(raw) ?? 0;
  return '₹${value.toStringAsFixed(2)}';
}
