import 'package:flutter_test/flutter_test.dart';

import 'package:interval_timer/ui/timer_screen.dart';

void main() {
  test('TimerPhase has all expected states', () {
    expect(TimerPhase.values, containsAll([
      TimerPhase.countdown,
      TimerPhase.work,
      TimerPhase.rest,
      TimerPhase.done,
    ]));
  });
}
