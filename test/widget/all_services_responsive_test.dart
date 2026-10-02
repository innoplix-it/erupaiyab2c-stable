import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:e_rupaiya/features/home/components/home_icon_tile.dart';
import 'package:e_rupaiya/features/home/controllers/home_controller.dart';
import 'package:e_rupaiya/features/home/models/banner_model.dart';
import 'package:e_rupaiya/features/home/models/quick_action_model.dart';
import 'package:e_rupaiya/features/home/repositories/home_repository.dart';
import 'package:e_rupaiya/features/home/views/home_search_view.dart';
import 'package:e_rupaiya/widgets/common_search_bar.dart';
import 'package:e_rupaiya/widgets/common_service_svg_icon.dart';

const _categories = [
  QuickActionCategory(
    category: 'Recharge',
    services: [
      QuickActionService(name: 'Mobile Prepaid'),
      QuickActionService(name: 'Mobile Postpaid'),
      QuickActionService(name: 'FASTag Recharge'),
      QuickActionService(name: 'EV Recharge'),
      QuickActionService(name: 'Fleet Card Recharge'),
      QuickActionService(name: 'NCMC Recharge'),
    ],
  ),
  QuickActionCategory(
    category: 'Utility Bills',
    services: [
      QuickActionService(name: 'Electricity Bill'),
      QuickActionService(name: 'Book LPG'),
      QuickActionService(name: 'Pipe Gas', icon: 'https://cdn/x.png'),
      QuickActionService(name: 'Prepaid Meter'),
      QuickActionService(name: 'Cable TV'),
      QuickActionService(name: 'DTH'),
      QuickActionService(name: 'Broadband'),
      QuickActionService(name: 'Landline'),
      QuickActionService(name: 'Housing Society'),
      QuickActionService(name: 'Municipal Services'),
    ],
  ),
  QuickActionCategory(
    category: 'Financial',
    services: [
      QuickActionService(name: 'Credit Card Bill'),
      QuickActionService(name: 'Digital Gold'),
      QuickActionService(name: 'Digital Silver'),
      QuickActionService(name: 'Loan Repayment'),
      QuickActionService(name: 'Municipal Taxes'),
      QuickActionService(name: 'EChallan'),
      QuickActionService(name: 'NPS'),
      QuickActionService(name: 'Forex'),
      QuickActionService(name: 'Agent Collection'),
      QuickActionService(name: 'B2B Payments'),
    ],
  ),
  QuickActionCategory(
    category: 'Pay Via Credit Card (Education)',
    services: [
      QuickActionService(name: 'School Fees'),
      QuickActionService(name: 'College Fees'),
      QuickActionService(name: 'Tuition Fees'),
      QuickActionService(name: 'Education Fees'),
    ],
  ),
  QuickActionCategory(
    category: 'Insurance',
    services: [
      QuickActionService(name: 'General Insurance'),
      QuickActionService(name: 'Health Insurance'),
      QuickActionService(name: 'Life Insurance'),
    ],
  ),
  QuickActionCategory(
    category: 'Rent & Property',
    services: [
      QuickActionService(name: 'House Rent'),
      QuickActionService(name: 'Shop Rent'),
      QuickActionService(name: 'Rental'),
    ],
  ),
];

/// API order deliberately differs from the Figma order.
final _apiOrder = [
  _categories[5],
  _categories[2],
  _categories[0],
  _categories[4],
  _categories[1],
  _categories[3],
];

class _MockHomeRepository implements HomeRepository {
  @override
  Future<List<BannerModel>> fetchExploreAllServicesBanners({
    String lang = 'en',
  }) async {
    return [];
  }

