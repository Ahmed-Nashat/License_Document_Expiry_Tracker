import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Brand mark: a shield with a checkmark, with a small bell badge on the
/// top-right corner. Single-color — ink (#111111) on light, white on dark.
/// Scales cleanly from 16px (favicon) to 48px+.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.white : AppColors.ink;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(color: color),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // ── Shield body (rounded pentagon) ──────────────────────────────────────
    // Shield takes up roughly the bottom 88% of the icon; top-right leaves
    // room for the bell badge overlay.
    final shieldLeft = w * 0.04;
    final shieldRight = w * 0.80;
    final shieldTop = h * 0.12;
    final shieldBottom = h * 0.96;
    final shieldMidX = (shieldLeft + shieldRight) / 2;
    final r = w * 0.12; // corner radius

    final shieldPath = Path()
      ..moveTo(shieldMidX, shieldTop) // top-center (peak)
      ..lineTo(shieldRight - r, shieldTop)
      ..quadraticBezierTo(shieldRight, shieldTop, shieldRight, shieldTop + r)
      ..lineTo(shieldRight, h * 0.58)
      // Curve inward to bottom tip
      ..cubicTo(shieldRight, h * 0.80, shieldMidX, shieldBottom, shieldMidX,
          shieldBottom)
      ..cubicTo(
          shieldMidX, shieldBottom, shieldLeft, h * 0.80, shieldLeft, h * 0.58)
      ..lineTo(shieldLeft, shieldTop + r)
      ..quadraticBezierTo(shieldLeft, shieldTop, shieldLeft + r, shieldTop)
      ..close();

    canvas.drawPath(shieldPath, paint);

    // ── Checkmark (cut-out / contrasting color) ──────────────────────────
    final checkPaint = Paint()
      ..color =
          color == AppColors.ink ? AppColors.white : const Color(0xFF0E0E0C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.095
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(shieldMidX - w * 0.195, h * 0.50)
      ..lineTo(shieldMidX - w * 0.04, h * 0.63)
      ..lineTo(shieldMidX + w * 0.19, h * 0.37);

    canvas.drawPath(checkPath, checkPaint);

    // ── Bell badge (top-right corner) ────────────────────────────────────
    // The bell is a small filled circle with a tiny bell icon inside, drawn
    // at the top-right corner of the bounding box to overlap the shield.
    final bellCx = w * 0.875;
    final bellCy = h * 0.175;
    final bellR = w * 0.175;

    // Badge background — same color as the foreground (solid pill)
    canvas.drawCircle(Offset(bellCx, bellCy), bellR, paint);

    // Bell silhouette (contrasting cutout)
    final bellBody = Paint()
      ..color =
          color == AppColors.ink ? AppColors.white : const Color(0xFF0E0E0C)
      ..style = PaintingStyle.fill;

    final bs = bellR * 0.55; // bell scale factor relative to badge
    final bx = bellCx;
    final by = bellCy;

    // Bell dome (arc + sides)
    final bellPath = Path();
    bellPath.addArc(
      Rect.fromCenter(
          center: Offset(bx, by - bs * 0.1), width: bs * 1.6, height: bs * 1.4),
      math.pi,
      math.pi,
    );
    bellPath
      ..lineTo(bx + bs * 0.80, by + bs * 0.42)
      ..lineTo(bx - bs * 0.80, by + bs * 0.42)
      ..close();

    canvas.drawPath(bellPath, bellBody);

    // Clapper (small circle at bottom of bell)
    canvas.drawCircle(
      Offset(bx, by + bs * 0.55),
      bs * 0.22,
      bellBody,
    );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) => old.color != color;
}
