import 'package:e_rupaiya/features/profile/models/help_topic.dart';
import 'package:e_rupaiya/features/profile/views/help_support_screen.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _widths = <double>[320, 360, 375, 390, 412, 414, 440];

const _question =
    'How can I keep my payments safe on e-Rupaiya when the question wraps onto more than one line?';

const _answer =
    'To keep your payments safe on e-Rupaiya, always use a strong password and never share your OTP or PIN with anyone. Enable app security features like fingerprint or face lock. Avoid using public Wi-Fi for transactions and regularly check your transaction history. Update the app frequently to stay protected from security threats.';

const _topic = HelpTopic(
  id: 'topic-safe',
  title: _question,
  description: _answer,
);

const _videoTopic = HelpTopic(
  id: 'topic-video',
  title: 'How can I pay a bill using Erupaiya?',
  description: 'Open the biller and complete the payment.',
  video: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('detail shows the question, peach preview, answer and feedback',
      (tester) async {
    await _pumpDetail(tester, topic: _topic, width: 390);

    expect(find.text('Help & Support'), findsNothing);
    expect(find.text(_question), findsOneWidget);
    expect(find.text(_answer), findsOneWidget);
    expect(find.byKey(const Key('help-topic-video-preview')), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.text('Was This Information Helpful ?'), findsOneWidget);
    expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    expect(find.byIcon(Icons.thumb_down), findsOneWidget);
    expect(find.byIcon(Icons.thumb_up_alt_outlined), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    _drainNonLayoutErrors(tester);
  });

  testWidgets('a topic without a video still keeps the preview card',
      (tester) async {
    await _pumpDetail(tester, topic: _topic, width: 360);
    expect(find.byKey(const Key('help-topic-video-preview')), findsOneWidget);
    _drainNonLayoutErrors(tester);
  });

  testWidgets('a topic with a video keeps the same preview and its answer',
      (tester) async {
    await _pumpDetail(tester, topic: _videoTopic, width: 390);
    expect(find.text(_videoTopic.title), findsOneWidget);
    expect(find.text(_videoTopic.description), findsOneWidget);
    expect(find.byKey(const Key('help-topic-video-preview')), findsOneWidget);
    _drainNonLayoutErrors(tester);
  });

  testWidgets('thumbs down opens the feedback sheet once', (tester) async {
    await _pumpDetail(tester, topic: _topic, width: 390, height: 844);

    await tester.tap(find.byKey(const Key('help-topic-thumb-down')));
    await _settle(tester);

    expect(find.text("What Didn't Work For You?"), findsOneWidget);
    expect(find.text('Feedback'), findsWidgets);
    expect(find.text('0 / 400'), findsOneWidget);
    expect(find.byKey(const Key('feedback-close')), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(
      _continueColor(tester),
      const Color(0xFFF2A98E),
    );

    await tester.enterText(find.byType(TextField), 'Not clear');
    await _settle(tester);
    expect(find.text('9 / 400'), findsOneWidget);
    expect(
      _continueColor(tester),
      const Color(0xFFDD5428),
    );

    await tester.tap(find.byKey(const Key('feedback-close')));
    await _settle(tester);
    expect(find.text("What Didn't Work For You?"), findsNothing);

    await tester.tap(find.byKey(const Key('help-topic-thumb-down')));
    await _settle(tester);
    expect(find.text("What Didn't Work For You?"), findsNothing);
    _drainNonLayoutErrors(tester);
  });

  for (final width in _widths) {
    for (final textScale in [1.0, 1.15]) {
      testWidgets(
        'topic detail fits $width at text scale $textScale',
        (tester) async {
          await _pumpDetail(
            tester,
            topic: _topic,
            width: width,
            height: width == 320 ? 568.0 : 844,
            textScale: textScale,
          );
          expect(find.text(_question), findsOneWidget);
          expect(find.byKey(const Key('help-topic-video-preview')),
              findsOneWidget);
          final helpful = find.text('Was This Information Helpful ?');
          await tester.ensureVisible(helpful);
          await tester.pump();
          expect(helpful, findsOneWidget);
          expect(find.byKey(const Key('help-topic-thumb-up')), findsOneWidget);
          _drainNonLayoutErrors(tester);
        },
      );
    }
  }
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required HelpTopic topic,
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

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: HelpTopicDetailView(topic: topic),
      ),
    ),
  );
  await _settle(tester);
  _drainNonLayoutErrors(tester);
}

Color? _continueColor(WidgetTester tester) {
  final button = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Continue'),
  );
  return button.style?.backgroundColor?.resolve(const <WidgetState>{});
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
