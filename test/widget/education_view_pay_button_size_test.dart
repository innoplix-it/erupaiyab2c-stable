import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpAtWidth(WidgetTester tester, double screenW) async {
    const figmaW = 448.0;
    const maxW = 560.0;
    const minW = 320.0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(screenW, 800)),
          child: Builder(
            builder: (context) {
              final w = MediaQuery.sizeOf(context).width.clamp(minW, maxW);
              final u = w / figmaW;
              return Scaffold(
                body: Center(
                  child: SizedBox(
                    key: Key('slot-$screenW'),
                    height: 32 * u,
                    child: ElevatedButton(
                      key: Key('button-$screenW'),
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDD5428),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 10 * u),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16 * u),
                        ),
                      ),
                      child: Text(
                        'View & Pay',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12 * u,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('View & Pay scales with MediaQuery u (320, 448, 560)', (
    tester,
  ) async {
    for (final screenW in [320.0, 448.0, 560.0]) {
      await pumpAtWidth(tester, screenW);
      final clamped = screenW.clamp(320.0, 560.0);
      final u = clamped / 448.0;

      final slot = tester.getSize(find.byKey(Key('slot-$screenW')));
      final button = tester.getSize(find.byKey(Key('button-$screenW')));

      expect(slot.height, closeTo(32 * u, 0.01));
      expect(button.height, closeTo(32 * u, 0.01));
      expect(button.width, greaterThan(0));

      if (screenW == 448.0) {
        // ignore: avoid_print
        print(
          'VIEW_PAY_AT_U1 slotH=${slot.height} buttonW=${button.width} '
          'buttonH=${button.height} badgeSvgW=${105 * u} badgeSvgH=${30 * u}',
        );
      }
    }
  });
}
