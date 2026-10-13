import 'package:e_rupaiya/features/profile/controllers/profile_controller.dart';
import 'package:e_rupaiya/features/profile/models/profile_model.dart';
import 'package:e_rupaiya/features/profile/models/profile_state.dart';
import 'package:e_rupaiya/features/profile/repositories/profile_repository.dart';
import 'package:e_rupaiya/features/spinandear/controllers/spin_options_controller.dart';
import 'package:e_rupaiya/features/spinandear/helpers/spin_sound_controller.dart';
import 'package:e_rupaiya/features/spinandear/models/spin_options_state.dart';
import 'package:e_rupaiya/features/spinandear/repositories/spin_repository.dart';
import 'package:e_rupaiya/features/spinandear/views/spin_and_win_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _FakeProfileRepository implements ProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestProfileController extends ProfileController {
  _TestProfileController(ProfileState initial)
      : super(repository: _FakeProfileRepository()) {
    state = initial;
  }

  int fetchProfileCallCount = 0;

  @override
  Future<void> fetchProfile() async {
    fetchProfileCallCount++;
  }

  @override
  Future<void> fetchProfileIfNeeded({
    Duration ttl = const Duration(minutes: 1),
    bool force = false,
  }) async {
    fetchProfileCallCount++;
  }

  void updateState(ProfileState newState) {
    state = newState;
  }
}

class _FakeSpinRepository implements SpinRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestSpinOptionsController extends SpinOptionsController {
  _TestSpinOptionsController() : super(repository: _FakeSpinRepository()) {
    state = const SpinOptionsState(
      isLoading: false,
      options: {
        'Normal': [10, 20, 50, 100],
      },
    );
  }

  @override
  Future<void> fetchSpinOptions() async {}
}

ProfileModel _makeProfile({required int spins}) {
  return ProfileModel(
    id: 'user_123',
    name: 'Test User',
    mobile: '9876543210',
    normalSpinRemaining: spins,
  );
}

/// Captures the cues the screen triggers so spin audio can be asserted without
/// a real audio platform.
class _RecordingSpinAudio implements SpinAudioPlayer {
  final List<String> plays = [];
  int stopCount = 0;

  @override
  Future<void> disableLooping() async {}

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> play(String asset) async => plays.add(asset);

  @override
  Future<void> dispose() async {}
}

