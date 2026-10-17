import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Slow, seamless horizontal marquee of login service tiles.
///
/// Figma frame is 440×956 with 100×100 tiles. Project [ScreenUtilInit] uses
/// 360×690, so tile size is derived once from screen width × (100/440) — the
/// same value for width and height — keeping squares without `.w`/`.h` skew.
class LoginServicesSlider extends StatefulWidget {
  const LoginServicesSlider({
    super.key,
    this.height,
    this.cycleDuration = const Duration(seconds: 48),
  });

  /// Optional fixed marquee height. When null, height follows 4-row tile math
  /// (uniformly scaled to fit [LayoutBuilder] constraints when needed).
  final double? height;

  /// Time for one full content-width scroll. Keep slow and smooth.
  final Duration cycleDuration;

  /// Figma artboard width the tile specs (100, gap 6) are authored against.
  static const double figmaFrameWidth = 440;

  static const double tileDesign = 100;
  static const double gapDesign = 6;
  static const double radiusDesign = 16;
  static const int rowCount = 4;

  @override
  State<LoginServicesSlider> createState() => _LoginServicesSliderState();
}

class _LoginServicesSliderState extends State<LoginServicesSlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const double _padTopDesign = 4;
  static const double _padRightDesign = 10;
  static const double _padBottomDesign = 4;
  static const double _padLeftDesign = 6;

  /// Icon circle / artwork ratios from the Electricity tile SVG (viewBox 100).
  static const double _iconCircleRatio = 48.6 / 100;
  static const double _iconArtRatio = 30.6 / 100;

  static const Color _tileFill = Color(0x4DFFFFFF);
  static const Color _labelColor = Color(0xFF000000);

  /// Four Figma rows (staggered brick layout). Icons use existing app assets.
  static final List<List<_LoginTileSpec>> _rows = [
    [
      _LoginTileSpec(
        label: 'Electricity Bill',
        pngAsset: FileConstants.loginElectricityBillIcon,
      ),
      const _LoginTileSpec(
        label: 'FASTag Recharge',
        svgAsset: 'assets/images/svg/services/fastag_recharge.svg',
      ),
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
    ],
    [
      const _LoginTileSpec(
        label: 'Mobile Postpaid',
        svgAsset: 'assets/images/svg/services/mobile_recharge.svg',
        iconAspect: 23 / 37,
      ),
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
        label: 'Mobile Recharge',
        svgAsset: 'assets/images/svg/services/mobile_recharge.svg',
        iconAspect: 23 / 37,
      ),
    ],
    [
      const _LoginTileSpec(
        label: 'Tuition Fees',
        svgAsset: 'assets/images/svg/services/tuition_fees.svg',
        iconAspect: 33 / 35,
      ),
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
    ],
    [
      _LoginTileSpec(
        label: 'Personal Loan',
        pngAsset: FileConstants.personalLoans,
      ),
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
    ],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant LoginServicesSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycleDuration != widget.cycleDuration) {
      _controller.duration = widget.cycleDuration;
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Map Figma-440 tile (100) onto current width once — square sides.
        final baseTile = screenSize.width *
            (LoginServicesSlider.tileDesign /
                LoginServicesSlider.figmaFrameWidth);
        final baseGap = screenSize.width *
            (LoginServicesSlider.gapDesign /
                LoginServicesSlider.figmaFrameWidth);

        const rows = LoginServicesSlider.rowCount;
        var tileSize = baseTile;
        var gap = baseGap;
        var naturalH = rows * tileSize + (rows - 1) * gap;

        final budget = widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : naturalH);

        // Uniform shrink to fit parent — never stretch W/H independently.
        if (naturalH > budget && budget > 0) {
          final factor = budget / naturalH;
          tileSize *= factor;
          gap *= factor;
          naturalH = budget;
        }

        final height = widget.height ?? naturalH;
        final radius = tileSize *
            (LoginServicesSlider.radiusDesign / LoginServicesSlider.tileDesign);
        final iconCircle = tileSize * _iconCircleRatio;
        final iconArt = tileSize * _iconArtRatio;
        final padding = EdgeInsets.fromLTRB(
          tileSize * (_padLeftDesign / LoginServicesSlider.tileDesign),
          tileSize * (_padTopDesign / LoginServicesSlider.tileDesign),
          tileSize * (_padRightDesign / LoginServicesSlider.tileDesign),
          tileSize * (_padBottomDesign / LoginServicesSlider.tileDesign),
        );

        // Repeat each row so the strip is wider than the screen.
        const repeats = 3;
        final rowSpecs = _rows
            .map(
              (row) => List<_LoginTileSpec>.generate(
                row.length * repeats,
                (i) => row[i % row.length],
              ),
            )
            .toList(growable: false);

        final tilesPerRow = rowSpecs.first.length;
        final stagger = (tileSize + gap) / 2;
        final stripWidth =
            tilesPerRow * tileSize + (tilesPerRow - 1) * gap + stagger;

        return SizedBox(
          height: height,
          width: double.infinity,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final dx = -_controller.value * stripWidth;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxWidth: stripWidth * 2,
                maxHeight: height,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var copy = 0; copy < 2; copy++)
                      _SliderStrip(
                        width: stripWidth,
                        height: height,
                        tileSize: tileSize,
                        gap: gap,
                        stagger: stagger,
                        rowSpecs: rowSpecs,
                        iconCircle: iconCircle,
                        iconArt: iconArt,
                        radius: radius,
                        padding: padding,
                        tileFill: _tileFill,
                        labelColor: _labelColor,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
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

class _SliderStrip extends StatelessWidget {
  const _SliderStrip({
    required this.width,
    required this.height,
    required this.tileSize,
    required this.gap,
    required this.stagger,
    required this.rowSpecs,
    required this.iconCircle,
    required this.iconArt,
    required this.radius,
    required this.padding,
    required this.tileFill,
    required this.labelColor,
  });

  final double width;
  final double height;
  final double tileSize;
  final double gap;
  final double stagger;
  final List<List<_LoginTileSpec>> rowSpecs;
  final double iconCircle;
  final double iconArt;
  final double radius;
  final EdgeInsets padding;
  final Color tileFill;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var r = 0; r < rowSpecs.length; r++) ...[
            if (r > 0) SizedBox(height: gap),
            _TileRow(
              specs: rowSpecs[r],
              tileSize: tileSize,
              gap: gap,
              // Alternate rows offset for the Figma brick layout.
              leadingPad: r.isOdd ? stagger : 0,
              iconCircle: iconCircle,
              iconArt: iconArt,
              radius: radius,
              padding: padding,
              tileFill: tileFill,
              labelColor: labelColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({
    required this.specs,
    required this.tileSize,
    required this.gap,
    required this.leadingPad,
    required this.iconCircle,
    required this.iconArt,
    required this.radius,
    required this.padding,
    required this.tileFill,
    required this.labelColor,
  });

  final List<_LoginTileSpec> specs;
  final double tileSize;
  final double gap;
  final double leadingPad;
  final double iconCircle;
  final double iconArt;
  final double radius;
  final EdgeInsets padding;
  final Color tileFill;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: leadingPad),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < specs.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            _ServiceTile(
              spec: specs[i],
              size: tileSize,
              iconCircle: iconCircle,
              iconArt: iconArt,
              radius: radius,
              padding: padding,
              tileFill: tileFill,
              labelColor: labelColor,
            ),
          ],
        ],
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
  });

  final _LoginTileSpec spec;
  final double size;
  final double iconCircle;
  final double iconArt;
  final double radius;
  final EdgeInsets padding;
  final Color tileFill;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    double artW = iconArt;
    double artH = iconArt;
    if (spec.iconAspect >= 1) {
      artH = iconArt / spec.iconAspect;
    } else {
      artW = iconArt * spec.iconAspect;
    }

    // Label ~10px on the 100-unit Figma tile; scale with tile, clamp via .sp
    // only for the design baseline font (single ScreenUtil pass).
    final labelSize = (10 * size / LoginServicesSlider.tileDesign).clamp(
      8.0,
      11.0,
    );

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
              Expanded(
                child: Center(
                  child: Container(
                    width: iconCircle,
                    height: iconCircle,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Colors.white,
                          Color(0xFFEEF3FD),
                        ],
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
                ),
              ),
              Text(
                spec.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
