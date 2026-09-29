import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// Figma frame values (440px wide reference) for the Home bottom bar.
abstract final class HomeBottomNavMetrics {
  static const double figmaWidth = 440;
  static const double figmaPaddingH = 20;
  static const double figmaGap = 22;
  static const Duration tapAnimationDuration = Duration(seconds: 2);
  static const Color activeLabel = Color(0xFF000000);
  static const Color inactiveLabel = Color(0xFF6D6D6D);

  static double iconSize() => (24.r).clamp(20.0, 24.0);
  static double spinSize() => (46.r).clamp(40.0, 46.0);
  static double paddingV() => (16.h).clamp(12.0, 16.0);
  static double iconLabelGap() => (8.h).clamp(6.0, 8.0);
  static double fontSize() => (14.sp).clamp(12.0, 14.0);

  static TextStyle labelStyle(Color color) {
    final size = fontSize();
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1,
      letterSpacing: -0.02 * size,
      color: color,
    );
  }

  /// persistent_bottom_nav_bar renders the bar with `TextScaler.noScaling`,
  /// so the label box follows the raw font size.
  static double labelBoxHeight() => fontSize() + 2;

  /// Bar height excluding the system inset (80 on the Figma reference).
  static double barHeight() {
    final itemHeight = iconSize() + iconLabelGap() + labelBoxHeight();
    final content = itemHeight > spinSize() ? itemHeight : spinSize();
    return paddingV() * 2 + content;
  }

  /// Five equal slots whose centres match Figma's 20px padding + 22px gaps:
  /// each slot absorbs half a gap on either side, so the outer inset is
  /// `20 - 22 / 2` scaled to the real screen width.
  static double rowInset(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / figmaWidth;
    return (figmaPaddingH - figmaGap / 2) * scale;
  }
}

class HomeBottomNavEntry {
  const HomeBottomNavEntry({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.animationAsset,
  });

  final String label;
  final Widget activeIcon;
  final Widget inactiveIcon;
  final String animationAsset;
}

/// Fixed Home bottom bar: four animated items with a label-less Spin & Win
/// button in the centre.
class HomeBottomNavBar extends StatefulWidget {
  const HomeBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.leading,
    required this.trailing,
    required this.onItemSelected,
    this.spinIndex = 2,
  }) : assert(leading.length == 2 && trailing.length == 2);

  final int selectedIndex;
  final List<HomeBottomNavEntry> leading;
  final List<HomeBottomNavEntry> trailing;
  final ValueChanged<int> onItemSelected;
  final int spinIndex;

  @override
  State<HomeBottomNavBar> createState() => _HomeBottomNavBarState();
}

class _HomeBottomNavBarState extends State<HomeBottomNavBar> {
  int? _animatingIndex;
  int _playSerial = 0;

  void _handleTap(int index) {
    if (index != widget.spinIndex) {
      setState(() {
        _animatingIndex = index;
        _playSerial++;
      });
    }
    widget.onItemSelected(index);
  }

  void _handlePlaybackEnd(int index) {
    if (_animatingIndex == index && mounted) {
      setState(() => _animatingIndex = null);
    }
  }

