// ============================================================================
// BridgeMovingLoadDock — AASHTO LRFD HL-93 Moving-Load Envelope Scrubber
// 60 FPS Timeline Scrubber, Live Influence-Line Chart η(x) & 3D Truck Sync
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/bridge_moving_load_solver.dart';
import 'glass_pod.dart';
import 'info_tooltip.dart';
import 'three_js_view.dart';

class BridgeMovingLoadDock extends StatefulWidget {
  final StructuralModel model;
  final String? selectedMemberId;
  final void Function(MovingLoadStepState stepState)? onStepScrubbed;

  const BridgeMovingLoadDock({
    super.key,
    required this.model,
    this.selectedMemberId,
    this.onStepScrubbed,
  });

  @override
  State<BridgeMovingLoadDock> createState() => _BridgeMovingLoadDockState();
}

class _BridgeMovingLoadDockState extends State<BridgeMovingLoadDock> {
  String _vehicleType = 'HL93_TRUCK_PLUS_LANE';
  late String _targetMemberId;
  late BridgeMovingLoadEnvelopeResult _envelopeResult;
  int _activeStepIndex = 0;
  bool _isPlaying = false;
  Timer? _playTimer;

  static const List<MapEntry<String, String>> _vehicles = [
    MapEntry('HL93_TRUCK_PLUS_LANE', 'HL-93 TRUCK (325 kN) + LANE'),
    MapEntry('HL93_TANDEM_PLUS_LANE', 'HL-93 TANDEM (220 kN) + LANE'),
    MapEntry('HL93_FATIGUE_TRUCK', 'AASHTO FATIGUE I TRUCK'),
  ];

  @override
  void initState() {
    super.initState();
    _targetMemberId = widget.selectedMemberId ??
        (widget.model.members.isNotEmpty ? widget.model.members.first.id : 'M1');
    _solveEnvelopes();
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    ThreeJsViewportBridge.clearMovingLoadTruck();
    super.dispose();
  }

  void _solveEnvelopes() {
    _envelopeResult = BridgeMovingLoadSolver.solveEnvelopes(
      model: widget.model,
      vehicleType: _vehicleType,
      numSteps: 40,
      targetInfluenceMemberId: _targetMemberId,
    );
    _activeStepIndex = (_envelopeResult.numSteps ~/ 2).clamp(0, _envelopeResult.numSteps - 1);
    _broadcastActiveStep();
  }

