// ============================================================================
// FoundationStudioDialog — Geotechnical Foundation & SSI Studio (ACI 318-19)
// Winkler Elastic Soil Springs, Allowable Bearing, Two-Way Punching Shear
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/structural_api_service.dart';
import 'glass_pod.dart';

class FoundationStudioDialog extends StatefulWidget {
  final StructuralModel model;
  final StructuralApiService apiService;
  final VoidCallback? onStructureModified;
  final void Function(String, VoidCallback)? onRequireAuth;

  const FoundationStudioDialog({
    super.key,
    required this.model,
    required this.apiService,
    this.onStructureModified,
    this.onRequireAuth,
  });

  static Future<void> show(
    BuildContext context, {
    required StructuralModel model,
    required StructuralApiService apiService,
    VoidCallback? onStructureModified,
    void Function(String, VoidCallback)? onRequireAuth,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => FoundationStudioDialog(
        model: model,
        apiService: apiService,
        onStructureModified: onStructureModified,
        onRequireAuth: onRequireAuth,
      ),
    );
  }

  @override
  State<FoundationStudioDialog> createState() => _FoundationStudioDialogState();
}

class _FoundationStudioDialogState extends State<FoundationStudioDialog> {
  double _ksModulus = 45000.0; // kN/m^3
  double _qAllow = 280.0; // kPa
  double _footingWidthB = 2.5; // m
  double _footingLengthL = 2.5; // m
  double _footingThicknessT = 0.60; // m
  bool _isEvaluating = false;
  Map<String, dynamic>? _results;

  @override
  void initState() {
    super.initState();
    _evaluateFoundations();
  }

