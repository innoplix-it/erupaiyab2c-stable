import 'dart:async';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/latest_transaction.dart';
import 'package:e_rupaiya/features/services/components/fetch_provider_metrics.dart';
import 'package:e_rupaiya/features/services/controllers/biller_listing_controller.dart';
import 'package:e_rupaiya/features/services/controllers/service_extras_controller.dart';
import 'package:e_rupaiya/features/services/models/biller_model.dart';
import 'package:e_rupaiya/features/services/repositories/biller_repository.dart';
import 'package:e_rupaiya/features/services/views/biller_listing_view.dart';
import 'package:e_rupaiya/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _billers = [
  Biller(
    billerId: '1',
    billerName: 'Maharashtra State Electricity Distribution Co. Ltd',
  ),
  Biller(billerId: '2', billerName: 'Adani Electricity Mumbai Limited'),
  Biller(billerId: '3', billerName: 'B.E.S.T Mumbai'),
  Biller(billerId: '4', billerName: 'Tata Power Delhi Distribution Limited'),
];

const _saved = LatestTransaction(
  id: '1',
  paymentType: 'Electricity',
  billerName: 'MSEDCL Mahavitaran Maharashtra',
  amount: 450,
  status: 'success',
  transactionRef: 'ref',
  serviceNo: '123456789012',
  icon: '',
  customerName: 'Rajiv Sanjiv Kumar',
  autoPayActive: true,
  createdAt: '2026-09-05T10:00:00Z',
);

class _FakeBillerRepository extends BillerRepository {
  _FakeBillerRepository() : super(dio: Dio());

