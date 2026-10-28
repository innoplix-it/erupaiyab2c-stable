import 'package:flutter/services.dart';

/// Segment index for PAN keyboard switching: letters, digits, final letter.
int panKeyboardSegmentForLength(int length) {
  if (length < 5) return 0;
  if (length < 9) return 1;
  return 2;
}

/// Keyboard type for the current PAN cursor position (by valid text length).
TextInputType panKeyboardTypeForLength(int length) {
  return panKeyboardSegmentForLength(length) == 1
      ? TextInputType.number
      : TextInputType.text;
}

/// Filters and normalises in-progress PAN entry to `AAAAA9999A` (max 10 chars).
class PanInputFormatter extends TextInputFormatter {
  const PanInputFormatter();

  static final RegExp _letter = RegExp(r'[A-Za-z]');
  static final RegExp _digit = RegExp(r'[0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = _formatPan(newValue.text);
    if (formatted == oldValue.text && newValue.text != oldValue.text) {
      return oldValue;
    }
    if (formatted == oldValue.text) {
      return _clampSelection(oldValue, formatted);
    }
    return TextEditingValue(
      text: formatted,
      selection: _mapSelection(newValue.selection, newValue.text, formatted),
    );
  }

  static String _formatPan(String raw) {
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length && buffer.length < 10; i++) {
      final char = raw[i];
      final pos = buffer.length;
      if (pos < 5 || pos == 9) {
        if (_letter.hasMatch(char)) {
          buffer.write(char.toUpperCase());
        }
      } else if (_digit.hasMatch(char)) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static TextEditingValue _clampSelection(
    TextEditingValue value,
    String formatted,
  ) {
    final end = value.selection.end.clamp(0, formatted.length);
    return value.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: end),
    );
  }

  static TextSelection _mapSelection(
    TextSelection selection,
    String raw,
    String formatted,
  ) {
    final rawOffset = selection.baseOffset.clamp(0, raw.length);
    final prefix = _formatPan(raw.substring(0, rawOffset));
    final offset = prefix.length.clamp(0, formatted.length);
    return TextSelection.collapsed(offset: offset);
  }
}

/// Digits-only Aadhaar with optional `1234 5678 9012` grouping (max 12 digits).
class AadhaarInputFormatter extends TextInputFormatter {
  const AadhaarInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 12 ? digits.substring(0, 12) : digits;

    final buffer = StringBuffer();
    for (var index = 0; index < trimmed.length; index++) {
      if (index > 0 && index % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(trimmed[index]);
    }

    final formatted = buffer.toString();
    final selection = _mapSelection(newValue.selection, newValue.text, formatted);
    return TextEditingValue(text: formatted, selection: selection);
  }

  static TextSelection _mapSelection(
    TextSelection selection,
    String raw,
    String formatted,
  ) {
    final digitsBefore = raw
        .substring(0, selection.baseOffset.clamp(0, raw.length))
        .replaceAll(RegExp(r'\D'), '')
        .length;
    var offset = 0;
    var digitCount = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (formatted[i] != ' ') {
        digitCount++;
      }
      offset = i + 1;
      if (digitCount >= digitsBefore) {
        break;
      }
    }
    if (digitsBefore == 0) {
      offset = 0;
    }
    return TextSelection.collapsed(offset: offset.clamp(0, formatted.length));
  }
}
