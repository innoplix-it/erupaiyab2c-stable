// Verifies that opening a fresh add-beneficiary form clears the previous
// beneficiary's PAN / Account Number / IFSC, while preserving mobile and name.
//
// The shared EducationFeesController is persistent (not auto-dispose), so
// without the mount-time clear these fields would re-seed from the last entry.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/views/education_fees_recipient_view.dart';

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

Widget _app(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      child: MaterialApp(
        theme: ThemeData(
          textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        ),
        // Unverified "Add Details" flow shows the full form immediately and
        // skips the mobile-registration check, so the assertions below are
        // isolated from unrelated side effects.
        home: const EducationFeesRecipientView(unverifiedFlow: true),
      ),
    ),
  );
}

String _fieldText(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(Key(key))).controller!.text;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('new form opens with PAN / Account / IFSC cleared',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        educationFeesRepositoryProvider.overrideWithValue(_FakeRepo()),
      ],
    );
    addTearDown(container.dispose);

    // Simulate a fully completed previous beneficiary persisted in the
    // (non auto-dispose) controller.
    final notifier = container.read(educationFeesControllerProvider.notifier);
    notifier.updateMobileInput('9876543210');
    notifier.updateRecipientName('Ravi Kumar');
    notifier.updatePan('ABCDE1234F');
    notifier.updateAccountNumber('89120100012345');
    notifier.updateIfsc('BARB0123456');

    final seeded = container.read(educationFeesControllerProvider);
    expect(seeded.pan, 'ABCDE1234F');
    expect(seeded.accountNumber, '89120100012345');
    expect(seeded.ifsc, 'BARB0123456');

    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    // The three identity/bank fields must be empty on the fresh form.
    expect(_fieldText(tester, 'pan_field'), isEmpty);
    expect(_fieldText(tester, 'account_field'), isEmpty);
    expect(_fieldText(tester, 'ifsc_field'), isEmpty);

    // And cleared in the controller too (not just visually).
    final after = container.read(educationFeesControllerProvider);
    expect(after.pan, isEmpty);
    expect(after.accountNumber, isEmpty);
    expect(after.ifsc, isEmpty);
    // Verification flags reset so a stale "verified" cannot enable Proceed.
    expect(after.panVerified, isFalse);
    expect(after.bankVerified, isFalse);

    // Mobile and name are intentionally preserved.
    expect(_fieldText(tester, 'name_field'), 'Ravi Kumar');
  });
}
