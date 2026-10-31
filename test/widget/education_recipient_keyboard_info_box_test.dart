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

/// Pumps the recipient form with a synthetic [keyboardInset] injected through
/// the root [MediaQuery]. The view reads [MediaQuery.viewInsets] to decide
/// whether the keyboard is open, so a non-zero bottom inset reproduces the
/// "keyboard visible" state without a real IME.
Widget _app({required double keyboardInset}) {
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
          ),
          child: child!,
        ),
        home: const EducationFeesRecipientView(unverifiedFlow: true),
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

const _infoText = 'We will notify the recipient via SMS';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpForm(WidgetTester tester, double inset) async {
    _setSize(tester, const Size(360, 690));
    await tester.pumpWidget(_app(keyboardInset: inset));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
  }

  testWidgets('info box is shown when the keyboard is closed', (tester) async {
    await pumpForm(tester, 0);

    expect(find.textContaining(_infoText), findsOneWidget);
    expect(find.text('Proceed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('info box is hidden when the keyboard opens', (tester) async {
    await pumpForm(tester, 300);

    expect(find.textContaining(_infoText), findsNothing);
    // The Proceed button must remain available while typing.
    expect(find.text('Proceed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('info box reappears after the keyboard is dismissed',
      (tester) async {
    await pumpForm(tester, 300);
    expect(find.textContaining(_infoText), findsNothing);

    // Dismiss the keyboard (inset back to 0) and rebuild.
    await tester.pumpWidget(_app(keyboardInset: 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.textContaining(_infoText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
