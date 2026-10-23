import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/profile/controllers/help_support_controller.dart';
import 'package:e_rupaiya/features/profile/controllers/recent_payment_help_controller.dart';
import 'package:e_rupaiya/features/profile/models/help_topic.dart';
import 'package:e_rupaiya/features/profile/models/support_faq_item.dart';
import 'package:e_rupaiya/features/profile/models/support_latest_transaction.dart';
import 'package:e_rupaiya/features/profile/repositories/help_support_repository.dart';
import 'package:e_rupaiya/features/profile/repositories/support_faq_repository.dart';
import 'package:e_rupaiya/features/profile/views/help_support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _widths = <double>[320, 360, 375, 390, 412, 414, 440];

const _electricity = SupportLatestTransaction(
  id: 'bill-1',
  paymentType: 'Utility Payment',
  billerName: 'Maharashtra State Electricity Distribution',
  amount: '160.00',
  status: 'failed',
  date: '2026-03-08 10:00:00',
  type: 'BBPS',
  transactionId: 'txn-1',
);

const _recharge = SupportLatestTransaction(
  id: 'bill-2',
  paymentType: 'Mobile Recharge',
  billerName: 'Airtel Prepaid',
  amount: '99.00',
  status: 'success',
  date: '2026-03-01 09:00:00',
  type: 'BBPS',
  transactionId: 'txn-2',
);

const _longQuestion =
    'How can I keep my payments safe on e-Rupaiya when the question wraps onto more than one line?';

final _topics = [
  const HelpTopic(
    id: 'topic-1',
    title: _longQuestion,
    description: 'Use the app PIN and do not share it.',
    video: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  ),
  const HelpTopic(
    id: 'topic-2',
    title: 'How do I add my bank account on e-Rupaiya?',
    description: 'Open your profile and add the bank.',
  ),
];

HelpSupportState _readyState() => const HelpSupportState(
      latestTransactions: [_electricity, _recharge],
      helpTopics: [],
    ).copyWith(
      isLoading: false,
      helpTopics: _topics,
    );

class _ScriptedHelpController extends HelpSupportController {
  _ScriptedHelpController(this._next)
      : super(repository: HelpSupportRepository(dio: Dio()));

  final HelpSupportState _next;

  @override
  Future<void> fetch() async {
    state = _next;
  }
}

class _SilentFaqRepository extends SupportFaqRepository {
  _SilentFaqRepository() : super(dio: Dio());

  @override
  Future<List<SupportFaqItem>> fetchFaqs({required String category}) async {
    return const [];
  }
}

void _applyView(
  WidgetTester tester, {
  required double width,
  double height = 800,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
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

Future<void> _pumpHelp(
  WidgetTester tester, {
  required HelpSupportState state,
  required double width,
  double height = 800,
  double textScale = 1,
}) async {
  _applyView(tester, width: width, height: height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  final router = GoRouter(
    initialLocation: RouteConstants.helpSupport,
    routes: [
      GoRoute(
        path: RouteConstants.helpSupport,
        builder: (_, __) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: RouteConstants.supportTickets,
        builder: (_, __) => const Scaffold(body: Text('Tickets Screen')),
      ),
      GoRoute(
        path: RouteConstants.helpCenterChat,
        builder: (_, __) => const Scaffold(body: Text('Chat Screen')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        helpSupportControllerProvider.overrideWith(
          (ref) => _ScriptedHelpController(state),
        ),
        supportFaqRepositoryProvider.overrideWithValue(_SilentFaqRepository()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  _drainNonLayoutErrors(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Help & Support shows Figma sections and live rows',
      (tester) async {
    await _pumpHelp(tester, state: _readyState(), width: 390);

    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Bill Details'), findsOneWidget);
    expect(find.text('Utility Payment'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(
      find.text('Maharashtra State Electricity Distribution'),
      findsOneWidget,
    );
    expect(find.text('₹160.00'), findsOneWidget);
    expect(find.text('Mobile Recharge'), findsOneWidget);
    expect(find.text('Help Topics'), findsOneWidget);
    expect(find.text(_longQuestion), findsOneWidget);
    expect(find.text('Recommended Videos'), findsOneWidget);
    expect(find.text('Quick Contact'), findsOneWidget);
    expect(find.text('support@erupaiya.com'), findsOneWidget);
    expect(find.text("Need Help? We've Got You"), findsNothing);
    expect(find.text('Chat With Us'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    expect(find.byKey(const Key('recommended-video-play')), findsOneWidget);
    _drainNonLayoutErrors(tester);
  });

  testWidgets('Tickets opens the existing tickets screen', (tester) async {
    await _pumpHelp(tester, state: _readyState(), width: 390);

    await tester.tap(find.text('Tickets'));
    await _settle(tester);
    expect(find.text('Tickets Screen'), findsOneWidget);
    _drainNonLayoutErrors(tester);
  });

  testWidgets('a help topic opens its existing detail', (tester) async {
    await _pumpHelp(tester, state: _readyState(), width: 390, height: 900);

    final topic = find.text('How do I add my bank account on e-Rupaiya?');
    await tester.ensureVisible(topic);
    await tester.pump();
    await tester.tap(topic);
    await _settle(tester);
    expect(find.text('Open your profile and add the bank.'), findsOneWidget);
    _drainNonLayoutErrors(tester);
  });

  testWidgets('bill card opens that transaction help screen', (tester) async {
    await _pumpHelp(tester, state: _readyState(), width: 390);

    await tester.tap(find.text('Utility Payment'));
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(find.text('Need help with your recent payment?'), findsOneWidget);
    expect(
      find.text('Maharashtra State Electricity Distribution'),
      findsWidgets,
    );
    _drainNonLayoutErrors(tester);
  });

  testWidgets('loading state keeps the section placeholders', (tester) async {
    await _pumpHelp(
      tester,
      state: const HelpSupportState(isLoading: true),
      width: 360,
    );
    expect(find.text('Loading help topic'), findsWidgets);
    expect(find.text('No recent transactions'), findsNothing);
    expect(find.text('Bill Details'), findsOneWidget);
  });

  testWidgets('empty state keeps the existing empty messages', (tester) async {
    await _pumpHelp(
      tester,
      state: const HelpSupportState(),
      width: 360,
    );
    expect(find.text('No recent transactions'), findsOneWidget);
    expect(find.text('No help topics available'), findsOneWidget);
    expect(find.text('Recommended Videos'), findsNothing);
    expect(find.text('Quick Contact'), findsOneWidget);
    expect(find.text('support@erupaiya.com'), findsOneWidget);
    _drainNonLayoutErrors(tester);
  });

  for (final width in _widths) {
    for (final textScale in [1.0, 1.15]) {
      testWidgets('help layout fits $width at text scale $textScale',
          (tester) async {
        await _pumpHelp(
          tester,
          state: _readyState(),
          width: width,
          height: width == 320 ? 568 : 844,
          textScale: textScale,
        );
        expect(find.text('Tickets'), findsOneWidget);
        expect(find.text(_longQuestion), findsOneWidget);
        final contact = find.text('Quick Contact');
        await tester.ensureVisible(contact);
        await tester.pump();
        expect(contact, findsOneWidget);
        expect(find.text('support@erupaiya.com'), findsOneWidget);
        _drainNonLayoutErrors(tester);
      });
    }
  }
}