Widget _buildTestApp({
  required _TestProfileController profileController,
  Size screenSize = const Size(360, 690),
}) {
  return ProviderScope(
    overrides: [
      profileControllerProvider.overrideWith((ref) => profileController),
      spinOptionsControllerProvider.overrideWith(
        (ref) => _TestSpinOptionsController(),
      ),
    ],
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const SpinAndWinView(),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Spin & Win Button - Backend Spin Count', () {
    testWidgets('1. Backend returns 0 spins -> Try Tomorrow is displayed and enabled',
        (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 0),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();

      // "Try Tomorrow" text should be displayed
      expect(find.text('Try Tomorrow'), findsOneWidget);
      expect(find.text('Spin The Wheel'), findsNothing);

      // Tapping must navigate home, so the button is enabled (onPressed !=
      // null) while keeping the exact same solid orange + white look.
      final elevatedButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Try Tomorrow'),
      );
      expect(elevatedButton.onPressed, isNotNull);
      expect(
        elevatedButton.style?.backgroundColor?.resolve({WidgetState.disabled}),
        equals(const Color(0xFFDD5428)),
      );
      expect(
        elevatedButton.style?.foregroundColor?.resolve({WidgetState.disabled}),
        equals(Colors.white),
      );
    });

    testWidgets(
        '2. Backend returns more than 0 spins -> Spin The Wheel is displayed and enabled',
        (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 3),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();

      // "Spin The Wheel" text should be displayed
      expect(find.text('Spin The Wheel'), findsOneWidget);
      expect(find.text('Try Tomorrow'), findsNothing);

      // Elevated button should be enabled (onPressed != null)
      final elevatedButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Spin The Wheel'),
      );
      expect(elevatedButton.onPressed, isNotNull);
    });

    testWidgets(
        '3. Spin count changes from > 0 to 0 -> button updates reactively to Try Tomorrow',
        (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 1),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();

      expect(find.text('Spin The Wheel'), findsOneWidget);
      expect(find.text('Try Tomorrow'), findsNothing);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );

      // Backend updates profile to 0 spins remaining
      controller.updateState(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 0),
        ),
      );
      await tester.pump();

      expect(find.text('Try Tomorrow'), findsOneWidget);
      expect(find.text('Spin The Wheel'), findsNothing);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets(
        '4. Tapping Try Tomorrow navigates to Home via GoRouter',
        (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 0),
        ),
      );

      final router = GoRouter(
        initialLocation: '/spin',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('HOME_SCREEN')),
            ),
          ),
          GoRoute(
            path: '/spin',
            builder: (context, state) => const SpinAndWinView(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith((ref) => controller),
            spinOptionsControllerProvider.overrideWith(
              (ref) => _TestSpinOptionsController(),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, _) => MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Try Tomorrow'), findsOneWidget);

      await tester.tap(find.text('Try Tomorrow'));
      // Advance past the 120 ms scale-restore timer and the route transition
      // (no pumpAndSettle: the wheel sparkles animate forever).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('HOME_SCREEN'), findsOneWidget);
      expect(find.text('Try Tomorrow'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '4. Loading and API error states (profile == null) do not show Try Tomorrow',
        (tester) async {
      // 4a: Loading state with null profile
      final loadingController = _TestProfileController(
        const ProfileState(
          isFetching: true,
          profile: null,
        ),
      );

      await tester.pumpWidget(
        _buildTestApp(profileController: loadingController),
      );
      await tester.pump();

      // When profile is null, hasZeroSpins is false -> must NOT show 'Try Tomorrow'
      expect(find.text('Try Tomorrow'), findsNothing);
      expect(find.text('Spin The Wheel'), findsOneWidget);

      // 4b: Error state with null profile
      final errorController = _TestProfileController(
        const ProfileState(
          isFetching: false,
          errorMessage: 'Server error',
          profile: null,
        ),
      );

      await tester.pumpWidget(
        _buildTestApp(profileController: errorController),
      );
      await tester.pump();

      expect(find.text('Try Tomorrow'), findsNothing);
      expect(find.text('Spin The Wheel'), findsOneWidget);
    });

    testWidgets('5. Try Tomorrow button is enabled but never triggers a spin',
        (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 0),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Try Tomorrow');
      expect(buttonFinder, findsOneWidget);

      // Enabled (tapping navigates home — covered by test 4), but its handler
      // is the navigation callback, so the spin flow can never start here.
      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.enabled, isTrue);
      expect(find.text('Spinning...'), findsNothing);
    });

    testWidgets(
        '6. Responsive layout renders correctly across various screen sizes',
        (tester) async {
      const screenSizes = [
        Size(320, 568), // Small
        Size(360, 690), // Standard
        Size(375, 812), // iPhone X/11/12 mini
        Size(390, 844), // iPhone 12/13/14
        Size(412, 915), // Pixel 7
        Size(440, 956), // Large device
      ];

      for (final size in screenSizes) {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = _TestProfileController(
          ProfileState(
            isFetching: false,
            profile: _makeProfile(spins: 0),
          ),
        );

        await tester.pumpWidget(
          _buildTestApp(profileController: controller, screenSize: size),
        );
        await tester.pump();

        expect(find.text('Try Tomorrow'), findsOneWidget);
        final buttonRender = tester.renderObject(
          find.widgetWithText(ElevatedButton, 'Try Tomorrow'),
        );
        expect(buttonRender, isNotNull);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('Daily Spin Remaining Badge - 1 to 4 Digit Counts', () {
    testWidgets(
        '1. Single and multi-digit counts (9, 19, 199, 1999) render on single line and expand dynamically',
        (tester) async {
      final counts = [9, 19, 199, 1999];
      final widths = <int, double>{};

      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 9),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();

      for (final count in counts) {
        controller.updateState(
          ProfileState(
            isFetching: false,
            profile: _makeProfile(spins: count),
          ),
        );
        await tester.pump();

        // Label and count text must both exist
        expect(find.text('Daily Spin Remaining'), findsOneWidget);
        final countTextFinder = find.text('$count');
        expect(countTextFinder, findsOneWidget);

        // Text properties: single line, no soft wrap
        final textWidget = tester.widget<Text>(countTextFinder);
        expect(textWidget.maxLines, equals(1));
        expect(textWidget.softWrap, isFalse);

        // Badge container expands with digit count
        final badgeContainerFinder = find.ancestor(
          of: countTextFinder,
          matching: find.byType(Container),
        ).first;
        final badgeRender = tester.renderObject(badgeContainerFinder) as RenderBox;
        widths[count] = badgeRender.size.width;

        expect(tester.takeException(), isNull);
      }

      // Verify dynamic expansion: width(9) <= width(19) < width(199) < width(1999)
      expect(widths[9]!, lessThanOrEqualTo(widths[19]!));
      expect(widths[19]!, lessThan(widths[199]!));
      expect(widths[199]!, lessThan(widths[1999]!));
    });

    testWidgets(
        '2. Responsive across widths (320, 360, 375, 390, 412, 440) with 4-digit count without overflow',
        (tester) async {
      const screenSizes = [
        Size(320, 568), // Compact width 320
        Size(360, 690), // Standard 360
        Size(375, 812), // iPhone 375
        Size(390, 844), // iPhone 390
        Size(412, 915), // Pixel 412
        Size(440, 956), // Large 440
      ];

      for (final size in screenSizes) {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = _TestProfileController(
          ProfileState(
            isFetching: false,
            profile: _makeProfile(spins: 1999),
          ),
        );

        await tester.pumpWidget(
          _buildTestApp(profileController: controller, screenSize: size),
        );
        await tester.pump();

        // Label and 4-digit count are rendered
        expect(
          find.text('Daily Spin Remaining'),
          findsOneWidget,
          reason: 'Label missing on width ${size.width}',
        );
        expect(
          find.text('1999'),
          findsOneWidget,
          reason: 'Count 1999 missing on width ${size.width}',
        );

        // Bottom summary text also updates with 1999
        expect(
          find.textContaining('1999 free spins left today'),
          findsOneWidget,
        );

        // No RenderFlex or layout overflow exception
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on size ${size.width}x${size.height}',
        );
      }
    });

    testWidgets('3. Badge updates reactively when backend count changes',
        (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 1),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      // Backend update to 199
      controller.updateState(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 199),
        ),
      );
      await tester.pump();

      expect(find.text('1'), findsNothing);
      expect(find.text('199'), findsOneWidget);

      // Backend update to 1999
      controller.updateState(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 1999),
        ),
      );
      await tester.pump();

      expect(find.text('199'), findsNothing);
      expect(find.text('1999'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });

  group('Spin sound trigger', () {
    late _RecordingSpinAudio audio;

    setUp(() {
      SpinSoundController.reset();
      audio = _RecordingSpinAudio();
      SpinSoundController.playerFactory = () => audio;
    });

    tearDown(() {
      SpinSoundController.reset();
    });

    testWidgets(
        'tapping Spin The Wheel starts the cue exactly once, from the beginning',
        (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 3),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Spin The Wheel'));
      await tester.pump();

      // handleSpin reached the cue call (button flips to "Spinning...") and
      // started the full clip once, with no seek/replay. The stop happens
      // before the play, which is what keeps two cues from overlapping.
      expect(find.text('Spinning...'), findsOneWidget);
      expect(audio.plays, [SpinSoundController.asset]);
      expect(audio.stopCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a single spin does not duplicate the cue across rebuilds',
        (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 3),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Spin The Wheel'));
      // Spin several frames well past the point the cue would have been
      // re-issued; the button is also disabled while spinning.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(audio.plays, hasLength(1));
      expect(find.text('Spinning...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
