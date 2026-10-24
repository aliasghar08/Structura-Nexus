import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../models/structural_models.dart';
import '../services/structural_api_service.dart';

class SeismicModalDialog extends StatefulWidget {
  final StructuralModel model;
  final StructuralApiService apiService;
  final Function(int modeIndex, Map<String, vm.Vector3> offsets) onActivateVibration;

  const SeismicModalDialog({
    super.key,
    required this.model,
    required this.apiService,
    required this.onActivateVibration,
  });

  static Future<void> show(
    BuildContext context, {
    required StructuralModel model,
    required StructuralApiService apiService,
    required Function(int modeIndex, Map<String, vm.Vector3> offsets) onActivateVibration,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => SeismicModalDialog(
        model: model,
        apiService: apiService,
        onActivateVibration: onActivateVibration,
      ),
    );
  }

  @override
  State<SeismicModalDialog> createState() => _SeismicModalDialogState();
}

class _SeismicModalDialogState extends State<SeismicModalDialog> {
  bool _isLoading = true;
  SeismicAnalysisResult? _result;
  int _selectedMode = 1;

  @override
  void initState() {
    super.initState();
    _fetchSeismic();
  }

  Future<void> _fetchSeismic() async {
    setState(() => _isLoading = true);
    final res = await widget.apiService.runDynamicModalAnalysis(widget.model);
    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
    }
  }

  void _triggerVibrationSimulation() {
    if (_result == null) return;
    final mode = _result!.modes.firstWhere((m) => m.modeNumber == _selectedMode);

    final Map<String, vm.Vector3> offsetMap = {};
    for (final pt in mode.modeShapeOffsets) {
      offsetMap[pt.nodeId] = vm.Vector3(pt.deltaX, pt.deltaY, pt.deltaZ);
    }

    widget.onActivateVibration(_selectedMode, offsetMap);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Simulating Dynamic Mode $_selectedMode (${mode.description}) in 3D Viewport!',
        ),
        backgroundColor: const Color(0xFF00F0FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1117),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 820,
        height: 620,
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
                      colors: [Color(0xFF0284C7), Color(0xFF00F0FF)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.waves_rounded, size: 22, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI DYNAMIC MODAL & ASCE 7-16 SEISMIC ENGINE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Eigenvalue Analysis  •  Equivalent Lateral Force (ELF)  •  Inter-Story Drift',
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
                      CircularProgressIndicator(color: Color(0xFF00F0FF)),
                      SizedBox(height: 16),
                      Text(
                        'Computing Eigenvalues, Modal Participation Ratios & Base Shear...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'ASCE 7-16 Equivalent Lateral Force (ELF) Procedure',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              )
            else if (_result != null) ...[
              // Telemetry Cards
              Row(
                children: [
                  _buildMetricCard(
                    title: 'FUNDAMENTAL PERIOD (T1)',
                    value: '${_result!.fundamentalPeriodT1.toStringAsFixed(3)} s',
                    subtext: '${_result!.modes[0].frequencyHz.toStringAsFixed(2)} Hz frequency',
                    color: const Color(0xFF00F0FF),
                    icon: Icons.timer_outlined,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: 'BASE SHEAR (V_BASE)',
                    value: '${_result!.baseShearVBaseKn.toStringAsFixed(1)} kN',
                    subtext: 'Cs = ${_result!.seismicResponseCoeffCs.toStringAsFixed(3)}',
                    color: const Color(0xFF58A6FF),
                    icon: Icons.shield_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: 'INTER-STORY DRIFT',
                    value: '${_result!.interStoryDriftRatioPct.toStringAsFixed(2)}%',
                    subtext: _result!.driftComplianceStatus,
                    color: _result!.interStoryDriftRatioPct <= 2.0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    icon: Icons.swap_horiz_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: 'SEISMIC WEIGHT',
                    value: '${_result!.totalEffectiveSeismicWeightKn.toStringAsFixed(0)} kN',
                    subtext: 'Category ${_result!.seismicDesignCategory} • R=${_result!.responseModificationR}',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.fitness_center_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Modal Table
              const Text(
                'VIBRATION MODE SHAPES & MASS PARTICIPATION',
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
                    itemCount: _result!.modes.length,
                    separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (ctx, idx) {
                      final mode = _result!.modes[idx];
                      final isSelected = mode.modeNumber == _selectedMode;

                      return InkWell(
                        onTap: () => setState(() => _selectedMode = mode.modeNumber),
                        child: Container(
                          color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.08) : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF00F0FF) : Colors.white38,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF00F0FF),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mode ${mode.modeNumber}: ${mode.description}',
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF00F0FF) : Colors.white,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    Text(
                                      'Frequency: ${mode.frequencyHz.toStringAsFixed(2)} Hz • Period: ${mode.periodSeconds.toStringAsFixed(3)} s',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: mode.modalMassParticipationPct / 100.0,
                                          backgroundColor: Colors.white10,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isSelected ? const Color(0xFF00F0FF) : const Color(0xFF58A6FF),
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${mode.modalMassParticipationPct.toStringAsFixed(1)}% mass',
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _triggerVibrationSimulation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                    label: Text(
                      'Simulate Mode $_selectedMode in 3D Viewport',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
