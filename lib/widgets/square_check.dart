import 'package:flutter/material.dart';

import '../theme.dart';

/// The hollow square that fills in when a day is done.
class SquareCheck extends StatelessWidget {
  const SquareCheck({
    super.key,
    required this.checked,
    this.color = AppColors.textSecondary,
    this.size = 22,
  });

  final bool checked;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: checked ? color : Colors.transparent,
        border: Border.all(color: color, width: 1.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: checked
          ? Icon(
              Icons.check_rounded,
              size: size * 0.72,
              color: ThemeData.estimateBrightnessForColor(color) ==
                      Brightness.dark
                  ? Colors.white
                  : AppColors.background,
            )
          : null,
    );
  }
}
