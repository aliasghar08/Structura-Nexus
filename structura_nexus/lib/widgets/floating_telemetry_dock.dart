// ============================================================================
// FloatingTelemetryDock — Floating Glass Island Telemetry HUD
// Staggered spring physics (Curves.easeOutBack), DCR indicators & ASCE 7 combos
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'glass_pod.dart';

class FloatingTelemetryDock extends StatefulWidget {
  final double maxDcr;
  final bool isPass;
  final int passCount;
  final int warnCount;
  final int failCount;
  final double baseShearKn;
  final double driftRatio;
  final double alphaCr;
  final double b2Amp;
  final String activeLoadCombination;
  final ValueChanged<String> onCombinationChanged;
  final VoidCallback onAutoSizerPressed;
  final VoidCallback onStabilityPressed;

  const FloatingTelemetryDock({
    super.key,
    required this.maxDcr,
    required this.isPass,
    this.passCount = 0,
    this.warnCount = 0,
    this.failCount = 0,
    required this.baseShearKn,
    required this.driftRatio,
    required this.alphaCr,
    required this.b2Amp,
    this.activeLoadCombination = '1.2D+1.6L',
    required this.onCombinationChanged,
    required this.onAutoSizerPressed,
    required this.onStabilityPressed,
  });

  @override
  State<FloatingTelemetryDock> createState() => _FloatingTelemetryDockState();
}

class _FloatingTelemetryDockState extends State<FloatingTelemetryDock>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredPod({
    required int index,
    required Widget child,
    double? width,
  }) {
    final double start = (index * 0.12).clamp(0.0, 0.7);
    final double end = (start + 0.45).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _animController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: SizedBox(width: width, child: child),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isPass ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 28),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 1. AISC 360-16 Governing DCR Capsule
            _buildStaggeredPod(
              index: 0,
              width: 245,
              child: GlassPod(
                borderRadius: 24,
                glowColor: statusColor.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "AISC 360-16",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 0.8),
                          ),
                          child: Text(
                            widget.isPass ? "PASSED" : "OVERSTRESSED",
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            widget.maxDcr.toStringAsFixed(3),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "MAX DCR",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (widget.maxDcr / 1.0).clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${widget.passCount} Pass  •  ${widget.warnCount} Warn  •  ${widget.failCount} Fail",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 2. ASCE 7-16 Load Combinations Glass Island
            _buildStaggeredPod(
              index: 1,
              width: 300,
              child: GlassPod(
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "ASCE 7-16 LOAD COMBINATIONS",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildLoadPill("1.4D", "Dead", widget.activeLoadCombination == "1.4D"),
                        _buildLoadPill("1.2D+1.6L", "Gravity Live", widget.activeLoadCombination == "1.2D+1.6L"),
                        _buildLoadPill("1.2D+1.0W+0.5L", "Wind Sway", widget.activeLoadCombination.contains("1.0W")),
                        _buildLoadPill("1.2D+1.0E+0.2S", "Seismic", widget.activeLoadCombination.contains("1.0E")),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 3. Telemetry & Quick Action Auto-Sizer
            _buildStaggeredPod(
              index: 2,
              width: 290,
              child: GlassPod(
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _metricSnippet("BASE SHEAR", "${widget.baseShearKn.toStringAsFixed(1)} kN"),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _metricSnippet("DRIFT RATIO", "${(widget.driftRatio * 100).toStringAsFixed(3)}%"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: widget.onAutoSizerPressed,
                      icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.black),
                      label: const Text(
                        "AI SECTION AUTO-SIZER",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F0FF),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 38),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // 4. Lateral & Stability Glass Pod
            _buildStaggeredPod(
              index: 3,
              width: 280,
              child: GlassPod(
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _metricSnippet("α_cr BUCKLING", widget.alphaCr > 0 ? widget.alphaCr.toStringAsFixed(2) : "—"),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _metricSnippet("B2 SWAY AMP", widget.b2Amp.toStringAsFixed(2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: widget.onStabilityPressed,
                      icon: const Icon(Icons.grain, size: 14, color: Color(0xFF00F0FF)),
                      label: const Text(
                        "ASCE 7 & P-Δ ENGINE",
                        style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.5), width: 1.0),
                        minimumSize: const Size(double.infinity, 38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricSnippet(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLoadPill(String title, String subtitle, bool isSelected) {
    return InkWell(
      onTap: () => widget.onCombinationChanged(title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F6FEB).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF58A6FF) : Colors.white.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
