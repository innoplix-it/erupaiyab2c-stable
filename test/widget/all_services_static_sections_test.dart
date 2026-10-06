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

/// Mock API payload that deliberately contains every old/duplicate category
/// the real backend can return. The screen must hide or replace each one.
const _categories = [
  QuickActionCategory(
    category: 'Pay Bills & Expenses',
    services: [QuickActionService(name: 'Water')],
  ),
  QuickActionCategory(
    // Only the five approved cards survive; the rest are commented out.
    category: 'Other Services',
    services: [
      QuickActionService(name: 'Donation'),
      QuickActionService(name: 'Subscription'),
      QuickActionService(name: 'Water'),
      QuickActionService(name: 'Metro Recharge'),
      QuickActionService(name: 'Pan Card Services'),
    ],
  ),
  QuickActionCategory(
    category: 'Banking & Investments',
    services: [QuickActionService(name: 'Recurring Deposit')],
  ),
  QuickActionCategory(
    // Duplicate of the hardcoded static Recharge containers.
    category: 'Recharge',
    services: [QuickActionService(name: 'Mobile Prepaid')],
  ),
  QuickActionCategory(
    // Duplicate of the hardcoded Utility Bills container.
    category: 'Utility Bills',
    services: [
      QuickActionService(name: 'DTH'),
      QuickActionService(name: 'Cable TV'),
    ],
  ),
  QuickActionCategory(
    // Duplicate of the hardcoded Financial container.
    category: 'Financial',
    services: [QuickActionService(name: 'NPS')],
  ),
  QuickActionCategory(
    // Old education container with the removed Gym tile and old rent tiles.
    category: 'Education and Lifestyle',
    services: [
      QuickActionService(name: 'School Fees'),
      QuickActionService(name: 'Gym Membership'),
      QuickActionService(name: 'House Rent'),
    ],
  ),
  QuickActionCategory(
    category: 'Insurance',
    services: [QuickActionService(name: 'Life Insurance')],
  ),
  QuickActionCategory(
    category: 'Rent & Property',
    services: [QuickActionService(name: 'Shop Rent')],
  ),
  QuickActionCategory(
    // Not replaced by Figma sections — must keep rendering.
    category: 'Money Transfer',
    services: [QuickActionService(name: 'IMPS')],
  ),
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
      categories: _categories,
      banners: <String, List<BannerModel>>{},
      isNameEmailExist: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Tile labels are rendered with two-word line breaks (e.g. "Mobile\nPrepaid")
/// by [HomeIconTile], so match tiles on the widget property, not find.text.
List<HomeIconTile> tilesNamed(WidgetTester tester, String label) {
  return tester
      .widgetList<HomeIconTile>(find.byType(HomeIconTile))
      .where((t) => t.label == label)
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester, {double width = 390}) async {
    // Tall surface so the lazily built ListView lays out every section,
    // with a matching ScreenUtil design height: `.h` values stay at their
    // real-device scale instead of inflating proportionally to the surface
    // (otherwise the content grows just as fast as the viewport).
    tester.view.physicalSize = Size(width, 10000) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWithValue(_MockHomeRepository()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(360, 10000),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            home: Scaffold(body: child),
          ),
          child: const HomeSearchView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders every Figma section exactly once, in order', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.takeException(), isNull);

    // Recharge heading appears twice (pink strip + white card); the API
    // duplicate adds no third occurrence. Same for every replaced category.
    expect(find.text('Recharge'), findsNWidgets(2));
    for (final heading in [
      'Utility Bills',
      'Financial',
      'Pay via Credit Card (Education)',
      'Insurance',
      'Rent & Property',
      'Other Services',
    ]) {
      expect(find.text(heading), findsNWidgets(1), reason: heading);
    }

    // Required vertical order, ending with the non-replaced API section.
    final ordered = <String, double>{
      'Recharge': tester.getTopLeft(find.text('Recharge').last).dy,
      'Utility Bills': tester.getTopLeft(find.text('Utility Bills')).dy,
      'Financial': tester.getTopLeft(find.text('Financial')).dy,
      'Pay via Credit Card (Education)': tester
          .getTopLeft(find.text('Pay via Credit Card (Education)'))
          .dy,
      'Insurance': tester.getTopLeft(find.text('Insurance')).dy,
      'Rent & Property': tester.getTopLeft(find.text('Rent & Property')).dy,
      'Other Services': tester.getTopLeft(find.text('Other Services')).dy,
      'Money Transfer': tester.getTopLeft(find.text('Money Transfer')).dy,
    };
    final keys = ordered.keys.toList();
    for (var i = 1; i < keys.length; i++) {
      expect(
        ordered[keys[i]]!,
        greaterThan(ordered[keys[i - 1]]!),
        reason: '${keys[i - 1]} should be above ${keys[i]}',
      );
    }
  });

  testWidgets('Recharge shows the six required cards with new icons', (
    tester,
  ) async {
    await pump(tester);

    // Five tiles in the pink strip, six in the white Recharge card.
    expect(tilesNamed(tester, 'Mobile Prepaid').length, 2);
    for (final label in [
      'Mobile Postpaid',
      'FASTag Recharge',
      'EV Recharge',
      'Fleet Card Recharge',
    ]) {
      expect(tilesNamed(tester, label), hasLength(2), reason: label);
    }
    expect(tilesNamed(tester, 'NCMC Recharge'), hasLength(1));

    for (final tile in tilesNamed(tester, 'FASTag Recharge')) {
      // The new SVG must be used — never the old fasttag.png fallback.
      expect(tile.svgAsset, 'assets/images/svg/services/fastag_recharge.svg');
      expect(tile.iconUrl, isNot(contains('fasttag.png')));
    }
  });

  testWidgets('Education, Insurance and Rent sections use Figma tiles/SVGs', (
    tester,
  ) async {
    await pump(tester);

    expect(tilesNamed(tester, 'Education Fees'), hasLength(1));
    expect(
      tilesNamed(tester, 'Education Fees').single.svgAsset,
      'assets/images/svg/services/education_fees.svg',
    );
    expect(tilesNamed(tester, 'Rental').single.svgAsset,
        'assets/images/svg/services/rental.svg');

    expect(tilesNamed(tester, 'Gym Membership'), isEmpty);
    // Old API duplicates are suppressed: single occurrences only.
    for (final label in [
      'School Fees',
      'Tution Fees',
      'College Fees',
      'General Insurance',
      'Health Insurance',
      'Life Insurance',
      'House Rent',
      'Shop Rent',
      'Rental',
    ]) {
      expect(tilesNamed(tester, label), hasLength(1), reason: label);
    }

    // Financial icon-reuse rules from the task.
    final creditCardBill = tilesNamed(tester, 'Credit Card Bill').single;
    final echallan = tilesNamed(tester, 'eChallan').single;
    expect(creditCardBill.svgAsset,
        'assets/images/svg/services/ncmc_recharge.svg');
    expect(echallan.svgAsset, 'assets/images/svg/services/ncmc_recharge.svg');
    expect(tilesNamed(tester, 'Digital Gold').single.svgAsset,
        'assets/images/svg/services/electricity_bill.svg');
    expect(tilesNamed(tester, 'Digital Silver').single.svgAsset,
        'assets/images/svg/services/digital_silver.svg');
    expect(tilesNamed(tester, 'Agent Collection').single.svgAsset,
        'assets/images/svg/services/agent_collection.svg');
    expect(tilesNamed(tester, 'B2B Payments').single.svgAsset,
        'assets/images/svg/services/b2b_payments.svg');
  });

  testWidgets('hidden categories stay hidden; API remainder still renders', (
    tester,
  ) async {
    await pump(tester);

    for (final heading in [
      'Banking & Investments',
      'Pay Bills & Expenses',
      'Education and Lifestyle',
    ]) {
      expect(find.text(heading), findsNothing, reason: heading);
    }
    // Commented-out Other Services items never render...
    expect(find.text('Donation'), findsNothing);
    expect(find.text('Recurring Deposit'), findsNothing);
    // ...while the five approved cards do (Pipe Gas / Prepaid Meter also
    // exist in the Utility Bills container, hence two occurrences).
    expect(tilesNamed(tester, 'Subscription'), hasLength(1));
    expect(tilesNamed(tester, 'Water'), hasLength(1));
    expect(tilesNamed(tester, 'Metro Recharge'), hasLength(1));
    expect(tilesNamed(tester, 'Pipe Gas'), hasLength(2));
    expect(tilesNamed(tester, 'Prepaid Meter'), hasLength(2));
    // Non-replaced API category still renders.
    expect(find.text('Money Transfer'), findsOneWidget);
    expect(tilesNamed(tester, 'IMPS'), hasLength(1));
  });

  testWidgets('search keeps suppressed categories searchable', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'dth');
    await tester.pumpAndSettle();
    // Display text is capitalized ("Dth"), so match the tile widget itself.
    expect(tilesNamed(tester, 'DTH'), isNotEmpty);
    expect(find.text('Recharge'), findsNothing);

    // Commented-out Other Services items stay hidden in search too...
    await tester.enterText(find.byType(TextField), 'donation');
    await tester.pumpAndSettle();
    expect(find.text('No services found'), findsOneWidget);

    // ...but the kept ones remain searchable.
    await tester.enterText(find.byType(TextField), 'metro');
    await tester.pumpAndSettle();
    expect(tilesNamed(tester, 'Metro Recharge'), isNotEmpty);

    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    await tester.pumpAndSettle();
    expect(find.text('No services found'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Recharge'), findsNWidgets(2));
    expect(find.text('Utility Bills'), findsNWidgets(1));
  });
}
