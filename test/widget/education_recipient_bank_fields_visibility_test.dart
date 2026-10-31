import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_account_type.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_state.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/views/education_fees_recipient_view.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';

/// Regression coverage for the "BANK DETAILS fields disappear" bug:
/// the persistent provider can retain a stale `upiId` from the verified flow
/// (system back never runs the AppBar `controller.reset()`), and the
/// unverified Add Details flow hides the Account Type picker, so its pinning
/// effect must repair ANY stale accountType — not only `none` — or the
/// Account Number / IFSC widgets are dropped from the tree.
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

  @override
  Future<EducationBeneficiariesResponse> fetchBeneficiaries() async =>
      const EducationBeneficiariesResponse(status: true);
}

late ProviderContainer _container;

/// Home route with two buttons so the views are *pushed* and can be popped
/// with the system back gesture (`pageBack`), exactly like in the app.
Widget _harness() {
  return UncontrolledProviderScope(
    container: _container,
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  key: const Key('open_verified'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EducationFeesRecipientView(),
                    ),
                  ),
                  child: const SizedBox.shrink(),
                ),
                ElevatedButton(
                  key: const Key('open_unverified'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const EducationFeesRecipientView(unverifiedFlow: true),
                    ),
                  ),
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

EducationFeesState _state() => _container.read(educationFeesControllerProvider);

Future<void> _openUnverifiedFlow(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open_unverified')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _container = ProviderContainer(
      overrides: [
        educationFeesRepositoryProvider.overrideWithValue(_FakeRepo()),
      ],
    );
  });
  tearDown(() => _container.dispose());

  testWidgets('unverified flow repairs stale upiId: bank fields appear',
      (tester) async {
    await tester.pumpWidget(_harness());
    // Simulate the verified flow having left `upiId` behind (what the
    // Account Type sheet's onSelect does) WITHOUT any reset.
    _container
        .read(educationFeesControllerProvider.notifier)
        .updateAccountType(EducationAccountType.upiId);
    expect(_state().accountType, EducationAccountType.upiId);

    await _openUnverifiedFlow(tester);

    expect(find.byKey(const Key('account_field')), findsOneWidget);
    expect(find.byKey(const Key('ifsc_field')), findsOneWidget);
    expect(_state().accountType, EducationAccountType.bankDetails);
  });

  testWidgets(
      'navigation regression: UPI via sheet in verified flow, system back, '
      'then unverified Add Details still shows bank fields', (tester) async {
    await tester.pumpWidget(_harness());

    // 1. Verified flow: open, verify a registered mobile so the picker shows.
    await tester.tap(find.byKey(const Key('open_verified')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.pumpAndSettle();
    expect(find.text('Select Account Type'), findsOneWidget);

    // 2. Select UPI ID through the real Account Type sheet.
    final picker = find.ancestor(
      of: find.text('Select Account Type'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(picker);
    await tester.pumpAndSettle();
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('UPI ID'));
    await tester.pumpAndSettle();
    expect(_state().accountType, EducationAccountType.upiId);

    // 3. Exit with SYSTEM back (not the AppBar arrow): pop the route directly
    // so the AppBar's `onBack` (the only `controller.reset()` call site) is
    // never invoked — exactly what Android's back gesture does.
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(_state().accountType, EducationAccountType.upiId,
        reason: 'system back must leave the persistent provider untouched');

    // 4. Open the unverified Add Details flow: stale upiId must be repaired.
    await _openUnverifiedFlow(tester);
    expect(find.byKey(const Key('account_field')), findsOneWidget);
    expect(find.byKey(const Key('ifsc_field')), findsOneWidget);
    expect(_state().accountType, EducationAccountType.bankDetails);
  });

  testWidgets('unverified flow from none seeds bankDetails: fields appear',
      (tester) async {
    await tester.pumpWidget(_harness());
    expect(_state().accountType, EducationAccountType.none);

    await _openUnverifiedFlow(tester);

    expect(find.byKey(const Key('account_field')), findsOneWidget);
    expect(find.byKey(const Key('ifsc_field')), findsOneWidget);
    expect(_state().accountType, EducationAccountType.bankDetails);
  });

  testWidgets('verified flow keeps stale upiId (picker still user-controlled)',
      (tester) async {
    await tester.pumpWidget(_harness());
    _container
        .read(educationFeesControllerProvider.notifier)
        .updateAccountType(EducationAccountType.upiId);

    await tester.tap(find.byKey(const Key('open_verified')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.pumpAndSettle();

    // The pinning effect is unverified-flow only: the verified flow must NOT
    // auto-switch away from UPI ID.
    expect(_state().accountType, EducationAccountType.upiId);
    expect(find.byKey(const Key('account_field')), findsNothing);
    expect(find.text('UPI ID'), findsOneWidget);
  });
}
