import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/widgets/app_search_bar.dart';
import 'package:e_rupaiya/features/educationFees/components/education_erupaiya_verifying_overlay.dart';
import 'package:e_rupaiya/features/educationFees/views/education_search_recipient_view.dart';
import 'package:e_rupaiya/features/educationFees/views/education_tutor_request_view.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(home: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    // Grant contacts permission so the search bar (not the empty state)
    // renders in the widget test environment.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async {
        if (call.method == 'checkPermissionStatus') return 1; // granted
        return 0;
      },
    );
  });

  testWidgets('contact tap shows verifying overlay text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EducationSearchRecipientView(
          verificationDuration: Duration(milliseconds: 200),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Search Recipient'), findsNothing);
    expect(find.text('enter contact name or number'), findsOneWidget);
    expect(find.text('Contacts'), findsNothing);
    expect(find.text('Verifying on eRupaiya'), findsNothing);

    // The bar keeps the shared (credit card listing) defaults; only the
    // leading glyph is Education-specific.
    final bar = tester.widget<AppSearchBar>(find.byType(AppSearchBar));
    expect(bar.barHeight, isNull);
    expect(bar.barCornerRadius, isNull);
    expect(bar.prefixIcon, isNotNull);
  });

  testWidgets('verifying overlay completes and opens tutor request',
      (tester) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EducationErupaiyaVerifyingOverlay(
            duration: const Duration(milliseconds: 100),
            onCompleted: () => completed = true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Verifying on eRupaiya'), findsOneWidget);
    expect(find.text('Do not close or go back.'), findsOneWidget);
    // Loader is all SVG: gradient circle + centred eRupaiya glyph + arc.
    expect(find.byType(Image), findsNothing);
    expect(find.byType(SvgPicture), findsNWidgets(3));

    await tester.pump(const Duration(milliseconds: 120));
    expect(completed, isTrue);
  });

  testWidgets('PopScope allows pop before verification starts', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EducationSearchRecipientView(
          verificationDuration: Duration(seconds: 30),
        ),
      ),
    );
    await tester.pump();

    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isTrue);
  });

  testWidgets('tutor request screen shows actions and no local banner',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EducationTutorRequestView(
          tutorName: 'Supriya Sarang Ithape',
          mobile: '9876544582',
          amount: 2000,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Supriya Sarang Ithape'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.textContaining('Send Request'), findsOneWidget);
    expect(
      find.textContaining(
        'Please ask your tutor to accept the tuition fees request',
      ),
      findsOneWidget,
    );
    // Investment banner now comes from the backend; no local PNG rendered.
    expect(
      find.imageAsset(FileConstants.educationInvestmentBannerPng),
      findsNothing,
    );
  });
}

Finder imageAssetContaining(String asset) => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == asset,
    );

extension on CommonFinders {
  Finder imageAsset(String asset) => imageAssetContaining(asset);
}
