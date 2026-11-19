// ============================================================================
// ProgressiveCollapseDialog — UFC 4-023-03 & GSA Alternate Load Path Studio
// Sudden Column Loss, Catenary Bridging & Disproportionate Collapse Sweep
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/progressive_collapse_engine.dart';
import 'glass_pod.dart';
import 'info_tooltip.dart';

class ProgressiveCollapseDialog extends StatefulWidget {
  final StructuralModel model;
  final ValueChanged<StructuralModel>? onCommitDamagedModel;
  final ValueChanged<StructuralModel>? onApplyRetrofitModel;

  const ProgressiveCollapseDialog({
    super.key,
    required this.model,
    this.onCommitDamagedModel,
    this.onApplyRetrofitModel,
  });

  @override
  State<ProgressiveCollapseDialog> createState() => _ProgressiveCollapseDialogState();
}

class _ProgressiveCollapseDialogState extends State<ProgressiveCollapseDialog> {
  double _dif = 2.0; // UFC 4-023-03 Dynamic Increase Factor Omega_LD
  late List<ColumnRemovalScenarioResult> _sweepResults;
  ColumnRemovalScenarioResult? _selectedScenario;
  ProgressiveCollapseRetrofitResult? _retrofitResult;

  @override
  void initState() {
    super.initState();
    _runSweep();
  }

  void _runSweep() {
    _sweepResults = ProgressiveCollapseEngine.runVulnerabilitySweep(
      model: widget.model,
      dynamicIncreaseFactor: _dif,
      maxColumns: 14,
    );
    if (_sweepResults.isNotEmpty) {
      if (_selectedScenario != null) {
        _selectedScenario = _sweepResults.firstWhere(
          (r) => r.removedMemberId == _selectedScenario!.removedMemberId,
          orElse: () => _sweepResults.first,
        );
      } else {
        _selectedScenario = _sweepResults.first;
      }
    }
    _retrofitResult = null;
  }

