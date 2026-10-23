import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/profile/controllers/recent_payment_help_controller.dart';
import 'package:e_rupaiya/features/profile/models/support_faq_item.dart';
import 'package:e_rupaiya/features/profile/models/support_latest_transaction.dart';
import 'package:e_rupaiya/features/profile/repositories/support_faq_repository.dart';
import 'package:e_rupaiya/features/profile/views/recent_payment_help_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _widths = <double>[320, 360, 375, 390, 412, 414, 440];

const _transaction = SupportLatestTransaction(
  id: 'bill-1',
  paymentType: 'Utility Payment',
  billerName: 'Maharashtra State Electricity Distribution',
  amount: '160.00',
  status: 'failed',
  date: '2026-03-08 10:00:00',
  type: 'BBPS',
  transactionId: 'txn-1',
);

const _faqs = [
  SupportFaqItem(
    id: '1',
    title: 'Why is my payment still pending?',
    description: 'Payments can take a short time to update.',
  ),
  SupportFaqItem(
    id: '2',
    title: 'How long does a refund take if payment fails?',
    description: 'Refunds are returned to the original method.',
  ),
];

class _ScriptedFaqRepository extends SupportFaqRepository {
  _ScriptedFaqRepository(this.items) : super(dio: Dio());

  final List<SupportFaqItem> items;

  @override
  Future<List<SupportFaqItem>> fetchFaqs({required String category}) async {
    return items;
  }
}

void _applyView(
  WidgetTester tester, {
  required double width,
  double height = 844,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _drainNonLayoutErrors(WidgetTester tester) {
  Object? error = tester.takeException();
  while (error != null) {
    final text = '$error';
    expect(text, isNot(contains('RenderFlex')));
    expect(text, isNot(contains('overflowed')));
    error = tester.takeException();
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required List<SupportFaqItem> faqs,
  required double width,
  double height = 844,
  double textScale = 1,
}) async {
  _applyView(tester, width: width, height: height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportFaqRepositoryProvider.overrideWithValue(
          _ScriptedFaqRepository(faqs),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const RecentPaymentHelpScreen(transaction: _transaction),
        ),
      ),
    ),
  );
  await _settle(tester);
  _drainNonLayoutErrors(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('recent payment screen shows the transaction and every FAQ',
      (tester) async {
    await _pump(tester, faqs: _faqs, width: 390);

    expect(find.text('Need help with your recent payment?'), findsOneWidget);
    expect(find.text('Utility Payment'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(
      find.text('Maharashtra State Electricity Distribution'),
      findsOneWidget,
    );
    expect(find.text('₹160.00'), findsOneWidget);
    expect(find.text("FAQ's"), findsOneWidget);
    expect(find.text('Why is my payment still pending?'), findsOneWidget);
    expect(
      find.text('How long does a refund take if payment fails?'),
      findsOneWidget,
    );
    expect(find.text('Still need help?'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    _drainNonLayoutErrors(tester);
  });

  testWidgets('a single API FAQ is shown and is not replaced', (tester) async {
    await _pump(
      tester,
      faqs: const [
        SupportFaqItem(id: 't', title: 'test e', description: 'Only one.'),
      ],
      width: 390,
    );

    expect(find.text('test e'), findsOneWidget);
    expect(find.text('Why is my payment still pending?'), findsNothing);
    expect(find.text('No FAQs available'), findsNothing);
  });

  testWidgets('FAQ tap opens that item description', (tester) async {
    await _pump(tester, faqs: _faqs, width: 390);

    await tester.tap(find.text('Why is my payment still pending?'));
    await _settle(tester);
    expect(
      find.text('Payments can take a short time to update.'),
      findsOneWidget,
    );
    expect(
      find.text('Refunds are returned to the original method.'),
      findsNothing,
    );
    _drainNonLayoutErrors(tester);
  });

  testWidgets('Still need help opens the existing ticket screen',
      (tester) async {
    await _pump(tester, faqs: _faqs, width: 390);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Still need help?'));
    await _settle(tester);
    expect(find.text('Write To Us'), findsOneWidget);
    expect(find.text('Select Transaction'), findsOneWidget);
    _drainNonLayoutErrors(tester);
  });

  for (final width in _widths) {
    for (final textScale in [1.0, 1.15]) {
      testWidgets(
        'recent payment layout fits $width at text scale $textScale',
        (tester) async {
          await _pump(
            tester,
            faqs: _faqs,
            width: width,
            height: width == 320 ? 568 : 844,
            textScale: textScale,
          );
          expect(
            find.text('Need help with your recent payment?'),
            findsOneWidget,
          );
          final button = find.text('Still need help?');
          await tester.ensureVisible(button);
          await tester.pump();
          expect(button, findsOneWidget);
          _drainNonLayoutErrors(tester);
        },
      );
    }
  }
}
