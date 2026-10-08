import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';
import '../models/spin_reward.dart';

/// Reward-segment colour for the wheel centre circle (Figma).
const Color kSpinRewardSegmentColor = Color(0xFFDD5428);

/// Figma: linear-gradient(169.27deg, #FD8818 7.96%, #FED06A 47.53%,
/// #F68811 87.09%). Applied per orange slice.
const List<Color> kSpinSliceGradientColors = [
  Color(0xFFFD8818),
  Color(0xFFFED06A),
  Color(0xFFF68811),
];
const List<double> kSpinSliceGradientStops = [0.0796, 0.4753, 0.8709];
const double kSpinSliceGradientAngleDeg = 169.27;

/// Ring around the wheel: #CF6716 (top) -> #E1BE31 (bottom).
const LinearGradient kSpinWheelBorderGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFCF6716), Color(0xFFE1BE31)],
);

/// E-Coin icon shown before the "xx E-Coins" text.
const String _coinSvg = '''
<svg width="26" height="26" viewBox="0 0 26 26" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M21.4226 16.0535C23.4769 11.512 21.46 6.1648 16.9177 4.11013C12.3754 2.05547 7.02786 4.07142 4.97355 8.61288C2.91925 13.1544 4.93615 18.5016 9.47842 20.5562C14.0207 22.6109 19.3683 20.595 21.4226 16.0535Z" fill="#1B1B25"/>
<path d="M20.1687 16.5291C22.223 11.9876 20.2061 6.64038 15.6638 4.58571C11.1215 2.53104 5.77395 4.547 3.71965 9.08847C1.66534 13.6299 3.68224 18.9772 8.22451 21.0318C12.7668 23.0865 18.1144 21.0705 20.1687 16.5291Z" fill="#F39207"/>
<path d="M18.5765 15.8083C16.9242 19.4612 12.6073 21.086 8.9569 19.4348C5.30648 17.7835 3.6778 13.4655 5.32875 9.81576C6.9797 6.16599 11.298 4.53806 14.9484 6.18931C18.5988 7.84055 20.2275 12.1585 18.5765 15.8083ZM5.75579 10.0089C4.21071 13.4247 5.7337 17.4624 9.15004 19.0078C12.5664 20.5531 16.6044 19.0309 18.1495 15.6151C19.6946 12.1994 18.1716 8.16163 14.7553 6.61627C11.3389 5.07092 7.30088 6.5932 5.75579 10.0089Z" fill="#FCF0E3"/>
<path d="M12.7476 10.1174C12.9368 10.2152 13.114 10.3397 13.2742 10.4937C13.6695 10.8733 13.892 11.3631 13.9561 11.8865C13.9773 12.06 14.0012 12.2513 13.9721 12.4223C13.9556 12.5943 13.9188 12.764 13.8598 12.9258C13.786 13.1283 13.6764 13.3173 13.5322 13.4787C13.1181 13.9423 12.4794 14.1461 11.8713 14.3311C11.8117 14.2727 11.7522 14.2143 11.6927 14.1558C11.7862 13.977 11.8811 13.7936 11.905 13.5924C11.9288 13.3912 11.8678 13.1654 11.6998 13.0379C11.5196 13.436 11.3392 13.8343 11.159 14.2324C11.08 14.1573 11.001 14.0821 10.9219 14.007C11.0857 13.6453 11.2496 13.2836 11.4134 12.922C11.1613 12.8434 10.9008 13.0136 10.7638 13.2253C10.6269 13.437 10.5692 13.6903 10.4448 13.9095C10.3681 13.8354 10.2915 13.7612 10.2148 13.6872C10.5055 13.0446 10.7962 12.402 11.0869 11.7594C11.1635 11.8334 11.2401 11.9076 11.3166 11.9816C11.2091 12.219 11.1016 12.4565 10.9941 12.6938C11.1619 12.6088 11.3615 12.5815 11.5511 12.6176L11.794 12.0792C11.8731 12.1543 11.952 12.2295 12.031 12.3046C11.9668 12.4476 11.9024 12.5906 11.8381 12.7336C12.1932 13.0192 12.3152 13.5448 12.1163 13.9327C12.6089 13.6345 12.994 13.1423 13.0524 12.5754C13.0871 12.2385 13.0048 11.8884 12.8275 11.5891C12.6501 11.2896 12.3783 11.0414 12.0597 10.8877C11.7421 10.7346 11.3779 10.6761 11.0352 10.7322C10.5549 10.8109 10.1409 11.108 9.85169 11.4814C9.34154 12.1404 9.19761 13.0569 9.47891 13.859C9.76023 14.661 10.4593 15.3265 11.2916 15.5838C12.124 15.8413 13.0668 15.6832 13.7347 15.174C14.1929 14.8246 14.5127 14.3166 14.645 13.7622C14.7575 13.2909 14.7285 12.7901 14.5607 12.3245C14.5598 12.3221 14.5591 12.3197 14.5581 12.3174C14.5581 12.3174 15.5216 12.7533 15.5217 12.7533C15.6086 13.356 15.5321 13.983 15.2664 14.5705C14.4892 16.2893 12.3887 17.0149 10.5899 16.1786C8.80183 15.3471 8.0032 13.3038 8.799 11.6005C8.96024 11.2555 9.18609 10.9402 9.46017 10.6727C10.026 10.1205 10.8419 9.77432 11.6688 9.83054C12.0498 9.85643 12.4173 9.94656 12.7476 10.1174Z" fill="white"/>
</svg>
''';

