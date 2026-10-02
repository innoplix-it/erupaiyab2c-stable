import 'package:e_rupaiya/features/services/components/fetch_provider_metrics.dart';
import 'package:e_rupaiya/features/services/models/bill_response_model.dart';
import 'package:e_rupaiya/features/services/views/biller_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  const sampleBill = BillResponse(
    refId: 'REF123',
    fetchRefId: 'FETCH123',
    amountInPaisa: '45000',
    accountHolderName: 'Rahul Sharma',
    dueDate: '2025-10-06',
    billDate: '2025-09-25',
    billPeriod: '2509',
    billNumber: 'BILL789',
    otherDetails: {
      'Last Paid Amount': '450',
      'Last Paid Date': '2025-12-06',
    },
    additionalParams: {
      'Customer Number': '058927104563',
      'Early Payment Date': '2025-09-25',
      'PC': '2',
    },
    approvalRefNum: 'APP123',
    note:
        'An Additional ₹10 Fee Will Apply If The Bill Is Paid After 6th May, 12:00 AM.',
  );

  Widget buildTestWidget({
    required Size screenSize,
    double textScale = 1.0,
    VoidCallback? onToggle,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: screenSize,
        textScaler: TextScaler.linear(textScale),
      ),
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElectricityBillSection(
                    bill: sampleBill,
                    customerParams: const {
                      'Customer Number': '058927104563',
                    },
                    onToggle: onToggle ?? () {},
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  group('Electricity Bill Details Section Tests', () {
    testWidgets('renders all cards, SVGs, and dynamic values', (tester) async {
      var toggled = false;

      await tester.pumpWidget(
        buildTestWidget(
          screenSize: const Size(392, 844),
          onToggle: () => toggled = true,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Consumer info checks
      expect(find.text('Customer Number'), findsOneWidget);
      expect(find.text('058927104563'), findsOneWidget);
      expect(find.text('Early Payment Date'), findsOneWidget);
      expect(find.text('2025-09-25'), findsOneWidget);
      expect(find.text('PC'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Verify toggle button works
      final svgWidgets = find.byType(SvgPicture);
      expect(svgWidgets, findsNWidgets(3)); // Down arrow, clock, info

      await tester.tap(svgWidgets.first);
      expect(toggled, isTrue);

      // 2. Bill / Payment card checks
      expect(find.text("Bill for Sep '25"), findsOneWidget);
      expect(find.text('Due on: 6th Oct'), findsOneWidget);
      expect(find.text('₹450.00'), findsOneWidget);
      expect(find.textContaining('Last Paid'), findsOneWidget);
      expect(find.textContaining('6 Dec 2025'), findsOneWidget);

      // 3. Additional fee card checks
      expect(
        find.textContaining('An Additional ₹10 Fee Will Apply'),
        findsOneWidget,
      );
    });

    const testSizes = [
      Size(320, 568),
      Size(320, 700),
      Size(360, 640),
      Size(375, 812),
      Size(390, 844),
      Size(412, 915),
      Size(440, 956),
    ];

    for (final size in testSizes) {
      testWidgets(
          'fits ${size.width.toInt()}x${size.height.toInt()} with zero overflow',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(screenSize: size),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('₹450.00'), findsOneWidget);
      });

      testWidgets(
          'fits ${size.width.toInt()}x${size.height.toInt()} with text scale 1.15',
          (tester) async {
        await tester.pumpWidget(
          buildTestWidget(screenSize: size, textScale: 1.15),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('₹450.00'), findsOneWidget);
      });
    }
  });

  group('Figma layout on the Pay Now frame', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    Future<void> pumpOnDevice(
      WidgetTester tester,
      double width, {
      BillResponse bill = sampleBill,
      bool expanded = false,
      VoidCallback? onToggle,
    }) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = Size(width, width * 956 / 440) * 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
                    .copyWith(textScaler: const TextScaler.linear(1.15)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: FetchProviderMetrics.w(24),
                    ),
                    child: ElectricityBillSection(
                      bill: bill,
                      customerParams: const {
                        'Customer Number': '058927104563',
                      },
                      onToggle: onToggle ?? () {},
                      isExpanded: expanded,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder feeText() => find.textContaining('Will Apply');

    Finder feeCard() =>
        find.ancestor(of: feeText(), matching: find.byType(ClipRRect)).first;

    for (final width in [320.0, 360.0, 375.0, 390.0, 412.0, 440.0]) {
      testWidgets('fee card matches Figma at ${width.toInt()}px',
          (tester) async {
        await pumpOnDevice(tester, width);
        expect(tester.takeException(), isNull);

        double fx(double px) => px * width / 440;
        final card = tester.getRect(feeCard());
        expect(card.left, moreOrLessEquals(fx(24), epsilon: 0.5));
        expect(card.width, moreOrLessEquals(fx(392), epsilon: 0.5));
        expect(
          card.height,
          greaterThanOrEqualTo(FetchProviderMetrics.h(72) - 0.5),
        );

        final container = tester.widget<Container>(
          find
              .descendant(of: feeCard(), matching: find.byType(Container))
              .first,
        );
        final decoration = container.decoration! as BoxDecoration;
        final border = decoration.border! as Border;
        expect(decoration.color, const Color(0xFFFAFAFA));
        expect(border.left.color, const Color(0xFFDD5428));
        expect(border.left.width, moreOrLessEquals(1.5.w));
        expect(border.top, BorderSide.none);
        expect(border.right, BorderSide.none);
        expect(border.bottom, BorderSide.none);

        final icon = tester.getRect(
          find.descendant(of: feeCard(), matching: find.byType(SvgPicture)),
        );
        final text = tester.getRect(feeText());
        expect(
          icon.left,
          moreOrLessEquals(card.left + 1.5.w + fx(16), epsilon: 0.5),
        );
        expect(
          text.right,
          lessThanOrEqualTo(card.right - fx(16) + 0.5),
        );
        expect(
          icon.center.dy,
          moreOrLessEquals(
            tester.getRect(feeText()).top + 12.sp * 1.15 * 20 / 12 / 2,
            epsilon: 1,
          ),
        );
        expect(text.left - icon.right, moreOrLessEquals(fx(10), epsilon: 0.5));
        expect(icon.top, greaterThanOrEqualTo(card.top));
        expect(text.top, greaterThan(card.top));
        expect(text.bottom, lessThan(card.bottom));
        expect(text.right, lessThanOrEqualTo(card.right));

        final style = tester.widget<RichText>(
          find.descendant(of: feeCard(), matching: find.byType(RichText)),
        );
        final root = (style.text as TextSpan).children!.single as TextSpan;
        expect(root.style!.fontSize, moreOrLessEquals(12.sp));
        expect(root.style!.fontWeight, FontWeight.w400);
        expect(root.style!.fontFamily, contains('PlusJakartaSans'));
        expect(root.style!.height, moreOrLessEquals(20 / 12));
        final bold = root.children!
            .cast<TextSpan>()
            .where((s) => s.style?.fontWeight == FontWeight.w700)
            .map((s) => s.text)
            .toList();
        expect(bold, ['₹10 Fee']);

        for (final label in ['Customer Number', '₹450.00', 'Due on: 6th Oct']) {
          final r = tester.getRect(find.text(label));
          expect(r.left, greaterThanOrEqualTo(0), reason: label);
          expect(r.right, lessThanOrEqualTo(width), reason: label);
        }
      });
    }

    testWidgets('backend note is shown in the Figma format', (tester) async {
      const rawNoteBill = BillResponse(
        refId: 'REF123',
        fetchRefId: 'FETCH123',
        amountInPaisa: '77000',
        accountHolderName: 'Rahul Sharma',
        dueDate: '2026-10-06',
        billDate: '2026-09-16',
        billPeriod: '2609',
        billNumber: 'BILL789',
        otherDetails: {},
        additionalParams: {},
        approvalRefNum: 'APP123',
        note:
            'An Additional Rs.10 fee will apply if the bill is paid after 2026-10-06, 12:00AM.',
      );
      await pumpOnDevice(tester, 412, bill: rawNoteBill);
      expect(tester.takeException(), isNull);

      final rich = tester.widget<RichText>(
        find.descendant(of: feeCard(), matching: find.byType(RichText)),
      );
      expect(
        rich.text.toPlainText(),
        'An Additional ₹10 Fee Will Apply If The Bill Is Paid After 6th Oct, '
        '12:00 AM.',
      );
    });

    const fullBill = BillResponse(
      refId: 'REF123',
      fetchRefId: 'FETCH123',
      amountInPaisa: '45000',
      accountHolderName: 'RAHUL SURESH PATIL',
      dueDate: '2025-10-06',
      billDate: '2025-09-25',
      billPeriod: '2509',
      billNumber: 'BILL789',
      otherDetails: {
        'Early Payment Amount': '44000',
        'Late Payment Amount': '45000',
        'Last Paid Amount': '450',
        'Last Paid Date': '2025-12-06',
      },
      additionalParams: {
        'Early Payment Date': '2025-09-25',
        'PC': '2',
        'Disconn Tag': '0',
        'Bill Month': '2509',
        'DTC Code': '6700044',
        'Bill Type': 'POSTPAID',
      },
      approvalRefNum: 'APP123',
      note:
          'An Additional ₹10 Fee Will Apply If The Bill Is Paid After 6th May, 12:00 AM.',
    );

    for (final width in [320.0, 360.0, 375.0, 390.0, 412.0, 440.0]) {
      testWidgets('expanded details match Figma at ${width.toInt()}px',
          (tester) async {
        var toggles = 0;
        await pumpOnDevice(
          tester,
          width,
          bill: fullBill,
          expanded: true,
          onToggle: () => toggles++,
        );
        expect(tester.takeException(), isNull);

        for (final entry in {
          'Customer Number': '058927104563',
          'Early Payment Date': '2025-09-25',
          'PC': '2',
          'Disconn Tag': '0',
          'Bill Month': '2509',
          'DTC Code': '6700044',
          'Bill Type': 'POSTPAID',
          'Customer Name': 'RAHUL SURESH PATIL',
          'Due Date': '6 Oct 2025',
          'Early payment date & amount': 'Before 25 Sep 2025 – ₹440.00',
          'Due payment date & amount': '25 Sep to 6 Oct 2025 – ₹440.00',
          'Late payment date & amount': 'After 6 Oct 2025 – ₹450.00',
        }.entries) {
          final label = tester.getRect(find.text(entry.key));
          final value = tester.getRect(find.text(entry.value));
          expect(label.left, greaterThanOrEqualTo(0), reason: entry.key);
          expect(value.right, lessThanOrEqualTo(width), reason: entry.value);
          expect(label.right, lessThan(value.left), reason: entry.key);
          expect(label.top, moreOrLessEquals(value.top, epsilon: 4),
              reason: entry.key);
        }

        expect(feeText(), findsNothing);
        expect(find.text('₹450.00'), findsOneWidget);

        final toggle = find.byKey(const ValueKey('electricity-details-toggle'));
        final arrow = tester.getRect(toggle);
        final card = tester.getRect(
          find
              .ancestor(
                of: find.text('Customer Number'),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(arrow.center.dx, moreOrLessEquals(card.center.dx, epsilon: 1));
        expect(arrow.center.dy, moreOrLessEquals(card.bottom, epsilon: 1));
        expect(arrow.width, moreOrLessEquals(FetchProviderMetrics.r(32)));

        final svg = tester.widget<SvgPicture>(
          find.descendant(of: toggle, matching: find.byType(SvgPicture)),
        );
        expect(
          (svg.bytesLoader as SvgStringLoader).toString(),
          isNotEmpty,
        );

        await tester.tap(toggle);
        expect(toggles, 1);
      });
    }
  });
}
