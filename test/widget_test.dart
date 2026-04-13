import 'package:flutter_test/flutter_test.dart';

import 'package:interval_timer/timer_logic.dart';
import 'package:interval_timer/ui/timer_screen.dart';

void main() {
  group('TimerPhase', () {
    test('has all expected states', () {
      expect(TimerPhase.values, [
        TimerPhase.countdown,
        TimerPhase.work,
        TimerPhase.rest,
        TimerPhase.done,
      ]);
    });
  });

  group('TimerLogic initial state', () {
    test('starts in countdown phase with 10 seconds', () {
      final logic = TimerLogic(onSeconds: 30, offSeconds: 15, totalRounds: 5);
      expect(logic.phase, TimerPhase.countdown);
      expect(logic.secondsLeft, 10);
      expect(logic.currentRound, 1);
      expect(logic.paused, false);
    });
  });

  group('TimerLogic countdown', () {
    test('counts down from 10 to 1 then transitions to work', () {
      final logic = TimerLogic(onSeconds: 30, offSeconds: 15, totalRounds: 5);

      // Tick 9 times — stays in countdown
      for (int i = 0; i < 9; i++) {
        final transition = logic.tick();
        expect(transition, isNull);
        expect(logic.phase, TimerPhase.countdown);
      }
      expect(logic.secondsLeft, 1);

      // 10th tick transitions to work
      final transition = logic.tick();
      expect(transition, TimerPhase.work);
      expect(logic.phase, TimerPhase.work);
      expect(logic.secondsLeft, 30);
      expect(logic.currentRound, 1);
    });
  });

  group('TimerLogic work phase', () {
    late TimerLogic logic;

    setUp(() {
      logic = TimerLogic(onSeconds: 5, offSeconds: 3, totalRounds: 2);
      // Skip countdown
      for (int i = 0; i < 10; i++) {
        logic.tick();
      }
      expect(logic.phase, TimerPhase.work);
    });

    test('counts down work interval then transitions to rest', () {
      // Tick 4 times (5 -> 4 -> 3 -> 2 -> still in work)
      for (int i = 0; i < 4; i++) {
        final t = logic.tick();
        expect(t, isNull);
      }
      expect(logic.secondsLeft, 1);

      // 5th tick transitions to rest (round 1 not last)
      final transition = logic.tick();
      expect(transition, TimerPhase.rest);
      expect(logic.phase, TimerPhase.rest);
      expect(logic.secondsLeft, 3);
      expect(logic.currentRound, 1);
    });
  });

  group('TimerLogic rest phase', () {
    late TimerLogic logic;

    setUp(() {
      logic = TimerLogic(onSeconds: 3, offSeconds: 2, totalRounds: 3);
      // Skip countdown (10 ticks)
      for (int i = 0; i < 10; i++) {
        logic.tick();
      }
      // Skip work (3 ticks)
      for (int i = 0; i < 3; i++) {
        logic.tick();
      }
      expect(logic.phase, TimerPhase.rest);
    });

    test('counts down rest interval then transitions to work with round++', () {
      expect(logic.currentRound, 1);

      // Tick through rest (2 seconds)
      logic.tick(); // 2 -> 1
      final transition = logic.tick(); // advance
      expect(transition, TimerPhase.work);
      expect(logic.phase, TimerPhase.work);
      expect(logic.currentRound, 2);
      expect(logic.secondsLeft, 3);
    });
  });

  group('TimerLogic completes on last round', () {
    test('transitions to done after last work phase', () {
      final logic = TimerLogic(onSeconds: 2, offSeconds: 2, totalRounds: 2);

      // Countdown: 10 ticks
      for (int i = 0; i < 10; i++) {
        logic.tick();
      }
      expect(logic.phase, TimerPhase.work);

      // Round 1 work: 2 ticks
      for (int i = 0; i < 2; i++) {
        logic.tick();
      }
      expect(logic.phase, TimerPhase.rest);

      // Round 1 rest: 2 ticks
      for (int i = 0; i < 2; i++) {
        logic.tick();
      }
      expect(logic.phase, TimerPhase.work);
      expect(logic.currentRound, 2);

      // Round 2 work: 2 ticks -> done (last round)
      logic.tick(); // 2 -> 1
      final transition = logic.tick();
      expect(transition, TimerPhase.done);
      expect(logic.phase, TimerPhase.done);
      expect(logic.secondsLeft, 0);
    });

    test('single round goes work then done (no rest)', () {
      final logic = TimerLogic(onSeconds: 2, offSeconds: 2, totalRounds: 1);

      // Countdown
      for (int i = 0; i < 10; i++) {
        logic.tick();
      }
      expect(logic.phase, TimerPhase.work);

      // Work phase completes — last round, so straight to done
      logic.tick();
      final transition = logic.tick();
      expect(transition, TimerPhase.done);
      expect(logic.phase, TimerPhase.done);
    });
  });

  group('TimerLogic pause', () {
    test('tick does nothing when paused', () {
      final logic = TimerLogic(onSeconds: 30, offSeconds: 15, totalRounds: 5);
      logic.paused = true;

      final before = logic.secondsLeft;
      final transition = logic.tick();
      expect(transition, isNull);
      expect(logic.secondsLeft, before);
    });

    test('tick does nothing when done', () {
      final logic = TimerLogic(onSeconds: 2, offSeconds: 2, totalRounds: 1);
      // Run to completion
      for (int i = 0; i < 10 + 2; i++) {
        logic.tick();
      }
      expect(logic.phase, TimerPhase.done);

      final transition = logic.tick();
      expect(transition, isNull);
    });
  });

  group('TimerLogic isLastThreeSeconds', () {
    test('true when 3 or fewer seconds remain in active phase', () {
      final logic = TimerLogic(onSeconds: 5, offSeconds: 5, totalRounds: 5);
      expect(logic.secondsLeft, 10);
      expect(logic.isLastThreeSeconds, false);

      // Tick down to 3
      for (int i = 0; i < 7; i++) {
        logic.tick();
      }
      expect(logic.secondsLeft, 3);
      expect(logic.isLastThreeSeconds, true);
    });

    test('false when in done phase even with low seconds', () {
      final logic = TimerLogic(onSeconds: 1, offSeconds: 1, totalRounds: 1);
      // Run to done
      for (int i = 0; i < 10 + 1; i++) {
        logic.tick();
      }
      expect(logic.phase, TimerPhase.done);
      expect(logic.isLastThreeSeconds, false);
    });
  });

  group('TimerLogic full workout simulation', () {
    test('3 rounds of 3s on / 2s off completes in expected ticks', () {
      final logic = TimerLogic(onSeconds: 3, offSeconds: 2, totalRounds: 3);

      int ticks = 0;
      while (logic.phase != TimerPhase.done) {
        logic.tick();
        ticks++;
        // Safety: prevent infinite loop in case of bug
        if (ticks > 100) fail('Timer did not complete');
      }

      // Expected: 10 (countdown) + 3 (work1) + 2 (rest1) + 3 (work2) + 2 (rest2) + 3 (work3) = 23
      expect(ticks, 23);
      expect(logic.currentRound, 3);
    });

    test('round counter is correct throughout', () {
      final logic = TimerLogic(onSeconds: 2, offSeconds: 1, totalRounds: 3);
      final roundHistory = <int>[];

      while (logic.phase != TimerPhase.done) {
        logic.tick();
        if (logic.phase == TimerPhase.work || logic.phase == TimerPhase.rest) {
          roundHistory.add(logic.currentRound);
        }
      }

      // Round 1: work(2 ticks at round=1) then rest transition advances
      // to rest at round=1, but rest->work tick bumps round to 2, etc.
      // work1(1,1) rest1(1) work2(2,2) rest2(2) work3(3,3)
      expect(roundHistory, [1, 1, 1, 2, 2, 2, 3, 3]);
    });
  });

  group('TimerLogic advance() direct calls', () {
    test('advance from countdown goes to work', () {
      final logic = TimerLogic(onSeconds: 30, offSeconds: 15, totalRounds: 5);
      final result = logic.advance();
      expect(result, TimerPhase.work);
      expect(logic.secondsLeft, 30);
    });

    test('advance from done stays done', () {
      final logic = TimerLogic(onSeconds: 1, offSeconds: 1, totalRounds: 1);
      logic.phase = TimerPhase.done;
      logic.secondsLeft = 0;
      final result = logic.advance();
      expect(result, TimerPhase.done);
    });
  });

  group('Setup screen format helpers', () {
    // These replicate the format logic from the setup screen
    String formatInterval(int seconds) {
      if (seconds < 60) return '${seconds}s';
      final min = seconds ~/ 60;
      final sec = seconds % 60;
      return sec == 0 ? '${min}m' : '${min}m${sec}s';
    }

    String formatTotal(int onSeconds, int offSeconds, int rounds) {
      final totalSeconds = (onSeconds + offSeconds) * rounds;
      final min = totalSeconds ~/ 60;
      final sec = totalSeconds % 60;
      if (sec == 0) return '${min}m';
      return '${min}m ${sec}s';
    }

    test('formatInterval handles seconds under 60', () {
      expect(formatInterval(15), '15s');
      expect(formatInterval(30), '30s');
      expect(formatInterval(45), '45s');
    });

    test('formatInterval handles 60 and above', () {
      expect(formatInterval(60), '1m');
      expect(formatInterval(90), '1m30s');
      expect(formatInterval(120), '2m');
    });

    test('formatTotal calculates correct total workout time', () {
      expect(formatTotal(30, 15, 10), '7m 30s');
      expect(formatTotal(60, 30, 5), '7m 30s');
      expect(formatTotal(30, 30, 10), '10m');
      expect(formatTotal(15, 15, 20), '10m');
    });
  });
}
