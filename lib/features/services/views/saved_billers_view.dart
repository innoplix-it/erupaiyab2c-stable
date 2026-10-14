import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../widgets/my_app_bar.dart';
import '../components/service_recent_section.dart';
import '../controllers/biller_listing_controller.dart';
import '../controllers/service_extras_controller.dart';
import 'biller_listing_view.dart';

/// "View all" for a service's Saved Billers: the full list behind the
/// preview row, from the same latest-transactions provider.
class SavedBillersView extends ConsumerWidget {
  const SavedBillersView({super.key, required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = categoryName.trim();
    final savedBillers = ref.watch(serviceLatestTransactionsProvider(service));
    final billers = ref.watch(billerListingControllerProvider).billers;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: 'Saved Billers',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SavedBillersList(
              savedBillers: savedBillers,
              serviceCategory: categoryName,
              onRetry: () =>
                  ref.invalidate(serviceLatestTransactionsProvider(service)),
              onPayNow: (txn) => openSavedBillerPayment(
                context,
                ref,
                txn: txn,
                billers: billers,
                categoryName: categoryName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
