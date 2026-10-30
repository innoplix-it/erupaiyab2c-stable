import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_account_type.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/views/education_fees_recipient_view.dart';
import '../helpers/responsive_test_sizes.dart';

class _FakeRepo extends EducationFeesRepository {
  _FakeRepo() : super();

  @override
  Future<EducationCheckMobileResponse> checkMobile(String mobile) async =>
      const EducationCheckMobileResponse(status: true, exists: true);

  @override
  Future<EducationVerifyPanResponse> verifyPan({
    required String name,
    required String pan,
    required String deviceId,
  }) async =>
      const EducationVerifyPanResponse(status: true);

  @override
  Future<EducationVerifyBankResponse> verifyBank({
    required String accountNo,
    required String ifsc,
    required String recipientName,
  }) async =>
      const EducationVerifyBankResponse(status: true, bankAccountId: 1);
}

Widget _app({required bool unverified}) {
  return ProviderScope(
    overrides: [
      educationFeesRepositoryProvider.overrideWithValue(_FakeRepo()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(
        theme: ThemeData(
          textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        ),
        home: EducationFeesRecipientView(unverifiedFlow: unverified),
      ),
    ),
  );
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = size * 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpAndExpand(WidgetTester tester, Size size) async {
  _setSize(tester, size);
  await tester.pumpWidget(_app(unverified: false));
  await tester.pump();

  final controller = ProviderScope.containerOf(
    tester.element(find.byType(EducationFeesRecipientView)),
  ).read(educationFeesControllerProvider.notifier);

  // Drive the form to its fully-expanded (verified) state.
  controller.updateMobileInput('9876543210');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
  
  // Enter text via TextField to ensure controllers are synced
  await tester.enterText(find.byType(TextField).at(0), '9876543210');
  await tester.pump();
  await tester.enterText(find.byType(TextField).at(1), 'Ravi Kumar');
  await tester.pump();
  await tester.enterText(find.byType(TextField).at(2), 'ABCDE1234F');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
  
  controller.updateAccountType(EducationAccountType.bankDetails);
  await tester.pump();
  
  await tester.enterText(find.byKey(const Key('account_field')), '89120100012345');
  await tester.pump();
  await tester.enterText(find.byKey(const Key('ifsc_field')), 'BARB0123456');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
}

Future<void> _pumpUnverified(WidgetTester tester, Size size) async {
  _setSize(tester, size);
  await tester.pumpWidget(_app(unverified: true));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('expanded form renders the Figma sections and CTAs',
      (tester) async {
    await _pumpAndExpand(tester, const Size(360, 690));

    expect(find.text('PERSONAL DETAILS'), findsOneWidget);
    expect(find.text("Tutor's Mobile Number"), findsOneWidget);
    expect(find.text("Tutor's Name (as per PAN)"), findsOneWidget);
    expect(find.text('PAN Number'), findsOneWidget);
    expect(find.text('Subject (Optional)'), findsOneWidget);
    expect(find.text('BANK DETAILS'), findsOneWidget);
    expect(find.text('Account Number'), findsOneWidget);
    expect(find.text('IFSC Code'), findsOneWidget);
    expect(find.text('Proceed'), findsOneWidget);
    // Contact button + verified badges render as SVGs in-field.
    expect(find.byType(SvgPicture), findsWidgets);
    // Typed PAN digits must be visible in the field.
    expect(find.text('ABCDE1234F'), findsOneWidget);
  });

  testWidgets('PAN field shows typed text in uppercase and limits to 10',
      (tester) async {
    await _pumpUnverified(tester, const Size(360, 690));

    // PAN is the 3rd TextField (mobile, name, PAN, ...); its key is now a
    // stage-varying ValueKey, so locate it positionally.
    final panField = find.byType(TextField).at(2);
    await tester.enterText(panField, 'abcde1234fxyz');
    await tester.pump();

    expect(find.text('ABCDE1234F'), findsOneWidget);
    final field = tester.widget<TextField>(panField);
    expect(field.controller!.text, 'ABCDE1234F');
    expect(field.style?.color, isNotNull);
  });

  testWidgets('stays overflow-free across the device matrix', (tester) async {
    for (final size in responsiveTestScreenSizes) {
      await _pumpAndExpand(tester, size);
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
    }
  });

  testWidgets('unverified flow shows the full form immediately (no input)',
      (tester) async {
    await _pumpUnverified(tester, const Size(360, 690));

    expect(find.text('PERSONAL DETAILS'), findsOneWidget);
    expect(find.text("Tutor's Name (as per PAN)"), findsOneWidget);
    expect(find.text('PAN Number'), findsOneWidget);
    expect(find.text('Subject (Optional)'), findsOneWidget);
    expect(find.text('BANK DETAILS'), findsOneWidget);
    expect(find.text('Account Number'), findsOneWidget);
    expect(find.text('IFSC Code'), findsOneWidget);
    expect(find.text('Proceed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'unverified flow keeps bank details visible after typing name/PAN',
      (tester) async {
    await _pumpUnverified(tester, const Size(360, 690));

    expect(find.text('Account Number'), findsOneWidget);

    // Typing in the name/PAN fields resets accountType in the controller;
    // the view must re-pin it so the bank section never disappears.
    await tester.enterText(find.byType(TextField).at(1), 'Ravi Kumar');
    await tester.pumpAndSettle();
    expect(find.text('Account Number'), findsOneWidget);
    expect(find.text('IFSC Code'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(2), 'ABCDE1234F');
    await tester.pumpAndSettle();
    expect(find.text('Account Number'), findsOneWidget);
    expect(find.text('IFSC Code'), findsOneWidget);
    expect(find.byKey(const Key('account_field')), findsOneWidget);
    expect(find.byKey(const Key('ifsc_field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'verified flow keeps bank details visible after editing name/PAN/account/IFSC',
      (tester) async {
    await _pumpAndExpand(tester, const Size(360, 690));

    expect(find.text('Account Number'), findsOneWidget);
    expect(find.text('IFSC Code'), findsOneWidget);

    // Edit recipient name - bank details must remain visible
    await tester.enterText(find.byType(TextField).at(1), 'Rajesh Kumar');
    await tester.pumpAndSettle();
    expect(find.text('Account Number'), findsOneWidget);
    expect(find.text('IFSC Code'), findsOneWidget);

    // Edit PAN - bank details must remain visible
    await tester.enterText(find.byType(TextField).at(2), 'FGHIJ5678K');
    await tester.pumpAndSettle();
    expect(find.text('Account Number'), findsOneWidget);
    expect(find.text('IFSC Code'), findsOneWidget);

    // Edit account number - bank details must remain visible
    await tester.enterText(find.byKey(const Key('account_field')), '89120100067890');
    await tester.pumpAndSettle();
    expect(find.text('Account Number'), findsOneWidget);
    expect(find.text('IFSC Code'), findsOneWidget);

    // Edit IFSC - bank details must remain visible
    await tester.enterText(find.byKey(const Key('ifsc_field')), 'SBIN0001234');
    await tester.pumpAndSettle();
    expect(find.text('Account Number'), findsOneWidget);
    expect(find.text('IFSC Code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back navigation clears form data', (tester) async {
    await _pumpAndExpand(tester, const Size(360, 690));

    final controller = ProviderScope.containerOf(
      tester.element(find.byType(EducationFeesRecipientView)),
    ).read(educationFeesControllerProvider.notifier);

    // Verify form has data
    expect(controller.state.mobileInput, '9876543210');
    expect(controller.state.recipientName, 'Ravi Kumar');
    expect(controller.state.pan, 'ABCDE1234F');
    expect(controller.state.accountNumber, '89120100012345');
    expect(controller.state.ifsc, 'BARB0123456');

    // Simulate back navigation by calling reset
    controller.reset();
    await tester.pump();

    // Verify all data is cleared
    expect(controller.state.mobileInput, '');
    expect(controller.state.recipientName, '');
    expect(controller.state.pan, '');
    expect(controller.state.accountNumber, '');
    expect(controller.state.ifsc, '');
    expect(controller.state.accountType, EducationAccountType.none);
    expect(controller.state.panVerified, false);
    expect(controller.state.bankVerified, false);
  });
}
