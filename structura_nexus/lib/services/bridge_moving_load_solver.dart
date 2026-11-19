// ============================================================================
// BridgeMovingLoadSolver — AASHTO LRFD HL-93 Moving-Load & Influence-Line Engine
// 40-Step 12-DOF DSM Envelope Solver, Influence Ordinates η(x) & Fatigue Δf
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:convert';
import 'dart:math' as math;
import '../models/structural_models.dart';
import 'embedded_fea_solver.dart';

class BridgeMemberEnvelope {
  final String memberId;
  final String section;
  final double pMaxKn;
  final double pMinKn;
  final double vMaxKn;
  final double mMaxKnm;
  final double mMinKnm;
  final double maxDcr;
  final double fatigueStressRangeMpa;
  final double fatigueThresholdMpa;
  final String fatigueStatus;
  final int criticalStepIndex;
  final double criticalTruckXM;

  const BridgeMemberEnvelope({
    required this.memberId,
    required this.section,
    required this.pMaxKn,
    required this.pMinKn,
    required this.vMaxKn,
    required this.mMaxKnm,
    required this.mMinKnm,
    required this.maxDcr,
    required this.fatigueStressRangeMpa,
    required this.fatigueThresholdMpa,
    required this.fatigueStatus,
    required this.criticalStepIndex,
    required this.criticalTruckXM,
  });
}

class MovingLoadStepState {
  final int stepIndex;
  final double leadAxleXM;
  final double deckElevationYM;
  final double deckCenterZM;
  final double normalizedProgress;
  final double maxDeckDeflectionMm;
  final double governingDcr;
  final double influenceOrdinate;
  final List<Map<String, double>> activeAxles; // [{'x': ..., 'load_kn': ...}]
  final Map<String, List<double>> nodeDisplacements;
  final Map<String, double> memberDcrs;

  const MovingLoadStepState({
    required this.stepIndex,
    required this.leadAxleXM,
    required this.deckElevationYM,
    required this.deckCenterZM,
    required this.normalizedProgress,
    required this.maxDeckDeflectionMm,
    required this.governingDcr,
    required this.influenceOrdinate,
    required this.activeAxles,
    required this.nodeDisplacements,
    required this.memberDcrs,
  });

  String toTruckViewportJson() => jsonEncode({
        'lead_x_m': leadAxleXM,
        'deck_y_m': deckElevationYM,
        'deck_z_m': deckCenterZM,
        'axles': activeAxles,
        'member_dcrs': memberDcrs,
      });
}

class BridgeMovingLoadEnvelopeResult {
  final String vehicleType;
  final double spanMinXM;
  final double spanMaxXM;
  final double spanLengthM;
  final int numSteps;
  final double multiPresenceFactorM;
  final double dynamicAllowanceFactor;
  final String targetInfluenceMemberId;
  final List<double> influenceLineXM;
  final List<double> influenceLineOrdinates;
  final List<BridgeMemberEnvelope> memberEnvelopes;
  final List<MovingLoadStepState> stepStates;
  final double governingBridgeDcr;
  final double maxFatigueStressRangeMpa;
  final String overallStatus;

  const BridgeMovingLoadEnvelopeResult({
    required this.vehicleType,
    required this.spanMinXM,
    required this.spanMaxXM,
    required this.spanLengthM,
    required this.numSteps,
    required this.multiPresenceFactorM,
    required this.dynamicAllowanceFactor,
    required this.targetInfluenceMemberId,
    required this.influenceLineXM,
    required this.influenceLineOrdinates,
    required this.memberEnvelopes,
    required this.stepStates,
    required this.governingBridgeDcr,
    required this.maxFatigueStressRangeMpa,
    required this.overallStatus,
  });
}

class BridgeMovingLoadSolver {
  static const Map<int, double> _multiPresenceFactors = {
    1: 1.20,
    2: 1.00,
    3: 0.85,
    4: 0.65,
  };

