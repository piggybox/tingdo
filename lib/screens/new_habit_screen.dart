import 'package:flutter/material.dart';

import '../data/store_scope.dart';
import '../logic/anchor.dart';
import '../theme.dart';
import '../util/dates.dart';
import '../widgets/mark.dart';

/// Setup asks six short questions, one at a time. The order matters: the thing,
/// then who it makes you, then the cue, then the ceiling, then the floor.
class NewHabitScreen extends StatefulWidget {
  const NewHabitScreen({super.key, required this.isFirstHabit});

  final bool isFirstHabit;

  @override
  State<NewHabitScreen> createState() => _NewHabitScreenState();
}

class _NewHabitScreenState extends State<NewHabitScreen> {
  static const _stepCount = 6;

  final _name = TextEditingController();
  final _identity = TextEditingController();
  final _anchor = TextEditingController();
  final _fullLabel = TextEditingController();
  final _fullDetail = TextEditingController();
  final _floorLabel = TextEditingController();
  final _floorDetail = TextEditingController();

  var _step = 0;
  String? _error;
  var _weekdays = <int>{1, 2, 3, 4, 5, 6, 7};

  @override
  void dispose() {
    for (final c in [
      _name,
      _identity,
      _anchor,
      _fullLabel,
      _fullDetail,
      _floorLabel,
      _floorDetail,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateStep() {
    switch (_step) {
      case 0:
        return _name.text.trim().isEmpty ? 'Give it a name.' : null;
      case 1:
        return _identity.text.trim().isEmpty
            ? 'Name the person this makes you.'
            : null;
      case 2:
        return validateAnchor(_anchor.text);
      case 3:
        return _fullLabel.text.trim().isEmpty
            ? 'Name the full version.'
            : null;
      case 4:
        return _floorLabel.text.trim().isEmpty ? 'Name the floor.' : null;
      case 5:
        return _weekdays.isEmpty ? 'Pick at least one day.' : null;
    }
    return null;
  }

  void _next() {
    final error = _validateStep();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_step == _stepCount - 1) {
      _finish();
      return;
    }
    setState(() {
      _error = null;
      _step++;
    });
  }

  void _back() {
    if (_step == 0) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _error = null;
      _step--;
    });
  }

  Future<void> _finish() async {
    final store = StoreScope.read(context);
    final navigator = Navigator.of(context);
    await store.addHabit(
      name: _name.text,
      identity: _identity.text,
      anchor: _anchor.text,
      fullLabel: _fullLabel.text,
      fullDetail: _fullDetail.text,
      floorLabel: _floorLabel.text,
      floorDetail: _floorDetail.text,
      activeWeekdays: _weekdays,
    );
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isFirstHabit && _step == 0) ...[
                  Row(
                    children: [
                      const TingDoMark(height: 34),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'TingDo',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'One habit. No streaks to break.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 38),
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.topLeft,
                  child: Column(
                    key: ValueKey(_step),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildStep(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.missed,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _next,
                      child: Text(
                        _step == _stepCount - 1 ? 'Start' : 'Continue',
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: _back,
                      child: Text(_step == 0 ? 'Cancel' : 'Back'),
                    ),
                    const Spacer(),
                    _StepDots(step: _step, count: _stepCount),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStep() {
    switch (_step) {
      case 0:
        return [
          const _Question(
            kicker: 'The one thing',
            question: "What's the habit?",
            note: 'Just one. You can add another once this one holds.',
          ),
          _Field(
            controller: _name,
            hint: 'Write',
            autofocus: true,
            onSubmitted: _next,
          ),
        ];
      case 1:
        return [
          const _Question(
            kicker: 'Identity',
            question: 'Who does this make you?',
            note: 'Every check will read as a vote for this person, not as a '
                'number on a counter.',
          ),
          _Field(
            controller: _identity,
            hint: 'someone who writes',
            autofocus: true,
            onSubmitted: _next,
          ),
        ];
      case 2:
        return [
          const _Question(
            kicker: 'The anchor',
            question: 'What happens right before it?',
            note: 'Not a time. A clock reminds you when you are busy; a cue '
                'reminds you when the habit actually fits.',
          ),
          _Field(
            controller: _anchor,
            hint: 'After I pour my coffee',
            autofocus: true,
            onSubmitted: _next,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in anchorExamples)
                _ExampleChip(
                  label: example,
                  onTap: () => setState(() {
                    _anchor.text = example;
                    _error = null;
                  }),
                ),
            ],
          ),
        ];
      case 3:
        return [
          const _Question(
            kicker: 'The ceiling',
            question: 'What does a full day look like?',
            note: 'The version you would do on a good day.',
          ),
          _Field(
            controller: _fullLabel,
            hint: 'Full session',
            autofocus: true,
            onSubmitted: _next,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: _fullDetail,
            hint: '500 words · 25 min',
            onSubmitted: _next,
          ),
        ];
      case 4:
        return [
          const _Question(
            kicker: 'The floor',
            question: 'And the smallest honest version?',
            note: 'Under two minutes. On a terrible day this is what you do, '
                'and it counts exactly the same — the habit you are building '
                'is showing up, not the volume.',
          ),
          _Field(
            controller: _floorLabel,
            hint: 'Just the floor',
            autofocus: true,
            onSubmitted: _next,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: _floorDetail,
            hint: '3 sentences · 2 min',
            onChanged: (_) => setState(() {}),
            onSubmitted: _next,
          ),
          if (_floorLooksBig) ...[
            const SizedBox(height: 10),
            const Text(
              'That still sounds like a good day. A floor should survive a bad '
              'one — shrink it until it feels almost silly.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textFaint,
                height: 1.4,
              ),
            ),
          ],
        ];
      case 5:
        return [
          const _Question(
            kicker: 'Days',
            question: 'Which days does this apply to?',
            note: 'Days you turn off are not misses — they simply do not count.',
          ),
          _WeekdayPicker(
            selected: _weekdays,
            onChanged: (days) => setState(() {
              _weekdays = days;
              _error = null;
            }),
          ),
        ];
    }
    return const [];
  }

  /// A soft check on the floor: anything over five minutes is not a floor.
  bool get _floorLooksBig {
    final match = RegExp(r'(\d+)\s*(min|minute|hour|hr)', caseSensitive: false)
        .firstMatch(_floorDetail.text);
    if (match == null) return false;
    final value = int.tryParse(match.group(1)!) ?? 0;
    final unit = match.group(2)!.toLowerCase();
    return unit.startsWith('h') ? value >= 1 : value > 5;
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.kicker,
    required this.question,
    this.note,
  });

  final String kicker;
  final String question;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: AppColors.textFaint,
          ),
        ),
        const SizedBox(height: 10),
        Text(question, style: Theme.of(context).textTheme.displaySmall),
        if (note != null) ...[
          const SizedBox(height: 10),
          Text(
            note!,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 22),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      decoration: InputDecoration(hintText: hint),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardRaised,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (var day = 1; day <= 7; day++)
          _DayToggle(
            label: weekdayInitials[day - 1],
            selected: selected.contains(day),
            onTap: () {
              final next = {...selected};
              if (!next.remove(day)) next.add(day);
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSurface : AppColors.cardRaised,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  selected ? AppColors.accentOnSurface : AppColors.textFaint,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step, required this.count});

  final int step;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= step ? AppColors.full : AppColors.divider,
              ),
            ),
          ),
      ],
    );
  }
}
