// ============================================================================
// Floating Copyright Watermark & Legal Protection Badge
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// Protected under DMCA 17 U.S.C. § 512(c) and International Copyright Treaties.
// ============================================================================

import 'package:flutter/material.dart';

/// A floating, non-intrusive copyright watermark positioned at the bottom of the
/// viewport. Wraps its visual tree in [IgnorePointer] so touch, mouse, scroll,
/// and click events pass through unobstructed to underlying widgets.
class FloatingCopyrightWatermark extends StatelessWidget {
  /// When true (default) the badge positions itself at the bottom of the
  /// enclosing [Stack]. When false it renders inline so a parent layout
  /// (e.g. a Column of HUD islands) can reserve space and avoid overlap.
  final bool positioned;

  const FloatingCopyrightWatermark({super.key, this.positioned = true});

  static const String ownerName = 'Ali Asghar';
  static const String ownerEmail = 'aliasgharinnocent@yahoo.com';
  static const String appTitle = 'Structura Nexus';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomOffset = media.padding.bottom > 0 ? media.padding.bottom + 4.0 : 6.0;

    final badge = Center(
        child: IgnorePointer(
          ignoring: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              final String textContent;
              if (width >= 640) {
                textContent =
                    '$appTitle © $ownerName · $ownerEmail · All Rights Reserved · DMCA Protected';
              } else if (width >= 420) {
                textContent = '$appTitle © $ownerName · $ownerEmail';
              } else {
                textContent = '© $ownerName · $ownerEmail';
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1F6FEB).withValues(alpha: 0.45),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 11,
                      color: Color(0xFF00F0FF),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        textContent,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.25,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    );

    if (!positioned) return badge;

    return Positioned(
      bottom: bottomOffset,
      left: 16,
      right: 16,
      child: badge,
    );
  }
}
