import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_snackbar.dart';

/// Centralized clipboard security gate (app-wide sensitive-data policy).
///
/// EVERY clipboard write in the app must go through [SecureClipboard.copy].
/// If the text contains a PAN, Aadhaar number, bank account number (labelled
/// or formatted) or IFSC code, the copy is blocked and the user sees a simple
/// security message instead. Non-sensitive values (transaction references,
/// referral links, etc.) copy exactly as before.
///
/// Deliberate design choices:
/// * No background clipboard monitoring and no clearing of the user's
///   existing clipboard content.
/// * Sensitive text is NEVER logged during validation — only the boolean
///   verdict is used.
/// * Validation is best-effort pattern matching (see [containsSensitiveData]
///   limitations in the AUD-038 follow-up report); it replaces the copy
///   operation itself, not just the copy icons.
class SecureClipboard {
  SecureClipboard._();

  /// Message shown when a copy is blocked. Kept in one place so every screen
  /// behaves identically.
  static const String blockedMessage =
      'Sensitive information cannot be copied for security reasons.';

  // PAN: 5 letters + 4 digits + 1 letter (e.g. ABCDE1234F). The negative
  // look-around keeps a longer alphanumeric order id from falsely matching.
  static final RegExp _pan =
      RegExp(r'(?<![A-Za-z0-9])[A-Z]{5}[0-9]{4}[A-Z](?![A-Za-z0-9])');

  // IFSC: 4 letters + '0' + 6 DIGITS (e.g. HDFC0001234). The strict digit
  // tail also matches legacy 4+7 forms like SBIN0001234 / SBIN1122334 while
  // avoiding false hits on UPI IDs such as NAME@OKHDFCBANK.
  static final RegExp _ifsc =
      RegExp(r'(?<![A-Za-z0-9])[A-Z]{4}0\d{6}(?![A-Za-z0-9])');

  // Aadhaar: 12 digits starting 2-9 in the canonical grouped formats
  // (2345 6789 0123 / 2345-6789-0123). Separators are REQUIRED here so a
  // plain 12-digit RRN/UTR transaction reference is not falsely blocked;
  // unformatted Aadhaar is still caught by the labelled-account rule.
  static final RegExp _aadhaar = RegExp(r'\b[2-9]\d{3}[ -]\d{4}[ -]\d{4}\b');

  // Contextual detection of raw values that appear with an identity/banking
  // label: a hint keyword together with a 9-20 digit run or a PAN-shaped
  // token (e.g. "Account No: 50100123456789", "Aadhaar: 234567890123").
  static final RegExp _accountHint =
      RegExp(r'aadhaar|aadhar|ifsc|\bpan\b|account', caseSensitive: false);
  static final RegExp _longDigitRun = RegExp(r'\d{9,20}');

  /// Returns true when [text] contains (or is) a sensitive identity or
  /// banking value that must never leave the app via the clipboard.
  static bool containsSensitiveData(String text) {
    if (text.isEmpty) return false;
    // PAN/IFSC are canonically upper-case; normalise case for those checks
    // only (digit/aadhaar matching is case-insensitive already by nature).
    final upper = text.toUpperCase();
    if (_pan.hasMatch(upper)) return true;
    if (_ifsc.hasMatch(upper)) return true;
    if (_aadhaar.hasMatch(text)) return true;
    if (_accountHint.hasMatch(text) && _longDigitRun.hasMatch(text)) {
      return true;
    }
    return false;
  }

  /// Copies [text] to the system clipboard ONLY when it is free of sensitive
  /// values. Returns true when the clipboard was written.
  ///
  /// When blocked, shows [blockedMessage] and performs NO clipboard write —
  /// whatever the user previously copied (from this or any other app) stays
  /// untouched.
  static Future<bool> copy(String text) async {
    if (containsSensitiveData(text)) {
      AppSnackbar.show(blockedMessage);
      return false;
    }
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  }

  /// `contextMenuBuilder` for identity/banking entry fields (PAN, Aadhaar,
  /// account number, IFSC).
  ///
  /// Flutter's built-in selection toolbar writes straight to the clipboard
  /// and would otherwise bypass [SecureClipboard.copy] for values the USER
  /// types himself. This builder removes the COPY and CUT buttons (cut also
  /// copies) while keeping Select-all / Paste UX intact.
  static Widget sensitiveFieldContextMenu(
      BuildContext context, EditableTextState state) {
    final items = state.contextMenuButtonItems
        .where((item) =>
            item.type != ContextMenuButtonType.copy &&
            item.type != ContextMenuButtonType.cut)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: items,
    );
  }
}
