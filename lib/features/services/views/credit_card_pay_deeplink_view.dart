import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/my_app_bar.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/models/credit_card_item.dart';
import '../controllers/biller_detail_controller.dart';
import '../models/biller_detail_args.dart';
import '../models/biller_model.dart';

class CreditCardPayDeeplinkView extends ConsumerStatefulWidget {
  const CreditCardPayDeeplinkView({
    super.key,
    required this.billerName,
    required this.maskedIdentifier,
    required this.customerMobile,
    this.amount,
    this.iconUrl,
  });

  final String billerName;
  final String maskedIdentifier;
  final String customerMobile;
  final double? amount;
  final String? iconUrl;

  @override
  ConsumerState<CreditCardPayDeeplinkView> createState() =>
      _CreditCardPayDeeplinkViewState();
}

class _CreditCardPayDeeplinkViewState
    extends ConsumerState<CreditCardPayDeeplinkView> {
  bool _didNavigate = false;

  String _normalize(String input) => input.trim().toLowerCase();

  String _last4FromMasked(String maskedIdentifier) {
    final digits = maskedIdentifier.replaceAll(RegExp(r'\\D'), '');
    if (digits.length >= 4) return digits.substring(digits.length - 4);
    return digits;
  }

  bool _isMatch(CreditCardItem card) {
    final targetName = _normalize(widget.billerName);
    final cardName = _normalize(card.billerName ?? '');
    final nameOk = targetName.isNotEmpty &&
        cardName.isNotEmpty &&
        (cardName == targetName || cardName.contains(targetName));

    final targetMobile = _normalize(widget.customerMobile);
    final cardMobile = _normalize(card.registerMobNo ?? '');
    final mobileOk = targetMobile.isNotEmpty &&
        cardMobile.isNotEmpty &&
        cardMobile == targetMobile;

    final targetLast4 = _last4FromMasked(widget.maskedIdentifier);
    final cardLast4 = (card.last4Digit ?? '').trim();
    final last4Ok = targetLast4.isNotEmpty &&
        cardLast4.isNotEmpty &&
        cardLast4 == targetLast4;

    final maskedDigits = widget.maskedIdentifier.replaceAll('*', '').trim();
    final maskedOk = maskedDigits.isNotEmpty &&
        _normalize(card.maskedIdentifier ?? '')
            .endsWith(_normalize(maskedDigits));

    return nameOk && (last4Ok || mobileOk || maskedOk);
  }

  void _tryNavigate() {
    if (_didNavigate || !mounted) return;
    final homeState = ref.read(homeControllerProvider);
    final cards = homeState.creditCardActions;
    if (homeState.isFetchingCreditCards || cards == null) return;

    if (cards.isEmpty) {
      _didNavigate = true;
      AppSnackbar.show(
        'No cards found. Please add a card first.',
        type: AppSnackbarType.error,
      );
      context.pushReplacement(RouteConstants.creditCardListing);
      return;
    }

    final match =
        cards.firstWhere(_isMatch, orElse: () => const CreditCardItem());

    if ((match.billerId ?? '').trim().isEmpty) {
      _didNavigate = true;
      AppSnackbar.show(
        'Unable to find this card. Please retry from Credit Card section.',
        type: AppSnackbarType.error,
      );
      context.pushReplacement(RouteConstants.creditCardMyCards);
      return;
    }

    _didNavigate = true;
    final resolvedBillerName = (match.billerName ?? '').trim().isNotEmpty
        ? match.billerName!.trim()
        : widget.billerName;
    final biller = Biller(
      billerId: match.billerId ?? '',
      billerName: resolvedBillerName,
      icon: (match.icon ?? '').trim().isNotEmpty ? match.icon : widget.iconUrl,
    );

    ref.read(billerDetailControllerProvider.notifier).selectBiller(
          biller,
          categoryName: resolvedBillerName,
        );
    context.pushReplacement(
      RouteConstants.billerDetail,
      extra: BillerDetailArgs(
        biller: biller,
        isCreditCard: true,
        paymentType: resolvedBillerName,
        mobileNumber: match.registerMobNo ?? widget.customerMobile,
        cardLast4: (match.last4Digit ?? '').trim().isNotEmpty
            ? match.last4Digit
            : _last4FromMasked(widget.maskedIdentifier),
        autoFetchBill: true,
        autoOpenPaymentSheet: false,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homeControllerProvider.notifier).fetchCreditCardActions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryNavigate());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: 'Credit Card',
        onBack: () => context.pop(),
        showHelp: false,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 12.h),
              Text(
                homeState.isFetchingCreditCards
                    ? 'Loading your cards…'
                    : 'Opening bill fetch…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
