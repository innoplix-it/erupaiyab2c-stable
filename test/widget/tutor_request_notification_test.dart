import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:e_rupaiya/features/educationFees/components/education_tuition_request_popup.dart';
import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/controllers/tutor_received_requests_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/services/tutor_request_notification_service.dart';
import 'package:e_rupaiya/features/educationFees/services/tutor_request_pending_store.dart';
import 'package:e_rupaiya/features/educationFees/widgets/tutor_request_notification_listener.dart';
import 'package:e_rupaiya/features/educationFees/views/tutor_received_requests_view.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';

class MockEducationFeesRepository extends Mock implements EducationFeesRepository {}

class MockRemoteMessage extends Mock implements RemoteMessage {
  @override
  Map<String, dynamic> get data => _data;
  final Map<String, dynamic> _data;

  MockRemoteMessage(this._data);

  @override
  String? get messageId => 'test_message_id';
}

EducationTutorRequestStatusResponse _statusResponse({
  required String requestReference,
  required String requestStatus,
  required bool isPending,
  required bool isAccepted,
  required bool isRejected,
  String amount = '100',
  String subject = 'Tuition',
  bool status = true,
}) {
  return EducationTutorRequestStatusResponse(
    status: status,
    data: status
        ? EducationTutorRequestStatusData(
            requestReference: requestReference,
            amount: amount,
            subject: subject,
            requestStatus: requestStatus,
            isAccepted: isAccepted,
            isRejected: isRejected,
            isPending: isPending,
            rejectionReason: null,
            createdAt: '2024-01-01',
            respondedAt: isPending ? null : '2024-01-01',
          )
        : null,
  );
}

EducationTutorRequestStatusResponse _pendingStatus(
  String requestReference, {
  String amount = '100',
  String subject = 'Tuition',
}) {
  return _statusResponse(
    requestReference: requestReference,
    requestStatus: 'PENDING',
    isPending: true,
    isAccepted: false,
    isRejected: false,
    amount: amount,
    subject: subject,
  );
}

void _stubEmptyReceivedRequests(MockEducationFeesRepository mockRepo) {
  when(
    () => mockRepo.fetchTutorReceivedRequests(
      page: any(named: 'page'),
      perPage: any(named: 'perPage'),
      status: any(named: 'status'),
    ),
  ).thenAnswer(
    (_) async => const EducationTutorReceivedRequestsResponse(
      status: true,
      data: EducationTutorReceivedRequestsData(
        requests: [],
        pagination: null,
      ),
    ),
  );
}

void _stubRespond(
  MockEducationFeesRepository mockRepo, {
  String requestReference = 'REF123',
  String action = 'ACCEPTED',
}) {
  when(
    () => mockRepo.respondToTutorRequest(
      requestReference: any(named: 'requestReference'),
      action: any(named: 'action'),
    ),
  ).thenAnswer(
    (_) async => EducationTutorRespondToRequestResponse(
      status: true,
      data: EducationTutorRespondToRequestData(
        requestReference: requestReference,
        amount: '100',
        requestStatus: action,
        respondedAt: '2024-01-01',
      ),
      requestStatus: action,
    ),
  );
}

TutorRequestNotificationService _configureService(
  MockEducationFeesRepository mockRepo,
) {
  _stubEmptyReceivedRequests(mockRepo);
  _stubRespond(mockRepo);
  final service = TutorRequestNotificationService();
  service.debugReset(
    repository: mockRepo,
    authChecker: () async => true,
  );
  return service;
}

Widget _wrapWithListener(Widget child, {MockEducationFeesRepository? mockRepo}) {
  final overrides = <Override>[
    if (mockRepo != null) ...[
      educationFeesRepositoryProvider.overrideWithValue(mockRepo),
      tutorReceivedRequestsRepositoryProvider.overrideWithValue(mockRepo),
    ],
  ];

  return ProviderScope(
    overrides: overrides,
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, widget) {
          return TutorRequestNotificationListener(
            child: widget ?? const SizedBox.shrink(),
          );
        },
        home: Scaffold(body: child),
      ),
    ),
  );
}

