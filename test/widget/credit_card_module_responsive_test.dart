import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/home/controllers/home_controller.dart';
import 'package:e_rupaiya/features/home/models/credit_card_item.dart';
import 'package:e_rupaiya/features/home/models/home_state.dart';
import 'package:e_rupaiya/features/home/repositories/home_repository.dart';
import 'package:e_rupaiya/features/services/components/credit_card/credit_card_figma_metrics.dart';
import 'package:e_rupaiya/features/services/components/credit_card_pay_now/credit_card_pay_now_section.dart';
import 'package:e_rupaiya/features/services/controllers/credit_card_transactions_controller.dart';
import 'package:e_rupaiya/features/services/models/bill_response_model.dart';
import 'package:e_rupaiya/features/services/models/credit_card_transaction.dart';
import 'package:e_rupaiya/features/services/repositories/credit_card_transactions_repository.dart';
import 'package:e_rupaiya/features/home/models/banner_model.dart';
import 'package:e_rupaiya/features/services/controllers/service_extras_controller.dart';
import 'package:e_rupaiya/features/services/views/credit_card_intro_view.dart';
import 'package:e_rupaiya/features/services/views/credit_card_my_cards_view.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:e_rupaiya/features/services/views/credit_card_transaction_detail_screen.dart';
import 'package:e_rupaiya/features/services/views/credit_card_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _widths = <double>[320, 360, 375, 390, 414, 440];
const _scales = <double>[0.85, 1.0, 1.15];

CreditCardTransaction _longTx() => const CreditCardTransaction(
      paymentStatus: 'SUCCESS',
      billerName: 'Saraswat Co-Operative Bank Ltd Credit Card',
      maskedIdentifier: 'XXXX7355055961',
      amount: '30000.00',
      platformFees: '15.50',
      totalAmountCharged: '30015.50',
      paymentTransactionId:
          'TXN-CC-2026-05-06-ABCDEFGHIJKLMNOPQRSTUVWXYZ-998877',
      bankReferenceId: 'BANKREF-VERY-LONG-REFERENCE-ID-123456789012345',
      transactionTime: '6 May 2026, 05:29 PM',
      method: 'UPI',
      methodIcon: '',
      paymentMode: 'UPI',
      vpa: 'very.long.customer.name@oksbi',
      rrn: '12345678901234567890',
      icon: '',
    );

class _CardsHomeController extends HomeController {
  _CardsHomeController() : super(repository: HomeRepository(dio: Dio())) {
    state = const HomeState(
      isFetchingCreditCards: false,
      creditCardActions: [
        CreditCardItem(
          billerName: 'Saraswat Co-Operative Bank Ltd',
          maskedIdentifier: '****2656',
          lastAmount: 1,
          lastPaidDate: '2026-07-08',
          isDue: false,
        ),
      ],
    );
  }

  @override
  Future<void> fetchCreditCardActions() async {}
}

class _FakeCreditCardTransactionsRepository
    extends CreditCardTransactionsRepository {
  _FakeCreditCardTransactionsRepository() : super(dio: Dio());

  @override
  Future<CreditCardTransactionsResponse> fetchTransactions({
    required String maskedIdentifier,
    int page = 1,
    int limit = 10,
  }) async {
    return CreditCardTransactionsResponse(
      success: true,
      message: '',
      items: [_longTx()],
      currentPage: 1,
      totalPages: 1,
      totalRecords: 1,
    );
  }
}

