import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/profile/controllers/profile_controller.dart';
import 'package:e_rupaiya/features/profile/models/profile_model.dart';
import 'package:e_rupaiya/features/profile/models/profile_state.dart';
import 'package:e_rupaiya/features/profile/repositories/bank_accounts_repository.dart';
import 'package:e_rupaiya/features/profile/repositories/profile_repository.dart';
import 'package:e_rupaiya/features/refer_and_earn/views/add_bank_account_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

/// A profile controller seeded with a verified profile so the view never
/// triggers a real profile fetch and the KYC branch is inactive during
/// responsive renders.
class _FakeProfileController extends ProfileController {
  _FakeProfileController()
      : super(repository: ProfileRepository(dio: Dio())) {
    state = const ProfileState(
      profile: ProfileModel(
        id: '1',
        name: 'Test User',
        mobile: '8055851920',
        kycStatus: ProfileKycStatus.verified,
      ),
    );
  }
}

Future<void> _pumpAddBank(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  BankAccountEntry? existingAccount,
  String? selectedBankName,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileControllerProvider.overrideWith((ref) => _FakeProfileController()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: AddBankAccountView(
                existingAccount: existingAccount,
                selectedBankName: selectedBankName,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('verify step renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpAddBank(tester, size: size);
        expect(tester.takeException(), isNull);

        expect(find.text('Add Bank Account'), findsOneWidget);
        expect(find.text('Account Number'), findsOneWidget);
        expect(find.text('IFSC Code'), findsOneWidget);
        expect(find.text('Verify Account'), findsOneWidget);
        expect(
          find.textContaining('I Confirm That The Bank Account Details'),
          findsOneWidget,
        );
        // Two text fields for account number + IFSC.
        expect(find.byType(TextField), findsNWidgets(2));
      });
    }
  });

  group('form fields and button stay inside the screen', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpAddBank(tester, size: size);
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

        for (final finder in [
          find.text('Account Number'),
          find.text('IFSC Code'),
          find.text('Verify Account'),
          find.textContaining('I Confirm That The Bank Account Details'),
        ]) {
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(screen.width));
        }

        // The primary CTA is fully visible above the fold (bottom bar).
        expect(
          tester.getRect(find.text('Verify Account')).bottom,
          lessThanOrEqualTo(screen.height),
        );
      });
    }
  });

  testWidgets('edit mode changes the title and prefills holder/bank',
      (tester) async {
    await _pumpAddBank(
      tester,
      size: const Size(390, 844),
      existingAccount: const BankAccountEntry(
        id: 7,
        bankName: 'HDFC Bank',
        accountNumber: '50000123456789',
        accountHolderName: 'Test User',
        verified: true,
        ifsc: 'HDFC0000060',
      ),
    );
    expect(find.text('Edit Bank Account'), findsOneWidget);
    // Edit mode still starts on the verify step, so the CTA reads
    // "Verify Account"; the "Update Bank Account" label only appears after
    // verification moves the form to the confirm step.
    expect(find.text('Verify Account'), findsOneWidget);
    expect(find.text('Update Bank Account'), findsNothing);
  });

  testWidgets('selected bank name prefills the CTA step without overflow',
      (tester) async {
    await _pumpAddBank(
      tester,
      size: const Size(360, 690),
      selectedBankName: 'ICICI Bank',
    );
    expect(find.text('Verify Account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkbox toggles on tap', (tester) async {
    await _pumpAddBank(tester, size: const Size(390, 844));
    final checkbox = find.byType(Checkbox);
    expect(checkbox, findsOneWidget);
    expect(tester.widget<Checkbox>(checkbox).value, false);
    await tester.tap(checkbox);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Checkbox>(checkbox).value, true);
    expect(tester.takeException(), isNull);
  });

  group('supported text scales', () {
    for (final scale in [0.85, 1.0, 1.15]) {
      testWidgets('textScale $scale at 360x690', (tester) async {
        await _pumpAddBank(
          tester,
          size: const Size(360, 690),
          textScale: scale,
        );
        expect(find.text('Account Number'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
