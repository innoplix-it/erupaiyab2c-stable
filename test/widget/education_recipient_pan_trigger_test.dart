import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/views/education_fees_recipient_view.dart';

// ---------------------------------------------------------------------------
// Widget-level tests for the Education Fees recipient PAN field.
//
// The screen auto-verifies the PAN once a complete, valid number is entered.
// These tests drive the real field and prove the verify-pan request is only
// fired for a complete, well-formed PAN, never for a partial or malformed
// number, and never twice for the same unchanged value.
// ---------------------------------------------------------------------------

class _FakeEducationRepository extends EducationFeesRepository {
  _FakeEducationRepository() : super();

  final verifyPanCalls = <String>[];

  @override
  Future<EducationCheckMobileResponse> checkMobile(String mobile) async {
    return const EducationCheckMobileResponse(status: true, exists: true);
  }

  @override
  Future<EducationVerifyPanResponse> verifyPan({
    required String name,
    required String pan,
    required String deviceId,
  }) async {
    verifyPanCalls.add(pan);
    return const EducationVerifyPanResponse(status: true);
  }
}

Future<EducationFeesController> _pumpRecipientView(
  WidgetTester tester,
  _FakeEducationRepository repository,
) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(390, 844) * 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        educationFeesRepositoryProvider.overrideWithValue(repository),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          home: const EducationFeesRecipientView(),
        ),
      ),
    ),
  );
  await tester.pump();

  final controller = ProviderScope.containerOf(
    tester.element(find.byType(EducationFeesRecipientView)),
  ).read(educationFeesControllerProvider.notifier);

  // A verified existing recipient mobile reveals the recipient fields.
  await tester.enterText(_field(0), '9876543210');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return controller;
}

Finder _field(int index) => find.descendant(
      of: find.byType(TextField).at(index),
      matching: find.byType(EditableText),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late _FakeEducationRepository repository;

  setUp(() {
    repository = _FakeEducationRepository();
  });

  testWidgets('partial PAN entry (1-9 characters) never calls verify-pan',
      (tester) async {
    await _pumpRecipientView(tester, repository);
    await tester.enterText(_field(1), 'Ravi Kumar');
    await tester.pump();

    const partial = [
      'A',
      'AB',
      'ABC',
      'ABCD',
      'ABCDE',
      'ABCDE1',
      'ABCDE12',
      'ABCDE123',
      'ABCDE1234'
    ];
    for (final pan in partial) {
      await tester.enterText(_field(2), pan);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(repository.verifyPanCalls, isEmpty);
  });

  testWidgets('complete but invalid PAN does not call verify-pan',
      (tester) async {
    await _pumpRecipientView(tester, repository);
    await tester.enterText(_field(1), 'Ravi Kumar');
    await tester.pump();

    // The PAN formatter drops non-conforming characters, so these strings stay
    // complete-but-invalid (or empty) rather than truncating to a valid PAN.
    for (final pan in ['ABCDEFGHIJ', '1234567890', 'ABCD12345E']) {
      await tester.enterText(_field(2), pan);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(repository.verifyPanCalls, isEmpty);
    expect(find.text('PAN verified'), findsNothing);
  });

  testWidgets('a complete valid PAN triggers verify-pan exactly once',
      (tester) async {
    final controller = await _pumpRecipientView(tester, repository);
    await tester.enterText(_field(1), 'Ravi Kumar');
    await tester.pump();

    await tester.enterText(_field(2), 'ABCDE1234F');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repository.verifyPanCalls, ['ABCDE1234F']);
    expect(controller.state.panVerified, isTrue);
    // Success is now shown by the in-field verified badge, not a text row,
    // so the transient "Verifying PAN..." status must have cleared.
    expect(find.text('Verifying PAN...'), findsNothing);

    // Requirement 4: rebuilding with the number unchanged must not re-fire.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(repository.verifyPanCalls, hasLength(1));
  });

  testWidgets('a duplicate callback for the same unchanged PAN is ignored',
      (tester) async {
    await _pumpRecipientView(tester, repository);
    await tester.enterText(_field(1), 'Ravi Kumar');
    await tester.pump();
    await tester.enterText(_field(2), 'ABCDE1234F');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(repository.verifyPanCalls, hasLength(1));

    // Simulates a repeated listener/callback delivering the same value.
    await tester.enterText(_field(2), 'ABCDE1234F');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(repository.verifyPanCalls, hasLength(1));
  });

  testWidgets(
      'editing to a new valid PAN re-verifies and shows only the latest result',
      (tester) async {
    final controller = await _pumpRecipientView(tester, repository);
    await tester.enterText(_field(1), 'Ravi Kumar');
    await tester.pump();
    await tester.enterText(_field(2), 'ABCDE1234F');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(repository.verifyPanCalls, hasLength(1));

    // Clearing invalidates the verification result for the old value.
    await tester.enterText(_field(2), '');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.state.panVerified, isFalse);
    expect(find.text('PAN verified'), findsNothing);

    await tester.enterText(_field(2), 'XYZAB1234C');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(repository.verifyPanCalls, ['ABCDE1234F', 'XYZAB1234C']);
  });

  testWidgets('recipient PAN keyboard switches letters -> numbers -> letters',
      (tester) async {
    await _pumpRecipientView(tester, repository);
    await tester.enterText(_field(1), 'Ravi Kumar');
    await tester.pump();

    TextInputType panKeyboard() =>
        tester.widget<TextField>(find.byType(TextField).at(2)).keyboardType;

    // Stage 1: alphabetic keyboard for the first 5 characters.
    expect(panKeyboard(), TextInputType.text);

    await tester.enterText(_field(2), 'ABCDE');
    await tester.pump();
    // Stage 2: numeric keyboard once 5 letters are entered.
    expect(panKeyboard(), TextInputType.number);

    await tester.enterText(_field(2), 'ABCDE1234');
    await tester.pump();
    // Stage 3: back to alphabetic for the final letter.
    expect(panKeyboard(), TextInputType.text);

    await tester.enterText(_field(2), 'ABCDE1234F');
    await tester.pump();
    expect(panKeyboard(), TextInputType.text);
  });
}
