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

class _AuthMpinSetupStepState extends State<AuthMpinSetupStep> {
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  void didUpdateWidget(covariant AuthMpinSetupStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSubmitting && widget.isSubmitting) {
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(child: _buildScrollableContent()),
          // The form scrolls. Verify stays in the column so the scaffold
          // can place it above the keyboard instead of removing it on focus.
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            authSidePadding(context),
            0,
            authSidePadding(context),
            authH(context, 16),
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
                    offset: Offset(-authW(context, 8), 0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 24.r,
                      color: _ink,
                      onPressed: widget.onBack,
                    ),
                  ),
                  SizedBox(height: authH(context, 16)),
                  Text(
                    'Create MPIN',
                    style: authTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: authH(context, 4)),
                  Text(
                    'Set a 4 digit MPIN to secure your eRupaiya wallet.',
                    style: authTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: authMuted,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: authH(context, 22)),
                  const AuthCodeLabel('Add New Pin'),
                  SizedBox(height: authH(context, 6)),
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
                  SizedBox(height: authH(context, 12)),
                  const AuthCodeLabel('Confirm Pin'),
                  SizedBox(height: authH(context, 6)),
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
                    SizedBox(height: authH(context, 12)),
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
        authSidePadding(context),
        authH(context, 8),
        authSidePadding(context),
        authH(context, 16),
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
