/// Standard PAN format: 5 letters, 4 digits, 1 letter (ABCDE1234F).
final RegExp _panFormatRegExp = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

/// True only for a complete, correctly formatted 10-character PAN.
///
/// Case is normalised the same way the verify APIs normalise it, so callers
/// can pass the raw text-field value.
bool isValidPanFormat(String value) =>
    _panFormatRegExp.hasMatch(value.trim().toUpperCase());

/// Aadhaar must be exactly 12 digits once display-only spaces are removed.
final RegExp _aadhaarFormatRegExp = RegExp(r'^\d{12}$');

/// True only when every digit of a 12-digit Aadhaar number has been entered.
bool isValidAadhaarNumber(String value) =>
    _aadhaarFormatRegExp.hasMatch(value.replaceAll(RegExp(r'\s+'), ''));

String maskPan(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.length <= 4) return trimmed;
  return '${trimmed.substring(0, 4)}****';
}

String maskAadhaar(String value) {
  final cleaned = value.replaceAll(RegExp(r'\s+'), '');
  if (cleaned.length <= 4) return cleaned;
  final start = cleaned.substring(0, 2);
  final end = cleaned.substring(cleaned.length - 4);
  return '$start******$end';
}
