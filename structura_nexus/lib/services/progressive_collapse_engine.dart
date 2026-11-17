// ============================================================================
// ProgressiveCollapseEngine — UFC 4-023-03 & GSA Alternate Load Path (ALP)
// Sudden Notional Column Removal, Catenary Bridging & Vulnerability Sweep
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:math' as math;
import '../models/structural_models.dart';
import 'embedded_fea_solver.dart';

class ColumnRemovalScenarioResult {
  final String removedMemberId;
  final String section;
  final String locationClass; // 'CORNER COLUMN', 'PERIMETER COLUMN', 'INTERIOR COLUMN', 'PRIMARY STRUT'
  final String upperJointId;
  final double dynamicAmplificationFactor; // Omega_LD (default 2.0 per UFC 4-023-03)
  final double catenaryDeflectionMm;
  final double bridgingSpanM;
  final double chordRotationRad;
  final double allowableRotationRad;
  final double baselineMaxDcr;
  final double damagedMaxDcr;
  final int overloadedAdjacentMembers;
  final String mostCriticalAdjacentMemberId;
  final double robustnessIndex; // 0 to 100
  final String status; // 'ROBUST BRIDGING', 'PLASTIC CATENARY', 'COLLAPSE RISK'
  final StructuralModel damagedModel;

  const ColumnRemovalScenarioResult({
    required this.removedMemberId,
    required this.section,
    required this.locationClass,
    required this.upperJointId,
    required this.dynamicAmplificationFactor,
    required this.catenaryDeflectionMm,
    required this.bridgingSpanM,
    required this.chordRotationRad,
    required this.allowableRotationRad,
    required this.baselineMaxDcr,
    required this.damagedMaxDcr,
    required this.overloadedAdjacentMembers,
    required this.mostCriticalAdjacentMemberId,
    required this.robustnessIndex,
    required this.status,
    required this.damagedModel,
  });
}

class ProgressiveCollapseEngine {
  /// Identifies candidate vertical/inclined primary load-bearing columns/struts
  /// suitable for UFC 4-023-03 notional removal.
  static List<StructuralMember> findCandidateColumns(StructuralModel model) {
    final candidates = <StructuralMember>[];
    for (final m in model.members) {
      final nI = model.getNode(m.iNodeId);
      final nJ = model.getNode(m.jNodeId);
      if (nI == null || nJ == null) continue;
      final dy = (nJ.y - nI.y).abs();
      final dx = (nJ.x - nI.x).abs();
      final dz = (nJ.z - nI.z).abs();
      final horiz = math.sqrt(dx * dx + dz * dz);
      // Vertical or steep inclined column/strut
      if (dy > 0.5 && dy >= horiz * 0.75) {
        candidates.add(m);
      }
    }
    if (candidates.isEmpty && model.members.isNotEmpty) {
      return model.members.take(8).toList();
    }
    return candidates;
  }

  /// Classifies a column as Corner, Perimeter, or Interior based on plan bounding box.
  static String classifyColumnLocation(StructuralModel model, StructuralMember member) {
    final nI = model.getNode(member.iNodeId);
    final nJ = model.getNode(member.jNodeId);
    if (nI == null || nJ == null) return 'PRIMARY STRUT';

    double minX = double.infinity, maxX = -double.infinity;
    double minZ = double.infinity, maxZ = -double.infinity;
    for (final n in model.nodes) {
      if (n.x < minX) minX = n.x;
      if (n.x > maxX) maxX = n.x;
      if (n.z < minZ) minZ = n.z;
      if (n.z > maxZ) maxZ = n.z;
    }

    final x = 0.5 * (nI.x + nJ.x);
    final z = 0.5 * (nI.z + nJ.z);
    final onEdgeX = (x - minX).abs() < 0.25 || (x - maxX).abs() < 0.25;
    final onEdgeZ = (z - minZ).abs() < 0.25 || (z - maxZ).abs() < 0.25;

    final minElev = math.min(nI.y, nJ.y);
    final storyPrefix = minElev < 0.5 ? 'GROUND ' : 'UPPER ';

    if (onEdgeX && onEdgeZ) return '${storyPrefix}CORNER COLUMN';
    if (onEdgeX || onEdgeZ) return '${storyPrefix}PERIMETER COLUMN';
    return '${storyPrefix}INTERIOR COLUMN';
  }

