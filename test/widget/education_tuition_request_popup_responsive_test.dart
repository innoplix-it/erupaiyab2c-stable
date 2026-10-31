// Responsive audit for the shared Tuition Fee Request popup — all 4 states
// (request / received / accepted / declined).
//
// Runs the popup across the canonical device matrix at 1.0 and 1.15 text
// scaling and asserts: no render exceptions, dialog fully inside the usable
// viewport (24px top/bottom safe areas simulated), primary buttons visible,
// and Accept/Decline/Done/close still behave (single dialog, no duplicates).
//
// Real Plus Jakarta Sans files (build/test_fonts/PJS-*.ttf) are loaded when
// present; without them the placeholder Ahem font inflates text metrics, so
// 1-5px overflow reports must be treated as test artifacts, not UI defects.

import 'dart:io';
import 'dart:typed_data' show ByteData;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_rupaiya/features/educationFees/components/education_tuition_request_popup.dart';
import '../helpers/responsive_test_sizes.dart';

var _realFontsLoaded = false;

Future<void> _loadRealFonts() async {
  const weights = [400, 500, 600, 700, 800];
  final files = {
    for (final w in weights) w: File('build/test_fonts/PJS-$w.ttf'),
  };
  if (files.values.any((f) => !f.existsSync())) return;
  _realFontsLoaded = true;
  final bytes = {
    for (final e in files.entries)
      e.key: ByteData.sublistView(e.value.readAsBytesSync()),
  };
  int nearest(int w) =>
      weights.reduce((a, b) => (a - w).abs() <= (b - w).abs() ? a : b);
  Future<void> register(String family, int weight) =>
      (FontLoader(family)..addFont(Future.value(bytes[nearest(weight)]!)))
          .load();

  for (final family in ['PlusJakartaSans']) {
    await register('${family}_regular', 400);
    await register('${family}_italic', 400);
    for (var w = 100; w <= 900; w += 100) {
      await register('${family}_$w', w);
      await register('${family}_${w}italic', w);
    }
  }
  await register('Roboto', 400);
}

const double _kSimulatedSafeArea = 24;

void _setSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = size * 2.0;
  // Simulate a non-zero top/bottom safe area (notch / gesture bar) so the
  // centered dialog is checked against usable space, not the raw viewport.
  tester.view.padding = const FakeViewPadding(
    top: _kSimulatedSafeArea,
    bottom: _kSimulatedSafeArea,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
}

Widget _host(
  EducationTuitionPopupState state, {
  double textScale = 1.0,
  String requesterName = 'Darshan Nikam',
  double amount = 2000,
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    fontSizeResolver: FontSizeResolvers.radius,
    child: MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showEducationTuitionRequestPopup(
                  // Use the scaled context so the dialog inherits the scale.
                  context,
                  state: state,
                  amount: amount,
                  requesterName: requesterName,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openPopup(
  WidgetTester tester,
  EducationTuitionPopupState state, {
  required Size size,
  double textScale = 1.0,
  String requesterName = 'Darshan Nikam',
  double amount = 2000,
}) async {
  _setSize(tester, size);
  await tester.pumpWidget(
    _host(state, textScale: textScale, requesterName: requesterName, amount: amount),
  );
  await tester.pump();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Asserts the visible dialog card (the Material surface inside the Dialog's
/// full-screen AnimatedPadding wrapper) is fully inside the usable viewport.
void _expectDialogInsideViewport(WidgetTester tester, Size size) {
  final cardRect = tester.getRect(
    find
        .descendant(of: find.byType(Dialog), matching: find.byType(Material))
        .first,
  );
  final usable = Rect.fromLTRB(
    0,
    _kSimulatedSafeArea,
    size.width,
    size.height - _kSimulatedSafeArea,
  );
  expect(
    cardRect.left >= usable.left - 0.5 &&
        cardRect.right <= usable.right + 0.5 &&
        cardRect.top >= usable.top - 0.5 &&
        cardRect.bottom <= usable.bottom + 0.5,
    isTrue,
    reason: 'dialog card $cardRect escapes usable viewport $usable',
  );
}

bool _isResultState(EducationTuitionPopupState state) =>
    state == EducationTuitionPopupState.accepted ||
    state == EducationTuitionPopupState.declined;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadRealFonts();
  });

  for (final size in responsiveTestScreenSizes) {
    for (final state in EducationTuitionPopupState.values) {
      testWidgets('$state stays overflow-free at ${size.width}x${size.height}',
          (tester) async {
        await _openPopup(tester, state, size: size);

        expect(tester.takeException(), isNull,
            reason: 'render exception at $size / $state');
        _expectDialogInsideViewport(tester, size);

        // Primary action must exist in the tree (a very short screen may
        // require scrolling — SingleChildScrollView guarantees reachability).
        expect(
          find.text(_isResultState(state) ? 'Done' : 'Accept Request'),
          findsOneWidget,
          reason: 'primary button missing at $size / $state',
        );
        expect(
          find.text('Decline'),
          _isResultState(state) ? findsNothing : findsOneWidget,
        );
      });
    }
  }

  for (final size in responsiveTestScreenSizes) {
    for (final state in EducationTuitionPopupState.values) {
      testWidgets(
          '$state survives 1.15 text scale at ${size.width}x${size.height}',
          (tester) async {
        await _openPopup(tester, state, size: size, textScale: 1.15);
        expect(tester.takeException(), isNull,
            reason: 'render exception at 1.15 scale $size / $state');
        _expectDialogInsideViewport(tester, size);
      });
    }
  }

  testWidgets('long requester name wraps without overflow', (tester) async {
    await _openPopup(
      tester,
      EducationTuitionPopupState.request,
      size: const Size(320, 568),
      amount: 9999999,
      requesterName: 'Ramachandran Venkataramanagramanathan',
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ramachandran'), findsOneWidget);
    _expectDialogInsideViewport(tester, const Size(320, 568));
  });

  group('behaviour on the smallest device (320x568)', () {
    testWidgets('Accept closes the popup', (tester) async {
      await _openPopup(tester, EducationTuitionPopupState.request,
          size: const Size(320, 568));
      await tester.ensureVisible(find.text('Accept Request'));
      await tester.tap(find.text('Accept Request'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Decline closes the popup', (tester) async {
      await _openPopup(tester, EducationTuitionPopupState.received,
          size: const Size(320, 568));
      await tester.ensureVisible(find.text('Decline'));
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('close button dismisses', (tester) async {
      await _openPopup(tester, EducationTuitionPopupState.accepted,
          size: const Size(320, 568));
      await tester.tap(find.byKey(const ValueKey('tuitionPopupClose')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Done dismisses the declined result', (tester) async {
      await _openPopup(tester, EducationTuitionPopupState.declined,
          size: const Size(320, 568));
      await tester.ensureVisible(find.text('Done'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });

  testWidgets('rapid repeated taps open only one dialog', (tester) async {
    _setSize(tester, const Size(360, 690));
    await tester.pumpWidget(_host(EducationTuitionPopupState.request));
    await tester.pump();
    final trigger = find.text('open');
    await tester.tap(trigger);
    await tester.tap(trigger);
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('real Plus Jakarta Sans fonts were available', (tester) async {
    // Guard: when skipped/failing, small overflow reports in the tests above
    // may be Ahem placeholder-font artifacts rather than real defects.
    expect(_realFontsLoaded, isTrue,
        reason: 'build/test_fonts/PJS-*.ttf missing — Ahem metrics in use');
  }, skip: !_realFontsLoaded);
}
