// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../components/credit_card/credit_card_figma_metrics.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/app_search_bar.dart';
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
  void didUpdateWidget(covariant CreditCardTransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maskedIdentifier != widget.maskedIdentifier) {
      Future.microtask(() {
        ref
            .read(creditCardTransactionsControllerProvider.notifier)
            .fetchTransactions(
              maskedIdentifier: widget.maskedIdentifier,
            );
      });
    }
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
                '${item.billerName} ${item.paymentStatus} ${item.amount} ${item.paymentTransactionId} ${item.bankReferenceId}'
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
            // Match the common app bar (Transaction History): default title
            // style + 52x25 Bharat Connect + 20px help icon.
            bharatConnectWidth: 52,
            bharatConnectHeight: 25,
            helpIconSize: 20,
            onBack: () => context.pop(),
          ),
          // Pinned like Transaction History: gap stays under the field while
          // the list scrolls in the Expanded below.
          Padding(
            padding: AppSearchBar.pinnedPadding,
            child: AppSearchBar(
              hintText: 'Search Transactions',
              controller: _searchController,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _buildContent(context, state, items),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CreditCardTransactionsState state,
    List<CreditCardTransaction> items,
  ) {
    if (widget.maskedIdentifier.trim().isEmpty) {
      return const Center(
        child: _EmptyState(message: 'Masked identifier is missing.'),
      );
    }

    if (state.isLoading && state.items.isEmpty) {
      return Center(
        child: SpinKitCircle(
          color: AppColors.primary,
          size: MediaQuery.sizeOf(context).width * (48 / 440),
        ),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: CreditCardFigmaMetrics.s(context, 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              SizedBox(height: CreditCardFigmaMetrics.sy(context, 12)),
              TextButton(
                onPressed: () => ref
                    .read(creditCardTransactionsControllerProvider.notifier)
                    .fetchTransactions(
                      maskedIdentifier: widget.maskedIdentifier,
                    ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref
          .read(creditCardTransactionsControllerProvider.notifier)
          .fetchTransactions(
            maskedIdentifier: widget.maskedIdentifier,
            isRefresh: true,
          ),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      CreditCardFigmaMetrics.s(context, 16),
                      CreditCardFigmaMetrics.sy(context, 0),
                      CreditCardFigmaMetrics.s(context, 16),
                      CreditCardFigmaMetrics.sy(context, 12),
                    ),
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
            child: SizedBox(height: CreditCardFigmaMetrics.sy(context, 24)),
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
          padding: EdgeInsets.symmetric(
              horizontal: CreditCardFigmaMetrics.s(context, 16),
              vertical: CreditCardFigmaMetrics.sy(context, 14)),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(CreditCardFigmaMetrics.s(context, 16)),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: CreditCardFigmaMetrics.s(context, 42),
                    width: CreditCardFigmaMetrics.s(context, 42),
                    decoration: BoxDecoration(
                      color: meta.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                        CreditCardFigmaMetrics.s(context, 10),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: item.icon.trim().isNotEmpty
                        ? Image.network(
                            item.icon,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.credit_card,
                              color: meta.color,
                            ),
                          )
                        : Icon(
                            Icons.credit_card,
                            color: meta.color,
                          ),
                  ),
                  SizedBox(width: CreditCardFigmaMetrics.s(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.billerName.isNotEmpty ? item.billerName : 'Card',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: (Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.fontSize ??
                                            14) -
                                        2,
                                  ),
                        ),
                        SizedBox(height: CreditCardFigmaMetrics.sy(context, 4)),
                        Text(
                          item.transactionTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: CreditCardFigmaMetrics.s(context, 8)),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.45,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatAmount(item.amount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        SizedBox(height: CreditCardFigmaMetrics.sy(context, 6)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: CreditCardFigmaMetrics.s(context, 8),
                            vertical: CreditCardFigmaMetrics.sy(context, 2),
                          ),
                          decoration: BoxDecoration(
                            color: meta.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(
                              CreditCardFigmaMetrics.s(context, 12),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            meta.label,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: meta.color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: (Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.fontSize ??
                                              12) -
                                          1,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.message = 'No transactions found'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: CreditCardFigmaMetrics.s(context, 16),
        vertical: CreditCardFigmaMetrics.sy(context, 24),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
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
