import 'package:flutter/material.dart';
import 'glass.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdvancedGlassPanel(
      radius: size * 0.32,
      blurLevel: GlassBlurLevel.medium,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            'DN',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: size * 0.36,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}
