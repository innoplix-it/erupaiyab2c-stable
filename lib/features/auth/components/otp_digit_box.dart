import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/core/barrel_file.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OtpDigitBox extends StatelessWidget {
  const OtpDigitBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.isError = false,
    this.isFilled = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool isError;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final borderColor = isError
        ? Colors.red
        : isFilled
            ? AppColors.primary
            : const Color(0xFFD9D9D9);

    return SizedBox(width: 40.r,
      height: 40.r,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: false,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: borderColor, width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
                color: isError ? Colors.red : AppColors.primary, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Colors.red, width: 1.4),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
