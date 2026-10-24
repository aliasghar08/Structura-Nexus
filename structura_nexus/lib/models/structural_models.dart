import 'package:vector_math/vector_math_64.dart';

enum DisplayMode {
  geometry,
  deformed,
  sfdRibbon,
  bmdRibbon,
  vonMisesStress,
  aiscCompliance,
  modalVibration,
}

enum EngineType {
  hybridDual,
  surrogateGnn,
  exactFea,
}

class SectionProfile {
  final String name;
  final double depthM;
  final double widthM;
  final double areaM2;
  final double ixM4;
  final double iyM4;
  final double rxM;
  final double ryM;
  final double zxM3;
  final double zyM3;
  final double sxM3;
  final double syM3;
  final double weightKgM;

  const SectionProfile({
    required this.name,
    required this.depthM,
    required this.widthM,
    required this.areaM2,
    required this.ixM4,
    required this.iyM4,
    required this.rxM,
    required this.ryM,
    required this.zxM3,
    required this.zyM3,
    required this.sxM3,
    required this.syM3,
    required this.weightKgM,
  });

  static const Map<String, SectionProfile> catalog = {
    'W10X33': SectionProfile(
      name: 'W10X33',
      depthM: 0.247,
      widthM: 0.202,
      areaM2: 0.00626,
      ixM4: 7.12e-5,
      iyM4: 1.52e-5,
      rxM: 0.107,
      ryM: 0.0493,
      zxM3: 6.36e-4,
      zyM3: 2.33e-4,
      sxM3: 5.75e-4,
      syM3: 1.51e-4,
      weightKgM: 49.1,
    ),
    'W12X26': SectionProfile(
      name: 'W12X26',
      depthM: 0.310,
      widthM: 0.165,
      areaM2: 0.00494,
      ixM4: 8.49e-5,
      iyM4: 7.20e-6,
      rxM: 0.131,
      ryM: 0.0381,
      zxM3: 6.01e-4,
      zyM3: 1.34e-4,
      sxM3: 5.47e-4,
      syM3: 8.72e-5,
      weightKgM: 38.7,
    ),
    'W14X22': SectionProfile(
      name: 'W14X22',
      depthM: 0.349,
      widthM: 0.127,
      areaM2: 0.00419,
      ixM4: 8.28e-5,
      iyM4: 2.91e-6,
      rxM: 0.141,
      ryM: 0.0264,
      zxM3: 5.44e-4,
      zyM3: 7.05e-5,
      sxM3: 4.75e-4,
      syM3: 4.59e-5,
      weightKgM: 32.7,
    ),
    'W14X30': SectionProfile(
      name: 'W14X30',
      depthM: 0.352,
      widthM: 0.171,
      areaM2: 0.00571,
      ixM4: 1.21e-4,
      iyM4: 8.16e-6,
      rxM: 0.146,
      ryM: 0.0378,
      zxM3: 7.87e-4,
      zyM3: 1.54e-4,
      sxM3: 6.88e-4,
      syM3: 9.54e-5,
      weightKgM: 44.6,
    ),
    'W14X38': SectionProfile(
      name: 'W14X38',
      depthM: 0.358,
      widthM: 0.172,
      areaM2: 0.00723,
      ixM4: 1.60e-4,
      iyM4: 1.11e-5,
      rxM: 0.149,
      ryM: 0.0391,
      zxM3: 1.02e-3,
      zyM3: 2.08e-4,
      sxM3: 8.95e-4,
      syM3: 1.29e-4,
      weightKgM: 56.5,
    ),
    'W14X48': SectionProfile(
      name: 'W14X48',
      depthM: 0.351,
      widthM: 0.204,
      areaM2: 0.00909,
      ixM4: 2.02e-4,
      iyM4: 2.14e-5,
      rxM: 0.149,
      ryM: 0.0485,
      zxM3: 1.29e-3,
      zyM3: 3.38e-4,
      sxM3: 1.15e-3,
      syM3: 2.10e-4,
      weightKgM: 71.4,
    ),
    'W14X68': SectionProfile(
      name: 'W14X68',
      depthM: 0.356,
      widthM: 0.255,
      areaM2: 0.0129,
      ixM4: 3.01e-4,
      iyM4: 5.04e-5,
      rxM: 0.152,
      ryM: 0.0625,
      zxM3: 1.88e-3,
      zyM3: 6.13e-4,
      sxM3: 1.69e-3,
      syM3: 3.95e-4,
      weightKgM: 101.2,
    ),
    'W14X90': SectionProfile(
      name: 'W14X90',
      depthM: 0.356,
      widthM: 0.369,
      areaM2: 0.0171,
      ixM4: 4.16e-4,
      iyM4: 1.51e-4,
      rxM: 0.156,
      ryM: 0.0940,
      zxM3: 2.57e-3,
      zyM3: 1.25e-3,
      sxM3: 2.34e-3,
      syM3: 8.18e-4,
      weightKgM: 133.9,
    ),
  };
}