  void _triggerAutoRetrofit() {
    if (_selectedScenario == null) return;
    setState(() {
      _retrofitResult = ProgressiveCollapseEngine.autoRetrofitScenario(
        baselineModel: widget.model,
        scenario: _selectedScenario!,
      );
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ROBUST BRIDGING':
        return const Color(0xFF10B981);
      case 'PLASTIC CATENARY':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _selectedScenario;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: GlassPod(
        width: 960,
        height: 670,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Flexible(
                                  child: Text(
                                    'PROGRESSIVE COLLAPSE & ALTERNATE LOAD PATH STUDIO',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6),
                                InfoTooltip(
                                  title: 'Alternate Load Path (ALP) Analysis',
                                  codeRef: 'UFC 4-023-03 & GSA APM',
                                  message:
                                      'Evaluates structural survivability when a primary vertical load-bearing column is suddenly lost (blast, impact, or localized failure). Checks whether Vierendeel frame action and catenary tension bridge the missing support without disproportionate collapse.',
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'UFC 4-023-03 Extreme Event: Ω_LD(1.2D + 0.5L) • Notional Column Removal & Catenary Bridging',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  tooltip: 'Close Progressive Collapse Studio',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Top Parameter & Summary Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF121927),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Wrap(
                spacing: 20,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'DYNAMIC AMPLIFICATION (Ω_LD):',
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const InfoTooltip(
                        title: 'Dynamic Increase Factor (Ω_LD)',
                        codeRef: 'UFC 4-023-03 Table 3-4',
                        message:
                            'Accounts for instantaneous dynamic shock when a column is suddenly removed. Standard static-equivalent factor is Ω_LD = 2.0 for linear elastic / plastic hinge evaluation of bays directly above the removed column.',
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 150,
                        child: Slider(
                          value: _dif,
                          min: 1.2,
                          max: 2.5,
                          divisions: 13,
                          activeColor: const Color(0xFF00F0FF),
                          onChanged: (v) {
                            setState(() {
                              _dif = v;
                              _runSweep();
                            });
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.45)),
                        ),
                        child: Text(
                          '${_dif.toStringAsFixed(2)}×',
                          style: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (active != null) ...[
                    _buildMiniStat(
                      label: 'REMOVED ELEMENT',
                      value: '${active.removedMemberId} (${active.section})',
                      color: const Color(0xFF00F0FF),
                      tooltipTitle: 'Notionally Removed Column',
                      tooltipCode: 'UFC 4-023-03 §3-2.9',
                      tooltipMsg:
                          'Column temporarily removed from global 12-DOF stiffness matrix [K] to test alternate load paths through overhead beams.',
                    ),
                    _buildMiniStat(
                      label: 'CATENARY DROP Δ_y',
                      value: '${active.catenaryDeflectionMm.toStringAsFixed(1)} mm',
                      color: const Color(0xFFF59E0B),
                      tooltipTitle: 'Double-Span Catenary Drop',
                      tooltipCode: 'GSA APM §4.2',
                      tooltipMsg:
                          'Vertical downward displacement at Joint ${active.upperJointId} directly above the missing column under amplified gravity loads.',
                    ),
                    _buildMiniStat(
                      label: 'CHORD ROTATION θ',
                      value: '${(active.chordRotationRad * 100).toStringAsFixed(2)}% rad',
                      color: active.chordRotationRad <= active.allowableRotationRad
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      tooltipTitle: 'Plastic Hinge Chord Rotation',
                      tooltipCode: 'UFC 4-023-03 Table 4-1',
                      tooltipMsg:
                          'Chord rotation θ = Δ_y / L_bay compared against plastic rotation limit θ_allow = ${(active.allowableRotationRad * 100).toStringAsFixed(1)}% rad.',
                    ),
                    _buildMiniStat(
                      label: 'ROBUSTNESS INDEX',
                      value: '${active.robustnessIndex.toStringAsFixed(1)} / 100',
                      color: _statusColor(active.status),
                      tooltipTitle: 'Structural Robustness Score',
                      tooltipCode: 'ASCE 7-16 §1.4',
                      tooltipMsg:
                          'Composite integrity index (0–100) combining redistributed Demand-Capacity Ratio (DCR_ALP) and catenary rotation reserve.',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Body: Left Column Vulnerability Table + Right Catenary Bridging Visualizer
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Vulnerability Sweep Ranking
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1420),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.format_list_numbered_rounded, size: 15, color: Color(0xFF00F0FF)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'COLUMN REMOVAL VULNERABILITY RANKING',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              InfoTooltip(
                                title: 'Automated Vulnerability Sweep',
                                codeRef: 'UFC 4-023-03 §3-2.9.1',
                                message:
                                    'Ranks every perimeter, corner, and interior column by the peak redistributed DCR when that single column is notionally removed. Click any row to inspect its bridging mechanics.',
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _sweepResults.length,
                              itemBuilder: (ctx, idx) {
                                final item = _sweepResults[idx];
                                final isSel = active?.removedMemberId == item.removedMemberId;
                                final sColor = _statusColor(item.status);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedScenario = item),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? const Color(0xFF00F0FF).withValues(alpha: 0.14)
                                            : const Color(0xFF151D2E),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSel ? const Color(0xFF00F0FF) : Colors.white10,
                                          width: isSel ? 1.3 : 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: sColor.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '#${idx + 1}',
                                              style: TextStyle(
                                                color: sColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Column ${item.removedMemberId} • ${item.section}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '${item.locationClass} • Upper Joint ${item.upperJointId}',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.5),
                                                    fontSize: 9.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'DCR ${item.damagedMaxDcr.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: sColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              Text(
                                                item.status,
                                                style: TextStyle(
                                                  color: sColor.withValues(alpha: 0.85),
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Right: Catenary Bridging Diagram & Detailed Forensic Card
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1420),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: active == null
                          ? const Center(
                              child: Text(
                                'No vertical columns detected in current model.',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.timeline_rounded, size: 15, color: Color(0xFF00F0FF)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'DOUBLE-SPAN CATENARY BRIDGING DIAGRAM (${active.removedMemberId} LOSS)',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    const InfoTooltip(
                                      title: 'Catenary & Vierendeel Action',
                                      codeRef: 'UFC 4-023-03 Fig 3-2',
                                      message:
                                          'Visualizes the double-span bridging mechanism across the removed column. Red dashed column indicates notional loss; cyan/amber curve shows deflected catenary chord and plastic hinge zones.',
                                      size: 14,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF090D15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: CustomPaint(
                                      painter: _CatenaryBridgingPainter(scenario: active),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Forensic Engineering Breakdown
                                Expanded(
                                  flex: 6,
                                  child: SingleChildScrollView(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF141C2B),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _statusColor(active.status).withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  'VERDICT: ${active.status}',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: _statusColor(active.status),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  'Critical Bridging Member: ${active.mostCriticalAdjacentMemberId}',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF00F0FF),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '• Baseline Max DCR: ${active.baselineMaxDcr.toStringAsFixed(3)} → Damaged ALP DCR: ${active.damagedMaxDcr.toStringAsFixed(3)} (${active.overloadedAdjacentMembers} members > 1.0)\n'
                                            '• Bridging Bay Span: ${active.bridgingSpanM.toStringAsFixed(2)} m (2L = ${(active.bridgingSpanM * 2).toStringAsFixed(1)} m double-span catenary)\n'
                                            '• Recommendation: ${active.status == "COLLAPSE RISK" ? "Add perimeter spandrel tie reinforcement or hat-truss outrigger bracing to arrest catenary drop." : "Structure develops sufficient Vierendeel & catenary tie capacity per UFC 4-023-03."}',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.8),
                                              fontSize: 10.5,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          // v4.5 Automated Retrofit & Catenary Tie-Force Action Bar
                                          Row(
                                            children: [
                                              Flexible(
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF00F0FF),
                                                    foregroundColor: Colors.black,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                                                  ),
                                                  icon: const Icon(Icons.auto_fix_high_rounded, size: 15),
                                                  label: const Text(
                                                    'AUTO-RETROFIT & SIZE CATENARY TIES',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                                                  ),
                                                  onPressed: _triggerAutoRetrofit,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const InfoTooltip(
                                                title: 'Automated ALP Retrofit & Catenary Tie Optimizer',
                                                codeRef: 'UFC 4-023-03 §3-1 & Table 4-1',
                                                message:
                                                    'Sizes horizontal internal (Ti), peripheral (Tp), and vertical (Tv) catenary continuity ties per UFC 4-023-03 §3-1 and upgrades double-span bridging girders until θ <= θ_allow and DCR_ALP <= 0.95.',
                                                size: 15,
                                              ),
                                            ],
                                          ),
                                          if (_retrofitResult != null) ...[
                                            const SizedBox(height: 10),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(0xFF10B981).withValues(alpha: 0.55),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Expanded(
                                                        child: Text(
                                                          'UFC 4-023-03 RETROFIT & CATENARY TIE SYNTHESIS COMPLETE',
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            color: Color(0xFF10B981),
                                                            fontSize: 10.5,
                                                            fontWeight: FontWeight.w900,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '+${_retrofitResult!.addedSteelMassKg.toStringAsFixed(1)} kg Retrofit Steel',
                                                        style: const TextStyle(
                                                          color: Color(0xFF00F0FF),
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '• Chord Rotation θ: ${(_retrofitResult!.thetaBeforeRad * 100).toStringAsFixed(2)}% rad → ${(_retrofitResult!.thetaAfterRad * 100).toStringAsFixed(2)}% rad (Limit ≤ ${(_retrofitResult!.allowableRotationRad * 100).toStringAsFixed(1)}% rad)\n'
                                                    '• Required Catenary Tie T_req: ${_retrofitResult!.tieSizing.governingTieDemandKn.toStringAsFixed(1)} kN (Ti=${_retrofitResult!.tieSizing.internalTieReqKn.toStringAsFixed(0)} kN, Tp=${_retrofitResult!.tieSizing.peripheralTieReqKn.toStringAsFixed(0)} kN) → ${_retrofitResult!.tieSizing.recommendedContinuityPlate}\n'
                                                    '• ALP DCR: ${_retrofitResult!.dcrBefore.toStringAsFixed(2)} → ${_retrofitResult!.dcrAfter.toStringAsFixed(2)} • Robustness: ${_retrofitResult!.robustnessBefore.toStringAsFixed(1)} → ${_retrofitResult!.robustnessAfter.toStringAsFixed(1)}/100',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Footer Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      Icon(Icons.verified_user_rounded, size: 15, color: Color(0xFF10B981)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '12-DOF Damaged Stiffness Matrix [K_damaged] Solved Exactly • Ctrl/Cmd+Z Restores Column',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white60, fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CLOSE', style: TextStyle(color: Colors.white70)),
                    ),
                    if (_retrofitResult != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.shield_rounded, size: 15),
                        label: const Text(
                          'APPLY RETROFIT TO 3D FRAME',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                        onPressed: () {
                          final cb = widget.onApplyRetrofitModel ?? widget.onCommitDamagedModel;
                          cb?.call(_retrofitResult!.retrofittedModel);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                    const SizedBox(width: 10),
                    if (active != null && widget.onCommitDamagedModel != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: Text(
                          'SIMULATE ${active.removedMemberId} LOSS IN 3D VIEWPORT',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                        onPressed: () {
                          widget.onCommitDamagedModel!(active.damagedModel);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
    required String tooltipTitle,
    required String tooltipCode,
    required String tooltipMsg,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                InfoTooltip(
                  title: tooltipTitle,
                  codeRef: tooltipCode,
                  message: tooltipMsg,
                  size: 13,
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CatenaryBridgingPainter extends CustomPainter {
  final ColumnRemovalScenarioResult scenario;

  _CatenaryBridgingPainter({required this.scenario});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leftX = w * 0.16;
    final midX = w * 0.50;
    final rightX = w * 0.84;
    final topY = h * 0.28;
    final botY = h * 0.82;

    // Intact side columns
    final colPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(leftX, botY), Offset(leftX, topY), colPaint);
    canvas.drawLine(Offset(rightX, botY), Offset(rightX, topY), colPaint);

    // Undamaged original beam axis (dashed faint)
    final refPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(leftX, topY), Offset(rightX, topY), refPaint);

    // Removed center column (dashed crimson)
    final removedPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 3.0;
    const dashH = 7.0;
    for (double y = topY + 10; y < botY; y += dashH * 2) {
      canvas.drawLine(
        Offset(midX, y),
        Offset(midX, (y + dashH).clamp(topY, botY)),
        removedPaint,
      );
    }

    // Catenary sag at center joint
    final sagNorm = (scenario.catenaryDeflectionMm / 120.0).clamp(0.12, 0.42);
    final dropY = topY + (botY - topY) * sagNorm;

    // Deflected catenary curve
    final catenaryPath = Path()
      ..moveTo(leftX, topY)
      ..quadraticBezierTo(midX * 0.65, dropY, midX, dropY)
      ..quadraticBezierTo(midX + (rightX - midX) * 0.35, dropY, rightX, topY);

    final catPaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(catenaryPath, catPaint);

    // Plastic hinge circles at ends and center
    final hingePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    for (final pt in [Offset(leftX, topY), Offset(midX, dropY), Offset(rightX, topY)]) {
      canvas.drawCircle(pt, 5.5, hingePaint);
    }

    // Labels
    final tp = TextPainter(
      text: TextSpan(
        text: 'Δ_cat = ${scenario.catenaryDeflectionMm.toStringAsFixed(1)} mm  (θ = ${(scenario.chordRotationRad * 100).toStringAsFixed(2)}% rad)',
        style: const TextStyle(
          color: Color(0xFF00F0FF),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(midX - tp.width / 2, dropY + 10));

    final remTp = TextPainter(
      text: TextSpan(
        text: 'REMOVED: ${scenario.removedMemberId}',
        style: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    remTp.paint(canvas, Offset(midX - remTp.width / 2, botY - 18));
  }

  @override
  bool shouldRepaint(covariant _CatenaryBridgingPainter oldDelegate) =>
      oldDelegate.scenario != scenario;
}
