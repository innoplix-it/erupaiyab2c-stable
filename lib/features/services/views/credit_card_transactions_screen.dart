// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../components/credit_card/credit_card_figma_metrics.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/app_search_bar.dart';
import '../controllers/credit_card_transactions_controller.dart';
import '../models/credit_card_month_section.dart';
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

    final sections = groupCreditCardTransactionsByMonth(items);

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
          if (sections.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else ...[
            for (var s = 0; s < sections.length; s++) ...[
              SliverToBoxAdapter(
                child: _MonthHeader(
                  title: sections[s].title,
                  count: sections[s].count,
                  isFirst: s == 0,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = sections[s].items[index];
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
                  childCount: sections[s].items.length,
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(height: CreditCardFigmaMetrics.sy(context, 24)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.title,
    required this.count,
    this.isFirst = false,
  });

  final String title;
  final int count;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final countLabel = '$count Transaction${count == 1 ? '' : 's'}';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        CreditCardFigmaMetrics.s(context, 16),
        isFirst
            ? CreditCardFigmaMetrics.sy(context, 4)
            : CreditCardFigmaMetrics.sy(context, 16),
        CreditCardFigmaMetrics.s(context, 16),
        CreditCardFigmaMetrics.sy(context, 12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: CreditCardFigmaMetrics.s(context, 12),
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: 0,
                color: const Color(0xFF000000),
              ),
            ),
          ),
          SizedBox(width: CreditCardFigmaMetrics.s(context, 8)),
          Text(
            countLabel,
            maxLines: 1,
            style: GoogleFonts.plusJakartaSans(
              fontSize: CreditCardFigmaMetrics.s(context, 12),
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: 0,
              color: const Color(0xFF7C7C7C),
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
                        ? AppNetworkImage(
                            url: item.icon,
                            fit: BoxFit.cover,
                            errorWidget: Icon(
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.billerName.isNotEmpty ? item.billerName : 'Card',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: CreditCardFigmaMetrics.s(context, 12),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        SizedBox(height: CreditCardFigmaMetrics.sy(context, 4)),
                        Text(
                          item.transactionTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: CreditCardFigmaMetrics.s(context, 10),
                            fontWeight: FontWeight.w400,
                            height: 1.1,
                            color: const Color(0xFF7C7C7C),
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: CreditCardFigmaMetrics.s(context, 15),
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            letterSpacing: 0,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        SizedBox(height: CreditCardFigmaMetrics.sy(context, 6)),
                        _StatusBadge(meta: meta),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.meta});

  final _StatusMeta meta;

  @override
  Widget build(BuildContext context) {
    // Media query-based uniform responsive dimensions for all status states
    // Ensures Failed, Success, and Pending badges have the exact same size.
    final badgeWidth = CreditCardFigmaMetrics.s(context, 76);
    final badgeHeight = CreditCardFigmaMetrics.sy(context, 22);
    final badgeRadius = CreditCardFigmaMetrics.s(context, 11);

    return Container(
      width: badgeWidth,
      height: badgeHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: meta.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(badgeRadius),
      ),
      child: Text(
        meta.label,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: CreditCardFigmaMetrics.s(context, 10.5),
          fontWeight: FontWeight.w600,
          height: 1,
          letterSpacing: 0,
          color: meta.color,
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: CreditCardFigmaMetrics.s(context, 14),
            fontWeight: FontWeight.w500,
            color: const Color(0xFF7C7C7C),
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
  final upper = status.trim().toUpperCase();
  if (upper.contains('FAIL') || upper.contains('REFUND')) {
    return const _StatusMeta('Failed', Color(0xFFD84315));
  }
  if (upper.contains('PEND') || upper.contains('PROCESS')) {
    return const _StatusMeta('Pending', Color(0xFFF6A623));
  }
  return const _StatusMeta('Success', Color(0xFF0F8A4B));
}

String _formatAmount(String raw) {
  final value = double.tryParse(raw) ?? 0;
  return '₹${value.toStringAsFixed(2)}';
}
