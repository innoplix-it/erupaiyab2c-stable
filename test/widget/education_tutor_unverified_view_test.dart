import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/views/education_tutor_unverified_view.dart';
import '../helpers/responsive_test_sizes.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(home: child),
      ),
    );

Widget _view() => const EducationTutorUnverifiedView(
      tutorName: 'Test Tutor Name',
      amount: 2000,
      amountLabel: '\u20B92000',
    );

class _FakeAskKycRepository extends EducationFeesRepository {
  int sendCount = 0;
  final askReferences = <String?>[];

  @override
  Future<EducationTutorSendRequestResponse> sendTutorRequest({
    required String mobile,
    required int amount,
    required String subject,
  }) async {
    sendCount++;
    return const EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 1,
        requestReference: 'EDUTR-CREATED',
        tutorId: 1,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '',
      ),
    );
  }

  @override
  Future<EducationTutorAskKycResponse> askTutorForKyc({
    String? requestReference,
    String? mobile,
  }) async {
    askReferences.add(requestReference);
    return const EducationTutorAskKycResponse(
      status: true,
      message: 'KYC reminder notification sent successfully.',
      data: EducationTutorAskKycData(
        requestReference: '',
        notificationSentTo: 10,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders identity card, banner and both CTAs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view()));
    await tester.pump();

    expect(find.text('Test Tutor Name'), findsOneWidget);
    expect(find.text('Unverified'), findsOneWidget);
    expect(find.text('Ask for KYC'), findsOneWidget);
    expect(find.text('Add Details'), findsOneWidget);
    expect(
      find.textContaining('Please ask your tutor to accept the tuition fees'),
      findsOneWidget,
    );
    // Investment banner comes from the backend; no local PNG is rendered here.
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('Ask for KYC posts ask-kyc with the request reference', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final repo = _FakeAskKycRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          educationFeesRepositoryProvider.overrideWithValue(repo),
        ],
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          fontSizeResolver: FontSizeResolvers.radius,
          builder: (context, _) => MaterialApp(home: _view()),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EducationTutorUnverifiedView)),
    );
    final controller = container.read(educationFeesControllerProvider.notifier);
    controller.updateMobileInput('9876543210');
    controller.updateAmountInput('2000');
    controller.updateFeeType('tuition fees');

    await tester.tap(find.text('Ask for KYC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.sendCount, 1);
    expect(repo.askReferences, ['EDUTR-CREATED']);
  });

  testWidgets('stays overflow-free across the device matrix', (tester) async {
    for (final size in responsiveTestScreenSizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_wrap(_view()));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
    }
  });
}
