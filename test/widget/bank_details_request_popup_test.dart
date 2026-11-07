import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_rupaiya/features/educationFees/components/bank_details_request_popup.dart';

Widget _app(Widget home) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    fontSizeResolver: FontSizeResolvers.radius,
    builder: (context, _) => MaterialApp(home: home),
  );
}

void main() {
  testWidgets('terms link opens the terms screen without the checkbox', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showBankDetailsRequestPopup(
                context,
                requesterName: 'Darshan Nikam',
                feeType: 'tuition fees',
                amount: 2000,
                paymentPurpose: 'Tuition Fees',
                paymentMethod: 'Credit Card',
                paymentStatus: 'Not Yet Paid',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Bank Details Request'), findsOneWidget);
    expect(find.textContaining('Darshan Nikam'), findsOneWidget);
    expect(find.text('Share Details'), findsOneWidget);

    final share = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Share Details'),
    );
    expect(share.onPressed, isNull);

    await tester.ensureVisible(find.byKey(const ValueKey('bank-details-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bank-details-checkbox')));
    await tester.pumpAndSettle();

    expect(find.text('Terms & Conditions'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Terms & Conditions'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Bank Details Request'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.byKey(const ValueKey('bank-details-checkbox')));
    await tester.pumpAndSettle();
    expect(find.text('Terms & Conditions'), findsOneWidget);
    await tester.tap(find.text('I Disagree'));
    await tester.pumpAndSettle();
    expect(find.text('Bank Details Request'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Share Details'),
          )
          .onPressed,
      isNull,
    );

    await tester.ensureVisible(find.text('I agree '));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I agree '));
    await tester.pumpAndSettle();

    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('1. Purpose of Payment'), findsOneWidget);
    expect(find.text('7. Security'), findsOneWidget);

    await tester.tap(find.text('I Agree'));
    await tester.pumpAndSettle();

    expect(find.text('Bank Details Request'), findsOneWidget);
    expect(find.byKey(const ValueKey('bank-details-checkbox-checked')), findsOneWidget);
    final enabled = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Share Details'),
    );
    expect(enabled.onPressed, isNotNull);
    expect(
      enabled.style?.backgroundColor?.resolve(const <WidgetState>{}),
      const Color(0xFFDD5428),
    );
  });

  testWidgets('popup lays out on a short phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showBankDetailsRequestPopup(
                context,
                requesterName: 'Darshan Nikam',
                feeType: 'tuition fees',
                amount: 2000,
                paymentPurpose: 'Tuition Fees',
                paymentMethod: 'Credit Card',
                paymentStatus: 'Not Yet Paid',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('popup lays out on a tablet and in landscape', (tester) async {
    Future<void> openAt(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showBankDetailsRequestPopup(
                  context,
                  requesterName: 'Darshan Nikam',
                  feeType: 'tuition fees',
                  amount: 2000,
                  paymentPurpose: 'Tuition Fees',
                  paymentMethod: 'Credit Card',
                  paymentStatus: 'Not Yet Paid',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Bank Details Request'), findsOneWidget);
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));
    await openAt(const Size(768, 1024));
    await openAt(const Size(800, 360));
  });
}
