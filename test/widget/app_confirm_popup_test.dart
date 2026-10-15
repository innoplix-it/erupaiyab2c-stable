import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/widgets/app_confirm_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<bool?> openAndTap(WidgetTester tester, String label) async {
    bool? result;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showAppConfirmPopup(
                    context: context,
                    icon: Icons.casino_outlined,
                    title: 'Wheel is Spinning',
                    message: 'Leaving now may lose your reward.',
                    confirmLabel: 'Exit Anyway',
                    cancelLabel: 'Wait',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Wheel is Spinning'), findsOneWidget);
    expect(find.text('Leaving now may lose your reward.'), findsOneWidget);
    expect(find.byIcon(Icons.casino_outlined), findsOneWidget);

    // Same look as the app's other confirmation dialogs.
    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.backgroundColor, Colors.white);
    final cancel = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Wait'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(
      cancel.style!.backgroundColor!.resolve({}),
      AppColors.primary,
    );
    final confirm = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Exit Anyway'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(confirm.style!.backgroundColor!.resolve({}), Colors.white);

    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmPopup), findsNothing);
    return result;
  }

  testWidgets('confirm action resolves true', (tester) async {
    expect(await openAndTap(tester, 'Exit Anyway'), isTrue);
  });

  testWidgets('cancel action resolves false', (tester) async {
    expect(await openAndTap(tester, 'Wait'), isFalse);
  });
}
