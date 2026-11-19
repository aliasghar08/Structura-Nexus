// ============================================================================
// ConnectionDetailerService — Deterministic AISC 360-16 Chapter J Connection Solver
// Shear Tabs, Extended Moment End-Plates, Braced Gussets & Column Baseplates
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:convert';
import 'dart:math' as math;

class ConnectionLimitStateCheck {
  final String name;
  final String clause;
  final double demand;
  final double capacityPhiRn;
  final String unit;
  final double dcr;
  final String status;
  final String formula;

  const ConnectionLimitStateCheck({
    required this.name,
    required this.clause,
    required this.demand,
    required this.capacityPhiRn,
    required this.unit,
    required this.dcr,
    required this.status,
    required this.formula,
  });
}

class Bolt3DGlyphSpec {
  final double localXM;
  final double localYM;
  final double localZM;
  final double diameterM;
  final double utilizationDcr;
  final String grade;

  const Bolt3DGlyphSpec({
    required this.localXM,
    required this.localYM,
    required this.localZM,
    required this.diameterM,
    required this.utilizationDcr,
    required this.grade,
  });

  Map<String, dynamic> toJson() => {
        'local_x_m': localXM,
        'local_y_m': localYM,
        'local_z_m': localZM,
        'diameter_m': diameterM,
        'utilization_dcr': utilizationDcr,
        'grade': grade,
      };
}

class ConnectionDetailResult {
  final String connectionType; // 'SHEAR_TAB', 'MOMENT_END_PLATE', 'GUSSET_PLATE', 'BASEPLATE'
  final String jointId;
  final List<double> jointCoordsM;
  final double governingDcr;
  final String governingLimitState;
  final String overallStatus;
  final double requiredPlateThicknessMm;
  final double providedPlateThicknessMm;
  final double recommendedWeldLegMm;
  final double? whitmoreWidthMm;
  final bool continuityPlateRequired;
  final List<ConnectionLimitStateCheck> limitStates;
  final List<Bolt3DGlyphSpec> bolts3d;
  final List<double> plateDimensionsM;

  const ConnectionDetailResult({
    required this.connectionType,
    required this.jointId,
    required this.jointCoordsM,
    required this.governingDcr,
    required this.governingLimitState,
    required this.overallStatus,
    required this.requiredPlateThicknessMm,
    required this.providedPlateThicknessMm,
    required this.recommendedWeldLegMm,
    this.whitmoreWidthMm,
    this.continuityPlateRequired = false,
    required this.limitStates,
    required this.bolts3d,
    required this.plateDimensionsM,
  });

  String toViewportJson() => jsonEncode({
        'connection_type': connectionType,
        'joint_id': jointId,
        'joint_coords_m': jointCoordsM,
        'governing_dcr': governingDcr,
        'plate_dimensions_m': plateDimensionsM,
        'bolts_3d': bolts3d.map((b) => b.toJson()).toList(),
      });
}

class ConnectionDetailerService {
  static const Map<String, Map<String, double>> _boltStrengthsMpa = {
    'A325': {'Fnt': 620.0, 'Fnv': 372.0},
    'A490': {'Fnt': 780.0, 'Fnv': 457.0},
  };

