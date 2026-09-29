import 'package:e_rupaiya/features/home/components/home_icon_tile.dart';
import 'package:e_rupaiya/features/home/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpSurface(
    WidgetTester tester, {
    required Size logicalSize,
    required Widget body,
    double textScale = 1,
    double topPadding = 47,
  }) async {
    final dpr = 2.0;
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = Size(
      logicalSize.width * dpr,
      logicalSize.height * dpr,
    );
    tester.view.padding = FakeViewPadding(
      top: topPadding * dpr,
      bottom: 0,
      left: 0,
      right: 0,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) {
          return MaterialApp(
            home: Builder(
              builder: (context) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(
                    padding: EdgeInsets.only(top: topPadding),
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: Material(color: Colors.white, child: body),
                );
              },
            ),
          );
        },
      ),
    );
    await tester.pump();
  }

  for (final width in <double>[320, 390, 430, 440]) {
    testWidgets('home header, hero, and bills fit a $width-wide phone', (
      tester,
    ) async {
      final headerKey = GlobalKey();
      final heroKey = GlobalKey();
      var headerGap = 0.0;
      await pumpSurface(
        tester,
        logicalSize: Size(width, 800),
        body: Column(
          children: [
            Builder(
              builder: (context) {
                headerGap = debugHomeHeaderBottomGap(context);
                return Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                    bottom: headerGap,
                  ),
                  child: KeyedSubtree(
                    key: headerKey,
                    child: debugHomeStickyHeader(),
                  ),
                );
              },
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  KeyedSubtree(key: heroKey, child: debugHomeHeroBanner()),
                  debugHomeBillsCard(),
                  const SizedBox(height: 1200),
                ],
              ),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);

      final headerTop = tester.getTopLeft(find.byKey(headerKey)).dy;
      final headerBottom = tester.getBottomLeft(find.byKey(headerKey)).dy;
      final heroTop = tester.getTopLeft(find.byKey(heroKey)).dy;
      expect(headerTop, greaterThanOrEqualTo(47 - 0.5));
      expect(headerGap, inInclusiveRange(4.0, 8.0));
      expect(heroTop - headerBottom, closeTo(headerGap, 0.5));

      final headerBefore = tester.getTopLeft(find.byKey(headerKey));
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(find.byKey(headerKey)), headerBefore);

      final widthBox = tester.getSize(find.byKey(headerKey)).width;
      expect(widthBox, lessThanOrEqualTo(width + 0.5));
    });

    testWidgets('bills card keeps Figma ratio and fits content at $width', (
      tester,
    ) async {
      final cardKey = GlobalKey();
      final margin = width < 380 ? 16.0 * width / 360 : width * 24 / 440;
      await pumpSurface(
        tester,
        logicalSize: Size(width, 900),
        textScale: 1.15,
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: margin),
          children: [KeyedSubtree(key: cardKey, child: debugHomeBillsCard())],
        ),
      );
      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byKey(cardKey));
      expect(card.width, closeTo(width - 2 * margin, 0.5));
      expect(card.height, closeTo(card.width * 276 / 392, 0.5));
      if (width == 440) expect(card.width, closeTo(392, 0.5));

      for (final label in ['Book\nGas', 'Explore All Utilities']) {
        final rect = tester.getRect(find.text(label));
        expect(rect.bottom, lessThanOrEqualTo(card.bottom + 0.5), reason: label);
        expect(rect.right, lessThanOrEqualTo(card.right + 0.5), reason: label);
      }
    });

    testWidgets('service labels stay inside a $width-wide row', (tester) async {
      await pumpSurface(
        tester,
        logicalSize: Size(width, 800),
        textScale: 1.15,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HomeIconTile(label: 'Electricity Bill'),
              ),
              Expanded(
                child: HomeIconTile(label: 'Mobile Prepaid'),
              ),
              Expanded(
                child: HomeIconTile(label: 'Fastag Recharge'),
              ),
              Expanded(
                child: HomeIconTile(label: 'Credit Card'),
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      final twoLine = find.text('Electricity\nBill');
      final oneLine = find.text('Fastag\nRecharge');
      final circles = find.byType(HomeServiceCircle);
      final style = tester.widget<Text>(twoLine).style!;
      expect(
        style.fontSize,
        closeTo(homeServiceCardLabelStyle().fontSize!, 0.01),
      );
      expect(style.fontSize, lessThan(12.sp));
      expect(style.fontWeight, FontWeight.w600);
      expect(style.height, HomeServiceItemMetrics.labelLineHeight);

      final labelTop = tester.getTopLeft(twoLine).dy;
      final circleBottom = tester.getBottomLeft(circles.first).dy;
      final gap = homeServiceCardLabelGap(tester.element(twoLine));
      expect(gap, inInclusiveRange(2.0, 6.0));
      expect(labelTop - circleBottom, closeTo(gap, 0.5));
      expect(tester.getTopLeft(oneLine).dy, closeTo(labelTop, 0.5));
    });

    testWidgets('loan labels share gap and alignment at $width', (
      tester,
    ) async {
      await pumpSurface(
        tester,
        logicalSize: Size(width, 800),
        textScale: 1.15,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: debugHomeLoansGrid(),
        ),
      );
      expect(tester.takeException(), isNull);

      const labels = [
        'Personal\nLoan',
        'Business\nLoan',
        'Home\nLoan',
        'Loan Against\nProperty',
      ];
      final circles = find.byType(HomeServiceCircle);
      final gap = homeServiceCardLabelGap(tester.element(circles.first));
      final firstTop = tester.getTopLeft(find.text(labels.first)).dy;
      for (var i = 0; i < labels.length; i++) {
        final label = find.text(labels[i]);
        final rect = tester.getRect(label);
        final circle = tester.getRect(circles.at(i));
        expect(rect.top, closeTo(firstTop, 0.5), reason: labels[i]);
        expect(rect.top - circle.bottom, closeTo(gap, 0.5), reason: labels[i]);
        expect(rect.center.dx, closeTo(circle.center.dx, 0.5));
      }
    });

    testWidgets('investment row styling and icon size at $width', (
      tester,
    ) async {
      await pumpSurface(
        tester,
        logicalSize: Size(width, 800),
        textScale: 1.15,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: debugHomeInvestmentRow(),
        ),
      );
      expect(tester.takeException(), isNull);

      final lottie = find.byType(Lottie);
      expect(lottie, findsOneWidget);
      final iconSize = homeServiceIconSize();
      expect(tester.getSize(lottie).width, closeTo(iconSize, 0.5));
      expect(tester.getSize(lottie).height, closeTo(iconSize, 0.5));
      expect(iconSize, lessThanOrEqualTo(34.w + 0.01));

      final circles = tester
          .widgetList<HomeServiceCircle>(find.byType(HomeServiceCircle))
          .toList();
      expect(circles, hasLength(3));
      expect(circles[1].fillColors, HomeServiceCircle.goldFill);
      expect(circles[2].fillColors, HomeServiceCircle.silverFill);
      for (final c in find.byType(HomeServiceCircle).evaluate()) {
        final size = (c.renderObject! as RenderBox).size;
        expect(size.width, closeTo(HomeServiceCircle.size, 0.5));
        expect(size.height, closeTo(HomeServiceCircle.size, 0.5));
      }
    });
  }

  for (final size in const <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(360, 800),
    Size(412, 915),
    Size(440, 956),
  ]) {
    testWidgets('bills card rows never collide at ${size.width}x${size.height}',
        (tester) async {
      final cardKey = GlobalKey();
      final width = size.width;
      final margin = width < 380 ? 16.0 * width / 360 : width * 24 / 440;
      await pumpSurface(
        tester,
        logicalSize: size,
        textScale: 1.15,
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: margin),
          children: [KeyedSubtree(key: cardKey, child: debugHomeBillsCard())],
        ),
      );
      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byKey(cardKey));
      final tiles = find.byType(HomeIconTile);
      expect(tiles, findsNWidgets(5));
      final strip = tester.getRect(find.byWidgetPredicate((w) {
        if (w is! Image) return false;
        var provider = w.image;
        if (provider is ResizeImage) provider = provider.imageProvider;
        return provider is AssetImage &&
            provider.assetName.contains('bookLpgStrip');
      }));
      final bookGasCircle =
          tester.getRect(find.byType(HomeServiceCircle).at(4));

      for (var i = 0; i < 4; i++) {
        final tile = tester.getRect(tiles.at(i));
        expect(tile.bottom, lessThanOrEqualTo(strip.top + 0.5));
        if (i == 0) {
          expect(tile.bottom, lessThanOrEqualTo(bookGasCircle.top));
        }
      }
      expect(tester.getRect(tiles.at(4)).bottom,
          lessThanOrEqualTo(card.bottom + 0.5));

      final orbit = tester.getRect(find.byWidgetPredicate((w) =>
          w is LottieBuilder &&
          w.lottie is AssetLottie &&
          (w.lottie as AssetLottie).assetName.contains('Ellipse-orbit')));
      expect(orbit.center.dx, closeTo(bookGasCircle.center.dx, 0.5));
      expect(orbit.center.dy, closeTo(bookGasCircle.center.dy, 0.5));
      expect(orbit.width, closeTo(bookGasCircle.width * 96 / 68, 0.5));
    });
  }

  testWidgets('service circles match Figma 68/10/2 on the 440 frame', (
    tester,
  ) async {
    await pumpSurface(
      tester,
      logicalSize: const Size(440, 956),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: debugHomeInvestmentRow(),
      ),
    );
    expect(HomeServiceCircle.size, closeTo(68, 0.01));
    expect(HomeServiceCircle.contentPadding, closeTo(10, 0.01));
    expect(HomeServiceCircle.borderWidth, closeTo(2, 0.01));
    expect(homeServiceIconSize(), closeTo(34, 0.01));

    final decoration = HomeServiceCircle.decoration();
    final border = decoration.border! as Border;
    expect(border.top.color, const Color(0xFFFFFFFF));
    expect(border.top.strokeAlign, BorderSide.strokeAlignOutside);
    expect((decoration.gradient! as RadialGradient).colors,
        HomeServiceCircle.defaultFill);
    expect(decoration.boxShadow, hasLength(4));
  });
}
