import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/structural_api_service.dart';

class EmbodiedCarbonDialog extends StatefulWidget {
  final StructuralModel model;
  final StructuralApiService apiService;

  const EmbodiedCarbonDialog({
    super.key,
    required this.model,
    required this.apiService,
  });

  static Future<void> show(
    BuildContext context, {
    required StructuralModel model,
    required StructuralApiService apiService,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => EmbodiedCarbonDialog(
        model: model,
        apiService: apiService,
      ),
    );
  }

  @override
  State<EmbodiedCarbonDialog> createState() => _EmbodiedCarbonDialogState();
}

class _EmbodiedCarbonDialogState extends State<EmbodiedCarbonDialog> {
  bool _isLoading = true;
  EmbodiedCarbonReport? _report;

  @override
  void initState() {
    super.initState();
    _fetchCarbon();
  }

  Future<void> _fetchCarbon() async {
    setState(() => _isLoading = true);
    final res = await widget.apiService.runEmbodiedCarbonAssessment(widget.model);
    if (mounted) {
      setState(() {
        _report = res;
        _isLoading = false;
      });
    }
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
        width: 840,
        height: 630,
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
                      colors: [Color(0xFF059669), Color(0xFF34D399)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco_rounded, size: 22, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI EMBODIED CARBON & SUSTAINABILITY LCA ENGINE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'SE 2050 Commitment  •  LEED v4.1 MRc1 LCA  •  EN 15804 EPD Emissions',
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
                        'Calculating Cradle-to-Gate Embodied Carbon Footprint...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Benchmarking Primary BF-BOF vs Recycled EAF Structural Steel',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              )
            else if (_report != null) ...[
              // Sustainability KPI Cards
              Row(
                children: [
                  _buildMetricCard(
                    title: 'CARBON REDUCTION',
                    value: '${_report!.potentialCarbonReductionPct.toStringAsFixed(1)}%',
                    subtext: 'Via EAF Recycled Steel',
                    color: const Color(0xFF10B981),
                    icon: Icons.energy_savings_leaf_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: 'BASELINE EMISSIONS',
                    value: '${_report!.baselineEmbodiedCarbonKgCo2e.toStringAsFixed(0)} kg',
                    subtext: 'Standard BF-BOF steel',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.cloud_outlined,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: 'LOW-CARBON TARGET',
                    value: '${_report!.optimizedLowCarbonKgCo2e.toStringAsFixed(0)} kg',
                    subtext: 'Electric Arc Furnace',
                    color: const Color(0xFF34D399),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: 'STEEL TONNAGE',
                    value: '${(_report!.totalSteelWeightKg / 1000.0).toStringAsFixed(2)} t',
                    subtext: '${_report!.totalSteelWeightKg.toStringAsFixed(0)} kg total',
                    color: const Color(0xFF00F0FF),
                    icon: Icons.line_weight_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Certification Badges
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _report!.leedCreditStatus,
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF60A5FA)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _report!.se2050ComplianceStatus,
                              style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Green Procurement Recommendations
              const Text(
                'GREEN SPECIFICATIONS & EMBODIED CARBON REDUCTION MEASURES',
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ListView.separated(
                    itemCount: _report!.greenRecommendations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final rec = _report!.greenRecommendations[idx];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rec,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
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
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21262D),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
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
              style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold),
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
