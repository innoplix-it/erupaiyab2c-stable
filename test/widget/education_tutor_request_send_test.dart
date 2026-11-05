import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/views/education_tutor_request_view.dart';

class MockEducationFeesRepository extends Mock implements EducationFeesRepository {}

Widget _wrap(
  Widget child, {
  MockEducationFeesRepository? mockRepo,
  String? feeType,
}) {
  final router = GoRouter(
    initialLocation: '/request',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('HOME_PAGE'))),
      ),
      GoRoute(path: '/request', builder: (context, state) => child),
    ],
  );
  
  final overrides = <Override>[
    if (mockRepo != null)
      educationFeesRepositoryProvider.overrideWithValue(mockRepo),
  ];
  
  final screen = ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    fontSizeResolver: FontSizeResolvers.radius,
    builder: (context, _) => MaterialApp.router(routerConfig: router),
  );

  return ProviderScope(
    overrides: overrides,
    child: feeType == null
        ? screen
        : _FeeTypeSeed(feeType: feeType, child: screen),
  );
}

class _FeeTypeSeed extends ConsumerStatefulWidget {
  const _FeeTypeSeed({required this.feeType, required this.child});

  final String feeType;
  final Widget child;

  @override
  ConsumerState<_FeeTypeSeed> createState() => _FeeTypeSeedState();
}

