import 'package:flutter/material.dart';
import '../models/structural_models.dart';

class CodeCompliancePanel extends StatelessWidget {
  final StructuralModel model;
  final VoidCallback onOptimize;
  final Function(String) onCombinationChanged;

  const CodeCompliancePanel({
    super.key,
    required this.model,
    required this.onOptimize,
    required this.onCombinationChanged,
  });

  @override
  Widget build(BuildContext context) {
    double maxDcr = 0.0;
    int passCount = 0;
    int failCount = 0;
    int warnCount = 0;

    for (final m in model.members) {
      if (m.governingDcr > maxDcr) maxDcr = m.governingDcr;
      if (m.governingDcr > 1.0) {
        failCount++;
      } else if (m.governingDcr > 0.85) {
        warnCount++;
      } else {
        passCount++;
      }
    }

    final isOverallPass = failCount == 0;
    final statusColor = isOverallPass
        ? (warnCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981))
        : const Color(0xFFFF0055);

    return Container(
      height: 205,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 1. Governing DCR Status Card
            Container(
              width: 210,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'AISC 360-16',
                          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOverallPass ? (warnCount > 0 ? 'MARGINAL' : 'PASSED') : 'VIOLATION',
                          style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          maxDcr.toStringAsFixed(3),
                          style: TextStyle(color: statusColor, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        const Text('MAX DCR', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    value: (maxDcr / 1.2).clamp(0.0, 1.0),
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 5,
                  ),
                  Text(
                    '$passCount Pass  •  $warnCount Warn  •  $failCount Fail',
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 2. Factored ASCE 7 Load Combinations
            Container(
              width: 320,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ASCE 7-16 LOAD COMBINATIONS',
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildComboBtn('1.4D', 'Dead Load'),
                      _buildComboBtn('1.2D+1.6L', 'Gravity Live'),
                      _buildComboBtn('1.2D+1.0W+0.5L', 'Wind Sway'),
                      _buildComboBtn('1.2D+1.0E+0.2S', 'Seismic'),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        model.isEquilibrated ? 'Equilibrium: ΣF = 0, ΣM = 0' : 'Residual Error',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 3. Global Structural Telemetry & AI Section Optimizer
            Container(
              width: 330,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'TELEMETRY',
                          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        'Latency: ${model.solverLatencyMs.toStringAsFixed(1)} ms',
                        style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTelemetryBlock(
                          'GLOBAL BASE SHEAR',
                          '${(model.baseShearN / 1000).toStringAsFixed(1)} kN',
                          'V_base = Σ R_horiz',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTelemetryBlock(
                          'DRIFT RATIO',
                          '${(model.maxDriftRatio * 100).toStringAsFixed(3)}%',
                          'Limit ≤ 0.20%',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onOptimize,
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 13),
                      label: const Text(
                        'AI SECTION AUTO-SIZER',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F6FEB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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

  Widget _buildComboBtn(String combo, String desc) {
    final isSelected = model.loadCombination == combo;
    return InkWell(
      onTap: () => onCombinationChanged(combo),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F6FEB).withValues(alpha: 0.2) : const Color(0xFF0D1117),
          border: Border.all(color: isSelected ? const Color(0xFF1F6FEB) : Colors.white10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              combo,
              style: TextStyle(
                color: isSelected ? const Color(0xFF58A6FF) : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryBlock(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(color: Colors.white24, fontSize: 8)),
        ],
      ),
    );
  }
}
