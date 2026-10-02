import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable widget for rendering service SVG icons.
class CommonServiceSvgIcon extends StatelessWidget {
  const CommonServiceSvgIcon({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.colorFilter,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      colorFilter: colorFilter,
    );
  }
}