  /// Simulates sudden notional removal of [removedMemberId] under UFC 4-023-03
  /// Extreme Event load amplification [dynamicIncreaseFactor] (Omega_LD, typically 2.0).
  static ColumnRemovalScenarioResult evaluateNotionalRemoval({
    required StructuralModel baselineModel,
    required String removedMemberId,
    double dynamicIncreaseFactor = 2.0,
    double allowablePlasticRotationRad = 0.035,
  }) {
    final targetMember = baselineModel.members.firstWhere(
      (m) => m.id == removedMemberId,
      orElse: () => baselineModel.members.first,
    );

    final nI = baselineModel.getNode(targetMember.iNodeId);
    final nJ = baselineModel.getNode(targetMember.jNodeId);
    final upperNode = (nI != null && nJ != null)
        ? (nJ.y >= nI.y ? nJ : nI)
        : (nJ ?? nI);
    final upperJointId = upperNode?.id ?? targetMember.jNodeId;

    double baselineMaxDcr = 0.0;
    for (final m in baselineModel.members) {
      if (m.governingDcr > baselineMaxDcr) baselineMaxDcr = m.governingDcr;
    }

    // Clone model without the removed column, amplifying gravity loads near the affected bay by DIF
    final clonedNodes = baselineModel.nodes.map((n) {
      final loads = List<double>.from(n.loads);
      while (loads.length < 6) {
        loads.add(0.0);
      }
      // UFC 4-023-03 §3-2.9.2: Apply Omega_LD dynamic amplification to bays immediately adjacent to removed element
      bool isAdjacentBay = false;
      if (upperNode != null) {
        final distHoriz = math.sqrt(
          math.pow(n.x - upperNode.x, 2) + math.pow(n.z - upperNode.z, 2),
        );
        if (distHoriz <= 9.0 && n.y >= upperNode.y - 0.5) {
          isAdjacentBay = true;
        }
      }
      final factor = isAdjacentBay ? dynamicIncreaseFactor : 1.0;
      // Ensure non-zero downward extreme event gravity load if node had zero load
      double fy = loads[1] * factor;
      final hasSupport = n.restraint.any((r) => r == 1);
      if (isAdjacentBay && fy.abs() < 1000.0 && !hasSupport) {
        fy = -45000.0 * dynamicIncreaseFactor;
      }
      return n.copyWith(
        loads: [loads[0], fy, loads[2], loads[3], loads[4], loads[5]],
      );
    }).toList();

    final remainingMembers = baselineModel.members
        .where((m) => m.id != targetMember.id)
        .map((m) => m.copyWith())
        .toList();

    final damagedModel = baselineModel.copyWith(
      nodes: clonedNodes,
      members: remainingMembers,
    );

    // Solve damaged 12-DOF Direct Stiffness system
    EmbeddedFeaSolver.solve(damagedModel);

    final damagedUpperNode = damagedModel.getNode(upperJointId);
    double catenaryDeflectionMm = 0.0;
    if (damagedUpperNode != null && damagedUpperNode.displacements.length >= 3) {
      final ux = damagedUpperNode.displacements[0];
      final uy = damagedUpperNode.displacements[1];
      final uz = damagedUpperNode.displacements[2];
      catenaryDeflectionMm = math.sqrt(ux * ux + uy * uy + uz * uz) * 1000.0;
      if (catenaryDeflectionMm < 0.5) {
        catenaryDeflectionMm = uy.abs() * 1000.0;
      }
    }

    // Estimate bridging span from connected horizontal beams at upperJointId
    double bridgingSpanM = 6.0;
    final connectedBeams = damagedModel.members.where(
      (m) => m.iNodeId == upperJointId || m.jNodeId == upperJointId,
    );
    for (final b in connectedBeams) {
      final len = damagedModel.getMemberLength(b);
      if (len > 1.5) {
        bridgingSpanM = len;
        break;
      }
    }

    final chordRotationRad = (catenaryDeflectionMm / 1000.0) / math.max(bridgingSpanM, 1.0);

    double damagedMaxDcr = 0.0;
    int overloadedCount = 0;
    String criticalMemberId = remainingMembers.isNotEmpty ? remainingMembers.first.id : 'NONE';
    for (final m in damagedModel.members) {
      // Under UFC 4-023-03 m-factor plastic acceptance criteria, DCR_ALP is normalized against yield capacity
      if (m.governingDcr > damagedMaxDcr) {
        damagedMaxDcr = m.governingDcr;
        criticalMemberId = m.id;
      }
      if (m.governingDcr > 1.0) {
        overloadedCount++;
      }
    }

    // Determine robustness index (0-100) and status
    final rotRatio = chordRotationRad / math.max(allowablePlasticRotationRad, 0.005);
    final dcrRatio = damagedMaxDcr / 2.0; // m-factor ~ 2.0 for ductile steel framing
    final penalty = math.max(rotRatio, dcrRatio);
    final robustnessIndex = (100.0 * (1.0 - 0.45 * penalty)).clamp(5.0, 99.5);

    String status;
    if (damagedMaxDcr <= 1.0 && chordRotationRad <= allowablePlasticRotationRad * 0.5) {
      status = 'ROBUST BRIDGING';
    } else if (damagedMaxDcr <= 2.0 && chordRotationRad <= allowablePlasticRotationRad) {
      status = 'PLASTIC CATENARY';
    } else {
      status = 'COLLAPSE RISK';
    }

    return ColumnRemovalScenarioResult(
      removedMemberId: targetMember.id,
      section: targetMember.section,
      locationClass: classifyColumnLocation(baselineModel, targetMember),
      upperJointId: upperJointId,
      dynamicAmplificationFactor: dynamicIncreaseFactor,
      catenaryDeflectionMm: catenaryDeflectionMm,
      bridgingSpanM: bridgingSpanM,
      chordRotationRad: chordRotationRad,
      allowableRotationRad: allowablePlasticRotationRad,
      baselineMaxDcr: baselineMaxDcr,
      damagedMaxDcr: damagedMaxDcr,
      overloadedAdjacentMembers: overloadedCount,
      mostCriticalAdjacentMemberId: criticalMemberId,
      robustnessIndex: robustnessIndex,
      status: status,
      damagedModel: damagedModel,
    );
  }