  @override
  Future<BillerListResponse> fetchBillers({
    required String categoryName,
    int page = 1,
    int limit = 20,
    String? search,
  }) async =>
      BillerListResponse(categoryName: categoryName, billers: _billers);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(
    WidgetTester tester,
    Size size, {
    Future<List<LatestTransaction>> Function()? savedBillers,
    String categoryName = 'Electricity',
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = size * 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billerRepositoryProvider.overrideWithValue(_FakeBillerRepository()),
          serviceLatestTransactionsProvider.overrideWith(
            (ref, service) =>
                savedBillers?.call() ?? Future.value(const [_saved, _saved]),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          fontSizeResolver: FontSizeResolvers.radius,
          builder: (context, _) => MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.15)),
                child: BillerListingView(categoryName: categoryName),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  const sizes = [
    Size(320, 568),
    Size(320, 700),
    Size(360, 640),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
    Size(440, 956),
  ];

  for (final size in sizes) {
    testWidgets(
        'Fetch Your Provider fits ${size.width.toInt()}x'
        '${size.height.toInt()} at 1.15 text', (tester) async {
      await pump(tester, size);
      expect(tester.takeException(), isNull);

      expect(find.text('Saved Billers'), findsOneWidget);
      final title = tester.getRect(find.text('Saved Billers'));
      final viewAll = tester.getRect(find.text('View all'));
      expect(title.right, lessThanOrEqualTo(viewAll.left));
      expect(viewAll.right, lessThanOrEqualTo(size.width));

      expect(find.text('Search by billers'), findsOneWidget);
      final search = tester.getRect(find.byType(AppSearchBar));
      expect(search.left, greaterThanOrEqualTo(0));
      expect(search.right, lessThanOrEqualTo(size.width));

      final dots = find.byType(PopupMenuButton<String>).first;
      final card = tester.getRect(
        find.ancestor(of: dots, matching: find.byType(GestureDetector)).last,
      );
      final dotsRect = tester.getRect(dots);
      expect(dotsRect.right, lessThanOrEqualTo(card.right));
      final badgeFinder = find.byType(SvgPicture).first;
      final badge = tester.getRect(badgeFinder);
      expect(badge.right, lessThanOrEqualTo(card.right));
      expect(badge.bottom, lessThanOrEqualTo(card.bottom));
      expect(badge.width / badge.height, moreOrLessEquals(78 / 25));

      final rowName = find.text(_billers.first.billerName);
      expect(rowName, findsOneWidget);
      final nameRect = tester.getRect(rowName);
      expect(nameRect.right, lessThanOrEqualTo(size.width));
    });
  }

  for (final size in const [
    Size(320, 700),
    Size(360, 740),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
    Size(440, 956),
  ]) {
    testWidgets('operator rows are clean at ${size.width.toInt()}px',
        (tester) async {
      await pump(tester, size);
      expect(tester.takeException(), isNull);

      for (final biller in _billers) {
        final name = find.text(biller.billerName);
        final text = tester.widget<Text>(name);
        expect(text.maxLines, isNull, reason: 'names must not be clipped');
        expect(text.style!.fontSize, moreOrLessEquals(13.sp));
        expect(text.style!.fontWeight, FontWeight.w500);
        expect(text.style!.color, const Color(0xFF000000));

        final row = find.ancestor(of: name, matching: find.byType(Row)).first;
        final logoCard = tester.getRect(
          find.descendant(of: row, matching: find.byType(Container)).first,
        );
        final arrow = tester.getRect(
          find.descendant(of: row, matching: find.byType(Image)).last,
        );
        final nameRect = tester.getRect(name);
        final rowRect = tester.getRect(row);

        // Square card, 50px on the 440 Figma frame, with the logo filling
        // all but a 4px inset and the 1.w border.
        final cardSize = FetchProviderMetrics.r(50);
        expect(logoCard.width, moreOrLessEquals(cardSize, epsilon: 0.5));
        expect(logoCard.height, moreOrLessEquals(cardSize, epsilon: 0.5));
        if (size.width == 440) {
          expect(logoCard.width, moreOrLessEquals(50, epsilon: 0.5));
        }
        final logo = tester.widget<Container>(
          find.descendant(of: row, matching: find.byType(Container)).first,
        );
        final logoSide = cardSize - 2 * (FetchProviderMetrics.r(4) + 1.w);
        expect(
          logo.padding,
          EdgeInsets.all(FetchProviderMetrics.r(4)),
        );
        expect(logoSide / cardSize, greaterThan(0.75));
        expect(arrow.width, moreOrLessEquals(24.w, epsilon: 0.5));
        expect(arrow.height, moreOrLessEquals(24.h, epsilon: 0.5));
        expect(nameRect.left, greaterThanOrEqualTo(logoCard.right));
        expect(nameRect.right, lessThanOrEqualTo(arrow.left));
        expect(arrow.right, lessThanOrEqualTo(size.width));
        expect(logoCard.center.dy, moreOrLessEquals(rowRect.center.dy));
        expect(arrow.center.dy, moreOrLessEquals(rowRect.center.dy));

        // Every line gets the same 1.35 line height, so wrapped names have
        // an even gap and the paragraph height is a whole number of lines.
        final lineHeight = 13.sp * 1.35 * 1.15;
        final lines = nameRect.height / lineHeight;
        expect(lines, moreOrLessEquals(lines.roundToDouble(), epsilon: 0.1));
        expect(lines.round(), greaterThanOrEqualTo(1));
      }

      Rect rowOf(String name) => tester.getRect(
            find
                .ancestor(of: find.text(name), matching: find.byType(Row))
                .first,
          );
      for (var i = 1; i < _billers.length; i++) {
        final gap = rowOf(_billers[i].billerName).top -
            rowOf(_billers[i - 1].billerName).bottom;
        expect(gap, moreOrLessEquals(size.width * 20 / 440, epsilon: 0.5),
            reason: 'rows keep the Figma 20px gap scaled by screen width');
      }
    });
  }

  group('tall phones do not get extra space between operators', () {
    // Same width, very different heights: row spacing must not change.
    final gaps = <double>[];
    for (final size in const [Size(360, 740), Size(360, 1000)]) {
      testWidgets('gap at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await pump(tester, size);
        Rect rowOf(String name) => tester.getRect(
              find
                  .ancestor(of: find.text(name), matching: find.byType(Row))
                  .first,
            );
        final gap = rowOf(_billers[1].billerName).top -
            rowOf(_billers[0].billerName).bottom;
        expect(gap, moreOrLessEquals(360 * 20 / 440, epsilon: 0.5));
        gaps.add(gap);
        if (gaps.length == 2) {
          expect(gaps[1], moreOrLessEquals(gaps[0], epsilon: 0.01));
        }
      });
    }
  });

