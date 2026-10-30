import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_rupaiya/features/educationFees/views/education_tutor_unverified_view.dart';
import '../helpers/responsive_test_sizes.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(home: child),
    );

Widget _view() => const EducationTutorUnverifiedView(
      tutorName: 'Supriya Sarang Ithape',
      amount: 2000,
      amountLabel: '\u20B92000',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders identity card, banner and both CTAs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_wrap(_view()));
    await tester.pump();

    expect(find.text('Supriya Sarang Ithape'), findsOneWidget);
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

  testWidgets('stays overflow-free across the device matrix', (tester) async {
    for (final size in responsiveTestScreenSizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_wrap(_view()));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
    }
  });
}
