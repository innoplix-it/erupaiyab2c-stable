import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';

class PinInputRow extends StatelessWidget {
  const PinInputRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
    this.enabled = true,
    this.onPinChanged,
    this.onPinCompleted,
  }) : assert(controllers.length == focusNodes.length);

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool enabled;
  final ValueChanged<String>? onPinChanged;
  final ValueChanged<String>? onPinCompleted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = MediaQuery.sizeOf(context).width;
        // Figma gap 8 / 360 and box cap 56 / 360. Never force a minimum
        // wider than the parent, or a narrow row overflows.
        final spacing = (screenW * (8 / 360)).clamp(4.0, 12.0);
        final maxWidth = constraints.maxWidth;
        final totalSpacing = spacing * (controllers.length - 1);
        final cap = screenW * (56 / 360);
        final available = (maxWidth - totalSpacing) / controllers.length;
        final boxSize = available.clamp(0.0, cap);
        final children = <Widget>[];
        for (var i = 0; i < controllers.length; i++) {
          children.add(
            _PinDigitField(
              controller: controllers[i],
              focusNode: focusNodes[i],
              enabled: enabled,
              width: boxSize,
              height: boxSize,
              onChanged: (value) {
                if (value.isEmpty && i > 0) {
                  focusNodes[i - 1].requestFocus();
                } else if (value.isNotEmpty && i < focusNodes.length - 1) {
                  focusNodes[i + 1].requestFocus();
                }
                final pin = controllers.map((c) => c.text).join();
                onPinChanged?.call(pin);
                final isComplete =
                    controllers.every((c) => c.text.trim().isNotEmpty);
                if (isComplete) {
                  onPinCompleted?.call(pin);
                }
              },
            ),
          );
          if (i != controllers.length - 1) {
            children.add(SizedBox(width: spacing));
          }
        }
        return SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: children,
          ),
        );
      },
    );
  }
}

class _PinDigitField extends StatelessWidget {
  const _PinDigitField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.enabled = true,
    required this.width,
    required this.height,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        final hasValue = controller.text.trim().isNotEmpty;
        final isFocused = focusNode.hasFocus;
        final borderColor =
            isFocused || hasValue ? AppColors.primary : AppColors.lightBorder;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}
