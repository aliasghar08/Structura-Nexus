import 'package:vector_math/vector_math_64.dart';

enum DisplayMode {
  geometry,
  deformed,
  sfdRibbon,
  bmdRibbon,
  vonMisesStress,
  aiscCompliance,
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
  })  : nodes = nodes ?? [],
        members = members ?? [];

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
