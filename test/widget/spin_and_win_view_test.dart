import 'dart:math' as math;

import 'package:e_rupaiya/features/profile/controllers/profile_controller.dart';
import 'package:e_rupaiya/features/profile/models/profile_model.dart';
import 'package:e_rupaiya/features/profile/models/profile_state.dart';
import 'package:e_rupaiya/features/profile/repositories/profile_repository.dart';
import 'package:e_rupaiya/features/spinandear/components/spin_result_popup.dart';
import 'package:e_rupaiya/features/spinandear/components/spin_wheel.dart';
import 'package:e_rupaiya/features/spinandear/controllers/spin_options_controller.dart';
import 'package:e_rupaiya/features/spinandear/helpers/spin_sound_controller.dart';
import 'package:e_rupaiya/features/spinandear/models/spin_options_state.dart';
import 'package:e_rupaiya/features/spinandear/repositories/spin_repository.dart';
import 'package:e_rupaiya/features/spinandear/views/spin_and_win_view.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
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
  Future<Map<String, List<int>>> fetchSpinOptions() async => const {};

  @override
  Future<void> recordSpin({required String spinType}) async {}
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
  final List<String> preloads = [];
  int stopCount = 0;

  /// Spin cue playhead reports, served in order (the last one repeats).
  /// Empty: position unknown, as on a platform without position support.
  List<Duration> playheads = [];
  int positionQueries = 0;

  @override
  Future<Duration?> position(String asset) async {
    if (playheads.isEmpty) return null;
    final i = math.min(positionQueries++, playheads.length - 1);
    return playheads[i];
  }

  @override
  Future<void> disableLooping() async {}

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> play(String asset) async => plays.add(asset);

  @override
  Future<void> preload(String asset) async => preloads.add(asset);

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
      // Inject the fake so handleSpin's recordSpin() completes without a real
      // network call, allowing the popup display (and popup sound) to be reached.
      spinRepositoryProvider.overrideWithValue(_FakeSpinRepository()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(
        // Wire navigatorKey so KDialog.openDialog() can find a context.
        navigatorKey: navigatorKey,
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
    testWidgets(
        '1. Backend returns 0 spins -> Try Tomorrow is displayed and enabled',
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

    testWidgets('4. Tapping Try Tomorrow navigates to Home via GoRouter',
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
        final badgeContainerFinder = find
            .ancestor(
              of: countTextFinder,
              matching: find.byType(Container),
            )
            .first;
        final badgeRender =
            tester.renderObject(badgeContainerFinder) as RenderBox;
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
      expect(audio.plays, [SpinSoundController.spinAsset]);
      expect(audio.stopCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a single spin does not duplicate the cue across rebuilds',
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

    testWidgets(
        'popup cue fires exactly once at the moment the result popup becomes '
        'visible - not before, not on subsequent rebuilds', (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 3),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();

      // No popup cue before the spin completes.
      expect(
        audio.plays.where((p) => p == SpinSoundController.popupAsset),
        isEmpty,
        reason: 'popup cue must not fire before the result popup is shown',
      );

      // Tap to spin, then advance clock far enough for the full wheel animation
      // (kSpinWheelDuration = 5100ms) and all post-animation async work to
      // drain (recordSpin, fetchProfile). The extra 1s covers the latter.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Spin The Wheel'));
      await tester.pump();
      await tester.pump(kSpinWheelDuration + const Duration(seconds: 1));
      // Drain any remaining microtasks that may still be in the queue.
      await tester.pump();

      // The popup cue is the last play call and was issued exactly once.
      final popupPlays = audio.plays
          .where((p) => p == SpinSoundController.popupAsset)
          .toList();
      expect(
        popupPlays,
        hasLength(1),
        reason: 'spinandwinpopup.mp3 must play exactly once per spin result',
      );
      expect(
        audio.plays.last,
        SpinSoundController.popupAsset,
        reason: 'popup cue must be the last play event, not an earlier one',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'popup cue does not fire a second time on subsequent frame pumps',
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
      await tester.pump(kSpinWheelDuration + const Duration(seconds: 1));
      await tester.pump();

      final countAfterFirstPump =
          audio.plays.where((p) => p == SpinSoundController.popupAsset).length;

      // Additional frames must not re-trigger the popup cue.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      final countAfterMorePumps =
          audio.plays.where((p) => p == SpinSoundController.popupAsset).length;

      expect(
        countAfterMorePumps,
        equals(countAfterFirstPump),
        reason: 'popup cue must not replay on subsequent rebuilds',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'the last click (4922ms) brings in the reward slice, the wheel settles '
        'on its centre as the cue ends (5100ms), and the popup and its cue '
        'arrive together on the frame it stops', (tester) async {
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
      expect(audio.plays, [SpinSoundController.spinAsset]);
      // The cue has started; the wheel starts turning on this frame. Neither
      // pump advances the clock, so cue times are measured from here.
      await tester.pump();

      int sliceUnderPointer() {
        final wheel = tester.widget<SpinWheel>(find.byType(SpinWheel));
        final slice = 2 * math.pi / wheel.rewards.length;
        return ((-wheel.rotation) % (2 * math.pi) / slice).floor() %
            wheel.rewards.length;
      }

      await tester.pump(
        const Duration(milliseconds: kSpinCueLastClickMs - 1),
      );
      final beforeLastClick = sliceUnderPointer();
      await tester.pump(const Duration(milliseconds: 2));
      final afterLastClick = sliceUnderPointer();
      expect(afterLastClick, isNot(beforeLastClick),
          reason: 'the last click brings a new slice to the pointer');

      await tester.pump(
        kSpinWheelDuration -
            const Duration(milliseconds: kSpinCueLastClickMs + 2),
      );
      expect(find.text('Spinning...'), findsOneWidget,
          reason: 'the wheel must still be settling 1ms before 5100ms');
      expect(sliceUnderPointer(), afterLastClick,
          reason: 'no further slice change after the last click');
      expect(audio.plays, [SpinSoundController.spinAsset]);
      expect(find.byType(SpinResultPopup), findsNothing);

      // The wheel completes on the first frame at or after 5100ms.
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump();
      expect(audio.plays, [
        SpinSoundController.spinAsset,
        SpinSoundController.popupAsset,
      ]);
      expect(find.byType(SpinResultPopup), findsOneWidget);

      // The resting angle points the top pin at the reward the popup shows.
      final wheel = tester.widget<SpinWheel>(find.byType(SpinWheel));
      final slice = 2 * math.pi / wheel.rewards.length;
      final rest = wheel.rotation % (2 * math.pi);
      final landed =
          (wheel.rewards.length - (rest + slice / 2) / slice).round() %
              wheel.rewards.length;
      final shown =
          tester.widget<SpinResultPopup>(find.byType(SpinResultPopup)).reward;
      expect(wheel.rewards[landed].label, shown.label);
      expect(wheel.rewards[landed].type, shown.type);
      expect(sliceUnderPointer(), landed);
      expect(sliceUnderPointer(), afterLastClick);
      final offCentre = (rest + slice / 2) % slice;
      expect(math.min(offCentre, slice - offCentre), lessThan(1e-9),
          reason: 'rests on the reward slice centre');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a late audio start shifts the wheel onto the cue: it waits for the '
        'playhead, starts at it and changes slice on the last click',
        (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 3),
        ),
      );
      // Silent for the first ten polls, then already 300ms into the cue.
      const lateBy = 300;
      audio.playheads = [
        for (var i = 0; i < 10; i++) Duration.zero,
        const Duration(milliseconds: lateBy),
      ];

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();

      double rotation() =>
          tester.widget<SpinWheel>(find.byType(SpinWheel)).rotation;
      int sliceUnderPointer() {
        final wheel = tester.widget<SpinWheel>(find.byType(SpinWheel));
        final slice = 2 * math.pi / wheel.rewards.length;
        return ((-wheel.rotation) % (2 * math.pi) / slice).floor() %
            wheel.rewards.length;
      }

      final rest = rotation();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Spin The Wheel'));
      await tester.pump();
      expect(audio.plays, [SpinSoundController.spinAsset]);

      // While the cue is silent the wheel must not move.
      await tester.pump(const Duration(milliseconds: 40));
      expect(rotation(), rest, reason: 'no wheel movement before the sound');
      expect(audio.positionQueries, lessThan(10));

      // Step until the playhead is reported and the wheel starts on it.
      var waited = 0;
      while (audio.positionQueries < 11 && waited < 500) {
        await tester.pump(const Duration(milliseconds: 1));
        waited++;
      }
      await tester.pump();
      expect(audio.positionQueries, 11);
      // From here wheel time == cue time - lateBy.

      await tester.pump(
        const Duration(milliseconds: kSpinCueLastClickMs - lateBy - 2),
      );
      final beforeLastClick = sliceUnderPointer();
      await tester.pump(const Duration(milliseconds: 4));
      final afterLastClick = sliceUnderPointer();
      expect(afterLastClick, isNot(beforeLastClick),
          reason: 'the slice changes on the last click in cue time');

      await tester.pump(
        const Duration(
          milliseconds: kSpinCueDurationMs - kSpinCueLastClickMs - 2 - 2,
        ),
      );
      expect(find.byType(SpinResultPopup), findsNothing,
          reason: 'no popup before the cue-time stop');
      expect(sliceUnderPointer(), afterLastClick,
          reason: 'no further slice change after the last click');

      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();
      expect(find.byType(SpinResultPopup), findsOneWidget,
          reason: 'the wheel stops at cue time 5100ms, '
              '${kSpinCueDurationMs - lateBy}ms after it started');
      final shown =
          tester.widget<SpinResultPopup>(find.byType(SpinResultPopup)).reward;
      final wheel = tester.widget<SpinWheel>(find.byType(SpinWheel));
      expect(wheel.rewards[sliceUnderPointer()].label, shown.label);
      expect(tester.takeException(), isNull);
    });

    testWidgets('repeated taps start one cue and one spin', (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 3),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();

      final button = find.byType(ElevatedButton).first;
      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      await tester.tap(button, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.tap(button, warnIfMissed: false);
      await tester.pump(kSpinWheelDuration + const Duration(seconds: 1));
      await tester.pump();

      expect(
        audio.plays.where((p) => p == SpinSoundController.spinAsset),
        hasLength(1),
      );
      expect(
        audio.plays.where((p) => p == SpinSoundController.popupAsset),
        hasLength(1),
      );
      expect(find.byType(SpinResultPopup), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('both cues are preloaded on screen mount', (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 3),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      await tester.pump();
      await tester.pump();

      expect(audio.preloads, [
        SpinSoundController.spinAsset,
        SpinSoundController.popupAsset,
      ]);
      expect(audio.plays, isEmpty);
    });

    testWidgets('popup asset is preloaded on screen mount before any spin tap',
        (tester) async {
      final controller = _TestProfileController(
        ProfileState(
          isFetching: false,
          profile: _makeProfile(spins: 3),
        ),
      );

      await tester.pumpWidget(_buildTestApp(profileController: controller));
      // Allow the microtask that calls preloadPopup() to run.
      await tester.pump();
      await tester.pump();

      // The preload call must have been issued (best-effort) by the time the
      // user would interact. No play must have occurred yet.
      expect(
        audio.preloads.contains(SpinSoundController.popupAsset),
        isTrue,
        reason: 'spinandwinpopup.mp3 must be preloaded on screen mount',
      );
      expect(
        audio.plays,
        isEmpty,
        reason: 'preloading must not start audio playback',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
