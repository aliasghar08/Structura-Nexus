// ============================================================================
// Structura Nexus: Proprietary Concrete Studio & SectionNet-PM P-M Dialog
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'glass_pod.dart';
import '../services/dart_neural_engine.dart';

class ConcretePmDialog extends StatefulWidget {
  final VoidCallback? onOptimizeApplied;
  final Function(String feature, VoidCallback onAuth)? onRequireAuth;

  const ConcretePmDialog({
    super.key,
    this.onOptimizeApplied,
    this.onRequireAuth,
  });

  @override
  State<ConcretePmDialog> createState() => _ConcretePmDialogState();
}

class _ConcretePmDialogState extends State<ConcretePmDialog> {
  double _b = 0.45; // meters
  double _h = 0.60; // meters
  double _fc = 35.0; // MPa
  final double _fy = 420.0; // MPa
  double _rho = 0.022; // Reinforcement ratio
  double _pu = 1200.0; // kN
  double _mu = 280.0; // kN-m

  String _exposureCondition = 'EXTERIOR_MOIST';
  final double _coverMm = 40.0;
  final double _barDiaMm = 25.0;
  final int _numBars = 4;

  bool _showCalibration = false;
  late Map<String, dynamic> _prediction;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  void _recompute() {
    _prediction = DartNeuralEngine.instance.predictConcreteSection(
      b: _b,
      h: _h,
      fc: _fc,
      fy: _fy,
      rho: _rho,
      puKn: _pu,
      muKnm: _mu,
    );
  }