  void _broadcastActiveStep() {
    if (_envelopeResult.stepStates.isEmpty) return;
    final state = _envelopeResult.stepStates[_activeStepIndex];
    ThreeJsViewportBridge.updateMovingLoadTruck(state.toTruckViewportJson());
    widget.onStepScrubbed?.call(state);
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    _playTimer?.cancel();
    if (_isPlaying) {
      _playTimer = Timer.periodic(const Duration(milliseconds: 55), (_) {
        if (!mounted) return;
        setState(() {
          _activeStepIndex = (_activeStepIndex + 1) % _envelopeResult.numSteps;
        });
        _broadcastActiveStep();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepState = _envelopeResult.stepStates[_activeStepIndex];
    final targetEnv = _envelopeResult.memberEnvelopes.firstWhere(
      (e) => e.memberId == _targetMemberId,
      orElse: () => _envelopeResult.memberEnvelopes.first,
    );
    final isPass = _envelopeResult.governingBridgeDcr <= 1.0;
    final statusColor = isPass ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: GlassPod(
        width: 960,
        height: 640,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Color(0xFF00F0FF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Flexible(
                                  child: Text(
                                    'AASHTO LRFD HL-93 MOVING-LOAD BRIDGE ENVELOPE SCRUBBER',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6),
                                InfoTooltip(
                                  title: 'AASHTO LRFD HL-93 Moving-Load & Influence-Line Solver',
                                  codeRef: 'AASHTO LRFD §3.6.1.2 & §6.6',
                                  message:
                                      'Steps the HL-93 Design Truck (35 kN + 145 kN + 145 kN, 1+IM = 1.33) + 9.3 kN/m Design Lane Load across the span in 40 increments, solving the 12-DOF stiffness matrix at each position to extract P/V/M envelopes, influence lines η(x), and fatigue stress ranges Δf.',
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Span: ${_envelopeResult.spanLengthM.toStringAsFixed(1)} m (${_envelopeResult.numSteps} DSM Steps) • Dynamic Allowance (1+IM) = ${_envelopeResult.dynamicAllowanceFactor.toStringAsFixed(2)} • Multi-Presence m = ${_envelopeResult.multiPresenceFactorM.toStringAsFixed(2)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  tooltip: 'Close HL-93 Moving-Load Scrubber',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vehicle Type & Target Member Selector Strip
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _vehicles.map((v) {
                        final isSel = _vehicleType == v.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _vehicleType = v.key;
                                _solveEnvelopes();
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF00F0FF) : const Color(0xFF131B2E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF00F0FF) : Colors.white12,
                                ),
                              ),
                              child: Text(
                                v.value,
                                style: TextStyle(
                                  color: isSel ? Colors.black : Colors.white70,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141D2F),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _targetMemberId,
                      isDense: true,
                      dropdownColor: const Color(0xFF141D2F),
                      items: widget.model.members.take(24).map((m) {
                        return DropdownMenuItem(
                          value: m.id,
                          child: Text(
                            'Influence Member: ${m.id} (${m.section})',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _targetMemberId = val;
                            _solveEnvelopes();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 60 FPS Timeline Scrubber Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF101726),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying ? const Color(0xFFF59E0B) : const Color(0xFF00F0FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                    label: Text(
                      _isPlaying ? 'PAUSE 3D TRUCK' : 'PLAY 60 FPS HL-93',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                    ),
                    onPressed: _togglePlay,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Step ${_activeStepIndex + 1}/${_envelopeResult.numSteps}  (x = ${stepState.leadAxleXM.toStringAsFixed(1)} m)',
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _activeStepIndex.toDouble(),
                      min: 0.0,
                      max: (_envelopeResult.numSteps - 1).toDouble(),
                      divisions: _envelopeResult.numSteps - 1,
                      activeColor: const Color(0xFF00F0FF),
                      onChanged: (val) {
                        setState(() {
                          _activeStepIndex = val.round();
                        });
                        _broadcastActiveStep();
                      },
                    ),
                  ),
                  const InfoTooltip(
                    title: '60 FPS Moving-Load Position Scrubber',
                    codeRef: 'Live 3D Truck & DCR Sync',
                    message:
                        'Drag the slider or press Play to move the 3D HL-93 axle train across the bridge deck while watching live member DCR colors and influence ordinates η(x).',
                    size: 14,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Body: Left Live Influence-Line Chart + Right Member Envelope Table
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Live Influence Line Chart η(x) & Target Member Envelope
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1320),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.show_chart_rounded, size: 15, color: Color(0xFF00F0FF)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'INFLUENCE LINE η(x) — MEMBER $_targetMemberId',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const InfoTooltip(
                                title: 'Müller-Breslau Influence Line Ordinate η(x)',
                                codeRef: 'AASHTO LRFD §4.6.2',
                                message:
                                    'Plots normalized member internal force response η(x) as a function of longitudinal truck position x along the bridge deck.',
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF080C14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: CustomPaint(
                                painter: _InfluenceLineChartPainter(
                                  ordinates: _envelopeResult.influenceLineOrdinates,
                                  activeIndex: _activeStepIndex,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141D2F),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MEMBER $_targetMemberId ENVELOPE & FATIGUE (AASHTO §6.6)',
                                  style: const TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '• Axial Envelope: P_max = ${targetEnv.pMaxKn.toStringAsFixed(1)} kN  |  P_min = ${targetEnv.pMinKn.toStringAsFixed(1)} kN\n'
                                  '• Flexure & Shear: M_max = ${targetEnv.mMaxKnm.toStringAsFixed(1)} kN·m  |  V_max = ${targetEnv.vMaxKn.toStringAsFixed(1)} kN\n'
                                  '• Fatigue Stress Range Δf: ${targetEnv.fatigueStressRangeMpa.toStringAsFixed(1)} MPa vs. ΔF_TH = ${targetEnv.fatigueThresholdMpa.toStringAsFixed(0)} MPa (${targetEnv.fatigueStatus})',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    height: 1.38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Right: All-Member Governing Envelope Table
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1320),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  'GOVERNING HL-93 MEMBER FORCE ENVELOPES',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                                ),
                                child: Text(
                                  'MAX DCR ${_envelopeResult.governingBridgeDcr.toStringAsFixed(3)}',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _envelopeResult.memberEnvelopes.length,
                              itemBuilder: (ctx, i) {
                                final env = _envelopeResult.memberEnvelopes[i];
                                final isSel = env.memberId == _targetMemberId;
                                final dColor = env.maxDcr <= 1.0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _targetMemberId = env.memberId;
                                        _solveEnvelopes();
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? const Color(0xFF00F0FF).withValues(alpha: 0.14)
                                            : const Color(0xFF141D2F),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSel ? const Color(0xFF00F0FF) : Colors.white10,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${env.memberId} (${env.section}) • Crit Truck x = ${env.criticalTruckXM.toStringAsFixed(1)} m',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'P: [${env.pMinKn.toStringAsFixed(0)}, +${env.pMaxKn.toStringAsFixed(0)}] kN  •  V_max: ${env.vMaxKn.toStringAsFixed(0)} kN  •  M_max: ${env.mMaxKnm.toStringAsFixed(0)} kN·m  •  Δf: ${env.fatigueStressRangeMpa.toStringAsFixed(1)} MPa',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.6),
                                                    fontSize: 9.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'DCR ${env.maxDcr.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: dColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Active Step Deck Deflection: ${stepState.maxDeckDeflectionMm.toStringAsFixed(2)} mm  •  Influence Ordinate η(x): ${stepState.influenceOrdinate.toStringAsFixed(4)}  •  Max Fatigue Δf: ${_envelopeResult.maxFatigueStressRangeMpa.toStringAsFixed(1)} MPa',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CLOSE', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfluenceLineChartPainter extends CustomPainter {
  final List<double> ordinates;
  final int activeIndex;

  _InfluenceLineChartPainter({
    required this.ordinates,
    required this.activeIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ordinates.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final midY = h * 0.5;

    // Zero baseline
    canvas.drawLine(
      Offset(12, midY),
      Offset(w - 12, midY),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 1.0,
    );

    double maxAbs = 1e-4;
    for (final v in ordinates) {
      if (v.abs() > maxAbs) maxAbs = v.abs();
    }

    final path = Path();
    for (int i = 0; i < ordinates.length; i++) {
      final x = 16.0 + (w - 32.0) * (i / math.max(1, ordinates.length - 1));
      final y = midY - (ordinates[i] / maxAbs) * (h * 0.36);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF00F0FF)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Active step cursor
    final clampedIdx = activeIndex.clamp(0, ordinates.length - 1);
    final actX = 16.0 + (w - 32.0) * (clampedIdx / math.max(1, ordinates.length - 1));
    final actY = midY - (ordinates[clampedIdx] / maxAbs) * (h * 0.36);

    canvas.drawLine(
      Offset(actX, 12),
      Offset(actX, h - 12),
      Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: 0.65)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(actX, actY),
      5.5,
      Paint()..color = const Color(0xFFF59E0B),
    );
  }

  @override
  bool shouldRepaint(covariant _InfluenceLineChartPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex || oldDelegate.ordinates != ordinates;
}

