import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/profile/controllers/support_tickets_controller.dart';
import 'package:e_rupaiya/features/profile/models/support_ticket.dart';
import 'package:e_rupaiya/features/profile/repositories/support_tickets_repository.dart';
import 'package:e_rupaiya/features/profile/views/support_tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _widths = <double>[320, 360, 375, 390, 412, 414, 440];

SupportTicket _ticket({
  required String id,
  required String description,
  required String status,
  required String date,
}) {
  return SupportTicket(
    id: id,
    transactionId: 'txn-$id',
    service: 'Rent & Utility Payments',
    issueType: 'Payment',
    isTransactionRelated: true,
    description: description,
    status: status,
    createdAtRaw: date,
    screenshot: null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ticket badges match the Figma colors and labels',
      (tester) async {
    await _pumpTickets(tester, width: 390);

    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Open Tickets'), findsOneWidget);
    expect(find.text('Why Payment Faild'), findsNWidgets(2));
    expect(
        find.text("Rent & Utility Payments  •  14 Apr'26"), findsNWidgets(2));
    expect(_badgeColor(tester, 'Open'), const Color(0xFFDAA507));
    expect(_badgeColor(tester, 'Resolved'), const Color(0xFF058337));
    expect(_badgeColor(tester, 'Closed'), const Color(0xFFF54237));
    expect(_badgeColor(tester, 'Reopened'), const Color(0xFFB07B00));
    _drainNonLayoutErrors(tester);
  });

  for (final width in _widths) {
    for (final textScale in [1.0, 1.15]) {
      testWidgets('tickets layout fits $width at text scale $textScale',
          (tester) async {
        await _pumpTickets(
          tester,
          width: width,
          height: width == 320 ? 568 : 844,
          textScale: textScale,
        );
        expect(find.text('Open'), findsOneWidget);
        final closed = find.text('Closed');
        await tester.ensureVisible(closed);
        await tester.pump();
        expect(closed, findsOneWidget);
        _drainNonLayoutErrors(tester);
      });
    }
  }
}

Color _badgeColor(WidgetTester tester, String label) {
  final box = tester.widget<Container>(find.byKey(Key('ticket-status-$label')));
  return (box.decoration! as BoxDecoration).color!;
}

Future<void> _pumpTickets(
  WidgetTester tester, {
  required double width,
  double height = 844,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  final tickets = [
    _ticket(
      id: '1',
      description: 'Why Payment Faild',
      status: 'Open',
      date: '2026-04-14 10:00:00',
    ),
    _ticket(
      id: '2',
      description: 'Why Payment Faild',
      status: 'Resolved',
      date: '2026-04-14 10:00:00',
    ),
    _ticket(
      id: '3',
      description: 'Refund is not getting',
      status: 'Closed',
      date: '2026-07-10 10:00:00',
    ),
    _ticket(
      id: '4',
      description: 'Facing some issues',
      status: 'Reopened',
      date: '2026-07-03 10:00:00',
    ),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportTicketsControllerProvider.overrideWith(
          (ref) => _ScriptedTicketsController(
            SupportTicketsState(tickets: tickets),
          ),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const SupportTicketsScreen(),
        ),
      ),
    ),
  );
  await _settle(tester);
  _drainNonLayoutErrors(tester);
}

class _ScriptedTicketsController extends SupportTicketsController {
  _ScriptedTicketsController(this._next)
      : super(repository: SupportTicketsRepository(dio: Dio()));

  final SupportTicketsState _next;

  @override
  Future<void> fetchTickets() async {
    state = _next;
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _drainNonLayoutErrors(WidgetTester tester) {
  Object? error = tester.takeException();
  while (error != null) {
    final text = '$error';
    expect(text, isNot(contains('RenderFlex')));
    expect(text, isNot(contains('overflowed')));
    error = tester.takeException();
  }
}
