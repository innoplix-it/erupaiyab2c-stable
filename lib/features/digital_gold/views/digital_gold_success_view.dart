// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../educationFees/views/education_payment_thank_you_view.dart';
import '../models/digital_metal.dart';

class DigitalGoldSuccessView extends StatelessWidget {
  const DigitalGoldSuccessView({
    super.key,
    this.metal = DigitalMetal.gold,
  });

  final DigitalMetal metal;

  @override
  Widget build(BuildContext context) {
    final theme = DigitalMetalTheme.of(metal);
    return EducationPaymentThankYouView(
      amount: '',
      payableAmount: '',
      transactionTime: DateTime.now().toIso8601String(),
      paymentType: '${theme.label} Buy',
    );
  }
}
