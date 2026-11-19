// ============================================================================
// ConnectionDetailDialog — AISC 360-16 Chapter J 3D Connection & Baseplate Studio
// 2D Dimensioned Shop-Detail Diagram, Limit-State DCR Table & 3D WebGL Synthesis
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/connection_detailer_service.dart';
import 'glass_pod.dart';
import 'info_tooltip.dart';
import 'three_js_view.dart';

class ConnectionDetailDialog extends StatefulWidget {
  final StructuralModel model;
  final String? initialJointId;
  final String initialConnectionType;

  const ConnectionDetailDialog({
    super.key,
    required this.model,
    this.initialJointId,
    this.initialConnectionType = 'SHEAR_TAB',
  });

  @override
  State<ConnectionDetailDialog> createState() => _ConnectionDetailDialogState();
}

class _ConnectionDetailDialogState extends State<ConnectionDetailDialog> {
  late String _connectionType;
  late String _selectedJointId;
  String _boltGrade = 'A325';
  int _numBolts = 4;
  double _plateThicknessMm = 12.7;
  final double _shearVuKn = 210.0;
  final double _momentMuKnm = 320.0;
  final double _axialPuKn = 650.0;
  bool _render3DActive = false;
  late ConnectionDetailResult _result;

  static const List<MapEntry<String, String>> _archetypes = [
    MapEntry('SHEAR_TAB', 'BOLTED SHEAR TAB (§J3/J4)'),
    MapEntry('MOMENT_END_PLATE', 'EXTENDED MOMENT END-PLATE (DG 4)'),
    MapEntry('GUSSET_PLATE', 'BRACED GUSSET (WHITMORE 30°)'),
    MapEntry('BASEPLATE', 'COLUMN BASEPLATE & ANCHORS (DG 1)'),
  ];

  @override
  void initState() {
    super.initState();
    _connectionType = widget.initialConnectionType;
    _selectedJointId = widget.initialJointId ??
        (widget.model.nodes.isNotEmpty ? widget.model.nodes.first.id : 'N1');
    _recompute();
  }

  List<double> _getJointCoords() {
    final node = widget.model.getNode(_selectedJointId);
    if (node != null) {
      return [node.x, node.y, node.z];
    }
    return const [0.0, 3.6, 0.0];
  }

  void _recompute() {
    _result = ConnectionDetailerService.evaluateConnection(
      connectionType: _connectionType,
      jointId: _selectedJointId,
      jointCoordsM: _getJointCoords(),
      shearVuKn: _shearVuKn,
      momentMuKnm: _momentMuKnm,
      axialPuKn: _axialPuKn,
      boltGrade: _boltGrade,
      numBolts: _numBolts,
      plateThicknessMm: _plateThicknessMm,
    );
    if (_render3DActive) {
      ThreeJsViewportBridge.render3DConnectionAssembly(_result.toViewportJson());
    }
  }

