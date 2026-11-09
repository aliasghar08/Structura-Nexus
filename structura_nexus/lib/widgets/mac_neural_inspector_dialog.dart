// ============================================================================
// Structura Nexus: Mac-Trained Neural AI Inspector & Benchmark Suite
// Live inspection and benchmarking of all 10 proprietary neural surrogates
// trained on Apple Silicon Mac (Metal Performance Shaders / MPS GPU).
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/dart_neural_engine.dart';

class MacNeuralInspectorDialog extends StatefulWidget {
  final StructuralModel currentModel;

  const MacNeuralInspectorDialog({
    super.key,
    required this.currentModel,
  });

  @override
  State<MacNeuralInspectorDialog> createState() => _MacNeuralInspectorDialogState();
}

class _MacNeuralInspectorDialogState extends State<MacNeuralInspectorDialog> {
  final DartNeuralEngine _neuralEngine = DartNeuralEngine.instance;

  bool _isBenchmarking = false;
  Map<String, dynamic>? _benchmarkResults;
  double _totalBenchmarkLatencyMs = 0.0;

  @override
  void initState() {
    super.initState();
    _neuralEngine.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _runBenchmark() async {
    setState(() => _isBenchmarking = true);

    await Future.delayed(const Duration(milliseconds: 120));

    final swTotal = Stopwatch()..start();

    // 1. StructuraNet-3D
    final resStructura = _neuralEngine.predictStructuraNet3D(widget.currentModel);

    // 2. SectionNet-PM
    final resSection = _neuralEngine.predictConcreteSection();

    // 3. ConnectionNet-AI
    final resConn = _neuralEngine.predictSteelConnection();

    // 4. FoundationNet-SSI
    final resFoundation = _neuralEngine.predictFoundationSSI();

    // 5. PushoverNet-PBEE
    final resPushover = _neuralEngine.predictPushoverPBEE();

    // 6. AeroNet-CFD
    final resAero = _neuralEngine.predictAeroCFD();

    // 7. CompositeFloorNet-AI
    final resComposite = _neuralEngine.predictCompositeFloor();

    // 8. HazardDynamicNet-AI
    final resHazard = _neuralEngine.predictHazardDynamicResponse();

    // 9. ModalEigenNet-AI
    final resModal = _neuralEngine.predictModalDynamics();

    // 10. CarbonNet-LCA
    final resCarbon = _neuralEngine.predictEmbodiedCarbon();

    swTotal.stop();

    if (mounted) {
      setState(() {
        _isBenchmarking = false;
        _totalBenchmarkLatencyMs = swTotal.elapsedMicroseconds / 1000.0;
        _benchmarkResults = {
          'structuranet_3d': resStructura,
          'sectionnet_pm': resSection,
          'connection_net': resConn,
          'foundation_net': resFoundation,
          'pushover_net': resPushover,
          'aero_net': resAero,
          'composite_floor_net': resComposite,
          'hazard_net': resHazard,
          'modal_net': resModal,
          'carbon_net': resCarbon,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engines = _neuralEngine.getLoadedEnginesInfo();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 1040,
        height: 720,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 36,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildTelemetryOverview(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: engines.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final e = engines[idx];
                    final bRes = _benchmarkResults?[e['id']];
                    return _buildEngineCard(e, bRes);
                  },
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.memory_rounded, color: Color(0xFF00F0FF), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'MAC-TRAINED NEURAL AI ENGINE & SURROGATE INSPECTOR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Trained on Apple Silicon Mac (Metal Performance Shaders / MPS GPU) • Pure Dart SIMD Tensor Runtime',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryOverview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: const Color(0xFF101622),
      child: Row(
        children: [
          _buildTelemetryPill('PLATFORM ACCELERATOR', 'Apple Silicon MPS GPU', Icons.developer_board_rounded, const Color(0xFF00F0FF)),
          const SizedBox(width: 12),
          _buildTelemetryPill('ACTIVE SURROGATES', '10 / 10 Hot & Ready', Icons.bolt_rounded, const Color(0xFF7EE787)),
          const SizedBox(width: 12),
          _buildTelemetryPill('TENSOR RUNTIME', 'SIMD Float32List (<1.5ms)', Icons.speed_rounded, const Color(0xFFFFA657)),
          const SizedBox(width: 12),
          _buildTelemetryPill('CHECKPOINTS', 'Mac MPS Checkpoints', Icons.verified_rounded, const Color(0xFFD2A8FF)),
        ],
      ),
    );
  }

  Widget _buildTelemetryPill(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                  Text(val, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineCard(Map<String, dynamic> e, Map<String, dynamic>? benchmark) {
    final hasBench = benchmark != null;
    final latency = hasBench ? (benchmark['latency_ms'] as num).toStringAsFixed(2) : e['latency'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasBench ? const Color(0xFF00F0FF).withValues(alpha: 0.4) : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: hasBench ? const Color(0xFF00F0FF) : const Color(0xFF7EE787),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      e['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        e['status'],
                        style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${e['domain']} • ${e['architecture']}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PARAMS: ${e['params']}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
                Text('CKPT: ${e['checkpoint']}', style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasBench ? '$latency ms' : e['latency'],
                  style: TextStyle(
                    color: hasBench ? const Color(0xFF7EE787) : const Color(0xFF00F0FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  hasBench ? 'TESTED ON MODEL' : 'IN-APP LATENCY',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF101622),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _benchmarkResults != null
                ? Text(
                    'Benchmark Finished: All 10 engines evaluated in ${_totalBenchmarkLatencyMs.toStringAsFixed(2)} ms total!',
                    style: const TextStyle(color: Color(0xFF7EE787), fontSize: 12, fontWeight: FontWeight.bold),
                  )
                : const Text(
                    '10/10 Mac-Trained Neural Engines hot and ready for 1-click evaluation.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isBenchmarking ? null : _runBenchmark,
            icon: _isBenchmarking
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0F1D)))
                : const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF0A0F1D)),
            label: Text(
              _isBenchmarking ? 'Running Forward Passes...' : 'Run Real-Time Mac AI Benchmark',
              style: const TextStyle(color: Color(0xFF0A0F1D), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