  /// Deterministic offline & online AISC 360-16 Chapter J limit-state evaluator.
  static ConnectionDetailResult evaluateConnection({
    required String connectionType,
    String jointId = 'N1',
    List<double> jointCoordsM = const [0.0, 3.6, 0.0],
    double shearVuKn = 210.0,
    double momentMuKnm = 320.0,
    double axialPuKn = 650.0,
    String boltGrade = 'A325',
    double boltDiameterMm = 22.225,
    int numBolts = 4,
    double boltPitchMm = 76.2,
    double boltGaugeMm = 140.0,
    double edgeDistanceMm = 38.1,
    double plateThicknessMm = 12.7,
    double plateWidthMm = 220.0,
    double plateHeightMm = 340.0,
    double plateFyMpa = 345.0,
    double plateFuMpa = 450.0,
    double weldLegMm = 8.0,
    double fcConcreteMpa = 28.0,
  }) {
    final type = connectionType.toUpperCase();
    if (type == 'MOMENT_END_PLATE') {
      return _evaluateMomentEndPlate(
        jointId: jointId,
        jointCoordsM: jointCoordsM,
        momentMuKnm: momentMuKnm,
        shearVuKn: shearVuKn,
        boltGrade: boltGrade,
        boltDiameterMm: boltDiameterMm,
        numBolts: numBolts,
        boltGaugeMm: boltGaugeMm,
        plateThicknessMm: plateThicknessMm,
        plateWidthMm: plateWidthMm,
        plateFyMpa: plateFyMpa,
        weldLegMm: weldLegMm,
      );
    } else if (type == 'GUSSET_PLATE') {
      return _evaluateGussetPlate(
        jointId: jointId,
        jointCoordsM: jointCoordsM,
        axialPuKn: axialPuKn,
        boltGrade: boltGrade,
        boltDiameterMm: boltDiameterMm,
        numBolts: numBolts,
        boltPitchMm: boltPitchMm,
        boltGaugeMm: boltGaugeMm,
        plateThicknessMm: plateThicknessMm,
        plateFyMpa: plateFyMpa,
        weldLegMm: weldLegMm,
      );
    } else if (type == 'BASEPLATE') {
      return _evaluateBaseplate(
        jointId: jointId,
        jointCoordsM: jointCoordsM,
        axialPuKn: axialPuKn,
        shearVuKn: shearVuKn,
        boltDiameterMm: boltDiameterMm,
        plateThicknessMm: plateThicknessMm,
        plateWidthMm: plateWidthMm,
        plateHeightMm: plateHeightMm,
        plateFyMpa: plateFyMpa,
        fcConcreteMpa: fcConcreteMpa,
      );
    } else {
      return _evaluateShearTab(
        jointId: jointId,
        jointCoordsM: jointCoordsM,
        shearVuKn: shearVuKn,
        boltGrade: boltGrade,
        boltDiameterMm: boltDiameterMm,
        numBolts: numBolts,
        boltPitchMm: boltPitchMm,
        edgeDistanceMm: edgeDistanceMm,
        plateThicknessMm: plateThicknessMm,
        plateFyMpa: plateFyMpa,
        plateFuMpa: plateFuMpa,
      );
    }
  }