  Map<String, dynamic> _computeCrackServiceability() {
    final bMm = _b * 1000.0;
    final hMm = _h * 1000.0;
    final ab1Mm2 = (math.pi / 4.0) * (_barDiaMm * _barDiaMm);
    final asMm2 = _numBars * ab1Mm2;
    final dMm = hMm - _coverMm - (_barDiaMm / 2.0);

    final ecMpa = 4700.0 * math.sqrt(_fc);
    const esMpa = 200000.0;
    final nRatio = esMpa / ecMpa;
    final rhoVal = asMm2 / (bMm * dMm);

    final rn = rhoVal * nRatio;
    final k = math.sqrt(rn * rn + 2.0 * rn) - rn;
    final kdMm = k * dMm;

    final icrMm4 = (1.0 / 3.0) * bMm * (kdMm * kdMm * kdMm) + nRatio * asMm2 * ((dMm - kdMm) * (dMm - kdMm));
    final igMm4 = (1.0 / 12.0) * bMm * (hMm * hMm * hMm);
    final iEffRatio = icrMm4 / math.max(igMm4, 1.0);

    final msNmm = _mu.abs() * 1e6;
    final fsElastic = (msNmm * (dMm - kdMm) / math.max(icrMm4, 1.0)) * nRatio;
    final fsMpa = math.max(10.0, math.min(fsElastic, (2.0 / 3.0) * _fy));

    final sMaxFormula = 380.0 * (280.0 / fsMpa) - 2.5 * _coverMm;
    final sMaxCap = 300.0 * (280.0 / fsMpa);
    final sMaxMm = math.max(50.0, math.min(sMaxFormula, sMaxCap));

    final sActualMm = math.max(20.0, (bMm - 2.0 * _coverMm - _barDiaMm) / math.max(1, _numBars - 1));
    final spacingDcr = sActualMm / math.max(sMaxMm, 1e-4);

    final dcMm = _coverMm + (_barDiaMm / 2.0);
    final aTensionMm2 = (2.0 * dcMm * bMm) / _numBars;
    var beta = (hMm - kdMm) / math.max(dMm - kdMm, 1.0);
    beta = math.max(1.10, math.min(1.35, beta));

    final wkMm = 0.076 * beta * fsMpa * math.pow(dcMm * aTensionMm2, 1.0 / 3.0) * 1e-3;

    final allowableMap = {
      'INTERIOR_DRY': 0.40,
      'EXTERIOR_MOIST': 0.30,
      'DEICING_SALTS': 0.20,
      'WATER_RETAINING': 0.10,
    };
    final wAllowMm = allowableMap[_exposureCondition] ?? 0.30;
    final crackDcr = wkMm / wAllowMm;
    final isCrackPass = crackDcr <= 1.0 && spacingDcr <= 1.0;

    return {
      'wk_mm': wkMm,
      'w_allow_mm': wAllowMm,
      'crack_dcr': crackDcr,
      's_actual_mm': sActualMm,
      's_max_mm': sMaxMm,
      'spacing_dcr': spacingDcr,
      'fs_mpa': fsMpa,
      'ieff_ratio': iEffRatio,
      'is_crack_pass': isCrackPass,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dcr = (_prediction['governing_dcr'] as num?)?.toDouble() ?? 0.0;
    final isPass = dcr <= 1.0;
    final latency = (_prediction['latency_ms'] as num?)?.toDouble() ?? 0.18;
    final optRhoPct = (_prediction['optimal_rebar_pct'] as num?)?.toDouble() ?? 2.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassPod(
        width: 860,
        height: 640,
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.architecture, color: Color(0xFF00F0FF), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "PROPRIETARY CONCRETE STUDIO",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "SectionNet-PM Neural Surrogate & Fiber Discretization (In-Browser: ${latency.toStringAsFixed(2)} ms)",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _showCalibration = !_showCalibration);
                      },
                      icon: const Icon(Icons.analytics, size: 14, color: Color(0xFF00F0FF)),
                      label: Text(
                        _showCalibration ? "HIDE CALIBRATION" : "NEURAL LOSS CURVE",
                        style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 16),

            // Content Split: Controls on Left, 2D Interaction Diagram on Right
            Expanded(
              child: _showCalibration
                  ? _buildCalibrationView()
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Panel: Sliders & Controls
                        SizedBox(
                          width: 380,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSliderRow(
                                  label: "Width (b)",
                                  value: _b,
                                  min: 0.25,
                                  max: 0.90,
                                  unit: "m",
                                  onChanged: (v) => setState(() { _b = v; _recompute(); }),
                                ),
                                _buildSliderRow(
                                  label: "Height (h)",
                                  value: _h,
                                  min: 0.30,
                                  max: 1.20,
                                  unit: "m",
                                  onChanged: (v) => setState(() { _h = v; _recompute(); }),
                                ),
                                _buildSliderRow(
                                  label: "Concrete f'c",
                                  value: _fc,
                                  min: 20.0,
                                  max: 70.0,
                                  unit: "MPa",
                                  onChanged: (v) => setState(() { _fc = v; _recompute(); }),
                                ),
                                _buildSliderRow(
                                  label: "Rebar Ratio (ρ)",
                                  value: _rho * 100.0,
                                  min: 1.0,
                                  max: 5.0,
                                  unit: "%",
                                  onChanged: (v) => setState(() { _rho = v / 100.0; _recompute(); }),
                                ),
                                const Divider(color: Colors.white12),
                                _buildSliderRow(
                                  label: "Factored Axial (Pu)",
                                  value: _pu,
                                  min: 100.0,
                                  max: 4500.0,
                                  unit: "kN",
                                  onChanged: (v) => setState(() { _pu = v; _recompute(); }),
                                ),
                                _buildSliderRow(
                                  label: "Factored Moment (Mu)",
                                  value: _mu,
                                  min: 20.0,
                                  max: 900.0,
                                  unit: "kN-m",
                                  onChanged: (v) => setState(() { _mu = v; _recompute(); }),
                                ),
                                const SizedBox(height: 12),

                                // AI Auto-Optimization Pill
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F6FEB).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF1F6FEB).withValues(alpha: 0.4)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Expanded(
                                            child: Text(
                                              "NEURAL REBAR RECOMMENDATION",
                                              style: TextStyle(color: Color(0xFF58A6FF), fontSize: 10.5, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${optRhoPct.toStringAsFixed(2)}%",
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Optimal longitudinal reinforcement to target DCR ≈ 0.85 under applied (Pu, Mu).",
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          if (widget.onRequireAuth != null) {
                                            widget.onRequireAuth!("Concrete Neural Optimizer", () {
                                              setState(() {
                                                _rho = optRhoPct / 100.0;
                                                _recompute();
                                              });
                                            });
                                          } else {
                                            setState(() {
                                              _rho = optRhoPct / 100.0;
                                              _recompute();
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.black),
                                        label: const Text(
                                          "APPLY OPTIMAL REBAR",
                                          style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00F0FF),
                                          minimumSize: const Size(double.infinity, 36),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Right Panel: 2D P-M Interaction Diagram Canvas
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (isPass ? const Color(0xFF3FB950) : const Color(0xFFF85149)).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: isPass ? const Color(0xFF3FB950) : const Color(0xFFF85149)),
                                          ),
                                          child: Text(
                                            isPass ? "PASS (DCR ${dcr.toStringAsFixed(2)})" : "OVERSTRESSED (DCR ${dcr.toStringAsFixed(2)})",
                                            style: TextStyle(
                                              color: isPass ? const Color(0xFF3FB950) : const Color(0xFFF85149),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            "ACI 318-19 Envelope",
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "φPn(max): ${(_prediction['max_phi_pn_kn'] as num?)?.toStringAsFixed(0)} kN",
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CustomPaint(
                                      painter: InteractionEnvelopePainter(
                                        curvePoints: (_prediction['curve_points'] as List<dynamic>?)
                                                ?.map((e) => Map<String, double>.from(
                                                    (e as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))))
                                                .toList() ??
                                            [],
                                        demandPu: _pu,
                                        demandMu: _mu,
                                        isPass: isPass,
                                      ),
                                      child: Container(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // ACI 318-19 §24.3.2 / ACI 224R Crack Serviceability Control Panel
                              _buildCrackServiceabilityCard(_computeCrackServiceability()),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrackServiceabilityCard(Map<String, dynamic> crack) {
    final isCrackPass = crack['is_crack_pass'] as bool;
    final wkMm = crack['wk_mm'] as double;
    final wAllowMm = crack['w_allow_mm'] as double;
    final sActualMm = crack['s_actual_mm'] as double;
    final sMaxMm = crack['s_max_mm'] as double;
    final iEff = crack['ieff_ratio'] as double;
    const condOptions = ['INTERIOR_DRY', 'EXTERIOR_MOIST', 'DEICING_SALTS', 'WATER_RETAINING'];

    final statusColor = isCrackPass ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161E2E).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Color(0xFF00F0FF), size: 14),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "ACI 318-19 §24.3.2 / ACI 224R CRACK CONTROL",
                        style: TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  isCrackPass ? "PASS / VERIFIED" : "EXCEEDS LIMIT",
                  style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                "Crack Width wk: ${wkMm.toStringAsFixed(3)} mm (≤ ${wAllowMm.toStringAsFixed(2)} mm)",
                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
              Text(
                "Bar Spacing s: ${sActualMm.toStringAsFixed(0)} mm (≤ ${sMaxMm.toStringAsFixed(0)} mm)",
                style: const TextStyle(color: Colors.white70, fontSize: 10.5),
              ),
              Text(
                "I_eff / I_g: ${iEff.toStringAsFixed(2)}",
                style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            children: condOptions.map((cond) {
              final isSel = _exposureCondition == cond;
              return InkWell(
                onTap: () => setState(() => _exposureCondition = cond),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF00F0FF) : const Color(0xFF0B101B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSel ? const Color(0xFF00F0FF) : Colors.white24),
                  ),
                  child: Text(
                    cond.replaceAll('_', ' '),
                    style: TextStyle(
                      color: isSel ? Colors.black : Colors.white70,
                      fontSize: 8.5,
                      fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationView() {
    final history = DartNeuralEngine.instance.sectionNetHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SectionNet-PM Training Convergence & Calibration (PyTorch / ADAMW)",
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Trained on 400+ analytical non-linear fiber section integrations. Loss decreased from 0.42 to 0.073.",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: ListView.separated(
              itemCount: history.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, idx) {
                final item = history[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Epoch ${item['epoch']}", style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 12, fontWeight: FontWeight.bold)),
                      Text("Total Loss: ${item['total_loss']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text("Envelope MSE: ${item['envelope_loss']}", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                      Text("Telemetry MSE: ${item['telemetry_loss']}", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold)),
              Text("${value.toStringAsFixed(value < 10 ? 2 : 0)} $unit", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: const Color(0xFF00F0FF),
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class InteractionEnvelopePainter extends CustomPainter {
  final List<Map<String, double>> curvePoints;
  final double demandPu;
  final double demandMu;
  final bool isPass;

  InteractionEnvelopePainter({
    required this.curvePoints,
    required this.demandPu,
    required this.demandMu,
    required this.isPass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (curvePoints.isEmpty) return;

    final pad = 40.0;
    final w = size.width - 2 * pad;
    final h = size.height - 2 * pad;

    double maxM = 100.0;
    double maxP = 1000.0;
    for (final pt in curvePoints) {
      if (pt['phi_mn_knm']! > maxM) maxM = pt['phi_mn_knm']!;
      if (pt['phi_pn_kn']! > maxP) maxP = pt['phi_pn_kn']!;
    }
    maxM = math.max(maxM, demandMu * 1.25);
    maxP = math.max(maxP, demandPu * 1.25);

    // Axes
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    final originX = pad;
    final originY = pad + h * 0.85;

    canvas.drawLine(Offset(originX, originY), Offset(originX + w, originY), axisPaint);
    canvas.drawLine(Offset(originX, pad), Offset(originX, pad + h), axisPaint);

    // Envelope Path
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < curvePoints.length; i++) {
      final pt = curvePoints[i];
      final m = pt['phi_mn_knm']!;
      final p = pt['phi_pn_kn']!;

      final px = originX + (m / maxM) * w;
      final py = originY - (p / maxP) * (h * 0.80);

      if (i == 0) {
        path.moveTo(px, py);
        fillPath.moveTo(px, py);
      } else {
        path.lineTo(px, py);
        fillPath.lineTo(px, py);
      }
    }

    fillPath.lineTo(originX, originY);
    fillPath.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // Demand Point (Mu, Pu)
    final dX = originX + (demandMu / maxM) * w;
    final dY = originY - (demandPu / maxP) * (h * 0.80);

    final demandColor = isPass ? const Color(0xFF3FB950) : const Color(0xFFF85149);
    final demandPaint = Paint()
      ..color = demandColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dX, dY), 6.0, demandPaint);
    canvas.drawCircle(
      Offset(dX, dY),
      10.0,
      Paint()
        ..color = demandColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant InteractionEnvelopePainter oldDelegate) {
    return oldDelegate.demandPu != demandPu || oldDelegate.demandMu != demandMu;
  }
}
