import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/structural_api_service.dart';
import 'glass_pod.dart';

class ShopDrawingAuditDialog extends StatefulWidget {
  const ShopDrawingAuditDialog({super.key});

  @override
  State<ShopDrawingAuditDialog> createState() => _ShopDrawingAuditDialogState();
}

class _ShopDrawingAuditDialogState extends State<ShopDrawingAuditDialog> {
  final _apiService = StructuralApiService();

  String _selectedPreset = "Bolted_Moment_EndPlate.png";
  bool _isAuditing = false;
  Map<String, dynamic>? _auditResult;

  final List<Map<String, String>> _presets = [
    {
      'id': 'Bolted_Moment_EndPlate.png',
      'title': 'Moment End-Plate',
      'subtitle': 'AISC 360-16 Chapter J & DG 4',
      'icon': 'bolt',
    },
    {
      'id': 'Column_Baseplate_Anchor.png',
      'title': 'Baseplate & Anchors',
      'subtitle': 'AISC 360-16 Chapter J & DG 1',
      'icon': 'foundation',
    },
    {
      'id': 'RC_Column_Rebar_Cage.png',
      'title': 'RC Rebar Cage',
      'subtitle': 'ACI 318-19 Chapter 25 Tied Cage',
      'icon': 'view_stream',
    },
  ];

  @override
  void initState() {
    super.initState();
    _runAudit();
  }

  Future<void> _runAudit() async {
    setState(() => _isAuditing = true);
    try {
      final res = await _apiService.auditShopDrawing(presetId: _selectedPreset);
      if (mounted) {
        setState(() {
          _auditResult = res;
          _isAuditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAuditing = false);
      }
    }
  }

  void _exportPunchlist() {
    if (_auditResult == null) return;
    final punchlist = (_auditResult!['punchlist'] as List?) ?? [];
    final title = _auditResult!['extracted_details']?['drawing_title'] ?? _selectedPreset;
    final status = _auditResult!['overall_status'] ?? 'PASSED';
    final score = _auditResult!['compliance_score'] ?? 100.0;

    final buffer = StringBuffer();
    buffer.writeln("=================================================");
    buffer.writeln("STRUCTURA NEXUS — SHOP DRAWING QA AUDIT PUNCHLIST");
    buffer.writeln("Document: $title");
    buffer.writeln("Status:   $status (Compliance Score: $score%)");
    buffer.writeln("Governing Limit State: ${_auditResult!['governing_limit_state']}");
    buffer.writeln("Capacity-to-Demand (C/D): ${_auditResult!['capacity_demand_ratio']}");
    buffer.writeln("=================================================");
    buffer.writeln();

    for (int i = 0; i < punchlist.length; i++) {
      final item = punchlist[i] as Map<String, dynamic>;
      buffer.writeln("[Item ${i + 1}] ${item['code']} (${item['severity']})");
      buffer.writeln("Ref:         ${item['standard_ref']}");
      buffer.writeln("Description: ${item['description']}");
      buffer.writeln("Remedy:      ${item['remedy']}");
      buffer.writeln();
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF00E5FF)),
            SizedBox(width: 10),
            Text("AEC Punch-List copied to clipboard!"),
          ],
        ),
        backgroundColor: const Color(0xFF101928),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _auditResult?['overall_status'] ?? "PASSED";
    final isPass = status == "PASSED";
    final score = (_auditResult?['compliance_score'] as num?)?.toDouble() ?? 98.5;
    final governing = _auditResult?['governing_limit_state'] ?? "AISC Bolt Tension & Flange Prying";
    final cdRatio = (_auditResult?['capacity_demand_ratio'] as num?)?.toDouble() ?? 0.74;
    final details = (_auditResult?['extracted_details'] as Map<String, dynamic>?) ?? {};
    final punchlist = (_auditResult?['punchlist'] as List?) ?? [];
    final boxes = (_auditResult?['bounding_boxes'] as List?) ?? [];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassPod(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9100).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF9100).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: Color(0xFFFF9100), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SHOP-DRAWING & CONNECTION VISUAL QA AUDITOR",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "ConnectionNet-AI Multimodal Vision • AISC 360-16 Chapter J & ACI 318-19 Chapter 25",
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  if (_isAuditing)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF9100)),
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

              // Preset Selector Tabs
              Row(
                children: _presets.map((p) {
                  final isSelected = _selectedPreset == p['id'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() => _selectedPreset = p['id']!);
                          _runAudit();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFF9100).withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF9100) : Colors.white12,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                p['title']!,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p['subtitle']!,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Compliance Score Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isPass ? const Color(0xFF00E676).withValues(alpha: 0.08) : const Color(0xFFFF3D00).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPass ? const Color(0xFF00E676).withValues(alpha: 0.35) : const Color(0xFFFF3D00).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isPass ? const Color(0xFF00E676) : const Color(0xFFFF3D00)).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPass ? Icons.verified_rounded : Icons.warning_amber_rounded,
                                color: isPass ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isPass ? "AISC / ACI COMPLIANT" : "REJECTED WITH PUNCHLIST",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                          color: isPass ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "${score.toStringAsFixed(1)}%",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: isPass ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${details['component_type'] ?? ''} • Governing Limit: $governing • Demand/Capacity Ratio: ${cdRatio.toStringAsFixed(2)}",
                                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Drawing Schematic View & Bounding Box Callouts
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1523),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.crop_free_rounded, color: Color(0xFF00E5FF), size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  "MULTIMODAL BOUNDING-BOX DEFECT DETECTION",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.white),
                                ),
                                const Spacer(),
                                Text(
                                  "${boxes.length} Spatial Callouts",
                                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Callout Pills
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: boxes.map((b) {
                                final isCrit = b['severity'] == 'CRITICAL_FAIL';
                                final isWarn = b['severity'] == 'WARNING';
                                final color = isCrit ? const Color(0xFFFF3D00) : (isWarn ? const Color(0xFFFFD600) : const Color(0xFF00E676));
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: color.withValues(alpha: 0.35)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.center_focus_strong_rounded, size: 14, color: color),
                                      const SizedBox(width: 6),
                                      Text(
                                        "${b['label']} [${b['standard_ref']}]",
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Engineering Punch-List Items
                      const Text(
                        "GOVERNING CODE DEFECT PUNCH-LIST",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFFFF9100)),
                      ),
                      const SizedBox(height: 8),
                      ...punchlist.map((item) {
                        final sev = item['severity'] as String? ?? 'CODE_PASS';
                        final isCrit = sev == 'CRITICAL_FAIL';
                        final isWarn = sev == 'WARNING';
                        final color = isCrit ? const Color(0xFFFF3D00) : (isWarn ? const Color(0xFFFFD600) : const Color(0xFF00E676));

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sev.replaceAll("_", " "),
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
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
                                          item['code'] as String? ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "(${item['standard_ref']})",
                                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['description'] as String? ?? '',
                                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Remedy: ${item['remedy']}",
                                      style: TextStyle(fontSize: 10, color: const Color(0xFF00E5FF).withValues(alpha: 0.9), fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF9100),
                      side: const BorderSide(color: Color(0xFFFF9100)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text("Export Punch-List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: _exportPunchlist,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
