import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/file_constants.dart';

const Duration paymentProcessingDuration = Duration(seconds: 60);

class PaymentProcessingLoader extends StatefulWidget {
  const PaymentProcessingLoader({
    super.key,
    this.size = 160,
  });

  final double size;

  @override
  State<PaymentProcessingLoader> createState() =>
      _PaymentProcessingLoaderState();
}

class _PaymentProcessingLoaderState extends State<PaymentProcessingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: paymentProcessingDuration,
    );
    _controller.forward();
  }

  void _syncToElapsed() {
    final elapsed = DateTime.now().difference(_startedAt);
    final progress = (elapsed.inMilliseconds /
            paymentProcessingDuration.inMilliseconds)
        .clamp(0.0, 1.0);
    _controller.duration = paymentProcessingDuration;
    _controller.value = progress;
    if (progress >= 1) {
      return;
    }
    if (!_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.asset(
        FileConstants.paymentProcessingLottie,
        controller: _controller,
        fit: BoxFit.contain,
        onLoaded: (_) => _syncToElapsed(),
      ),
    );
  }
}
