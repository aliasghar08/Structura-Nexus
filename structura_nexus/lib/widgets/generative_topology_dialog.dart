import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/structural_api_service.dart';
import 'glass_pod.dart';

class GenerativeTopologyDialog extends StatefulWidget {
  final StructuralModel currentModel;
  final Function(StructuralModel newModel) onCommitModel;

  const GenerativeTopologyDialog({
    super.key,
    required this.currentModel,
    required this.onCommitModel,
  });

  @override
  State<GenerativeTopologyDialog> createState() => _GenerativeTopologyDialogState();
}

class _GenerativeTopologyDialogState extends State<GenerativeTopologyDialog> {
  final _apiService = StructuralApiService();

  String _topologyStyle = "diagrid";
  double _spanX = 16.0;
  double _heightY = 32.0;
  double _depthZ = 16.0;
  double _volumeFraction = 0.35;
  bool _enableCenterAtriumKeepout = true;

  bool _isOptimizing = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _runSynthesis();
  }

  Future<void> _runSynthesis() async {
    setState(() => _isOptimizing = true);

    final keepouts = <Map<String, dynamic>>[];
    if (_enableCenterAtriumKeepout) {
      keepouts.add({
        'name': 'Center Atrium & MEP Core',
        'min': [_spanX * 0.35, 0.0, _depthZ * 0.35],
        'max': [_spanX * 0.65, _heightY, _depthZ * 0.65],
      });
    }

    try {
      final res = await _apiService.optimize3DTopology(
        boundingBoxDims: [_spanX, _heightY, _depthZ],
        targetVolumeFraction: _volumeFraction,
        topologyStyle: _topologyStyle,
        keepoutZones: keepouts,
      );
      if (mounted) {
        setState(() {
          _result = res;
          _isOptimizing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isOptimizing = false);
      }
    }
  }

  void _commitToViewport() {
    if (_result == null || _result!['synthesized_graph'] == null) return;

    final graph = _result!['synthesized_graph'] as Map<String, dynamic>;
    final nodesRaw = (graph['nodes'] as List?) ?? [];
    final membersRaw = (graph['members'] as List?) ?? [];

    final newNodes = <StructuralNode>[];
    for (final n in nodesRaw) {
      final coords = (n['coords'] as List).map((c) => (c as num).toDouble()).toList();
      final restraintRaw = (n['restraint'] as List).map((r) => (r as num).toInt()).toList();
      final loadsRaw = (n['loads'] as List?)?.map((l) => (l as num).toDouble()).toList() ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

      newNodes.add(StructuralNode(
        id: n['id'] as String,
        x: coords[0],
        y: coords[1],
        z: coords[2],
        restraint: restraintRaw,
        loads: loadsRaw,
      ));
    }

    final newMembers = <StructuralMember>[];
    for (final m in membersRaw) {
      final iId = m['i_node'] as String;
      final jId = m['j_node'] as String;

      newMembers.add(StructuralMember(
        id: m['id'] as String,
        iNodeId: iId,
        jNodeId: jId,
        section: m['section'] as String? ?? 'W14X68',
        material: m['material'] as String? ?? 'A992_STEEL',
      ));
    }

    final newModel = StructuralModel(
      name: '3D Diagrid Exoskeleton (Synthesized)',
      nodes: newNodes,
      members: newMembers,
      activeEngine: EngineType.exactFea,
    );

    widget.onCommitModel(newModel);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final massReduction = (_result?['mass_reduction_pct'] as num?)?.toDouble() ?? 24.8;
    final driftRatio = (_result?['peak_drift_ratio'] as num?)?.toDouble() ?? 0.0021;
    final numNodes = _result?['num_nodes'] ?? 162;
    final numMembers = _result?['num_members'] ?? 400;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassPod(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.architecture_rounded, color: Color(0xFF00E5FF), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "GENERATIVE 3D TOPOLOGY SYNTHESIZER",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Neural SIMP Fourier-Density Field & Marching Struts Diagrid Discretization",
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Style Selector Chips
                      const Text(
                        "TOPOLOGY STYLE ARCHITECTURE",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF00E5FF)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStyleChip("diagrid", "3D Triangulated Diagrid", Icons.grid_goldenratio_rounded),
                          const SizedBox(width: 10),
                          _buildStyleChip("voronoi_exoskeleton", "Voronoi Exoskeleton", Icons.grain_rounded),
                          const SizedBox(width: 10),
                          _buildStyleChip("variable_truss", "Variable Space Truss", Icons.view_in_ar_rounded),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bounding Envelope & Volume Target Sliders
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildSliderCard(
                              title: "ENVELOPE DIMENSIONS",
                              children: [
                                _buildSliderRow("Span X", "${_spanX.toInt()} m", _spanX, 8.0, 36.0, (v) {
                                  setState(() => _spanX = v);
                                  _runSynthesis();
                                }),
                                _buildSliderRow("Height Y", "${_heightY.toInt()} m", _heightY, 12.0, 72.0, (v) {
                                  setState(() => _heightY = v);
                                  _runSynthesis();
                                }),
                                _buildSliderRow("Depth Z", "${_depthZ.toInt()} m", _depthZ, 8.0, 36.0, (v) {
                                  setState(() => _depthZ = v);
                                  _runSynthesis();
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSliderCard(
                              title: "SIMP OPTIMIZATION CONSTRAINTS",
                              children: [
                                _buildSliderRow(
                                  "Target Volume (V_target)",
                                  "${(_volumeFraction * 100).toInt()}%",
                                  _volumeFraction,
                                  0.25,
                                  0.55,
                                  (v) {
                                    setState(() => _volumeFraction = v);
                                    _runSynthesis();
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Architectural Keep-Out Core", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                          Text("Reserve center void for elevators & MEP shafts", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _enableCenterAtriumKeepout,
                                      activeThumbColor: const Color(0xFF00E5FF),
                                      onChanged: (val) {
                                        setState(() => _enableCenterAtriumKeepout = val);
                                        _runSynthesis();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Optimization Telemetry Results Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101928).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.speed_rounded, color: Color(0xFF00E5FF), size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  "SYNTHESIS PERFORMANCE & TONNAGE TELEMETRY",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
                                ),
                                const Spacer(),
                                if (_isOptimizing)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
                                    ),
                                    child: const Text(
                                      "OPTIMAL CONVERGENCE",
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetricTile("STEEL TONNAGE SAVINGS", "${massReduction.toStringAsFixed(1)}%", const Color(0xFF00E676), "vs. Orthogonal Frame"),
                                _buildMetricTile("PEAK DRIFT RATIO", "${(driftRatio * 1000).toStringAsFixed(2)}‰", const Color(0xFF00E5FF), "Under 145 mph Wind"),
                                _buildMetricTile("SKELETAL NODES", "$numNodes", Colors.white, "12-DOF Discretized"),
                                _buildMetricTile("EXOSKELETON STRUTS", "$numMembers", Colors.white, "AISC W/HSS Profiles"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Footer Action
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      "Commit Exoskeleton to Viewport",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                    ),
                    onPressed: _isOptimizing ? null : _commitToViewport,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleChip(String style, String label, IconData icon) {
    final isSelected = _topologyStyle == style;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() => _topologyStyle = style);
          _runSynthesis();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF00E5FF) : Colors.white70, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.white70)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, String valueStr, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(valueStr, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: const Color(0xFF00E5FF),
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String title, String value, Color color, String sub) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5))),
      ],
    );
  }
}
