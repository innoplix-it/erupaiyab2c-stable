import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/features/mobile_prepaid/components/recharge_quick_action_card.dart';
import 'package:e_rupaiya/features/services/components/bharat_connect_consent_card.dart';
import 'package:e_rupaiya/widgets/bill_sample_terms_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = size * 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
              child: const Scaffold(body: _PayNowHarness()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 360.0, 375.0, 390.0, 412.0, 440.0]) {
    testWidgets(
        'consent card keeps Figma width inside 16.w padding at '
        '${width.toInt()}px', (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = Size(width, width * 956 / 440) * 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          fontSizeResolver: FontSizeResolvers.radius,
          builder: (context, _) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [BharatConnectConsentCard()],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expectConsentCardGeometry(tester, width);
    });

    testWidgets('Pay Now pieces fit ${width.toInt()}px at 1.15 text',
        (tester) async {
      await pump(tester, Size(width, width * 956 / 440));
      expect(tester.takeException(), isNull);

      for (final finder in [
        find.text('Maharashtra State Electricity Distribution Co. Ltd'),
        find.text('View Sample Bill'),
        find.text(BharatConnectConsentCard.message),
      ]) {
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      }

      expectConsentCardGeometry(tester, width);

      final logo = tester.getSize(find.byType(SimCardIconContainer));
      expect(logo.width, moreOrLessEquals(logo.height));
      if (width == 440) {
        expect(logo.width, moreOrLessEquals(50, epsilon: 0.5));
        final header = tester.getSize(
          find
              .ancestor(
                of: find.text('View Sample Bill'),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
        expect(header.height, greaterThanOrEqualTo(54 - 0.5));
      }

      await tester.tap(find.text('View Sample Bill'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Bill Sample'), findsOneWidget);
    });
  }

  testWidgets('styles match the Figma spec', (tester) async {
    await pump(tester, const Size(440, 956));

    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      (svg.bytesLoader as SvgAssetLoader).assetName,
      BillSampleTermsCard.viewSampleBillIcon,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.keyboard_arrow_down)).color,
      const Color(0xFF000000),
    );

    final label = tester.widget<Text>(find.text('View Sample Bill')).style!;
    expect(label.color, const Color(0xFFDD5428));
    expect(label.fontWeight, FontWeight.w500);

    final title = tester
        .widget<Text>(
          find.text('Maharashtra State Electricity Distribution Co. Ltd'),
        )
        .style!;
    expect(title.fontWeight, FontWeight.w500);
    expect(title.height, 1);

    final consent =
        tester.widget<Text>(find.text(BharatConnectConsentCard.message)).style!;
    expect(consent.fontWeight, FontWeight.w400);
    expect(consent.height, 16 / 12);
    final card = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(BharatConnectConsentCard),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (card.decoration! as BoxDecoration).color,
      const Color(0xFFF9F9F9),
    );
  });
}

void expectConsentCardGeometry(WidgetTester tester, double width) {
  double fx(double px) => px * width / 440;
  final card = tester.getRect(
    find
        .descendant(
          of: find.byType(BharatConnectConsentCard),
          matching: find.byType(Container),
        )
        .first,
  );
  expect(card.left, moreOrLessEquals(fx(24), epsilon: 0.5));
  expect(card.width, moreOrLessEquals(fx(392), epsilon: 0.5));
  expect(card.height, greaterThanOrEqualTo((64 * 690 / 956).h - 0.5));

  final logo = tester.getRect(
    find.descendant(
      of: find.byType(BharatConnectConsentCard),
      matching: find.byType(Image),
    ),
  );
  final text = tester.getRect(find.text(BharatConnectConsentCard.message));
  expect(logo.left, moreOrLessEquals(card.left + fx(16) + 1, epsilon: 1.5));
  expect(text.left - logo.right, moreOrLessEquals(fx(16), epsilon: 0.5));
  expect(logo.center.dy, moreOrLessEquals(card.center.dy, epsilon: 1));
  expect(text.center.dy, moreOrLessEquals(card.center.dy, epsilon: 1));
  expect(logo.top, greaterThan(card.top));
  expect(logo.bottom, lessThan(card.bottom));
  expect(text.top, greaterThan(card.top));
  expect(text.bottom, lessThan(card.bottom));
  expect(text.right, lessThanOrEqualTo(card.right - fx(16) + 0.5));
}

class _PayNowHarness extends StatefulWidget {
  const _PayNowHarness();

  @override
  State<_PayNowHarness> createState() => _PayNowHarnessState();
}

class _PayNowHarnessState extends State<_PayNowHarness> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final side = (24 * 360 / 440).w;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: side, vertical: 16),
      child: Column(
        children: [
          SimpleQuickActionCard(
            title: 'maharashtra State Electricity Distribution Co. Ltd',
            subtitle: '',
            leadingAsset: FileConstants.bharatConnectColor,
            actionLabel: 'Change',
            operatorStyle: true,
            onAction: () {},
          ),
          const SizedBox(height: 16),
          BillSampleTermsCard(
            isExpanded: expanded,
            onToggle: () => setState(() => expanded = !expanded),
            viewSampleBillStyle: true,
          ),
          const SizedBox(height: 16),
          const BharatConnectConsentCard(),
        ],
      ),
    );
  }
}
