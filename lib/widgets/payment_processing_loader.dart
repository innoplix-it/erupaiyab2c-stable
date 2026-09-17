import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/file_constants.dart';

class PaymentProcessingLoader extends StatelessWidget {
  const PaymentProcessingLoader({
    super.key,
    this.size = 160,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        FileConstants.paymentProcessingLottie,
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
        frameRate: FrameRate.max,
      ),
    );
  }
}
