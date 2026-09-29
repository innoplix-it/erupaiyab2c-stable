import 'package:e_rupaiya/features/home/components/home_icon_tile.dart';
import 'package:e_rupaiya/features/home/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

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

  for (final width in <double>[320, 390, 430]) {
    testWidgets('home header, hero, and bills fit a $width-wide phone', (
      tester,
    ) async {
      final headerKey = GlobalKey();
      final heroKey = GlobalKey();
      await pumpSurface(
        tester,
        logicalSize: Size(width, 800),
        body: Column(
          children: [
            Builder(
              builder: (context) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
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
      expect(heroTop, greaterThanOrEqualTo(headerBottom - 0.5));
      expect(heroTop - headerBottom, lessThan(2));

      final headerBefore = tester.getTopLeft(find.byKey(headerKey));
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(find.byKey(headerKey)), headerBefore);

      final widthBox = tester.getSize(find.byKey(headerKey)).width;
      expect(widthBox, lessThanOrEqualTo(width + 0.5));
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
    });
  }
}
