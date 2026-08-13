import '../models/day_entry.dart';
import '../models/habit.dart';
import '../util/dates.dart';

/// Data as a diagnostic, never a scolding. Insights only appear once there is
/// enough history for the pattern to be real, and every one of them ends in a
/// concrete adjustment the person can make.
class Insight {
  const Insight({required this.message, this.action, this.weekday});

  final String message;

  /// Label for the one adjustment offered, if any.
  final String? action;

  /// Set when the action is "drop this weekday".
  final int? weekday;
}

const _lookbackDays = 56;
const _minAgeForInsights = 21;

List<DateTime> _missedDates(Habit habit, DateTime today) {
  final missed = <DateTime>[];
  for (final date in daysEndingOn(today, _lookbackDays)) {
    if (!date.isBefore(today)) continue; // today is still open
    if (date.isBefore(habit.createdAt)) continue;
    if (!habit.activeWeekdays.contains(date.weekday)) continue;
    final entry = habit.entryOn(date);
    if (entry == null || entry.kind == DayKind.missed) missed.add(date);
  }
  return missed;
}

/// "You miss Thursdays." Fires only when one weekday genuinely dominates.
Insight? weekdayInsight(Habit habit, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  if (daysBetween(habit.createdAt, today) < _minAgeForInsights) return null;

  final missed = _missedDates(habit, today);
  if (missed.length < 4) return null;

  final counts = <int, int>{};
  for (final d in missed) {
    counts[d.weekday] = (counts[d.weekday] ?? 0) + 1;
  }
  if (habit.activeWeekdays.length < 2) return null;

  final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  if (top.value < 3) return null;
  if (top.value / missed.length < 0.4) return null;

  final day = weekdayName(top.key);
  return Insight(
    message: 'You miss ${day}s — ${top.value} of your last '
        '${missed.length} misses. Move the anchor, or take ${day}s off.',
    action: 'Drop ${day}s',
    weekday: top.key,
  );
}

/// "Most misses: no time." Turns the four one-word reasons into one suggestion.
Insight? reasonInsight(Habit habit, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final reasons = <MissReason, int>{};
  for (final date in daysEndingOn(today, _lookbackDays)) {
    final entry = habit.entryOn(date);
    final reason = entry?.reason;
    if (reason == null) continue;
    reasons[reason] = (reasons[reason] ?? 0) + 1;
  }
  final total = reasons.values.fold(0, (a, b) => a + b);
  if (total < 3) return null;

  final top = reasons.entries.reduce((a, b) => a.value >= b.value ? a : b);
  if (top.value / total < 0.5) return null;

  final message = switch (top.key) {
    MissReason.noTime =>
      'No time, mostly. That usually means the floor is still too big — '
          'shrink it until it fits a bad day.',
    MissReason.tired =>
      'Tired, mostly. Try anchoring it earlier, before the day spends you.',
    MissReason.forgot =>
      'Forgot, mostly. The anchor is not reliable enough — pick a moment that '
          'always happens.',
    MissReason.away =>
      'Away, mostly. Give the habit a version that travels.',
  };
  return Insight(message: message);
}

List<Insight> insightsFor(Habit habit, {DateTime? now}) => [
      weekdayInsight(habit, now: now),
      reasonInsight(habit, now: now),
    ].whereType<Insight>().toList();
