import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';

class AuthBrandHeader extends StatefulWidget {
  const AuthBrandHeader({
    super.key,
    this.title = 'Turn Every\nPayment\ninto Points.',
    this.subtitle =
        'Earn points\nevery time you\npay.\nYour payments,\nyour power.',
  });

  final String title;
  final String subtitle;

  @override
  State<AuthBrandHeader> createState() => _AuthBrandHeaderState();
}

class _AuthBrandHeaderState extends State<AuthBrandHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusTop = MediaQuery.paddingOf(context).top;
    final designTop = 32.h;
    return Padding(
      padding: EdgeInsets.only(
        top: statusTop > designTop ? statusTop : designTop,
        left: 20.w,
        right: 20.w,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final heroStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 40.sp,
                fontWeight: FontWeight.w700,
                height: 1.15,
              );

          final subtitleStyle =
              Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  );

          final titlePainter = TextPainter(
            text: TextSpan(text: widget.title, style: heroStyle),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: constraints.maxWidth);

          final subtitlePainter = TextPainter(
            text: TextSpan(text: widget.subtitle, style: subtitleStyle),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: constraints.maxWidth);

          final contentHeight =
              6.h + titlePainter.height + 6.h + subtitlePainter.height;

          return SizedBox(
            height: contentHeight,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Positioned(
                        top: -_animation.value * contentHeight,
                        left: 0,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 6.h),
                            _GradientText(
                              text: widget.title,
                              style: heroStyle,
                            ),
                            SizedBox(height: 6.h),
                            _GradientText(
                              text: widget.subtitle,
                              style: subtitleStyle,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: (1 - _animation.value) * contentHeight,
                        left: 0,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 6.h),
                            _GradientText(
                              text: widget.title,
                              style: heroStyle,
                            ),
                            SizedBox(height: 6.h),
                            _GradientText(
                              text: widget.subtitle,
                              style: subtitleStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return AppColors.heroTextGradient
            .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
      },
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: style?.copyWith(color: Colors.white),
      ),
    );
  }
}
