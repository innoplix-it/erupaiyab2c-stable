import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'auth_code_fields.dart';
import 'auth_step_parts.dart';

const Color _ink = Color(0xFF09090B);

/// Create MPIN layout from the Figma spec. Presentation only: submit, back
/// navigation and PIN validation are owned by the caller.
class AuthMpinSetupStep extends StatefulWidget {
  const AuthMpinSetupStep({
    super.key,
    required this.newPinController,
    required this.confirmPinController,
    required this.newPinFocusNode,
    required this.confirmPinFocusNode,
    required this.onBack,
    required this.onSubmit,
    this.pinLength = 4,
    this.errorText,
    this.isSubmitting = false,
    this.onPinChanged,
    this.onNewPinCompleted,
    this.onConfirmPinCompleted,
  });

  final TextEditingController newPinController;
  final TextEditingController confirmPinController;
  final FocusNode newPinFocusNode;
  final FocusNode confirmPinFocusNode;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final int pinLength;
  final String? errorText;
  final bool isSubmitting;
  final ValueChanged<String>? onPinChanged;
  final ValueChanged<String>? onNewPinCompleted;
  final ValueChanged<String>? onConfirmPinCompleted;

  @override
  State<AuthMpinSetupStep> createState() => _AuthMpinSetupStepState();
}

class _AuthMpinSetupStepState extends State<AuthMpinSetupStep>
    with WidgetsBindingObserver {
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  /// Keeps keypad layout / hides footer while Verify is processing.
  bool _keepLifted = false;
  bool _hadKeyboard = false;

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.newPinFocusNode.addListener(_onFocusChanged);
    widget.confirmPinFocusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AuthMpinSetupStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.newPinFocusNode != widget.newPinFocusNode) {
      oldWidget.newPinFocusNode.removeListener(_onFocusChanged);
      widget.newPinFocusNode.addListener(_onFocusChanged);
    }
    if (oldWidget.confirmPinFocusNode != widget.confirmPinFocusNode) {
      oldWidget.confirmPinFocusNode.removeListener(_onFocusChanged);
      widget.confirmPinFocusNode.addListener(_onFocusChanged);
    }
    if (!oldWidget.isSubmitting && widget.isSubmitting) {
      _keepLifted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isSubmitting) return;
        final focused = FocusManager.instance.primaryFocus;
        if (focused is FocusNode) {
          showAuthKeyboard(focused);
        } else if (widget.confirmPinFocusNode.hasFocus) {
          showAuthKeyboard(widget.confirmPinFocusNode);
        } else {
          showAuthKeyboard(widget.newPinFocusNode);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.newPinFocusNode.removeListener(_onFocusChanged);
    widget.confirmPinFocusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (widget.newPinFocusNode.hasFocus ||
        widget.confirmPinFocusNode.hasFocus) {
      _keepLifted = true;
    }
    setState(() {});
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final inset = View.maybeOf(context)?.viewInsets.bottom ?? 0;
    if (inset > 0) {
      _hadKeyboard = true;
      _keepLifted = true;
    } else if (_hadKeyboard) {
      _hadKeyboard = false;
      if (widget.isSubmitting) {
        setState(() {});
        return;
      }
      final anyFocused = widget.newPinFocusNode.hasFocus ||
          widget.confirmPinFocusNode.hasFocus;
      if (!anyFocused) _keepLifted = false;
      setState(() {});
    }
  }

  bool get _lifted {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0 ||
        (View.maybeOf(context)?.viewInsets.bottom ?? 0) > 0;
    final anyFocused =
        widget.newPinFocusNode.hasFocus || widget.confirmPinFocusNode.hasFocus;
    return keyboardOpen || anyFocused || widget.isSubmitting || _keepLifted;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(child: _buildScrollableContent()),
          // Figma Create MPIN: no bottom CTA while keypad is up or while
          // Verify is processing so content does not drop.
          if (!_lifted) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            authHorizontalPadding,
            0,
            authHorizontalPadding,
            16.h,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: authContentMaxWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    // Lines the arrow glyph up with the content edge while
                    // keeping the full 48dp tap target.
                    offset: Offset(-8.w, 0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 24.r,
                      color: _ink,
                      onPressed: widget.onBack,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Create MPIN',
                    style: authTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Set a 4 digit MPIN to secure your eRupaiya wallet.',
                    style: authTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: authMuted,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  const AuthCodeLabel('Add New Pin'),
                  SizedBox(height: 6.h),
                  AuthPinRowWithToggle(
                    controller: widget.newPinController,
                    focusNode: widget.newPinFocusNode,
                    obscure: _obscureNew,
                    autofocus: true,
                    enabled: true,
                    hasError: _hasError,
                    onToggle: widget.isSubmitting
                        ? () {}
                        : () => setState(() => _obscureNew = !_obscureNew),
                    onChanged: widget.isSubmitting ? null : widget.onPinChanged,
                    onCompleted:
                        widget.isSubmitting ? null : widget.onNewPinCompleted,
                  ),
                  SizedBox(height: 12.h),
                  const AuthCodeLabel('Confirm Pin'),
                  SizedBox(height: 6.h),
                  AuthPinRowWithToggle(
                    controller: widget.confirmPinController,
                    focusNode: widget.confirmPinFocusNode,
                    obscure: _obscureConfirm,
                    enabled: true,
                    hasError: _hasError,
                    onToggle: widget.isSubmitting
                        ? () {}
                        : () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                    onChanged: widget.isSubmitting ? null : widget.onPinChanged,
                    onCompleted: widget.isSubmitting
                        ? null
                        : widget.onConfirmPinCompleted,
                  ),
                  if (_hasError) ...[
                    SizedBox(height: 12.h),
                    Text(
                      widget.errorText!,
                      style: authTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        authHorizontalPadding,
        8.h,
        authHorizontalPadding,
        16.h,
      ),
      child: ListenableBuilder(
        listenable: Listenable.merge(
          [widget.newPinController, widget.confirmPinController],
        ),
        builder: (context, _) {
          final complete =
              widget.newPinController.text.length == widget.pinLength &&
                  widget.confirmPinController.text.length == widget.pinLength;
          return AuthPrimaryButton(
            label: 'Verify',
            enabled: complete && !widget.isSubmitting,
            onPressed: widget.onSubmit,
            isLoading: widget.isSubmitting,
          );
        },
      ),
    );
  }
}
