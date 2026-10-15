import 'dart:math' as math;

import 'package:e_rupaiya/features/spinandear/components/spin_wheel.dart';
import 'package:e_rupaiya/features/spinandear/models/spin_reward.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reads the slice under the pointer from the rendered wheel: the label whose
/// painted centre is angularly closest to straight up from the wheel centre,
/// where the fixed pin sits. Independent of the angle formulas in
/// `spin_wheel.dart` / `spin_and_win_view.dart`.
const int _n = 8;
const double _slice = 2 * math.pi / _n;

final _rewards = [
  for (var i = 0; i < _n; i++)
    SpinReward(label: 'R$i', type: SpinRewardType.coins, coins: 11 * (i + 1)),
];

String _text(int i) => '${11 * (i + 1)} E-Coins';

/// The selected-reward angle exactly as the view computes it.
double _viewTargetAngle(int index) => (_n - index) * _slice - _slice / 2;

Future<void> _pumpWheel(WidgetTester tester, double rotation) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SpinWheel(rewards: _rewards, rotation: rotation, size: 300),
          ),
        ),
      ),
    ),
  );
}

/// Clockwise angle of each rendered label from the top, in radians [0, 2pi).
List<double> _labelAngles(WidgetTester tester) {
  final centre = tester.getCenter(find.byType(SpinWheel));
  return [
    for (var i = 0; i < _n; i++)
      () {
        final c = tester.getCenter(find.text(_text(i)));
        final a = math.atan2(c.dx - centre.dx, -(c.dy - centre.dy));
        return a % (2 * math.pi);
      }(),
  ];
}

int _renderedSliceUnderPointer(WidgetTester tester) {
  final angles = _labelAngles(tester);
  var best = 0;
  var bestDist = double.infinity;
  for (var i = 0; i < _n; i++) {
    final d = math.min(angles[i], 2 * math.pi - angles[i]);
    if (d < bestDist) {
      bestDist = d;
      best = i;
    }
  }
  return best;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('positive rotation turns the rendered wheel clockwise',
      (tester) async {
    await _pumpWheel(tester, 0);
    final before = _labelAngles(tester);
    await _pumpWheel(tester, 0.1);
    final after = _labelAngles(tester);
    for (var i = 0; i < _n; i++) {
      final delta = (after[i] - before[i]) % (2 * math.pi);
      expect(delta, moreOrLessEquals(0.1, epsilon: 0.02),
          reason: 'label $i moves clockwise by the rotation');
    }
  });

  testWidgets('each selected-reward angle centres that label on the pin',
      (tester) async {
    for (var index = 0; index < _n; index++) {
      await _pumpWheel(tester, _viewTargetAngle(index));
      final angles = _labelAngles(tester);
      final d = math.min(angles[index], 2 * math.pi - angles[index]);
      expect(d, lessThan(0.02), reason: 'reward $index sits under the pin');
      expect(_renderedSliceUnderPointer(tester), index);
    }
  });

  final finals =
      kSpinCueClickMs.sublist(kSpinCueClickMs.length - kSpinFinalClickCount);
  final lastFour = kSpinCueClickMs.sublist(kSpinCueClickMs.length - 4);

  for (var index = 0; index < _n; index++) {
    testWidgets('rendered slice per click, first and second spin -> $index',
        (tester) async {
      // First spin from the wheel's initial 0, second from the resting angle
      // of a first spin to a different reward (as the view does).
      final firstRest = SpinCuePath.plan(
        start: 0,
        targetAngle: _viewTargetAngle((index + 3) % _n),
        sliceCount: _n,
      ).end;
      for (final start in [0.0, firstRest % (2 * math.pi)]) {
        final path = SpinCuePath.plan(
          start: start,
          targetAngle: _viewTargetAngle(index),
          sliceCount: _n,
        );
        Future<int> sliceAt(num ms) async {
          await _pumpWheel(tester, path.rotationAt(ms.toDouble()));
          return _renderedSliceUnderPointer(tester);
        }

        // Wheel begins exactly where it rested.
        expect(path.rotationAt(0), start);

        // Every final click: the slice changes on the click, by one.
        var expected = (index + kSpinFinalClickCount) % _n;
        expect(await sliceAt(finals.first - 2), expected);
        for (final click in finals) {
          expect(await sliceAt(click - 2), expected,
              reason: 'no change before the ${click}ms click');
          expected = (expected - 1) % _n;
          expect(await sliceAt(click + 2), expected,
              reason: 'one slice change on the ${click}ms click');
        }

        // The final four clicks: four changes, counted at 1ms around them.
        var changes = 0;
        var current = await sliceAt(lastFour.first - 2);
        for (var t = lastFour.first - 1; t <= kSpinCueDurationMs; t++) {
          if (t > lastFour.first + 2 &&
              lastFour.every((c) => (t - c).abs() > 2) &&
              t % 20 != 0) {
            continue;
          }
          final s = await sliceAt(t);
          if (s != current) changes++;
          current = s;
        }
        expect(changes, 4, reason: 'four clicks, four slice changes');
        expect(current, index);

        // Rests on the reward's centre, nothing moves after the cue.
        await _pumpWheel(tester, path.rotationAt(kSpinCueDurationMs + 500.0));
        final angles = _labelAngles(tester);
        final d = math.min(angles[index], 2 * math.pi - angles[index]);
        expect(d, lessThan(0.02));
      }
    });
  }
}
