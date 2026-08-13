import 'package:flutter/material.dart';

import '../models/day_entry.dart';
import '../theme.dart';
import '../util/dates.dart';

/// The blameless miss review: four one-word options, no free-text box, no
/// explaining yourself. It exists so the app can later say "you miss
/// Thursdays" — a diagnostic, not a confession.
class MissReasonResult {
  const MissReasonResult(this.reason, {this.cleared = false});

  final MissReason? reason;
  final bool cleared;
}

Future<MissReasonResult?> showMissReasonSheet(
  BuildContext context, {
  required DateTime date,
  MissReason? current,
}) {
  return showDialog<MissReasonResult>(
    context: context,
    builder: (context) => _MissReasonDialog(date: date, current: current),
  );
}

class _MissReasonDialog extends StatelessWidget {
  const _MissReasonDialog({required this.date, this.current});

  final DateTime date;
  final MissReason? current;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${weekdayName(date.weekday)} ${date.day}/${date.month}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'What got in the way?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'No judgement — this is just so patterns can show up later.',
                style: TextStyle(fontSize: 13, color: AppColors.textFaint),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reason in MissReason.values)
                    _ReasonChip(
                      label: reason.label,
                      selected: reason == current,
                      onTap: () => Navigator.of(context)
                          .pop(MissReasonResult(reason)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (current != null)
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .pop(const MissReasonResult(null, cleared: true)),
                      child: const Text('Clear'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSurface : AppColors.cardRaised,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: selected
                  ? AppColors.accentOnSurface
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
