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

// ─── Scattered numbers background painter ─────────────────────────────────────
/// Draws large, barely-visible day numerals (1–31) scattered across the canvas.
/// Sizes vary from 48px to 130px, positions and rotations are deterministic
/// (seeded by month+year) so they don't jump on every rebuild.
class _NumberBackgroundPainter extends CustomPainter {
  _NumberBackgroundPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final base = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111111);

    final now = DateTime.now();
    final seed = now.year * 12 + now.month;
    final rng = math.Random(seed);

    // Place 31 numbers pseudo-randomly; vary size + opacity per number
    for (int day = 1; day <= 31; day++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final fontSize = 48.0 + rng.nextDouble() * 82.0; // 48–130px
      final alpha = 0.035 + rng.nextDouble() * 0.045;  // 3.5–8%

      final tp = TextPainter(
        text: TextSpan(
          text: '$day',
          style: TextStyle(
            color: base.withValues(alpha: alpha),
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            letterSpacing: -2,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      // Centre the number on its random point
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_NumberBackgroundPainter old) => old.isDark != isDark;
}


// ─── App background ────────────────────────────────────────────────────────────
/// Flat monochromatic canvas with scattered day-number typographic texture.
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
              painter: _NumberBackgroundPainter(isDark: isDark)),
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