  @override
  Future<
      ({
        List<QuickActionCategory> categories,
        Map<String, List<BannerModel>> banners,
        bool? isNameEmailExist,
      })> fetchQuickActions({String? search}) async {
    return (
      categories: _apiOrder,
      banners: <String, List<BannerModel>>{},
      isNameEmailExist: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _svgDir = 'assets/images/svg/services';
const _suppliedSvgs = {
  'EV Recharge': 'ev_recharge',
  'Fleet Card Recharge': 'fleet_card_recharge',
  'NCMC Recharge': 'ncmc_recharge',
  'Pipe Gas': 'pipe_gas',
  'Prepaid Meter': 'prepaid_meter',
  'Cable TV': 'cable_tv',
  'DTH': 'dth',
  'Broadband': 'broadband',
  'Landline': 'landline',
  'Housing Society': 'housing_society',
  'Municipal Services': 'municipal_services',
  'Digital Gold': 'digital_gold',
  'Digital Silver': 'digital_silver',
  'Loan Repayment': 'loan_repayment',
  'Municipal Taxes': 'municipal_taxes',
  'NPS': 'nps',
  'Forex': 'forex',
  'Agent Collection': 'agent_collection',
  'B2B Payments': 'b2b_payments',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester, double width) async {
    // Tall enough that the whole (lazily built) list is laid out at once.
    tester.view.physicalSize = Size(width, 3200) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWithValue(_MockHomeRepository()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          fontSizeResolver: FontSizeResolvers.radius,
          builder: (context, child) => MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.15)),
                child: const HomeSearchView(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  HomeIconTile tileNamed(WidgetTester tester, String name, {int index = 0}) {
    return tester
        .widgetList<HomeIconTile>(find.byType(HomeIconTile))
        .where((t) => t.label == name)
        .elementAt(index);
  }

  const widths = [320.0, 360.0, 375.0, 390.0, 412.0, 440.0];

  for (final width in widths) {
    testWidgets('All Services matches the Figma flow at ${width.toInt()}px', (
      tester,
    ) async {
      await pump(tester, width);
      expect(tester.takeException(), isNull);

      final search = tester.getRect(find.byType(CommonSearchBar));
      final banner = tester.getRect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  'assets/images/investmentallservices.png',
        ),
      );
      final inset = width * 24 / 440;
      expect(search.left, moreOrLessEquals(inset, epsilon: 0.5));
      expect(search.right, moreOrLessEquals(width - inset, epsilon: 0.5));
      expect(banner.left, moreOrLessEquals(inset, epsilon: 0.5));
      expect(banner.width / banner.height, moreOrLessEquals(393 / 67));
      expect(search.bottom, lessThanOrEqualTo(banner.top));

      // Pink strip (first "Recharge"), then the sections in Figma order.
      final headings = [
        'Recharge',
        'Utility Bills',
        'Financial',
        'Pay Via Credit Card (Education)',
        'Insurance',
        'Rent & Property',
      ];
      expect(find.text('Recharge'), findsNWidgets(2));
      final stripTitle = tester.getRect(find.text('Recharge').first);
      expect(stripTitle.top, greaterThan(banner.bottom));
      var previous = stripTitle.top;
      for (final heading in headings) {
        final rect = tester.getRect(find.text(heading).last);
        expect(rect.top, greaterThan(previous), reason: heading);
        previous = rect.top;
      }

      // Strip: first five Recharge services in one row.
      final stripTiles = [
        for (final name in [
          'Mobile Prepaid',
          'Mobile Postpaid',
          'FASTag Recharge',
          'EV Recharge',
          'Fleet Card Recharge',
        ])
          tester.getRect(find.byWidget(tileNamed(tester, name))),
      ];
      for (final r in stripTiles) {
        expect(r.top, moreOrLessEquals(stripTiles.first.top));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(width));
      }

      // Category cards: 4 per row, everything inside the screen.
      final utilityRow = [
        for (final name in [
          'Electricity Bill',
          'Book LPG',
          'Pipe Gas',
          'Prepaid Meter',
          'Cable TV',
        ])
          tester.getRect(find.byWidget(tileNamed(tester, name))),
      ];
      for (var i = 1; i < 4; i++) {
        expect(utilityRow[i].top, moreOrLessEquals(utilityRow[0].top));
      }
      expect(utilityRow[4].top, greaterThan(utilityRow[0].bottom));
      expect(utilityRow[4].left, moreOrLessEquals(utilityRow[0].left));

      for (final tile in tester.widgetList<HomeIconTile>(
        find.byType(HomeIconTile),
      )) {
        final r = tester.getRect(find.byWidget(tile));
        expect(r.left, greaterThanOrEqualTo(0), reason: tile.label);
        expect(r.right, lessThanOrEqualTo(width), reason: tile.label);
        expect(tile.onTap, isNotNull, reason: tile.label);
        final label = homeServiceCardLabelStyle();
        expect(label.fontFamily, contains('PlusJakartaSans'));
      }
    });
  }

  testWidgets('every supplied service uses its exact SVG asset', (
    tester,
  ) async {
    await pump(tester, 390);
    // Sections with more than two rows start collapsed (existing behaviour).
    for (final heading in ['Utility Bills', 'Financial']) {
      await tester.tap(find.text(heading));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    final rendered = tester
        .widgetList<CommonServiceSvgIcon>(find.byType(CommonServiceSvgIcon))
        .map((w) => w.assetPath)
        .toList();
    for (final entry in _suppliedSvgs.entries) {
      expect(
        rendered,
        contains('$_svgDir/${entry.value}.svg'),
        reason: entry.key,
      );
    }
    expect(rendered, contains('$_svgDir/cable_tv_overlay.svg'));

    // The supplied SVG wins over an API icon.
    expect(tileNamed(tester, 'Pipe Gas').iconUrl, isNull);
    // EChallan reuses the Credit Card icon.
    expect(
      tileNamed(tester, 'EChallan').iconUrl,
      tileNamed(tester, 'Credit Card Bill').iconUrl,
    );
  });

  testWidgets('search still filters the dynamic services', (tester) async {
    await pump(tester, 390);
    await tester.enterText(find.byType(TextField), 'gold');
    await tester.pumpAndSettle();

    final labels = tester
        .widgetList<HomeIconTile>(find.byType(HomeIconTile))
        .map((t) => t.label)
        .toList();
    expect(labels, ['Digital Gold']);
    expect(find.text('Recharge'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Recharge'), findsNWidgets(2));
  });
}
