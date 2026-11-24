// ============================================================================
// NextStepPromptBanner — Contextual Post-Action VisionOS Next-Step Action Pill
// Anchored cleanly above FloatingTelemetryDock with 1-click workflow progression
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../services/workspace_storage.dart';
import 'glass_pod.dart';

class NextStepPromptData {
  final String message;
  final String actionLabel;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onAction;

  const NextStepPromptData({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.auto_awesome_rounded,
    this.accentColor = const Color(0xFF00F0FF),
  });
}

class NextStepPromptBanner extends StatelessWidget {
  final NextStepPromptData prompt;
  final VoidCallback onDismiss;

  const NextStepPromptBanner({
    super.key,
    required this.prompt,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => WorkspacePreferences.freezeOrbit(true),
      onExit: (_) => WorkspacePreferences.freezeOrbit(false),
      child: GlassPod(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        borderRadius: 18,
        glowColor: prompt.accentColor.withValues(alpha: 0.35),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: prompt.accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: prompt.accentColor.withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Icon(prompt.icon, size: 15, color: prompt.accentColor),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                prompt.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: prompt.onAction,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: prompt.accentColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: prompt.accentColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prompt.actionLabel,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 15, color: Colors.white54),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              tooltip: 'Dismiss Next-Step Prompt',
            ),
          ],
        ),
      ),
    );
  }
}
