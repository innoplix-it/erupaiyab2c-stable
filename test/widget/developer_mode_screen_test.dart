import 'package:e_rupaiya/features/developer_mode/views/developer_mode_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _harness() => ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      ensureScreenSize: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DeveloperModeEnabledScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

/// Sends the Android system back gesture through the navigation channel so we
/// exercise the real PopScope path, not just Navigator.maybePop().
Future<void> _pressBack(WidgetTester tester) async {
  final ByteData message =
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute'));
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    message,
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders the approved lock content', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Developer Mode Enabled'), findsOneWidget);
    expect(find.text('How to fix?'), findsOneWidget);
    expect(find.text('Close App'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back does NOT pop the lock screen (CASE D)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await _pressBack(tester);

    // Still locked: the blocking screen is present and no normal route leaked.
    expect(find.byType(DeveloperModeEnabledScreen), findsOneWidget);
    expect(find.text('Developer Mode Enabled'), findsOneWidget);
    expect(find.text('open'), findsNothing);
  });

  testWidgets('stays overflow-free at the narrowest supported width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 520));
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Close App'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
