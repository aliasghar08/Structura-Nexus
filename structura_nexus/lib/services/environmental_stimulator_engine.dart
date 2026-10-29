// ============================================================================
// Structura Nexus: Real-Time Environmental Multi-Hazard Dynamic Stimulator
// Simulates Earthquake Ground Motion, Hurricane Winds, Fire, Snow & Subsidence
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:math' as math;
import '../models/structural_models.dart';

class EnvironmentalStimulationState {
  // 1. Wind & Hurricane
  double windSpeedMph;
  double windDirectionDeg;
  bool isWindActive;

  // 2. Seismic Shaking
  double seismicPgaG;
  String seismicRecord; // 'El Centro 1940', 'Kobe 1995', 'Harmonic'
  bool isSeismicActive;

  // 3. Thermal Fire & Solar
  double deltaTempC;
  bool isThermalActive;

  // 4. Extreme Snow & Ice
  double snowLoadKpa;
  bool isSnowActive;

  // 5. Differential Soil Settlement
  double settlementMm;
  bool isSettlementActive;

  // Animation Time
  double simulationTimeSec;

  EnvironmentalStimulationState({
    this.windSpeedMph = 0.0,
    this.windDirectionDeg = 0.0,
    this.isWindActive = false,
    this.seismicPgaG = 0.0,
    this.seismicRecord = 'El Centro 1940',
    this.isSeismicActive = false,
    this.deltaTempC = 0.0,
    this.isThermalActive = false,
    this.snowLoadKpa = 0.0,
    this.isSnowActive = false,
    this.settlementMm = 0.0,
    this.isSettlementActive = false,
    this.simulationTimeSec = 0.0,
  });

  EnvironmentalStimulationState copyWith({
    double? windSpeedMph,
    double? windDirectionDeg,
    bool? isWindActive,
    double? seismicPgaG,
    String? seismicRecord,
    bool? isSeismicActive,
    double? deltaTempC,
    bool? isThermalActive,
    double? snowLoadKpa,
    bool? isSnowActive,
    double? settlementMm,
    bool? isSettlementActive,
    double? simulationTimeSec,
  }) {
    return EnvironmentalStimulationState(
      windSpeedMph: windSpeedMph ?? this.windSpeedMph,
      windDirectionDeg: windDirectionDeg ?? this.windDirectionDeg,
      isWindActive: isWindActive ?? this.isWindActive,
      seismicPgaG: seismicPgaG ?? this.seismicPgaG,
      seismicRecord: seismicRecord ?? this.seismicRecord,
      isSeismicActive: isSeismicActive ?? this.isSeismicActive,
      deltaTempC: deltaTempC ?? this.deltaTempC,
      isThermalActive: isThermalActive ?? this.isThermalActive,
      snowLoadKpa: snowLoadKpa ?? this.snowLoadKpa,
      isSnowActive: isSnowActive ?? this.isSnowActive,
      settlementMm: settlementMm ?? this.settlementMm,
      isSettlementActive: isSettlementActive ?? this.isSettlementActive,
      simulationTimeSec: simulationTimeSec ?? this.simulationTimeSec,
    );
  }
}

class EnvironmentalStimulationMetrics {
  final double maxRoofDriftMm;
  final double maxDriftRatio;
  final double totalBaseShearKn;
  final double totalOverturningMomentKnm;
  final double structuralIntegrityHealthPct;
  final int overstressedMemberCount;
  final String statusSummary;
  final String hazardLevel; // SAFE, ELEVATED, SEVERE, COLLAPSE RISK

  EnvironmentalStimulationMetrics({
    required this.maxRoofDriftMm,
    required this.maxDriftRatio,
    required this.totalBaseShearKn,
    required this.totalOverturningMomentKnm,
    required this.structuralIntegrityHealthPct,
    required this.overstressedMemberCount,
    required this.statusSummary,
    required this.hazardLevel,
  });
}

