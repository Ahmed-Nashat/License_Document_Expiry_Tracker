import 'dart:ui';
import 'package:flutter/material.dart';

// ─── Monochromatic design tokens ──────────────────────────────────────────────
const _fog = Color(0xFFF1EFE8);
const _white = Color(0xFFFFFFFF);
const _border = Color(0xFFD3D1C7);
const _borderDark = Color(0xFF3A3A38);
const _surfaceDark = Color(0xFF1A1A18);

enum GlassBlurLevel {
  subtle(8.0),
  medium(16.0),
  strong(28.0),
  maximum(50.0);

  final double sigma;
  const GlassBlurLevel(this.sigma);
}

// ─── Background dot-grid painter ──────────────────────────────────────────────
/// Draws an evenly-spaced dot grid, creating a calm "graph-paper" texture
/// that adds structure without competing with the content.
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.dotColor});

  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 26.0; // gap between dots
    const radius = 1.1; // dot radius

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.dotColor != dotColor;
}

// ─── App background ────────────────────────────────────────────────────────────
/// Flat monochromatic canvas with a subtle dot-grid texture for visual
/// structure. The pattern is barely-there — purely perceptible, not decorative.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0E0E0C) : _fog;
    final dotColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.045)
        : const Color(0xFF111111).withValues(alpha: 0.055);

    return Stack(
      children: [
        // Base canvas
        Positioned.fill(child: ColoredBox(color: bgColor)),
        // Dot-grid structure layer
        Positioned.fill(
          child: CustomPaint(painter: _DotGridPainter(dotColor: dotColor)),
        ),
        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}

// ─── Frosted glass panel ───────────────────────────────────────────────────────
/// Apple Liquid Glass panel. Shadows are neutral (no color bloom).
class AdvancedGlassPanel extends StatelessWidget {
  const AdvancedGlassPanel({
    super.key,
    required this.child,
    this.blurLevel = GlassBlurLevel.medium,
    this.padding,
    this.radius = 12.0,
    this.tint,
    this.primaryColor, // retained for API compatibility; ignored
    this.showBorder = true,
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

    final borderColor = isDark
        ? _borderDark.withValues(alpha: 0.60)
        : _border.withValues(alpha: 0.80);

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
              border: showBorder
                  ? Border.all(color: borderColor, width: 1)
                  : null,
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
          top: 10,
          bottom: 10,
          left: 10,
          right: 10,
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
