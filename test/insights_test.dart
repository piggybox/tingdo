import 'package:flutter_test/flutter_test.dart';
import 'package:tingdo/logic/insights.dart';
import 'package:tingdo/models/day_entry.dart';
import 'package:tingdo/models/habit.dart';
import 'package:tingdo/util/dates.dart';

final today = DateTime(2026, 8, 13); // a Thursday

Habit habitStartedDaysAgo(int days) => Habit(
      id: 'h',
      name: 'Write',
      identity: 'someone who writes',
      anchor: 'After I pour my coffee',
      fullLabel: 'Full session',
      fullDetail: '500 words',
      floorLabel: 'Just the floor',
      floorDetail: '3 sentences',
      createdAt: today.subtract(Duration(days: days)),
    );

void fill(Habit habit, int days, {Set<int> skipWeekdays = const {}}) {
  for (var d = 1; d <= days; d++) {
    final date = today.subtract(Duration(days: d));
    if (skipWeekdays.contains(date.weekday)) continue;
    habit.entries[dateKey(date)] = DayEntry(date: date, kind: DayKind.full);
  }
}

void main() {
  group('weekdayInsight', () {
    test('stays quiet until there is enough history to mean anything', () {
      final habit = habitStartedDaysAgo(10);
      fill(habit, 10, skipWeekdays: {DateTime.thursday});
      expect(weekdayInsight(habit, now: today), isNull);
    });

    test('stays quiet when misses are scattered', () {
      final habit = habitStartedDaysAgo(56);
      fill(habit, 56);
      for (final d in [2, 9, 17, 26, 40]) {
        habit.entries.remove(dateKey(today.subtract(Duration(days: d))));
      }
      expect(weekdayInsight(habit, now: today), isNull);
    });

    test('names the weekday when one clearly dominates', () {
      final habit = habitStartedDaysAgo(56);
      fill(habit, 56, skipWeekdays: {DateTime.thursday});
      final insight = weekdayInsight(habit, now: today);
      expect(insight, isNotNull);
      expect(insight!.message, contains('Thursdays'));
      expect(insight.weekday, DateTime.thursday);
      expect(insight.action, 'Drop Thursdays');
    });

    test('ignores weekdays already turned off', () {
      final habit = habitStartedDaysAgo(56)
        ..activeWeekdays = {1, 2, 3, 5, 6, 7};
      fill(habit, 56, skipWeekdays: {DateTime.thursday});
      expect(weekdayInsight(habit, now: today), isNull);
    });
  });

  group('reasonInsight', () {
    void tag(Habit habit, int daysAgo, MissReason reason) {
      final date = today.subtract(Duration(days: daysAgo));
      habit.entries[dateKey(date)] =
          DayEntry(date: date, kind: DayKind.missed, reason: reason);
    }

    test('needs a few reasons before it says anything', () {
      final habit = habitStartedDaysAgo(56);
      tag(habit, 2, MissReason.noTime);
      tag(habit, 5, MissReason.noTime);
      expect(reasonInsight(habit, now: today), isNull);
    });

    test('suggests shrinking the floor when time is the blocker', () {
      final habit = habitStartedDaysAgo(56);
      for (final d in [2, 5, 9, 14]) {
        tag(habit, d, MissReason.noTime);
      }
      expect(reasonInsight(habit, now: today)!.message, contains('shrink it'));
    });

    test('stays quiet when no single reason dominates', () {
      final habit = habitStartedDaysAgo(56);
      tag(habit, 2, MissReason.noTime);
      tag(habit, 5, MissReason.tired);
      tag(habit, 9, MissReason.forgot);
      tag(habit, 14, MissReason.away);
      expect(reasonInsight(habit, now: today), isNull);
    });
  });
}
