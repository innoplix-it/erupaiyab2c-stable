import 'package:e_rupaiya/features/services/models/bill_response_model.dart';
import 'package:e_rupaiya/features/services/views/biller_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

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
      testWidgets('fits ${size.width.toInt()}x${size.height.toInt()} with zero overflow',
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
}
