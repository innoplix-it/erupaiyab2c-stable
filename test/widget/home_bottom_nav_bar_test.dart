import 'package:e_rupaiya/features/home/components/home_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  HomeBottomNavEntry entry(String label, String asset) => HomeBottomNavEntry(
        label: label,
        activeIcon: SizedBox.expand(key: ValueKey('$label-active')),
        inactiveIcon: SizedBox.expand(key: ValueKey('$label-inactive')),
        animationAsset: asset,
      );

  Future<List<int>> pumpBar(
    WidgetTester tester, {
    required Size size,
    int selectedIndex = 0,
  }) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = size * 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final taps = <int>[];
    // Mirrors production: the bar is hosted by PersistentTabView.custom,
    // which provides no Scaffold/Material ancestor for the custom widget.
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          home: Builder(
            builder: (context) => PersistentTabView.custom(
              context,
              controller: PersistentTabController(initialIndex: selectedIndex),
              itemCount: 5,
              screens: [
                for (var i = 0; i < 5; i++)
                  CustomNavBarScreen(
                    screen: ListView(
                      key: ValueKey('screen-$i'),
                      children: const [
                        SizedBox(height: 2000, key: ValueKey('content')),
                      ],
                    ),
                  ),
              ],
              navBarHeight: HomeBottomNavMetrics.barHeight(),
              confineToSafeArea: true,
              customWidget: HomeBottomNavBar(
                selectedIndex: selectedIndex,
                leading: [
                  entry('Pay Bills', 'assets/animations/branding-reveal.json'),
                  entry('Offers', 'assets/animations/Discount-icon-2-sec.json'),
                ],
                trailing: [
                  entry('Alerts', 'assets/animations/bell-icon.json'),
                  entry('History', 'assets/animations/history-icon.json'),
                ],
                onItemSelected: taps.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return taps;
  }

  for (final size in const [
    Size(320, 640),
    Size(360, 780),
    Size(390, 844),
    Size(440, 956),
  ]) {
    testWidgets('bar layout fits ${size.width}x${size.height}', (tester) async {
      await pumpBar(tester, size: size);
      expect(tester.takeException(), isNull);

      final bar = tester.getRect(find.byType(HomeBottomNavBar));
      expect(bar.width, closeTo(size.width, 0.5));
      expect(bar.bottom, closeTo(size.height, 0.5));
      expect(find.byType(ErrorWidget), findsNothing);

      final screen = tester.getRect(find.byKey(const ValueKey('screen-0')));
      expect(screen.bottom, lessThanOrEqualTo(bar.top + 0.5));

      await tester.drag(
        find.byKey(const ValueKey('screen-0')),
        const Offset(0, -600),
      );
      await tester.pump();
      expect(tester.getRect(find.byType(HomeBottomNavBar)), bar);
      expect(find.text('Spin & Win'), findsNothing);

      final spin = tester.getRect(find.byType(SpinWinNavItem).first);
      expect(spin.center.dx, closeTo(size.width / 2, 0.5));

      final centers = [
        tester.getCenter(find.byKey(const ValueKey('Pay Bills-active'))).dx,
        for (final label in ['Offers', 'Alerts', 'History'])
          tester.getCenter(find.byKey(ValueKey('$label-inactive'))).dx,
      ];
      expect(centers[0] + centers[3], closeTo(size.width, 1));
      expect(centers[1] + centers[2], closeTo(size.width, 1));

      final labelTops = [
        for (final label in ['Pay Bills', 'Offers', 'Alerts', 'History'])
          tester.getCenter(find.text(label)).dy,
      ];
      for (final top in labelTops) {
        expect(top, closeTo(labelTops.first, 0.5));
      }

      if (size.width == 440) {
        expect(bar.height, closeTo(80, 0.5));
        expect(HomeBottomNavMetrics.iconSize(), 24);
        expect(HomeBottomNavMetrics.spinSize(), 46);
        expect(HomeBottomNavMetrics.fontSize(), 14);
        final payCenter = centers.first;
        expect(payCenter, closeTo(51.2, 1.5));
      }
    });
  }

  testWidgets('tap plays the item animation for ~2s then restores icon', (
    tester,
  ) async {
    final taps = await pumpBar(tester, size: const Size(390, 844));

    await tester.tap(find.text('Offers'));
    await tester.pump();
    expect(taps, [1]);
    expect(find.byType(Lottie), findsOneWidget);
    expect(find.byKey(const ValueKey('Offers-inactive')), findsNothing);

    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.byType(Lottie), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.byType(Lottie), findsNothing);
    expect(find.byKey(const ValueKey('Offers-inactive')), findsOneWidget);
  });

  testWidgets('tapping another item switches the animation cleanly', (
    tester,
  ) async {
    final taps = await pumpBar(tester, size: const Size(390, 844));

    await tester.tap(find.text('Offers'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Alerts'));
    await tester.pump();

    expect(taps, [1, 3]);
    expect(find.byType(Lottie), findsOneWidget);
    expect(find.byKey(const ValueKey('Offers-inactive')), findsOneWidget);
    expect(find.byKey(const ValueKey('Alerts-inactive')), findsNothing);

    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump();
    expect(find.byType(Lottie), findsNothing);
    expect(find.byKey(const ValueKey('Alerts-inactive')), findsOneWidget);
  });

  testWidgets('spin is icon-only and does not animate', (tester) async {
    final taps = await pumpBar(tester, size: const Size(390, 844));
    await tester.tap(find.byType(SpinWinNavItem));
    await tester.pump();
    expect(taps, [2]);
    expect(find.byType(Lottie), findsNothing);
  });
}
