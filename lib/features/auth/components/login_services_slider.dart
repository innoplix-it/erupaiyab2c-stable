import 'dart:math' as math;

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_svg/flutter_svg.dart';

/// Slow, seamless, staggered marquee of login service tiles.
///
/// Two layouts, both authored against Figma frames:
///  * default (keyboard closed): 4 rows, 100x100 tiles on a 440 frame.
///  * [compact] (keyboard open / short viewport): 2 larger rows, 117x117 tiles
///    on a 428 frame, shown faded behind the form.
///
/// Tile size is derived once from the screen width and used for BOTH width and
/// height, so tiles stay square. No `.w`/`.h` is used here (no double scaling).
///
/// Smoothness:
///  * One [Ticker] advances a travelled-distance value in px/sec, so the
///    speed is constant and independent of tile size. Switching between the
///    4-row and 2-row layout never restarts or jumps the marquee.
///  * Every row is a cached raster layer ([RepaintBoundary]) that is only
///    translated each frame; tiles are never rebuilt while animating.
///  * The built row content is cached per layout, so keyboard-animation
///    frames (which rebuild the parent every frame) do not rebuild tiles.
///  * 4 rows <-> 2 rows is cross-faded instead of snapping.
class LoginServicesSlider extends StatefulWidget {
  const LoginServicesSlider({
    super.key,
    this.height,
    this.rowCount = 4,
    this.compact = false,
    this.speed = 16,
    this.cycleDuration,
  });

  /// Optional fixed marquee height. When null, height follows the tile math
  /// (uniformly scaled down to fit the parent's constraints when needed).
  final double? height;

  /// Visible rows (max 4, or 2 when [compact]).
  final int rowCount;

  /// Keyboard-open Figma layout: larger tiles, 2-line labels, 2 rows.
  final bool compact;

  /// Scroll speed in Figma px/sec on a 440 wide frame (scaled to the real
  /// screen width). 16 is slow and calm; raise for faster movement.
  final double speed;

  /// No longer used (speed is px/sec now). Kept so old call sites compile.
  final Duration? cycleDuration;

  // ---- Default (keyboard closed) Figma frame: 440 wide ----
  static const double figmaFrameWidth = 440;
  static const double tileDesign = 100;
  static const double hGapDesign = 14;
  static const double vGapDesign = 18;
  static const double radiusDesign = 16;
  static const int maxRowCount = 4;

  /// Left edge (design units) of the first tile of each row (brick stagger).
  static const List<double> rowOffsetDesign = [45, 33, 81, 39];

  // ---- Compact (keyboard open) Figma frame: 428 wide ----
  static const double compactFrameWidth = 428;
  static const double compactTileDesign = 117;
  static const double compactHGapDesign = 23;
  static const double compactVGapDesign = 19;
  static const int compactMaxRowCount = 2;

  /// Row offsets in tile-100 units (row 1 starts with a clipped tile).
  static const List<double> compactRowOffsetDesign = [-47, 0];

  static double tileFor(double screenWidth, {bool compact = false}) => compact
      ? screenWidth * (compactTileDesign / compactFrameWidth)
      : screenWidth * (tileDesign / figmaFrameWidth);

  static double hGapFor(double screenWidth, {bool compact = false}) => compact
      ? screenWidth * (compactHGapDesign / compactFrameWidth)
      : screenWidth * (hGapDesign / figmaFrameWidth);

  static double vGapFor(double screenWidth, {bool compact = false}) => compact
      ? screenWidth * (compactVGapDesign / compactFrameWidth)
      : screenWidth * (vGapDesign / figmaFrameWidth);

  /// Natural (unshrunk) height for [rows] rows at [screenWidth].
  static double naturalHeight(
    double screenWidth,
    int rows, {
    bool compact = false,
  }) =>
      rows * tileFor(screenWidth, compact: compact) +
      (rows - 1) * vGapFor(screenWidth, compact: compact);

  @override
  State<LoginServicesSlider> createState() => _LoginServicesSliderState();
}

