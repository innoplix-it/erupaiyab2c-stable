import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../services/phone_hint_service.dart';

/// Android phone-number hint: once on mount, again when the user taps an empty
/// field ([onEmptyFieldTap]). Avoids focus-listener loops that reopen the sheet
/// and jank the login step.
VoidCallback useLoginPhoneHint({
  required TextEditingController phoneController,
  required FocusNode mobileFocusNode,
  required bool enabled,
}) {
  final inFlight = useRef(false);

  Future<void> showKeyboard() async {
    // The hint activity returns before the Flutter view has window focus.
    // requestFocus / TextInput.show in that moment is dropped, so the number
    // fills and the form stays at the bottom. Wait until we are resumed, then
    // open the keyboard again.
    final binding = WidgetsBinding.instance;
    if (binding.lifecycleState != AppLifecycleState.resumed) {
      final resumed = Completer<void>();
      final listener = AppLifecycleListener(
        onResume: () {
          if (!resumed.isCompleted) resumed.complete();
        },
      );
      try {
        await resumed.future.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        // The sheet may already have resumed without a lifecycle event.
      } finally {
        listener.dispose();
      }
    }
    if (!enabled) return;
    final frame = Completer<void>();
    binding.addPostFrameCallback((_) {
      if (!frame.isCompleted) frame.complete();
    });
    await frame.future;
    if (!enabled) return;
    mobileFocusNode.requestFocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!enabled) return;
    if (!mobileFocusNode.hasFocus) mobileFocusNode.requestFocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  Future<void> request() async {
    if (!enabled) return;
    if (phoneController.text.trim().isNotEmpty) return;
    if (inFlight.value) return;
    inFlight.value = true;
    try {
      // Do not focus while the number sheet is up, so the form stays at the
      // bottom. After the user picks a number or dismisses the sheet, open
      // the keyboard and the Figma lifted layout follows focus.
      final hint = await PhoneHintService.getPhoneNumberHint();
      if (!enabled) return;
      if (hint != null && phoneController.text.trim().isEmpty) {
        final digits = hint.replaceAll(RegExp(r'\D'), '');
        final normalized =
            digits.length > 10 ? digits.substring(digits.length - 10) : digits;
        if (normalized.length == 10) {
          phoneController.text = normalized;
        }
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        await showKeyboard();
      }
    } finally {
      inFlight.value = false;
    }
  }

  final didAutoPrompt = useRef(false);

  useEffect(() {
    if (!enabled || didAutoPrompt.value) return null;
    didAutoPrompt.value = true;
    Future.microtask(request);
    return null;
  }, [enabled]);

  return request;
}
