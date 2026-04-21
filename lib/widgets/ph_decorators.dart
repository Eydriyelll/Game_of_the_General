// lib/widgets/ph_decorators.dart
// Shared Philippine-themed decorative widgets used across multiple screens.

import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ── Philippine Background (subtle flag geometry) ─────────────────────────────

class PhilippineBackground extends StatelessWidget {
  const PhilippineBackground({super.key});
  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: CustomPaint(painter: _PhBgPainter()),
      );
}

class _PhBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = AppTheme.phNavy.withOpacity(0.07);
    final p1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.45, 0)
      ..lineTo(0, size.height * 0.45)
      ..close();
    canvas.drawPath(p1, paint);
    paint.color = AppTheme.phRed.withOpacity(0.04);
    final p2 = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.6, size.height)
      ..lineTo(size.width, size.height * 0.6)
      ..close();
    canvas.drawPath(p2, paint);
    paint.color = AppTheme.phNavy.withOpacity(0.03);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.5), paint);
    paint.color = AppTheme.phRed.withOpacity(0.03);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5),
        paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Philippine Sun ────────────────────────────────────────────────────────────

class PhSunWidget extends StatelessWidget {
  final double size;
  const PhSunWidget({super.key, required this.size});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _SunPainter()),
      );
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final fill = Paint()
      ..color = AppTheme.phGold
      ..style = PaintingStyle.fill;
    final rays = Paint()
      ..color = AppTheme.phGold.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final a = i * 45 * pi / 180;
      canvas.drawLine(
        Offset(cx + r * 0.42 * cos(a), cy + r * 0.42 * sin(a)),
        Offset(cx + r * 0.88 * cos(a), cy + r * 0.88 * sin(a)),
        rays,
      );
    }
    canvas.drawCircle(Offset(cx, cy), r * 0.38, fill);
    final inner = Paint()
      ..color = AppTheme.background.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r * 0.22, inner);
    _star(canvas, Offset(cx, cy - r * 0.18), r * 0.06, fill);
  }

  void _star(Canvas canvas, Offset center, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final o = Offset(center.dx + r * cos((i * 72 - 90) * pi / 180),
          center.dy + r * sin((i * 72 - 90) * pi / 180));
      final inn = Offset(
          center.dx + r * 0.4 * cos(((i * 72 + 36) - 90) * pi / 180),
          center.dy + r * 0.4 * sin(((i * 72 + 36) - 90) * pi / 180));
      if (i == 0)
        path.moveTo(o.dx, o.dy);
      else
        path.lineTo(o.dx, o.dy);
      path.lineTo(inn.dx, inn.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}
