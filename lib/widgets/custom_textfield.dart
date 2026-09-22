import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatelessWidget {
  final String? labelText;
  final TextEditingController textEditingController;
  final FocusNode? focusNode;
  final bool enabled;
  final void Function(String)? onSubmitted;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final bool? obscureText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool isMandatory;
  final int? maxLines;
  final int? minLines;
  final bool showBorder;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    super.key,
    this.labelText,
    required this.enabled,
    required this.textEditingController,
    this.focusNode,
    this.onSubmitted,
    this.keyboardType,
    this.onChanged,
    this.suffixIcon,
    this.obscureText,
    this.validator,
    this.inputFormatters,
    this.isMandatory = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.showBorder = true,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: enabled,
      focusNode: focusNode,
      controller: textEditingController,
      keyboardType: keyboardType ?? TextInputType.text,
      decoration: _inputDecoration(),
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      obscureText: obscureText ?? false,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      minLines: minLines,
    );
  }

  InputDecoration _inputDecoration() {
    final radius = borderRadius ?? BorderRadius.circular(8.0.r);
    final border = showBorder
        ? OutlineInputBorder(borderRadius: radius)
        : InputBorder.none;
    return InputDecoration(
      labelText: isMandatory ? '$labelText *' : labelText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: fillColor ?? Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding,
    );
  }
}
