import 'ui/timer_screen.dart';

/// Pure timer state machine — no Flutter dependencies, fully testable.
class TimerLogic {
  final int onSeconds;
  final int offSeconds;
  final int totalRounds;

  TimerPhase phase = TimerPhase.countdown;
  int secondsLeft = 10;
  int currentRound = 1;
  bool paused = false;

  TimerLogic({
    required this.onSeconds,
    required this.offSeconds,
    required this.totalRounds,
  });

  /// Tick one second. Returns the phase that was just entered (if a transition
  /// happened), or null if no transition occurred.
  TimerPhase? tick() {
    if (paused || phase == TimerPhase.done) return null;

    if (secondsLeft > 1) {
      secondsLeft--;
      return null;
    }

    // secondsLeft == 1 → advance
    return advance();
  }

  /// Force advance to the next phase. Returns the new phase.
  TimerPhase advance() {
    switch (phase) {
      case TimerPhase.countdown:
        phase = TimerPhase.work;
        secondsLeft = onSeconds;
        return TimerPhase.work;

      case TimerPhase.work:
        if (currentRound >= totalRounds) {
          phase = TimerPhase.done;
          secondsLeft = 0;
          return TimerPhase.done;
        }
        phase = TimerPhase.rest;
        secondsLeft = offSeconds;
        return TimerPhase.rest;

      case TimerPhase.rest:
        currentRound++;
        phase = TimerPhase.work;
        secondsLeft = onSeconds;
        return TimerPhase.work;

      case TimerPhase.done:
        return TimerPhase.done;
    }
  }

  bool get isLastThreeSeconds => secondsLeft <= 3 && phase != TimerPhase.done;

  /// Total elapsed work time so far (completed rounds only).
  int get completedWorkSeconds => (currentRound - 1) * onSeconds;
}
