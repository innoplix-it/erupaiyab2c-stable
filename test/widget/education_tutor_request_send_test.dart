import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:e_rupaiya/features/educationFees/views/education_tutor_request_view.dart';

Widget _wrap(Widget child) {
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
  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp.router(routerConfig: router),
    ),
  );
}

Widget _view({
  Duration sendDuration = Duration.zero,
  Duration sentLabelDuration = Duration.zero,
  String? maskedAccount,
  int acceptAfterSeconds = 9999,
  Duration redirectDuration = const Duration(seconds: 5),
}) {
  return EducationTutorRequestView(
    tutorName: 'Supriya Sarang Ithape',
    mobile: '9876544582',
    amount: 2000,
    maskedAccount: maskedAccount,
    sendDuration: sendDuration,
    sentLabelDuration: sentLabelDuration,
    acceptAfterSeconds: acceptAfterSeconds,
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
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      _wrap(
        _view(
          sendDuration: const Duration(milliseconds: 300),
          sentLabelDuration: const Duration(milliseconds: 400),
        ),
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
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view()));
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
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view()));
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
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view(
      maskedAccount: 'XXXXXX4582',
      acceptAfterSeconds: 3,
    )));
    await tester.pump();

    await tester.tap(find.text('Send Request'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Timer reaches the simulated accept signal.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Request accepted successfully'), findsOneWidget);
    expect(
      find.text('you will redirected in 5 sec to tutor profile'),
      findsOneWidget,
    );

    // Redirect fires after the announced 5 seconds.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('BANK DETAILS'), findsOneWidget);
    expect(find.text('Subject (Optional)'), findsOneWidget);
    expect(find.text('Proceed to Pay'), findsOneWidget);
    expect(
      find.text('Supriya has accepted your request now yu can sent tution fees'),
      findsOneWidget,
    );
    expect(
      find.text('tutor will be saved for future payments'),
      findsOneWidget,
    );
    // The shared identity card is reused, so the amount pill stays the same.
    expect(find.text('\u20B92,000'), findsOneWidget);
  });

  testWidgets('Go to Home navigates to the home route', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view()));
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

    expect(find.text('Supriya Sarang Ithape'), findsOneWidget);
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
    expect(find.text('9876544582'), findsNothing);
  });
}