  void _evaluateFoundations() async {
    setState(() => _isEvaluating = true);
    final res = await widget.apiService.evaluateGeotechnicalFoundations(
      model: widget.model,
      subgradeModulusKs: _ksModulus,
      footingWidthB: _footingWidthB,
      footingLengthL: _footingLengthL,
      footingThicknessT: _footingThicknessT,
      allowableBearingKpa: _qAllow,
    );
    if (!mounted) return;
    setState(() {
      _isEvaluating = false;
      _results = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 700;

    final maxBearingDcr = (_results?['max_bearing_dcr'] as num?)?.toDouble() ?? 0.0;
    final maxPunchingDcr = (_results?['max_punching_dcr'] as num?)?.toDouble() ?? 0.0;
    final isPass = (_results?['is_all_passed'] as bool?) ?? (maxBearingDcr <= 1.0 && maxPunchingDcr <= 1.0);
    final pressurePoints = (_results?['support_pressure_points'] as List?) ?? [];
    final winklerSprings = (_results?['winkler_springs'] as Map<String, dynamic>?) ?? {};

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isCompact ? size.width * 0.94 : 580,
          maxHeight: size.height * 0.88,
        ),
        child: Material(
          color: Colors.transparent,
          child: GlassPod(
            padding: const EdgeInsets.all(22),
            borderRadius: 24,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.terrain_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'GEOTECHNICAL FOUNDATION STUDIO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'ACI 318-19 Punching Shear • 6-DOF Winkler Soil Springs',
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      if (_isEvaluating)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // DCR Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: (isPass ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isPass ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPass ? Icons.verified_rounded : Icons.warning_amber_rounded,
                          color: isPass ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPass ? 'FOUNDATION SYSTEM CERTIFIED PASS' : 'FOUNDATION CAPACITY EXCEEDED',
                                style: TextStyle(
                                  color: isPass ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                'Max Bearing DCR: ${maxBearingDcr.toStringAsFixed(3)}  •  Punching Shear DCR: ${maxPunchingDcr.toStringAsFixed(3)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interactive Sliders: Subgrade Modulus & Allowable Bearing
                  _buildSlider(
                    label: 'SUBGRADE MODULUS (ks)',
                    valueString: '${(_ksModulus / 1000.0).toStringAsFixed(0)} MN/m³ (${_ksModulus.toStringAsFixed(0)} kN/m³)',
                    value: _ksModulus,
                    min: 15000.0,
                    max: 100000.0,
                    onChanged: (v) {
                      setState(() => _ksModulus = v);
                      _evaluateFoundations();
                    },
                  ),
                  const SizedBox(height: 10),

                  _buildSlider(
                    label: 'ALLOWABLE BEARING (q_allow)',
                    valueString: '${_qAllow.toStringAsFixed(0)} kPa',
                    value: _qAllow,
                    min: 120.0,
                    max: 600.0,
                    onChanged: (v) {
                      setState(() => _qAllow = v);
                      _evaluateFoundations();
                    },
                  ),
                  const SizedBox(height: 10),

                  // Footing Geometry: B, L, T
                  Row(
                    children: [
                      Expanded(
                        child: _buildSlider(
                          label: 'WIDTH (B)',
                          valueString: '${_footingWidthB.toStringAsFixed(1)}m',
                          value: _footingWidthB,
                          min: 1.5,
                          max: 6.0,
                          onChanged: (v) {
                            setState(() => _footingWidthB = (v * 10).round() / 10);
                            _evaluateFoundations();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSlider(
                          label: 'LENGTH (L)',
                          valueString: '${_footingLengthL.toStringAsFixed(1)}m',
                          value: _footingLengthL,
                          min: 1.5,
                          max: 6.0,
                          onChanged: (v) {
                            setState(() => _footingLengthL = (v * 10).round() / 10);
                            _evaluateFoundations();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSlider(
                          label: 'THICKNESS (T)',
                          valueString: '${(_footingThicknessT * 100).toStringAsFixed(0)}cm',
                          value: _footingThicknessT,
                          min: 0.40,
                          max: 1.50,
                          onChanged: (v) {
                            setState(() => _footingThicknessT = (v * 100).round() / 100);
                            _evaluateFoundations();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Winkler Elastic 6-DOF Springs Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '6-DOF WINKLER ELASTIC SPRING MATRIX [K_soil]',
                          style: TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Ky (Vertical): ${((winklerSprings['ky_vertical_kn_m'] as num?)?.toDouble() ?? 0) / 1000} MN/m',
                              style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                            ),
                            Text(
                              'Kx, Kz (Sliding): ${((winklerSprings['kx_horizontal_kn_m'] as num?)?.toDouble() ?? 0) / 1000} MN/m',
                              style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                            ),
                            Text(
                              'Kθx, Kθz (Rocking): ${((winklerSprings['k_rot_x_knm_rad'] as num?)?.toDouble() ?? 0) / 1000} MN·m/rad',
                              style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Support Pressure Points Table
                  const Text(
                    'BASE SUPPORT CONTACT PRESSURES & PUNCHING SHEAR',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: pressurePoints.take(4).map((pt) {
                        final nid = pt['node_id'] as String;
                        final q = (pt['contact_pressure_kpa'] as num?)?.toDouble() ?? 0.0;
                        final bDcr = (pt['governing_dcr'] as num?)?.toDouble() ?? 0.0;
                        final pDcr = (pt['punching_shear_dcr'] as num?)?.toDouble() ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Joint $nid', style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 10, fontWeight: FontWeight.bold)),
                              Text('q = ${q.toStringAsFixed(1)} kPa', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                              Text('Bearing: ${bDcr.toStringAsFixed(3)}', style: TextStyle(color: bDcr <= 1.0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 10)),
                              Text('Punching: ${pDcr.toStringAsFixed(3)}', style: TextStyle(color: pDcr <= 1.0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 10)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 16, color: Colors.black),
                      label: const Text('Dismiss & Apply Soil Boundaries', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        widget.onStructureModified?.call();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required String valueString,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w800)),
            Text(valueString, style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
            activeTrackColor: const Color(0xFF00F0FF),
            inactiveTrackColor: Colors.white12,
            thumbColor: const Color(0xFF00F0FF),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
