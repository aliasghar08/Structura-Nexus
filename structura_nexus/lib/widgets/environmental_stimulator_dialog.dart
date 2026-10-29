// ============================================================================
// Structura Nexus: Environmental Multi-Hazard Dynamic Stimulator & Building Studio
// Synthesizes or Imports Buildings & Stimulates Earthquakes, Hurricanes, Fire, Snow & Sinkholes in Real Time
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'glass_pod.dart';
import '../models/structural_models.dart';
import '../services/building_generator_service.dart';
import '../services/environmental_stimulator_engine.dart';

class EnvironmentalStimulatorDialog extends StatefulWidget {
  final StructuralModel model;
  final Function(StructuralModel newModel) onModelReplaced;
  final VoidCallback onStructureModified;
  final Function(String feature, VoidCallback onAuth)? onRequireAuth;

  const EnvironmentalStimulatorDialog({
    super.key,
    required this.model,
    required this.onModelReplaced,
    required this.onStructureModified,
    this.onRequireAuth,
  });

  @override
  State<EnvironmentalStimulatorDialog> createState() => _EnvironmentalStimulatorDialogState();
}

class _EnvironmentalStimulatorDialogState extends State<EnvironmentalStimulatorDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Real-Time Stimulation State
  late EnvironmentalStimulationState _stimState;
  Timer? _animTimer;
  bool _isPlaying = true;
  EnvironmentalStimulationMetrics? _metrics;

  // Parametric Generator State
  int _genStories = 5;
  int _genBaysX = 3;
  int _genBaysZ = 2;
  double _genBayWidth = 6.0;
  double _genStoryHeight = 3.6;
  BuildingSystemType _genSystem = BuildingSystemType.xBracedFrame;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _stimState = EnvironmentalStimulationState(
      windSpeedMph: 75.0,
      windDirectionDeg: 0.0,
      isWindActive: true,
      seismicPgaG: 0.35,
      seismicRecord: 'El Centro 1940',
      isSeismicActive: false,
      deltaTempC: 0.0,
      isThermalActive: false,
      snowLoadKpa: 0.0,
      isSnowActive: false,
      settlementMm: 0.0,
      isSettlementActive: false,
    );

    _startAnimationLoop();
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startAnimationLoop() {
    _animTimer?.cancel();
    _animTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!_isPlaying) return;
      _stimState.simulationTimeSec += 0.033;
      final m = EnvironmentalStimulatorEngine.stimulateBuilding(
        model: widget.model,
        state: _stimState,
      );
      if (mounted) {
        setState(() {
          _metrics = m;
        });
        widget.onStructureModified();
      }
    });
  }

  void _applyDisasterPreset({
    required double windMph,
    required bool windOn,
    required double pgaG,
    required bool pgaOn,
    required String record,
    required double fireC,
    required bool fireOn,
    required double snowKpa,
    required bool snowOn,
    required double sinkholeMm,
    required bool sinkholeOn,
  }) {
    setState(() {
      _stimState.windSpeedMph = windMph;
      _stimState.isWindActive = windOn;
      _stimState.seismicPgaG = pgaG;
      _stimState.isSeismicActive = pgaOn;
      _stimState.seismicRecord = record;
      _stimState.deltaTempC = fireC;
      _stimState.isThermalActive = fireOn;
      _stimState.snowLoadKpa = snowKpa;
      _stimState.isSnowActive = snowOn;
      _stimState.settlementMm = sinkholeMm;
      _stimState.isSettlementActive = sinkholeOn;
      _isPlaying = true;
    });
  }

  void _generateAndReplaceBuilding() {
    final newModel = BuildingGeneratorService.generateParametricBuilding(
      name: 'Synthesized $_genStories-Story Frame',
      numStories: _genStories,
      baysX: _genBaysX,
      baysZ: _genBaysZ,
      bayWidthX: _genBayWidth,
      storyHeight: _genStoryHeight,
      system: _genSystem,
    );
    widget.onModelReplaced(newModel);
    setState(() {
      _tabController.animateTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final health = _metrics?.structuralIntegrityHealthPct ?? 95.0;
    final level = _metrics?.hazardLevel ?? 'SAFE';
    final driftMm = _metrics?.maxRoofDriftMm ?? 12.0;
    final driftRatio = _metrics?.maxDriftRatio ?? 0.001;
    final shearKn = _metrics?.totalBaseShearKn ?? 450.0;
    final overstressed = _metrics?.overstressedMemberCount ?? 0;

    Color levelColor = const Color(0xFF10B981);
    if (level == 'COLLAPSE RISK') {
      levelColor = const Color(0xFFEC4899);
    } else if (level == 'SEVERE HAZARD') {
      levelColor = const Color(0xFFF59E0B);
    } else if (level == 'ELEVATED STRESS') {
      levelColor = const Color(0xFF00F0FF);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: GlassPod(
        width: 920,
        height: 700,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cyclone_rounded, color: Colors.black, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ENVIRONMENTAL MULTI-HAZARD DYNAMIC STIMULATOR",
                          style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        Text(
                          "Real-Time Earthquake Shaking • Hurricanes • Fire • Snow • Foundation Subsidence",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: const Color(0xFF00F0FF),
                      labelColor: const Color(0xFF00F0FF),
                      unselectedLabelColor: Colors.white54,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: "LIVE ENVIRONMENTAL STIMULATOR"),
                        Tab(text: "SYNTHESIZE / IMPORT BUILDING"),
                      ],
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLiveStimulatorTab(health, level, levelColor, driftMm, driftRatio, shearKn, overstressed),
                  _buildSynthesizerTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStimulatorTab(
    double health,
    String level,
    Color levelColor,
    double driftMm,
    double driftRatio,
    double shearKn,
    int overstressed,
  ) {
    return Column(
      children: [
        // Top Health & Safety Status Banner
        GlassPod(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          borderRadius: 14,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: levelColor),
                ),
                child: Text(
                  level,
                  style: TextStyle(color: levelColor, fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("STRUCTURAL HEALTH: ", style: TextStyle(color: Colors.white54, fontSize: 10)),
                        Text("${health.toStringAsFixed(1)}%", style: TextStyle(color: levelColor, fontWeight: FontWeight.bold, fontSize: 11.5)),
                        const Spacer(),
                        Text("Roof Sway: ${driftMm.toStringAsFixed(1)} mm (${(driftRatio * 100).toStringAsFixed(2)}%) • Base Shear: ${shearKn.toStringAsFixed(0)} kN • Failed Members: $overstressed", style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (health / 100.0).clamp(0.05, 1.0),
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(levelColor),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Play / Pause Animation Button
              IconButton(
                tooltip: _isPlaying ? "Pause Shaking" : "Play Shaking",
                icon: Icon(_isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded, color: const Color(0xFF00F0FF), size: 28),
                onPressed: () => setState(() => _isPlaying = !_isPlaying),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Controls Grid and Disaster Presets
        Expanded(
          child: Row(
            children: [
              // Left Sliders
              Expanded(
                flex: 5,
                child: ListView(
                  padding: const EdgeInsets.only(right: 12),
                  children: [
                    // 1. Wind & Hurricane
                    _hazardSection(
                      title: "🌪️ HURRICANE WIND FORCE",
                      isActive: _stimState.isWindActive,
                      onToggle: (v) => setState(() => _stimState.isWindActive = v),
                      color: const Color(0xFF00F0FF),
                      child: Column(
                        children: [
                          _sliderRow("Wind Speed", "${_stimState.windSpeedMph.toStringAsFixed(0)} mph", _stimState.windSpeedMph, 0, 180, (v) => setState(() => _stimState.windSpeedMph = v), const Color(0xFF00F0FF)),
                          _sliderRow("Angle", "${_stimState.windDirectionDeg.toStringAsFixed(0)}°", _stimState.windDirectionDeg, 0, 360, (v) => setState(() => _stimState.windDirectionDeg = v), const Color(0xFF00F0FF)),
                        ],
                      ),
                    ),

                    // 2. Earthquake Shaking
                    _hazardSection(
                      title: "🌋 EARTHQUAKE GROUND SHAKING",
                      isActive: _stimState.isSeismicActive,
                      onToggle: (v) => setState(() => _stimState.isSeismicActive = v),
                      color: const Color(0xFFEC4899),
                      child: Column(
                        children: [
                          _sliderRow("Peak Ground Accel (PGA)", "${_stimState.seismicPgaG.toStringAsFixed(2)} g", _stimState.seismicPgaG, 0.05, 1.5, (v) => setState(() => _stimState.seismicPgaG = v), const Color(0xFFEC4899)),
                          Row(
                            children: [
                              const Text("Record: ", style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(width: 8),
                              ...['El Centro 1940', 'Kobe 1995', 'Harmonic'].map((rec) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(rec, style: const TextStyle(fontSize: 10)),
                                  selected: _stimState.seismicRecord == rec,
                                  onSelected: (_) => setState(() => _stimState.seismicRecord = rec),
                                ),
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3. Thermal Fire & Solar
                    _hazardSection(
                      title: "🔥 THERMAL EXPANSION & FIRE",
                      isActive: _stimState.isThermalActive,
                      onToggle: (v) => setState(() => _stimState.isThermalActive = v),
                      color: const Color(0xFFF59E0B),
                      child: _sliderRow("Delta Temperature", "${_stimState.deltaTempC.toStringAsFixed(0)} °C", _stimState.deltaTempC, -40, 800, (v) => setState(() => _stimState.deltaTempC = v), const Color(0xFFF59E0B)),
                    ),

                    // 4. Extreme Snow & Ice
                    _hazardSection(
                      title: "❄️ ROOF SNOW & ICE ACCUMULATION",
                      isActive: _stimState.isSnowActive,
                      onToggle: (v) => setState(() => _stimState.isSnowActive = v),
                      color: const Color(0xFF38BDF8),
                      child: _sliderRow("Snow Surcharge", "${_stimState.snowLoadKpa.toStringAsFixed(1)} kPa", _stimState.snowLoadKpa, 0, 5.0, (v) => setState(() => _stimState.snowLoadKpa = v), const Color(0xFF38BDF8)),
                    ),

                    // 5. Differential Soil Settlement
                    _hazardSection(
                      title: "⛰️ CORNER FOUNDATION SUBSIDENCE",
                      isActive: _stimState.isSettlementActive,
                      onToggle: (v) => setState(() => _stimState.isSettlementActive = v),
                      color: const Color(0xFF10B981),
                      child: _sliderRow("Differential Settlement", "${_stimState.settlementMm.toStringAsFixed(0)} mm", _stimState.settlementMm, 0, 150, (v) => setState(() => _stimState.settlementMm = v), const Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),

              // Right Disaster Presets
              SizedBox(
                width: 260,
                child: GlassPod(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "1-CLICK DISASTER SCENARIOS",
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 10),
                      _disasterBtn("🌪️ Cat-5 Hurricane", "160 mph gust with dynamic vortex buffeting", () {
                        _applyDisasterPreset(windMph: 160, windOn: true, pgaG: 0, pgaOn: false, record: 'El Centro 1940', fireC: 0, fireOn: false, snowKpa: 0, snowOn: false, sinkholeMm: 0, sinkholeOn: false);
                      }),
                      _disasterBtn("🌋 San Andreas 7.8M", "0.85g PGA multi-frequency Kobe fault wave", () {
                        _applyDisasterPreset(windMph: 0, windOn: false, pgaG: 0.85, pgaOn: true, record: 'Kobe 1995', fireC: 0, fireOn: false, snowKpa: 0, snowOn: false, sinkholeMm: 0, sinkholeOn: false);
                      }),
                      _disasterBtn("🔥 Post-Quake Inferno", "0.40g seismic + 650°C thermal column yielding", () {
                        _applyDisasterPreset(windMph: 0, windOn: false, pgaG: 0.40, pgaOn: true, record: 'El Centro 1940', fireC: 650, fireOn: true, snowKpa: 0, snowOn: false, sinkholeMm: 0, sinkholeOn: false);
                      }),
                      _disasterBtn("❄️ Arctic Blizzard Pack", "4.2 kPa snow + -30°C contraction + 60mph wind", () {
                        _applyDisasterPreset(windMph: 60, windOn: true, pgaG: 0, pgaOn: false, record: 'El Centro 1940', fireC: -30, fireOn: true, snowKpa: 4.2, snowOn: true, sinkholeMm: 0, sinkholeOn: false);
                      }),
                      _disasterBtn("⛰️ Washout Sinkhole", "85 mm corner subsidence with moment shear spike", () {
                        _applyDisasterPreset(windMph: 0, windOn: false, pgaG: 0, pgaOn: false, record: 'El Centro 1940', fireC: 0, fireOn: false, snowKpa: 0, snowOn: false, sinkholeMm: 85, sinkholeOn: true);
                      }),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          minimumSize: const Size.fromHeight(38),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.restart_alt_rounded, color: Colors.white, size: 18),
                        label: const Text("Reset All Hazards", style: TextStyle(color: Colors.white, fontSize: 11)),
                        onPressed: () {
                          _applyDisasterPreset(windMph: 0, windOn: false, pgaG: 0, pgaOn: false, record: 'El Centro 1940', fireC: 0, fireOn: false, snowKpa: 0, snowOn: false, sinkholeMm: 0, sinkholeOn: false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSynthesizerTab() {
    return Row(
      children: [
        // Parametric Generator Controls
        Expanded(
          flex: 5,
          child: ListView(
            padding: const EdgeInsets.only(right: 16),
            children: [
              const Text("PARAMETRIC 3D BUILDING BUILDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              const Text("Generate custom multi-storey space frames with live diaphragms and structural systems.", style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 14),
              _sliderRow("Number of Storeys", "$_genStories", _genStories.toDouble(), 1, 20, (v) => setState(() => _genStories = v.round()), const Color(0xFF00F0FF)),
              _sliderRow("Bays in X", "$_genBaysX", _genBaysX.toDouble(), 1, 6, (v) => setState(() => _genBaysX = v.round()), const Color(0xFF00F0FF)),
              _sliderRow("Bays in Z", "$_genBaysZ", _genBaysZ.toDouble(), 1, 6, (v) => setState(() => _genBaysZ = v.round()), const Color(0xFF00F0FF)),
              _sliderRow("Bay Width X", "${_genBayWidth.toStringAsFixed(1)} m", _genBayWidth, 4.0, 12.0, (v) => setState(() => _genBayWidth = v), const Color(0xFF00F0FF)),
              _sliderRow("Story Height", "${_genStoryHeight.toStringAsFixed(1)} m", _genStoryHeight, 2.8, 5.0, (v) => setState(() => _genStoryHeight = v), const Color(0xFF00F0FF)),
              const SizedBox(height: 10),
              const Text("Lateral Bracing System", style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text("X-Braced Frame", style: TextStyle(fontSize: 10.5)),
                    selected: _genSystem == BuildingSystemType.xBracedFrame,
                    onSelected: (_) => setState(() => _genSystem = BuildingSystemType.xBracedFrame),
                  ),
                  ChoiceChip(
                    label: const Text("Moment Frame (SMF)", style: TextStyle(fontSize: 10.5)),
                    selected: _genSystem == BuildingSystemType.momentFrame,
                    onSelected: (_) => setState(() => _genSystem = BuildingSystemType.momentFrame),
                  ),
                  ChoiceChip(
                    label: const Text("Chevron Braced", style: TextStyle(fontSize: 10.5)),
                    selected: _genSystem == BuildingSystemType.chevronBraced,
                    onSelected: (_) => setState(() => _genSystem = BuildingSystemType.chevronBraced),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.architecture_rounded, size: 20),
                label: const Text("GENERATE & LOAD INTO 3D WORKSTATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _generateAndReplaceBuilding,
              ),
            ],
          ),
        ),

        // Built-in Archetypes & File Import
        SizedBox(
          width: 320,
          child: GlassPod(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PRE-BUILT ARCHETYPES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                _archetypeItem("🏢 5-Story Office Frame", "3x2 bays, 3.6m story height, perimeter X-braces", () {
                  setState(() {
                    _genStories = 5;
                    _genBaysX = 3;
                    _genBaysZ = 2;
                    _genSystem = BuildingSystemType.xBracedFrame;
                  });
                  _generateAndReplaceBuilding();
                }),
                _archetypeItem("🏙️ 12-Story High-Rise Tower", "2x2 bays, 4.0m story height, Chevron lateral core", () {
                  setState(() {
                    _genStories = 12;
                    _genBaysX = 2;
                    _genBaysZ = 2;
                    _genSystem = BuildingSystemType.chevronBraced;
                  });
                  _generateAndReplaceBuilding();
                }),
                _archetypeItem("🏭 Industrial Portal Frame", "1-story, 12m span, moment resisting steel frame", () {
                  setState(() {
                    _genStories = 1;
                    _genBaysX = 1;
                    _genBaysZ = 3;
                    _genBayWidth = 12.0;
                    _genStoryHeight = 6.0;
                    _genSystem = BuildingSystemType.momentFrame;
                  });
                  _generateAndReplaceBuilding();
                }),
                const Spacer(),
                const Divider(color: Colors.white10),
                const Text("IMPORT FROM CAD / BIM", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text("Drag & drop .JSON, .S2K, .IFC or .DXF structural models directly into the workstation canvas.", style: TextStyle(color: Colors.white54, fontSize: 10.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _archetypeItem(String title, String desc, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hazardSection({
    required String title,
    required bool isActive,
    required ValueChanged<bool> onToggle,
    required Color color,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPod(
        padding: const EdgeInsets.all(12),
        borderRadius: 14,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.5, letterSpacing: 0.6)),
                Switch(
                  value: isActive,
                  activeTrackColor: color.withValues(alpha: 0.5),
                  activeThumbColor: color,
                  onChanged: onToggle,
                ),
              ],
            ),
            if (isActive) ...[
              const Divider(color: Colors.white10, height: 12),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _disasterBtn(String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 9.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderRow(String label, String valueStr, double val, double min, double max, ValueChanged<double> onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
              Text(valueStr, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              activeTrackColor: color,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
            ),
            child: Slider(value: val.clamp(min, max), min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
