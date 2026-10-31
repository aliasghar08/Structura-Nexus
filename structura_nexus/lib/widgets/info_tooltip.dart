// ============================================================================
// InfoTooltip — High-Contrast Accessible Engineering Tooltip
// Overrides default transparent theme for crisp readability over 3D WebGL
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';

class InfoTooltip extends StatelessWidget {
  final String message;
  final double size;
  final Color? iconColor;

  const InfoTooltip({
    super.key,
    required this.message,
    this.size = 18.0,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? const Color(0xFF00F0FF);
    return Tooltip(
      message: message,
      waitDuration: Duration.zero,
      showDuration: const Duration(seconds: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2638), // High-contrast solid dark gray
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.2,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.help,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Icon(
              Icons.info_outline,
              size: size,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

