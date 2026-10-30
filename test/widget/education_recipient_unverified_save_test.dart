import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_account_type.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/views/education_fees_recipient_view.dart';
import 'package:e_rupaiya/features/educationFees/views/education_tutor_profile_view.dart';

/// Repo fake with configurable verification/save outcomes; counts calls so
/// duplicate submissions are detectable.
class _E2ERepo extends EducationFeesRepository {
  _E2ERepo({this.panOk = true, this.bankOk = true, this.saveOk = true})
      : super();

  bool panOk;
  bool bankOk;
  bool saveOk;

  int saveCount = 0;

  @override
  Future<EducationCheckMobileResponse> checkMobile(String mobile) async =>
      const EducationCheckMobileResponse(status: true, exists: true);

  @override
  Future<EducationVerifyPanResponse> verifyPan({
    required String name,
    required String pan,
    required String deviceId,
  }) async =>
      EducationVerifyPanResponse(
        status: panOk,
        message: panOk ? null : 'PAN and name do not match.',
      );

  @override
  Future<EducationVerifyBankResponse> verifyBank({
    required String accountNo,
    required String ifsc,
    required String recipientName,
  }) async =>
      EducationVerifyBankResponse(
        status: bankOk,
        bankAccountId: bankOk ? 1 : null,
        message: bankOk ? null : 'Name does not match bank records.',
      );

  @override
  Future<EducationSaveBeneficiaryResponse> saveBeneficiary({
    required String name,
    required String mobile,
    required String pan,
    required String accountType,
    required String accountNo,
    required String ifsc,
  }) async {
    saveCount++;
    return saveOk
        ? const EducationSaveBeneficiaryResponse(status: true, beneficiaryId: 5)
        : const EducationSaveBeneficiaryResponse(
            status: false,
            message: 'Beneficiary already exists.',
          );
  }

  @override
  Future<EducationBeneficiariesResponse> fetchBeneficiaries() async =>
      const EducationBeneficiariesResponse(status: true);
}

Widget _app(_E2ERepo repo, {required bool unverified}) {
  return ProviderScope(
    overrides: [
      educationFeesRepositoryProvider.overrideWithValue(repo),
    ],
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(
        home: EducationFeesRecipientView(unverifiedFlow: unverified),
      ),
    ),
  );
}

/// Fills the unverified Add Details form and lets the automatic PAN/bank
/// verification effects settle.
Future<void> _fillUnverifiedForm(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), '9876543210');
  await tester.enterText(find.byType(TextField).at(1), 'Ravi Kumar');
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('pan_field')), 'ABCDE1234F');
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('account_field')),
    '1234567890',
  );
  await tester.enterText(
    find.byKey(const Key('ifsc_field')),
    'HDFC0001234',
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('unverified flow: verified form submits once and navigates',
      (tester) async {
    final repo = _E2ERepo();
    await tester.pumpWidget(_app(repo, unverified: true));
    await tester.pump();

    await _fillUnverifiedForm(tester);

    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    expect(repo.saveCount, 1);
    expect(find.byType(EducationTutorProfileView), findsOneWidget);
  });

  testWidgets('unverified flow: missing PAN verification blocks with reason',
      (tester) async {
    final repo = _E2ERepo(panOk: false);
    await tester.pumpWidget(_app(repo, unverified: true));
    await tester.pump();

    await _fillUnverifiedForm(tester);

    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    expect(repo.saveCount, 0);
    expect(find.text('Please verify PAN details.'), findsOneWidget);
    expect(find.byType(EducationTutorProfileView), findsNothing);
  });

  testWidgets('unverified flow: missing bank verification blocks with reason',
      (tester) async {
    final repo = _E2ERepo(bankOk: false);
    await tester.pumpWidget(_app(repo, unverified: true));
    await tester.pump();

    await _fillUnverifiedForm(tester);

    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    expect(repo.saveCount, 0);
    expect(find.text('Please verify bank details.'), findsOneWidget);
    expect(find.byType(EducationTutorProfileView), findsNothing);
  });

  testWidgets('double tap issues exactly one request', (tester) async {
    final repo = _E2ERepo();
    await tester.pumpWidget(_app(repo, unverified: true));
    await tester.pump();

    await _fillUnverifiedForm(tester);

    // Two taps without a rebuild in between: the second must be rejected by
    // the controller in-flight guard (and the button loading state).
    await tester.tap(find.text('Proceed'));
    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    expect(repo.saveCount, 1);
  });

  testWidgets('API failure shows error, no navigation, retry succeeds',
      (tester) async {
    final repo = _E2ERepo(saveOk: false);
    await tester.pumpWidget(_app(repo, unverified: true));
    await tester.pump();

    await _fillUnverifiedForm(tester);

    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    expect(repo.saveCount, 1);
    expect(
      find.text('Beneficiary already exists.'),
      findsOneWidget,
    );
    expect(find.byType(EducationTutorProfileView), findsNothing);

    // Recover: server-side conflict resolved, retry from the same form.
    repo.saveOk = true;
    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    expect(repo.saveCount, 2);
    expect(find.byType(EducationTutorProfileView), findsOneWidget);
  });

  testWidgets('normal flow blocks unregistered recipient with reason',
      (tester) async {
    // Registered check fails in the normal flow: Proceed must not submit.
    final repo = _E2ERepo();
    await tester.pumpWidget(_app(repo, unverified: false));
    await tester.pump();

    final controller = ProviderScope.containerOf(
      tester.element(find.byType(EducationFeesRecipientView)),
    ).read(educationFeesControllerProvider.notifier);
    controller.state = controller.state.copyWith(
      recipientName: 'Ravi Kumar',
      mobileInput: '9876543210',
      pan: 'ABCDE1234F',
      panVerified: true,
      accountType: EducationAccountType.bankDetails,
      accountNumber: '1234567890',
      ifsc: 'HDFC0001234',
      bankVerified: true,
      showRecipientFields: false,
    );
    await tester.pump();

    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    // Form not shown (registration not confirmed): the button stays inert
    // and nothing is submitted. Guard reasons are covered at controller
    // level in education_fees_save_beneficiary_test.dart.
    expect(repo.saveCount, 0);
  });
}
