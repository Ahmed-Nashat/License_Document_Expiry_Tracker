import 'dart:ui';
import 'package:flutter/material.dart';

enum GlassBlurLevel {
  subtle(8.0), // backdrop-blur-sm
  medium(16.0), // backdrop-blur-md
  strong(28.0), // backdrop-blur-xl
  maximum(50.0); // backdrop-blur-3xl

  final double sigma;
  const GlassBlurLevel(this.sigma);
}

/// Rich Apple-style background with glowing ambient orbs so glassmorphism blur is clearly visible.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Clean base gradient background
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF0A1020),
                        Color(0xFF101A31),
                        Color(0xFF0B1326),
                      ]
                    : const [
                        Color(0xFFF8FAFF),
                        Color(0xFFEEF3FF),
                        Color(0xFFF8F9FC),
                      ],
              ),
            ),
          ),
        ),

        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Advanced Frosted Glass Panel implementing the Glassmorphism Advanced design specification.
class AdvancedGlassPanel extends StatelessWidget {
  const AdvancedGlassPanel({
    super.key,
    required this.child,
    this.blurLevel = GlassBlurLevel.strong, // default: backdrop-blur-xl
    this.padding,
    this.radius = 24.0,
    this.tint,
    this.primaryColor,
    this.showBorder = false,
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

    // Critical Rules from SKILL.md:
    // 1. backdrop-blur required
    // 2. Semi-transparent background (bg-white/10 to bg-white/25, dark:bg-black/40 to dark:bg-white/5)
    // 3. Subtle borders: border-white/20 with specular light gradient
    // 4. Shadow for depth: shadow-xl shadow-primary/10
    // 5. Dark mode variant defined
    final List<Color> surfaceColors;
    if (tint != null) {
      surfaceColors = [
        tint!.withValues(alpha: isDark ? 0.65 : 0.55),
        tint!.withValues(alpha: isDark ? 0.40 : 0.30),
      ];
    } else if (isDark) {
      surfaceColors = [
        const Color(0xFFFFFFFF).withValues(alpha: 0.12),
        const Color(0xFF0F172A).withValues(alpha: 0.45),
      ];
    } else {
      surfaceColors = [
        Colors.white.withValues(alpha: 0.45),
        Colors.white.withValues(alpha: 0.20),
      ];
    }

    final Color shadowBaseColor = primaryColor ?? const Color(0xFF2563EB);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Colored depth shadow: shadow-xl shadow-primary/20
          BoxShadow(
            color: shadowBaseColor.withValues(alpha: isDark ? 0.28 : 0.16),
            blurRadius: 32,
            offset: const Offset(0, 14),
            spreadRadius: -2,
          ),
          // Ambient soft ambient dark shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: surfaceColors,
              ),
              border: showBorder
                  ? Border.all(
                      color:
                          Colors.white.withValues(alpha: isDark ? 0.22 : 0.55),
                      width: 1.2,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A pre-built layered glass stack as described in SKILL.md
class LayeredGlassStack extends StatelessWidget {
  const LayeredGlassStack({
    super.key,
    required this.child,
    this.primaryColor,
  });

  final Widget child;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background layer - most blur (3xl), bg-white/5
        Positioned.fill(
          child: AdvancedGlassPanel(
            blurLevel: GlassBlurLevel.maximum,
            tint: isDark ? const Color(0xFF1E293B) : Colors.white,
            radius: 32,
            primaryColor: primaryColor,
            child: const SizedBox.expand(),
          ),
        ),
        // Middle layer - strong blur (xl), bg-white/10
        Positioned.fill(
          top: 10,
          bottom: 10,
          left: 10,
          right: 10,
          child: AdvancedGlassPanel(
            blurLevel: GlassBlurLevel.strong,
            tint: isDark ? const Color(0xFF334155) : Colors.white,
            radius: 28,
            primaryColor: primaryColor,
            child: const SizedBox.expand(),
          ),
        ),
        // Content layer - medium blur (md), bg-white/20
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: AdvancedGlassPanel(
            blurLevel: GlassBlurLevel.medium,
            tint: isDark ? const Color(0xFF0F172A) : Colors.white,
            radius: 24,
            padding: const EdgeInsets.all(24.0),
            primaryColor: primaryColor,
            child: child,
          ),
        ),
      ],
    );
  }
}
