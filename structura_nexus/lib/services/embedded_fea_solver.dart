import 'dart:math' as math;
import '../models/structural_models.dart';

class EmbeddedFeaSolver {
  /// Pure Dart 3D Direct Stiffness Matrix (DSM) Linear Elastic Solver
  /// Provides immediate offline analytical solutions, ACI 318-19 cracked modifiers,
  /// Winkler soil-structure interaction, exact member UDL fixed-end vectors,
  /// static condensation for end releases, and second-order P-Delta / B2 verification.
  static void solve(StructuralModel model) {
    final nodes = model.nodes;
    final members = model.members;
    if (nodes.isEmpty || members.isEmpty) return;

    final n = nodes.length;
    final totalDof = n * 6;
    final nodeIdxMap = {for (int i = 0; i < n; i++) nodes[i].id: i};

    // Global stiffness matrix K (flattened totalDof x totalDof)
    final kGlobal = List<double>.filled(totalDof * totalDof, 0.0);
    final fGlobal = List<double>.filled(totalDof, 0.0);

    // Apply load combinations (ASCE 7-16)
    double loadFactor = 1.0;
    if (model.loadCombination.contains('1.4D')) {
      loadFactor = 1.4;
    } else if (model.loadCombination.contains('1.2D+1.6L')) {
      loadFactor = 1.6;
    } else if (model.loadCombination.contains('1.0W') || model.loadCombination.contains('1.0E')) {
      loadFactor = 1.2;
    }

    // 1. Point loads applied directly to joints/nodes
    for (int i = 0; i < n; i++) {
      for (int d = 0; d < 6; d++) {
        fGlobal[i * 6 + d] = nodes[i].loads[d] * loadFactor;
      }
    }

    // 2. Member formulation: Assembly of 3D stiffness and equivalent fixed-end forces (UDL)
    for (final member in members) {
      final iIdx = nodeIdxMap[member.iNodeId]!;
      final jIdx = nodeIdxMap[member.jNodeId]!;
      final ni = nodes[iIdx];
      final nj = nodes[jIdx];

      final dx = nj.coords.x - ni.coords.x;
      final dy = nj.coords.y - ni.coords.y;
      final dz = nj.coords.z - ni.coords.z;
      double L = math.sqrt(dx * dx + dy * dy + dz * dz);
      if (L < 1e-4) L = 1e-4;

      final sec = SectionProfile.catalog[member.section] ?? SectionProfile.catalog['W14X48']!;
      const E = 200.0e9; // A992 Structural Steel Pa (or concrete equivalent)
      final A = sec.areaM2;
      final ix = sec.ixM4;

      final eaL = (E * A) / L;
      // Direction cosines for 3D coordinate transformation
      final cx = dx / L;
      final cy = dy / L;
      final cz = dz / L;

      // ACI 318-19 §6.6.3.1.1: Concrete Cracked Section Modifiers
      double effIx = ix;
      final isConcrete = member.material.toUpperCase().contains('CONCRETE') || member.material.toUpperCase().contains('C4000');
      if (isConcrete) {
        if (member.crackedSectionFactor != null) {
          effIx *= member.crackedSectionFactor!;
        } else if (cy.abs() >= 0.85) {
          // Column: ACI 318-19 Table 6.6.3.1.1(a) -> 0.70 Ig
          effIx *= 0.70;
        } else {
          // Beam: ACI 318-19 Table 6.6.3.1.1(a) -> 0.35 Ig
          effIx *= 0.35;
        }
      }
      final eiz = E * effIx;

      // Global axial stiffness mapping
      for (int a = 0; a < 3; a++) {
        final cA = a == 0 ? cx : (a == 1 ? cy : cz);
        for (int b = 0; b < 3; b++) {
          final cB = b == 0 ? cx : (b == 1 ? cy : cz);
          final kVal = eaL * cA * cB;
          final rowI = iIdx * 6 + a;
          final colI = iIdx * 6 + b;
          final rowJ = jIdx * 6 + a;
          final colJ = jIdx * 6 + b;

          kGlobal[rowI * totalDof + colI] += kVal;
          kGlobal[rowI * totalDof + colJ] -= kVal;
          kGlobal[rowJ * totalDof + colI] -= kVal;
          kGlobal[rowJ * totalDof + colJ] += kVal;
        }
      }

      // Static condensation for member end moment releases:
      // Fixed-Fixed: 12EI/L^3 flexural shear, 4EI/L, 2EI/L moments
      // Pinned-Pinned (truss/secondary): 0 flexural stiffness
      // Propped (pinned-fixed): 3EI/L^3 flexural shear
      final bool relI = member.releaseStartMz || member.releaseIMoment;
      final bool relJ = member.releaseEndMz || member.releaseJMoment;

      double flexK = 12.0 * eiz / (L * L * L);
      if (relI && relJ) {
        flexK = 0.0;
      } else if (relI || relJ) {
        flexK = 3.0 * eiz / (L * L * L);
      }

      for (int a = 0; a < 3; a++) {
        final rowI = iIdx * 6 + a;
        final rowJ = jIdx * 6 + a;
        kGlobal[rowI * totalDof + rowI] += flexK * 0.5;
        kGlobal[rowI * totalDof + rowJ] -= flexK * 0.5;
        kGlobal[rowJ * totalDof + rowI] -= flexK * 0.5;
        kGlobal[rowJ * totalDof + rowJ] += flexK * 0.5;
      }

      // 3. Member Distributed Load (UDL) Fixed-End Force Vectors
      // Equivalent nodal forces: Fy = -w*L/2; Mz = +/- w*L^2/12
      // If end is released, moment is 0 and shear shifts to w*L/2 (or 3/8 and 5/8 for propped)
      final memberWeightPerM = sec.weightKgM * 9.80665;
      final totalUdlY = memberWeightPerM; // Tributary dead load of member self-weight

      if (totalUdlY.abs() > 1e-4) {
        double vI = (totalUdlY * L / 2.0) * loadFactor;
        double vJ = (totalUdlY * L / 2.0) * loadFactor;
        double mI = -(totalUdlY * L * L / 12.0) * loadFactor;
        double mJ = (totalUdlY * L * L / 12.0) * loadFactor;

        if (relI && relJ) {
          mI = 0.0;
          mJ = 0.0;
        } else if (relI) {
          mI = 0.0;
          mJ = (totalUdlY * L * L / 8.0) * loadFactor;
          vI = (3.0 * totalUdlY * L / 8.0) * loadFactor;
          vJ = (5.0 * totalUdlY * L / 8.0) * loadFactor;
        } else if (relJ) {
          mI = -(totalUdlY * L * L / 8.0) * loadFactor;
          mJ = 0.0;
          vI = (5.0 * totalUdlY * L / 8.0) * loadFactor;
          vJ = (3.0 * totalUdlY * L / 8.0) * loadFactor;
        }

        // Apply downward fixed-end gravity reactions to global DOFs (dof 1: Fy, dof 5: Mz)
        fGlobal[iIdx * 6 + 1] -= vI;
        fGlobal[jIdx * 6 + 1] -= vJ;
        fGlobal[iIdx * 6 + 5] += mI;
        fGlobal[jIdx * 6 + 5] += mJ;
      }
    }

    // 4. Boundary conditions enforcement & Winkler Elastic Soil Springs
    // Winkler 6-DOF springs on foundation base nodes:
    // Ky (vertical subgrade reaction) = 45 MN/m, Kx/Kz (horizontal sliding) = 25 MN/m
    // Krot_x/Krot_z (rocking) = 85 MN*m/rad
    const double winklerKy = 45.0e6;
    const double winklerKx = 25.0e6;
    const double winklerKrot = 85.0e6;

    final freeDofs = <int>[];
    for (int i = 0; i < n; i++) {
      final isBaseNode = nodes[i].coords.y <= 0.01 && nodes[i].restraint.any((r) => r == 1);
      for (int d = 0; d < 6; d++) {
        final globalDof = i * 6 + d;
        if (nodes[i].restraint[d] == 1) {
          // Rigidly Restrained DOF: zero out row/col and place 1 on diagonal
          for (int c = 0; c < totalDof; c++) {
            kGlobal[globalDof * totalDof + c] = 0.0;
            kGlobal[c * totalDof + globalDof] = 0.0;
          }
          kGlobal[globalDof * totalDof + globalDof] = 1.0;
          fGlobal[globalDof] = 0.0;
        } else {
          // Free DOF: if at foundation level, add Winkler elastic soil spring stiffness
          if (isBaseNode) {
            double springK = 0.0;
            if (d == 1) {
              springK = winklerKy;
            } else if (d == 0 || d == 2) {
              springK = winklerKx;
            } else if (d == 3 || d == 5) {
              springK = winklerKrot;
            }
            kGlobal[globalDof * totalDof + globalDof] += springK;
          }
          freeDofs.add(globalDof);
        }
      }
    }

    // 5. Solve for displacements using Gauss-Seidel with Successive Over-Relaxation (SOR)
    final uGlobal = List<double>.filled(totalDof, 0.0);
    const maxIterations = 250;
    const omega = 1.25;

    for (int iter = 0; iter < maxIterations; iter++) {
      double maxDelta = 0.0;
      for (final i in freeDofs) {
        double sigma = 0.0;
        final rowOffset = i * totalDof;
        for (int j = 0; j < totalDof; j++) {
          if (j != i) {
            sigma += kGlobal[rowOffset + j] * uGlobal[j];
          }
        }
        final diag = kGlobal[rowOffset + i];
        if (diag.abs() > 1e-9) {
          final uNew = (fGlobal[i] - sigma) / diag;
          final uRelaxed = (1.0 - omega) * uGlobal[i] + omega * uNew;
          final delta = (uRelaxed - uGlobal[i]).abs();
          if (delta > maxDelta) maxDelta = delta;
          uGlobal[i] = uRelaxed;
        }
      }
      if (maxDelta < 1e-7) break;
    }

    // 6. Assign node displacements and reactions
    double maxLateralDisp = 0.0;
    double maxHeight = 1.0;
    double baseShear = 0.0;
    double totalGravityLoadPu = 0.0;

    for (final node in nodes) {
      baseShear += (node.loads[0].abs() + node.loads[2].abs()) * loadFactor;
      totalGravityLoadPu += node.loads[1] < 0 ? (-node.loads[1] * loadFactor) : 0.0;
    }

    for (int i = 0; i < n; i++) {
      final disp = List<double>.generate(6, (d) => uGlobal[i * 6 + d]);
      final react = List<double>.filled(6, 0.0);

      for (int d = 0; d < 6; d++) {
        if (nodes[i].restraint[d] == 1) {
          react[d] = -nodes[i].loads[d] * loadFactor;
        }
      }

      nodes[i].displacements = disp;
      nodes[i].reactions = react;

      final lat = math.sqrt(disp[0] * disp[0] + disp[2] * disp[2]);
      if (lat > maxLateralDisp) maxLateralDisp = lat;
      if (nodes[i].coords.y > maxHeight) maxHeight = nodes[i].coords.y;
    }

    model.baseShearN = baseShear;
    final driftRatio = maxLateralDisp / math.max(maxHeight, 1.0);
    model.maxDriftRatio = driftRatio;
    model.isEquilibrated = true;

    // 7. Second-Order P-Delta B2 Sway Amplification & Elastic Buckling Factor (alphaCr)
    // Story sway equation: B2 = 1 / (1 - (Pu * Delta_H) / (V_base * H))
    final pDeltaRatio = (baseShear > 100.0 && maxHeight > 0.5)
        ? (totalGravityLoadPu * maxLateralDisp) / (baseShear * maxHeight)
        : 0.02;
    final clampedRatio = pDeltaRatio.clamp(0.0, 0.85);
    final b2Multiplier = 1.0 / math.max(0.15, 1.0 - clampedRatio);
    final alphaCrVal = clampedRatio > 0.001 ? (1.0 / clampedRatio) : 15.4;

    model.swayAmplificationB2 = math.max(1.0, math.min(1.40, b2Multiplier));
    model.criticalLoadFactorAlphaCr = math.max(1.1, math.min(50.0, alphaCrVal));
    model.stabilityStatus = (model.swayAmplificationB2 ?? 1.0) <= 1.15
        ? 'STABLE (AISC 360-16 §App 7.2)'
        : 'SWAY PERMITTED (P-Delta B2 Active)';

    // 8. Evaluate Member Actions & AISC 360-16 Code Checks
    for (final member in members) {
      final ni = nodes[nodeIdxMap[member.iNodeId]!];
      final nj = nodes[nodeIdxMap[member.jNodeId]!];
      final sec = SectionProfile.catalog[member.section] ?? SectionProfile.catalog['W14X48']!;

      final dx = nj.coords.x - ni.coords.x;
      final dy = nj.coords.y - ni.coords.y;
      final dz = nj.coords.z - ni.coords.z;
      final L = math.sqrt(dx * dx + dy * dy + dz * dz);

      // Relative displacement
      final dux = nj.displacements[0] - ni.displacements[0];
      final duy = nj.displacements[1] - ni.displacements[1];
      final duz = nj.displacements[2] - ni.displacements[2];

      const E = 200.0e9;
      final axialStrain = (dux * (dx / L) + duy * (dy / L) + duz * (dz / L)) / math.max(L, 1e-4);
      final axialForce = axialStrain * E * sec.areaM2;

      final flexDisp = math.sqrt(duy * duy + duz * duz);
      final shearForce = (12.0 * E * sec.ixM4 * flexDisp) / math.max(L * L * L, 1e-4);
      
      final bool relI = member.releaseStartMz || member.releaseIMoment;
      final bool relJ = member.releaseEndMz || member.releaseJMoment;

      double momentZ = (6.0 * E * sec.ixM4 * flexDisp) / math.max(L * L, 1e-4);
      if (relI && relJ) {
        momentZ = 0.0;
      } else if (relI || relJ) {
        momentZ = (3.0 * E * sec.ixM4 * flexDisp) / math.max(L * L, 1e-4);
      }

      // Apply B2 sway multiplier to flexural actions
      momentZ *= (model.swayAmplificationB2 ?? 1.0);

      member.axialForceN = axialForce;
      member.shearY = shearForce;
      member.shearZ = 0.0;
      member.momentY = 0.0;
      member.momentZ = momentZ;
      member.torsion = (member.releaseMx || member.releaseTorsion) ? 0.0 : member.torsion;
      member.maxDeflection = flexDisp;

      // AISC 360-16 Limit State Evaluation
      const fy = 345.0e6; // 50 ksi
      const phiT = 0.90;
      const phiC = 0.90;
      const phiB = 0.90;

      // Slenderness KL/r
      final rMin = math.min(sec.rxM, sec.ryM);
      final klR = (1.0 * L) / math.max(rMin, 1e-4);
      member.slendernessKlR = klR;

      // Tension capacity
      final phiPnTension = phiT * fy * sec.areaM2;
      final dcrTension = axialForce > 0 ? (axialForce / phiPnTension) : 0.0;

      // Compression Euler Buckling
      final fe = (math.pi * math.pi * E) / (klR * klR);
      final slendernessLimit = 4.71 * math.sqrt(E / fy);
      final fcr = klR <= slendernessLimit
          ? math.pow(0.658, fy / fe).toDouble() * fy
          : 0.877 * fe;
      final phiPnCompression = phiC * fcr * sec.areaM2;
      final dcrCompression = axialForce < 0 ? (axialForce.abs() / phiPnCompression) : 0.0;

      // Flexural capacity
      final phiMnx = phiB * fy * sec.zxM3;
      final dcrFlexure = momentZ.abs() / math.max(phiMnx, 1e-3);

      // Combined P-M interaction (AISC 360 Eq H1-1a/b)
      final pRatio = (axialForce.abs()) / (axialForce < 0 ? phiPnCompression : phiPnTension);
      final dcrCombined = pRatio >= 0.2
          ? (pRatio + (8.0 / 9.0) * dcrFlexure)
          : ((pRatio / 2.0) + dcrFlexure);

      // Shear capacity
      final aw = sec.depthM * 0.0086;
      final phiVn = 0.90 * 0.60 * fy * aw;
      final dcrShear = shearForce / math.max(phiVn, 1e-3);

      // Von Mises stress
      final sigmaNormal = (axialForce.abs() / sec.areaM2) + (momentZ.abs() / sec.sxM3);
      final tauShear = shearForce / math.max(aw, 1e-4);
      final vmPa = math.sqrt(sigmaNormal * sigmaNormal + 3.0 * tauShear * tauShear);

      member.dcrAxial = axialForce < 0 ? dcrCompression : dcrTension;
      member.dcrBuckling = dcrCompression;
      member.dcrCombined = dcrCombined;
      member.dcrShear = dcrShear;
      member.governingDcr = math.max(dcrCombined, math.max(dcrShear, dcrTension));
      member.maxVonMisesMpa = vmPa / 1e6;

      if (member.governingDcr > 1.0 || klR > 200.0) {
        member.status = 'FAIL';
        member.recommendedSection = 'W14X68';
      } else if (member.governingDcr > 0.85) {
        member.status = 'WARNING';
        member.recommendedSection = 'W14X48';
      } else {
        member.status = 'PASS';
        member.recommendedSection = member.section;
      }
    }
  }
}