  /// Runs a 40-step AASHTO LRFD HL-93 moving-load envelope analysis across [model].
  static BridgeMovingLoadEnvelopeResult solveEnvelopes({
    required StructuralModel model,
    String vehicleType = 'HL93_TRUCK_PLUS_LANE',
    int numSteps = 40,
    double rearAxleSpacingM = 4.3,
    double dynamicLoadAllowanceIm = 0.33,
    double laneLoadKnPerM = 9.3,
    int numLanes = 1,
    String? targetInfluenceMemberId,
  }) {
    final nodes = model.nodes;
    final members = model.members;
    final nSteps = numSteps.clamp(5, 80);

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double sumZ = 0.0;

    for (final n in nodes) {
      if (n.x < minX) minX = n.x;
      if (n.x > maxX) maxX = n.x;
      if (n.y < minY) minY = n.y;
      sumZ += n.z;
    }
    if (!minX.isFinite) minX = 0.0;
    if (!maxX.isFinite || maxX <= minX) maxX = minX + 36.0;
    if (!minY.isFinite) minY = 0.0;
    final spanLen = math.max(1.0, maxX - minX);
    final avgZ = nodes.isEmpty ? 0.0 : sumZ / nodes.length;

    // Identify deck stringer / bottom-chord nodes
    var deckNodes = nodes.where((n) => (n.y - minY).abs() <= 1.6).toList();
    if (deckNodes.length < 2) {
      deckNodes = List<StructuralNode>.from(nodes);
    }

    double mFactor = _multiPresenceFactors[numLanes] ?? 0.65;
    double imFactor = 1.0 + dynamicLoadAllowanceIm;
    double laneQ = laneLoadKnPerM;

    final vType = vehicleType.toUpperCase();
    late final List<MapEntry<double, double>> axles; // offset_m -> axle_kn
    if (vType.contains('TANDEM')) {
      axles = const [
        MapEntry(0.0, 110.0),
        MapEntry(1.2, 110.0),
      ];
    } else if (vType.contains('FATIGUE')) {
      axles = const [
        MapEntry(0.0, 35.0),
        MapEntry(4.3, 145.0),
        MapEntry(13.3, 145.0),
      ];
      imFactor = 1.15;
      mFactor = 1.0;
      laneQ = 0.0;
    } else {
      final sRear = rearAxleSpacingM.clamp(4.3, 9.0);
      axles = [
        const MapEntry(0.0, 35.0),
        const MapEntry(4.3, 145.0),
        MapEntry(4.3 + sRear, 145.0),
      ];
    }

    final truckLen = axles.last.key;
    final targetMemberId = targetInfluenceMemberId ?? (members.isNotEmpty ? members.first.id : 'M1');

    final pMaxMap = <String, double>{};
    final pMinMap = <String, double>{};
    final vMaxMap = <String, double>{};
    final mMaxMap = <String, double>{};
    final mMinMap = <String, double>{};
    final dcrMaxMap = <String, double>{};
    final critStepMap = <String, int>{};
    final critXMap = <String, double>{};

    for (final m in members) {
      pMaxMap[m.id] = -1e12;
      pMinMap[m.id] = 1e12;
      vMaxMap[m.id] = 0.0;
      mMaxMap[m.id] = -1e12;
      mMinMap[m.id] = 1e12;
      dcrMaxMap[m.id] = 0.0;
      critStepMap[m.id] = 0;
      critXMap[m.id] = minX;
    }

    double totalTruckKn = 0.0;
    for (final a in axles) {
      totalTruckKn += a.value * imFactor * mFactor;
    }

    final influenceX = <double>[];
    final influenceOrd = <double>[];
    final stepStates = <MovingLoadStepState>[];

    final deckIds = deckNodes.map((n) => n.id).toSet();
    final tribDx = spanLen / math.max(1, deckNodes.length - 1);

    for (int stepIdx = 0; stepIdx < nSteps; stepIdx++) {
      final progress = stepIdx / math.max(1, nSteps - 1);
      final leadX = minX + progress * (spanLen + truckLen);

      final stepModel = model.copyWith(
        nodes: model.nodes.map((n) {
          final isRestrained = n.restraint.any((r) => r == 1);
          double fy = 0.0;
          if (deckIds.contains(n.id) && !isRestrained) {
            fy = -laneQ * 1000.0 * tribDx * mFactor * 0.5;
          }
          return n.copyWith(loads: [0.0, fy, 0.0, 0.0, 0.0, 0.0]);
        }).toList(),
        members: model.members.map((m) => m.copyWith()).toList(),
      );

      final stepDeckNodes = stepModel.nodes.where((n) => deckIds.contains(n.id)).toList();
      final activeAxles = <Map<String, double>>[];

      for (final a in axles) {
        final axleX = leadX - a.key;
        if (axleX >= minX - 0.5 && axleX <= maxX + 0.5) {
          final factoredAxleKn = a.value * imFactor * mFactor;
          activeAxles.add({
            'x': axleX.clamp(minX, maxX),
            'load_kn': factoredAxleKn,
          });
          final factoredAxleN = factoredAxleKn * 1000.0;

          stepDeckNodes.sort((n1, n2) => (n1.x - axleX).abs().compareTo((n2.x - axleX).abs()));
          if (stepDeckNodes.length >= 2) {
            final n1 = stepDeckNodes[0];
            final n2 = stepDeckNodes[1];
            final d1 = (n1.x - axleX).abs();
            final d2 = (n2.x - axleX).abs();
            final dTot = math.max(0.01, d1 + d2);
            final w1 = 1.0 - (d1 / dTot);
            final w2 = 1.0 - w1;
            n1.loads[1] -= factoredAxleN * w1;
            n2.loads[1] -= factoredAxleN * w2;
          } else if (stepDeckNodes.isNotEmpty) {
            stepDeckNodes.first.loads[1] -= factoredAxleN;
          }
        }
      }

      EmbeddedFeaSolver.solve(stepModel);

      double maxDeflMm = 0.0;
      final nodeDisps = <String, List<double>>{};
      for (final n in stepModel.nodes) {
        final dyMm = n.dispY.abs() * 1000.0;
        if (dyMm > maxDeflMm) maxDeflMm = dyMm;
        nodeDisps[n.id] = List<double>.from(n.displacements);
      }

      double stepGovDcr = 0.0;
      double stepOrd = 0.0;
      final memberDcrs = <String, double>{};

      for (final m in stepModel.members) {
        final pKn = m.axialForceN / 1000.0;
        final vKn = m.shearForceN.abs() / 1000.0;
        final mKnm = m.bendingMomentNm / 1000.0;
        final dcr = m.governingDcr;
        memberDcrs[m.id] = dcr;

        if (dcr > stepGovDcr) stepGovDcr = dcr;

        if (pKn > pMaxMap[m.id]!) pMaxMap[m.id] = pKn;
        if (pKn < pMinMap[m.id]!) pMinMap[m.id] = pKn;
        if (vKn > vMaxMap[m.id]!) vMaxMap[m.id] = vKn;
        if (mKnm > mMaxMap[m.id]!) mMaxMap[m.id] = mKnm;
        if (mKnm < mMinMap[m.id]!) mMinMap[m.id] = mKnm;
        if (dcr >= dcrMaxMap[m.id]!) {
          dcrMaxMap[m.id] = dcr;
          critStepMap[m.id] = stepIdx;
          critXMap[m.id] = leadX.clamp(minX, maxX);
        }

        if (m.id == targetMemberId) {
          final respMag = pKn.abs() >= mKnm.abs() ? pKn : mKnm;
          stepOrd = respMag / math.max(totalTruckKn, 1.0);
        }
      }

      final clampedCentroidX = (leadX - 0.5 * truckLen).clamp(minX, maxX);
      influenceX.add(clampedCentroidX);
      influenceOrd.add(stepOrd);

      stepStates.add(
        MovingLoadStepState(
          stepIndex: stepIdx,
          leadAxleXM: clampedCentroidX,
          deckElevationYM: minY,
          deckCenterZM: avgZ,
          normalizedProgress: progress,
          maxDeckDeflectionMm: maxDeflMm,
          governingDcr: stepGovDcr,
          influenceOrdinate: stepOrd,
          activeAxles: activeAxles,
          nodeDisplacements: nodeDisps,
          memberDcrs: memberDcrs,
        ),
      );
    }

    final envelopesOut = <BridgeMemberEnvelope>[];
    double govBridgeDcr = 0.0;
    double maxFatigueMpa = 0.0;
    const fatigueThresholdMpa = 69.0; // AASHTO Category C constant-amplitude threshold

    for (final m in members) {
      final pMax = pMaxMap[m.id]!;
      final pMin = pMinMap[m.id]!;
      final vMax = vMaxMap[m.id]!;
      final mMax = mMaxMap[m.id]!;
      final mMin = mMinMap[m.id]!;
      final maxDcr = dcrMaxMap[m.id]!;

      final deltaPKn = (pMax - pMin).abs();
      final deltaMKnm = (mMax - mMin).abs();
      final stressRangeMpa = ((deltaPKn / 118.0) + (deltaMKnm / 2.34)) * 0.45;

      if (maxDcr > govBridgeDcr) govBridgeDcr = maxDcr;
      if (stressRangeMpa > maxFatigueMpa) maxFatigueMpa = stressRangeMpa;

      envelopesOut.add(
        BridgeMemberEnvelope(
          memberId: m.id,
          section: m.section,
          pMaxKn: pMax,
          pMinKn: pMin,
          vMaxKn: vMax,
          mMaxKnm: mMax,
          mMinKnm: mMin,
          maxDcr: maxDcr,
          fatigueStressRangeMpa: stressRangeMpa,
          fatigueThresholdMpa: fatigueThresholdMpa,
          fatigueStatus: stressRangeMpa <= fatigueThresholdMpa ? 'PASS' : 'FATIGUE ALERT',
          criticalStepIndex: critStepMap[m.id]!,
          criticalTruckXM: critXMap[m.id]!,
        ),
      );
    }

    return BridgeMovingLoadEnvelopeResult(
      vehicleType: vehicleType,
      spanMinXM: minX,
      spanMaxXM: maxX,
      spanLengthM: spanLen,
      numSteps: nSteps,
      multiPresenceFactorM: mFactor,
      dynamicAllowanceFactor: imFactor,
      targetInfluenceMemberId: targetMemberId,
      influenceLineXM: influenceX,
      influenceLineOrdinates: influenceOrd,
      memberEnvelopes: envelopesOut,
      stepStates: stepStates,
      governingBridgeDcr: govBridgeDcr,
      maxFatigueStressRangeMpa: maxFatigueMpa,
      overallStatus: govBridgeDcr <= 1.0 ? 'PASS (AASHTO LRFD HL-93)' : 'OVERSTRESSED',
    );
  }
}