class _LoginServicesSliderState extends State<LoginServicesSlider>
    with SingleTickerProviderStateMixin {
  /// Total distance (px) the marquee has travelled. Shared by every row and
  /// by both layouts, so cross-fading layouts stay perfectly in phase.
  final ValueNotifier<double> _distance = ValueNotifier<double>(0);

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _pxPerSecond = 0;

  _SliderLayout? _layout;
  Widget? _content;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    // Clamp dt so a resumed (un-muted) ticker never causes a visible jump.
    final dt = ((elapsed - _lastElapsed).inMicroseconds /
            Duration.microsecondsPerSecond)
        .clamp(0.0, 0.1)
        .toDouble();
    _lastElapsed = elapsed;
    _distance.value += dt * _pxPerSecond;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = widget.compact;
    _pxPerSecond =
        widget.speed * (screenWidth / LoginServicesSlider.figmaFrameWidth);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxRows = compact
              ? LoginServicesSlider.compactMaxRowCount
              : LoginServicesSlider.maxRowCount;
          final rows = widget.rowCount.clamp(1, maxRows);

          var tileSize =
              LoginServicesSlider.tileFor(screenWidth, compact: compact);
          var hGap = LoginServicesSlider.hGapFor(screenWidth, compact: compact);
          var vGap = LoginServicesSlider.vGapFor(screenWidth, compact: compact);
          var naturalH = rows * tileSize + (rows - 1) * vGap;

          final budget = widget.height ??
              (constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : naturalH);

          // Uniform shrink only (tiles stay square, aspect never skewed).
          if (naturalH > budget && budget > 0) {
            final factor = budget / naturalH;
            tileSize *= factor;
            hGap *= factor;
            vGap *= factor;
            naturalH = budget;
          }

          final layout = _SliderLayout(
            compact: compact,
            rows: rows,
            tileSize: tileSize,
            hGap: hGap,
            vGap: vGap,
            viewWidth: constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : screenWidth,
            height: widget.height ?? naturalH,
          );

          // Re-create the (expensive) content only when the layout changes.
          // Same instance => Flutter skips rebuilding the tiles entirely.
          if (_content == null || layout != _layout) {
            _layout = layout;
            _content = KeyedSubtree(
              key: ValueKey<String>('${layout.compact}-${layout.rows}'),
              child: _SliderContent(layout: layout, distance: _distance),
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            // Previous child must not grow the Stack (otherwise compact→closed
            // transition reports a Column overflow at the tall closed height).
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              clipBehavior: Clip.hardEdge,
              children: <Widget>[
                for (final child in previous)
                  Positioned.fill(
                    child: ClipRect(child: child),
                  ),
                if (current != null) current,
              ],
            ),
            child: _content!,
          );
        },
      ),
    );
  }
}

/// Immutable geometry of one slider layout (used as cache key).
@immutable
class _SliderLayout {
  const _SliderLayout({
    required this.compact,
    required this.rows,
    required this.tileSize,
    required this.hGap,
    required this.vGap,
    required this.viewWidth,
    required this.height,
  });

  final bool compact;
  final int rows;
  final double tileSize;
  final double hGap;
  final double vGap;
  final double viewWidth;
  final double height;

  @override
  bool operator ==(Object other) =>
      other is _SliderLayout &&
      other.compact == compact &&
      other.rows == rows &&
      other.tileSize == tileSize &&
      other.hGap == hGap &&
      other.vGap == vGap &&
      other.viewWidth == viewWidth &&
      other.height == height;

  @override
  int get hashCode =>
      Object.hash(compact, rows, tileSize, hGap, vGap, viewWidth, height);
}

class _LoginTileSpec {
  const _LoginTileSpec({
    required this.label,
    this.svgAsset,
    this.pngAsset,
    this.iconAspect = 1,
  });

  final String label;
  final String? svgAsset;
  final String? pngAsset;
  final double iconAspect;
}

// NOTE: College Fees uses the tuition icon until a dedicated
// college_fees.svg (graduation-cap) asset is added to the project.
const String _collegeFeesSvg = 'assets/images/svg/services/tuition_fees.svg';

/// Four Figma rows (keyboard closed). 4 tiles = one seamless loop period.
final List<List<_LoginTileSpec>> _closedRows = [
  [
    _LoginTileSpec(
      label: 'Book LPG',
      pngAsset: FileConstants.gasCylinder,
      iconAspect: 48 / 84,
    ),
    _LoginTileSpec(
      label: 'Credit Card',
      pngAsset: FileConstants.credit,
      iconAspect: 77 / 61,
    ),
    _LoginTileSpec(
      label: 'Electricity',
      pngAsset: FileConstants.loginElectricityBillIcon,
    ),
    const _LoginTileSpec(
      label: 'FASTag Recharge',
      svgAsset: 'assets/images/svg/services/fastag_recharge.svg',
    ),
  ],
  [
    _LoginTileSpec(
      label: 'Credit Card',
      pngAsset: FileConstants.credit,
      iconAspect: 77 / 61,
    ),
    const _LoginTileSpec(
      label: 'School Fees',
      svgAsset: 'assets/images/svg/services/school_fees.svg',
    ),
    const _LoginTileSpec(
      label: 'College Fees',
      svgAsset: _collegeFeesSvg,
      iconAspect: 33 / 35,
    ),
    const _LoginTileSpec(
      label: 'Mobile Prepaid',
      svgAsset: 'assets/images/svg/services/mobile_recharge.svg',
      iconAspect: 23 / 37,
    ),
  ],
  [
    const _LoginTileSpec(
      label: 'Shop Rent',
      svgAsset: 'assets/images/svg/services/shop_rent.svg',
      iconAspect: 40 / 36,
    ),
    const _LoginTileSpec(
      label: 'House Rent',
      svgAsset: 'assets/images/svg/services/house_rent.svg',
      iconAspect: 42 / 36,
    ),
    const _LoginTileSpec(
      label: 'Gym',
      svgAsset: 'assets/images/svg/services/gym_membership.svg',
    ),
    const _LoginTileSpec(
      label: 'Tuition Fees',
      svgAsset: 'assets/images/svg/services/tuition_fees.svg',
      iconAspect: 33 / 35,
    ),
  ],
  [
    _LoginTileSpec(
      label: 'Home Loan',
      pngAsset: FileConstants.homeLoans,
    ),
    _LoginTileSpec(
      label: 'Business Loan',
      pngAsset: FileConstants.businessLoans,
    ),
    _LoginTileSpec(
      label: 'Credit Card',
      pngAsset: FileConstants.credit,
      iconAspect: 77 / 61,
    ),
    _LoginTileSpec(
      label: 'Personal Loan',
      pngAsset: FileConstants.personalLoans,
    ),
  ],
];

