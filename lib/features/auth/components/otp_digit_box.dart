import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/core/barrel_file.dart';

class OtpDigitBox extends StatelessWidget {
  const OtpDigitBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.width,
    this.height,
    this.isError = false,
    this.isFilled = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final double? width;
  final double? height;
  final bool isError;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final borderColor = isError
        ? Colors.red
        : isFilled
            ? AppColors.primary
            : const Color(0xFFD9D9D9);

    final screenW = MediaQuery.sizeOf(context).width;
    final box = screenW * (48 / 360);
    return SizedBox(
      width: width ?? box.clamp(36.0, 56.0),
      height: height ?? box.clamp(36.0, 56.0),
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