class StructuralNode {
  final String id;
  Vector3 coords;
  // [Rx, Ry, Rz, Rmx, Rmy, Rmz] (1 = restrained, 0 = free)
  List<int> restraint;
  // [Fx, Fy, Fz, Mx, My, Mz] (Forces in N, Moments in N*m)
  List<double> loads;
  // Calculated results
  List<double> displacements; // [ux, uy, uz, rx, ry, rz]
  List<double> reactions; // [Rx, Ry, Rz, Rmx, Rmy, Rmz]

  StructuralNode({
    required this.id,
    required this.coords,
    List<int>? restraint,
    List<double>? loads,
    List<double>? displacements,
    List<double>? reactions,
  })  : restraint = restraint ?? [0, 0, 0, 0, 0, 0],
        loads = loads ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        displacements = displacements ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        reactions = reactions ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  bool get isFixed => restraint.every((r) => r == 1);
  bool get isPinned =>
      restraint[0] == 1 &&
      restraint[1] == 1 &&
      restraint[2] == 1 &&
      restraint[3] == 0 &&
      restraint[4] == 0 &&
      restraint[5] == 0;
  bool get isRoller =>
      restraint[1] == 1 &&
      restraint[0] == 0 &&
      restraint[2] == 0 &&
      restraint[3] == 0 &&
      restraint[4] == 0 &&
      restraint[5] == 0;
  bool get hasLoad => loads.any((l) => l.abs() > 0.01);

  Map<String, dynamic> toJson() => {
        'id': id,
        'coords': [coords.x, coords.y, coords.z],
        'restraint': restraint,
        'loads': loads,
      };

