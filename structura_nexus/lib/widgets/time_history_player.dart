// ============================================================================
// TimeHistoryPlayer — Floating Glass Media Scrubber for NLTHA Seismic Playback
// Newmark-Beta Real-Time 3D Frame Dynamic Swaying & Plastic Yielding Player
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/structural_api_service.dart';
import 'glass_pod.dart';

class TimeHistoryPlayer extends StatefulWidget {
  final StructuralModel model;
  final StructuralApiService apiService;
  final VoidCallback onClose;
  final Function(double timeSec, Map<String, List<double>> nodeOffsets)? onTimeStepChanged;

  const TimeHistoryPlayer({
    super.key,
    required this.model,
    required this.apiService,
    required this.onClose,
    this.onTimeStepChanged,
  });

  @override
  State<TimeHistoryPlayer> createState() => _TimeHistoryPlayerState();
}

class _TimeHistoryPlayerState extends State<TimeHistoryPlayer> with SingleTickerProviderStateMixin {
  String _selectedEarthquake = 'El Centro 1940';
  final double _scaleFactor = 1.0;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _currentTimeSec = 0.0;
  final double _durationSec = 6.0;
  Timer? _playbackTimer;

  Map<String, dynamic>? _nlthaData;
  List<double> _timeSteps = [];
  List<double> _roofDrift = [];
  List<double> _baseShear = [];
  Map<String, List<List<double>>> _nodeTrajectories = {};

  final List<String> _earthquakes = [
    'El Centro 1940',
    'Kobe 1995',
    'Northridge 1994',
  ];

  @override
  void initState() {
    super.initState();
    _loadAndRunNltha();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _loadAndRunNltha() async {
    setState(() {
      _isLoading = true;
      _isPlaying = false;
      _playbackTimer?.cancel();
    });

    final res = await widget.apiService.runNltha(
      model: widget.model,
      earthquakeName: _selectedEarthquake,
      scaleFactor: _scaleFactor,
      durationSec: _durationSec,
    );

    if (!mounted) return;

    final rawTime = (res['time_steps'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final rawDrift = (res['roof_drift_history_mm'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final rawShear = (res['base_shear_history_kn'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final rawTraj = res['node_trajectories'] as Map<String, dynamic>? ?? {};

    final convertedTraj = <String, List<List<double>>>{};
    rawTraj.forEach((k, v) {
      final stepList = (v as List).map((step) => (step as List).map((coord) => (coord as num).toDouble()).toList()).toList();
      convertedTraj[k] = stepList;
    });

    setState(() {
      _isLoading = false;
      _nlthaData = res;
      _timeSteps = rawTime;
      _roofDrift = rawDrift;
      _baseShear = rawShear;
      _nodeTrajectories = convertedTraj;
      _currentTimeSec = 0.0;
    });

    _play();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() {
    if (_timeSteps.isEmpty) return;
    _playbackTimer?.cancel();
    setState(() => _isPlaying = true);

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentTimeSec += 0.033;
        if (_currentTimeSec >= _durationSec) {
          _currentTimeSec = 0.0;
        }
        _broadcastOffsets();
      });
    });
  }

  void _pause() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _rewind() {
    setState(() {
      _currentTimeSec = 0.0;
      _broadcastOffsets();
    });
  }

  void _broadcastOffsets() {
    if (_timeSteps.isEmpty || _nodeTrajectories.isEmpty) return;
    int stepIdx = ((_currentTimeSec / _durationSec) * (_timeSteps.length - 1)).round();
    stepIdx = stepIdx.clamp(0, _timeSteps.length - 1);

    final currentOffsets = <String, List<double>>{};
    _nodeTrajectories.forEach((nid, traj) {
      if (stepIdx < traj.length) {
        currentOffsets[nid] = traj[stepIdx];
      }
    });

    widget.onTimeStepChanged?.call(_currentTimeSec, currentOffsets);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 700;

    int stepIdx = 0;
    if (_timeSteps.isNotEmpty && _durationSec > 0) {
      stepIdx = ((_currentTimeSec / _durationSec) * (_timeSteps.length - 1)).round().clamp(0, _timeSteps.length - 1);
    }
    final currentDrift = stepIdx < _roofDrift.length ? _roofDrift[stepIdx] : 0.0;
    final currentShear = stepIdx < _baseShear.length ? _baseShear[stepIdx] : 0.0;
    final perfLevel = _nlthaData?['structural_performance_level'] as String? ?? 'OPERATIONAL';

    return GlassPod(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 18,
        vertical: isCompact ? 8 : 10,
      ),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Title, Earthquake Dropdown, Metrics & Close
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NLTHA DYNAMICS',
                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                ),
              ),
              const SizedBox(width: 10),

              // Earthquake Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedEarthquake,
                    isDense: true,
                    dropdownColor: const Color(0xFF161B22),
                    items: _earthquakes.map((eq) => DropdownMenuItem(value: eq, child: Text(eq, style: const TextStyle(color: Colors.white, fontSize: 11)))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedEarthquake = v);
                        _loadAndRunNltha();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Telemetry Readouts
              if (!isCompact) ...[
                Text(
                  'Drift: ${currentDrift.toStringAsFixed(1)} mm',
                  style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Text(
                  'Base V: ${currentShear.toStringAsFixed(0)} kN',
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 0.6),
                  ),
                  child: Text(
                    perfLevel,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
              ],

              const Spacer(),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00F0FF)),
                  ),
                ),

              // Exit / Close Button
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                tooltip: 'Exit NLTHA Mode',
                onPressed: () {
                  _playbackTimer?.cancel();
                  widget.onClose();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Scrubber Timeline Row: Rewind, Play/Pause, Slider, Time Label
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.replay_rounded, size: 18, color: Colors.white70),
                tooltip: 'Rewind to t=0',
                onPressed: _rewind,
              ),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 22,
                  color: const Color(0xFF00F0FF),
                ),
                tooltip: _isPlaying ? 'Pause' : 'Play',
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 6),

              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: const Color(0xFF00F0FF),
                    inactiveTrackColor: Colors.white12,
                    thumbColor: const Color(0xFF00F0FF),
                  ),
                  child: Slider(
                    value: _currentTimeSec.clamp(0.0, _durationSec),
                    min: 0.0,
                    max: _durationSec,
                    onChanged: (v) {
                      setState(() {
                        _currentTimeSec = v;
                        _broadcastOffsets();
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),
              Text(
                '${_currentTimeSec.toStringAsFixed(2)}s / ${_durationSec.toStringAsFixed(1)}s',
                style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
