import 'package:flutter/material.dart';

import '../data/store_scope.dart';
import '../logic/insights.dart';
import '../logic/stats.dart';
import '../models/day_entry.dart';
import '../models/habit.dart';
import '../theme.dart';
import '../util/dates.dart';
import '../widgets/day_grid.dart';
import '../widgets/miss_reason_sheet.dart';

/// One swipe from today: the longer view, plus whatever the data has to say.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final habits = store.habits;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 48),
          children: [
            const _PageTitle('History'),
            const SizedBox(height: 20),
            for (final habit in habits) ...[
              _HabitHistory(habit: habit),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        letterSpacing: 1.3,
        fontWeight: FontWeight.w600,
        color: AppColors.textFaint,
      ),
    );
  }
}

class _HabitHistory extends StatelessWidget {
  const _HabitHistory({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final stats = store.statsFor(habit);
    final cells = buildRibbon(habit, days: 90);
    final insights = insightsFor(habit);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  habit.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (habit.graduated)
                const _Tag(text: 'Graduated'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${stats.votes} ${stats.votes == 1 ? 'vote' : 'votes'} for: '
            '${habit.identity}',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Stat(
                value: stats.consistencyPercent == null
                    ? '—'
                    : '${stats.consistencyPercent}%',
                label: 'last 30 days',
              ),
              const SizedBox(width: 28),
              _Stat(value: '${stats.ageDays}', label: 'days in'),
              const SizedBox(width: 28),
              _Stat(value: '${stats.restsSpent}', label: 'rest days spent'),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Last 90 days',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          DayGrid(
            cells: cells,
            perRow: 30,
            spacing: 4,
            maxCellSize: 18,
            onTapDay: (cell) => _onTapDay(context, cell),
          ),
          const SizedBox(height: 12),
          const GridLegend(),
          const SizedBox(height: 10),
          const Text(
            'Tap a grey day to say what got in the way.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textFaint),
          ),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 20),
            for (final insight in insights) ...[
              _InsightCard(habit: habit, insight: insight),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _onTapDay(BuildContext context, DayCell cell) async {
    if (!cell.isMissed) return;
    final store = StoreScope.read(context);
    final result = await showMissReasonSheet(
      context,
      date: cell.date,
      current: habit.entryOn(cell.date)?.reason,
    );
    if (result == null) return;
    await store.setMissReason(habit, cell.date, result.cleared ? null : result.reason);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textFaint)),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardRaised,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Data as a diagnostic. Each insight comes with the one adjustment worth
/// making, and the adjustment is one tap away.
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.habit, required this.insight});

  final Habit habit;
  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.read(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.message,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          if (insight.action != null && insight.weekday != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => store.dropWeekday(habit, insight.weekday!),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.floor,
                ),
                child: Text(insight.action!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reason counts, shown on the settings page too.
String reasonBreakdown(Habit habit) {
  final counts = <MissReason, int>{};
  for (final entry in habit.entries.values) {
    final reason = entry.reason;
    if (reason == null) continue;
    counts[reason] = (counts[reason] ?? 0) + 1;
  }
  if (counts.isEmpty) return 'No reasons logged yet.';
  final parts = counts.entries.map((e) => '${e.key.label} ${e.value}').toList()
    ..sort();
  return parts.join('  ·  ');
}

String describeWeekdays(Set<int> days) {
  if (days.length == 7) return 'Every day';
  final sorted = days.toList()..sort();
  return sorted.map((d) => weekdayName(d).substring(0, 3)).join(', ');
}