/// Surprise gift-box icon (inline, same 26x26 viewBox as the coin icon).
const String _surpriseSvg = '''
<svg width="26" height="26" viewBox="0 0 26 26" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="5" y="13" width="16" height="10" rx="1.5" fill="#F39207"/>
<rect x="3" y="9" width="20" height="5" rx="1.5" fill="#DD5428"/>
<rect x="11.5" y="9" width="3" height="14" fill="#FCF0E3"/>
<path d="M13 9C13 9 8 9 8 6.2C8 4 11.3 4 13 9Z" fill="#FCF0E3"/>
<path d="M13 9C13 9 18 9 18 6.2C18 4 14.7 4 13 9Z" fill="#FCF0E3"/>
<rect x="5" y="13" width="16" height="10" rx="1.5" stroke="#1B1B25" stroke-width="1"/>
<rect x="3" y="9" width="20" height="5" rx="1.5" stroke="#1B1B25" stroke-width="1"/>
</svg>
''';

class SpinWheel extends StatelessWidget {
  const SpinWheel({
    super.key,
    required this.rewards,
    required this.rotation,
    this.size = 260,
    this.borderWidth,
  });

  final List<SpinReward> rewards;
  final double rotation;

  /// Outer diameter including the gradient ring.
  final double size;

  /// Ring thickness; defaults to the 10px reference scaled with `.r`.
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    final ring = borderWidth ?? 10.r;
    final inner = math.max(0.0, size - 2 * ring);
    final radius = inner / 2;
    final count = rewards.length;
    final sweep = count == 0 ? 0.0 : (2 * math.pi) / count;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(ring),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: kSpinWheelBorderGradient,
          ),
          child: ClipOval(
            child: SizedBox(
              width: inner,
              height: inner,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating layer: slices + labels.
                  Transform.rotate(
                    angle: rotation,
                    child: SizedBox(
                      width: inner,
                      height: inner,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size.square(inner),
                            painter: _WheelPainter(count: count),
                          ),
                          for (var i = 0; i < count; i++)
                            Transform.rotate(
                              // Slice mid-angle, clockwise from the top pin.
                              angle: (i + 0.5) * sweep - math.pi / 2,
                              child: SizedBox(
                                width: inner,
                                height: inner,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: radius * 0.07,
                                    ),
                                    child: SizedBox(
                                      width: radius * 0.62,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: _SliceLabel(
                                          reward: rewards[i],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // CSS `inset 0 11px 27px 25px #DD54281A` equivalent.
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment(0, -0.07),
                            radius: 0.72,
                            colors: [
                              Color(0x00DD5428),
                              Color(0x00DD5428),
                              Color(0x1ADD5428),
                            ],
                            stops: [0.0, 0.62, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Figma centre: navy (#292C4F) disc, white inner circle,
                  // gold rupee mark.
                  Container(
                    width: inner * 0.30,
                    height: inner * 0.30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF292C4F),
                      border: Border.all(
                        color: const Color(0xFF292C4F),
                        width: 2.r,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: inner * 0.13,
                        height: inner * 0.13,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            FileConstants.spinRupeeSvg,
                            width: inner * 0.075,
                            height: inner * 0.08,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Fixed gold location pin at the top-centre.
        Positioned(
          top: -6.r,
          left: 0,
          right: 0,
          child: Center(
            child: SvgPicture.asset(
              FileConstants.spinPointerSvg,
              width: 27.r,
              height: 33.r,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
              const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

/// One slice label. Reads from the centre outward: [icon] + text.
class _SliceLabel extends StatelessWidget {
  const _SliceLabel({required this.reward});

  final SpinReward reward;

  static const double _fontSize = 12;
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    late Widget icon;
    String text;

    switch (reward.type) {
      case SpinRewardType.coins:
        icon = SvgPicture.string(
          _coinSvg,
          width: _iconSize,
          height: _iconSize,
        );
        text = '${reward.coins} E-Coins';
        break;
      case SpinRewardType.surprise:
        icon = SvgPicture.string(
          _surpriseSvg,
          width: _iconSize,
          height: _iconSize,
        );
        text = 'Surprise';
        break;
      case SpinRewardType.extraSpin:
        icon = _emoji('🔄');
        text = 'Extra Spin';
        break;
      case SpinRewardType.jackpot:
        icon = _emoji('🎉');
        text = 'Jackpot Spin';
        break;
      case SpinRewardType.betterLuck:
        icon = _emoji('😂');
        text = 'Better Luck';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _emoji(String e) => Text(
    e,
    style: const TextStyle(fontSize: 14, height: 1.0),
  );
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.count});

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    if (count == 0) return;
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = (2 * math.pi) / count;

    // CSS 169.27deg -> direction vector (sin a, -cos a).
    const a = kSpinSliceGradientAngleDeg * math.pi / 180;
    final dx = math.sin(a);
    final dy = -math.cos(a);

    for (var i = 0; i < count; i++) {
      final start = -math.pi / 2 + i * sweep;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(rect, start, sweep, false)
        ..close();

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      // Figma order from the pin, clockwise: white, gradient, white,
      // gradient ... (10 W, 25 G, 50 W, 100 G, Surprise W, Extra G,
      // Jackpot W, Better Luck G). No divider lines.
      //
      // The orange ramp is painted ONCE across the whole wheel (shader rect
      // = the full wheel `rect`, not each slice's own bounds). A single
      // continuous 169deg gradient makes each slice a uniform slice of the
      // wheel-wide ramp, matching the Figma reference.
      if (i.isEven) {
        paint.color = Colors.white;
      } else {
        paint.shader = LinearGradient(
          begin: Alignment(-dx, -dy),
          end: Alignment(dx, dy),
          colors: kSpinSliceGradientColors,
          stops: kSpinSliceGradientStops,
        ).createShader(rect);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.count != count;
}