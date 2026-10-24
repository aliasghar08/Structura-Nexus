import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/structural_api_service.dart';

class GenerativeOptimizerDialog extends StatefulWidget {
  final StructuralModel model;
  final StructuralApiService apiService;
  final VoidCallback onStructureModified;

  const GenerativeOptimizerDialog({
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
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => GenerativeOptimizerDialog(
        model: model,
        apiService: apiService,
        onStructureModified: onStructureModified,
      ),
    );
  }

  @override
  State<GenerativeOptimizerDialog> createState() => _GenerativeOptimizerDialogState();
}

class _GenerativeOptimizerDialogState extends State<GenerativeOptimizerDialog> {
  bool _isLoading = true;
  GenerativeOptimizationResult? _result;

  @override
  void initState() {
    super.initState();
    _runOptimization();
  }

  Future<void> _runOptimization() async {
    setState(() => _isLoading = true);
    final res = await widget.apiService.runGenerativeOptimization(widget.model);
    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
    }
  }

  void _applyOptimizedSections() {
    if (_result == null) return;
    for (final entry in _result!.optimizedSectionsMap.entries) {
      final mem = widget.model.members.firstWhere(
        (m) => m.id == entry.key,
        orElse: () => widget.model.members.first,
      );
      mem.section = entry.value;
    }
    widget.onStructureModified();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generative Design applied! ${_result!.summary.weightReductionPct.toStringAsFixed(1)}% mass reduction saved.',
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1117),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 860,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hub_rounded, size: 22, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI GENERATIVE TOPOLOGY & MASS OPTIMIZER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Multi-Objective Genetic Algorithm  •  15-25% Mass Reduction  •  DCR <= 0.95',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 28),

            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: Color(0xFF10B981)),
                      SizedBox(height: 16),
                      Text(
                        'Executing Multi-Objective Evolutionary Algorithm (35 Iterations)...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Evaluating AISC 360-16 limit states and deflection limits',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              )
            else if (_result != null) ...[
              // Summary Cards Row
              Row(
                children: [
                  _buildMetricCard(
                    title: 'WEIGHT REDUCTION',
                    value: '${_result!.summary.weightReductionPct.toStringAsFixed(1)}%',
                    subtext: '${_result!.summary.weightReductionKg.toStringAsFixed(0)} kg saved',
                    color: const Color(0xFF10B981),
                    icon: Icons.trending_down_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: 'TOTAL STEEL MASS',
                    value: '${_result!.summary.optimizedTotalWeightKg.toStringAsFixed(0)} kg',
                    subtext: 'Down from ${_result!.summary.initialTotalWeightKg.toStringAsFixed(0)} kg',
                    color: const Color(0xFF58A6FF),
                    icon: Icons.scale_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: 'PEAK GOVERNING DCR',
                    value: _result!.summary.optimizedMaxDcr.toStringAsFixed(2),
                    subtext: 'Baseline was ${_result!.summary.initialMaxDcr.toStringAsFixed(2)}',
                    color: _result!.summary.optimizedMaxDcr <= 0.95
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    icon: Icons.verified_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: 'CODE COMPLIANCE',
                    value: _result!.codeComplianceVerified ? 'PASS' : 'WARNING',
                    subtext: 'AISC 360-16 DCR <= 1.0',
                    color: const Color(0xFF00F0FF),
                    icon: Icons.gavel_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Member Details Schedule
              const Text(
                'MEMBER-BY-MEMBER OPTIMAL PROFILES SCHEDULE',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ListView.separated(
                    itemCount: _result!.memberDetails.length,
                    separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (ctx, idx) {
                      final item = _result!.memberDetails[idx];
                      final isReduced = item.optimizedWeightKg < item.originalWeightKg;
                      final isUpsized = item.optimizedWeightKg > item.originalWeightKg;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF21262D),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item.memberId,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.originalSection,
                                        style: TextStyle(
                                          color: isReduced ? Colors.white38 : Colors.white70,
                                          fontSize: 12,
                                          decoration: isReduced ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      if (item.originalSection != item.optimizedSection) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF10B981)),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.optimizedSection,
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${item.optimizedWeightKg.toStringAsFixed(1)} kg (${item.weightSavedPct >= 0 ? '-' : '+'}${item.weightSavedPct.abs().toStringAsFixed(1)}%)',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'DCR: ${item.originalDcr.toStringAsFixed(2)} → ${item.optimizedDcr.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: item.optimizedDcr <= 0.95 ? Colors.white70 : Colors.redAccent,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isReduced
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : (isUpsized ? const Color(0xFF3B82F6).withValues(alpha: 0.15) : const Color(0xFF6B7280).withValues(alpha: 0.15)),
                                border: Border.all(
                                  color: isReduced
                                      ? const Color(0xFF10B981)
                                      : (isUpsized ? const Color(0xFF3B82F6) : Colors.white24),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.status,
                                style: TextStyle(
                                  color: isReduced
                                      ? const Color(0xFF10B981)
                                      : (isUpsized ? const Color(0xFF60A5FA) : Colors.white70),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _applyOptimizedSections,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      'Apply Generative Design',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }
}
