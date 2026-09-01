import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// ─── Monochromatic design tokens ──────────────────────────────────────────────
const _white = Color(0xFFFFFFFF);
const _surfaceDark = Color(0xFF1A1A18);

enum GlassBlurLevel {
  subtle(8.0),
  medium(16.0),
  strong(28.0),
  maximum(50.0);

  final double sigma;
  const GlassBlurLevel(this.sigma);
}

// ─── Ghost calendar painter ────────────────────────────────────────────────────
/// Draws a large, barely-visible ghost calendar filling the background.
/// The calendar shows the current month with a few dates highlighted by
/// faint circles — giving the app a purposeful, document-official feel.
class _GhostCalendarPainter extends CustomPainter {
  _GhostCalendarPainter({required this.isDark});

  final bool isDark;

  static const _dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final base = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF111111);

    // All text/lines at very low opacity — barely perceptible
    final faintColor  = base.withValues(alpha: 0.055);
    final dimColor    = base.withValues(alpha: 0.040);
    final circleColor = base.withValues(alpha: 0.070);
    final todayColor  = base.withValues(alpha: 0.10);

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // weekday: Mon=1 … Sun=7, so column offset 0–6
    final offset = firstDay.weekday - 1;

    // ── Layout ──────────────────────────────────────────────────────────────
    // Calendar spans full width with modest horizontal margin
    const hPad = 48.0;
    final calW = size.width - hPad * 2;
    final cellW = calW / 7;

    // Vertical: start roughly 14% from top
    final topY = size.height * 0.13;
    final monthFontSize = math.min(calW * 0.068, 80.0);
    final headerFontSize = math.min(cellW * 0.30, 14.0);
    final dateFontSize = math.min(cellW * 0.32, 18.0);
    final cellH = math.min(size.height * 0.105, cellW * 0.90);

    // ── Month name ──────────────────────────────────────────────────────────
    _paintText(
      canvas,
      '${_monthNames[now.month - 1]}  ${now.year}',
      Offset(hPad, topY),
      fontSize: monthFontSize,
      fontWeight: FontWeight.w700,
      color: faintColor,
      letterSpacing: -2,
    );

    final headerY = topY + monthFontSize + 18;

    // ── Day-of-week headers ─────────────────────────────────────────────────
    for (int col = 0; col < 7; col++) {
      final tp = _buildTP(
        _dayNames[col],
        fontSize: headerFontSize,
        fontWeight: FontWeight.w600,
        color: dimColor,
        letterSpacing: 1.5,
      );
      tp.layout(maxWidth: cellW);
      tp.paint(canvas,
          Offset(hPad + col * cellW + (cellW - tp.width) / 2, headerY));
    }

    // Separator line under headers
    final lineY = headerY + headerFontSize + 10;
    canvas.drawLine(
      Offset(hPad, lineY),
      Offset(hPad + calW, lineY),
      Paint()
        ..color = dimColor
        ..strokeWidth = 0.8,
    );

    // ── Dates ───────────────────────────────────────────────────────────────
    final gridY = lineY + 14;

    // Pick a few dates to highlight (simulate tracked expiry dates)
    final random = math.Random(now.month + now.year * 12);
    final highlights = <int>{};
    for (int i = 0; i < 5; i++) {
      highlights.add(random.nextInt(daysInMonth) + 1);
    }
    highlights.add(now.day); // today always highlighted

    final circlePaint = Paint()..style = PaintingStyle.fill;

    for (int day = 1; day <= daysInMonth; day++) {
      final pos = offset + day - 1;
      final row = pos ~/ 7;
      final col = pos % 7;
      final cx = hPad + col * cellW + cellW / 2;
      final cy = gridY + row * cellH + cellH / 2;

      final isToday = day == now.day;
      final isHighlight = highlights.contains(day);

      if (isToday) {
        // Filled circle for today
        circlePaint.color = todayColor;
        canvas.drawCircle(Offset(cx, cy), cellW * 0.36, circlePaint);
      } else if (isHighlight) {
        // Stroke circle for highlighted dates
        canvas.drawCircle(
          Offset(cx, cy),
          cellW * 0.33,
          Paint()
            ..color = circleColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }

      final tp = _buildTP(
        '$day',
        fontSize: isToday ? dateFontSize * 1.15 : dateFontSize,
        fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
        color: isToday
            ? base.withValues(alpha: 0.18)
            : (isHighlight ? circleColor : dimColor),
      );
      tp.layout(maxWidth: cellW);
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  TextPainter _buildTP(
    String text, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double letterSpacing = 0,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double letterSpacing = 0,
  }) {
    final tp = _buildTP(text,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing);
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_GhostCalendarPainter old) => old.isDark != isDark;
}

// ─── App background ────────────────────────────────────────────────────────────
/// Flat monochromatic canvas with a large ghost calendar for visual structure.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E0E0C) : const Color(0xFFF1EFE8);

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: bgColor)),
        Positioned.fill(
          child: CustomPaint(
              painter: _GhostCalendarPainter(isDark: isDark)),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

// ─── Frosted glass panel ───────────────────────────────────────────────────────
class AdvancedGlassPanel extends StatelessWidget {
  const AdvancedGlassPanel({
    super.key,
    required this.child,
    this.blurLevel = GlassBlurLevel.medium,
    this.padding,
    this.radius = 12.0,
    this.tint,
    this.primaryColor,
    this.showBorder = false, // No borders
  });

  final Widget child;
  final GlassBlurLevel blurLevel;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? tint;
  final Color? primaryColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color surface;
    if (tint != null) {
      surface = tint!.withValues(alpha: isDark ? 0.72 : 0.90);
    } else if (isDark) {
      surface = _surfaceDark.withValues(alpha: 0.82);
    } else {
      surface = _white.withValues(alpha: 0.92);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurLevel.sigma,
            sigmaY: blurLevel.sigma,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: surface,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── Layered glass stack ───────────────────────────────────────────────────────
class LayeredGlassStack extends StatelessWidget {
  const LayeredGlassStack({super.key, required this.child, this.primaryColor});

  final Widget child;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: AdvancedGlassPanel(
            blurLevel: GlassBlurLevel.maximum,
            tint: isDark ? _surfaceDark : _white,
            radius: 24,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned.fill(
          top: 10, bottom: 10, left: 10, right: 10,
          child: AdvancedGlassPanel(
            blurLevel: GlassBlurLevel.strong,
            tint: isDark ? const Color(0xFF222220) : _white,
            radius: 20,
            child: const SizedBox.expand(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: AdvancedGlassPanel(
            blurLevel: GlassBlurLevel.medium,
            tint: isDark ? const Color(0xFF111110) : _white,
            radius: 16,
            padding: const EdgeInsets.all(24.0),
            child: child,
          ),
        ),
      ],
    );
  }
}
