import 'package:e_rupaiya/features/educationFees/components/education_tuition_request_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in the same ScreenUtil setup the app uses so widgets that
/// rely on `.r`/`.w` (e.g. CustomElevatedButton) build in tests.
Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(home: child),
    );

/// Pumps a tiny host screen whose button opens the shared popup in [state].
Future<void> _openPopup(
  WidgetTester tester,
  EducationTuitionPopupState state, {
  void Function(Future<bool?> result)? onResult,
}) async {
  await tester.pumpWidget(
    _host(
      Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              final result = showEducationTuitionRequestPopup(
                tester.element(find.byType(ElevatedButton)),
                state: state,
                amount: 2000,
                requesterName: 'Darshan Nikam',
              );
              onResult?.call(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('request state renders avatar header, details and both actions',
      (tester) async {
    await _openPopup(tester, EducationTuitionPopupState.request);

    expect(find.text('Tuition Fee Amount'), findsOneWidget);
    expect(find.text('\u20B92,000'), findsOneWidget);
    expect(find.text('Requested By Darshan Nikam'), findsOneWidget);
    expect(find.text('Awaiting Your Approval'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Accept Request'), findsOneWidget);
    // Initials come from the requester name, same helper as the cards.
    expect(find.text('DN'), findsOneWidget);
  });

  testWidgets('received state renders the new-request copy', (tester) async {
    await _openPopup(tester, EducationTuitionPopupState.received);

    expect(find.text('Tuition Fee Request'), findsOneWidget);
    expect(find.text('You have received a new payment request'),
        findsOneWidget);
    expect(find.text('Pending'), findsNothing);
    expect(find.text('Accept Request'), findsOneWidget);
  });

  testWidgets('accepted state shows the success copy and Done',
      (tester) async {
    await _openPopup(tester, EducationTuitionPopupState.accepted);

    expect(find.text('Request Accepted Successfully'), findsOneWidget);
    expect(find.text('Request Accepted'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Accept Request'), findsNothing);
  });

  testWidgets('declined state shows the decline copy and Done',
      (tester) async {
    await _openPopup(tester, EducationTuitionPopupState.declined);

    expect(find.text('Request Declined'), findsWidgets);
    expect(find.text('Darshan Nikam will be notified about your decision.'),
        findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('accept returns true, decline returns false, close returns null',
      (tester) async {
    Future<bool?>? result;

    await _openPopup(tester, EducationTuitionPopupState.received,
        onResult: (r) => result = r);
    await tester.tap(find.text('Accept Request'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);

    await _openPopup(tester, EducationTuitionPopupState.received,
        onResult: (r) => result = r);
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);

    await _openPopup(tester, EducationTuitionPopupState.request,
        onResult: (r) => result = r);
    await tester.tap(find.byKey(const ValueKey('tuitionPopupClose')));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });
}