class EnvironmentalStimulatorEngine {
  /// Applies live multi-hazard environmental stimulations directly onto the 3D StructuralModel,
  /// updating node displacement vectors, dynamic lateral sway, and member stress intensities in real time.
  static EnvironmentalStimulationMetrics stimulateBuilding({
    required StructuralModel model,
    required EnvironmentalStimulationState state,
  }) {
    double maxY = 0.0;
    for (final n in model.nodes) {
      if (n.y > maxY) maxY = n.y;
    }
    final buildingHeight = math.max(maxY, 3.0);

    // Natural period estimate
    final t1 = 0.0724 * math.pow(buildingHeight, 0.8);
    final omega1 = 2.0 * math.pi / t1;
    final t = state.simulationTimeSec;

    // 1. Wind & Hurricane Lateral Force & Dynamic Buffeting
    double windDriftFactor = 0.0;
    double windBaseShearN = 0.0;
    final windRad = state.windDirectionDeg * math.pi / 180.0;
    final windCos = math.cos(windRad);
    final windSin = math.sin(windRad);

    if (state.isWindActive && state.windSpeedMph > 0) {
      // Wind velocity pressure q = 0.00256 * V^2 (psf) -> N/m^2
      final vMs = state.windSpeedMph * 0.44704;
      final qBase = 0.613 * vMs * vMs;
      // Dynamic buffeting oscillation
      final buffeting = 1.0 + 0.15 * math.sin(t * 1.8) + 0.08 * math.cos(t * 3.4);
      windDriftFactor = (qBase / 2500.0) * 0.008 * buffeting;
      windBaseShearN = qBase * buildingHeight * 12.0 * buffeting;
    }

    // 2. Earthquake Ground Motion & Dynamic Resonant Shaking
    double seismicDispFactor = 0.0;
    double seismicBaseShearN = 0.0;

    if (state.isSeismicActive && state.seismicPgaG > 0) {
      final pga = state.seismicPgaG;
      double groundMotion = 0.0;

      if (state.seismicRecord == 'El Centro 1940') {
        // Multi-frequency historical earthquake wave synthesis
        groundMotion = 0.60 * math.sin(omega1 * t) +
            0.35 * math.sin(omega1 * 1.8 * t + 0.4) +
            0.20 * math.cos(omega1 * 3.1 * t + 1.2);
      } else if (state.seismicRecord == 'Kobe 1995') {
        // High-impulse near-fault pulse
        groundMotion = 0.85 * math.sin(omega1 * 0.9 * t) * math.exp(-0.04 * (t % 15.0)) +
            0.30 * math.sin(omega1 * 2.2 * t);
      } else {
        // Pure harmonic resonance
        groundMotion = math.sin(omega1 * t);
      }

      // Spectral amplification factor (typically 2.0 - 2.5)
      final dynamicAmp = 2.2;
      seismicDispFactor = (pga * 9.81 / (omega1 * omega1)) * dynamicAmp * groundMotion;
      seismicBaseShearN = (pga * 0.40) * model.totalMassKg * 9.81 * dynamicAmp * groundMotion.abs();
    }

    // 3. Thermal Fire & Expansion
    double thermalStrain = 0.0;
    if (state.isThermalActive && state.deltaTempC != 0) {
      thermalStrain = 1.2e-5 * state.deltaTempC; // Steel thermal expansion coeff
    }

    // 4. Extreme Snow Surcharge
    double snowForcePerNodeN = 0.0;
    if (state.isSnowActive && state.snowLoadKpa > 0) {
      snowForcePerNodeN = state.snowLoadKpa * 1000.0 * 16.0; // approx 16m2 tributary area
    }

    // 5. Differential Foundation Settlement
    final settlementM = (state.isSettlementActive ? state.settlementMm : 0.0) / 1000.0;

    // Apply Real-Time Dynamic Displacements to all Model Nodes
    double maxRoofDriftM = 0.0;

    for (final node in model.nodes) {
      final hRatio = node.y / buildingHeight; // 0 at ground, 1 at roof
      final invertedTri = math.pow(hRatio, 1.3).toDouble();

      // Lateral X and Z motion from Wind + Seismic
      final dxWind = windDriftFactor * invertedTri * buildingHeight * windCos;
      final dzWind = windDriftFactor * invertedTri * buildingHeight * windSin;
      final dxSeismic = seismicDispFactor * invertedTri;

      // Vertical Y displacement (Gravity + Snow - Settlement + Thermal expansion)
      double dy = 0.0;
      if (node.y == 0.0) {
        // Foundation settlement applied to corner base node (e.g. x == 0, z == 0)
        if (node.x == 0.0 && node.z == 0.0) {
          dy -= settlementM;
        }
      } else {
        // Floor nodes sag under snow and expand under thermal heat
        if (node.y == buildingHeight && state.isSnowActive) {
          dy -= (snowForcePerNodeN / 1e6) * 0.015;
        }
        if (state.isThermalActive) {
          dy += node.y * thermalStrain;
        }
      }

      final totalDx = dxWind + dxSeismic;
      final totalDz = dzWind;

      node.dispX = totalDx;
      node.dispY = dy;
      node.dispZ = totalDz;

      if (node.y == buildingHeight) {
        final roofHoriz = math.sqrt(totalDx * totalDx + totalDz * totalDz);
        if (roofHoriz > maxRoofDriftM) {
          maxRoofDriftM = roofHoriz;
        }
      }
    }

    // Update Member Internal Forces and Stress Heatmap (DCR)
    int overstressedCount = 0;
    for (final m in model.members) {
      final nodeI = model.nodes.firstWhere((n) => n.id == m.iNodeId, orElse: () => model.nodes.first);
      final nodeJ = model.nodes.firstWhere((n) => n.id == m.jNodeId, orElse: () => model.nodes.first);

      // Relative story drift across column
      final relDx = (nodeJ.dispX - nodeI.dispX).abs();
      final relDz = (nodeJ.dispZ - nodeI.dispZ).abs();
      final relDrift = math.sqrt(relDx * relDx + relDz * relDz);

      // Additional dynamic shear and moment induced by environmental stimulus
      final addedDcr = (relDrift / 0.04) * 0.45 + (state.isThermalActive ? (state.deltaTempC.abs() / 400.0) * 0.35 : 0.0);
      m.governingDcr = (m.governingDcr * 0.6) + addedDcr;
      if (m.governingDcr > 1.0) {
        overstressedCount++;
      }
    }

    final maxRoofDriftMm = maxRoofDriftM * 1000.0;
    final maxDriftRatio = maxRoofDriftM / buildingHeight;
    final totalShearKn = (windBaseShearN + seismicBaseShearN) / 1000.0;
    final totalOtmKnm = totalShearKn * (buildingHeight * 0.65);

    // Structural Integrity Safety Index (100% = Pristine, 0% = Collapse)
    double health = 100.0 - (maxDriftRatio / 0.02) * 50.0 - (overstressedCount * 3.5);
    if (state.isThermalActive && state.deltaTempC > 400.0) health -= 25.0;
    if (state.isSettlementActive && state.settlementMm > 50.0) health -= 15.0;
    health = health.clamp(5.0, 100.0);

    String level = 'SAFE';
    String summary = 'Structure performing within allowable elastic design criteria.';
    if (maxDriftRatio > 0.025 || health < 30.0) {
      level = 'COLLAPSE RISK';
      summary = 'Severe dynamic drift exceedance. Critical plastic hinging & P-Delta instability.';
    } else if (maxDriftRatio > 0.015 || health < 60.0) {
      level = 'SEVERE HAZARD';
      summary = 'Non-linear ductility engaged. Inter-story drift exceeding code drift limits.';
    } else if (maxDriftRatio > 0.007 || health < 85.0) {
      level = 'ELEVATED STRESS';
      summary = 'Noticeable lateral sway and localized member stress concentrations.';
    }

    return EnvironmentalStimulationMetrics(
      maxRoofDriftMm: maxRoofDriftMm,
      maxDriftRatio: maxDriftRatio,
      totalBaseShearKn: totalShearKn,
      totalOverturningMomentKnm: totalOtmKnm,
      structuralIntegrityHealthPct: health,
      overstressedMemberCount: overstressedCount,
      statusSummary: summary,
      hazardLevel: level,
    );
  }
}
