import 'package:flutter/material.dart';

import '../theme.dart';
import 'square_check.dart';

/// One of the two ways to show up.
///
/// The floor sits below the full version but is exactly as tappable: same hit
/// area, one tap, no confirmation dialog, no "are you sure you don't want to do
/// the real thing?". Any friction there teaches people the floor is cheating,
/// and the whole mechanic dies.
class OptionTile extends StatefulWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.detail,
    required this.checked,
    required this.onTap,
    this.emphasised = false,
    this.enabled = true,
  });

  final String label;
  final String detail;
  final bool checked;
  final VoidCallback onTap;

  /// The full version gets the light surface; the floor stays quiet but equal.
  final bool emphasised;
  final bool enabled;

  @override
  State<OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<OptionTile> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final emphasised = widget.emphasised;
    final baseColor = emphasised ? AppColors.accentSurface : AppColors.cardRaised;
    final textColor =
        emphasised ? AppColors.accentOnSurface : AppColors.textPrimary;
    final detailColor = emphasised
        ? AppColors.accentOnSurface.withValues(alpha: 0.75)
        : AppColors.textSecondary;

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: _hovered && widget.enabled
                ? Color.alphaBlend(
                    Colors.white.withValues(alpha: emphasised ? 0.12 : 0.05),
                    baseColor,
                  )
                : baseColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.checked
                  ? (emphasised ? AppColors.accentOnSurface : AppColors.floor)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.45,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (widget.detail.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.detail,
                          style: TextStyle(fontSize: 14, color: detailColor),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SquareCheck(
                  checked: widget.checked,
                  color: emphasised ? AppColors.accentOnSurface : AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