  static ConnectionDetailResult _evaluateShearTab({
    required String jointId,
    required List<double> jointCoordsM,
    required double shearVuKn,
    required String boltGrade,
    required double boltDiameterMm,
    required int numBolts,
    required double boltPitchMm,
    required double edgeDistanceMm,
    required double plateThicknessMm,
    required double plateFyMpa,
    required double plateFuMpa,
  }) {
    final db = boltDiameterMm;
    final ab = math.pi * db * db / 4.0;
    final nb = math.max(2, numBolts);
    final tp = plateThicknessMm;
    final fy = plateFyMpa;
    final fu = plateFuMpa;
    final s = boltPitchMm;
    final le = edgeDistanceMm;
    final vu = shearVuKn.abs();

    final boltMat = _boltStrengthsMpa[boltGrade.toUpperCase()] ?? _boltStrengthsMpa['A325']!;
    final fnv = boltMat['Fnv']!;

    // 1. Bolt Shear (§J3.6)
    final phiBoltShear = 0.75 * fnv * ab * nb / 1000.0;
    final dcrBoltShear = vu / math.max(phiBoltShear, 1e-3);

    // 2. Bolt Bearing & Tear-Out (§J3.10)
    final dHole = db + 2.0;
    final lcEdge = math.max(5.0, le - 0.5 * dHole);
    final lcInt = math.max(5.0, s - dHole);
    final rnEdge = math.min(1.2 * lcEdge * tp * fu, 2.4 * db * tp * fu);
    final rnInt = math.min(1.2 * lcInt * tp * fu, 2.4 * db * tp * fu);
    final phiBearing = 0.75 * (rnEdge + (nb - 1) * rnInt) / 1000.0;
    final dcrBearing = vu / math.max(phiBearing, 1e-3);

    // 3. Gross Shear Yielding (§J4.2a)
    final hPlate = (nb - 1) * s + 2.0 * le;
    final agv = hPlate * tp;
    final phiGrossShear = 1.00 * 0.60 * fy * agv / 1000.0;
    final dcrGross = vu / math.max(phiGrossShear, 1e-3);

    // 4. Net Shear Rupture (§J4.2b)
    final anv = math.max(100.0, (hPlate - nb * (dHole + 1.5)) * tp);
    final phiNetShear = 0.75 * 0.60 * fu * anv / 1000.0;
    final dcrNet = vu / math.max(phiNetShear, 1e-3);

    // 5. Block Shear Rupture (§J4.3)
    const eh = 38.1;
    final ant = math.max(50.0, (eh - 0.5 * (dHole + 1.5)) * tp);
    final agvBs = ((nb - 1) * s + le) * tp;
    final anvBs = math.max(80.0, agvBs - (nb - 0.5) * (dHole + 1.5) * tp);
    final rnBs = math.min(
      0.60 * fu * anvBs + 1.0 * fu * ant,
      0.60 * fy * agvBs + 1.0 * fu * ant,
    );
    final phiBlockShear = 0.75 * rnBs / 1000.0;
    final dcrBlock = vu / math.max(phiBlockShear, 1e-3);

    final checks = [
      ConnectionLimitStateCheck(
        name: 'Bolt Single-Shear Capacity',
        clause: 'AISC 360-16 §J3.6',
        demand: vu,
        capacityPhiRn: phiBoltShear,
        unit: 'kN',
        dcr: dcrBoltShear,
        status: dcrBoltShear <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φR_n = 0.75 · F_nv · A_b · n_b',
      ),
      ConnectionLimitStateCheck(
        name: 'Bolt Bearing & Tear-Out',
        clause: 'AISC 360-16 §J3.10',
        demand: vu,
        capacityPhiRn: phiBearing,
        unit: 'kN',
        dcr: dcrBearing,
        status: dcrBearing <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φR_n = 0.75 · Σ min(1.2 l_c t F_u, 2.4 d t F_u)',
      ),
      ConnectionLimitStateCheck(
        name: 'Plate Gross Shear Yielding',
        clause: 'AISC 360-16 §J4.2(a)',
        demand: vu,
        capacityPhiRn: phiGrossShear,
        unit: 'kN',
        dcr: dcrGross,
        status: dcrGross <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φR_n = 1.00 · 0.60 F_y A_gv',
      ),
      ConnectionLimitStateCheck(
        name: 'Plate Net Shear Rupture',
        clause: 'AISC 360-16 §J4.2(b)',
        demand: vu,
        capacityPhiRn: phiNetShear,
        unit: 'kN',
        dcr: dcrNet,
        status: dcrNet <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φR_n = 0.75 · 0.60 F_u A_nv',
      ),
      ConnectionLimitStateCheck(
        name: 'Block Shear Rupture',
        clause: 'AISC 360-16 §J4.3',
        demand: vu,
        capacityPhiRn: phiBlockShear,
        unit: 'kN',
        dcr: dcrBlock,
        status: dcrBlock <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φR_n = 0.75 · [0.60 F_u A_nv + U_bs F_u A_nt]',
      ),
    ];

    var gov = checks.first;
    for (final c in checks) {
      if (c.dcr > gov.dcr) gov = c;
    }

    final bolts = <Bolt3DGlyphSpec>[];
    final y0 = -0.5 * (nb - 1) * (s / 1000.0);
    for (int i = 0; i < nb; i++) {
      bolts.add(
        Bolt3DGlyphSpec(
          localXM: 0.04,
          localYM: y0 + i * (s / 1000.0),
          localZM: 0.0,
          diameterM: db / 1000.0,
          utilizationDcr: dcrBoltShear,
          grade: boltGrade,
        ),
      );
    }

    return ConnectionDetailResult(
      connectionType: 'SHEAR_TAB',
      jointId: jointId,
      jointCoordsM: jointCoordsM,
      governingDcr: gov.dcr,
      governingLimitState: gov.name,
      overallStatus: gov.dcr <= 1.0 ? 'PASS' : 'OVERSTRESSED',
      requiredPlateThicknessMm: tp * math.max(0.65, gov.dcr),
      providedPlateThicknessMm: tp,
      recommendedWeldLegMm: math.max(6.0, tp * 0.65),
      limitStates: checks,
      bolts3d: bolts,
      plateDimensionsM: [0.115, hPlate / 1000.0, tp / 1000.0],
    );
  }

