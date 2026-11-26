// ============================================================================
// Structura Nexus: Welcome Quick-Start Card Overlay
// Clean, non-blocking visionOS GlassPod offering 4 plain-English quick-launch paths
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../services/workspace_storage.dart';
import 'glass_pod.dart';

class WelcomeQuickstartOverlay extends StatefulWidget {
  final VoidCallback onExploreSamples;
  final VoidCallback onVisionToBim;
  final VoidCallback onStartGuidedBuild;
  final VoidCallback onAutoOptimizeAndReport;
  final VoidCallback onDismiss;
  final VoidCallback? onOpenShortcuts;

  const WelcomeQuickstartOverlay({
    super.key,
    required this.onExploreSamples,
    required this.onVisionToBim,
    required this.onStartGuidedBuild,
    required this.onAutoOptimizeAndReport,
    required this.onDismiss,
    this.onOpenShortcuts,
  });

  @override
  State<WelcomeQuickstartOverlay> createState() => _WelcomeQuickstartOverlayState();
}

class _WelcomeQuickstartOverlayState extends State<WelcomeQuickstartOverlay> {
  bool _dontShowAgain = false;

  void _handleDismiss() {
    if (_dontShowAgain) {
      WorkspacePreferences.setBool('hide_welcome_quickstart', true);
    }
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 768;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isCompact ? size.width * 0.94 : 840,
            maxHeight: size.height * 0.90,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: GlassPod(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            borderRadius: 24,
            glowColor: const Color(0xFF00F0FF).withValues(alpha: 0.25),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00F0FF), Color(0xFF0072FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.architecture_rounded, color: Colors.black, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  "WELCOME TO STRUCTURA NEXUS",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    "v4.8 ESSENTIAL",
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "What would you like to design or analyze today? Choose a path below to get started immediately:",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _handleDismiss,
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                        tooltip: 'Dismiss Welcome Card',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4 Big Plain-English 1-Click Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useTwoCols = constraints.maxWidth >= 600;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: useTwoCols ? 2 : 1,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: useTwoCols ? 2.3 : 2.8,
                        children: [
                          _buildActionCard(
                            title: "Explore 24 Sample Structures",
                            subtitle: "Browse certified commercial high-rises, bridges, warehouses & code benchmarks",
                            badge: "24 ARCHETYPES",
                            badgeColor: const Color(0xFF00F0FF),
                            icon: Icons.apartment_rounded,
                            onTap: () {
                              _handleDismiss();
                              widget.onExploreSamples();
                            },
                          ),
                          _buildActionCard(
                            title: "Convert 2D Floorplan to 3D",
                            subtitle: "Upload architectural blueprint (PDF/PNG) to auto-synthesize column grids & beams",
                            badge: "VISION-TO-BIM",
                            badgeColor: const Color(0xFF38BDF8),
                            icon: Icons.document_scanner_rounded,
                            onTap: () {
                              _handleDismiss();
                              widget.onVisionToBim();
                            },
                          ),
                          _buildActionCard(
                            title: "Start Guided Step-by-Step Build",
                            subtitle: "Follow interactive 4-stage guide: place joints, draw beams, assign supports & solve",
                            badge: "GUIDE ME",
                            badgeColor: const Color(0xFF10B981),
                            icon: Icons.route_rounded,
                            onTap: () {
                              _handleDismiss();
                              widget.onStartGuidedBuild();
                            },
                          ),
                          _buildActionCard(
                            title: "Auto-Optimize Steel & PE Report",
                            subtitle: "Load commercial tower, minimize steel tonnage with AI & preview signed calculation packet",
                            badge: "AISC AUTO-SIZER",
                            badgeColor: const Color(0xFFF59E0B),
                            icon: Icons.auto_awesome_rounded,
                            onTap: () {
                              _handleDismiss();
                              widget.onAutoOptimizeAndReport();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // Bottom Footer: "Don't show again" + Keyboard Shortcuts Hint
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _dontShowAgain,
                              onChanged: (val) => setState(() => _dontShowAgain = val ?? false),
                              activeColor: const Color(0xFF00F0FF),
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.white38),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                            child: const Text(
                              "Don't show on startup",
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onOpenShortcuts != null)
                            TextButton.icon(
                              onPressed: () {
                                _handleDismiss();
                                widget.onOpenShortcuts!();
                              },
                              icon: const Icon(Icons.keyboard_rounded, size: 14, color: Color(0xFF00F0FF)),
                              label: const Text(
                                "Keyboard Shortcuts (?)",
                                style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _handleDismiss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF21262D),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Enter Canvas", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF121927).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, color: badgeColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 0.6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded, color: badgeColor.withValues(alpha: 0.7), size: 13),
          ],
        ),
      ),
    );
  }
}
