import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// PAN format: AAAAA 9999 A  (5 letters, 4 digits, 1 letter) = 10 chars.
const int kPanLength = 10;
const int kPanLeadingLetters = 5;
const int kPanDigitsEnd = 9; // index of the final letter

/// Keyboard segment for the number of characters entered so far.
///  0 -> letters (first 5 chars)
///  1 -> numbers (next 4 chars, i.e. length 5..8)
///  2 -> letters (final char, length 9..10)
int panKeyboardSegmentForLength(int length) {
  if (length < kPanLeadingLetters) return 0;
  if (length < kPanDigitsEnd) return 1;
  return 2;
}

bool _isLetter(int c) => (c >= 0x41 && c <= 0x5A); // A-Z (after uppercase)
bool _isDigit(int c) => (c >= 0x30 && c <= 0x39);

/// Position-aware PAN formatter. Uppercases input, drops characters that are
/// invalid for their slot (letters / digits / letter) and caps at 10 chars.
/// Safe for pasted text.
class PanInputFormatter extends TextInputFormatter {
  const PanInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    final rawCursor = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, text.length)
        : text.length;

    final buf = StringBuffer();
    var accepted = 0;
    var acceptedBeforeCursor = 0;

    for (var i = 0; i < text.length && accepted < kPanLength; i++) {
      final c = text.codeUnitAt(i);
      final pos = accepted;
      final expectDigit = pos >= kPanLeadingLetters && pos < kPanDigitsEnd;
      final ok = expectDigit ? _isDigit(c) : _isLetter(c);
      if (!ok) continue;
      buf.writeCharCode(c);
      accepted++;
      if (i < rawCursor) acceptedBeforeCursor++;
    }

    return TextEditingValue(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: acceptedBeforeCursor),
    );
  }
}

/// Aadhaar formatter: digits only, max 12 digits, grouped as "1234 5678 9012".
class AadhaarInputFormatter extends TextInputFormatter {
  const AadhaarInputFormatter();

  static const int maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final rawCursor = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, text.length)
        : text.length;

    final digits = StringBuffer();
    var digitsBeforeCursor = 0;
    for (var i = 0; i < text.length && digits.length < maxDigits; i++) {
      final c = text.codeUnitAt(i);
      if (!_isDigit(c)) continue;
      digits.writeCharCode(c);
      if (i < rawCursor) digitsBeforeCursor++;
    }

    final d = digits.toString();
    final out = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) out.write(' ');
      out.write(d[i]);
    }

    final offset = digitsBeforeCursor == 0
        ? 0
        : digitsBeforeCursor + (digitsBeforeCursor - 1) ~/ 4;

    return TextEditingValue(
      text: out.toString(),
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Editable PAN field with segment-aware keyboard type and [PanInputFormatter].
///
/// Stages: letters (0-4) -> numbers (5-8) -> letter (9).
class PanInputField extends HookWidget {
  const PanInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.onChanged,
    this.style,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final TextAlign textAlign;

  /// Keyboard action (e.g. next / done) for smooth field navigation.
  final TextInputAction? textInputAction;

  /// Called when the keyboard action button is pressed.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final localFocus = focusNode ?? useFocusNode();
    final segment =
        useState(panKeyboardSegmentForLength(controller.text.length));

    // Single listener: only updates state when the stage actually changes.
    useEffect(() {
      void onTextChanged() {
        final next = panKeyboardSegmentForLength(controller.text.length);
        if (next != segment.value) {
          segment.value = next;
        }
      }

      // Sync once in case the controller was pre-filled / changed.
      onTextChanged();
      controller.addListener(onTextChanged);
      return () => controller.removeListener(onTextChanged);
    }, [controller]);

    // When the PAN stage changes, re-attach the input connection so the OS
    // keyboard actually switches (letters -> numbers -> letters) instead of
    // being dismissed by a widget-key rebuild. The persistent focus node is
    // toggled, so text and caret living in the controller survive.
    final lastSegment = useRef(segment.value);
    useEffect(() {
      if (segment.value == lastSegment.value) return null;
      lastSegment.value = segment.value;
      if (!localFocus.hasFocus) return null;
      localFocus.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        localFocus.requestFocus();
      });
      return null;
    }, [segment.value]);

    return TextField(
      controller: controller,
      focusNode: localFocus,
      keyboardType:
          segment.value == 1 ? TextInputType.number : TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: const [PanInputFormatter()],
      decoration: decoration,
      style: style,
      textAlign: textAlign,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
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
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final TextAlign textAlign;

  /// Keyboard action (e.g. next / done) for smooth field navigation.
  final TextInputAction? textInputAction;

  /// Called when the keyboard action button is pressed.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      autocorrect: false,
      enableSuggestions: false,
      // 12 digits + 2 group spaces = 14 chars; formatter enforces the digit cap.
      maxLength: 14,
      inputFormatters: const [AadhaarInputFormatter()],
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: decoration?.copyWith(counterText: '') ??
          const InputDecoration(counterText: ''),
      style: style,
      textAlign: textAlign,
      onChanged: onChanged,
    );
  }
}
