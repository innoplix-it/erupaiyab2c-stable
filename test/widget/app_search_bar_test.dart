import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:e_rupaiya/widgets/app_search_bar.dart';
import 'package:e_rupaiya/widgets/common_search_bar.dart';
import 'package:e_rupaiya/widgets/search_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

double _r(double px) => (px * 360 / 440).r;

/// The Electricity "Search by billers" bar exactly as it was configured
/// before being extracted into [AppSearchBar].
Widget _legacyElectricityBar(TextEditingController controller) =>
    CommonSearchBar(
      hintText: 'Search by billers',
      controller: controller,
      height: _r(54),
      radius: _r(12),
      borderWidth: 0.5,
      borderColor: const Color(0xFFD7D7D7),
      fillColor: const Color(0xFFFFFFFF),
      boxShadow: [
        BoxShadow(
          color: const Color(0x0F000000),
          offset: Offset(0, _r(4)),
          blurRadius: _r(16),
        ),
      ],
      hintStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w400,
        fontSize: (14 * 360 / 440).sp.clamp(12.0, 14.0).toDouble(),
        height: 1,
        letterSpacing: 0,
        color: const Color(0xFF7C7C7C),
      ),
    );

Widget _sharedBar(TextEditingController controller) => AppSearchBar(
      hintText: 'Search by billers',
      controller: controller,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    // The pixel capture needs real async time, which lets google_fonts'
    // offline lookup fail inside the test. Serve every google_fonts .ttf it
    // asks for from the SDK's bundled Roboto so the load succeeds instead.
    final fontBytes = File(
      '${Platform.environment['FLUTTER_ROOT']}'
      '/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
    ).readAsBytesSync();
    const families = ['PlusJakartaSans', 'BricolageGrotesque'];
    const weights = [
      'Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Light', //
    ];
    final manifest = <String, List<Object?>>{
      for (final family in families)
        for (final weight in weights) 'google_fonts/$family-$weight.ttf': [],
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (key == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage(manifest);
      }
      if (manifest.containsKey(key)) {
        return ByteData.sublistView(Uint8List.fromList(fontBytes));
      }
      return null;
    });
  });

  final boundaryKey = GlobalKey();

  Future<void> pump(
    WidgetTester tester,
    double width, {
    required String text,
    Widget Function(TextEditingController) bar = _sharedBar,
    double textScale = 1.0,
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(width, 800) * 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController(text: text);
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
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      RepaintBoundary(
                        key: boundaryKey,
                        child: bar(controller),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Let google_fonts finish loading so both bars render with the same font.
    await tester.runAsync(GoogleFonts.pendingFonts);
    await tester.pump();
  }

  Future<List<int>> pixels(WidgetTester tester) async {
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return data!.buffer.asUint8List().toList();
    });
    return bytes!;
  }

  for (final width in [320.0, 360.0, 375.0, 390.0, 412.0, 440.0]) {
    for (final text in ['', 'Tata']) {
      testWidgets(
          'matches the Electricity bar pixel-for-pixel at ${width.toInt()}px'
          '${text.isEmpty ? ' (hint)' : ' (typed text)'}', (tester) async {
        // Render each bar alone in the same spot so anti-aliasing is
        // comparable, then compare the raw pixels.
        await pump(tester, width, text: text, bar: _legacyElectricityBar);
        final legacySize = tester.getSize(find.byKey(boundaryKey));
        final legacyPixels = await pixels(tester);

        await pump(tester, width, text: text);
        final sharedSize = tester.getSize(find.byKey(boundaryKey));
        expect(sharedSize.width, moreOrLessEquals(legacySize.width));
        expect(sharedSize.height, moreOrLessEquals(legacySize.height));
        expect(await pixels(tester), legacyPixels);
      });
    }

    testWidgets('fits without overflow at ${width.toInt()}px, 1.15 text',
        (tester) async {
      await pump(tester, width, text: '', textScale: 1.15);
      expect(tester.takeException(), isNull);
      final rect = tester.getRect(find.byType(AppSearchBar));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(width));
      expect(rect.height, moreOrLessEquals(AppSearchBar.height));
    });
  }

  testWidgets('forwards input options and shows a trailing widget',
      (tester) async {
    await pump(tester, 360, text: '');
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final changes = <String>[];
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: AppSearchBar(
              hintText: 'Enter mobile number',
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              showSearchIcon: false,
              prefixText: '+91 ',
              onChanged: changes.add,
              trailing: const Text('toggle'),
            ),
          ),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode, focusNode);
    expect(field.keyboardType, TextInputType.phone);
    expect(find.byType(SearchBarLeadingIcon), findsNothing);
    expect(find.text('toggle'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '98a76');
    expect(controller.text, '9876');
    expect(changes.last, '9876');
  });
}