  factory StructuralNode.fromJson(Map<String, dynamic> json) {
    final c = (json['coords'] as List).map((e) => (e as num).toDouble()).toList();
    return StructuralNode(
      id: json['id'],
      coords: Vector3(c[0], c[1], c[2]),
      restraint: (json['restraint'] as List).map((e) => (e as num).toInt()).toList(),
      loads: (json['loads'] as List).map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class StructuralMember {
  final String id;
  final String iNodeId;
  final String jNodeId;
  String section;
  String material;

  // Analytical results
  double axialForceN; // + = tension, - = compression
  double shearY;
  double shearZ;
  double momentY;
  double momentZ;
  double torsion;
  double maxDeflection;
  double maxVonMisesMpa;
  double dcrAxial;
  double dcrBuckling;
  double dcrCombined;
  double dcrShear;
  double governingDcr;
  double slendernessKlR;
  String status; // PASS | FAIL | WARNING
  String? recommendedSection;

  StructuralMember({
    required this.id,
    required this.iNodeId,
    required this.jNodeId,
    this.section = 'W14X48',
    this.material = 'A992_STEEL',
    this.axialForceN = 0.0,
    this.shearY = 0.0,
    this.shearZ = 0.0,
    this.momentY = 0.0,
    this.momentZ = 0.0,
    this.torsion = 0.0,
    this.maxDeflection = 0.0,
    this.maxVonMisesMpa = 0.0,
    this.dcrAxial = 0.0,
    this.dcrBuckling = 0.0,
    this.dcrCombined = 0.0,
    this.dcrShear = 0.0,
    this.governingDcr = 0.0,
    this.slendernessKlR = 0.0,
    this.status = 'PASS',
    this.recommendedSection,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'i_node': iNodeId,
        'j_node': jNodeId,
        'section': section,
        'material': material,
      };

  factory StructuralMember.fromJson(Map<String, dynamic> json) => StructuralMember(
        id: json['id'],
        iNodeId: json['i_node'],
        jNodeId: json['j_node'],
        section: json['section'] ?? 'W14X48',
        material: json['material'] ?? 'A992_STEEL',
      );
}

class StructuralModel {
  String sessionId;
  String loadCombination;
  List<StructuralNode> nodes;
  List<StructuralMember> members;
  EngineType activeEngine;
  DisplayMode displayMode;
  double deformationScale;
  double baseShearN;
  double maxDriftRatio;
  double solverLatencyMs;
  bool isEquilibrated;
  double surrogateUncertainty;
  int activeVibrationMode;
  Map<String, Vector3> modalShapeOffsets;

  StructuralModel({
    required this.sessionId,
    this.loadCombination = '1.2D+1.6L',
    List<StructuralNode>? nodes,
    List<StructuralMember>? members,
    this.activeEngine = EngineType.hybridDual,
    this.displayMode = DisplayMode.geometry,
    this.deformationScale = 30.0,
    this.baseShearN = 0.0,
    this.maxDriftRatio = 0.0,
    this.solverLatencyMs = 0.0,
    this.isEquilibrated = true,
    this.surrogateUncertainty = 0.02,
    this.activeVibrationMode = 1,
    Map<String, Vector3>? modalShapeOffsets,
  })  : nodes = nodes ?? [],
        members = members ?? [],
        modalShapeOffsets = modalShapeOffsets ?? {};

  StructuralNode? getNode(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toGraphPayload(String action) => {
        'session_id': sessionId,
        'action': action,
        'load_combination': loadCombination,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'members': members.map((m) => m.toJson()).toList(),
      };
}

class OptimizationMetric {
  final double initialTotalWeightKg;
  final double optimizedTotalWeightKg;
  final double weightReductionKg;
  final double weightReductionPct;
  final double initialMaxDcr;
  final double optimizedMaxDcr;
  final int iterationsRun;
  final String algorithmUsed;
  final String status;

  OptimizationMetric({
    required this.initialTotalWeightKg,
    required this.optimizedTotalWeightKg,
    required this.weightReductionKg,
    required this.weightReductionPct,
    required this.initialMaxDcr,
    required this.optimizedMaxDcr,
    required this.iterationsRun,
    required this.algorithmUsed,
    required this.status,
  });

  factory OptimizationMetric.fromJson(Map<String, dynamic> json) => OptimizationMetric(
        initialTotalWeightKg: (json['initial_total_weight_kg'] as num).toDouble(),
        optimizedTotalWeightKg: (json['optimized_total_weight_kg'] as num).toDouble(),
        weightReductionKg: (json['weight_reduction_kg'] as num).toDouble(),
        weightReductionPct: (json['weight_reduction_pct'] as num).toDouble(),
        initialMaxDcr: (json['initial_max_dcr'] as num).toDouble(),
        optimizedMaxDcr: (json['optimized_max_dcr'] as num).toDouble(),
        iterationsRun: json['iterations_run'] ?? 35,
        algorithmUsed: json['algorithm_used'] ?? 'CMA-ES Optimizer',
        status: json['status'] ?? 'OPTIMIZED_COMPLIANT',
      );
}

class MemberOptimizationDetail {
  final String memberId;
  final String originalSection;
  final String optimizedSection;
  final double originalWeightKg;
  final double optimizedWeightKg;
  final double weightSavedPct;
  final double originalDcr;
  final double optimizedDcr;
  final String status;

  MemberOptimizationDetail({
    required this.memberId,
    required this.originalSection,
    required this.optimizedSection,
    required this.originalWeightKg,
    required this.optimizedWeightKg,
    required this.weightSavedPct,
    required this.originalDcr,
    required this.optimizedDcr,
    required this.status,
  });

  factory MemberOptimizationDetail.fromJson(Map<String, dynamic> json) => MemberOptimizationDetail(
        memberId: json['member_id'],
        originalSection: json['original_section'],
        optimizedSection: json['optimized_section'],
        originalWeightKg: (json['original_weight_kg'] as num).toDouble(),
        optimizedWeightKg: (json['optimized_weight_kg'] as num).toDouble(),
        weightSavedPct: (json['weight_saved_pct'] as num).toDouble(),
        originalDcr: (json['original_dcr'] as num).toDouble(),
        optimizedDcr: (json['optimized_dcr'] as num).toDouble(),
        status: json['status'] ?? 'OPTIMAL_REDUCED',
      );
}

class GenerativeOptimizationResult {
  final OptimizationMetric summary;
  final Map<String, String> optimizedSectionsMap;
  final List<MemberOptimizationDetail> memberDetails;
  final bool codeComplianceVerified;

  GenerativeOptimizationResult({
    required this.summary,
    required this.optimizedSectionsMap,
    required this.memberDetails,
    required this.codeComplianceVerified,
  });

  factory GenerativeOptimizationResult.fromJson(Map<String, dynamic> json) {
    final rawMap = json['optimized_sections_map'] as Map<String, dynamic>;
    final secMap = rawMap.map((k, v) => MapEntry(k, v.toString()));
    final details = (json['member_details'] as List)
        .map((d) => MemberOptimizationDetail.fromJson(d))
        .toList();

    return GenerativeOptimizationResult(
      summary: OptimizationMetric.fromJson(json['summary']),
      optimizedSectionsMap: secMap,
      memberDetails: details,
      codeComplianceVerified: json['code_compliance_verified'] ?? true,
    );
  }
}

class ModeShapePoint {
  final String nodeId;
  final double deltaX;
  final double deltaY;
  final double deltaZ;

  ModeShapePoint({
    required this.nodeId,
    required this.deltaX,
    required this.deltaY,
    required this.deltaZ,
  });

  factory ModeShapePoint.fromJson(Map<String, dynamic> json) => ModeShapePoint(
        nodeId: json['node_id'],
        deltaX: (json['delta_x'] as num).toDouble(),
        deltaY: (json['delta_y'] as num).toDouble(),
        deltaZ: (json['delta_z'] as num).toDouble(),
      );
}

class VibrationMode {
  final int modeNumber;
  final double periodSeconds;
  final double frequencyHz;
  final double modalMassParticipationPct;
  final String description;
  final List<ModeShapePoint> modeShapeOffsets;

  VibrationMode({
    required this.modeNumber,
    required this.periodSeconds,
    required this.frequencyHz,
    required this.modalMassParticipationPct,
    required this.description,
    required this.modeShapeOffsets,
  });

  factory VibrationMode.fromJson(Map<String, dynamic> json) => VibrationMode(
        modeNumber: json['mode_number'],
        periodSeconds: (json['period_seconds'] as num).toDouble(),
        frequencyHz: (json['frequency_hz'] as num).toDouble(),
        modalMassParticipationPct: (json['modal_mass_participation_pct'] as num).toDouble(),
        description: json['description'] ?? '',
        modeShapeOffsets: (json['mode_shape_offsets'] as List)
            .map((p) => ModeShapePoint.fromJson(p))
            .toList(),
      );
}

class SeismicAnalysisResult {
  final double fundamentalPeriodT1;
  final String seismicDesignCategory;
  final double spectralAccelerationSds;
  final double responseModificationR;
  final double importanceFactorIe;
  final double seismicResponseCoeffCs;
  final double totalEffectiveSeismicWeightKn;
  final double baseShearVBaseKn;
  final double interStoryDriftRatioPct;
  final String driftComplianceStatus;
  final List<VibrationMode> modes;

  SeismicAnalysisResult({
    required this.fundamentalPeriodT1,
    required this.seismicDesignCategory,
    required this.spectralAccelerationSds,
    required this.responseModificationR,
    required this.importanceFactorIe,
    required this.seismicResponseCoeffCs,
    required this.totalEffectiveSeismicWeightKn,
    required this.baseShearVBaseKn,
    required this.interStoryDriftRatioPct,
    required this.driftComplianceStatus,
    required this.modes,
  });

  factory SeismicAnalysisResult.fromJson(Map<String, dynamic> json) => SeismicAnalysisResult(
        fundamentalPeriodT1: (json['fundamental_period_t1'] as num).toDouble(),
        seismicDesignCategory: json['seismic_design_category'] ?? 'D',
        spectralAccelerationSds: (json['spectral_acceleration_sds'] as num).toDouble(),
        responseModificationR: (json['response_modification_r'] as num).toDouble(),
        importanceFactorIe: (json['importance_factor_ie'] as num).toDouble(),
        seismicResponseCoeffCs: (json['seismic_response_coeff_cs'] as num).toDouble(),
        totalEffectiveSeismicWeightKn:
            (json['total_effective_seismic_weight_kn'] as num).toDouble(),
        baseShearVBaseKn: (json['base_shear_v_base_kn'] as num).toDouble(),
        interStoryDriftRatioPct: (json['inter_story_drift_ratio_pct'] as num).toDouble(),
        driftComplianceStatus: json['drift_compliance_status'] ?? 'COMPLIANT',
        modes: (json['modes'] as List).map((m) => VibrationMode.fromJson(m)).toList(),
      );
}

class MemberCarbonDetail {
  final String memberId;
  final String section;
  final String material;
  final double lengthM;
  final double weightKg;
  final double standardCarbonKgCo2e;
  final double lowCarbonEafKgCo2e;
  final double carbonSavingsPotentialKgCo2e;

  MemberCarbonDetail({
    required this.memberId,
    required this.section,
    required this.material,
    required this.lengthM,
    required this.weightKg,
    required this.standardCarbonKgCo2e,
    required this.lowCarbonEafKgCo2e,
    required this.carbonSavingsPotentialKgCo2e,
  });

  factory MemberCarbonDetail.fromJson(Map<String, dynamic> json) => MemberCarbonDetail(
        memberId: json['member_id'],
        section: json['section'],
        material: json['material'],
        lengthM: (json['length_m'] as num).toDouble(),
        weightKg: (json['weight_kg'] as num).toDouble(),
        standardCarbonKgCo2e: (json['standard_carbon_kgco2e'] as num).toDouble(),
        lowCarbonEafKgCo2e: (json['low_carbon_eaf_kgco2e'] as num).toDouble(),
        carbonSavingsPotentialKgCo2e:
            (json['carbon_savings_potential_kgco2e'] as num).toDouble(),
      );
}

class EmbodiedCarbonReport {
  final double totalSteelWeightKg;
  final double baselineEmbodiedCarbonKgCo2e;
  final double optimizedLowCarbonKgCo2e;
  final double potentialCarbonReductionPct;
  final String leedCreditStatus;
  final String se2050ComplianceStatus;
  final List<MemberCarbonDetail> memberBreakdowns;
  final List<String> greenRecommendations;

  EmbodiedCarbonReport({
    required this.totalSteelWeightKg,
    required this.baselineEmbodiedCarbonKgCo2e,
    required this.optimizedLowCarbonKgCo2e,
    required this.potentialCarbonReductionPct,
    required this.leedCreditStatus,
    required this.se2050ComplianceStatus,
    required this.memberBreakdowns,
    required this.greenRecommendations,
  });

  factory EmbodiedCarbonReport.fromJson(Map<String, dynamic> json) => EmbodiedCarbonReport(
        totalSteelWeightKg: (json['total_steel_weight_kg'] as num).toDouble(),
        baselineEmbodiedCarbonKgCo2e:
            (json['baseline_embodied_carbon_kgco2e'] as num).toDouble(),
        optimizedLowCarbonKgCo2e: (json['optimized_low_carbon_kgco2e'] as num).toDouble(),
        potentialCarbonReductionPct:
            (json['potential_carbon_reduction_pct'] as num).toDouble(),
        leedCreditStatus: json['leed_credit_status'] ?? '',
        se2050ComplianceStatus: json['se2050_compliance_status'] ?? '',
        memberBreakdowns: (json['member_breakdowns'] as List)
            .map((b) => MemberCarbonDetail.fromJson(b))
            .toList(),
        greenRecommendations: List<String>.from(json['green_recommendations'] ?? []),
      );
}

class CopilotAction {
  final String actionType;
  final String description;
  final Map<String, dynamic>? suggestedModifications;

  CopilotAction({
    required this.actionType,
    required this.description,
    this.suggestedModifications,
  });

  factory CopilotAction.fromJson(Map<String, dynamic> json) => CopilotAction(
        actionType: json['action_type'],
        description: json['description'],
        suggestedModifications: json['suggested_modifications'] != null
            ? Map<String, dynamic>.from(json['suggested_modifications'])
            : null,
      );
}

class CopilotResponse {
  final String query;
  final String executiveSummary;
  final List<String> technicalInsights;
  final List<CopilotAction> actions;
  final List<String> suggestedPrompts;

  CopilotResponse({
    required this.query,
    required this.executiveSummary,
    required this.technicalInsights,
    required this.actions,
    required this.suggestedPrompts,
  });

  factory CopilotResponse.fromJson(Map<String, dynamic> json) => CopilotResponse(
        query: json['query'],
        executiveSummary: json['executive_summary'],
        technicalInsights: List<String>.from(json['technical_insights'] ?? []),
        actions: (json['actions'] as List).map((a) => CopilotAction.fromJson(a)).toList(),
        suggestedPrompts: List<String>.from(json['suggested_prompts'] ?? []),
      );
}

