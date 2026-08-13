import 'package:flutter/material.dart';

import '../data/store_scope.dart';
import '../logic/stats.dart';
import '../models/day_entry.dart';
import '../models/habit.dart';
import '../theme.dart';
import '../util/dates.dart';
import '../widgets/day_grid.dart';
import '../widgets/option_tile.dart';
import '../widgets/square_check.dart';
import 'new_habit_screen.dart';

/// The home screen is only today.
///
/// History, charts and settings live one swipe away. If someone opens the app
/// and sees a dashboard, they are managing a system instead of doing a thing.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final habits = store.activeHabits;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 48),
          children: [
            if (habits.isEmpty)
              const _AllGraduated()
            else
              for (final habit in habits) ...[
                _HabitCard(habit: habit),
                const SizedBox(height: 20),
              ],
            const SizedBox(height: 4),
            const _AddHabitFooter(),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final stats = store.statsFor(habit);
    final entry = stats.todayEntry;
    final offToday = !stats.scheduledToday;

    return Container(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
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
              Text(
                weekdayName(DateTime.now().weekday),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              SquareCheck(
                checked: stats.doneToday,
                color: stats.doneToday ? AppColors.full : AppColors.textFaint,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            habit.anchor,
            style: TextStyle(
              fontSize: 15,
              color: stats.nudgeLevel == NudgeLevel.quiet
                  ? AppColors.textFaint
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(habit.name, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 6),
          // Identity framing: each check is evidence about who you are, not a
          // point in a game.
          Text(
            '${stats.votes} ${stats.votes == 1 ? 'vote' : 'votes'} for: '
            '${habit.identity}',
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          if (offToday)
            _QuietNote(
              text: '${weekdayName(DateTime.now().weekday)}s are off. '
                  'Nothing to do — see you tomorrow.',
            )
          else if (stats.restingToday)
            _RestingNote(habit: habit)
          else ...[
            OptionTile(
              label: habit.fullLabel,
              detail: habit.fullDetail,
              checked: entry?.kind == DayKind.full,
              emphasised: true,
              onTap: () => store.logToday(habit, DayKind.full),
            ),
            const SizedBox(height: 10),
            OptionTile(
              label: habit.floorLabel,
              detail: habit.floorDetail,
              checked: entry?.kind == DayKind.floor,
              onTap: () => store.logToday(habit, DayKind.floor),
            ),
            if (!stats.doneToday && stats.nudgeLevel == NudgeLevel.loud) ...[
              const SizedBox(height: 12),
              Text(
                'The floor counts. ${habit.floorDetail.isEmpty ? '' : '${habit.floorDetail} '}'
                'is a real day.',
                style: const TextStyle(fontSize: 13, color: AppColors.textFaint),
              ),
            ],
          ],
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 18),
          _Ribbon(stats: stats),
          if (stats.readyToGraduate) ...[
            const SizedBox(height: 20),
            _GraduationOffer(habit: habit, stats: stats),
          ],
          if (!offToday && !stats.doneToday) ...[
            const SizedBox(height: 18),
            Center(child: _RestDayButton(habit: habit, stats: stats)),
          ],
        ],
      ),
    );
  }
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.stats});

  final HabitStats stats;

  @override
  Widget build(BuildContext context) {
    final pct = stats.consistencyPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Last 30 days',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              pct == null ? '—' : '$pct%',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DayGrid(cells: stats.ribbon, perRow: 15),
        const SizedBox(height: 12),
        const GridLegend(),
      ],
    );
  }
}

class _RestDayButton extends StatelessWidget {
  const _RestDayButton({required this.habit, required this.stats});

  final Habit habit;
  final HabitStats stats;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.read(context);
    final left = stats.restsRemaining;
    if (left == 0) {
      return const Text(
        'No rest days left in this window. The floor is still there.',
        style: TextStyle(fontSize: 13.5, color: AppColors.textFaint),
        textAlign: TextAlign.center,
      );
    }
    // Rest days are a feature you spend, not a failure you confess to.
    return TextButton(
      onPressed: () => store.logToday(habit, DayKind.rest),
      child: Text('Rough day? Take a rest day  ·  $left left'),
    );
  }
}

class _RestingNote extends StatelessWidget {
  const _RestingNote({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.read(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resting today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Spent, not missed. It leaves your number alone.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => store.logToday(habit, DayKind.rest),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Actually, I want to do it'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietNote extends StatelessWidget {
  const _QuietNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.cardRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
      ),
    );
  }
}

/// The app trying to lose you: at 90 solid days it offers to stop asking.
class _GraduationOffer extends StatelessWidget {
  const _GraduationOffer({required this.habit, required this.stats});

  final Habit habit;
  final HabitStats stats;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.read(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.full.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${stats.ageDays} days at ${stats.consistencyPercent}%.',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'This is yours now. Want to move it to the background and stop '
            'being asked about it?',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: () => store.graduate(habit),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text('Graduate it'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => store.snoozeGraduation(habit),
                child: const Text('Not yet'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllGraduated extends StatelessWidget {
  const _AllGraduated();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nothing to check today.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Everything you started has graduated. That is the goal, not a bug. '
            'Add something new when you actually want to.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Adding is gated on the current habit taking hold. Artificial scarcity is
/// the feature: most people fail because they start six things at once.
class _AddHabitFooter extends StatelessWidget {
  const _AddHabitFooter();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final blocked = store.addHabitBlockedReason();

    if (blocked != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          blocked,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: AppColors.textFaint),
        ),
      );
    }

    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NewHabitScreen(isFirstHabit: false),
          ),
        ),
        child: const Text('Add a habit'),
      ),
    );
  }
}
