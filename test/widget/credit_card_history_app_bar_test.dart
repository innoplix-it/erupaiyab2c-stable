import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/features/home/models/credit_card_item.dart';
import 'package:e_rupaiya/features/services/controllers/credit_card_transactions_controller.dart';
import 'package:e_rupaiya/features/services/models/credit_card_transaction.dart';
import 'package:e_rupaiya/features/services/repositories/credit_card_transactions_repository.dart';
import 'package:e_rupaiya/features/services/views/credit_card_intro_view.dart';
import 'package:e_rupaiya/features/services/views/credit_card_my_cards_view.dart';
import 'package:e_rupaiya/features/services/views/credit_card_transaction_detail_screen.dart';
import 'package:e_rupaiya/features/services/views/credit_card_transactions_screen.dart';
import 'package:e_rupaiya/widgets/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _sizes = <Size>[
  Size(320, 568),
  Size(360, 800),
  Size(440, 956),
  Size(800, 360),
];

CreditCardTransaction _tx(String status) => CreditCardTransaction(
      paymentStatus: status,
      billerName: 'SARAO00000NAT16',
      maskedIdentifier: '****9513',
      amount: '1.00',
      platformFees: '',
      totalAmountCharged: '1.00',
      paymentTransactionId: 'pay_TfnS3xZzQ6vlcc',
      bankReferenceId: '',
      transactionTime: '24 Sep 2026, 7:45am',
      method: '',
      methodIcon: '',
      paymentMode: '',
      vpa: '',
      rrn: '',
      icon: '',
    );

class _FakeTransactions extends CreditCardTransactionsRepository {
  _FakeTransactions() : super(dio: Dio());

  @override
  Future<CreditCardTransactionsResponse> fetchTransactions({
    required String maskedIdentifier,
    int page = 1,
    int limit = 10,
  }) async {
    return CreditCardTransactionsResponse(
      success: true,
      message: '',
      items: [_tx('SUCCESS'), _tx('FAILED')],
      currentPage: 1,
      totalPages: 1,
      totalRecords: 2,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAt(
    WidgetTester tester, {
    required Size size,
    required Widget home,
    List<Override> overrides = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) => ProviderScope(
          overrides: overrides,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              padding: const EdgeInsets.only(top: 24),
            ),
            child: MaterialApp(home: home),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  void expectNoOverflow(WidgetTester tester) {
    Object? exception;
    while ((exception = tester.takeException()) != null) {
      expect(
        exception.toString(),
        isNot(contains('overflowed')),
        reason: exception.toString(),
      );
    }
  }

  void expectSharedTitle(
    WidgetTester tester,
    String title, {
    required Color color,
  }) {
    final text = tester.widget<Text>(find.text(title));
    expect(text.style?.fontSize, 16);
    expect(text.style?.fontWeight, FontWeight.w700);
    expect(text.style?.letterSpacing, 0.15);
    expect(text.style?.height, 1.5);
    expect(text.style?.color, color);
  }

  Finder bharatConnect() {
    return find.byWidgetPredicate((widget) {
      if (widget is! Image) return false;
      final image = widget.image;
      return image is AssetImage &&
          image.assetName == FileConstants.bharatConnectColor;
    });
  }

  Finder circleIcons() {
    return find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final decoration = widget.decoration;
      return decoration is BoxDecoration && decoration.shape == BoxShape.circle;
    });
  }

  for (final size in _sizes) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('card transactions keep the common title at $label',
        (tester) async {
      await pumpAt(
        tester,
        size: size,
        overrides: [
          creditCardTransactionsRepositoryProvider.overrideWith(
            (ref) => _FakeTransactions(),
          ),
        ],
        home: const CreditCardTransactionsScreen(maskedIdentifier: '****9513'),
      );
      expectSharedTitle(tester, 'Card Transactions', color: Colors.black);
      expect(bharatConnect(), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.text('SARAO00000NAT16'), findsWidgets);
      expect(circleIcons(), findsNothing);
      final date = tester.getRect(find.text('24 Sep 2026, 7:45am').first);
      final success = tester.getRect(find.text('Success').first);
      expect(date.right, lessThanOrEqualTo(success.left + 1));
      final card = tester.getRect(
        find
            .ancestor(
                of: find.text('Success').first,
                matching: find.byType(Container))
            .first,
      );
      expect(success.right, lessThanOrEqualTo(card.right));
      expect(success.left, greaterThanOrEqualTo(card.left));
      expect(tester.getSize(find.byType(MyAppBar)).height, lessThan(100));
      expectNoOverflow(tester);
    });

    testWidgets('failed detail uses the common bar at $label', (tester) async {
      await pumpAt(
        tester,
        size: size,
        home: CreditCardTransactionDetailScreen(transaction: _tx('FAILED')),
      );
      expectSharedTitle(tester, 'Failed', color: Colors.black);
      expect(bharatConnect(), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.text('Payment Details'), findsOneWidget);
      expect(find.text('pay_TfnS3xZzQ6vlcc'), findsOneWidget);
      expect(circleIcons(), findsNothing);
      expect(tester.getSize(find.byType(MyAppBar)).height, lessThan(100));
      expectNoOverflow(tester);
    });
  }

  testWidgets('intro title uses the shared style and keeps its own header',
      (tester) async {
    await pumpAt(
      tester,
      size: const Size(360, 800),
      home: const CreditCardIntroView(),
    );
    final titles = tester.widgetList<Text>(find.text('Add New Card'));
    final title =
        titles.firstWhere((text) => text.style?.color == Colors.white);
    expect(title.style?.fontSize, 16);
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(title.style?.letterSpacing, 0.15);
    expect(title.style?.height, 1.5);
    expect(bharatConnect(), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expectNoOverflow(tester);
  });

  testWidgets('last paid date is #373737 and due date is #D30000',
      (tester) async {
    await pumpAt(
      tester,
      size: const Size(360, 800),
      home: Column(
        children: [
          CreditCardMyCardTile(
            item: const CreditCardItem(
              billerName: 'SARAO00000NAT16',
              maskedIdentifier: '****9513',
              lastAmount: 1,
              lastPaidDate: '2026-10-01',
              isDue: false,
            ),
            onOpenBills: () async {},
            onMenuTap: () {},
          ),
          CreditCardMyCardTile(
            item: const CreditCardItem(
              billerName: 'SARAO00000NAT16',
              maskedIdentifier: '****9513',
              lastAmount: 1,
              dueDate: '2026-10-06',
              isDue: true,
            ),
            onOpenBills: () async {},
            onMenuTap: () {},
          ),
        ],
      ),
    );

    final lastPaid = tester.widget<Text>(find.text('Last Paid On 1 Oct 2026'));
    final due = tester.widget<Text>(find.text('Due On 6 Oct 2026'));
    expect(lastPaid.style?.color, const Color(0xFF373737));
    expect(due.style?.color, const Color(0xFFD30000));
    expectNoOverflow(tester);
  });
}
