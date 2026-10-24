import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/structural_api_service.dart';

class GenerativeBracingDialog extends StatefulWidget {
  final StructuralModel model;
  final StructuralApiService apiService;
  final VoidCallback onStructureModified;

  const GenerativeBracingDialog({
    super.key,
    required this.model,
    required this.apiService,
    required this.onStructureModified,
  });

  static Future<void> show(
    BuildContext context, {
    required StructuralModel model,
    required StructuralApiService apiService,
    required VoidCallback onStructureModified,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GenerativeBracingDialog(
        model: model,
        apiService: apiService,
        onStructureModified: onStructureModified,
      ),
    );
  }

  @override
  State<GenerativeBracingDialog> createState() => _GenerativeBracingDialogState();
}

class _GenerativeBracingDialogState extends State<GenerativeBracingDialog> {
  bool _isLoading = false;
  double _driftLimitRatio = 1.0 / 400.0;
  Map<String, dynamic>? _optimizationResult;

  @override
  void initState() {
    super.initState();
    _runGenerativeSearch();
  }

  void _runGenerativeSearch() async {
    setState(() => _isLoading = true);
    final res = await widget.apiService.optimizeGenerativeBracing(
      widget.model,
      targetDriftRatio: _driftLimitRatio,
    );
    setState(() {
      _isLoading = false;
      _optimizationResult = res;
    });
  }

  void _applyBracing(Map<String, dynamic> candidate) {
    final addedNodes = candidate['added_nodes'] as List<dynamic>? ?? [];
    final addedMembers = candidate['added_members'] as List<dynamic>? ?? [];

    for (final rawNode in addedNodes) {
      final n = rawNode as Map<String, dynamic>;
      final coords = n['coords'] as List<dynamic>? ?? [0.0, 0.0, 0.0];
      widget.model.nodes.add(StructuralNode(
        id: n['id'].toString(),
        x: (n['x'] as num?)?.toDouble() ?? (coords[0] as num).toDouble(),
        y: (n['y'] as num?)?.toDouble() ?? (coords[1] as num).toDouble(),
        z: (n['z'] as num?)?.toDouble() ?? (coords[2] as num).toDouble(),
        isRestrained: [false, false, false, false, false, false],
      ));
    }

    for (final rawMem in addedMembers) {
      final m = rawMem as Map<String, dynamic>;
      widget.model.members.add(StructuralMember(
        id: m['id'].toString(),
        startNodeId: (m['startNodeId'] ?? m['i_node']).toString(),
        endNodeId: (m['endNodeId'] ?? m['j_node']).toString(),
        sectionProfile: (m['sectionProfile'] ?? m['section'] ?? 'W10X33').toString(),
      ));
    }

    widget.onStructureModified();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully applied ${candidate['name']} (${addedMembers.length} braces added)!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opt = _optimizationResult;
    return Dialog(
      backgroundColor: const Color(0xFF0D1117),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Container(
        width: 860,
        height: 640,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purpleAccent),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'GENERATIVE TOPOLOGY & BRACING OPTIMIZATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'AI Layout Search • X-Bracing, Chevron, Diagonal • Minimum Steel Mass under ASCE 7 Drift Limits',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Parameter & control row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Text('TARGET DRIFT LIMIT:', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  DropdownButton<double>(
                    value: _driftLimitRatio,
                    dropdownColor: const Color(0xFF161B22),
                    style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 12, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 1.0 / 300.0, child: Text('Δ ≤ H/300 (Standard Frame)')),
                      DropdownMenuItem(value: 1.0 / 400.0, child: Text('Δ ≤ H/400 (ASCE 7 Standard)')),
                      DropdownMenuItem(value: 1.0 / 500.0, child: Text('Δ ≤ H/500 (Wind Drift Stiff)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _driftLimitRatio = val);
                        _runGenerativeSearch();
                      }
                    },
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runGenerativeSearch,
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('RE-SYNTHESIZE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
                      foregroundColor: Colors.purpleAccent,
                      side: const BorderSide(color: Colors.purpleAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.purpleAccent),
                          SizedBox(height: 16),
                          Text('Synthesizing bracing configurations & evaluating drift limits...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    )
                  : (opt == null
                      ? const Center(child: Text('No optimization results available', style: TextStyle(color: Colors.white54)))
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Optimal Banner
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF10B981)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.recommend_rounded, color: Color(0xFF10B981), size: 24),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'RECOMMENDED OPTIMAL TOPOLOGY: ${opt['optimal_system_name']}',
                                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'Drift reduced by ${opt['drift_reduction_percentage']}% with only +${opt['added_steel_tonnes']} tonnes of steel • α_cr = ${opt['stability_alpha_cr']}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Candidate Cards List
                              const Text('GENERATIVE CANDIDATE TOPOLOGIES', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...((opt['candidates_evaluated'] as List<dynamic>? ?? []).map((candRaw) {
                                final cand = candRaw as Map<String, dynamic>;
                                final isOpt = cand['topology'] == opt['optimal_topology'];
                                return _buildCandidateCard(cand, isOpt);
                              })),
                            ],
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> cand, bool isOptimal) {
    final compliant = cand['drift_compliant'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isOptimal ? const Color(0xFF10B981) : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOptimal ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              cand['topology'] == 'X_BRACE'
                  ? Icons.close_rounded
                  : (cand['topology'] == 'CHEVRON' ? Icons.expand_less_rounded : Icons.trending_up_rounded),
              color: isOptimal ? const Color(0xFF10B981) : Colors.white70,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cand['name'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: compliant
                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                            : const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        compliant ? 'DRIFT OK' : 'DRIFT FAIL',
                        style: TextStyle(
                          color: compliant ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isOptimal) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('OPTIMAL', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Drift: ${(cand['lateral_drift_m'] * 1000.0).toStringAsFixed(1)} mm (${cand['drift_ratio']}) • '
                  'Reduction: ${cand['drift_reduction_percent']}% • Added: +${cand['added_weight_kg']} kg • '
                  'α_cr = ${cand['alpha_cr']} (B2 = ${cand['b2']})',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _applyBracing(cand),
            icon: const Icon(Icons.check_rounded, size: 14),
            label: const Text('APPLY BRACING'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isOptimal ? const Color(0xFF10B981) : const Color(0xFF00F0FF).withValues(alpha: 0.2),
              foregroundColor: isOptimal ? Colors.black : const Color(0xFF00F0FF),
              side: BorderSide(color: isOptimal ? const Color(0xFF10B981) : const Color(0xFF00F0FF)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