  Widget _item(HomeBottomNavEntry entry, int index) {
    return Expanded(
      child: AnimatedBottomNavItem(
        label: entry.label,
        activeIcon: entry.activeIcon,
        inactiveIcon: entry.inactiveIcon,
        animationAsset: entry.animationAsset,
        selected: widget.selectedIndex == index,
        playing: _animatingIndex == index,
        playSerial: _playSerial,
        onTap: () => _handleTap(index),
        onPlaybackEnd: () => _handlePlaybackEnd(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spinIndex = widget.spinIndex;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -6),
            blurRadius: 30,
          ),
        ],
      ),
      // PersistentTabView renders custom bars outside any Scaffold/Material,
      // so the items' ink effects need their own (transparent) Material.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: HomeBottomNavMetrics.rowInset(context),
            vertical: HomeBottomNavMetrics.paddingV(),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _item(widget.leading[0], 0),
              _item(widget.leading[1], 1),
              Expanded(
                child: SpinWinNavItem(onTap: () => _handleTap(spinIndex)),
              ),
              _item(widget.trailing[0], spinIndex + 1),
              _item(widget.trailing[1], spinIndex + 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon + label nav item that swaps its static icon for a one-shot Lottie
/// (≈2s) whenever [playing] turns on or [playSerial] changes while playing.
class AnimatedBottomNavItem extends StatefulWidget {
  const AnimatedBottomNavItem({
    super.key,
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.animationAsset,
    required this.selected,
    required this.playing,
    required this.playSerial,
    required this.onTap,
    required this.onPlaybackEnd,
  });

  final String label;
  final Widget activeIcon;
  final Widget inactiveIcon;
  final String animationAsset;
  final bool selected;
  final bool playing;
  final int playSerial;
  final VoidCallback onTap;
  final VoidCallback onPlaybackEnd;

  @override
  State<AnimatedBottomNavItem> createState() => _AnimatedBottomNavItemState();
}

class _AnimatedBottomNavItemState extends State<AnimatedBottomNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: HomeBottomNavMetrics.tapAnimationDuration,
  )..addStatusListener(_onStatus);

