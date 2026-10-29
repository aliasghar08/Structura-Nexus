// ============================================================================
// Structura Nexus: Wind Tunnel CFD & Aero-Surrogate Studio (AeroNet-CFD)
// ASCE 7-16 Chapter 31 Wind Tunnel Procedure, Corner Vortices & Strouhal Shedding
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'glass_pod.dart';
import '../services/structural_api_service.dart';

class WindCfdDialog extends StatefulWidget {
  final VoidCallback? onOptimizeApplied;
  final Function(String feature, VoidCallback onAuth)? onRequireAuth;

  const WindCfdDialog({
    super.key,
    this.onOptimizeApplied,
    this.onRequireAuth,
  });

  @override
  State<WindCfdDialog> createState() => _WindCfdDialogState();
}

class _WindCfdDialogState extends State<WindCfdDialog> {
  final StructuralApiService _api = StructuralApiService();

  double _heightM = 90.0;
  double _widthM = 30.0;
  final double _depthM = 30.0;
  double _windSpeed = 45.0; // m/s
  double _periodT1 = 2.4; // s

  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  void _recompute() async {
    final res = await _api.analyzeAerodynamicsCfd(
      buildingHeightM: _heightM,
      buildingWidthM: _widthM,
      buildingDepthM: _depthM,
      designWindSpeedMS: _windSpeed,
      firstNaturalPeriodS: _periodT1,
      terrainCategory: "B",
    );
    if (mounted) {
      setState(() {
        _result = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final qz = (_result?['qz_velocity_pressure_pa'] as num?)?.toDouble() ?? 1024.0;
    final fs = (_result?['vortex_shedding_frequency_hz'] as num?)?.toDouble() ?? 0.147;
    final isLockin = (_result?['is_lockin_resonance_risk'] as bool?) ?? false;
    final cornerSuction = (_result?['max_corner_suction_kpa'] as num?)?.toDouble() ?? -1.85;
    final glazingRating = (_result?['recommended_glazing_rating_kpa'] as num?)?.toDouble() ?? 2.78;
    final alongShear = (_result?['along_wind_base_shear_kn'] as num?)?.toDouble() ?? 1850.0;
    final acrossShear = (_result?['across_wind_base_shear_kn'] as num?)?.toDouble() ?? 1220.0;

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
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.air_rounded, color: Color(0xFF06B6D4), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "WIND TUNNEL CFD & AERO-SURROGATE",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        Text(
                          "ASCE 7-16 Ch 31 Wind Tunnel • Corner Vortex Suctions • Strouhal Shedding",
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

            // Main Body
            Expanded(
              child: Row(
                children: [
                  // Left Sliders
                  SizedBox(
                    width: 310,
                    child: ListView(
                      padding: const EdgeInsets.only(right: 14),
                      children: [
                        _sliderParam("Building Height (H)", "${_heightM.toStringAsFixed(0)} m", _heightM, 30, 300, (v) {
                          setState(() => _heightM = v);
                          _recompute();
                        }),
                        _sliderParam("Cross-Wind Width (B)", "${_widthM.toStringAsFixed(0)} m", _widthM, 15, 80, (v) {
                          setState(() => _widthM = v);
                          _recompute();
                        }),
                        _sliderParam("Wind Speed (V)", "${_windSpeed.toStringAsFixed(0)} m/s (${(_windSpeed * 2.237).toStringAsFixed(0)} mph)", _windSpeed, 25, 75, (v) {
                          setState(() => _windSpeed = v);
                          _recompute();
                        }),
                        _sliderParam("Natural Period (T1)", "${_periodT1.toStringAsFixed(2)} s", _periodT1, 0.5, 6.0, (v) {
                          setState(() => _periodT1 = v);
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
                                  Icon(isLockin ? Icons.warning_rounded : Icons.check_circle_rounded, color: isLockin ? const Color(0xFFEC4899) : const Color(0xFF10B981), size: 20),
                                  const SizedBox(width: 8),
                                  Text(isLockin ? "STROUHAL LOCK-IN RISK" : "VORTEX SHEDDING SAFE", style: TextStyle(color: isLockin ? const Color(0xFFEC4899) : const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text("Shedding Frequency: ${fs.toStringAsFixed(3)} Hz", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text("Velocity Pressure qz: ${qz.toStringAsFixed(0)} Pa", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text("Glazing Suction Rating: ${glazingRating.toStringAsFixed(2)} kPa", style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right CFD Aerodynamic Visualizer
                  Expanded(
                    child: Column(
                      children: [
                        // Flow field & streamline painter
                        Expanded(
                          flex: 5,
                          child: GlassPod(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(16),
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: _WindCfdStreamlinePainter(
                                heightM: _heightM,
                                widthM: _widthM,
                                cornerSuctionKpa: cornerSuction,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Base Shear Breakdown
                        Expanded(
                          flex: 3,
                          child: GlassPod(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _metricPill("ALONG-WIND SHEAR", "${alongShear.toStringAsFixed(0)} kN", Icons.east_rounded, const Color(0xFF00F0FF)),
                                _metricPill("ACROSS-WIND BUFFETING", "${acrossShear.toStringAsFixed(0)} kN", Icons.swap_vert_rounded, const Color(0xFFF59E0B)),
                                _metricPill("PEAK CORNER SUCTION", "${cornerSuction.toStringAsFixed(2)} kPa", Icons.cyclone_rounded, const Color(0xFFEC4899)),
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

  Widget _metricPill(String title, String val, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
              Text(valueStr, style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 11.5)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: const Color(0xFF06B6D4),
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

class _WindCfdStreamlinePainter extends CustomPainter {
  final double heightM;
  final double widthM;
  final double cornerSuctionKpa;

  _WindCfdStreamlinePainter({
    required this.heightM,
    required this.widthM,
    required this.cornerSuctionKpa,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;

    // Draw Building Silhouette (Plan / Top View)
    final bSize = 85.0;
    final buildingRect = Rect.fromCenter(center: Offset(cx, cy), width: bSize, height: bSize);

    final bPaint = Paint()
      ..color = const Color(0xFF161B22)
      ..style = PaintingStyle.fill;
    final bBorder = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(buildingRect, bPaint);
    canvas.drawRect(buildingRect, bBorder);

    // Wind Streamlines (Left to Right flowing around building)
    final streamPaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = -3; i <= 3; i++) {
      final yOffset = i * 28.0;
      final path = Path();
      path.moveTo(20, cy + yOffset);

      if (yOffset.abs() < 45.0) {
        // Deflect around building
        final sign = yOffset < 0 ? -1.0 : 1.0;
        path.cubicTo(
          cx - 80,
          cy + yOffset,
          cx - 50,
          cy + sign * 65.0,
          cx,
          cy + sign * 65.0,
        );
        path.cubicTo(
          cx + 50,
          cy + sign * 65.0,
          cx + 80,
          cy + yOffset,
          size.width - 20,
          cy + yOffset,
        );
      } else {
        path.lineTo(size.width - 20, cy + yOffset);
      }
      canvas.drawPath(path, streamPaint);
    }

    // Corner Separation Vortex Circles (High Suction Zones)
    final vortexPaint = Paint()
      ..color = const Color(0xFFEC4899).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final vortexRing = Paint()
      ..color = const Color(0xFFEC4899)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final corners = [
      Offset(cx - bSize / 2.0, cy - bSize / 2.0),
      Offset(cx - bSize / 2.0, cy + bSize / 2.0),
      Offset(cx + bSize / 2.0, cy - bSize / 2.0),
      Offset(cx + bSize / 2.0, cy + bSize / 2.0),
    ];

    for (final c in corners) {
      canvas.drawCircle(c, 12.0, vortexPaint);
      canvas.drawCircle(c, 16.0, vortexRing);
    }
  }

  @override
  bool shouldRepaint(covariant _WindCfdStreamlinePainter oldDelegate) => true;
}
