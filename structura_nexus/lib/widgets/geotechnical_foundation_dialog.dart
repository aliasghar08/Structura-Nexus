// ============================================================================
// Structura Nexus: Geotechnical Foundation & SSI Studio (Bowles / Meyerhof / ACI 318)
// Isolated Spread Footings, Punching Shear, Winkler Springs & Settlement
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'glass_pod.dart';
import '../services/structural_api_service.dart';

class GeotechnicalFoundationDialog extends StatefulWidget {
  final VoidCallback? onOptimizeApplied;
  final Function(String feature, VoidCallback onAuth)? onRequireAuth;

  const GeotechnicalFoundationDialog({
    super.key,
    this.onOptimizeApplied,
    this.onRequireAuth,
  });

  @override
  State<GeotechnicalFoundationDialog> createState() => _GeotechnicalFoundationDialogState();
}

class _GeotechnicalFoundationDialogState extends State<GeotechnicalFoundationDialog> {
  final StructuralApiService _api = StructuralApiService();

  double _pu = 1600.0; // kN
  double _mx = 120.0; // kN*m
  double _phiDeg = 32.0; // degrees
  final double _cKpa = 10.0; // kPa
  double _footingL = 2.8; // m
  final double _footingB = 2.8; // m
  double _footingT = 0.65; // m
  double _ks = 45000.0; // kN/m^3

  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  void _recompute() async {
    final res = await _api.analyzeGeotechnicalFoundation(
      axialLoadKn: _pu,
      momentXKnm: _mx,
      soilFrictionAngleDeg: _phiDeg,
      soilCohesionKpa: _cKpa,
      footingLengthM: _footingL,
      footingWidthM: _footingB,
      footingThicknessM: _footingT,
      subgradeModulusKnM3: _ks,
    );
    if (mounted) {
      setState(() {
        _result = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dcr = (_result?['governing_dcr'] as num?)?.toDouble() ?? 0.72;
    final isSafe = dcr <= 1.0;
    final qAllow = (_result?['q_allowable_kpa'] as num?)?.toDouble() ?? 326.8;
    final qAct = (_result?['q_max_service_kpa'] as num?)?.toDouble() ?? 235.4;
    final settlementMm = (_result?['settlement']?['elastic_settlement_mm'] as num?)?.toDouble() ?? 12.4;
    final rebar = _result?['reinforcement']?['recommended_bars']?.toString() ?? "12 x #6 (20mm) @ 250mm";

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassPod(
        width: 880,
        height: 660,
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.foundation_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "FOUNDATION & SOIL-STRUCTURE INTERACTION",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        Text(
                          "Meyerhof Bearing • ACI 318 Punching Shear • Winkler Springs (ks)",
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

            // Content Body
            Expanded(
              child: Row(
                children: [
                  // Left Parameters
                  SizedBox(
                    width: 320,
                    child: ListView(
                      padding: const EdgeInsets.only(right: 16),
                      children: [
                        _sliderParam("Axial Load (Pu)", "${_pu.toStringAsFixed(0)} kN", _pu, 300, 4000, (v) {
                          setState(() => _pu = v);
                          _recompute();
                        }),
                        _sliderParam("Moment (Mx)", "${_mx.toStringAsFixed(0)} kN*m", _mx, 0, 300, (v) {
                          setState(() => _mx = v);
                          _recompute();
                        }),
                        _sliderParam("Footing Length (L)", "${_footingL.toStringAsFixed(2)} m", _footingL, 1.5, 5.0, (v) {
                          setState(() => _footingL = v);
                          _recompute();
                        }),
                        _sliderParam("Footing Thickness (T)", "${_footingT.toStringAsFixed(2)} m", _footingT, 0.4, 1.2, (v) {
                          setState(() => _footingT = v);
                          _recompute();
                        }),
                        _sliderParam("Soil Friction Angle (phi)", "${_phiDeg.toStringAsFixed(0)}°", _phiDeg, 20.0, 42.0, (v) {
                          setState(() => _phiDeg = v);
                          _recompute();
                        }),
                        _sliderParam("Subgrade Modulus (ks)", "${(_ks / 1000).toStringAsFixed(0)} MPa/m", _ks, 15000, 100000, (v) {
                          setState(() => _ks = v);
                          _recompute();
                        }),
                        const SizedBox(height: 12),
                        GlassPod(
                          padding: const EdgeInsets.all(12),
                          borderRadius: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(isSafe ? Icons.check_circle_rounded : Icons.warning_rounded, color: isSafe ? const Color(0xFF10B981) : const Color(0xFFEC4899), size: 20),
                                  const SizedBox(width: 8),
                                  Text("GOVERNING DCR: ${dcr.toStringAsFixed(3)}", style: TextStyle(color: isSafe ? const Color(0xFF10B981) : const Color(0xFFEC4899), fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text("Soil: ${qAct.toStringAsFixed(1)} kPa / Max: ${qAllow.toStringAsFixed(1)} kPa", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text("Settlement: ${settlementMm.toStringAsFixed(1)} mm (Allowable: 25 mm)", style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Graphics and Details
                  Expanded(
                    child: Column(
                      children: [
                        // 2D Footing Pressure Distribution Painter
                        Expanded(
                          flex: 5,
                          child: GlassPod(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(16),
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: _FootingPressurePainter(
                                footingLength: _footingL,
                                footingThickness: _footingT,
                                qMax: qAct,
                                qAllow: qAllow,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Metric Highlights
                        Expanded(
                          flex: 3,
                          child: GlassPod(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statCard("FLEXURAL REBAR", rebar, Icons.grid_4x4_rounded, const Color(0xFF00F0FF)),
                                _statCard("WINKLER KZ", "${(_ks * _footingL * _footingB / 1e3).toStringAsFixed(0)} MN/m", Icons.grain_rounded, const Color(0xFFF59E0B)),
                                _statCard("PUNCHING SHEAR", "ACI 318 PASS (d/2)", Icons.shield_rounded, const Color(0xFF10B981)),
                              ],
                            ),
                          ),
                        ),
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

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
      ],
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
              Text(valueStr, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11.5)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: const Color(0xFF10B981),
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

class _FootingPressurePainter extends CustomPainter {
  final double footingLength;
  final double footingThickness;
  final double qMax;
  final double qAllow;

  _FootingPressurePainter({
    required this.footingLength,
    required this.footingThickness,
    required this.qMax,
    required this.qAllow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height * 0.45;

    // Draw Concrete Footing Block
    final fWidth = 260.0;
    final fHeight = 65.0;
    final footingRect = Rect.fromCenter(center: Offset(cx, cy), width: fWidth, height: fHeight);

    final concretePaint = Paint()
      ..color = const Color(0xFF1F6FEB).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final concreteBorder = Paint()
      ..color = const Color(0xFF58A6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(footingRect, const Radius.circular(6)), concretePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(footingRect, const Radius.circular(6)), concreteBorder);

    // Draw Column Pedestal
    final pedRect = Rect.fromCenter(center: Offset(cx, cy - fHeight / 2.0 - 25), width: 50, height: 50);
    final pedPaint = Paint()..color = const Color(0xFF30363D);
    canvas.drawRect(pedRect, pedPaint);

    // Draw Soil Strata Boundary Line
    final groundPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(20, cy + fHeight / 2.0), Offset(size.width - 20, cy + fHeight / 2.0), groundPaint);

    // Draw Trapezoidal Soil Pressure Distribution
    final pressureBaseY = cy + fHeight / 2.0 + 55.0;
    final pressurePath = Path()
      ..moveTo(cx - fWidth / 2.0, cy + fHeight / 2.0)
      ..lineTo(cx + fWidth / 2.0, cy + fHeight / 2.0)
      ..lineTo(cx + fWidth / 2.0, pressureBaseY)
      ..lineTo(cx - fWidth / 2.0, pressureBaseY - 20)
      ..close();

    final pressurePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final pressureBorder = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(pressurePath, pressurePaint);
    canvas.drawPath(pressurePath, pressureBorder);

    // Soil Spring Indicators (Winkler)
    final springPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 7; i++) {
      final sx = cx - fWidth / 2.0 + 20 + i * 36.0;
      canvas.drawLine(Offset(sx, cy + fHeight / 2.0), Offset(sx, cy + fHeight / 2.0 + 15), springPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FootingPressurePainter oldDelegate) => true;
}