class _LargeFakeCreditCardTransactionsRepository
    extends CreditCardTransactionsRepository {
  _LargeFakeCreditCardTransactionsRepository() : super(dio: Dio());

  @override
  Future<CreditCardTransactionsResponse> fetchTransactions({
    required String maskedIdentifier,
    int page = 1,
    int limit = 10,
  }) async {
    final items = List.generate(
      50,
      (i) => CreditCardTransaction(
        paymentStatus: i % 3 == 0 ? 'SUCCESS' : (i % 3 == 1 ? 'FAILED' : 'PENDING'),
        billerName: 'Bank ${i + 1} Credit Card',
        maskedIdentifier: 'XXXX${(i + 1).toString().padLeft(4, '0')}',
        amount: '${(i + 1) * 1000}.00',
        platformFees: '15.50',
        totalAmountCharged: '${(i + 1) * 1000 + 15.50}',
        paymentTransactionId: 'TXN-$i-ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        bankReferenceId: 'BANKREF-$i-123456789012345',
        transactionTime: '${i + 1} May 2026, 12:00 PM',
        method: 'UPI',
        methodIcon: '',
        paymentMode: 'UPI',
        vpa: 'user$i@oksbi',
        rrn: '123456789012345678',
        icon: '',
      ),
    );
    return CreditCardTransactionsResponse(
      success: true,
      message: '',
      items: items,
      currentPage: page,
      totalPages: 5,
      totalRecords: 50,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSized(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    double keyboard = 0,
    required Widget home,
    List<Override> overrides = const [],
    double bottomInset = 0,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.padding = FakeViewPadding(top: 24, bottom: bottomInset);
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
              textScaler: TextScaler.linear(textScale),
              viewInsets: EdgeInsets.only(bottom: keyboard),
              padding: EdgeInsets.only(top: 24, bottom: bottomInset),
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
      final text = exception.toString();
      expect(text, isNot(contains('overflowed')), reason: text);
    }
  }

  for (final width in _widths) {
    for (final scale in _scales) {
      final label = '${width.toInt()}px text $scale';

      testWidgets('credit card detail has no overflow at $label',
          (tester) async {
        await pumpSized(
          tester,
          size: Size(width, 800),
          textScale: scale,
          home: CreditCardTransactionDetailScreen(transaction: _longTx()),
        );
        expect(find.text('Payment Details'), findsOneWidget);
        expectNoOverflow(tester);
      });

      testWidgets('credit card detail stays laid out with keyboard at $label',
          (tester) async {
        await pumpSized(
          tester,
          size: Size(width, 700),
          textScale: scale,
          keyboard: 280,
          home: CreditCardTransactionDetailScreen(transaction: _longTx()),
        );
        expectNoOverflow(tester);
      });

      testWidgets('card transactions list has no overflow at $label',
          (tester) async {
        await pumpSized(
          tester,
          size: Size(width, 800),
          textScale: scale,
          overrides: [
            creditCardTransactionsRepositoryProvider.overrideWith(
              (ref) => _FakeCreditCardTransactionsRepository(),
            ),
          ],
          home:
              const CreditCardTransactionsScreen(maskedIdentifier: 'XXXX1234'),
        );
        expect(find.text('Saraswat Co-Operative Bank Ltd Credit Card'),
            findsOneWidget);
        expectNoOverflow(tester);
      });

      testWidgets('add card intro has no overflow at $label', (tester) async {
        await pumpSized(
          tester,
          size: Size(width, width < 360 ? 568 : 800),
          textScale: scale,
          home: const CreditCardIntroView(),
        );
        expect(find.text('Add New Card'), findsWidgets);
        expectNoOverflow(tester);
      });
    }
  }

  testWidgets('pay now amount choices fit at 320px with 1.15 text',
      (tester) async {
    const bill = BillResponse(
      refId: 'r',
      fetchRefId: 'f',
      amountInPaisa: '3000000',
      accountHolderName: 'SARAOOOOONAT16 VERY LONG ACCOUNT HOLDER NAME',
      dueDate: '2026-05-06',
      billDate: '2026-04-06',
      billPeriod: 'Monthly',
      billNumber: 'BILL-99887766554433221100',
      otherDetails: {},
      additionalParams: {},
      approvalRefNum: 'APPROVAL-REF-12345678901234567890',
      note: '',
    );
    final amount = TextEditingController(text: '30000');
    addTearDown(amount.dispose);
    await pumpSized(
      tester,
      size: const Size(320, 700),
      textScale: 1.15,
      keyboard: 240,
      home: Scaffold(
        body: SingleChildScrollView(
          child: CreditCardPayNowSection(
            bill: bill,
            totalOutstanding: 30000,
            minimumDue: 1500,
            selected: CreditCardPayNowAmountType.total,
            onChanged: (_) {},
            amountController: amount,
          ),
        ),
      ),
    );
    expect(find.text('Minimum Due'), findsOneWidget);
    expect(find.text('Total Amount'), findsOneWidget);
    expectNoOverflow(tester);
  });

  for (final width in _widths) {
    for (final scale in _scales) {
      for (final bottomInset in <double>[0, 34]) {
        testWidgets(
          'Add New Card sits on the Figma bottom inset at '
          '${width.toInt()}px text $scale inset $bottomInset',
          (tester) async {
            final height = width < 360 ? 568.0 : 844.0;
            await pumpSized(
              tester,
              size: Size(width, height),
              textScale: scale,
              bottomInset: bottomInset,
              overrides: [
                homeControllerProvider.overrideWith(
                  (ref) => _CardsHomeController(),
                ),
                servicePageBannersProvider.overrideWith(
                  (ref, slug) async => const <BannerModel>[],
                ),
              ],
              home: const CreditCardMyCardsView(),
            );
            expectNoOverflow(tester);
            final button = tester.getRect(find.byType(CustomElevatedButton));
            final side = CreditCardFigmaMetrics.s(
              tester.element(find.byType(CustomElevatedButton)),
              20,
            );
            final bottomGap = CreditCardFigmaMetrics.sy(
                  tester.element(find.byType(CustomElevatedButton)),
                  16,
                ) +
                bottomInset;
            expect(button.left, moreOrLessEquals(side, epsilon: 1.5));
            expect(
              button.right,
              moreOrLessEquals(width - side, epsilon: 1.5),
            );
            expect(
              button.bottom,
              moreOrLessEquals(height - bottomGap, epsilon: 1.5),
            );
            expect(button.top, greaterThan(0));
            expect(find.text('Add New Card'), findsOneWidget);
          },
        );
      }
    }
  }

  // Landscape orientation tests
  for (final width in _widths) {
    for (final scale in _scales) {
      testWidgets('transactions screen fits landscape ${width.toInt()}px text $scale',
          (tester) async {
        await pumpSized(
          tester,
          size: Size(width, 400),
          textScale: scale,
          overrides: [
            creditCardTransactionsRepositoryProvider.overrideWith(
              (ref) => _FakeCreditCardTransactionsRepository(),
            ),
          ],
          home: const CreditCardTransactionsScreen(maskedIdentifier: 'XXXX1234'),
        );
        expectNoOverflow(tester);
      });
    }
  }

  // Tablet size tests (>458px width)
  const tabletWidths = <double>[600, 768, 834, 1024];
  for (final width in tabletWidths) {
    for (final scale in _scales) {
      testWidgets('transactions screen fits tablet ${width.toInt()}px text $scale',
          (tester) async {
        await pumpSized(
          tester,
          size: Size(width, 900),
          textScale: scale,
          overrides: [
            creditCardTransactionsRepositoryProvider.overrideWith(
              (ref) => _FakeCreditCardTransactionsRepository(),
            ),
          ],
          home: const CreditCardTransactionsScreen(maskedIdentifier: 'XXXX1234'),
        );
        expectNoOverflow(tester);
      });
    }
  }

  // Long card identifier test
  testWidgets('transactions screen handles very long masked identifier',
      (tester) async {
    final longIdRepo = _FakeCreditCardTransactionsRepository();
    await pumpSized(
      tester,
      size: const Size(320, 700),
      textScale: 1.15,
      overrides: [
        creditCardTransactionsRepositoryProvider.overrideWith(
          (ref) => longIdRepo,
        ),
      ],
      home: const CreditCardTransactionsScreen(
          maskedIdentifier: 'XXXX123456789012345678901234567890'),
    );
    expectNoOverflow(tester);
  });

  // Large transaction count test (pagination)
  testWidgets('transactions screen handles large transaction count',
      (tester) async {
    await pumpSized(
      tester,
      size: const Size(390, 844),
      textScale: 1.0,
      overrides: [
        creditCardTransactionsRepositoryProvider.overrideWith(
          (ref) => _LargeFakeCreditCardTransactionsRepository(),
        ),
      ],
      home: const CreditCardTransactionsScreen(maskedIdentifier: 'XXXX1234'),
    );
    expectNoOverflow(tester);
    // Verify the screen renders with content
    expect(find.text('Card Transactions'), findsOneWidget);
  });
}