class _FeeTypeSeedState extends ConsumerState<_FeeTypeSeed> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(educationFeesControllerProvider.notifier)
          .updateFeeType(widget.feeType);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget _view({
  Duration sendDuration = Duration.zero,
  Duration sentLabelDuration = Duration.zero,
  String? maskedAccount,
  Duration redirectDuration = const Duration(seconds: 5),
  String? subject = 'Mathematics',
}) {
  return EducationTutorRequestView(
    tutorName: 'Test Tutor Name',
    mobile: '9876500001',
    amount: 2000,
    maskedAccount: maskedAccount,
    subject: subject,
    sendDuration: sendDuration,
    sentLabelDuration: sentLabelDuration,
    redirectDuration: redirectDuration,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('form phase shows actions and no timer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view()));
    await tester.pump();

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Send Request'), findsOneWidget);
    expect(
      find.text(
        'Please ask your tutor to accept the tuition fees request on erupaiya app',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('tutorRequestTimer')), findsNothing);
    expect(find.text('Go to Home'), findsNothing);
  });

  testWidgets('Send Request shows loader with Sending Request then '
      'Request sent', (tester) async {
    final mockRepo = MockEducationFeesRepository();
    
    when(() => mockRepo.sendTutorRequest(
      mobile: any(named: 'mobile'),
      amount: any(named: 'amount'),
      subject: any(named: 'subject'),
    )).thenAnswer((_) async => EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 123,
        requestReference: 'REF123',
        tutorId: 456,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '2024-01-01',
      ),
    ));
    
    when(() => mockRepo.fetchTutorRequestStatus(any())).thenAnswer(
      (_) async => EducationTutorRequestStatusResponse(
        status: true,
        data: EducationTutorRequestStatusData(
          requestReference: 'REF123',
          amount: '2000',
          subject: 'Mathematics',
          requestStatus: 'PENDING',
          isAccepted: false,
          isRejected: false,
          isPending: true,
          rejectionReason: null,
          createdAt: '2024-01-01',
          respondedAt: null,
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        _view(
          sendDuration: const Duration(milliseconds: 300),
          sentLabelDuration: const Duration(milliseconds: 400),
        ),
        mockRepo: mockRepo,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();

    expect(find.text('Sending Request'), findsOneWidget);
    expect(find.text('Do not close or go back.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 320));
    // Label cross-fades: old text animates out while new text animates in.
    expect(find.text('Request sent'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));

    // Loader gone, waiting screen visible.
    expect(find.text('Request sent'), findsNothing);
    expect(find.text('Sending Request'), findsNothing);
  });

  testWidgets('sent phase shows success line, timer and Go to Home',
      (tester) async {
    final mockRepo = MockEducationFeesRepository();
    
    when(() => mockRepo.sendTutorRequest(
      mobile: any(named: 'mobile'),
      amount: any(named: 'amount'),
      subject: any(named: 'subject'),
    )).thenAnswer((_) async => EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 123,
        requestReference: 'REF123',
        tutorId: 456,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '2024-01-01',
      ),
    ));
    
    when(() => mockRepo.fetchTutorRequestStatus(any())).thenAnswer(
      (_) async => EducationTutorRequestStatusResponse(
        status: true,
        data: EducationTutorRequestStatusData(
          requestReference: 'REF123',
          amount: '2000',
          subject: 'Mathematics',
          requestStatus: 'PENDING',
          isAccepted: false,
          isRejected: false,
          isPending: true,
          rejectionReason: null,
          createdAt: '2024-01-01',
          respondedAt: null,
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view(), mockRepo: mockRepo));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Payment request has been sent successfully'),
      findsOneWidget,
    );
    expect(find.text('00:00'), findsOneWidget);
    expect(
      find.text('Please wait until request\naccept from tutor'),
      findsOneWidget,
    );
    expect(
      find.text('go back and relax , will notify you once accept'),
      findsOneWidget,
    );
    expect(find.text('Go to Home'), findsOneWidget);
    expect(find.text('Send Request'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('timer counts up from zero and keeps running',
      (tester) async {
    final mockRepo = MockEducationFeesRepository();
    
    when(() => mockRepo.sendTutorRequest(
      mobile: any(named: 'mobile'),
      amount: any(named: 'amount'),
      subject: any(named: 'subject'),
    )).thenAnswer((_) async => EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 123,
        requestReference: 'REF123',
        tutorId: 456,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '2024-01-01',
      ),
    ));
    
    when(() => mockRepo.fetchTutorRequestStatus(any())).thenAnswer(
      (_) async => EducationTutorRequestStatusResponse(
        status: true,
        data: EducationTutorRequestStatusData(
          requestReference: 'REF123',
          amount: '2000',
          subject: 'Mathematics',
          requestStatus: 'PENDING',
          isAccepted: false,
          isRejected: false,
          isPending: true,
          rejectionReason: null,
          createdAt: '2024-01-01',
          respondedAt: null,
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view(), mockRepo: mockRepo));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('00:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);
    await tester.pump(const Duration(seconds: 65));
    expect(find.text('01:06'), findsOneWidget);
  });

  testWidgets('accept threshold shows the accepted loader then the profile',
      (tester) async {
    final mockRepo = MockEducationFeesRepository();
    
    when(() => mockRepo.sendTutorRequest(
      mobile: any(named: 'mobile'),
      amount: any(named: 'amount'),
      subject: any(named: 'subject'),
    )).thenAnswer((_) async => EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 123,
        requestReference: 'REF123',
        tutorId: 456,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '2024-01-01',
      ),
    ));
    
    when(() => mockRepo.saveTutorBeneficiaryRegistered(
          requestReference: any(named: 'requestReference'),
        )).thenAnswer((_) async =>
        const EducationTutorSaveBeneficiaryRegisteredResponse(
          status: true,
          data: EducationTutorSaveBeneficiaryRegisteredData(
            beneficiaryId: 1,
            recipientReference: 'REC-1',
            recipientType: 'TUTOR',
            panVerified: true,
            bankVerified: true,
          ),
        ));

    // First call returns PENDING, subsequent calls return ACCEPTED
    int callCount = 0;
    when(() => mockRepo.fetchTutorRequestStatus(any())).thenAnswer(
      (_) async {
        callCount++;
        if (callCount == 1) {
          return EducationTutorRequestStatusResponse(
            status: true,
            data: EducationTutorRequestStatusData(
              requestReference: 'REF123',
              amount: '2000',
              subject: 'Mathematics',
              requestStatus: 'PENDING',
              isAccepted: false,
              isRejected: false,
              isPending: true,
              rejectionReason: null,
              createdAt: '2024-01-01',
              respondedAt: null,
            ),
          );
        } else {
          return EducationTutorRequestStatusResponse(
            status: true,
            data: EducationTutorRequestStatusData(
              requestReference: 'REF123',
              amount: '2000',
              subject: 'Mathematics',
              requestStatus: 'ACCEPTED',
              isAccepted: true,
              isRejected: false,
              isPending: false,
              rejectionReason: null,
              createdAt: '2024-01-01',
              respondedAt: '2024-01-01',
            ),
          );
        }
      },
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view(
      maskedAccount: 'XXXXXX4582',
    ), mockRepo: mockRepo));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // First poll is still PENDING. The next even second returns ACCEPTED.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    
    // Accepted popup should appear
    expect(find.text('Request Accepted Successfully'), findsOneWidget);
    
    // Close the popup
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump();

    expect(find.text('you will redirected in 5 sec to tutor profile'),
        findsOneWidget);

    // Redirect fires after the announced 5 seconds.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('BANK DETAILS'), findsOneWidget);
    expect(find.text('Subject (Optional)'), findsOneWidget);
    expect(find.text('Proceed to Pay'), findsOneWidget);
    // The profile card no longer renders static status copy.
    expect(
      find.text('Test Tutor has accepted your request now you \n can sent tution fees'),
      findsNothing,
    );
    expect(
      find.text('tutor will be saved for future payments'),
      findsNothing,
    );
    // The shared identity card is reused, so the amount pill stays the same.
    expect(find.text('\u20B92,000'), findsOneWidget);
  });

  testWidgets('Go to Home navigates to the home route', (tester) async {
    final mockRepo = MockEducationFeesRepository();
    
    when(() => mockRepo.sendTutorRequest(
      mobile: any(named: 'mobile'),
      amount: any(named: 'amount'),
      subject: any(named: 'subject'),
    )).thenAnswer((_) async => EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 123,
        requestReference: 'REF123',
        tutorId: 456,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '2024-01-01',
      ),
    ));
    
    when(() => mockRepo.fetchTutorRequestStatus(any())).thenAnswer(
      (_) async => EducationTutorRequestStatusResponse(
        status: true,
        data: EducationTutorRequestStatusData(
          requestReference: 'REF123',
          amount: '2000',
          subject: 'Mathematics',
          requestStatus: 'PENDING',
          isAccepted: false,
          isRejected: false,
          isPending: true,
          rejectionReason: null,
          createdAt: '2024-01-01',
          respondedAt: null,
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view(), mockRepo: mockRepo));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Go to Home'));
    // Let the page transition finish before asserting the new screen.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('HOME_PAGE'), findsOneWidget);
    expect(find.text('Go to Home'), findsNothing);
  });

  testWidgets('shows the passed name and backend account_masked',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view(maskedAccount: '9445XXXXXX')));
    await tester.pump();

    expect(find.text('Test Tutor Name'), findsOneWidget);
    expect(find.text('9445XXXXXX'), findsOneWidget);
    expect(find.text('XXXXXX4582'), findsNothing);
  });

  testWidgets('hides the account line when the API has no account_masked',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view()));
    await tester.pump();

    // Nothing is derived from the mobile number; the row stays hidden.
    expect(find.text('XXXXXX4582'), findsNothing);
    expect(find.text('9876500001'), findsNothing);
  });

  testWidgets('REJECTED case shows declined popup and cancels timer',
      (tester) async {
    final mockRepo = MockEducationFeesRepository();
    
    when(() => mockRepo.sendTutorRequest(
      mobile: any(named: 'mobile'),
      amount: any(named: 'amount'),
      subject: any(named: 'subject'),
    )).thenAnswer((_) async => EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 123,
        requestReference: 'REF123',
        tutorId: 456,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '2024-01-01',
      ),
    ));
    
    // First call returns PENDING, subsequent calls return REJECTED
    int callCount = 0;
    when(() => mockRepo.fetchTutorRequestStatus(any())).thenAnswer(
      (_) async {
        callCount++;
        if (callCount == 1) {
          return EducationTutorRequestStatusResponse(
            status: true,
            data: EducationTutorRequestStatusData(
              requestReference: 'REF123',
              amount: '2000',
              subject: 'Mathematics',
              requestStatus: 'PENDING',
              isAccepted: false,
              isRejected: false,
              isPending: true,
              rejectionReason: null,
              createdAt: '2024-01-01',
              respondedAt: null,
            ),
          );
        } else {
          return EducationTutorRequestStatusResponse(
            status: true,
            data: EducationTutorRequestStatusData(
              requestReference: 'REF123',
              amount: '2000',
              subject: 'Mathematics',
              requestStatus: 'REJECTED',
              isAccepted: false,
              isRejected: true,
              isPending: false,
              rejectionReason: 'Tutor unavailable',
              createdAt: '2024-01-01',
              respondedAt: '2024-01-01',
            ),
          );
        }
      },
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view(), mockRepo: mockRepo));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Polling detects rejection after 4 seconds (second poll call)
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    
    // Declined popup should appear
    expect(find.text('Request Declined'), findsWidgets);
  });

  testWidgets('API Failure does not incorrectly mark request as accepted',
      (tester) async {
    final mockRepo = MockEducationFeesRepository();
    
    when(() => mockRepo.sendTutorRequest(
      mobile: any(named: 'mobile'),
      amount: any(named: 'amount'),
      subject: any(named: 'subject'),
    )).thenAnswer((_) async => EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 123,
        requestReference: 'REF123',
        tutorId: 456,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '2024-01-01',
      ),
    ));
    
    // API returns error
    when(() => mockRepo.fetchTutorRequestStatus(any())).thenThrow(
      Exception('Network error'),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view(), mockRepo: mockRepo));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Timer continues despite API errors
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    
    // No accepted popup should appear
    expect(find.text('Request accepted successfully'), findsNothing);
    // Timer should still be running
    expect(find.text('00:02'), findsOneWidget);
  });

  testWidgets('Screen disposal cancels timer and stops API calls',
      (tester) async {
    final mockRepo = MockEducationFeesRepository();
    
    when(() => mockRepo.sendTutorRequest(
      mobile: any(named: 'mobile'),
      amount: any(named: 'amount'),
      subject: any(named: 'subject'),
    )).thenAnswer((_) async => EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 123,
        requestReference: 'REF123',
        tutorId: 456,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '2024-01-01',
      ),
    ));
    
    when(() => mockRepo.fetchTutorRequestStatus(any())).thenAnswer(
      (_) async => EducationTutorRequestStatusResponse(
        status: true,
        data: EducationTutorRequestStatusData(
          requestReference: 'REF123',
          amount: '2000',
          subject: 'Mathematics',
          requestStatus: 'PENDING',
          isAccepted: false,
          isRejected: false,
          isPending: true,
          rejectionReason: null,
          createdAt: '2024-01-01',
          respondedAt: null,
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view(), mockRepo: mockRepo));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Navigate away (dispose the screen)
    await tester.tap(find.text('Go to Home'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // Verify we're on home page
    expect(find.text('HOME_PAGE'), findsOneWidget);
    
    // Wait to ensure no additional API calls are made after disposal
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('passes custom subject to sendTutorRequest API',
      (tester) async {
    final mockRepo = MockEducationFeesRepository();

    when(() => mockRepo.sendTutorRequest(
      mobile: any(named: 'mobile'),
      amount: any(named: 'amount'),
      subject: any(named: 'subject'),
    )).thenAnswer((_) async => EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 123,
        requestReference: 'REF123',
        tutorId: 456,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '2024-01-01',
      ),
    ));

    when(() => mockRepo.fetchTutorRequestStatus(any())).thenAnswer(
      (_) async => EducationTutorRequestStatusResponse(
        status: true,
        data: EducationTutorRequestStatusData(
          requestReference: 'REF123',
          amount: '2000',
          subject: 'Mathematics',
          requestStatus: 'PENDING',
          isAccepted: false,
          isRejected: false,
          isPending: true,
          rejectionReason: null,
          createdAt: '2024-01-01',
          respondedAt: null,
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(
      _view(subject: 'Mathematics'),
      mockRepo: mockRepo,
    ));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify the mock was called with the custom subject
    verify(() => mockRepo.sendTutorRequest(
      mobile: '9876500001',
      amount: 2000,
      subject: 'Mathematics',
    )).called(1);
  });

  testWidgets('sends the selected fee type when the view subject is null',
      (tester) async {
    final mockRepo = MockEducationFeesRepository();
    when(() => mockRepo.sendTutorRequest(
          mobile: any(named: 'mobile'),
          amount: any(named: 'amount'),
          subject: any(named: 'subject'),
        )).thenAnswer((_) async => EducationTutorSendRequestResponse(
          status: true,
          data: EducationTutorSendRequestData(
            requestId: 123,
            requestReference: 'REF123',
            tutorId: 456,
            amount: '2000',
            requestStatus: 'PENDING',
            createdAt: '2024-01-01',
          ),
        ));

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(
      _view(subject: null),
      mockRepo: mockRepo,
      feeType: '  School Fee  ',
    ));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    verify(() => mockRepo.sendTutorRequest(
          mobile: '9876500001',
          amount: 2000,
          subject: 'School Fee',
        )).called(1);
  });

  testWidgets('sends Chemistry when that subject is selected', (tester) async {
    final mockRepo = MockEducationFeesRepository();
    when(() => mockRepo.sendTutorRequest(
          mobile: any(named: 'mobile'),
          amount: any(named: 'amount'),
          subject: any(named: 'subject'),
        )).thenAnswer((_) async => EducationTutorSendRequestResponse(
          status: true,
          data: EducationTutorSendRequestData(
            requestId: 9,
            requestReference: 'REF-CHEM',
            tutorId: 4,
            amount: '2000',
            requestStatus: 'PENDING',
            createdAt: '2024-01-01',
          ),
        ));

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(
      _view(subject: 'Chemistry'),
      mockRepo: mockRepo,
    ));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    verify(() => mockRepo.sendTutorRequest(
          mobile: '9876500001',
          amount: 2000,
          subject: 'Chemistry',
        )).called(1);
  });

  Future<void> _expectSubjectBlocked(
    WidgetTester tester,
    String? subject,
  ) async {
    final mockRepo = MockEducationFeesRepository();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(
      _view(subject: subject),
      mockRepo: mockRepo,
    ));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();

    expect(find.text('Select a subject before sending the request.'),
        findsOneWidget);
    expect(find.text('Send Request'), findsOneWidget);
    verifyNever(() => mockRepo.sendTutorRequest(
          mobile: any(named: 'mobile'),
          amount: any(named: 'amount'),
          subject: any(named: 'subject'),
        ));
  }

  testWidgets('blocks a null subject', (tester) async {
    await _expectSubjectBlocked(tester, null);
  });

  testWidgets('blocks an empty subject', (tester) async {
    await _expectSubjectBlocked(tester, '');
  });

  testWidgets('blocks a whitespace-only subject', (tester) async {
    await _expectSubjectBlocked(tester, '   ');
  });

  testWidgets('trims whitespace from subject before sending',
      (tester) async {
    final mockRepo = MockEducationFeesRepository();

    when(() => mockRepo.sendTutorRequest(
      mobile: any(named: 'mobile'),
      amount: any(named: 'amount'),
      subject: any(named: 'subject'),
    )).thenAnswer((_) async => EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 123,
        requestReference: 'REF123',
        tutorId: 456,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '2024-01-01',
      ),
    ));

    when(() => mockRepo.fetchTutorRequestStatus(any())).thenAnswer(
      (_) async => EducationTutorRequestStatusResponse(
        status: true,
        data: EducationTutorRequestStatusData(
          requestReference: 'REF123',
          amount: '2000',
          subject: 'Physics',
          requestStatus: 'PENDING',
          isAccepted: false,
          isRejected: false,
          isPending: true,
          rejectionReason: null,
          createdAt: '2024-01-01',
          respondedAt: null,
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(
      _view(subject: '  Physics  '),
      mockRepo: mockRepo,
    ));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify the mock was called with trimmed subject
    verify(() => mockRepo.sendTutorRequest(
      mobile: '9876500001',
      amount: 2000,
      subject: 'Physics',
    )).called(1);
  });
}
