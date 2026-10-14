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
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.white),
        const AuthBackgroundImage(),
        SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildScrollableContent()),
              _buildFooter(),
            ],
          ),
        ),
      ],
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
                    enabled: !widget.isSubmitting,
                    hasError: _hasError,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    onChanged: widget.onPinChanged,
                    onCompleted: widget.onNewPinCompleted,
                  ),
                  SizedBox(height: 12.h),
                  const AuthCodeLabel('Confirm Pin'),
                  SizedBox(height: 6.h),
                  AuthPinRowWithToggle(
                    controller: widget.confirmPinController,
                    focusNode: widget.confirmPinFocusNode,
                    obscure: _obscureConfirm,
                    enabled: !widget.isSubmitting,
                    hasError: _hasError,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    onChanged: widget.onPinChanged,
                    onCompleted: widget.onConfirmPinCompleted,
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
