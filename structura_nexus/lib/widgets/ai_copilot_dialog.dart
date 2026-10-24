import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/structural_api_service.dart';

class AiCopilotDialog extends StatefulWidget {
  final StructuralModel model;
  final StructuralApiService apiService;
  final VoidCallback onStructureModified;

  const AiCopilotDialog({
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
      builder: (ctx) => AiCopilotDialog(
        model: model,
        apiService: apiService,
        onStructureModified: onStructureModified,
      ),
    );
  }

  @override
  State<AiCopilotDialog> createState() => _AiCopilotDialogState();
}

class _AiCopilotDialogState extends State<AiCopilotDialog> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    'Optimize overstressed members to bring DCR <= 0.95',
    'Evaluate ASCE 7-16 seismic drift and fundamental period',
    'Calculate cradle-to-gate embodied carbon footprint',
    'Audit AISC 360 buckling and slenderness limits',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'summary':
          'Hello Engineer. I am your Structura Nexus Copilot, powered by physics-informed graph surrogates and deterministic AISC/ACI limit-state checkers. How can I assist your structural design today?',
      'insights': [
        'Real-time queries will parse active geometry, applied loads, and boundary restraints.',
        'Actions can directly apply optimal cross-section profiles or run dynamic vibrations.',
      ],
      'actions': <CopilotAction>[],
      'prompts': _quickPrompts,
    });
  }

  Future<void> _submitQuery(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': query,
      });
      _isLoading = true;
    });
    _queryController.clear();

    final res = await widget.apiService.askCopilot(query, widget.model);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res != null) {
          _messages.add({
            'role': 'assistant',
            'summary': res.executiveSummary,
            'insights': res.technicalInsights,
            'actions': res.actions,
            'prompts': res.suggestedPrompts,
          });
        } else {
          _messages.add({
            'role': 'assistant',
            'summary': 'Could not process query. Please check backend connection.',
            'insights': [],
            'actions': <CopilotAction>[],
            'prompts': _quickPrompts,
          });
        }
      });
    }
  }

  void _applyCopilotAction(CopilotAction action) {
    if (action.actionType == 'OPTIMIZE_SECTIONS' && action.suggestedModifications != null) {
      final secMap = action.suggestedModifications!['sections_map'] as Map<String, dynamic>?;
      if (secMap != null) {
        for (final entry in secMap.entries) {
          final mem = widget.model.members.firstWhere(
            (m) => m.id == entry.key,
            orElse: () => widget.model.members.first,
          );
          mem.section = entry.value.toString();
        }
        widget.onStructureModified();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Applied optimized AISC cross-sections across all members!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1117),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 780,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1F6FEB), Color(0xFF00F0FF)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.psychology_rounded, size: 22, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI STRUCTURAL COPILOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Natural Language Engineering Intelligence  •  AISC 360-16 / ASCE 7-16',
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

            // Chat Message Stream
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (ctx, idx) {
                  final msg = _messages[idx];
                  final isUser = msg['role'] == 'user';

                  if (isUser) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12, left: 80),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F6FEB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  // Assistant Response Card
                  final insights = msg['insights'] as List<dynamic>? ?? [];
                  final actions = msg['actions'] as List<CopilotAction>? ?? [];
                  final prompts = msg['prompts'] as List<dynamic>? ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['summary'] as String,
                          style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 13, height: 1.4),
                        ),
                        if (insights.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...insights.map(
                            (ins) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: Color(0xFF00F0FF))),
                                  Expanded(
                                    child: Text(
                                      ins.toString(),
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: actions.map((act) {
                              return ElevatedButton.icon(
                                onPressed: () => _applyCopilotAction(act),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF238636),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                                label: Text(act.description, style: const TextStyle(fontSize: 11)),
                              );
                            }).toList(),
                          ),
                        ],
                        if (prompts.isNotEmpty && idx == _messages.length - 1) ...[
                          const SizedBox(height: 14),
                          const Text(
                            'SUGGESTED NEXT STEPS',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: prompts.map((p) {
                              return InkWell(
                                onTap: () => _submitQuery(p.toString()),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF21262D),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Text(
                                    p.toString(),
                                    style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 11),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00F0FF)),
                    ),
                    SizedBox(width: 8),
                    Text('Evaluating structural graph surrogates & limit states...', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Ask Copilot: "Optimize roof beams", "Check seismic drift", "Embodied carbon"...',
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _submitQuery,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _submitQuery(_queryController.text),
                    icon: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF00F0FF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
