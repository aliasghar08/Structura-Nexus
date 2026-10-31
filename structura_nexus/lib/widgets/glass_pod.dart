// ============================================================================
// GlassPod — Apple / visionOS Specular Glassmorphism Card
// Multi-pass blur, dual rim-light border gradient, and soft elevation
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassPod extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blurSigma;
  final Color baseColor;
  final double opacity;
  final Color? glowColor;
  final VoidCallback? onTap;

  const GlassPod({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 22.0,
    this.blurSigma = 24.0,
    this.baseColor = const Color(0xFF0B101B),
    this.opacity = 0.92,
    this.glowColor,
    this.onTap,
  });

  /// Reusable semi-transparent specular divider for functional row separation
  static Widget divider({double height = 20, Color? color}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: height / 2),
      height: 1.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color ?? Colors.white.withValues(alpha: 0.18),
            color ?? Colors.white.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.12, 0.88, 1.0],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pod = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor?.withValues(alpha: 0.25) ?? Colors.black.withValues(alpha: 0.40),
            blurRadius: glowColor != null ? 24 : 35,
            spreadRadius: glowColor != null ? 1 : -4,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: Colors.white.withValues(alpha: 0.06),
            highlightColor: Colors.white.withValues(alpha: 0.03),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                // Layered background with top specular highlight
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    baseColor.withValues(alpha: opacity),
                    baseColor.withValues(alpha: (opacity + 0.1).clamp(0.0, 1.0)),
                  ],
                  stops: const [0.0, 0.25, 1.0],
                ),
                // Apple-style bevel border (light top, dark bottom)
                border: Border.all(
                  width: 1.5,
                  color: Colors.white.withValues(alpha: 0.30),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (width != null && width! >= 480 && width!.isFinite) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final needsScale = (constraints.maxWidth.isFinite && constraints.maxWidth < width!) ||
              (height != null && height!.isFinite && constraints.maxHeight.isFinite && constraints.maxHeight < height!);
          if (!needsScale) return pod;
          return FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: SizedBox(
              width: width,
              height: height,
              child: pod,
            ),
          );
        },
      );
    }

    return pod;
  }
}
