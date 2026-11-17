// ============================================================================
// TributaryLoadPropagator — Automated Tributary Gravity & ASCE 7 Lateral Engine
// Calculates horizontal diaphragm tributary floor areas (Atrib) & ASCE 7-16
// directional windward/leeward pressures + ELF seismic story shears.
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:math' as math;
import '../models/structural_models.dart';

class TributaryPropagationSummary {
  final int storyCount;
  final double totalFloorAreaM2;
  final double totalFactoredGravityLoadKn;
  final double totalWindBaseShearKn;
  final double totalSeismicBaseShearKn;
  final List<double> floorElevations;
  final int affectedNodesCount;

  const TributaryPropagationSummary({
    required this.storyCount,
    required this.totalFloorAreaM2,
    required this.totalFactoredGravityLoadKn,
    required this.totalWindBaseShearKn,
    required this.totalSeismicBaseShearKn,
    required this.floorElevations,
    required this.affectedNodesCount,
  });
}

class TributaryLoadPropagator {
  /// Default dead load: 150mm normal concrete slab (3.6 kPa) + finishes/MEP (1.2 kPa) = 4.8 kPa
  static const double defaultDeadLoadKpa = 4.8;

  /// Default live load: ASCE 7-16 Table 4.3-1 / IBC 2024 Office/Commercial occupancy = 2.4 kPa
  static const double defaultLiveLoadKpa = 2.4;

  /// Default ASCE 7-16 basic wind speed V: 45.0 m/s (100 mph)
  static const double defaultWindSpeedMps = 45.0;

  /// Velocity pressure exposure coefficient Kz (ASCE 7-16 Table 26.10-1)
  static double calculateKz(double z, {String exposure = 'B'}) {
    final exp = exposure.toUpperCase();
    double alpha = 7.0;
    double zg = 365.76;
    double zmin = 4.57;

    if (exp == 'C') {
      alpha = 9.5;
      zg = 274.32;
      zmin = 4.57;
    } else if (exp == 'D') {
      alpha = 11.5;
      zg = 213.36;
      zmin = 2.13;
    }

    final effectiveZ = math.max(z, zmin).clamp(zmin, zg);
    return 2.01 * math.pow(effectiveZ / zg, 2.0 / alpha);
  }

