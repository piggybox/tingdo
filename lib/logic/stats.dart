import '../models/day_entry.dart';
import '../models/habit.dart';
import '../util/dates.dart';

/// How loudly the app should talk to you. It gets quieter as consistency
/// rises, and goes silent once a habit graduates — an app that still needs you
/// daily after six months has failed.
enum NudgeLevel { loud, normal, quiet, silent }

extension NudgeLevelLabel on NudgeLevel {
  String get label => switch (this) {
        NudgeLevel.loud => 'Every day',
        NudgeLevel.normal => 'Most days',
        NudgeLevel.quiet => 'Rarely',
        NudgeLevel.silent => 'Never',
      };
}

/// One square in the consistency ribbon.
class DayCell {
  const DayCell({
    required this.date,
    required this.kind,
    required this.scheduled,
    required this.beforeStart,
    required this.isToday,
  });

  final DateTime date;
  final DayKind? kind;
  final bool scheduled;
  final bool beforeStart;
  final bool isToday;

  /// A scheduled day, already past, with nothing logged on it.
  bool get isMissed =>
      scheduled &&
      !beforeStart &&
      !isToday &&
      (kind == null || kind == DayKind.missed);
}

/// The rolling window everything is measured over. Deliberately not a streak:
/// missing one day moves this a few points, so there is nothing to shatter and
/// therefore nothing to abandon.
const consistencyWindowDays = 30;

/// Rest days you can spend per rolling window.
const restAllowancePerWindow = 4;

/// A habit must be this old and this consistent before a second one unlocks.
const unlockAgeDays = 14;
const unlockConsistency = 0.7;

/// When the app offers to get out of your way.
const graduationAgeDays = 90;
const graduationConsistency = 0.8;
const graduationSnoozeDays = 30;

/// The squares for the last [days] days, oldest first. Used at 30 days on the
/// home card and at 90 on the history page.
List<DayCell> buildRibbon(Habit habit, {required int days, DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  return [
    for (final date in daysEndingOn(today, days))
      DayCell(
        date: date,
        kind: habit.entryOn(date)?.kind,
        scheduled: habit.activeWeekdays.contains(date.weekday),
        beforeStart: date.isBefore(habit.createdAt),
        isToday: isSameDay(date, today),
      ),
  ];
}

class HabitStats {
  HabitStats._({
    required this.habit,
    required this.today,
    required this.ribbon,
    required this.consideredDays,
    required this.showedUpDays,
    required this.restsSpent,
    required this.ageDays,
  });

  factory HabitStats.of(Habit habit, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final window = daysEndingOn(today, consistencyWindowDays);

    var considered = 0;
    var showedUp = 0;
    var rests = 0;
    final ribbon = <DayCell>[];

    for (final date in window) {
      final beforeStart = date.isBefore(habit.createdAt);
      final scheduled = habit.activeWeekdays.contains(date.weekday);
      final entry = habit.entryOn(date);
      final isToday = isSameDay(date, today);

      ribbon.add(DayCell(
        date: date,
        kind: entry?.kind,
        scheduled: scheduled,
        beforeStart: beforeStart,
        isToday: isToday,
      ));

      if (beforeStart || !scheduled) continue;
      if (entry?.kind == DayKind.rest) {
        rests++;
        continue; // Rest days are spent, not failed: neutral in both terms.
      }
      // Today is not over yet, so an empty today is not held against you.
      if (isToday && entry == null) continue;

      considered++;
      if (entry?.isShowingUp ?? false) showedUp++;
    }

    return HabitStats._(
      habit: habit,
      today: today,
      ribbon: ribbon,
      consideredDays: considered,
      showedUpDays: showedUp,
      restsSpent: rests,
      ageDays: daysBetween(habit.createdAt, today),
    );
  }

  final Habit habit;
  final DateTime today;
  final List<DayCell> ribbon;
  final int consideredDays;
  final int showedUpDays;
  final int restsSpent;
  final int ageDays;

  /// Null until there is at least one scheduled day to judge.
  double? get consistency =>
      consideredDays == 0 ? null : showedUpDays / consideredDays;

  int? get consistencyPercent {
    final c = consistency;
    return c == null ? null : (c * 100).round();
  }

  int get votes => habit.votes;

  int get restsRemaining =>
      (restAllowancePerWindow - restsSpent).clamp(0, restAllowancePerWindow);

  DayEntry? get todayEntry => habit.entryOn(today);

  bool get scheduledToday => habit.isScheduledOn(today);

  bool get doneToday => todayEntry?.isShowingUp ?? false;

  bool get restingToday => todayEntry?.kind == DayKind.rest;

  /// Gate on adding anything else. Artificial scarcity is the feature: most
  /// people fail because they start six things at once.
  bool get clearsUnlockBar =>
      ageDays >= unlockAgeDays && (consistency ?? 0) >= unlockConsistency;

  int get daysUntilUnlockEligible => (unlockAgeDays - ageDays).clamp(0, unlockAgeDays);

  bool get readyToGraduate {
    if (habit.graduated) return false;
    if (ageDays < graduationAgeDays) return false;
    if ((consistency ?? 0) < graduationConsistency) return false;
    final snoozed = habit.graduationSnoozedAt;
    // Asked once, waved off: leave it alone for a month.
    return snoozed == null || daysBetween(snoozed, today) >= graduationSnoozeDays;
  }

  NudgeLevel get nudgeLevel {
    if (habit.graduated) return NudgeLevel.silent;
    if (ageDays < 7) return NudgeLevel.loud;
    final c = consistency ?? 0;
    if (c >= 0.85) return NudgeLevel.quiet;
    if (c >= 0.6) return NudgeLevel.normal;
    return NudgeLevel.loud;
  }
}
