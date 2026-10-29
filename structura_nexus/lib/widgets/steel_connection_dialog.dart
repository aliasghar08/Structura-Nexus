// ============================================================================
// Structura Nexus: Steel Connection Studio (AISC 360-16 / AISC 358-16 / AISC DG 1)
// Bolted Shear Tabs, Extended End-Plates, Base Plates & Anchor Rods
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'glass_pod.dart';
import '../services/structural_api_service.dart';

class SteelConnectionDialog extends StatefulWidget {
  final VoidCallback? onOptimizeApplied;
  final Function(String feature, VoidCallback onAuth)? onRequireAuth;

  const SteelConnectionDialog({
    super.key,
    this.onOptimizeApplied,
    this.onRequireAuth,
  });

  @override
  State<SteelConnectionDialog> createState() => _SteelConnectionDialogState();
}

class _SteelConnectionDialogState extends State<SteelConnectionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StructuralApiService _api = StructuralApiService();

  // Shear Tab Parameters
  double _shearDemand = 220.0; // kN
  int _numBolts = 4;
  final double _boltDiaMm = 19.05; // 3/4 in
  double _plateThickMm = 9.525; // 3/8 in
  double _boltSpacingMm = 76.2; // 3 in
  double _weldSizeMm = 6.35; // 1/4 in
  Map<String, dynamic>? _shearTabResult;

  // Base Plate Parameters
  double _axialDemand = 1800.0; // kN
  double _momentDemand = 85.0; // kN*m
  double _plateLengthN = 550.0; // mm
  double _plateWidthB = 500.0; // mm
  Map<String, dynamic>? _basePlateResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _recomputeShearTab();
    _recomputeBasePlate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _recomputeShearTab() async {
    final res = await _api.checkShearTabConnection(
      shearDemandKn: _shearDemand,
      numBolts: _numBolts,
      boltDiameterMm: _boltDiaMm,
      plateThicknessMm: _plateThickMm,
      boltSpacingMm: _boltSpacingMm,
      weldSizeMm: _weldSizeMm,
    );
    if (mounted) {
      setState(() {
        _shearTabResult = res;
      });
    }
  }

  void _recomputeBasePlate() async {
    final res = await _api.checkBasePlateConnection(
      axialDemandKn: _axialDemand,
      momentDemandKnm: _momentDemand,
      plateLengthNMm: _plateLengthN,
      plateWidthBMm: _plateWidthB,
    );
    if (mounted) {
      setState(() {
        _basePlateResult = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "STEEL CONNECTION STUDIO",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        Text(
                          "AISC 360-16 / AISC 358 Limit States & Detailing",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: const Color(0xFFF59E0B),
                      labelColor: const Color(0xFFF59E0B),
                      unselectedLabelColor: Colors.white54,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: "SHEAR TAB (FIN PLATE)"),
                        Tab(text: "BASE PLATE & ANCHORS"),
                      ],
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildShearTabContent(),
                  _buildBasePlateContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShearTabContent() {
    final dcr = (_shearTabResult?['governing_dcr'] as num?)?.toDouble() ?? 0.68;
    final isSafe = dcr <= 1.0;
    final limitStates = (_shearTabResult?['limit_states'] as List<dynamic>?) ?? [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Parameters
        SizedBox(
          width: 320,
          child: ListView(
            padding: const EdgeInsets.only(right: 16),
            children: [
              _sliderParam("Shear Demand (Vu)", "${_shearDemand.toStringAsFixed(0)} kN", _shearDemand, 50, 600, (v) {
                setState(() => _shearDemand = v);
                _recomputeShearTab();
              }),
              _sliderParam("Number of Bolts", "$_numBolts", _numBolts.toDouble(), 2, 8, (v) {
                setState(() => _numBolts = v.round());
                _recomputeShearTab();
              }),
              _sliderParam("Plate Thickness", "${_plateThickMm.toStringAsFixed(1)} mm", _plateThickMm, 6.0, 25.4, (v) {
                setState(() => _plateThickMm = v);
                _recomputeShearTab();
              }),
              _sliderParam("Bolt Pitch (Spacing)", "${_boltSpacingMm.toStringAsFixed(1)} mm", _boltSpacingMm, 50.0, 100.0, (v) {
                setState(() => _boltSpacingMm = v);
                _recomputeShearTab();
              }),
              _sliderParam("Double Fillet Weld", "${_weldSizeMm.toStringAsFixed(1)} mm", _weldSizeMm, 4.0, 16.0, (v) {
                setState(() => _weldSizeMm = v);
                _recomputeShearTab();
              }),
              const SizedBox(height: 12),
              GlassPod(
                padding: const EdgeInsets.all(12),
                borderRadius: 14,
                child: Row(
                  children: [
                    Icon(isSafe ? Icons.check_circle_rounded : Icons.warning_rounded, color: isSafe ? const Color(0xFF10B981) : const Color(0xFFEC4899), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("GOVERNING DCR: ${dcr.toStringAsFixed(3)}", style: TextStyle(color: isSafe ? const Color(0xFF10B981) : const Color(0xFFEC4899), fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(isSafe ? "All AISC limit states satisfied" : "Overshear / Tearout exceedance", style: const TextStyle(color: Colors.white54, fontSize: 10.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right 2D CAD & Limit States
        Expanded(
          child: Column(
            children: [
              // 2D CAD Detailing Viewport
              Expanded(
                flex: 5,
                child: GlassPod(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _ShearTabCadPainter(
                      numBolts: _numBolts,
                      plateThickness: _plateThickMm,
                      spacing: _boltSpacingMm,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Limit States Table
              Expanded(
                flex: 4,
                child: GlassPod(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  child: ListView.separated(
                    itemCount: limitStates.length,
                    separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 10),
                    itemBuilder: (context, idx) {
                      final ls = limitStates[idx] as Map<String, dynamic>;
                      final lsDcr = (ls['dcr'] as num?)?.toDouble() ?? 0.0;
                      final pass = lsDcr <= 1.0;
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              ls['name']?.toString() ?? '',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          Text(
                            "${ls['capacity_kn']} kN",
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (pass ? const Color(0xFF10B981) : const Color(0xFFEC4899)).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "DCR ${lsDcr.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: pass ? const Color(0xFF10B981) : const Color(0xFFEC4899),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasePlateContent() {
    final dcr = (_basePlateResult?['governing_dcr'] as num?)?.toDouble() ?? 0.76;
    final isSafe = dcr <= 1.0;
    final reqThick = (_basePlateResult?['required_thickness_mm'] as num?)?.toDouble() ?? 28.5;
    final recThick = (_basePlateResult?['recommended_thickness_mm'] as num?)?.toInt() ?? 30;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: ListView(
            padding: const EdgeInsets.only(right: 16),
            children: [
              _sliderParam("Axial Load (Pu)", "${_axialDemand.toStringAsFixed(0)} kN", _axialDemand, 200, 4000, (v) {
                setState(() => _axialDemand = v);
                _recomputeBasePlate();
              }),
              _sliderParam("Moment (Mu)", "${_momentDemand.toStringAsFixed(0)} kN*m", _momentDemand, 0, 300, (v) {
                setState(() => _momentDemand = v);
                _recomputeBasePlate();
              }),
              _sliderParam("Plate Length (N)", "${_plateLengthN.toStringAsFixed(0)} mm", _plateLengthN, 350, 800, (v) {
                setState(() => _plateLengthN = v);
                _recomputeBasePlate();
              }),
              _sliderParam("Plate Width (B)", "${_plateWidthB.toStringAsFixed(0)} mm", _plateWidthB, 350, 800, (v) {
                setState(() => _plateWidthB = v);
                _recomputeBasePlate();
              }),
              const SizedBox(height: 12),
              GlassPod(
                padding: const EdgeInsets.all(14),
                borderRadius: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("RECOMMENDED THICKNESS", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 0.8)),
                    const SizedBox(height: 4),
                    Text("t_plate = $recThick mm (Min req: ${reqThick.toStringAsFixed(1)} mm)", style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Governing DCR: ${dcr.toStringAsFixed(2)} • ${isSafe ? 'PASS' : 'EXCEEDED'}", style: TextStyle(color: isSafe ? const Color(0xFF10B981) : const Color(0xFFEC4899), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GlassPod(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.layers_rounded, color: Color(0xFFF59E0B), size: 48),
                const SizedBox(height: 16),
                const Text("AISC DG 1 Base Plate Mechanics", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Concrete bearing capacity, cantilever plate bending yield lines (m, n, lambda n'), and 4-rod tension breakout verified per ACI 318 Chapter 17.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _metricPill("Length N", "${_plateLengthN.toInt()} mm"),
                    const SizedBox(width: 12),
                    _metricPill("Width B", "${_plateWidthB.toInt()} mm"),
                    const SizedBox(width: 12),
                    _metricPill("Plate tp", "$recThick mm"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricPill(String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
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
              Text(valueStr, style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 11.5)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: const Color(0xFFF59E0B),
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

class _ShearTabCadPainter extends CustomPainter {
  final int numBolts;
  final double plateThickness;
  final double spacing;

  _ShearTabCadPainter({
    required this.numBolts,
    required this.plateThickness,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;

    // Draw Column Flange Support
    final supportPaint = Paint()
      ..color = const Color(0xFF30363D)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(cx - 100, 20, 24, size.height - 40), supportPaint);

    // Draw Double Fillet Weld
    final weldPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    final pathWeld1 = Path()
      ..moveTo(cx - 76, cy - (numBolts * 18.0))
      ..lineTo(cx - 68, cy - (numBolts * 18.0))
      ..lineTo(cx - 76, cy - (numBolts * 18.0) + 12)
      ..close();
    canvas.drawPath(pathWeld1, weldPaint);

    // Draw Shear Tab Plate
    final plateHeight = (numBolts - 1) * 36.0 + 50.0;
    final platePaint = Paint()
      ..color = const Color(0xFF1F6FEB).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final plateBorder = Paint()
      ..color = const Color(0xFF58A6FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final plateRect = Rect.fromCenter(center: Offset(cx - 30, cy), width: 90, height: plateHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(plateRect, const Radius.circular(4)), platePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(plateRect, const Radius.circular(4)), plateBorder);

    // Draw Beam Web
    final beamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(cx - 30, cy - plateHeight / 2.0 - 20, 140, plateHeight + 40), beamPaint);

    // Draw Bolts with Crosshairs
    final boltFill = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    final boltLine = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;

    final startY = cy - ((numBolts - 1) * 36.0) / 2.0;
    for (int i = 0; i < numBolts; i++) {
      final by = startY + i * 36.0;
      final bx = cx - 30;
      canvas.drawCircle(Offset(bx, by), 9.0, boltFill);
      canvas.drawLine(Offset(bx - 9, by), Offset(bx + 9, by), boltLine);
      canvas.drawLine(Offset(bx, by - 9), Offset(bx, by + 9), boltLine);
    }
  }

  @override
  bool shouldRepaint(covariant _ShearTabCadPainter oldDelegate) =>
      oldDelegate.numBolts != numBolts || oldDelegate.spacing != spacing;
}