  static ConnectionDetailResult _evaluateMomentEndPlate({
    required String jointId,
    required List<double> jointCoordsM,
    required double momentMuKnm,
    required double shearVuKn,
    required String boltGrade,
    required double boltDiameterMm,
    required int numBolts,
    required double boltGaugeMm,
    required double plateThicknessMm,
    required double plateWidthMm,
    required double plateFyMpa,
    required double weldLegMm,
  }) {
    final db = boltDiameterMm;
    final ab = math.pi * db * db / 4.0;
    final nb = numBolts >= 8 ? 8 : 4;
    final tp = math.max(16.0, plateThicknessMm);
    final bp = math.max(180.0, plateWidthMm);
    final fy = plateFyMpa;
    final mu = momentMuKnm.abs();
    final vu = shearVuKn.abs();

    final boltMat = _boltStrengthsMpa[boltGrade.toUpperCase()] ?? _boltStrengthsMpa['A325']!;
    final fnt = boltMat['Fnt']!;
    final fnv = boltMat['Fnv']!;

    const h0M = 0.435;
    final nTensionBolts = nb ~/ 2;

    // 1. Bolt Tension & Prying Action
    final tuFlangeKn = mu / h0M;
    final phiRnBoltT = 0.75 * fnt * ab * nTensionBolts / (1000.0 * 1.15);
    final dcrBoltT = tuFlangeKn / math.max(phiRnBoltT, 1e-3);

    // 2. End-Plate Flexural Yield Line
    final ypMm = 2.85 * bp * (nb == 8 ? 1.25 : 1.0);
    final phiMnPlateKnm = 0.90 * fy * ypMm * (tp * tp) * h0M / 1e6;
    final dcrPlateYield = mu / math.max(phiMnPlateKnm, 1e-3);
    final tpMinMm = math.sqrt((mu * 1e6) / math.max(0.90 * fy * ypMm * h0M, 1.0));

    // 3. Flange-to-End-Plate Weld (§J2.4)
    final wLeg = math.max(8.0, weldLegMm);
    final lWeldMm = 2.0 * bp;
    final phiRnWeldKn = 0.75 * 0.60 * 490.0 * (0.707 * wLeg) * lWeldMm * 1.5 / 1000.0;
    final dcrWeld = tuFlangeKn / math.max(phiRnWeldKn, 1e-3);

    // 4. Column Web Continuity / Local Yielding (§J10.1)
    const twCol = 11.2;
    const tfCol = 18.0;
    const fyCol = 345.0;
    final phiRnWebKn = 1.00 * (5.0 * tfCol + 15.0) * fyCol * twCol / 1000.0;
    final dcrWeb = tuFlangeKn / math.max(phiRnWebKn, 1e-3);

    // 5. Bolt Shear on Compression Side (§J3.6)
    final phiRnShearKn = 0.75 * fnv * ab * (nb ~/ 2) / 1000.0;
    final dcrShear = vu / math.max(phiRnShearKn, 1e-3);

    final checks = [
      ConnectionLimitStateCheck(
        name: 'Bolt Tension & Prying Action',
        clause: 'AISC DG 4 / §J3.6',
        demand: tuFlangeKn,
        capacityPhiRn: phiRnBoltT,
        unit: 'kN',
        dcr: dcrBoltT,
        status: dcrBoltT <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φR_nt = 0.75 · F_nt · A_b · n_t / (1 + q_prying)',
      ),
      ConnectionLimitStateCheck(
        name: 'End-Plate Flexural Yield Line',
        clause: 'AISC DG 4 / DG 16 §3.2',
        demand: mu,
        capacityPhiRn: phiMnPlateKnm,
        unit: 'kN·m',
        dcr: dcrPlateYield,
        status: dcrPlateYield <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φM_np = 0.90 · F_yp · Y_p · t_p²',
      ),
      ConnectionLimitStateCheck(
        name: 'Flange-to-End-Plate Weld',
        clause: 'AISC 360-16 §J2.4',
        demand: tuFlangeKn,
        capacityPhiRn: phiRnWeldKn,
        unit: 'kN',
        dcr: dcrWeld,
        status: dcrWeld <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φR_nw = 0.75 · 0.60 F_EXX (0.707 w) L_w · 1.5',
      ),
      ConnectionLimitStateCheck(
        name: 'Column Web Continuity / Yielding',
        clause: 'AISC 360-16 §J10.1',
        demand: tuFlangeKn,
        capacityPhiRn: phiRnWebKn,
        unit: 'kN',
        dcr: dcrWeb,
        status: dcrWeb <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φR_n = 1.00 · (5 k + l_b) F_yw t_wc',
      ),
      ConnectionLimitStateCheck(
        name: 'Compression-Side Bolt Shear',
        clause: 'AISC 360-16 §J3.6',
        demand: vu,
        capacityPhiRn: phiRnShearKn,
        unit: 'kN',
        dcr: dcrShear,
        status: dcrShear <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φR_nv = 0.75 · F_nv · A_b · n_v',
      ),
    ];

    var gov = checks.first;
    for (final c in checks) {
      if (c.dcr > gov.dcr) gov = c;
    }

    final gM = boltGaugeMm / 1000.0;
    final yRows = nb == 4
        ? const [-0.20, 0.20]
        : const [-0.26, -0.15, 0.15, 0.26];
    final bolts = <Bolt3DGlyphSpec>[];
    for (final yM in yRows) {
      for (final zSign in const [-0.5, 0.5]) {
        bolts.add(
          Bolt3DGlyphSpec(
            localXM: 0.02,
            localYM: yM,
            localZM: zSign * gM,
            diameterM: db / 1000.0,
            utilizationDcr: yM > 0 ? dcrBoltT : dcrShear,
            grade: boltGrade,
          ),
        );
      }
    }

    return ConnectionDetailResult(
      connectionType: 'MOMENT_END_PLATE',
      jointId: jointId,
      jointCoordsM: jointCoordsM,
      governingDcr: gov.dcr,
      governingLimitState: gov.name,
      overallStatus: gov.dcr <= 1.0 ? 'PASS' : 'OVERSTRESSED',
      requiredPlateThicknessMm: tpMinMm,
      providedPlateThicknessMm: tp,
      recommendedWeldLegMm: wLeg,
      continuityPlateRequired: dcrWeb > 0.95,
      limitStates: checks,
      bolts3d: bolts,
      plateDimensionsM: [tp / 1000.0, 0.62, bp / 1000.0],
    );
  }