  group('Electricity Figma assets and fonts', () {
    testWidgets('uses the ecoins banner, not the old one', (tester) async {
      await pump(tester, const Size(390, 844));
      final assets = tester
          .widgetList<Image>(find.byType(Image))
          .map((i) => i.image)
          .whereType<AssetImage>()
          .map((a) => a.assetName)
          .toList();
      expect(assets, contains(FileConstants.electricityEcoins));
      expect(assets.where((a) => a.contains('electricitybanner')), isEmpty);
    });

      testWidgets('typed search text uses Plus Jakarta Sans', (tester) async {
      await pump(tester, const Size(390, 844));
      await tester.enterText(find.byType(TextField), 'adani');
      await tester.pump(const Duration(milliseconds: 100));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.style!.fontFamily, startsWith('PlusJakartaSans'));
      expect(field.controller!.text, 'adani');
    });

    testWidgets('AutoPay SVG and #696969 name / consumer number',
        (tester) async {
      await pump(tester, const Size(390, 844));
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture).first);
      expect(
        (svg.bytesLoader as SvgAssetLoader).assetName,
        FileConstants.autoPayBadge,
      );
      for (final value in [_saved.customerName, _saved.serviceNo]) {
        final text = tester.widget<Text>(find.text(value).first);
        expect(text.style!.color, const Color(0xFF696969));
      }
    });
  });

  group('Saved Billers heading and View all stay visible', () {
    void expectHeader(WidgetTester tester, Size size) {
      final title = find.text('Saved Billers');
      final viewAll = find.text('View all');
      expect(title, findsOneWidget);
      expect(viewAll, findsOneWidget);
      final titleRect = tester.getRect(title);
      final viewAllRect = tester.getRect(viewAll);
      expect(titleRect.width, greaterThan(0));
      expect(viewAllRect.width, greaterThan(0));
      expect(titleRect.left, greaterThanOrEqualTo(0));
      expect(viewAllRect.right, lessThanOrEqualTo(size.width));
      expect(
        viewAllRect.right,
        moreOrLessEquals(size.width - FetchProviderMetrics.w(24), epsilon: 1),
        reason: 'View all sits flush with the right inset',
      );
      expect(
        tester.widget<Text>(title).style!.fontSize,
        moreOrLessEquals(13.sp),
      );
      expect(
        tester.widget<Text>(viewAll).style!.fontSize,
        moreOrLessEquals(13.sp),
      );
      expect(titleRect.right, lessThanOrEqualTo(viewAllRect.left));
      // "View all" sits flush with the right inset, mirroring the title's
      // left inset, as in the Figma.
      final inset = FetchProviderMetrics.w(24);
      expect(titleRect.left, moreOrLessEquals(inset, epsilon: 0.5));
      expect(viewAllRect.right,
          moreOrLessEquals(size.width - inset, epsilon: 0.5));
    }

    for (final width in [320.0, 360.0, 375.0, 390.0, 412.0, 440.0]) {
      final size = Size(width, 800);
      testWidgets('with saved billers at ${width.toInt()}px', (tester) async {
        await pump(tester, size);
        expectHeader(tester, size);
        expect(tester.takeException(), isNull);
      });

      testWidgets('with no saved billers at ${width.toInt()}px',
          (tester) async {
        await pump(tester, size, savedBillers: () async => const []);
        expectHeader(tester, size);
        expect(find.byType(PopupMenuButton<String>), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('when the saved billers request fails', (tester) async {
      const size = Size(360, 800);
      await pump(
        tester,
        size,
        savedBillers: () => Future.error(Exception('network')),
      );
      expectHeader(tester, size);
      expect(tester.takeException(), isNull);
    });

    testWidgets('while saved billers are loading', (tester) async {
      const size = Size(360, 800);
      final pending = Completer<List<LatestTransaction>>();
      await pump(tester, size, savedBillers: () => pending.future);
      expectHeader(tester, size);
      pending.complete(const [_saved]);
      await tester.pump(const Duration(milliseconds: 100));
      expectHeader(tester, size);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });
  });

  group('FASTag and Book Gas use the shared search bar', () {
    for (final category in ['Fastag', 'LPG Gas']) {
      for (final width in [320.0, 360.0, 375.0, 390.0, 412.0, 440.0]) {
        testWidgets('$category at ${width.toInt()}px', (tester) async {
          final size = Size(width, 800);
          await pump(tester, size, categoryName: category);
          expect(tester.takeException(), isNull);

          final bar = find.byType(AppSearchBar);
          expect(bar, findsOneWidget);
          expect(find.text('Search Provider'), findsOneWidget);
          final rect = tester.getRect(bar);
          expect(rect.height, moreOrLessEquals(AppSearchBar.height));
          expect(rect.left, moreOrLessEquals(AppSearchBar.sideInset));
          expect(
            rect.right,
            moreOrLessEquals(size.width - AppSearchBar.sideInset),
          );
        });
      }
    }
  });
}
