import 'package:e_rupaiya/features/services/components/delete_saved_biller_dialog.dart';
import 'package:e_rupaiya/features/services/components/fetch_provider_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<List<bool>> pump(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = size * 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final results = <bool>[];
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.15)),
              child: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async =>
                        results.add(await showDeleteSavedBillerDialog(context)),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  Rect dialogRect(WidgetTester tester) => tester.getRect(
        find
            .descendant(
              of: find.byType(DeleteSavedBillerDialog),
              matching: find.byType(Container),
            )
            .first,
      );

  for (final width in [320.0, 360.0, 375.0, 390.0, 412.0, 440.0]) {
    testWidgets('dialog fits ${width.toInt()}px at 1.15 text', (tester) async {
      final size = Size(width, width * 956 / 440);
      await pump(tester, size);
      expect(tester.takeException(), isNull);

      final rect = dialogRect(tester);
      final inset = width * 24.5 / 440;
      expect(rect.left, moreOrLessEquals(inset, epsilon: 0.5));
      expect(rect.right, moreOrLessEquals(width - inset, epsilon: 0.5));
      expect(rect.top, greaterThan(0));
      expect(rect.bottom, lessThan(size.height));
      if (width == 440) {
        expect(rect.width, moreOrLessEquals(391, epsilon: 0.5));
      }

      for (final text in [
        'Delete Account',
        DeleteSavedBillerDialog.message,
        'No',
        'Yes',
      ]) {
        final r = tester.getRect(find.text(text));
        expect(r.left, greaterThanOrEqualTo(rect.left), reason: text);
        expect(r.right, lessThanOrEqualTo(rect.right), reason: text);
      }

      final close = find.byKey(const ValueKey('delete-account-close'));
      final closeRect = tester.getRect(close);
      final closeIcon = tester.getSize(
        find
            .ancestor(
              of: find.descendant(of: close, matching: find.byType(SvgPicture)),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      double fx(double px) => px * width / 440;
      expect(closeIcon.width, moreOrLessEquals(fx(24)));
      expect(closeIcon.height, moreOrLessEquals(fx(24)));

      final title = tester.widget<Text>(find.text('Delete Account')).style!;
      expect(
        title.fontSize,
        moreOrLessEquals(FetchProviderMetrics.font(16, min: 13)),
      );
      expect(title.fontWeight, FontWeight.w600);
      expect(title.fontFamily, contains('PlusJakartaSans'));
      final body = tester
          .widget<Text>(find.text(DeleteSavedBillerDialog.message))
          .style!;
      expect(
        body.fontSize,
        moreOrLessEquals(FetchProviderMetrics.font(14, min: 12)),
      );
      expect(body.fontWeight, FontWeight.w500);

      Material buttonOf(String label) => tester.widget<Material>(
            find
                .ancestor(of: find.text(label), matching: find.byType(Material))
                .first,
          );
      expect(buttonOf('No').color, const Color(0xFFDD5428));
      expect(buttonOf('Yes').color, const Color(0xFFFFFFFF));
      final noButton = tester.getRect(
        find
            .ancestor(of: find.text('No'), matching: find.byType(Material))
            .first,
      );
      final yesButton = tester.getRect(
        find
            .ancestor(of: find.text('Yes'), matching: find.byType(Material))
            .first,
      );
      expect(noButton.width / yesButton.width,
          moreOrLessEquals(162.5 / 164.5, epsilon: 0.01));
      expect(noButton.top, moreOrLessEquals(yesButton.top));
      expect(yesButton.left - noButton.right, moreOrLessEquals(fx(16)));
      expect(noButton.left - rect.left, moreOrLessEquals(fx(24), epsilon: 0.5));
      expect(
        rect.right - yesButton.right,
        moreOrLessEquals(fx(24), epsilon: 0.5),
      );
      if (width == 440) {
        expect(noButton.width + yesButton.width + 16, moreOrLessEquals(343));
        expect(title.fontSize, 16);
        expect(body.fontSize, 14);
      }
      expect(closeRect.right, lessThanOrEqualTo(rect.right));
      expect(
        closeRect.center.dy,
        moreOrLessEquals(
          tester.getRect(find.text('Delete Account')).center.dy,
          epsilon: 1,
        ),
      );

      final no = tester.getRect(find.text('No'));
      final yes = tester.getRect(find.text('Yes'));
      expect(no.right, lessThan(yes.left));
      expect(yes.bottom, lessThan(rect.bottom));
    });
  }

  testWidgets('X and No cancel, Yes confirms', (tester) async {
    final results = await pump(tester, const Size(390, 844));

    await tester.tap(find.byKey(const ValueKey('delete-account-close')));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteSavedBillerDialog), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteSavedBillerDialog), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteSavedBillerDialog), findsNothing);

    expect(results, [false, false, true]);
  });
}