Future<void> _openReceivedPopupFromFcm(
  WidgetTester tester, {
  required MockEducationFeesRepository mockRepo,
  required Widget screen,
  required String requestReference,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(
    _wrapWithListener(screen, mockRepo: mockRepo),
  );
  await tester.pump();

  final service = TutorRequestNotificationService();
  service.debugSetRepository(mockRepo);
  service.debugSetAuthChecker(() async => true);
  await service.handleForegroundMessage(
    MockRemoteMessage({
      'request_reference': requestReference,
      'type': 'tutor_request',
    }),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    TutorRequestPendingStore.debugUseMemoryStore();
  });

  tearDown(() {
    TutorRequestPendingStore.debugResetStore();
  });

  group('TutorRequestNotificationService', () {
    late TutorRequestNotificationService service;
    late MockEducationFeesRepository mockRepo;

    setUp(() {
      mockRepo = MockEducationFeesRepository();
      service = _configureService(mockRepo);
    });

    test('extracts request_reference from FCM data', () {
      expect(
        TutorRequestNotificationService.extractRequestReference({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
        'REF123',
      );
      expect(
        TutorRequestNotificationService.isTutorRequestPayload({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
        isTrue,
      );
      expect(
        TutorRequestNotificationService.isTutorRequestPayload({
          'request_reference': 'REF123',
          'type': 'payment_request',
        }),
        isTrue,
      );
      expect(
        TutorRequestNotificationService.isTutorRequestPayload({
          'request_reference': 'REF123',
        }),
        isTrue,
      );
    });

    test('live status PENDING object broadcasts the Received popup event',
        () async {
      const liveReference = 'EDUTR2026110504443591AAB581';
      when(() => mockRepo.fetchTutorRequestStatus(liveReference)).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse.fromJson(const {
          'request_reference': liveReference,
          'requester_user_id': '303',
          'amount': '1.00',
          'status': 'PENDING',
        }),
      );

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);

      await service.handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': liveReference,
          'type': 'tutor_request',
        }),
      );

      expect(events, hasLength(1));
      expect(events.single.requestReference, liveReference);
      expect(events.single.amount, '1.00');
      verify(() => mockRepo.fetchTutorRequestStatus(liveReference)).called(1);
      await subscription.cancel();
    });

    testWidgets('live status PENDING object opens the Received popup',
        (tester) async {
      const liveReference = 'EDUTR2026110504443591AAB581';
      when(() => mockRepo.fetchTutorRequestStatus(liveReference)).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse.fromJson(const {
          'request_reference': liveReference,
          'requester_user_id': '303',
          'amount': '1.00',
          'status': 'PENDING',
        }),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      await TutorRequestNotificationService().handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': liveReference,
          'type': 'tutor_request',
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('HOME_SCREEN'), findsOneWidget);
      expect(find.text('Bank Details Request'), findsOneWidget);
      expect(find.text('Share Details'), findsOneWidget);
      verify(() => mockRepo.fetchTutorRequestStatus(liveReference)).called(1);
    });

    test('maps distinct amounts, subjects, names and references', () async {
      const reference = 'EDUTR-CHEM-250';
      when(() => mockRepo.fetchTutorRequestStatus(reference)).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse.fromJson(const {
          'request_reference': reference,
          'requester_user_id': '808',
          'requester_name': 'Asha Patil',
          'amount': '250.00',
          'subject': 'Chemistry',
          'status': 'PENDING',
        }),
      );
      service.debugSetCurrentUserId(() async => '411');

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await service.handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': reference,
          'type': 'tutor_request',
          'title': 'New tuition request',
          'body': 'Asha Patil sent ₹250',
        }),
      );

      expect(events, hasLength(1));
      expect(events.single.requestReference, reference);
      expect(events.single.amount, '250.00');
      expect(events.single.subject, 'Chemistry');
      expect(events.single.requesterName, 'Asha Patil');
      expect(events.single.requestStatus, 'PENDING');
      await subscription.cancel();
    });

    test('keeps missing status fields empty', () async {
      const reference = 'EDUTR-BARE';
      when(() => mockRepo.fetchTutorRequestStatus(reference)).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse.fromJson(const {
          'request_reference': reference,
          'status': 'PENDING',
        }),
      );

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await service.handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': reference,
          'type': 'tutor_request',
        }),
      );

      expect(events, hasLength(1));
      expect(events.single.amount, isEmpty);
      expect(events.single.subject, isEmpty);
      expect(events.single.requesterName, isEmpty);
      await subscription.cancel();
    });

    test('skips the Received popup when the logged-in user is the requester',
        () async {
      const reference = 'EDUTR-SENDER';
      when(() => mockRepo.fetchTutorRequestStatus(reference)).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse.fromJson(const {
          'request_reference': reference,
          'requester_user_id': '303',
          'amount': '1.00',
          'status': 'PENDING',
        }),
      );
      service.debugSetCurrentUserId(() async => '303');

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await service.handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': reference,
          'type': 'tutor_request',
        }),
      );

      expect(events, isEmpty);
      await subscription.cancel();
    });

    test('parses flat, nested and JSON-string FCM data', () {
      expect(
        TutorRequestNotificationService.notificationDataFromPayload({
          'request_reference': 'FLAT-1',
          'type': 'tutor_request',
        })['request_reference'],
        'FLAT-1',
      );
      expect(
        TutorRequestNotificationService.notificationDataFromPayload({
          'data': {
            'request_reference': 'NESTED-2',
            'type': 'tutor_request',
          },
        })['request_reference'],
        'NESTED-2',
      );
      expect(
        TutorRequestNotificationService.notificationDataFromPayload({
          'data': '{"request_reference":"JSON-3","type":"tutor_request"}',
        })['request_reference'],
        'JSON-3',
      );
    });

    testWidgets('Received popup shows payload values and hides invented ones',
        (tester) async {
      const reference = 'EDUTR-CHEM-250';
      when(() => mockRepo.fetchTutorRequestStatus(reference)).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse.fromJson(const {
          'request_reference': reference,
          'requester_user_id': '808',
          'requester_name': 'Asha Patil',
          'amount': '250',
          'subject': 'Chemistry',
          'status': 'PENDING',
        }),
      );
      service.debugSetCurrentUserId(() async => '411');

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();
      await TutorRequestNotificationService().handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': reference,
          'type': 'tutor_request',
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Bank Details Request'), findsOneWidget);
      expect(find.textContaining('Asha Patil'), findsOneWidget);
      expect(find.textContaining('Chemistry'), findsOneWidget);
      expect(find.textContaining('\u20B9250'), findsOneWidget);
      expect(find.text('Student'), findsNothing);
      expect(find.text('Tuition Fees'), findsNothing);
      expect(find.text('Credit Card'), findsNothing);
      expect(find.text('Awaiting Your Approval'), findsNothing);
    });

    testWidgets('missing fields do not invent a name, amount or purpose',
        (tester) async {
      const reference = 'EDUTR-BARE-UI';
      when(() => mockRepo.fetchTutorRequestStatus(reference)).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse.fromJson(const {
          'request_reference': reference,
          'requester_user_id': '808',
          'status': 'PENDING',
        }),
      );
      service.debugSetCurrentUserId(() async => '411');

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();
      await TutorRequestNotificationService().handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': reference,
          'type': 'tutor_request',
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Bank Details Request'), findsOneWidget);
      expect(find.text('Student'), findsNothing);
      expect(find.text('Tuition'), findsNothing);
      expect(find.text('Tuition Fees'), findsNothing);
      expect(find.text('Credit Card'), findsNothing);
      expect(find.textContaining('\u20B9'), findsNothing);
    });

    testWidgets('does not show Received popup to the requester',
        (tester) async {
      const reference = 'EDUTR-SENDER-UI';
      when(() => mockRepo.fetchTutorRequestStatus(reference)).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse.fromJson(const {
          'request_reference': reference,
          'requester_user_id': '303',
          'amount': '1.00',
          'status': 'PENDING',
        }),
      );
      service.debugSetCurrentUserId(() async => '303');

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();
      await TutorRequestNotificationService().handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': reference,
          'type': 'tutor_request',
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('HOME_SCREEN'), findsOneWidget);
      expect(find.text('Bank Details Request'), findsNothing);
    });

    test('PENDING validation accepts string/int boolean flags from API', () async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse.fromJson({
          'status': true,
          'data': {
            'request_reference': 'REF123',
            'amount': '100',
            'subject': 'Tuition',
            'request_status': 'PENDING',
            'is_accepted': 'false',
            'is_rejected': 0,
            'is_pending': 'true',
            'rejection_reason': null,
            'created_at': '2024-01-01',
            'responded_at': null,
          },
        }),
      );

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);

      await service.handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
      );

      expect(events, hasLength(1));
      expect(events.first.requestReference, 'REF123');
      await subscription.cancel();
    });

    test('PENDING validation accepts Map<dynamic, dynamic> data payloads', () async {
      when(() => mockRepo.fetchTutorRequestStatus('REF456')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse.fromJson({
          'status': 1,
          'data': <dynamic, dynamic>{
            'request_reference': 'REF456',
            'amount': 250,
            'subject': 'Math',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'created_at': '2024-01-01',
          },
        }),
      );

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);

      await service.handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': 'REF456',
          'type': 'tutor_request',
        }),
      );

      expect(events, hasLength(1));
      expect(events.first.requestReference, 'REF456');
      expect(events.first.amount, '250');
      await subscription.cancel();
    });

    test('handles null request_reference gracefully', () async {
      final message = MockRemoteMessage({
        'type': 'tutor_request',
      });

      when(() => mockRepo.fetchTutorRequestStatus(any())).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      // Should not throw
      await service.handleForegroundMessage(message);
    });

    test('prevents duplicate popups for same request_reference', () async {
      final message = MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      });

      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => _pendingStatus('REF123'),
      );

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);

      await service.handleForegroundMessage(message);
      await service.handleForegroundMessage(message);
      await service.handleForegroundMessage(message);

      expect(events, hasLength(1));
      expect(events.first.requestReference, 'REF123');
      verify(() => mockRepo.fetchTutorRequestStatus('REF123')).called(1);
      await subscription.cancel();
    });

    test('Request Status GET is called immediately after FCM with exact reference',
        () async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => _pendingStatus('REF123'),
      );

      await service.handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
      );

      verify(() => mockRepo.fetchTutorRequestStatus('REF123')).called(1);
      verifyNever(() => mockRepo.fetchTutorRequestStatus('REF456'));
    });

    test('non-tutor FCM does not call Request Status GET', () async {
      await service.handleForegroundMessage(
        MockRemoteMessage({
          'type': 'wallet_credit',
          'reference': 'PAY123',
        }),
      );

      verifyNever(() => mockRepo.fetchTutorRequestStatus(any()));
    });

    test('background-verified PENDING skips duplicate Request Status GET',
        () async {
      await TutorRequestPendingStore.upsert(
        const TutorRequestPendingEntry(
          requestReference: 'REF123',
          verified: true,
          amount: '150',
          subject: 'Science',
        ),
      );

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);

      await service.handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
      );

      expect(events, hasLength(1));
      expect(events.first.requestReference, 'REF123');
      expect(events.first.amount, '150');
      expect(events.first.subject, 'Science');
      verifyNever(() => mockRepo.fetchTutorRequestStatus(any()));
      await subscription.cancel();
    });

    test('flushPersistedPendingRequests presents verified background entry',
        () async {
      await TutorRequestPendingStore.upsert(
        const TutorRequestPendingEntry(
          requestReference: 'REF999',
          verified: true,
          amount: '300',
          subject: 'Physics',
        ),
      );

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);

      await service.flushPersistedPendingRequests();

      expect(events, hasLength(1));
      expect(events.first.requestReference, 'REF999');
      verifyNever(() => mockRepo.fetchTutorRequestStatus(any()));
      expect(await TutorRequestPendingStore.loadAll(), isEmpty);
      await subscription.cancel();
    });

    test('flushPersistedPendingRequests verifies unverified entry via GET',
        () async {
      await TutorRequestPendingStore.upsert(
        const TutorRequestPendingEntry(
          requestReference: 'REF888',
          verified: false,
        ),
      );
      when(() => mockRepo.fetchTutorRequestStatus('REF888')).thenAnswer(
        (_) async => _pendingStatus('REF888', amount: '80', subject: 'Chem'),
      );

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);

      await service.flushPersistedPendingRequests();

      expect(events, hasLength(1));
      expect(events.first.requestReference, 'REF888');
      verify(() => mockRepo.fetchTutorRequestStatus('REF888')).called(1);
      await subscription.cancel();
    });

    test('clearOnLogout clears in-memory and persisted pending entries',
        () async {
      await TutorRequestPendingStore.upsert(
        const TutorRequestPendingEntry(
          requestReference: 'REF777',
          verified: true,
          amount: '10',
        ),
      );
      when(() => mockRepo.fetchTutorRequestStatus('REF777')).thenAnswer(
        (_) async => _pendingStatus('REF777'),
      );
      await service.handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': 'REF777',
          'type': 'tutor_request',
        }),
      );
      expect(service.shownRequestReferences.contains('REF777'), isTrue);

      await service.clearOnLogout();

      expect(service.shownRequestReferences, isEmpty);
      expect(await TutorRequestPendingStore.loadAll(), isEmpty);
    });
  });

  group('TutorRequestPendingStore', () {
    test('upsert and takeVerified round-trip', () async {
      await TutorRequestPendingStore.upsert(
        const TutorRequestPendingEntry(
          requestReference: 'REF1',
          verified: true,
          amount: '50',
          subject: 'Art',
        ),
      );
      final taken = await TutorRequestPendingStore.takeVerified('REF1');
      expect(taken, isNotNull);
      expect(taken!.amount, '50');
      expect(await TutorRequestPendingStore.takeVerified('REF1'), isNull);
    });

    test('unverified entries are not returned by takeVerified', () async {
      await TutorRequestPendingStore.upsert(
        const TutorRequestPendingEntry(
          requestReference: 'REF2',
          verified: false,
        ),
      );
      expect(await TutorRequestPendingStore.takeVerified('REF2'), isNull);
      expect(await TutorRequestPendingStore.loadAll(), hasLength(1));
    });
  });

  group('TutorRequestNotificationListener Widget Tests', () {
    late MockEducationFeesRepository mockRepo;

    setUp(() {
      mockRepo = MockEducationFeesRepository();
      _configureService(mockRepo);
    });

    tearDown(() {
      final navigator = navigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
      }
    });

    testWidgets('PENDING response displays Received popup on any screen',
        (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      when(() => mockRepo.respondToTutorRequest(
        requestReference: any(named: 'requestReference'),
        action: any(named: 'action'),
      )).thenAnswer(
        (_) async => EducationTutorRespondToRequestResponse(
          status: true,
          data: EducationTutorRespondToRequestData(
            requestReference: 'REF123',
            amount: '100',
            requestStatus: 'ACCEPTED',
            respondedAt: '2024-01-01',
          ),
          requestStatus: 'ACCEPTED',
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      // Simulate FCM event
      final service = TutorRequestNotificationService();
      service.clearShownRequests();
      final message = MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      });

      await service.handleForegroundMessage(message);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Popup should appear
      expect(find.text('Bank Details Request'), findsOneWidget);
      expect(find.textContaining('bank details'), findsOneWidget);
      expect(find.textContaining('\u20B9100'), findsOneWidget);
      expect(find.text('Share Details'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      verify(() => mockRepo.fetchTutorRequestStatus('REF123')).called(1);
    });

    testWidgets('ACCEPTED response does not show Received popup', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
            requestStatus: 'ACCEPTED',
            isAccepted: true,
            isRejected: false,
            isPending: false,
            rejectionReason: null,
            createdAt: '2024-01-01',
            respondedAt: '2024-01-01',
          ),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      // Simulate FCM event
      final service = TutorRequestNotificationService();
      service.clearShownRequests();
      final message = MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      });

      await service.handleForegroundMessage(message);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Popup should NOT appear
      expect(find.text('Bank Details Request'), findsNothing);
    });

    testWidgets('REJECTED response does not show Received popup', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
            requestStatus: 'REJECTED',
            isAccepted: false,
            isRejected: true,
            isPending: false,
            rejectionReason: 'Tutor unavailable',
            createdAt: '2024-01-01',
            respondedAt: '2024-01-01',
          ),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      // Simulate FCM event
      final service = TutorRequestNotificationService();
      service.clearShownRequests();
      final message = MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      });

      await service.handleForegroundMessage(message);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Popup should NOT appear
      expect(find.text('Bank Details Request'), findsNothing);
    });

    testWidgets('status false does not show popup', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: false,
          message: 'Request not found',
          data: null,
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      // Simulate FCM event
      final service = TutorRequestNotificationService();
      service.clearShownRequests();
      final message = MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      });

      await service.handleForegroundMessage(message);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Popup should NOT appear
      expect(find.text('Bank Details Request'), findsNothing);
    });

    testWidgets('Network error does not show popup', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenThrow(
        Exception('Network error'),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      // Simulate FCM event
      final service = TutorRequestNotificationService();
      service.clearShownRequests();
      final message = MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      });

      await service.handleForegroundMessage(message);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Popup should NOT appear (service returns false on error)
      expect(find.text('Bank Details Request'), findsNothing);
    });

    testWidgets('Popup ACCEPT button calls Accept API', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      when(() => mockRepo.respondToTutorRequest(
        requestReference: 'REF123',
        action: 'ACCEPTED',
      )).thenAnswer(
        (_) async => EducationTutorRespondToRequestResponse(
          status: true,
          data: EducationTutorRespondToRequestData(
            requestReference: 'REF123',
            amount: '100',
            requestStatus: 'ACCEPTED',
            respondedAt: '2024-01-01',
          ),
          requestStatus: 'ACCEPTED',
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 1400));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      // Simulate FCM event
      final service = TutorRequestNotificationService();
      service.clearShownRequests();
      final message = MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      });

      await service.handleForegroundMessage(message);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Popup should appear
      expect(find.text('Share Details'), findsOneWidget);

      await tester.ensureVisible(find.text('Terms & conditions'));
      await tester.tap(find.text('Terms & conditions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I Agree'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Share Details'));
      await tester.tap(find.text('Share Details'));
      await tester.pump();
      await tester.pump();

      // Verify API was called
      verify(() => mockRepo.respondToTutorRequest(
        requestReference: 'REF123',
        action: 'ACCEPTED',
      )).called(1);
    });

    testWidgets('Popup REJECT button calls Reject API', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      when(() => mockRepo.respondToTutorRequest(
        requestReference: 'REF123',
        action: 'REJECTED',
      )).thenAnswer(
        (_) async => EducationTutorRespondToRequestResponse(
          status: true,
          data: EducationTutorRespondToRequestData(
            requestReference: 'REF123',
            amount: '100',
            requestStatus: 'REJECTED',
            respondedAt: '2024-01-01',
          ),
          requestStatus: 'REJECTED',
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 1400));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      // Simulate FCM event
      final service = TutorRequestNotificationService();
      service.clearShownRequests();
      final message = MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      });

      await service.handleForegroundMessage(message);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Popup should appear
      expect(find.text('Decline'), findsOneWidget);

      await tester.ensureVisible(find.text('Decline'));
      await tester.tap(find.text('Decline'));
      await tester.pump();
      await tester.pump();

      // Verify API was called
      verify(() => mockRepo.respondToTutorRequest(
        requestReference: 'REF123',
        action: 'REJECTED',
      )).called(1);
    });

    testWidgets('Different request references handled separately',
        (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      when(() => mockRepo.fetchTutorRequestStatus('REF456')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF456',
            amount: '200',
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
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      // Simulate first FCM event
      final service = TutorRequestNotificationService();
      service.clearShownRequests();
      final message1 = MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      });

      await service.handleForegroundMessage(message1);
      await tester.pump();
      await tester.pump();

      // First popup should appear
      expect(find.textContaining('\u20B9100'), findsOneWidget);

      // Close first popup
      await tester.tap(find.byKey(const ValueKey('tuitionPopupClose')));
      await tester.pump();

      // Simulate second FCM event with different reference
      final message2 = MockRemoteMessage({
        'request_reference': 'REF456',
        'type': 'tutor_request',
      });

      await service.handleForegroundMessage(message2);
      await tester.pump();
      await tester.pump();

      // Second popup should appear with different amount
      expect(find.textContaining('\u20B9200'), findsOneWidget);
    });
  });

  group('Startup Pending Request Recovery Tests', () {
    late MockEducationFeesRepository mockRepo;

    setUp(() {
      mockRepo = MockEducationFeesRepository();
      _configureService(mockRepo);
    });

    test('startup check verifies individual request status', () async {
      final service = TutorRequestNotificationService();
      service.clearShownRequests();

      // Mock received requests API
      when(() => mockRepo.fetchTutorReceivedRequests(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        status: any(named: 'status'),
      )).thenAnswer(
        (_) async => EducationTutorReceivedRequestsResponse(
          status: true,
          data: EducationTutorReceivedRequestsData(
            requests: [
              {'request_reference': 'REF123', 'amount': '100'},
              {'request_reference': 'REF456', 'amount': '200'},
            ],
            pagination: null,
          ),
        ),
      );

      // Mock individual status checks - first is PENDING, second is ACCEPTED
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      when(() => mockRepo.fetchTutorRequestStatus('REF456')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF456',
            amount: '200',
            subject: 'Math',
            requestStatus: 'ACCEPTED',
            isAccepted: true,
            isRejected: false,
            isPending: false,
            rejectionReason: null,
            createdAt: '2024-01-01',
            respondedAt: '2024-01-01',
          ),
        ),
      );

      await service.checkPendingRequestsOnStartup();

      // Verify only PENDING request was broadcast
      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      // Should have one event for REF123 only (REF456 was ACCEPTED)
      expect(events.length, greaterThanOrEqualTo(1));
      if (events.isNotEmpty) {
        expect(events.first.requestReference, 'REF123');
      }
    });

    test('startup check allows retry after network failure', () async {
      final service = TutorRequestNotificationService();
      service.clearShownRequests();

      // First call fails
      when(() => mockRepo.fetchTutorReceivedRequests(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        status: any(named: 'status'),
      )).thenThrow(Exception('Network error'));

      await service.checkPendingRequestsOnStartup();

      // Second call should succeed (flag should not block retry)
      when(() => mockRepo.fetchTutorReceivedRequests(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        status: any(named: 'status'),
      )).thenAnswer(
        (_) async => EducationTutorReceivedRequestsResponse(
          status: true,
          data: EducationTutorReceivedRequestsData(
            requests: [
              {'request_reference': 'REF123', 'amount': '100'},
            ],
            pagination: null,
          ),
        ),
      );

      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      await service.checkPendingRequestsOnStartup();

      // Should succeed on retry
      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(events.length, greaterThanOrEqualTo(1));
    });

    test('startup check marks complete only after successful fetch', () async {
      final service = TutorRequestNotificationService();
      service.clearShownRequests();

      // First call fails
      when(() => mockRepo.fetchTutorReceivedRequests(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        status: any(named: 'status'),
      )).thenThrow(Exception('Network error'));

      await service.checkPendingRequestsOnStartup();

      // Second call should still run (flag not set on failure)
      when(() => mockRepo.fetchTutorReceivedRequests(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        status: any(named: 'status'),
      )).thenAnswer(
        (_) async => EducationTutorReceivedRequestsResponse(
          status: true,
          data: EducationTutorReceivedRequestsData(
            requests: [],
            pagination: null,
          ),
        ),
      );

      await service.checkPendingRequestsOnStartup();

      // Third call should be skipped (flag set after successful fetch)
      await service.checkPendingRequestsOnStartup();
    });

    test('empty requests list does not broadcast events', () async {
      final service = TutorRequestNotificationService();
      service.clearShownRequests();

      when(() => mockRepo.fetchTutorReceivedRequests(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        status: any(named: 'status'),
      )).thenAnswer(
        (_) async => EducationTutorReceivedRequestsResponse(
          status: true,
          data: EducationTutorReceivedRequestsData(
            requests: [],
            pagination: null,
          ),
        ),
      );

      await service.checkPendingRequestsOnStartup();

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(events.isEmpty, true);
    });

    test('FCM and startup share deduplication', () async {
      final service = TutorRequestNotificationService();
      service.clearShownRequests();

      // Startup check adds REF123
      when(() => mockRepo.fetchTutorReceivedRequests(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        status: any(named: 'status'),
      )).thenAnswer(
        (_) async => EducationTutorReceivedRequestsResponse(
          status: true,
          data: EducationTutorReceivedRequestsData(
            requests: [
              {'request_reference': 'REF123', 'amount': '100'},
            ],
            pagination: null,
          ),
        ),
      );

      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      await service.checkPendingRequestsOnStartup();

      // FCM with same reference should be deduplicated
      final message = MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      });

      await service.handleForegroundMessage(message);

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      // Should only have one event (from startup, FCM was deduplicated)
      expect(events.length, 1);
    });

    test('app resume refreshes pending requests', () async {
      final service = TutorRequestNotificationService();
      service.clearShownRequests();

      when(() => mockRepo.fetchTutorReceivedRequests(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        status: any(named: 'status'),
      )).thenAnswer(
        (_) async => EducationTutorReceivedRequestsResponse(
          status: true,
          data: EducationTutorReceivedRequestsData(
            requests: [
              {'request_reference': 'REF789', 'amount': '300'},
            ],
            pagination: null,
          ),
        ),
      );

      when(() => mockRepo.fetchTutorRequestStatus('REF789')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF789',
            amount: '300',
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

      await service.checkPendingRequestsOnResume();

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(events.length, greaterThanOrEqualTo(1));
      if (events.isNotEmpty) {
        expect(events.last.requestReference, 'REF789');
      }
    });

    test('root navigator not ready - event logged and popup state reset', () async {
      final service = TutorRequestNotificationService();
      service.clearShownRequests();

      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      await service.handleForegroundMessage(MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      }));

      // Verify event was broadcast even if navigator might not be ready
      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(events.length, 1);
      expect(events.first.requestReference, 'REF123');
    });

    test('mismatched request_reference does not show popup', () async {
      final service = TutorRequestNotificationService();
      service.clearShownRequests();

      // Mock status API returns different reference than requested
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF999', // Mismatch
            amount: '100',
            subject: 'Tuition',
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

      await service.handleForegroundMessage(MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      }));

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      // Should not broadcast event due to reference mismatch
      expect(events.isEmpty, true);
    });

    test('two different requests process independently', () async {
      final service = TutorRequestNotificationService();
      service.clearShownRequests();

      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      when(() => mockRepo.fetchTutorRequestStatus('REF456')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF456',
            amount: '200',
            subject: 'Math',
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

      await service.handleForegroundMessage(MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      }));

      await service.handleForegroundMessage(MockRemoteMessage({
        'request_reference': 'REF456',
        'type': 'tutor_request',
      }));

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      // Both requests should be processed independently
      expect(events.length, 2);
      final refs = events.map((e) => e.requestReference).toSet();
      expect(refs.contains('REF123'), true);
      expect(refs.contains('REF456'), true);
    });
  });

  group('Network Error Recovery Tests', () {
    late MockEducationFeesRepository mockRepo;

    setUp(() {
      mockRepo = MockEducationFeesRepository();
      _configureService(mockRepo);
    });

    test('network error allows retry', () async {
      final service = TutorRequestNotificationService();
      service.clearShownRequests();

      // First call fails
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenThrow(Exception('Network error'));

      await service.handleForegroundMessage(MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      }));

      // Should not be marked as shown on error
      expect(service.shownRequestReferences.contains('REF123'), false);

      // Second call succeeds
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      await service.handleForegroundMessage(MockRemoteMessage({
        'request_reference': 'REF123',
        'type': 'tutor_request',
      }));

      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(events.length, 1);
    });
  });

  group('Notification Tap Routing Tests', () {
    late MockEducationFeesRepository mockRepo;

    setUp(() {
      mockRepo = MockEducationFeesRepository();
      _configureService(mockRepo);
    });

    testWidgets('notification tap with PENDING shows auto popup on route', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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

      when(() => mockRepo.respondToTutorRequest(
        requestReference: 'REF123',
        action: any(named: 'action'),
      )).thenAnswer(
        (_) async => EducationTutorRespondToRequestResponse(
          status: true,
          data: EducationTutorRespondToRequestData(
            requestReference: 'REF123',
            amount: '100',
            requestStatus: 'ACCEPTED',
            respondedAt: '2024-01-01',
          ),
          requestStatus: 'ACCEPTED',
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            educationFeesRepositoryProvider.overrideWithValue(mockRepo),
            tutorReceivedRequestsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, _) => MaterialApp(
              home: TutorReceivedRequestsView(
                autoShowRequestReference: 'REF123',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Popup should appear automatically
      expect(find.text('Bank Details Request'), findsOneWidget);
      expect(find.text('Share Details'), findsOneWidget);
    });

    testWidgets('notification tap with ACCEPTED does not show popup', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
            requestStatus: 'ACCEPTED',
            isAccepted: true,
            isRejected: false,
            isPending: false,
            rejectionReason: null,
            createdAt: '2024-01-01',
            respondedAt: '2024-01-01',
          ),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            educationFeesRepositoryProvider.overrideWithValue(mockRepo),
            tutorReceivedRequestsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, _) => MaterialApp(
              home: TutorReceivedRequestsView(
                autoShowRequestReference: 'REF123',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Popup should NOT appear
      expect(find.text('Bank Details Request'), findsNothing);
    });

    testWidgets('notification tap with REJECTED does not show popup', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
            requestStatus: 'REJECTED',
            isAccepted: false,
            isRejected: true,
            isPending: false,
            rejectionReason: 'Unavailable',
            createdAt: '2024-01-01',
            respondedAt: '2024-01-01',
          ),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            educationFeesRepositoryProvider.overrideWithValue(mockRepo),
            tutorReceivedRequestsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, _) => MaterialApp(
              home: TutorReceivedRequestsView(
                autoShowRequestReference: 'REF123',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Popup should NOT appear
      expect(find.text('Bank Details Request'), findsNothing);
    });

    testWidgets('notification tap with network error allows retry', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenThrow(
        Exception('Network error'),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            educationFeesRepositoryProvider.overrideWithValue(mockRepo),
            tutorReceivedRequestsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, _) => MaterialApp(
              home: TutorReceivedRequestsView(
                autoShowRequestReference: 'REF123',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Popup should NOT appear on error
      expect(find.text('Bank Details Request'), findsNothing);
    });

    testWidgets('notification tap with reference mismatch does not show popup', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF999', // Mismatch
            amount: '100',
            subject: 'Tuition',
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
        ProviderScope(
          overrides: [
            educationFeesRepositoryProvider.overrideWithValue(mockRepo),
            tutorReceivedRequestsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, _) => MaterialApp(
              home: TutorReceivedRequestsView(
                autoShowRequestReference: 'REF123',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Popup should NOT appear on reference mismatch
      expect(find.text('Bank Details Request'), findsNothing);
    });

    testWidgets('auto popup only shows once per request', (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => EducationTutorRequestStatusResponse(
          status: true,
          data: EducationTutorRequestStatusData(
            requestReference: 'REF123',
            amount: '100',
            subject: 'Tuition',
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
        ProviderScope(
          overrides: [
            educationFeesRepositoryProvider.overrideWithValue(mockRepo),
            tutorReceivedRequestsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, _) => MaterialApp(
              home: TutorReceivedRequestsView(
                autoShowRequestReference: 'REF123',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // First popup appears
      expect(find.text('Bank Details Request'), findsOneWidget);

      // Close popup
      await tester.tap(find.byKey(const ValueKey('tuitionPopupClose')));
      await tester.pump();

      // Wait and verify popup doesn't appear again
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Bank Details Request'), findsNothing);
    });
  });

  group('Global Received popup on current route', () {
    late MockEducationFeesRepository mockRepo;

    setUp(() {
      mockRepo = MockEducationFeesRepository();
      _configureService(mockRepo);
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => _pendingStatus('REF123'),
      );
    });

    tearDown(() {
      final navigator = navigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
      }
    });

    testWidgets('popup opens while Home screen is active without a request card tap',
        (tester) async {
      await _openReceivedPopupFromFcm(
        tester,
        mockRepo: mockRepo,
        screen: const Center(child: Text('HOME_SCREEN')),
        requestReference: 'REF123',
      );

      expect(find.text('HOME_SCREEN'), findsOneWidget);
      expect(find.text('Bank Details Request'), findsOneWidget);
      expect(find.textContaining('bank details'), findsOneWidget);
      expect(find.text('Share Details'), findsOneWidget);
      expect(find.byType(TutorReceivedRequestsView), findsNothing);
    });

    testWidgets('popup opens while Profile screen is active', (tester) async {
      await _openReceivedPopupFromFcm(
        tester,
        mockRepo: mockRepo,
        screen: const Center(child: Text('PROFILE_SCREEN')),
        requestReference: 'REF123',
      );

      expect(find.text('PROFILE_SCREEN'), findsOneWidget);
      expect(find.text('Bank Details Request'), findsOneWidget);
      expect(find.text('Share Details'), findsOneWidget);
    });

    testWidgets('popup opens while Wallet screen is active', (tester) async {
      await _openReceivedPopupFromFcm(
        tester,
        mockRepo: mockRepo,
        screen: const Center(child: Text('WALLET_SCREEN')),
        requestReference: 'REF123',
      );

      expect(find.text('WALLET_SCREEN'), findsOneWidget);
      expect(find.text('Bank Details Request'), findsOneWidget);
      expect(find.text('Share Details'), findsOneWidget);
    });

    testWidgets(
        'root navigator not ready does not lose the request and still shows popup',
        (tester) async {
      final service = TutorRequestNotificationService();
      await service.handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
      );
      verify(() => mockRepo.fetchTutorRequestStatus('REF123')).called(1);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Bank Details Request'), findsOneWidget);
    });

    testWidgets(
        'background notification tap opens Received popup after PENDING validation',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      final service = TutorRequestNotificationService();
      await service.handleOpenedMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Bank Details Request'), findsOneWidget);
      expect(find.text('Share Details'), findsOneWidget);
    });

    testWidgets(
        'terminated notification tap restores the request reference and opens popup',
        (tester) async {
      final service = TutorRequestNotificationService();
      await service.handleIncomingFromData(
        {
          'request_reference': 'REF123',
          'type': 'tutor_request',
        },
        messageId: 'terminated_launch',
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Bank Details Request'), findsOneWidget);
      verify(() => mockRepo.fetchTutorRequestStatus('REF123')).called(1);
    });

    testWidgets(
        'persisted background PENDING opens Received popup on resume without GET',
        (tester) async {
      await TutorRequestPendingStore.upsert(
        const TutorRequestPendingEntry(
          requestReference: 'REF123',
          verified: true,
          amount: '100',
          subject: 'Tuition',
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Bank Details Request'), findsOneWidget);
      expect(find.text('Share Details'), findsOneWidget);
      verifyNever(() => mockRepo.fetchTutorRequestStatus('REF123'));
    });

    testWidgets('sender device skips Received popup for its own request',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            educationFeesRepositoryProvider.overrideWithValue(mockRepo),
            tutorReceivedRequestsRepositoryProvider.overrideWithValue(mockRepo),
            educationFeesControllerProvider.overrideWith(
              (ref) => EducationFeesController(repository: mockRepo)
                ..storeTutorRequestReference('REF123'),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, _) => MaterialApp(
              navigatorKey: navigatorKey,
              builder: (context, widget) {
                return TutorRequestNotificationListener(
                  child: widget ?? const SizedBox.shrink(),
                );
              },
              home: const Scaffold(
                body: Center(child: Text('SENDER_HOME')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final service = TutorRequestNotificationService();
      service.debugSetRepository(mockRepo);
      service.debugSetAuthChecker(() async => true);
      await service.handleForegroundMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Bank Details Request'), findsNothing);
      expect(find.text('SENDER_HOME'), findsOneWidget);
    });
  });

  group('Notification tap payload and retry', () {
    late MockEducationFeesRepository mockRepo;

    setUp(() {
      mockRepo = MockEducationFeesRepository();
      _configureService(mockRepo);
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => _pendingStatus('REF123'),
      );
    });

    test('extracts request_reference from flat, nested and JSON-string payloads',
        () {
      expect(
        TutorRequestNotificationService.notificationDataFromPayload({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        })['request_reference'],
        'REF123',
      );
      expect(
        TutorRequestNotificationService.notificationDataFromPayload({
          'title': 'New Tuition Request',
          'data': {
            'request_reference': 'REF123',
            'type': 'tutor_request',
          },
        })['request_reference'],
        'REF123',
      );
      final encoded = TutorRequestNotificationService.notificationDataFromPayload({
        'data': '{"request_reference":"REF123","type":"tutor_request"}',
      });
      expect(
        TutorRequestNotificationService.extractRequestReference(encoded),
        'REF123',
      );
      expect(
        TutorRequestNotificationService.isTutorRequestPayload(encoded),
        isTrue,
      );
    });

    testWidgets('local notification envelope opens the Received popup',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      await TutorRequestNotificationService().handleOpenedData(
        {
          'title': 'New Tuition Request',
          'body': 'You have received a new tuition payment request',
          'data': {
            'request_reference': 'REF123',
            'type': 'tutor_request',
            'route': '/education-tutor/received-requests',
          },
        },
        messageId: 'local_notification_tap',
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('HOME_SCREEN'), findsOneWidget);
      expect(find.text('Bank Details Request'), findsOneWidget);
      verify(() => mockRepo.fetchTutorRequestStatus('REF123')).called(1);
    });

    testWidgets('onMessageOpenedApp data opens the Received popup on the current screen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      await TutorRequestNotificationService().handleOpenedMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
          'route': '/education-tutor/received-requests',
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(TutorReceivedRequestsView), findsNothing);
      expect(find.text('Bank Details Request'), findsOneWidget);
      verify(() => mockRepo.fetchTutorRequestStatus('REF123')).called(1);
    });

    test('tap after a missed presentation does not call status again', () async {
      final service = TutorRequestNotificationService();
      await service.handleOpenedMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
      );

      service.releaseForRetry('REF123');
      final events = <TutorRequestEvent>[];
      final subscription = service.requestEvents.listen(events.add);
      await service.handleOpenedData(
        {
          'request_reference': 'REF123',
          'type': 'tutor_request',
        },
        messageId: 'notification_tap_retry',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(events.map((event) => event.requestReference), contains('REF123'));
      verify(() => mockRepo.fetchTutorRequestStatus('REF123')).called(1);
    });

    testWidgets('auth not ready keeps the tap and opens the popup once auth is ready',
        (tester) async {
      var authed = false;
      TutorRequestNotificationService().debugSetAuthChecker(() async => authed);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      await TutorRequestNotificationService().handleOpenedMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
      );
      expect(find.text('Bank Details Request'), findsNothing);
      verifyNever(() => mockRepo.fetchTutorRequestStatus('REF123'));

      authed = true;
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      await tester.pump();

      expect(find.text('Bank Details Request'), findsOneWidget);
      verify(() => mockRepo.fetchTutorRequestStatus('REF123')).called(1);
    });

    testWidgets('non-PENDING opened notification does not open the popup',
        (tester) async {
      when(() => mockRepo.fetchTutorRequestStatus('REF123')).thenAnswer(
        (_) async => _statusResponse(
          requestReference: 'REF123',
          requestStatus: 'ACCEPTED',
          isPending: false,
          isAccepted: true,
          isRejected: false,
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      await TutorRequestNotificationService().handleOpenedMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Bank Details Request'), findsNothing);
    });

    testWidgets('duplicate notification tap does not open a second popup',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        _wrapWithListener(
          const Center(child: Text('HOME_SCREEN')),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();

      final service = TutorRequestNotificationService();
      await service.handleOpenedMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
      );
      await service.handleOpenedMessage(
        MockRemoteMessage({
          'request_reference': 'REF123',
          'type': 'tutor_request',
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Bank Details Request'), findsOneWidget);
      verify(() => mockRepo.fetchTutorRequestStatus('REF123')).called(1);
    });
  });
}
