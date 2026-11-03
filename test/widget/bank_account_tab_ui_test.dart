import 'package:e_rupaiya/features/profile/components/bank_account_tab_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Figma reference values for the "Bank Account" tab of Personal Details.
const _kBankName = 'HDFC Bank';
const _kMasked = 'XXXX XXXX 1234';
const _kHolder = 'Darshan Nikam';
const _kIfsc = 'HDFC0001234';
const _kBranch = 'Warje, Pune';

/// Matches a card painted with the Figma hairline: 1px solid #E4E4E4.
const _hairlineSide = BorderSide(width: 1, color: Color(0xFFE4E4E4));

Finder findHairlineCards() => find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final decoration = widget.decoration;
      if (decoration is! BoxDecoration) return false;
      return decoration.border is Border &&
          decoration.border!.top == _hairlineSide &&
          decoration.border!.bottom == _hairlineSide;
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester,
    Size size,
    Widget child,
  ) async {
    const dpr = 2.0;
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = size * dpr;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Widget emptyState(VoidCallback onAdd) =>
      BankEmptyState(onAdd: onAdd);

  Widget savedAccount({
    bool showDetails = true,
    VoidCallback? onView,
    VoidCallback? onDelete,
    VoidCallback? onChange,
  }) =>
      BankAccountCard(
        bankName: _kBankName,
        maskedAccount: _kMasked,
        holderName: _kHolder,
        ifsc: _kIfsc,
        branch: _kBranch,
        showDetails: showDetails,
        onView: onView,
        onDelete: onDelete,
        onChange: onChange,
      );

  group('Bank Account tab empty state', () {
    testWidgets('shows the bank illustration, copy and CTA', (tester) async {
      var addCalls = 0;
      await pump(tester, const Size(360, 690), emptyState(() => addCalls++));

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('Add Bank Account'), findsOneWidget);
      expect(
        find.text('Link your bank account to manage\nsettlements securely'),
        findsOneWidget,
      );
      expect(find.text('+ Add Bank Account'), findsOneWidget);

      await tester.tap(find.text('+ Add Bank Account'));
      await tester.pump();
      expect(addCalls, 1);
    });

    for (final size in const [
      Size(320, 568), // narrow
      Size(360, 690), // design base
      Size(430, 932), // large
    ]) {
      testWidgets('renders without overflow at ${size.width}x${size.height}',
          (tester) async {
        await pump(tester, size, emptyState(() {}));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Bank Account tab saved account', () {
    testWidgets('summary card is hidden behind View until tapped',
        (tester) async {
      var viewCalls = 0;
      await pump(
        tester,
        const Size(360, 690),
        savedAccount(showDetails: false, onView: () => viewCalls++),
      );

      // Summary card only: logo fallback, name, masked number and View pill.
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
      expect(find.text(_kBankName), findsOneWidget);
      expect(find.text(_kMasked), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      expect(find.text('IFSC Code'), findsNothing);
      expect(find.text('Branch'), findsNothing);
      expect(find.text('Delete'), findsNothing);

      await tester.tap(find.text('View'));
      await tester.pump();
      expect(viewCalls, 1);
    });

    testWidgets('details card lists bank, holder, IFSC and branch',
        (tester) async {
      await pump(tester, const Size(360, 690), savedAccount());

      expect(find.text('Bank Name'), findsOneWidget);
      expect(find.text('Account Holder Name'), findsOneWidget);
      expect(find.text('IFSC Code'), findsOneWidget);
      expect(find.text('Branch'), findsOneWidget);
      expect(find.text(_kHolder), findsOneWidget);
      expect(find.text(_kIfsc), findsOneWidget);
      expect(find.text(_kBranch), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
    });

    testWidgets('both cards use the 1px #E4E4E4 hairline', (tester) async {
      await pump(tester, const Size(360, 690), savedAccount());
      expect(findHairlineCards(), findsNWidgets(2));
    });

    testWidgets('Delete and Change fire their callbacks', (tester) async {
      var deleteCalls = 0;
      var changeCalls = 0;
      await pump(
        tester,
        const Size(360, 690),
        savedAccount(
          onDelete: () => deleteCalls++,
          onChange: () => changeCalls++,
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.tap(find.text('Change'));
      await tester.pump();
      expect(deleteCalls, 1);
      expect(changeCalls, 1);
    });

    testWidgets('blank backend fields fall back to "--"', (tester) async {
      await pump(
        tester,
        const Size(360, 690),
        const BankAccountCard(
          bankName: _kBankName,
          maskedAccount: _kMasked,
          holderName: '',
          ifsc: '',
          branch: '',
        ),
      );
      expect(find.text('--'), findsNWidgets(3));
    });

    for (final size in const [
      Size(320, 568), // narrow
      Size(360, 690), // design base
      Size(430, 932), // large
    ]) {
      testWidgets('renders without overflow at ${size.width}x${size.height}',
          (tester) async {
        await pump(tester, size, savedAccount());
        expect(tester.takeException(), isNull);
      });
    }
  });
}
