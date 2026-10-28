import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../helpers/kyc_input_formatters.dart';

/// Editable PAN field with segment-aware keyboard type and [PanInputFormatter].
class PanInputField extends HookWidget {
  const PanInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.onChanged,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final localFocus = focusNode ?? useFocusNode();
    final segment = useState(panKeyboardSegmentForLength(controller.text.length));

    useEffect(() {
      void onTextChanged() {
        final next = panKeyboardSegmentForLength(controller.text.length);
        if (next != segment.value) {
          segment.value = next;
        }
      }

      controller.addListener(onTextChanged);
      return () => controller.removeListener(onTextChanged);
    }, [controller]);

    return TextField(
      key: ValueKey('pan_keyboard_${segment.value}'),
      controller: controller,
      focusNode: localFocus,
      keyboardType: panKeyboardTypeForLength(controller.text.length),
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: const [PanInputFormatter()],
      decoration: decoration,
      style: style,
      textAlign: textAlign,
      onChanged: onChanged,
    );
  }
}

/// Editable Aadhaar field: numeric keyboard, grouped digits, max 12 digits.
class AadhaarInputField extends StatelessWidget {
  const AadhaarInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.onChanged,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      autocorrect: false,
      enableSuggestions: false,
      maxLength: 14,
      inputFormatters: const [AadhaarInputFormatter()],
      decoration: decoration?.copyWith(counterText: '') ??
          const InputDecoration(counterText: ''),
      style: style,
      textAlign: textAlign,
      onChanged: onChanged,
    );
  }
}