  /// Sweeps candidate columns (up to [maxColumns] ground/critical columns) and
  /// ranks them from highest collapse vulnerability to most robust.
  static List<ColumnRemovalScenarioResult> runVulnerabilitySweep({
    required StructuralModel model,
    double dynamicIncreaseFactor = 2.0,
    int maxColumns = 12,
  }) {
    final candidates = findCandidateColumns(model);
    // Prioritize ground-floor columns first
    candidates.sort((a, b) {
      final aY = math.min(
        model.getNode(a.iNodeId)?.y ?? 0.0,
        model.getNode(a.jNodeId)?.y ?? 0.0,
      );
      final bY = math.min(
        model.getNode(b.iNodeId)?.y ?? 0.0,
        model.getNode(b.jNodeId)?.y ?? 0.0,
      );
      return aY.compareTo(bY);
    });

    final selected = candidates.take(maxColumns).toList();
    final results = <ColumnRemovalScenarioResult>[];
    for (final col in selected) {
      results.add(
        evaluateNotionalRemoval(
          baselineModel: model,
          removedMemberId: col.id,
          dynamicIncreaseFactor: dynamicIncreaseFactor,
        ),
      );
    }

    // Sort by highest damagedMaxDcr descending
    results.sort((a, b) => b.damagedMaxDcr.compareTo(a.damagedMaxDcr));
    return results;
  }
}
