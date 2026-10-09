// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../educationFees/views/education_payment_thank_you_view.dart';
import '../../models/digital_gold_purchase_receipt.dart';

class DigitalGoldSipSuccessView extends ConsumerStatefulWidget {
  const DigitalGoldSipSuccessView({
    super.key,
    this.receipt,
  });

  final DigitalGoldPurchaseReceipt? receipt;

  @override
  ConsumerState<DigitalGoldSipSuccessView> createState() =>
      _DigitalGoldSipSuccessViewState();
}

class _DigitalGoldSipSuccessViewState
    extends ConsumerState<DigitalGoldSipSuccessView> {
  @override
  void initState() {
    super.initState();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EducationPaymentThankYouView(
          amount: widget.receipt?.amountPaid ?? '',
          payableAmount: widget.receipt?.amountPaid ?? '',
          transactionTime: widget.receipt?.dateTime ?? DateTime.now().toIso8601String(),
          paymentType: 'Gold SIP',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
