// ============================================================================
// FloatingTelemetryDock — Floating Glass Island Telemetry HUD
// Staggered spring physics (Curves.easeOutBack), DCR indicators & ASCE 7 combos
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'glass_pod.dart';
import 'info_tooltip.dart';
import '../services/workspace_storage.dart';

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
  final VoidCallback? onParetoPressed;
  final bool isEssentialMode;

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
    this.onParetoPressed,
    this.isEssentialMode = false,
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
    final isCompact = MediaQuery.sizeOf(context).width < 700;
    final podPadding = isCompact ? const EdgeInsets.all(11) : const EdgeInsets.all(16);

    return MouseRegion(
      onEnter: (_) => WorkspacePreferences.freezeOrbit(true),
      onExit: (_) => WorkspacePreferences.freezeOrbit(false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (_) {},
        child: Padding(
          padding: EdgeInsets.only(
            left: isCompact ? 10 : 20,
            right: isCompact ? 10 : 20,
            bottom: isCompact ? 34 : 28,
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) => true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              clipBehavior: Clip.none,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 1. AISC 360-16 Governing DCR Capsule
            _buildStaggeredPod(
              index: 0,
              width: isCompact ? 255 : 270,
              child: GlassPod(
                padding: podPadding,
                borderRadius: 22,
                glowColor: statusColor.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.isEssentialMode ? "MAX STRESS (DCR)" : "AISC 360-16",
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const InfoTooltip(
                                title: 'Governing Demand-Capacity Ratio (DCR)',
                                standardOrRange:
                                    'AISC 360-16 Eq. H1-1a | ≤ 0.70: Under-utilized | 0.70–0.95: Optimal | > 1.00: Overstressed (Fail)',
                                description:
                                    'Ratio of factored axial + biaxial bending demand (Pu, Mux, Muy) to LRFD design strength (φPn, φMnx, φMny). Values > 1.00 require section upsizing.',
                                size: 13,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 0.8),
                          ),
                          child: Text(
                            widget.isEssentialMode
                                ? (widget.failCount > 0 ? "FAIL" : (widget.warnCount > 0 ? "WARNING" : "SAFE"))
                                : (widget.isPass ? "PASSED" : "OVERSTRESSED"),
                            style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.bold),
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
              width: 295,
              child: GlassPod(
                padding: podPadding,
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "ASCE 7-16 LOAD COMBINATIONS",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const InfoTooltip(
                          title: 'LRFD Factored Load Combinations',
                          codeRef: 'ASCE 7-16 §2.3.1',
                          message:
                              'Switches active factored load combination across the 3D frame:\n• 1.4D: Dead load only\n• 1.2D+1.6L: Gravity Dead + Live\n• 1.2D+1.0W+0.5L: Directional Wind Sway\n• 1.2D+1.0E+0.2S: Seismic ELF Lateral.',
                          size: 12.5,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildLoadPill(
                          "1.4D",
                          "Dead",
                          widget.activeLoadCombination == "1.4D",
                          codeRef: "ASCE 7-16 §2.3.1-1",
                          formula: "U = 1.4 D",
                          description: "Dead load alone. Governs during erection and for structural members with zero live load occupancy.",
                        ),
                        _buildLoadPill(
                          "1.2D+1.6L",
                          "Gravity Live",
                          widget.activeLoadCombination == "1.2D+1.6L",
                          codeRef: "ASCE 7-16 §2.3.1-2",
                          formula: "U = 1.2 D + 1.6 L + 0.5 (Lr or S or R)",
                          description: "Maximum factored gravity combination. Governs flexural floor beams and primary gravity column axial loads.",
                        ),
                        _buildLoadPill(
                          "1.2D+1.0W+0.5L",
                          "Wind Sway",
                          widget.activeLoadCombination.contains("1.0W"),
                          codeRef: "ASCE 7-16 §2.3.1-4",
                          formula: "U = 1.2 D + 1.0 W + 0.5 L + 0.5 (Lr or S or R)",
                          description: "Directional lateral wind pressure with tributary gravity. Governs lateral story drift and overturning moment.",
                        ),
                        _buildLoadPill(
                          "1.2D+1.0E+0.2S",
                          "Seismic",
                          widget.activeLoadCombination.contains("1.0E"),
                          codeRef: "ASCE 7-16 §2.3.1-5",
                          formula: "U = (1.2 + 0.2 S_DS) D + ρ Q_E + 0.5 L + 0.2 S",
                          description: "Equivalent lateral seismic force ELF combination including vertical earthquake acceleration effects.",
                        ),
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
              width: 285,
              child: GlassPod(
                padding: podPadding,
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _metricSnippet(
                            "BASE SHEAR",
                            "${widget.baseShearKn.toStringAsFixed(1)} kN",
                            title: "ASCE 7-16 Seismic & Wind Base Shear (V_b)",
                            codeRef: "ASCE 7-16 §12.8.1",
                            formula: "V_b = C_s · W = (S_DS / (R / I_e)) · W",
                            standardOrRange: "Total Base Reaction ΣR_x + ΣR_z",
                            tooltip:
                                "Total horizontal reaction ΣVx + ΣVz at base supports resisting wind and seismic lateral forces (ASCE 7-16 §12.8).",
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _metricSnippet(
                            "DRIFT RATIO",
                            "${(widget.driftRatio * 100).toStringAsFixed(3)}%",
                            title: "ASCE 7-16 Inter-Story Drift Ratio (Δ / h)",
                            codeRef: "ASCE 7-16 Table 12.12-1",
                            formula: "Δ = C_d · δ_e / I_e  |  Ratio = Δ / h_sx",
                            standardOrRange: "Seismic: ≤ 2.0% (0.020 h) | Wind: ≤ 0.25% (H/400)",
                            tooltip:
                                "Peak inter-story lateral drift ratio Δ/h. ASCE 7-16 Table 12.12-1 typically limits drift to 0.25% (H/400) for wind and 2.0% for seismic.",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onAutoSizerPressed,
                            icon: const Icon(Icons.auto_awesome, size: 13, color: Colors.black),
                            label: const Text(
                              "AI SECTION AUTO-SIZER",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F0FF),
                              foregroundColor: Colors.black,
                              minimumSize: const Size(0, 36),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const InfoTooltip(
                          title: "Neural SIMP Multi-Objective Auto-Sizer",
                          codeRef: "AISC 360-16 LRFD",
                          formula: "min Σ(ρ·A_i·L_i)  s.t.  DCR_i ≤ 0.95",
                          standardOrRange: "AISC W-Shapes & HSS | 0.70–0.95 Zone",
                          message:
                              "Iteratively evaluates standard AISC hot-rolled profiles using neural cross-section surrogate networks to minimize structural steel mass and carbon.",
                          size: 13,
                        ),
                        if (widget.isEssentialMode) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: widget.onStabilityPressed,
                            mouseCursor: SystemMouseCursors.click,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F6FEB).withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.45)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shield_outlined, size: 13, color: Color(0xFF00F0FF)),
                                  const SizedBox(width: 4),
                                  Text(
                                    "α_cr: ${widget.alphaCr > 0 ? widget.alphaCr.toStringAsFixed(1) : '—'}",
                                    style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const InfoTooltip(
                            title: 'Stability & Buckling Safety (α_cr / B_2)',
                            codeRef: 'AISC 360-16 App. 8',
                            message:
                                'Click to open Lateral Stability studio for 12×12 [Kg] eigenvalue buckling and second-order sway amplification.',
                            size: 13,
                          ),
                        ] else if (widget.onParetoPressed != null) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: widget.onParetoPressed,
                            mouseCursor: SystemMouseCursors.click,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F6FEB).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.hub_rounded, size: 14, color: Color(0xFF00F0FF)),
                                  SizedBox(width: 4),
                                  Text(
                                    "PARETO",
                                    style: TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const InfoTooltip(
                            title: "WebGPU Multi-Objective Pareto Frontier",
                            codeRef: "NSGA-II Non-Dominated Sorting",
                            formula: "Pareto Front: Mass (kg) vs CO₂e vs Drift (mm)",
                            standardOrRange: "GPU Parallel Compute Shaders",
                            message:
                                "Interactive 3D non-dominated trade-off exploration balancing structural steel mass (kg), embodied carbon footprint (kg CO2e), and lateral story drift (mm).",
                            size: 13,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4. Lateral & Stability Glass Pod (Shown in Pro Suite Mode)
            if (!widget.isEssentialMode) ...[
              const SizedBox(width: 14),
              _buildStaggeredPod(
                index: 3,
                width: 275,
                child: GlassPod(
                  padding: podPadding,
                  borderRadius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _metricSnippet(
                              "α_cr BUCKLING",
                              widget.alphaCr > 0 ? widget.alphaCr.toStringAsFixed(2) : "—",
                              title: "Elastic Critical Buckling Factor (α_cr)",
                              codeRef: "AISC 360-16 App. 8",
                              formula: "det([K_e] + α_cr · [K_g]) = 0",
                              standardOrRange: "α_cr ≥ 10.0: First-Order Valid | α_cr < 10.0: Second-Order P-Δ Mandatory",
                              tooltip:
                                  "Elastic critical buckling load multiplier det([Ke] + α_cr[Kg]) = 0. Values < 10.0 indicate second-order P-Delta sway sensitivity.",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _metricSnippet(
                              "B2 SWAY AMP",
                              widget.b2Amp.toStringAsFixed(2),
                              title: "Second-Order Sway Amplification (B_2)",
                              codeRef: "AISC 360-16 Eq. A-8-4",
                              formula: "B_2 = 1 / (1 - 1 / α_cr)  |  B_2 ≤ 1.50 Limit",
                              standardOrRange: "AISC Limit: B_2 ≤ 1.50 | Optimal: B_2 ≤ 1.20",
                              tooltip:
                                  "Second-order P-Δ sway moment amplification factor B2 = 1 / (1 - 1/α_cr) per AISC 360-16 Appendix 8.",
                            ),
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
          ],
        ),
      ),
    ),
    ),
    ),
    );
  }

  Widget _metricSnippet(
    String label,
    String val, {
    String? tooltip,
    String? title,
    String? codeRef,
    String? formula,
    String? standardOrRange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            if (tooltip != null) ...[
              const SizedBox(width: 3),
              InfoTooltip(
                title: title,
                codeRef: codeRef,
                formula: formula,
                standardOrRange: standardOrRange,
                message: tooltip,
                size: 12,
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLoadPill(
    String title,
    String subtitle,
    bool isSelected, {
    String? codeRef,
    String? formula,
    String? description,
  }) {
    final pill = InkWell(
      onTap: () => widget.onCombinationChanged(title),
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.04),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    const Color(0xFF1F6FEB).withValues(alpha: 0.70),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          "$title  $subtitle",
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );

    if (codeRef != null) {
      return InfoTooltip.wrap(
        title: "ASCE 7-16 Combination: $title ($subtitle)",
        codeRef: codeRef,
        formula: formula,
        message: description ?? title,
        child: pill,
      );
    }
    return pill;
  }
}
