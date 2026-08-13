import 'package:flutter/material.dart';

import '../logic/stats.dart';
import '../models/day_entry.dart';
import '../theme.dart';
import '../util/dates.dart';

/// The consistency ribbon: a rolling window of squares, no streak to break.
class DayGrid extends StatelessWidget {
  const DayGrid({
    super.key,
    required this.cells,
    required this.perRow,
    this.spacing = 6,
    this.maxCellSize = 24,
    this.onTapDay,
  });

  final List<DayCell> cells;

  /// Fixed squares per row, so the ribbon reads as even blocks rather than
  /// reflowing into a ragged last line as the window resizes.
  final int perRow;
  final double spacing;
  final double maxCellSize;
  final void Function(DayCell cell)? onTapDay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - spacing * (perRow - 1);
        final size = (available / perRow).clamp(6.0, maxCellSize);
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final cell in cells)
              _DaySquare(
                cell: cell,
                size: size,
                onTap: onTapDay == null ? null : () => onTapDay!(cell),
              ),
          ],
        );
      },
    );
  }
}

class _DaySquare extends StatelessWidget {
  const _DaySquare({required this.cell, required this.size, this.onTap});

  final DayCell cell;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final square = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _fill(cell),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: _border(cell),
      ),
    );

    return Tooltip(
      message: _tooltip(cell),
      waitDuration: const Duration(milliseconds: 400),
      child: onTap == null
          ? square
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(onTap: onTap, child: square),
            ),
    );
  }

  static Color _fill(DayCell cell) {
    if (cell.beforeStart || !cell.scheduled) return AppColors.empty;
    return switch (cell.kind) {
      DayKind.full => AppColors.full,
      DayKind.floor => AppColors.floor,
      DayKind.rest => AppColors.rest,
      // A tagged miss and an untagged gap look identical: warm grey, never red.
      DayKind.missed => AppColors.missed,
      null => cell.isToday ? Colors.transparent : AppColors.missed,
    };
  }

  static BoxBorder? _border(DayCell cell) {
    if (cell.isToday && cell.kind == null) {
      return Border.all(color: AppColors.textFaint, width: 1.4);
    }
    if (cell.beforeStart || !cell.scheduled) {
      return Border.all(color: AppColors.divider, width: 1);
    }
    return null;
  }

  static String _tooltip(DayCell cell) {
    final date = '${weekdayName(cell.date.weekday)} '
        '${cell.date.day}/${cell.date.month}';
    if (cell.beforeStart) return '$date · before you started';
    if (!cell.scheduled) return '$date · day off';
    final what = switch (cell.kind) {
      DayKind.full => 'full',
      DayKind.floor => 'floor',
      DayKind.rest => 'rest day',
      DayKind.missed => 'missed',
      null => cell.isToday ? 'today, still open' : 'missed',
    };
    return '$date · $what';
  }
}

/// Full / Floor / Missed / Rest, in that order of prominence.
class GridLegend extends StatelessWidget {
  const GridLegend({super.key, this.showRest = true});

  final bool showRest;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        const _LegendItem(color: AppColors.full, label: 'Full'),
        const _LegendItem(color: AppColors.floor, label: 'Floor'),
        const _LegendItem(color: AppColors.missed, label: 'Missed'),
        if (showRest) const _LegendItem(color: AppColors.rest, label: 'Rest'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
      ],
    );
  }
}