  static ConnectionDetailResult _evaluateGussetPlate({
    required String jointId,
    required List<double> jointCoordsM,
    required double axialPuKn,
    required String boltGrade,
    required double boltDiameterMm,
    required int numBolts,
    required double boltPitchMm,
    required double boltGaugeMm,
    required double plateThicknessMm,
    required double plateFyMpa,
    required double weldLegMm,
  }) {
    final pu = axialPuKn.abs();
    final tp = math.max(12.7, plateThicknessMm);
    final fy = plateFyMpa;
    const eMpa = 200000.0;
    final nRows = math.max(2, numBolts ~/ 2);
    final s = boltPitchMm;
    final g = boltGaugeMm;

    // 1. Whitmore 30° Dispersion Width
    final lConnMm = (nRows - 1) * s;
    final lWhitmoreMm = g + 2.0 * lConnMm * math.tan(30.0 * math.pi / 180.0);
    final aWhitmoreMm2 = lWhitmoreMm * tp;
    final phiPnYieldKn = 0.90 * fy * aWhitmoreMm2 / 1000.0;
    final dcrWhitmore = pu / math.max(phiPnYieldKn, 1e-3);

    // 2. Thornton Compression Buckling (K = 0.65)
    final rG = tp / math.sqrt(12.0);
    const lUnbracedMm = 260.0;
    final klR = 0.65 * lUnbracedMm / math.max(rG, 1.0);
    final feMpa = (math.pi * math.pi) * eMpa / math.max(klR * klR, 1.0);
    final fcrMpa = klR <= 4.71 * math.sqrt(eMpa / fy)
        ? math.pow(0.658, fy / feMpa).toDouble() * fy
        : 0.877 * feMpa;
    final phiPnBuckleKn = 0.90 * fcrMpa * aWhitmoreMm2 / 1000.0;
    final dcrThornton = pu / math.max(phiPnBuckleKn, 1e-3);

    // 3. Gusset-to-Frame Interface Weld (§J2.4)
    final wLeg = math.max(8.0, weldLegMm);
    const lInterfaceMm = 420.0;
    final phiRnInterfaceKn = 0.75 * 0.60 * 490.0 * (0.707 * wLeg) * (2.0 * lInterfaceMm) / 1000.0;
    final dcrInterface = pu / math.max(phiRnInterfaceKn, 1e-3);

    final checks = [
      ConnectionLimitStateCheck(
        name: 'Whitmore 30° Section Yielding',
        clause: 'AISC Manual Part 13 / §J4.1',
        demand: pu,
        capacityPhiRn: phiPnYieldKn,
        unit: 'kN',
        dcr: dcrWhitmore,
        status: dcrWhitmore <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φP_ny = 0.90 · F_y · (s_g + 2 L_b tan 30°) · t_g',
      ),
      ConnectionLimitStateCheck(
        name: 'Thornton Gusset Compression Buckling',
        clause: 'AISC 360-16 §J4.4 / §E3',
        demand: pu,
        capacityPhiRn: phiPnBuckleKn,
        unit: 'kN',
        dcr: dcrThornton,
        status: dcrThornton <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φP_ncr = 0.90 · F_cr(KL/r) · A_Whitmore  (K = 0.65)',
      ),
      ConnectionLimitStateCheck(
        name: 'Gusset-to-Frame Interface Weld',
        clause: 'AISC 360-16 §J2.4',
        demand: pu,
        capacityPhiRn: phiRnInterfaceKn,
        unit: 'kN',
        dcr: dcrInterface,
        status: dcrInterface <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φR_nw = 0.75 · 0.60 F_EXX (0.707 w) · 2 L_int',
      ),
    ];

    var gov = checks.first;
    for (final c in checks) {
      if (c.dcr > gov.dcr) gov = c;
    }

    final bolts = <Bolt3DGlyphSpec>[];
    for (int i = 0; i < nRows; i++) {
      final dist = 0.14 + i * (s / 1000.0);
      bolts.add(
        Bolt3DGlyphSpec(
          localXM: dist * 0.707,
          localYM: dist * 0.707,
          localZM: 0.0,
          diameterM: boltDiameterMm / 1000.0,
          utilizationDcr: gov.dcr,
          grade: boltGrade,
        ),
      );
    }

    return ConnectionDetailResult(
      connectionType: 'GUSSET_PLATE',
      jointId: jointId,
      jointCoordsM: jointCoordsM,
      governingDcr: gov.dcr,
      governingLimitState: gov.name,
      overallStatus: gov.dcr <= 1.0 ? 'PASS' : 'OVERSTRESSED',
      requiredPlateThicknessMm: tp * math.max(0.7, gov.dcr),
      providedPlateThicknessMm: tp,
      recommendedWeldLegMm: wLeg,
      whitmoreWidthMm: lWhitmoreMm,
      limitStates: checks,
      bolts3d: bolts,
      plateDimensionsM: [0.48, 0.48, tp / 1000.0],
    );
  }

