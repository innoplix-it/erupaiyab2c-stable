import 'package:e_rupaiya/features/services/components/credit_card_pay_now/credit_card_pay_now_section.dart';
import 'package:e_rupaiya/features/services/models/bill_response_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/responsive_test_sizes.dart';

final _sizes = responsiveTestScreenSizes.where((s) {
  for (final required in const <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(360, 690),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
    Size(440, 956),
    Size(458, 1024),
  ]) {
    if (s.width == required.width && s.height == required.height) return true;
  }
  return false;
}).toList();

BillResponse _bill() => const BillResponse(
      refId: 'r1',
      fetchRefId: 'f1',
      amountInPaisa: '3000000',
      accountHolderName: 'Sandip Patil',
      dueDate: '2026-05-11',
      billDate: '2026-05-11',
      billPeriod: '',
      billNumber: '1',
      otherDetails: {'Minimum Amount Due': '150000'},
      additionalParams: {},
      approvalRefNum: '',
      note: '',
      ecoinsRestrictionsPercent: 0,
    );

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required Widget child,
}) async {
  final view = tester.view;
  view.physicalSize = size;
  view.devicePixelRatio = 1;
  addTearDown(view.resetPhysicalSize);
  addTearDown(view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pay Now section matches Figma labels across phone sizes',
      (tester) async {
    expect(_sizes, hasLength(9));
    final controller = TextEditingController(text: '30000');
    addTearDown(controller.dispose);

    for (final size in _sizes) {
      await _pump(
        tester,
        size: size,
        child: CreditCardPayNowSection(
          bill: _bill(),
          totalOutstanding: 30000,
          minimumDue: 1500,
          selected: CreditCardPayNowAmountType.total,
          onChanged: (_) {},
          amountController: controller,
        ),
      );

      expect(find.text('Bill Amount'), findsOneWidget);
      expect(find.textContaining('Due on'), findsOneWidget);
      expect(find.text('Minimum Due'), findsOneWidget);
      expect(find.text('Total Amount'), findsOneWidget);
      expect(find.textContaining('Customer Name'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