  @override
  void initState() {
    super.initState();
    if (widget.playing) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant AnimatedBottomNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing &&
        (!oldWidget.playing || oldWidget.playSerial != widget.playSerial)) {
      _controller.forward(from: 0);
    } else if (!widget.playing && oldWidget.playing) {
      _controller.reset();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controller.reset();
      widget.onPlaybackEnd();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = HomeBottomNavMetrics.iconSize();
    final staticIcon = widget.selected ? widget.activeIcon : widget.inactiveIcon;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: InkResponse(
        onTap: widget.onTap,
        radius: iconSize * 1.6,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: iconSize,
              child: widget.playing
                  ? Lottie.asset(
                      widget.animationAsset,
                      controller: _controller,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                    )
                  : staticIcon,
            ),
            SizedBox(height: HomeBottomNavMetrics.iconLabelGap()),
            SizedBox(
              height: HomeBottomNavMetrics.labelBoxHeight(),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  textHeightBehavior: const TextHeightBehavior(
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
                  style: HomeBottomNavMetrics.labelStyle(
                    widget.selected
                        ? HomeBottomNavMetrics.activeLabel
                        : HomeBottomNavMetrics.inactiveLabel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centre Spin & Win button: icon only, no label.
class SpinWinNavItem extends StatelessWidget {
  const SpinWinNavItem({super.key, required this.onTap});

  final VoidCallback onTap;

  static const String svg =
      '<svg width="46" height="46" viewBox="0 0 46 46" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<rect width="46" height="46" rx="23" fill="#DD5428"/>'
      '<path d="M29.9939 32.6825C33.0224 30.4912 35 26.9209 35 22.8922C35 16.914 30.6461 11.9433 24.9572 10.9998L25.2155 10.4096C25.2548 10.3193 25.247 10.2155 25.1931 10.132C25.1392 10.0496 25.0482 10 24.9494 10H21.0495C20.9518 10 20.8597 10.0497 20.8058 10.132C20.7519 10.2144 20.7429 10.3193 20.7833 10.4096L21.0416 10.9998C15.3539 11.9431 11 16.914 11 22.8934C11 26.9264 12.982 30.5001 16.0174 32.6903L14.3453 35.5599C14.2925 35.6502 14.2925 35.7619 14.3441 35.8533C14.3958 35.9436 14.4924 36 14.5957 36H16.0971C16.1937 36 16.2835 35.9526 16.3374 35.8725L17.7759 33.7477C19.3559 34.5184 21.1291 34.9517 23 34.9517C24.8719 34.9517 26.644 34.5184 28.224 33.7477L29.6636 35.8725C29.7176 35.9526 29.8074 36 29.904 36H31.4054C31.5098 36 31.6053 35.9447 31.6569 35.8533C31.7086 35.763 31.7086 35.6513 31.6569 35.561L29.9939 32.6825ZM24.5048 10.5858L23 14.0252L21.4952 10.5858H24.5048ZM24.8259 22.8934C24.8259 23.9056 24.0062 24.7282 23 24.7282C21.9927 24.7282 21.174 23.9045 21.174 22.8934C21.174 21.8812 21.9938 21.0586 23 21.0586C24.0073 21.8823 24.8259 21.8823 24.8259 22.8934ZM21.0347 13.2002L22.5248 20.5214C22.2082 20.5858 21.914 20.711 21.6557 20.887L17.493 14.6953C18.5463 13.9787 19.7456 13.4642 21.0347 13.2012L21.0347 13.2002ZM14.7932 17.4328L20.993 21.5582C20.8212 21.8189 20.6977 22.1145 20.637 22.4327L13.3322 20.9996C13.5837 19.702 14.0903 18.497 14.7932 17.4328ZM14.9785 24.5137L20.6496 23.4124C20.7159 23.7137 20.836 23.9946 21.0022 24.2418L14.8338 28.4192C14.1185 27.3551 13.6042 26.1443 13.3436 24.8432L14.9776 24.5126L14.9785 24.5137ZM21.6701 24.9075C21.9296 25.0802 22.2227 25.2043 22.5393 25.2664L21.1086 32.6044C19.8172 32.3505 18.6168 31.8438 17.5589 31.1363L21.6712 24.9085L21.6701 24.9075ZM25.0198 32.5798L24.1821 28.8019L23.4746 25.2654C23.7902 25.2023 24.0833 25.0759 24.3416 24.9021L28.493 31.104C27.4577 31.8059 26.283 32.3148 25.0209 32.58L25.0198 32.5798ZM31.1983 28.3686L25.004 24.2318C25.177 23.9712 25.3005 23.6767 25.3623 23.3585L32.6628 24.8028C32.409 26.0994 31.9036 27.3055 31.1983 28.3686ZM27.7428 21.9232L25.3532 22.3836C25.2869 22.0766 25.1645 21.7911 24.9949 21.5395L31.1533 17.3531C31.8653 18.407 32.3807 19.6054 32.6446 20.8953L27.7428 21.9222L27.7428 21.9232ZM24.3256 20.876C24.0662 20.7033 23.772 20.5803 23.4564 20.5183L24.8736 13.1823C26.165 13.4328 27.3666 13.9372 28.4254 14.6424L24.3256 20.876ZM15.9416 35.4157H15.1016L16.4974 33.02C16.7445 33.1803 16.996 33.3337 17.2543 33.477L15.9416 35.4157ZM11.5811 22.8935C11.5811 17.1532 15.8001 12.3902 21.2846 11.5551L21.6979 12.4985C16.5604 13.145 12.5705 17.5584 12.5705 22.8934C12.5705 28.672 17.2497 33.3741 23.0005 33.3741C28.7512 33.3741 33.4304 28.672 33.4304 22.8934C33.4304 17.5581 29.4417 13.145 24.303 12.4985L24.7163 11.5551C30.2008 12.3901 34.4198 17.1532 34.4198 22.8935C34.4198 29.2205 29.2969 34.3674 23.0015 34.3674C16.7028 34.3674 11.5808 29.2196 11.5808 22.8935H11.5811ZM30.0573 35.4157L28.7446 33.4771C29.0074 33.3326 29.2623 33.1769 29.5127 33.0133L30.9007 35.4157H30.0573Z" fill="white"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    final size = HomeBottomNavMetrics.spinSize();
    return Semantics(
      button: true,
      label: 'Spin & Win',
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SvgPicture.string(svg, width: size, height: size),
        ),
      ),
    );
  }
}
