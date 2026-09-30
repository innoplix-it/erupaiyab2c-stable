import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/latest_transaction.dart';
import 'package:e_rupaiya/features/services/components/service_recent_section.dart';

const _txn = LatestTransaction(
  id: '1',
  billerId: 'b1',
  paymentType: 'electricity',
  billerName: 'Maharashtra State Electricity Distribution Co. Ltd',
  amount: 1250,
  status: 'success',
  transactionRef: 'ref',
  serviceNo: '170019239876',
  icon: '',
  customerName: 'rahul sharma',
  autoPayActive: true,
  createdAt: '2026-09-01T10:00:00Z',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<List<LatestTransaction>> pump(
    WidgetTester tester, {
    required Size size,
    double textScale = 1.0,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = size * 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final paid = <LatestTransaction>[];
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                body: ServiceRecentSection(
                  recentTransactions: const AsyncValue.data([_txn, _txn]),
                  title: 'Saved Billers',
                  savedBillersStyle: true,
                  onPayNow: paid.add,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return paid;
  }

  Size cardSize(WidgetTester tester) => tester.getSize(
        find
            .ancestor(
              of: find.text('170019239876').first,
              matching: find.byType(GestureDetector),
            )
            .last,
      );

  testWidgets('card is 325x131 on the 440x956 Figma frame', (tester) async {
    await pump(tester, size: const Size(440, 956));
    final size = cardSize(tester);
    expect(size.width, moreOrLessEquals(325, epsilon: 0.5));
    expect(size.height, moreOrLessEquals(131, epsilon: 1.5));
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 390.0, 440.0]) {
    testWidgets('no overflow at ${width.toInt()}px with 1.15 text',
        (tester) async {
      await pump(tester, size: Size(width, 700), textScale: 1.15);
      expect(tester.takeException(), isNull);
      expect(cardSize(tester).width, lessThan(width));
    });
  }

  testWidgets('3-dot menu opens bottom sheet with Delete AutoPay, View History, Delete Account',
      (tester) async {
    await pump(tester, size: const Size(360, 740));
    // Tap 3-dot icon
    final dotTap = find.ancestor(
      of: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_VerticalDots'),
      matching: find.byType(GestureDetector),
    ).first;
    await tester.tap(dotTap);
    await tester.pumpAndSettle();

    expect(find.text('Delete AutoPay'), findsOneWidget);
    expect(find.text('View History'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.text('170019239876'), findsAtLeastNWidgets(1));

    // Tap close X icon
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Delete AutoPay'), findsNothing);
  });
}
