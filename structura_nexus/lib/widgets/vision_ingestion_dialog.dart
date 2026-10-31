// ============================================================================
// VisionIngestionDialog — AI Vision-to-BIM Floorplan Ingestion Pipeline
// Ingests 2D architectural plans (PDF/PNG/JPEG) and synthesizes 3D space frames
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/structural_api_service.dart';
import 'glass_pod.dart';

class VisionIngestionDialog extends StatefulWidget {
  final StructuralApiService apiService;
  final Function(StructuralModel)? onModelSynthesized;
  final Function(StructuralModel)? onModelGenerated;

  const VisionIngestionDialog({
    super.key,
    required this.apiService,
    this.onModelSynthesized,
    this.onModelGenerated,
  }) : assert(onModelSynthesized != null || onModelGenerated != null,
            'Must provide onModelSynthesized or onModelGenerated');

  static Future<void> show(
    BuildContext context, {
    required StructuralApiService apiService,
    Function(StructuralModel)? onModelSynthesized,
    Function(StructuralModel)? onModelGenerated,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => VisionIngestionDialog(
        apiService: apiService,
        onModelSynthesized: onModelSynthesized,
        onModelGenerated: onModelGenerated,
      ),
    );
  }

  @override
  State<VisionIngestionDialog> createState() => _VisionIngestionDialogState();
}

class _VisionIngestionDialogState extends State<VisionIngestionDialog> {
  int _numStories = 3;
  double _storyHeightM = 3.6;
  String _selectedColSection = 'W14X90';
  String _selectedBeamSection = 'W18X50';
  String _selectedFilename = 'sample_office_floorplan.png';
  bool _isProcessing = false;
  String? _statusText;
  Map<String, dynamic>? _synthesizedResult;

  final List<String> _columnSections = ['W14X90', 'W14X120', 'W12X65', 'W14X48'];
  final List<String> _beamSections = ['W18X50', 'W16X40', 'W21X62', 'W12X30'];

  void _triggerSynthesis() async {
    setState(() {
      _isProcessing = true;
      _statusText = 'Ingesting floorplan vectors & detecting structural gridlines...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _statusText = 'Gemini Multimodal: Extracting shear walls and column coordinates...';
    });

    final res = await widget.apiService.synthesizeVisionToBim(
      filename: _selectedFilename,
      numStories: _numStories,
      storyHeightM: _storyHeightM,
      defaultColumnSection: _selectedColSection,
      defaultBeamSection: _selectedBeamSection,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _synthesizedResult = res;
      _statusText = '3D Frame Topology Synthesized Successfully!';
    });
  }

  void _applyToCanvas() {
    if (_synthesizedResult == null) return;
    final modelMap = _synthesizedResult!['synthesized_model'] as Map<String, dynamic>?;
    if (modelMap == null) return;

    final rawNodes = modelMap['nodes'] as List? ?? [];
    final rawMembers = modelMap['members'] as List? ?? [];

    final nodes = <StructuralNode>[];
    for (final rn in rawNodes) {
      final c = rn['coords'] as List;
      final rest = rn['restraint'] as List;
      final ld = rn['loads'] as List;
      nodes.add(StructuralNode(
        id: rn['id'] as String,
        x: (c[0] as num).toDouble(),
        y: (c[1] as num).toDouble(),
        z: (c[2] as num).toDouble(),
        restraint: List<int>.from(rest.map((e) => (e as num).toInt())),
        loads: [
          (ld[0] as num).toDouble(),
          (ld[1] as num).toDouble(),
          (ld[2] as num).toDouble(),
          0.0,
          0.0,
          0.0,
        ],
      ));
    }

    final members = <StructuralMember>[];
    for (final rm in rawMembers) {
      members.add(StructuralMember(
        id: rm['id'] as String,
        iNodeId: rm['i_node'] as String,
        jNodeId: rm['j_node'] as String,
        section: rm['section'] as String,
        material: rm['material'] as String? ?? 'A992_STEEL',
      ));
    }

    final newModel = StructuralModel(
      nodes: nodes,
      members: members,
    );

    widget.onModelSynthesized?.call(newModel);
    widget.onModelGenerated?.call(newModel);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 700;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isCompact ? size.width * 0.94 : 560,
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
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF00F0FF), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'VISION-TO-BIM STUDIO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              '2D Architectural Plan Ingestion & Autonomous 3D Synthesis',
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // File Dropzone Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                        width: 1.2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_upload_outlined, color: Color(0xFF00F0FF), size: 36),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFilename,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Drag & drop architectural floor plan (PDF, PNG, JPEG) or click to browse',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildSampleChip('Office_Tower_L1.png'),
                            _buildSampleChip('Commercial_Core_P1.pdf'),
                            _buildSampleChip('Residential_Grid_A.jpg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Parameters: Stories & Height
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STORIES: $_numStories',
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                activeTrackColor: const Color(0xFF00F0FF),
                                inactiveTrackColor: Colors.white12,
                                thumbColor: const Color(0xFF00F0FF),
                              ),
                              child: Slider(
                                value: _numStories.toDouble(),
                                min: 1,
                                max: 10,
                                divisions: 9,
                                onChanged: (v) => setState(() => _numStories = v.round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STORY HEIGHT: ${_storyHeightM.toStringAsFixed(1)}m',
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                activeTrackColor: const Color(0xFF00F0FF),
                                inactiveTrackColor: Colors.white12,
                                thumbColor: const Color(0xFF00F0FF),
                              ),
                              child: Slider(
                                value: _storyHeightM,
                                min: 2.8,
                                max: 5.0,
                                divisions: 22,
                                onChanged: (v) => setState(() => _storyHeightM = (v * 10).round() / 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Default Member Sections
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('COLUMN SECTION', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            const SizedBox(height: 4),
                            _buildDropdown(_selectedColSection, _columnSections, (v) => setState(() => _selectedColSection = v!)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('GIRDER SECTION', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            const SizedBox(height: 4),
                            _buildDropdown(_selectedBeamSection, _beamSections, (v) => setState(() => _selectedBeamSection = v!)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Progress & Status
                  if (_isProcessing)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF00F0FF)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _statusText ?? 'Processing...',
                            style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else if (_synthesizedResult != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '3D Space Frame Ready to Mount',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Nodes: ${_synthesizedResult!['node_count']}  •  Members: ${_synthesizedResult!['member_count']}  •  Height: ${_synthesizedResult!['total_height_m']}m',
                                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF00F0FF)),
                          label: const Text('Process Floorplan', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11.5)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF00F0FF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isProcessing ? null : _triggerSynthesis,
                        ),
                      ),
                      if (_synthesizedResult != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.view_in_ar_rounded, size: 15, color: Colors.black),
                            label: const Text('Synthesize 3D Frame', style: TextStyle(color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.w900)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00F0FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _applyToCanvas,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSampleChip(String filename) {
    final isSelected = _selectedFilename == filename;
    return InkWell(
      onTap: () => setState(() => _selectedFilename = filename),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white12,
            width: 0.8,
          ),
        ),
        child: Text(
          filename,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white60,
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          dropdownColor: const Color(0xFF161B22),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
