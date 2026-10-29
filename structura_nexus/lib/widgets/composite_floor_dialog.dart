// ============================================================================
// Structura Nexus: Composite Deck & Floor Vibration Studio (AISC 360 / AISC DG 11)
// Plastic Moment Capacity, Shear Studs Qn & Human Walking Vibration Comfort
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'glass_pod.dart';
import '../services/structural_api_service.dart';

class CompositeFloorDialog extends StatefulWidget {
  final VoidCallback? onOptimizeApplied;
  final Function(String feature, VoidCallback onAuth)? onRequireAuth;

  const CompositeFloorDialog({
    super.key,
    this.onOptimizeApplied,
    this.onRequireAuth,
  });

  @override
  State<CompositeFloorDialog> createState() => _CompositeFloorDialogState();
}

class _CompositeFloorDialogState extends State<CompositeFloorDialog> {
  final StructuralApiService _api = StructuralApiService();

  double _spanM = 9.0;
  double _spacingM = 3.0;
  double _slabThickMm = 130.0;
  int _numStuds = 32;
  double _liveLoadKpa = 3.0;
  final String _occupancy = "OFFICE";

  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  void _recompute() async {
    final res = await _api.analyzeCompositeFloor(
      beamSpanM: _spanM,
      beamSpacingM: _spacingM,
      slabTotalThicknessMm: _slabThickMm,
      numShearStuds: _numStuds,
      liveLoadKpa: _liveLoadKpa,
      occupancyType: _occupancy,
    );
    if (mounted) {
      setState(() {
        _result = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dcr = (_result?['flexural_dcr'] as num?)?.toDouble() ?? 0.65;
    final isSafe = (_result?['is_flexure_safe'] as bool?) ?? true;
    final phiMn = (_result?['design_moment_phi_mn_knm'] as num?)?.toDouble() ?? 465.0;
    final mu = (_result?['factored_moment_mu_knm'] as num?)?.toDouble() ?? 302.0;
    final compositePct = (_result?['composite_action_pct'] as num?)?.toDouble() ?? 68.5;
    final vib = _result?['vibration_serviceability'] as Map<String, dynamic>?;
    final fnHz = (vib?['natural_frequency_fn_hz'] as num?)?.toDouble() ?? 5.24;
    final apG = (vib?['peak_acceleration_ap_g_pct'] as num?)?.toDouble() ?? 0.312;
    final isVibPass = (vib?['is_vibration_satisfactory'] as bool?) ?? true;
    final perception = vib?['human_perception_rating']?.toString() ?? "QUIET / IMPERCEPTIBLE";

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
            // Top Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.layers_rounded, color: Color(0xFF14B8A6), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "COMPOSITE FLOOR & VIBRATION STUDIO",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        Text(
                          "AISC 360-16 Chapter I Composite Beams • AISC DG 11 Walking Vibration",
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

            // Vibration Serviceability Alert Banner
            GlassPod(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              borderRadius: 14,
              child: Row(
                children: [
                  Icon(isVibPass ? Icons.check_circle_rounded : Icons.warning_rounded, color: isVibPass ? const Color(0xFF10B981) : const Color(0xFFEC4899), size: 22),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DG 11 WALKING COMFORT: $perception (ap/g: ${apG.toStringAsFixed(3)}% / Limit: 0.50%)",
                        style: TextStyle(color: isVibPass ? const Color(0xFF10B981) : const Color(0xFFEC4899), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text("Floor Natural Frequency: ${fnHz.toStringAsFixed(2)} Hz (Target fn >= 3.0 Hz to prevent walking resonance)", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Body Row
            Expanded(
              child: Row(
                children: [
                  // Parameters
                  SizedBox(
                    width: 310,
                    child: ListView(
                      padding: const EdgeInsets.only(right: 14),
                      children: [
                        _sliderParam("Beam Span (L)", "${_spanM.toStringAsFixed(1)} m", _spanM, 5.0, 15.0, (v) {
                          setState(() => _spanM = v);
                          _recompute();
                        }),
                        _sliderParam("Beam Spacing (S)", "${_spacingM.toStringAsFixed(1)} m", _spacingM, 1.8, 4.5, (v) {
                          setState(() => _spacingM = v);
                          _recompute();
                        }),
                        _sliderParam("Total Slab Thickness", "${_slabThickMm.toStringAsFixed(0)} mm", _slabThickMm, 90.0, 200.0, (v) {
                          setState(() => _slabThickMm = v);
                          _recompute();
                        }),
                        _sliderParam("Shear Stud Count", "$_numStuds studs", _numStuds.toDouble(), 16, 64, (v) {
                          setState(() => _numStuds = v.round());
                          _recompute();
                        }),
                        _sliderParam("Live Load (LL)", "${_liveLoadKpa.toStringAsFixed(1)} kPa", _liveLoadKpa, 1.5, 7.5, (v) {
                          setState(() => _liveLoadKpa = v);
                          _recompute();
                        }),
                        const SizedBox(height: 10),
                        GlassPod(
                          padding: const EdgeInsets.all(12),
                          borderRadius: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("COMPOSITE ACTION: $compositePct%", style: const TextStyle(color: Color(0xFF14B8A6), fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text("Moment Demand Mu: ${mu.toStringAsFixed(1)} kN*m", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text("Capacity phi*Mn: ${phiMn.toStringAsFixed(1)} kN*m", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text("Flexural DCR: ${dcr.toStringAsFixed(3)} • ${isSafe ? 'PASS' : 'EXCEEDED'}", style: TextStyle(color: isSafe ? const Color(0xFF10B981) : const Color(0xFFEC4899), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2D Cross Section Painter
                  Expanded(
                    child: GlassPod(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _CompositeSectionPainter(
                          slabThickness: _slabThickMm,
                          compositePct: compositePct,
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
              Text(valueStr, style: const TextStyle(color: Color(0xFF14B8A6), fontWeight: FontWeight.bold, fontSize: 11.5)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: const Color(0xFF14B8A6),
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

class _CompositeSectionPainter extends CustomPainter {
  final double slabThickness;
  final double compositePct;

  _CompositeSectionPainter({
    required this.slabThickness,
    required this.compositePct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height * 0.45;

    // Concrete Slab on Deck
    final slabW = size.width - 60.0;
    final slabH = 50.0;
    final slabRect = Rect.fromCenter(center: Offset(cx, cy - 60), width: slabW, height: slabH);

    final slabPaint = Paint()
      ..color = const Color(0xFF1F6FEB).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final slabBorder = Paint()
      ..color = const Color(0xFF58A6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(slabRect, const Radius.circular(4)), slabPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(slabRect, const Radius.circular(4)), slabBorder);

    // Corrugated Metal Deck Rib Profile
    final deckPaint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final deckPath = Path();
    for (double x = cx - slabW / 2.0; x <= cx + slabW / 2.0 - 40; x += 50.0) {
      deckPath.moveTo(x, cy - 35);
      deckPath.lineTo(x + 15, cy - 35);
      deckPath.lineTo(x + 25, cy - 15);
      deckPath.lineTo(x + 40, cy - 15);
      deckPath.lineTo(x + 50, cy - 35);
    }
    canvas.drawPath(deckPath, deckPaint);

    // Shear Studs (Anchored to Steel Top Flange into Slab)
    final studPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    for (int i = -1; i <= 1; i++) {
      final sx = cx + i * 28.0;
      canvas.drawRect(Rect.fromLTWH(sx - 3, cy - 55, 6, 40), studPaint);
      canvas.drawCircle(Offset(sx, cy - 55), 7.0, studPaint); // Stud head
    }

    // Steel Wide-Flange Beam (W-shape cross section)
    final beamPaint = Paint()
      ..color = const Color(0xFF30363D)
      ..style = PaintingStyle.fill;
    final beamBorder = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Top Flange
    final tfRect = Rect.fromCenter(center: Offset(cx, cy - 10), width: 140, height: 12);
    canvas.drawRect(tfRect, beamPaint);
    canvas.drawRect(tfRect, beamBorder);

    // Web
    final webRect = Rect.fromCenter(center: Offset(cx, cy + 60), width: 10, height: 130);
    canvas.drawRect(webRect, beamPaint);
    canvas.drawRect(webRect, beamBorder);

    // Bottom Flange
    final bfRect = Rect.fromCenter(center: Offset(cx, cy + 130), width: 140, height: 12);
    canvas.drawRect(bfRect, beamPaint);
    canvas.drawRect(bfRect, beamBorder);
  }

  @override
  bool shouldRepaint(covariant _CompositeSectionPainter oldDelegate) => true;
}