/// Two Figma rows for the keyboard-open frame (full labels, 2-line wrap).
final List<List<_LoginTileSpec>> _compactRows = [
  [
    _LoginTileSpec(
      label: 'Book LPG',
      pngAsset: FileConstants.gasCylinder,
      iconAspect: 48 / 84,
    ),
    _LoginTileSpec(
      label: 'Electricity Bill',
      pngAsset: FileConstants.loginElectricityBillIcon,
    ),
    const _LoginTileSpec(
      label: 'Mobile Recharge',
      svgAsset: 'assets/images/svg/services/mobile_recharge.svg',
      iconAspect: 23 / 37,
    ),
    const _LoginTileSpec(
      label: 'FASTag Recharge',
      svgAsset: 'assets/images/svg/services/fastag_recharge.svg',
    ),
  ],
  [
    _LoginTileSpec(
      label: 'Credit Card',
      pngAsset: FileConstants.credit,
      iconAspect: 77 / 61,
    ),
    _LoginTileSpec(
      label: 'Electricity Bill',
      pngAsset: FileConstants.loginElectricityBillIcon,
    ),
    _LoginTileSpec(
      label: 'Book LPG',
      pngAsset: FileConstants.gasCylinder,
      iconAspect: 48 / 84,
    ),
    const _LoginTileSpec(
      label: 'Mobile Recharge',
      svgAsset: 'assets/images/svg/services/mobile_recharge.svg',
      iconAspect: 23 / 37,
    ),
  ],
];

/// All rows of one layout. Built once per [_SliderLayout].
class _SliderContent extends StatelessWidget {
  const _SliderContent({required this.layout, required this.distance});

  final _SliderLayout layout;
  final ValueListenable<double> distance;

  // Padding from Figma (top 4, right 10, bottom 4, left 6) on a 100 tile.
  static const double _padTopDesign = 4;
  static const double _padRightDesign = 10;
  static const double _padBottomDesign = 4;
  static const double _padLeftDesign = 6;

  /// Icon circle / artwork ratios from the tile SVG (viewBox 100).
  static const double _iconCircleRatio = 48.6 / 100;
  static const double _iconArtRatio = 30.6 / 100;

  static const Color _tileFill = Color(0x4DFFFFFF);
  static const Color _labelColor = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final compact = layout.compact;
    final source = compact ? _compactRows : _closedRows;
    final offsets = compact
        ? LoginServicesSlider.compactRowOffsetDesign
        : LoginServicesSlider.rowOffsetDesign;