  /// Evaluates and distributes floor gravity loads (1.2D + 1.6L) and ASCE 7-16 lateral forces.
  static TributaryPropagationSummary propagate({
    required StructuralModel model,
    double deadLoadKpa = defaultDeadLoadKpa,
    double liveLoadKpa = defaultLiveLoadKpa,
    double windSpeedMps = defaultWindSpeedMps,
    String exposure = 'B',
    bool applyLateral = true,
    bool preserveManualLoads = true,
  }) {
    if (model.nodes.isEmpty) {
      return const TributaryPropagationSummary(
        storyCount: 0,
        totalFloorAreaM2: 0,
        totalFactoredGravityLoadKn: 0,
        totalWindBaseShearKn: 0,
        totalSeismicBaseShearKn: 0,
        floorElevations: [],
        affectedNodesCount: 0,
      );
    }

    // 1. Group nodes by floor diaphragms (Y elevation rounded to nearest 0.1m)
    final Map<double, List<StructuralNode>> floorGroups = {};
    for (final node in model.nodes) {
      final yElev = (node.coords.y * 10).round() / 10.0;
      floorGroups.putIfAbsent(yElev, () => []).add(node);
    }

    final sortedElevations = floorGroups.keys.toList()..sort();
    final elevatedFloors = sortedElevations.where((y) => y > 0.1).toList();

    // 2. Factored gravity load per m2 in N/m2: (1.2D + 1.6L) * 1000
    final factoredLoadDensityNm2 = (1.2 * deadLoadKpa + 1.6 * liveLoadKpa) * 1000.0;

    double grandTotalAreaM2 = 0.0;
    double grandTotalGravityLoadN = 0.0;
    int affectedNodes = 0;

    // 3. Compute tributary areas per node on each elevated floor
    for (final y in elevatedFloors) {
      final floorNodes = floorGroups[y]!;
      final xs = floorNodes.map((n) => (n.coords.x * 100).round() / 100.0).toSet().toList()..sort();
      final zs = floorNodes.map((n) => (n.coords.z * 100).round() / 100.0).toSet().toList()..sort();

      for (final node in floorNodes) {
        if (preserveManualLoads && node.loadSource == 'MANUAL') {
          continue;
        }

        final nx = (node.coords.x * 100).round() / 100.0;
        final nz = (node.coords.z * 100).round() / 100.0;

        // X tributary span
        double spanX = 4.0; // fallback
        final xi = xs.indexOf(nx);
        if (xs.length > 1 && xi >= 0) {
          final double left = xi > 0 ? (nx - xs[xi - 1]) : (xs[1] - xs[0]);
          final double right = xi < xs.length - 1 ? (xs[xi + 1] - nx) : (xs[xs.length - 1] - xs[xs.length - 2]);
          spanX = (xi == 0 || xi == xs.length - 1) ? 0.5 * (xi == 0 ? right : left) : 0.5 * (left + right);
        }

        // Z tributary span
        double spanZ = 4.0; // fallback
        final zi = zs.indexOf(nz);
        if (zs.length > 1 && zi >= 0) {
          final double back = zi > 0 ? (nz - zs[zi - 1]) : (zs[1] - zs[0]);
          final double front = zi < zs.length - 1 ? (zs[zi + 1] - nz) : (zs[zs.length - 1] - zs[zs.length - 2]);
          spanZ = (zi == 0 || zi == zs.length - 1) ? 0.5 * (zi == 0 ? front : back) : 0.5 * (back + front);
        }

        final tribArea = math.max(spanX * spanZ, 1.0);
        node.tributaryAreaM2 = tribArea;
        node.loadSource = 'TRIBUTARY_AUTO';

        final gravityLoadN = -tribArea * factoredLoadDensityNm2;
        grandTotalAreaM2 += tribArea;
        grandTotalGravityLoadN += gravityLoadN.abs();

        // Assign gravity Fy to loads[1]
        while (node.loads.length < 6) {
          node.loads.add(0.0);
        }
        node.loads[1] = gravityLoadN;
        affectedNodes++;
      }
    }

    // 4. Calculate ASCE 7-16 Lateral Loads (Wind & Seismic ELF)
    double totalWindBaseShearN = 0.0;
    double totalSeismicBaseShearN = 0.0;

    if (applyLateral && elevatedFloors.isNotEmpty) {
      final allNodes = model.nodes;
      final xsAll = allNodes.map((n) => n.coords.x).toList();
      final zsAll = allNodes.map((n) => n.coords.z).toList();
      final minX = xsAll.reduce(math.min);
      final maxX = xsAll.reduce(math.max);
      final minZ = zsAll.reduce(math.min);
      final maxZ = zsAll.reduce(math.max);

      final buildingWidthZ = math.max(maxZ - minZ, 4.0);
      final buildingDepthX = math.max(maxX - minX, 4.0);
      final buildingHeight = elevatedFloors.last;

      // Mean roof velocity pressure qh
      final qh = 0.613 * calculateKz(buildingHeight, exposure: exposure) * 0.85 * math.pow(windSpeedMps, 2);
      final cpWindward = 0.85 * 0.8;
      final lOverB = buildingDepthX / buildingWidthZ;
      final cpLeeward = 0.85 * (lOverB <= 1.0 ? 0.5 : (lOverB >= 4.0 ? 0.2 : 0.5 - (lOverB - 1.0) * (0.3 / 3.0)));

      // Tributary heights for each story
      final Map<double, double> storyTributaryH = {};
      for (int i = 0; i < elevatedFloors.length; i++) {
        final currentY = elevatedFloors[i];
        final prevY = i > 0 ? elevatedFloors[i - 1] : 0.0;
        final nextY = i < elevatedFloors.length - 1 ? elevatedFloors[i + 1] : currentY + (currentY - prevY);
        final hTrib = 0.5 * (nextY - prevY);
        storyTributaryH[currentY] = math.max(hTrib, 1.5);
      }

      // Wind distribution along +X direction
      for (final y in elevatedFloors) {
        final qz = 0.613 * calculateKz(y, exposure: exposure) * 0.85 * math.pow(windSpeedMps, 2);
        final pNet = (qz * cpWindward) + (qh * cpLeeward);
        final hTrib = storyTributaryH[y] ?? 3.0;
        final storyWindForceN = pNet * buildingWidthZ * hTrib;
        totalWindBaseShearN += storyWindForceN;

        // Distribute to windward nodes (nodes with x ~= minX)
        final floorNodes = floorGroups[y]!;
        final windwardNodes = floorNodes.where((n) => (n.coords.x - minX).abs() < 0.15).toList();
        final targetNodes = windwardNodes.isNotEmpty ? windwardNodes : floorNodes;
        final nodalWindForceN = storyWindForceN / targetNodes.length;

        for (final node in targetNodes) {
          if (preserveManualLoads && node.loadSource == 'MANUAL') continue;
          node.loads[0] = (node.loads[0] + nodalWindForceN);
          node.loadSource = 'TRIBUTARY_AUTO';
        }
      }

      // Approximate Seismic ELF Base Shear (ASCE 7-16 Sec 12.8)
      // Wservice ~= Total factored gravity / 1.2
      final serviceWeightN = grandTotalGravityLoadN / 1.2;
      final cs = 0.085; // Typical seismic response coefficient (SDS / (R/Ie))
      final vSeismicN = cs * serviceWeightN;
      totalSeismicBaseShearN = vSeismicN;

      // Vertical distribution factor Cvx = (w_x * h_x^k) / sum(w_i * h_i^k)
      final kExp = buildingHeight > 15.0 ? 1.5 : 1.0;
      double sumWhk = 0.0;
      for (final y in elevatedFloors) {
        final floorWeight = (floorGroups[y]!.length / allNodes.length) * serviceWeightN;
        sumWhk += floorWeight * math.pow(y, kExp);
      }

      if (sumWhk > 0) {
        for (final y in elevatedFloors) {
          final floorWeight = (floorGroups[y]!.length / allNodes.length) * serviceWeightN;
          final cvx = (floorWeight * math.pow(y, kExp)) / sumWhk;
          final storySeismicN = cvx * vSeismicN;

          // Seismic distributed to all joints on floor
          final floorNodes = floorGroups[y]!;
          final nodalSeismicN = storySeismicN / floorNodes.length;

          for (final node in floorNodes) {
            if (preserveManualLoads && node.loadSource == 'MANUAL') continue;
            // Add seismic shear in +Z direction or +X direction
            node.loads[2] = nodalSeismicN * 0.3; // 30% orthogonal ASCE 7 combination
          }
        }
      }
    }

    return TributaryPropagationSummary(
      storyCount: elevatedFloors.length,
      totalFloorAreaM2: grandTotalAreaM2,
      totalFactoredGravityLoadKn: grandTotalGravityLoadN / 1000.0,
      totalWindBaseShearKn: totalWindBaseShearN / 1000.0,
      totalSeismicBaseShearKn: totalSeismicBaseShearN / 1000.0,
      floorElevations: elevatedFloors,
      affectedNodesCount: affectedNodes,
    );
  }
}