  void _toggle3DViewportRender() {
    setState(() {
      _render3DActive = !_render3DActive;
      if (_render3DActive) {
        ThreeJsViewportBridge.render3DConnectionAssembly(_result.toViewportJson());
      } else {
        ThreeJsViewportBridge.clear3DConnectionAssemblies();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPass = _result.overallStatus == 'PASS';
    final statusColor = isPass ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: GlassPod(
        width: 980,
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
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.hardware_rounded,
                          color: Color(0xFF00F0FF),
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
                                    'AISC 360-16 CHAPTER J 3D CONNECTION & BASEPLATE SYNTHESIZER',
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
                                  title: 'Deterministic AISC 360-16 Chapter J Detailer',
                                  codeRef: 'AISC 360-16 Ch. J & DG 1 / 4 / 16',
                                  message:
                                      'Evaluates bolt shear, bearing/tear-out, block shear (§J4.3), end-plate yield lines, Whitmore 30° gusset dispersion, Thornton buckling, and concrete foundation bearing, and synthesizes 3D hex-bolt/plate assemblies directly in Three.js.',
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Target Joint: $_selectedJointId • Governing DCR: ${_result.governingDcr.toStringAsFixed(3)} (${_result.governingLimitState})',
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
                  tooltip: 'Close Connection Synthesizer',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Connection Archetype Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _archetypes.map((entry) {
                  final isSel = _connectionType == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _connectionType = entry.key;
                          if (_connectionType == 'MOMENT_END_PLATE') {
                            _numBolts = 8;
                            _plateThicknessMm = 25.4;
                          } else if (_connectionType == 'GUSSET_PLATE') {
                            _numBolts = 6;
                            _plateThicknessMm = 16.0;
                          } else if (_connectionType == 'BASEPLATE') {
                            _numBolts = 4;
                            _plateThicknessMm = 25.4;
                          } else {
                            _numBolts = 4;
                            _plateThicknessMm = 12.7;
                          }
                          _recompute();
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF00F0FF) : const Color(0xFF131B2E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? const Color(0xFF00F0FF) : Colors.white12,
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.white70,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Parameter Control Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Bolt Grade Selector
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'BOLT GRADE:',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const InfoTooltip(
                        title: 'High-Strength Structural Bolts',
                        codeRef: 'AISC 360-16 Table J3.2',
                        message:
                            '• Group A (ASTM F3125 Gr. A325): F_nt = 620 MPa, F_nv = 372 MPa\n• Group B (ASTM F3125 Gr. A490): F_nt = 780 MPa, F_nv = 457 MPa.',
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      for (final g in const ['A325', 'A490'])
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ChoiceChip(
                            label: Text(g, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            selected: _boltGrade == g,
                            selectedColor: const Color(0xFF00F0FF),
                            backgroundColor: const Color(0xFF1E293B),
                            labelStyle: TextStyle(color: _boltGrade == g ? Colors.black : Colors.white),
                            onSelected: (_) {
                              setState(() {
                                _boltGrade = g;
                                _recompute();
                              });
                            },
                          ),
                        ),
                    ],
                  ),

                  // Bolt Count Selector
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'BOLTS:',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      for (final nb in const [4, 6, 8])
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ChoiceChip(
                            label: Text('${nb}B', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            selected: _numBolts == nb,
                            selectedColor: const Color(0xFF00F0FF),
                            backgroundColor: const Color(0xFF1E293B),
                            labelStyle: TextStyle(color: _numBolts == nb ? Colors.black : Colors.white),
                            onSelected: (_) {
                              setState(() {
                                _numBolts = nb;
                                _recompute();
                              });
                            },
                          ),
                        ),
                    ],
                  ),

                  // Plate Thickness Slider
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PLATE t_p: ${_plateThicknessMm.toStringAsFixed(1)} mm',
                        style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        width: 120,
                        child: Slider(
                          value: _plateThicknessMm.clamp(9.5, 38.0),
                          min: 9.5,
                          max: 38.0,
                          activeColor: const Color(0xFF00F0FF),
                          onChanged: (v) {
                            setState(() {
                              _plateThicknessMm = v;
                              _recompute();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Main Split View: Left 2D Shop Drawing SVG + Right Limit-State DCR Table
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: 2D Dimensioned Shop-Detail SVG Blueprint
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1320),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.architecture_rounded, size: 15, color: Color(0xFF00F0FF)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '2D DIMENSIONED SHOP DETAIL (${_result.connectionType})',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const InfoTooltip(
                                title: '2D Fabrication Shop Blueprint',
                                codeRef: 'AISC Detailing Manual',
                                message:
                                    'Displays plate geometry, bolt pitch (s = 76.2 mm), gauge (g = 140 mm), edge distance (Le = 38.1 mm), and Whitmore 30° dispersion lines.',
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF080C14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: CustomPaint(
                                painter: _ShopDetailBlueprintPainter(result: _result),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Required t_p,min: ${_result.requiredPlateThicknessMm.toStringAsFixed(1)} mm  •  Provided t_p: ${_result.providedPlateThicknessMm.toStringAsFixed(1)} mm  •  Fillet Weld: ${_result.recommendedWeldLegMm.toStringAsFixed(1)} mm'
                            '${_result.whitmoreWidthMm != null ? "  •  Whitmore L_w: ${_result.whitmoreWidthMm!.toStringAsFixed(1)} mm" : ""}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Right: AISC 360-16 Chapter J Limit-State DCR Breakdown Table
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1320),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: const [
                                    Icon(Icons.fact_check_rounded, size: 15, color: Color(0xFF00F0FF)),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'AISC 360-16 CHAPTER J LIMIT-STATE AUDIT',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                                ),
                                child: Text(
                                  '${_result.overallStatus} (MAX DCR ${_result.governingDcr.toStringAsFixed(3)})',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _result.limitStates.length,
                              itemBuilder: (ctx, i) {
                                final ls = _result.limitStates[i];
                                final cColor = ls.dcr <= 1.0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141D2F),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: cColor.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      ls.name,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 1.5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF7EE787)
                                                          .withValues(alpha: 0.14),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      ls.clause,
                                                      style: const TextStyle(
                                                        color: Color(0xFF7EE787),
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Demand: ${ls.demand.toStringAsFixed(1)} ${ls.unit}  •  Capacity φR_n: ${ls.capacityPhiRn.toStringAsFixed(1)} ${ls.unit}  •  ${ls.formula}',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.65),
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'DCR ${ls.dcr.toStringAsFixed(3)}',
                                          style: TextStyle(
                                            color: cColor,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InfoTooltip(
                                          title: ls.name,
                                          codeRef: ls.clause,
                                          message:
                                              'Governing Equation: ${ls.formula}\nFactored Demand = ${ls.demand.toStringAsFixed(2)} ${ls.unit} vs. Design Strength φR_n = ${ls.capacityPhiRn.toStringAsFixed(2)} ${ls.unit} (DCR = ${ls.dcr.toStringAsFixed(3)}).',
                                          size: 14,
                                        ),
                                      ],
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
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Footer with 1-Click 3D Connection Assembly Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Synthesizes extruded steel plates & 3D hex-head $_boltGrade bolts color-coded by DCR at Joint $_selectedJointId',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CLOSE', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _render3DActive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF00F0FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(
                        _render3DActive ? Icons.view_in_ar_rounded : Icons.bolt_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _render3DActive
                            ? '3D CONNECTION ACTIVE IN VIEWPORT (CLICK TO CLEAR)'
                            : 'RENDER 3D CONNECTION IN VIEWPORT',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                      ),
                      onPressed: _toggle3DViewportRender,
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
}

class _ShopDetailBlueprintPainter extends CustomPainter {
  final ConnectionDetailResult result;

  _ShopDetailBlueprintPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    final platePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (result.connectionType == 'GUSSET_PLATE') {
      final path = Path()
        ..moveTo(cx - 95, cy + 75)
        ..lineTo(cx + 85, cy + 75)
        ..lineTo(cx + 85, cy - 10)
        ..lineTo(cx - 10, cy - 85)
        ..lineTo(cx - 95, cy - 85)
        ..close();
      canvas.drawPath(path, platePaint);
      canvas.drawPath(path, borderPaint);

      // Whitmore 30-deg dispersion lines
      final whitmorePaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(cx - 45, cy + 40), Offset(cx + 55, cy - 45), whitmorePaint);
    } else {
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: 150, height: 185);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), platePaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), borderPaint);
    }

    // Draw Hex Bolts
    final nBolts = result.bolts3d.length;
    for (int i = 0; i < nBolts; i++) {
      final b = result.bolts3d[i];
      final bColor = b.utilizationDcr > 1.0
          ? const Color(0xFFEF4444)
          : (b.utilizationDcr >= 0.80 ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
      final bx = cx + (b.localZM * 320.0);
      final by = cy - (b.localYM * 260.0);
      canvas.drawCircle(Offset(bx, by), 7.5, Paint()..color = bColor);
      canvas.drawCircle(
        Offset(bx, by),
        7.5,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShopDetailBlueprintPainter oldDelegate) =>
      oldDelegate.result != result;
}
