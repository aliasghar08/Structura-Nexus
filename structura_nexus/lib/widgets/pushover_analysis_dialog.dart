// ============================================================================
// Structura Nexus: Non-Linear Static Pushover & Performance Studio (ASCE 41-17)
// Capacity Spectrum Method (ATC-40 ADRS), Plastic Hinging & Damage States
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'glass_pod.dart';
import '../services/structural_api_service.dart';

class PushoverAnalysisDialog extends StatefulWidget {
  final VoidCallback? onOptimizeApplied;
  final Function(String feature, VoidCallback onAuth)? onRequireAuth;

  const PushoverAnalysisDialog({
    super.key,
    this.onOptimizeApplied,
    this.onRequireAuth,
  });

  @override
  State<PushoverAnalysisDialog> createState() => _PushoverAnalysisDialogState();
}

class _PushoverAnalysisDialogState extends State<PushoverAnalysisDialog> {
  final StructuralApiService _api = StructuralApiService();

  double _heightM = 24.0;
  final int _numStories = 6;
  double _weightKn = 12000.0;
  double _sds = 1.05;
  double _sd1 = 0.62;
  final String _lateralSystem = "STEEL_SMF";

  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _runPushover();
  }

  void _runPushover() async {
    final res = await _api.runNonlinearPushoverAnalysis(
      buildingHeightM: _heightM,
      numStories: _numStories,
      seismicWeightKn: _weightKn,
      spectralSds: _sds,
      spectralSd1: _sd1,
      lateralSystem: _lateralSystem,
      targetDriftRatio: 0.020,
    );
    if (mounted) {
      setState(() {
        _result = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfLevel = _result?['performance_level']?.toString() ?? "IMMEDIATE OCCUPANCY (IO)";
    final perfDesc = _result?['performance_description']?.toString() ?? "Minor hairline yielding in beam plastic hinges. Structure retains 98% stiffness.";
    final t1 = (_result?['fundamental_period_t1_s'] as num?)?.toDouble() ?? 1.25;
    final peakShear = (_result?['peak_base_shear_kn'] as num?)?.toDouble() ?? 2450.0;
    final curvePoints = (_result?['pushover_curve'] as List<dynamic>?) ?? [];
    final perfPoint = _result?['performance_point'] as Map<String, dynamic>?;
    final perfDriftMm = (perfPoint?['roof_drift_mm'] as num?)?.toDouble() ?? 165.0;
    final perfSaG = (perfPoint?['spectral_acceleration_sa_g'] as num?)?.toDouble() ?? 0.504;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassPod(
        width: 900,
        height: 680,
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.stacked_line_chart_rounded, color: Color(0xFF00F0FF), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "NON-LINEAR PUSHOVER & PBEE STUDIO",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        Text(
                          "ASCE 41-17 Performance States • ATC-40 ADRS Capacity Spectrum",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),

            // Performance Classification Banner
            GlassPod(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 14,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      perfLevel,
                      style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      perfDesc,
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Content Area
            Expanded(
              child: Row(
                children: [
                  // Left Control Column
                  SizedBox(
                    width: 300,
                    child: ListView(
                      padding: const EdgeInsets.only(right: 14),
                      children: [
                        _sliderParam("Building Height (H)", "${_heightM.toStringAsFixed(0)} m", _heightM, 10, 100, (v) {
                          setState(() => _heightM = v);
                          _runPushover();
                        }),
                        _sliderParam("Seismic Weight (W)", "${(_weightKn / 1000).toStringAsFixed(0)} MN", _weightKn, 2000, 50000, (v) {
                          setState(() => _weightKn = v);
                          _runPushover();
                        }),
                        _sliderParam("Short Spectral (SDS)", "${_sds.toStringAsFixed(2)} g", _sds, 0.2, 2.0, (v) {
                          setState(() => _sds = v);
                          _runPushover();
                        }),
                        _sliderParam("1-Sec Spectral (SD1)", "${_sd1.toStringAsFixed(2)} g", _sd1, 0.1, 1.2, (v) {
                          setState(() => _sd1 = v);
                          _runPushover();
                        }),
                        const SizedBox(height: 12),
                        GlassPod(
                          padding: const EdgeInsets.all(12),
                          borderRadius: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("PERFORMANCE POINT (ATC-40)", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.8)),
                              const SizedBox(height: 4),
                              Text("Roof Drift: ${perfDriftMm.toStringAsFixed(1)} mm (${(perfDriftMm / (_heightM * 10)).toStringAsFixed(2)}%)", style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 12.5)),
                              Text("Spectral Accel Sa: ${perfSaG.toStringAsFixed(3)} g", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text("Fundamental T1: ${t1.toStringAsFixed(2)} s", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text("Peak Base Shear: ${peakShear.toStringAsFixed(0)} kN", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right ADRS Capacity Spectrum Chart Painter
                  Expanded(
                    child: GlassPod(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _AdrsCapacityPainter(
                          curvePoints: curvePoints,
                          perfSa: perfSaG,
                          perfSd: perfDriftMm * 0.75,
                        ),
                      ),
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

  Widget _sliderParam(String label, String valueStr, double val, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
              Text(valueStr, style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 11.5)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: const Color(0xFF00F0FF),
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
            ),
            child: Slider(value: val.clamp(min, max), min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _AdrsCapacityPainter extends CustomPainter {
  final List<dynamic> curvePoints;
  final double perfSa;
  final double perfSd;

  _AdrsCapacityPainter({
    required this.curvePoints,
    required this.perfSa,
    required this.perfSd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ox = 45.0;
    final oy = size.height - 35.0;
    final plotW = size.width - 60.0;
    final plotH = size.height - 60.0;

    // Grid lines & Axis
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(ox, oy), Offset(ox + plotW, oy), axisPaint);
    canvas.drawLine(Offset(ox, oy), Offset(ox, oy - plotH), axisPaint);

    // Text labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(text: "Spectral Displacement Sd (mm)", style: TextStyle(color: Colors.white54, fontSize: 10));
    tp.layout();
    tp.paint(canvas, Offset(ox + plotW / 2.0 - 60, oy + 12));

    // Pushover Capacity Curve (Green / Cyan)
    final capPath = Path();
    capPath.moveTo(ox, oy);

    final maxSd = 250.0;
    final maxSa = 1.2;

    for (int i = 0; i < curvePoints.length; i++) {
      final pt = curvePoints[i] as Map<String, dynamic>;
      final sd = (pt['sd_mm'] as num?)?.toDouble() ?? 0.0;
      final sa = (pt['sa_g'] as num?)?.toDouble() ?? 0.0;
      final x = ox + (sd / maxSd) * plotW;
      final y = oy - (sa / maxSa) * plotH;
      if (i == 0) {
        capPath.moveTo(x, y);
      } else {
        capPath.lineTo(x, y);
      }
    }

    final capPaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(capPath, capPaint);

    // Demand Spectrum Curve (Violet / Magenta)
    final demandPath = Path();
    for (double period = 0.2; period <= 2.5; period += 0.1) {
      final sa = min(1.05, 0.62 / period);
      final sd = ((period / (2 * math.pi)) * (period / (2 * math.pi))) * (sa * 9.81) * 1000.0;
      final x = ox + (sd / maxSd) * plotW;
      final y = oy - (sa / maxSa) * plotH;
      if (period == 0.2) {
        demandPath.moveTo(x, y);
      } else {
        demandPath.lineTo(x, y);
      }
    }
    final demandPaint = Paint()
      ..color = const Color(0xFFEC4899)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(demandPath, demandPaint);

    // Performance Point Star / Circle
    final px = ox + (perfSd / maxSd) * plotW;
    final py = oy - (perfSa / maxSa) * plotH;
    final starPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(px, py), 6.0, starPaint);
    canvas.drawCircle(Offset(px, py), 10.0, Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  double min(double a, double b) => a < b ? a : b;

  @override
  bool shouldRepaint(covariant _AdrsCapacityPainter oldDelegate) => true;
}