    final tileSize = layout.tileSize;
    final scale = tileSize / LoginServicesSlider.tileDesign;
    final radius = LoginServicesSlider.radiusDesign * scale;
    final iconCircle = tileSize * _iconCircleRatio;
    final iconArt = tileSize * _iconArtRatio;
    final padding = EdgeInsets.fromLTRB(
      _padLeftDesign * scale,
      _padTopDesign * scale,
      _padRightDesign * scale,
      _padBottomDesign * scale,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final height =
            maxH.isFinite ? math.min(layout.height, maxH) : layout.height;
        // Clip + unconstrained OverflowBox so AnimatedSwitcher previous
        // children never report Column overflow when the stack shrinks.
        return SizedBox(
          height: height,
          width: double.infinity,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: double.infinity,
              minHeight: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var r = 0; r < layout.rows; r++) ...[
                    if (r > 0) SizedBox(height: layout.vGap),
                    _MarqueeRow(
                      distance: distance,
                      specs: source[r],
                      viewWidth: layout.viewWidth,
                      tileSize: tileSize,
                      gap: layout.hGap,
                      offset: offsets[r % offsets.length] * scale,
                      iconCircle: iconCircle,
                      iconArt: iconArt,
                      radius: radius,
                      padding: padding,
                      tileFill: _tileFill,
                      labelColor: _labelColor,
                      compact: compact,
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
}

/// One marquee row. Content is built once, rasterised once (RepaintBoundary)
/// and only translated on every tick.
///
/// Seamless loop: the tile pattern repeats every `specs.length` tiles
/// (= period). Wrapping the translation by exactly one period lands on an
/// identical picture, so there is no seam, jump or gap.
class _MarqueeRow extends StatelessWidget {
  const _MarqueeRow({
    required this.distance,
    required this.specs,
    required this.viewWidth,
    required this.tileSize,
    required this.gap,
    required this.offset,
    required this.iconCircle,
    required this.iconArt,
    required this.radius,
    required this.padding,
    required this.tileFill,
    required this.labelColor,
    required this.compact,
  });

  final ValueListenable<double> distance;
  final List<_LoginTileSpec> specs;
  final double viewWidth;
  final double tileSize;
  final double gap;

  /// Left edge of the first tile at distance 0 (may be negative).
  final double offset;
  final double iconCircle;
  final double iconArt;
  final double radius;
  final EdgeInsets padding;
  final Color tileFill;
  final Color labelColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final n = specs.length;
    final stride = tileSize + gap;
    final period = n * stride;

    // Translation is wrapped into [-period, 0), so tiles must cover
    // [-period, viewWidth]. +2 tiles of safety.
    final count = ((viewWidth + period) / stride).ceil() + 2;
    final rowWidth = count * stride - gap;

    final content = RepaintBoundary(
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        minWidth: 0,
        maxWidth: rowWidth + 2,
        minHeight: tileSize,
        maxHeight: tileSize,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) SizedBox(width: gap),
              _ServiceTile(
                spec: specs[i % n],
                size: tileSize,
                iconCircle: iconCircle,
                iconArt: iconArt,
                radius: radius,
                padding: padding,
                tileFill: tileFill,
                labelColor: labelColor,
                compact: compact,
              ),
            ],
          ],
        ),
      ),
    );

    return SizedBox(
      width: viewWidth,
      height: tileSize,
      child: AnimatedBuilder(
        animation: distance,
        child: content,
        builder: (context, child) {
          // Dart `%` is Euclidean: result is always in [0, period).
          final dx = ((offset - distance.value) % period) - period;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.spec,
    required this.size,
    required this.iconCircle,
    required this.iconArt,
    required this.radius,
    required this.padding,
    required this.tileFill,
    required this.labelColor,
    required this.compact,
  });

  final _LoginTileSpec spec;
  final double size;
  final double iconCircle;
  final double iconArt;
  final double radius;
  final EdgeInsets padding;
  final Color tileFill;
  final Color labelColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    double artW = iconArt;
    double artH = iconArt;
    if (spec.iconAspect >= 1) {
      artH = iconArt / spec.iconAspect;
    } else {
      artW = iconArt * spec.iconAspect;
    }

    // Default: Plus Jakarta Sans SemiBold 10px on a 100 tile (ratio 0.10).
    // Compact (keyboard open): smaller 2-line label (ratio ~0.07).
    final labelSize = size * (compact ? 0.07 : 0.10);
    final topGap = size * (compact ? 0.08 : 0.11);
    final labelGap = size * (compact ? 0.05 : 0.10);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tileFill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              SizedBox(height: topGap),
              Container(
                width: iconCircle,
                height: iconCircle,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Colors.white, Color(0xFFEEF3FD)],
                  ),
                  border: Border.all(
                    color: const Color(0x4DFFFFFF),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: SizedBox(
                  width: artW,
                  height: artH,
                  child: _TileIcon(spec: spec),
                ),
              ),
              SizedBox(height: labelGap),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    // Compact: narrow box so "Electricity Bill" wraps to 2 lines.
                    width: compact ? size * 0.56 : null,
                    child: Text(
                      _capitalizeLabel(spec.label),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: labelSize,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                        height: 1.0,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// CSS-style capitalize, keeping known acronyms (FASTag, LPG).
  static String _capitalizeLabel(String raw) {
    return raw.split(' ').map((word) {
      if (word.isEmpty) return word;
      final lower = word.toLowerCase();
      if (lower == 'fastag') return 'FASTag';
      if (lower == 'lpg') return 'LPG';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.spec});

  final _LoginTileSpec spec;

  @override
  Widget build(BuildContext context) {
    if (spec.svgAsset != null) {
      return SvgPicture.asset(
        spec.svgAsset!,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
    }
    return Image.asset(
      spec.pngAsset!,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
  }
}