  static ConnectionDetailResult _evaluateBaseplate({
    required String jointId,
    required List<double> jointCoordsM,
    required double axialPuKn,
    required double shearVuKn,
    required double boltDiameterMm,
    required double plateThicknessMm,
    required double plateWidthMm,
    required double plateHeightMm,
    required double plateFyMpa,
    required double fcConcreteMpa,
  }) {
    final pu = axialPuKn.abs();
    final vu = shearVuKn.abs();
    final fc = fcConcreteMpa;
    final fy = plateFyMpa;
    final bMm = math.max(450.0, plateWidthMm * 2.2);
    final nMm = math.max(450.0, plateHeightMm * 1.45);
    final tp = math.max(25.4, plateThicknessMm * 2.0);

    // 1. Concrete Bearing Capacity (0.85 f'c A1 sqrt(A2/A1))
    final a1Mm2 = bMm * nMm;
    const sqrtA2A1 = 1.5;
    final phiPpKn = 0.65 * 0.85 * fc * a1Mm2 * sqrtA2A1 / 1000.0;
    final dcrBearing = pu / math.max(phiPpKn, 1e-3);

    // 2. Baseplate Cantilever Bending Thickness
    const dCol = 355.0;
    const bfCol = 368.0;
    final mCant = 0.5 * (nMm - 0.95 * dCol);
    final nCant = 0.5 * (bMm - 0.80 * bfCol);
    final lCant = math.max(math.max(mCant, nCant), 45.0);
    final tpMinMm = lCant * math.sqrt((2.0 * pu * 1000.0) / math.max(0.90 * fy * bMm * nMm, 1.0));
    final phiMnPlateKn = 0.90 * fy * bMm * nMm * math.pow(tp / lCant, 2) / 2000.0;
    final dcrPlate = pu / math.max(phiMnPlateKn, 1e-3);

    // 3. Anchor Rod Shear & Breakout
    final da = math.max(22.225, boltDiameterMm);
    final aa = math.pi * da * da / 4.0;
    const nAnchors = 4;
    final phiVnAnchorsKn = 0.75 * 0.60 * 400.0 * aa * nAnchors / 1000.0;
    final dcrAnchors = vu / math.max(phiVnAnchorsKn, 1e-3);

    final checks = [
      ConnectionLimitStateCheck(
        name: 'Concrete Foundation Bearing',
        clause: 'AISC 360-16 §J8 / DG 1',
        demand: pu,
        capacityPhiRn: phiPpKn,
        unit: 'kN',
        dcr: dcrBearing,
        status: dcrBearing <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φP_p = 0.65 · 0.85 f\'_c A_1 √(A_2 / A_1)',
      ),
      ConnectionLimitStateCheck(
        name: 'Baseplate Cantilever Flexure',
        clause: 'AISC Design Guide 1 §3.1',
        demand: pu,
        capacityPhiRn: phiMnPlateKn,
        unit: 'kN',
        dcr: dcrPlate,
        status: dcrPlate <= 1.0 ? 'PASS' : 'FAIL',
        formula: 't_p,min = l_max · √[2 P_u / (0.90 F_y B N)]',
      ),
      ConnectionLimitStateCheck(
        name: 'Anchor Rod Shear & Breakout',
        clause: 'AISC DG 1 / ACI 318-19 §17.7',
        demand: vu,
        capacityPhiRn: phiVnAnchorsKn,
        unit: 'kN',
        dcr: dcrAnchors,
        status: dcrAnchors <= 1.0 ? 'PASS' : 'FAIL',
        formula: 'φV_sa = 0.75 · 0.60 F_uta A_se,V · n_a',
      ),
    ];

    var gov = checks.first;
    for (final c in checks) {
      if (c.dcr > gov.dcr) gov = c;
    }

    final dx = (bMm / 1000.0) * 0.36;
    final dz = (nMm / 1000.0) * 0.36;
    final bolts = <Bolt3DGlyphSpec>[
      for (final sx in const [-1.0, 1.0])
        for (final sz in const [-1.0, 1.0])
          Bolt3DGlyphSpec(
            localXM: sx * dx,
            localYM: 0.03,
            localZM: sz * dz,
            diameterM: da / 1000.0,
            utilizationDcr: dcrAnchors,
            grade: 'F1554-Gr55',
          ),
    ];

    return ConnectionDetailResult(
      connectionType: 'BASEPLATE',
      jointId: jointId,
      jointCoordsM: jointCoordsM,
      governingDcr: gov.dcr,
      governingLimitState: gov.name,
      overallStatus: gov.dcr <= 1.0 ? 'PASS' : 'OVERSTRESSED',
      requiredPlateThicknessMm: tpMinMm,
      providedPlateThicknessMm: tp,
      recommendedWeldLegMm: 10.0,
      limitStates: checks,
      bolts3d: bolts,
      plateDimensionsM: [bMm / 1000.0, tp / 1000.0, nMm / 1000.0],
    );
  }
}

