import 'package:flutter/material.dart';

import '../theme.dart';

/// The TingDo mark, drawn rather than shipped as an image so it stays sharp at
/// any size and picks up the palette.
///
/// It is the same geometry as the app icon (see design/build_icons.sh): a T
/// whose top bar is the full version and whose bottom bar is the floor, drawn
/// identically because the app refuses to rank them.
class TingDoMark extends StatelessWidget {
  const TingDoMark({super.key, this.height = 34, this.color = AppColors.floor});

  final double height;
  final Color color;

  /// Ratio taken straight from the icon artwork: 423 wide by 489 tall.
  static const _aspect = 423 / 489;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'TingDo',
      child: SizedBox(
        height: height,
        width: height * _aspect,
        child: CustomPaint(painter: _MarkPainter(color)),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);

  final Color color;

  // Coordinates in the icon's own 423 x 489 space.
  static const _barWidth = 423.0;
  static const _barHeight = 85.0;
  static const _stemLeft = 169.0;
  static const _stemWidth = 85.0;
  static const _stemBottom = 366.0;
  static const _floorTop = 404.0;
  static const _radius = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 489;
    canvas.scale(scale);

    final paint = Paint()..color = color;
    const radius = Radius.circular(_radius);

    void bar(double top) => canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, _barWidth, _barHeight).shift(Offset(0, top)),
            radius,
          ),
          paint,
        );

    bar(0); // the full version
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(_stemLeft, 0, _stemWidth, _stemBottom),
        radius,
      ),
      paint,
    );
    bar(_floorTop); // the floor, same bar, same weight
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}
