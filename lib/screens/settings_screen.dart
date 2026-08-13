import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store.dart';
import '../data/store_scope.dart';
import '../logic/anchor.dart';
import '../logic/stats.dart';
import '../models/habit.dart';
import '../theme.dart';
import '../util/dates.dart';
import 'history_screen.dart' show describeWeekdays, reasonBreakdown;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 48),
          children: [
            const _SectionLabel('Settings'),
            const SizedBox(height: 20),
            const _WitnessCard(),
            const SizedBox(height: 18),
            for (final habit in store.habits) ...[
              _HabitSettingsCard(habit: habit),
              const SizedBox(height: 18),
            ],
            const _StorageCard(),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

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

class _Card extends StatelessWidget {
  const _Card({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// One witness, not a feed. A leaderboard creates performance anxiety and then
/// abandonment; one person who asks about it at dinner is what actually works.
class _WitnessCard extends StatefulWidget {
  const _WitnessCard();

  @override
  State<_WitnessCard> createState() => _WitnessCardState();
}

class _WitnessCardState extends State<_WitnessCard> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: StoreScope.read(context).witness?.name ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveWitness(AppStore store) {
    final value = _name.text.trim();
    if (value.isEmpty) return store.setWitness(null);
    final existing = store.witness;
    if (existing == null) return store.setWitness(Witness(name: value));
    existing.name = value;
    return store.setWitness(existing);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final witness = store.witness;
    final message = store.witnessMessage();

    return _Card(
      title: 'Your witness',
      subtitle: 'One person who gets your number each week. Not a feed, not a '
          'leaderboard — someone who will ask you about it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Who? (a name is enough)',
                  ),
                  onSubmitted: (_) => _saveWitness(store),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => _saveWitness(store),
                child: const Text('Save'),
              ),
            ],
          ),
          if (witness != null && witness.name.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardRaised,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: message));
                    await store.markWitnessShared();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied — send it to ${witness.name}.'),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.floor,
                  ),
                  child: const Text('Copy this week\'s note'),
                ),
                const Spacer(),
                Text(
                  witness.lastSharedAt == null
                      ? 'Not sent yet'
                      : 'Last sent '
                          '${_relativeDays(witness.lastSharedAt!)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _relativeDays(DateTime when) {
    final days = daysBetween(when, DateTime.now());
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }
}

class _HabitSettingsCard extends StatelessWidget {
  const _HabitSettingsCard({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final stats = store.statsFor(habit);

    return _Card(
      title: habit.name,
      subtitle: habit.anchor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            label: 'Days',
            value: describeWeekdays(habit.activeWeekdays),
            action: 'Change',
            onAction: () => _editWeekdays(context, store, habit),
          ),
          _Row(
            label: 'Anchor',
            value: habit.anchor,
            action: 'Edit',
            onAction: () => _editAnchor(context, store, habit),
          ),
          // Notifications get quieter as consistency rises. An app that still
          // needs you daily after six months has failed.
          _Row(
            label: 'Nudges',
            value: stats.nudgeLevel.label,
            hint: habit.graduated
                ? 'Graduated — this one is yours now.'
                : 'Set automatically from your consistency.',
          ),
          _Row(label: 'Misses', value: reasonBreakdown(habit)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (habit.graduated)
                TextButton(
                  onPressed: () => store.unGraduate(habit),
                  child: const Text('Bring it back to today'),
                )
              else
                TextButton(
                  onPressed: () => store.graduate(habit),
                  child: const Text('Graduate it'),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => _confirmDelete(context, store, habit),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textFaint,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editWeekdays(
    BuildContext context,
    AppStore store,
    Habit habit,
  ) async {
    var selected = {...habit.activeWeekdays};
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Which days?'),
          content: Wrap(
            spacing: 8,
            children: [
              for (var day = 1; day <= 7; day++)
                GestureDetector(
                  onTap: () => setState(() {
                    if (!selected.remove(day)) selected.add(day);
                  }),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected.contains(day)
                          ? AppColors.accentSurface
                          : AppColors.cardRaised,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      weekdayInitials[day - 1],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected.contains(day)
                            ? AppColors.accentOnSurface
                            : AppColors.textFaint,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != null) await store.setActiveWeekdays(habit, result);
  }

  Future<void> _editAnchor(
    BuildContext context,
    AppStore store,
    Habit habit,
  ) async {
    final controller = TextEditingController(text: habit.anchor);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final error = validateAnchor(controller.text);
          return AlertDialog(
            title: const Text('What happens right before it?'),
            content: SizedBox(
              width: 380,
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: anchorExamples.first,
                  errorText: controller.text.isEmpty ? null : error,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: error != null
                    ? null
                    : () => Navigator.of(context).pop(controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (result != null) {
      await store.updateHabit(habit, (h) => h.anchor = result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppStore store,
    Habit habit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${habit.name}?'),
        content: const Text(
          'This removes the habit and everything logged against it. '
          'It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await store.deleteHabit(habit);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.hint,
    this.action,
    this.onAction,
  });

  final String label;
  final String value;
  final String? hint;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textFaint,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textFaint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.floor,
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return _Card(
      title: 'Your data',
      subtitle: 'Everything lives in one file on this machine. Nothing is '
          'uploaded anywhere.',
      child: SelectableText(
        store.storagePath ?? 'Not saved yet',
        style: const TextStyle(fontSize: 12.5, color: AppColors.textFaint),
      ),
    );
  }
}
