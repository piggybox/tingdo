import 'package:flutter_test/flutter_test.dart';
import 'package:tingdo/logic/stats.dart';
import 'package:tingdo/models/day_entry.dart';
import 'package:tingdo/models/habit.dart';
import 'package:tingdo/util/dates.dart';

final today = DateTime(2026, 8, 13); // a Thursday

Habit makeHabit({
  int startedDaysAgo = 60,
  Set<int>? weekdays,
  Map<int, DayKind> log = const {},
}) {
  final habit = Habit(
    id: 'h',
    name: 'Write',
    identity: 'someone who writes',
    anchor: 'After I pour my coffee',
    fullLabel: 'Full session',
    fullDetail: '500 words',
    floorLabel: 'Just the floor',
    floorDetail: '3 sentences',
    createdAt: today.subtract(Duration(days: startedDaysAgo)),
    activeWeekdays: weekdays,
  );
  log.forEach((daysAgo, kind) {
    final date = today.subtract(Duration(days: daysAgo));
    habit.entries[dateKey(date)] = DayEntry(date: date, kind: kind);
  });
  return habit;
}

void main() {
  group('consistency', () {
    test('is null before there is anything to judge', () {
      final habit = makeHabit(startedDaysAgo: 0);
      expect(HabitStats.of(habit, now: today).consistency, isNull);
    });

    test('counts the floor exactly like the full version', () {
      final full = makeHabit(
        startedDaysAgo: 3,
        log: {1: DayKind.full, 2: DayKind.full, 3: DayKind.full},
      );
      final floor = makeHabit(
        startedDaysAgo: 3,
        log: {1: DayKind.floor, 2: DayKind.floor, 3: DayKind.floor},
      );
      expect(HabitStats.of(full, now: today).consistency, 1.0);
      expect(HabitStats.of(floor, now: today).consistency, 1.0);
    });

    test('a single miss nudges the number instead of collapsing it', () {
      final log = {for (var d = 1; d <= 30; d++) d: DayKind.full}..remove(3);
      final habit = makeHabit(log: log);
      final stats = HabitStats.of(habit, now: today);
      // 29 of 30 past days, today still open and therefore not counted.
      expect(stats.consideredDays, 29);
      expect(stats.consistencyPercent, 97);
    });

    test('today does not count against you until it is over', () {
      final habit = makeHabit(
        startedDaysAgo: 1,
        log: {1: DayKind.full},
      );
      final stats = HabitStats.of(habit, now: today);
      expect(stats.consideredDays, 1);
      expect(stats.consistency, 1.0);
    });

    test('rest days are neutral in both terms of the fraction', () {
      final withRest = makeHabit(
        startedDaysAgo: 3,
        log: {1: DayKind.full, 2: DayKind.rest, 3: DayKind.full},
      );
      final stats = HabitStats.of(withRest, now: today);
      expect(stats.consideredDays, 2);
      expect(stats.consistency, 1.0);
      expect(stats.restsSpent, 1);
      expect(stats.restsRemaining, restAllowancePerWindow - 1);
    });

    test('days you turned off are not misses', () {
      // Weekdays only; the weekend gaps must not be held against the habit.
      final habit = makeHabit(startedDaysAgo: 13, weekdays: {1, 2, 3, 4, 5});
      for (var d = 1; d <= 13; d++) {
        final date = today.subtract(Duration(days: d));
        if (date.weekday >= 6) continue;
        habit.entries[dateKey(date)] = DayEntry(date: date, kind: DayKind.full);
      }
      expect(HabitStats.of(habit, now: today).consistency, 1.0);
    });

    test('days before the habit existed are not misses', () {
      final habit = makeHabit(
        startedDaysAgo: 2,
        log: {1: DayKind.full, 2: DayKind.full},
      );
      expect(HabitStats.of(habit, now: today).consideredDays, 2);
    });
  });

  test('votes count every time you showed up, either way', () {
    final habit = makeHabit(
      log: {1: DayKind.full, 2: DayKind.floor, 3: DayKind.rest, 4: DayKind.missed},
    );
    expect(HabitStats.of(habit, now: today).votes, 2);
  });

  test('the ribbon has one square per day in the window', () {
    final stats = HabitStats.of(makeHabit(), now: today);
    expect(stats.ribbon.length, consistencyWindowDays);
    expect(stats.ribbon.last.isToday, isTrue);
    expect(stats.ribbon.first.date, today.subtract(const Duration(days: 29)));
  });

  group('the one-habit-at-a-time gate', () {
    test('stays shut while the habit is still new, however perfect', () {
      final log = {for (var d = 1; d <= 5; d++) d: DayKind.full};
      final stats = HabitStats.of(makeHabit(startedDaysAgo: 5, log: log), now: today);
      expect(stats.consistency, 1.0);
      expect(stats.clearsUnlockBar, isFalse);
    });

    test('stays shut when an old habit is not holding', () {
      final log = {for (var d = 1; d <= 30; d += 3) d: DayKind.full};
      final stats = HabitStats.of(makeHabit(log: log), now: today);
      expect(stats.clearsUnlockBar, isFalse);
    });

    test('opens once the habit is old enough and holding', () {
      final log = {for (var d = 1; d <= 30; d++) d: DayKind.full};
      final stats = HabitStats.of(makeHabit(log: log), now: today);
      expect(stats.clearsUnlockBar, isTrue);
    });
  });

  group('graduation', () {
    test('is offered after 90 solid days', () {
      final log = {for (var d = 1; d <= 30; d++) d: DayKind.full};
      final stats =
          HabitStats.of(makeHabit(startedDaysAgo: 95, log: log), now: today);
      expect(stats.readyToGraduate, isTrue);
      expect(stats.nudgeLevel, NudgeLevel.quiet);
    });

    test('is not offered to a shaky habit', () {
      final log = {for (var d = 1; d <= 30; d += 2) d: DayKind.full};
      final stats =
          HabitStats.of(makeHabit(startedDaysAgo: 95, log: log), now: today);
      expect(stats.readyToGraduate, isFalse);
    });

    test('is not asked again the day after it is waved off', () {
      final log = {for (var d = 1; d <= 30; d++) d: DayKind.full};
      final habit = makeHabit(startedDaysAgo: 95, log: log)
        ..graduationSnoozedAt = today.subtract(const Duration(days: 1));
      expect(HabitStats.of(habit, now: today).readyToGraduate, isFalse);
    });

    test('comes back a month after being waved off', () {
      final log = {for (var d = 1; d <= 30; d++) d: DayKind.full};
      final habit = makeHabit(startedDaysAgo: 95, log: log)
        ..graduationSnoozedAt = today.subtract(const Duration(days: 31));
      expect(HabitStats.of(habit, now: today).readyToGraduate, isTrue);
    });

    test('silences the app once taken', () {
      final habit = makeHabit(startedDaysAgo: 95)..graduated = true;
      expect(HabitStats.of(habit, now: today).nudgeLevel, NudgeLevel.silent);
    });
  });

  group('nudges get quieter as consistency rises', () {
    test('loud for a brand new habit', () {
      expect(
        HabitStats.of(makeHabit(startedDaysAgo: 2), now: today).nudgeLevel,
        NudgeLevel.loud,
      );
    });

    test('normal in the middle', () {
      final log = {for (var d = 1; d <= 30; d++) d: DayKind.full}
        ..removeWhere((d, _) => d % 4 == 0);
      expect(
        HabitStats.of(makeHabit(log: log), now: today).nudgeLevel,
        NudgeLevel.normal,
      );
    });
  });
}
