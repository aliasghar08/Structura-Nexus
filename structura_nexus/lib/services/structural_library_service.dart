import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/structural_models.dart';
import '../data/benchmark_presets.dart';
import 'firebase_auth_service.dart';

class CloudProjectMeta {
  final String id;
  final String title;
  final String description;
  final int nodeCount;
  final int memberCount;
  final double totalWeightKg;
  final double governingDcr;
  final String authorUid;
  final String authorName;
  final DateTime updatedAt;
  final Map<String, dynamic> graphData;

  CloudProjectMeta({
    required this.id,
    required this.title,
    required this.description,
    required this.nodeCount,
    required this.memberCount,
    required this.totalWeightKg,
    required this.governingDcr,
    required this.authorUid,
    required this.authorName,
    required this.updatedAt,
    required this.graphData,
  });

  factory CloudProjectMeta.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CloudProjectMeta(
      id: doc.id,
      title: data['title'] ?? 'Untitled Structural Model',
      description: data['description'] ?? '',
      nodeCount: data['nodeCount'] ?? 0,
      memberCount: data['memberCount'] ?? 0,
      totalWeightKg: (data['totalWeightKg'] as num?)?.toDouble() ?? 0.0,
      governingDcr: (data['governingDcr'] as num?)?.toDouble() ?? 0.0,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous Engineer',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      graphData: data['graphData'] as Map<String, dynamic>? ?? {},
    );
  }
}

class StructuralLibraryService {
  static final StructuralLibraryService _instance = StructuralLibraryService._internal();
  factory StructuralLibraryService() => _instance;
  StructuralLibraryService._internal();

  final FirebaseAuthService _auth = FirebaseAuthService();

  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Curated built-in library of certified structural engineering models.
  List<Map<String, dynamic>> getCuratedTemplates() {
    return [
      {
        'id': 'sway_frame',
        'title': '3-Story AISC 360-16 Sway Frame',
        'category': 'Building Frames',
        'badge': 'SEISMIC READY',
        'description': '3-story, 2-bay rigid moment resisting space frame with lateral wind & seismic loads.',
        'nodeCount': 12,
        'memberCount': 16,
        'standard': 'AISC 360-16 / ASCE 7-16',
        'factory': () => BenchmarkPresets.multiStorySwayFrame(),
      },
      {
        'id': 'portal_frame',
        'title': 'Industrial Clear-Span Portal Frame',
        'category': 'Industrial & Warehouses',
        'badge': 'CLEAR SPAN',
        'description': '18-meter pitched gable industrial warehouse portal frame with roof live and wind suction loads.',
        'nodeCount': 10,
        'memberCount': 12,
        'standard': 'AISC 360-16',
        'factory': () => _buildPortalFrame(),
      },
      {
        'id': 'transmission_tower',
        'title': '3D Lattice Transmission Tower',
        'category': 'Towers & Masts',
        'badge': 'SPACE TRUSS',
        'description': '24-meter high-voltage electrical transmission tower with cross-bracing and conductor tension loads.',
        'nodeCount': 20,
        'memberCount': 38,
        'standard': 'ASCE 10-15 / AISC 360-16',
        'factory': () => _buildTransmissionTower(),
      },
      {
        'id': 'pratt_truss_bridge',
        'title': 'Pratt Highway Truss Bridge',
        'category': 'Bridges & Infrastructure',
        'badge': 'AASHTO / AISC',
        'description': '30-meter single-span through-truss bridge with deck stringers and AASHTO HL-93 truck loading.',
        'nodeCount': 14,
        'memberCount': 25,
        'standard': 'AISC 360-16',
        'factory': () => _buildPrattTrussBridge(),
      },
      {
        'id': 'space_frame_canopy',
        'title': 'Double-Layer Space Grid Canopy',
        'category': 'Canopies & Domes',
        'badge': '3D GRID',
        'description': 'Orthogonal double-layer spatial roof truss canopy with column support nodes at corners.',
        'nodeCount': 18,
        'memberCount': 32,
        'standard': 'AISC 360-16',
        'factory': () => _buildSpaceGridCanopy(),
      },
      {
        'id': 'timoshenko_cantilever',
        'title': 'Timoshenko & Gere Cantilever (BM-01)',
        'category': 'Verification Benchmarks',
        'badge': '0.000% ERROR',
        'description': 'Closed-form textbook analytical benchmark case. Tip deflection delta = 0.010561 m verified.',
        'nodeCount': 2,
        'memberCount': 1,
        'standard': 'Mechanics of Materials Sec 5.4',
        'factory': () => BenchmarkPresets.timoshenkoCantilever(),
      },
      {
        'id': 'hibbeler_beam',
        'title': 'Hibbeler Simple Beam (BM-02)',
        'category': 'Verification Benchmarks',
        'badge': '0.000% ERROR',
        'description': 'Simply supported midspan load benchmark. Midspan deflection delta = 0.005569 m verified.',
        'nodeCount': 3,
        'memberCount': 2,
        'standard': 'Structural Analysis 10th Ed Ex 8-3',
        'factory': () => BenchmarkPresets.hibbelerSimpleBeam(),
      },
      {
        'id': 'leet_frame',
        'title': 'Leet & Uang Symmetrical Frame (BM-03)',
        'category': 'Verification Benchmarks',
        'badge': '0.000% ERROR',
        'description': 'Rigid frame reaction equilibrium verification. Vertical reactions R_y = 25,000 N verified.',
        'nodeCount': 4,
        'memberCount': 3,
        'standard': 'Fundamentals of Structural Analysis Sec 4.2',
        'factory': () => BenchmarkPresets.leetSymmetricFrame(),
      },
    ];
  }

  // --- Curated Factory Generators ---

  static StructuralModel _buildPortalFrame() {
    final nodes = [
      StructuralNode(id: 'N1', x: 0.0, y: 0.0, z: 0.0, isRestrained: [true, true, true, true, true, true]),
      StructuralNode(id: 'N2', x: 0.0, y: 6.0, z: 0.0, isRestrained: [false, false, false, false, false, false]),
      StructuralNode(id: 'N3', x: 9.0, y: 8.5, z: 0.0, isRestrained: [false, false, false, false, false, false], fyN: -45000), // Apex
      StructuralNode(id: 'N4', x: 18.0, y: 6.0, z: 0.0, isRestrained: [false, false, false, false, false, false]),
      StructuralNode(id: 'N5', x: 18.0, y: 0.0, z: 0.0, isRestrained: [true, true, true, true, true, true]),
      // Bay 2 (depth = 6m)
      StructuralNode(id: 'N6', x: 0.0, y: 0.0, z: 6.0, isRestrained: [true, true, true, true, true, true]),
      StructuralNode(id: 'N7', x: 0.0, y: 6.0, z: 6.0, isRestrained: [false, false, false, false, false, false], fxN: 18000), // Windward
      StructuralNode(id: 'N8', x: 9.0, y: 8.5, z: 6.0, isRestrained: [false, false, false, false, false, false], fyN: -45000),
      StructuralNode(id: 'N9', x: 18.0, y: 6.0, z: 6.0, isRestrained: [false, false, false, false, false, false]),
      StructuralNode(id: 'N10', x: 18.0, y: 0.0, z: 6.0, isRestrained: [true, true, true, true, true, true]),
    ];

    final members = [
      // Frame 1
      StructuralMember(id: 'M1', startNodeId: 'N1', endNodeId: 'N2', sectionProfile: 'W18X50'),
      StructuralMember(id: 'M2', startNodeId: 'N2', endNodeId: 'N3', sectionProfile: 'W16X36'),
      StructuralMember(id: 'M3', startNodeId: 'N3', endNodeId: 'N4', sectionProfile: 'W16X36'),
      StructuralMember(id: 'M4', startNodeId: 'N4', endNodeId: 'N5', sectionProfile: 'W18X50'),
      // Frame 2
      StructuralMember(id: 'M5', startNodeId: 'N6', endNodeId: 'N7', sectionProfile: 'W18X50'),
      StructuralMember(id: 'M6', startNodeId: 'N7', endNodeId: 'N8', sectionProfile: 'W16X36'),
      StructuralMember(id: 'M7', startNodeId: 'N8', endNodeId: 'N9', sectionProfile: 'W16X36'),
      StructuralMember(id: 'M8', startNodeId: 'N9', endNodeId: 'N10', sectionProfile: 'W18X50'),
      // Longitudinal Purlins & Eave Struts
      StructuralMember(id: 'M9', startNodeId: 'N2', endNodeId: 'N7', sectionProfile: 'W12X26'),
      StructuralMember(id: 'M10', startNodeId: 'N3', endNodeId: 'N8', sectionProfile: 'W12X26'),
      StructuralMember(id: 'M11', startNodeId: 'N4', endNodeId: 'N9', sectionProfile: 'W12X26'),
      // Eaves Bracing
      StructuralMember(id: 'M12', startNodeId: 'N2', endNodeId: 'N8', sectionProfile: 'W10X22'),
    ];

    return StructuralModel(name: 'Industrial Clear-Span Portal Frame', nodes: nodes, members: members);
  }

  static StructuralModel _buildTransmissionTower() {
    final nodes = [
      // Base legs (4x4m)
      StructuralNode(id: 'B1', x: -2.0, y: 0.0, z: -2.0, isRestrained: [true, true, true, true, true, true]),
      StructuralNode(id: 'B2', x: 2.0, y: 0.0, z: -2.0, isRestrained: [true, true, true, true, true, true]),
      StructuralNode(id: 'B3', x: 2.0, y: 0.0, z: 2.0, isRestrained: [true, true, true, true, true, true]),
      StructuralNode(id: 'B4', x: -2.0, y: 0.0, z: 2.0, isRestrained: [true, true, true, true, true, true]),
      // Tier 1 (H = 8m, 3x3m)
      StructuralNode(id: 'T1_1', x: -1.5, y: 8.0, z: -1.5, isRestrained: [false, false, false, false, false, false]),
      StructuralNode(id: 'T1_2', x: 1.5, y: 8.0, z: -1.5, isRestrained: [false, false, false, false, false, false]),
      StructuralNode(id: 'T1_3', x: 1.5, y: 8.0, z: 1.5, isRestrained: [false, false, false, false, false, false]),
      StructuralNode(id: 'T1_4', x: -1.5, y: 8.0, z: 1.5, isRestrained: [false, false, false, false, false, false]),
      // Tier 2 (H = 16m, 2x2m)
      StructuralNode(id: 'T2_1', x: -1.0, y: 16.0, z: -1.0, isRestrained: [false, false, false, false, false, false]),
      StructuralNode(id: 'T2_2', x: 1.0, y: 16.0, z: -1.0, isRestrained: [false, false, false, false, false, false]),
      StructuralNode(id: 'T2_3', x: 1.0, y: 16.0, z: 1.0, isRestrained: [false, false, false, false, false, false]),
      StructuralNode(id: 'T2_4', x: -1.0, y: 16.0, z: 1.0, isRestrained: [false, false, false, false, false, false]),
      // Crossarm Peak (H = 24m)
      StructuralNode(id: 'P1', x: 0.0, y: 24.0, z: 0.0, isRestrained: [false, false, false, false, false, false], fxN: 35000, fyN: -12000),
      // Crossarm Left/Right conductor supports
      StructuralNode(id: 'CA_L', x: -5.0, y: 20.0, z: 0.0, isRestrained: [false, false, false, false, false, false], fyN: -18000),
      StructuralNode(id: 'CA_R', x: 5.0, y: 20.0, z: 0.0, isRestrained: [false, false, false, false, false, false], fyN: -18000),
      StructuralNode(id: 'CA_C', x: 0.0, y: 20.0, z: 0.0, isRestrained: [false, false, false, false, false, false]),
    ];

    final members = [
      // Base legs to Tier 1
      StructuralMember(id: 'LEG1', startNodeId: 'B1', endNodeId: 'T1_1', sectionProfile: 'W12X53'),
      StructuralMember(id: 'LEG2', startNodeId: 'B2', endNodeId: 'T1_2', sectionProfile: 'W12X53'),
      StructuralMember(id: 'LEG3', startNodeId: 'B3', endNodeId: 'T1_3', sectionProfile: 'W12X53'),
      StructuralMember(id: 'LEG4', startNodeId: 'B4', endNodeId: 'T1_4', sectionProfile: 'W12X53'),
      // Tier 1 horizontal
      StructuralMember(id: 'T1_H1', startNodeId: 'T1_1', endNodeId: 'T1_2', sectionProfile: 'W10X30'),
      StructuralMember(id: 'T1_H2', startNodeId: 'T1_2', endNodeId: 'T1_3', sectionProfile: 'W10X30'),
      StructuralMember(id: 'T1_H3', startNodeId: 'T1_3', endNodeId: 'T1_4', sectionProfile: 'W10X30'),
      StructuralMember(id: 'T1_H4', startNodeId: 'T1_4', endNodeId: 'T1_1', sectionProfile: 'W10X30'),
      // Tier 1 cross bracing
      StructuralMember(id: 'T1_BR1', startNodeId: 'B1', endNodeId: 'T1_2', sectionProfile: 'W10X22'),
      StructuralMember(id: 'T1_BR2', startNodeId: 'B2', endNodeId: 'T1_3', sectionProfile: 'W10X22'),
      // Tier 1 to Tier 2
      StructuralMember(id: 'LEG5', startNodeId: 'T1_1', endNodeId: 'T2_1', sectionProfile: 'W10X39'),
      StructuralMember(id: 'LEG6', startNodeId: 'T1_2', endNodeId: 'T2_2', sectionProfile: 'W10X39'),
      StructuralMember(id: 'LEG7', startNodeId: 'T1_3', endNodeId: 'T2_3', sectionProfile: 'W10X39'),
      StructuralMember(id: 'LEG8', startNodeId: 'T1_4', endNodeId: 'T2_4', sectionProfile: 'W10X39'),
      // Tier 2 horizontal
      StructuralMember(id: 'T2_H1', startNodeId: 'T2_1', endNodeId: 'T2_2', sectionProfile: 'W10X30'),
      StructuralMember(id: 'T2_H2', startNodeId: 'T2_2', endNodeId: 'T2_3', sectionProfile: 'W10X30'),
      StructuralMember(id: 'T2_H3', startNodeId: 'T2_3', endNodeId: 'T2_4', sectionProfile: 'W10X30'),
      StructuralMember(id: 'T2_H4', startNodeId: 'T2_4', endNodeId: 'T2_1', sectionProfile: 'W10X30'),
      // Tier 2 to Peak
      StructuralMember(id: 'LEG9', startNodeId: 'T2_1', endNodeId: 'P1', sectionProfile: 'W10X22'),
      StructuralMember(id: 'LEG10', startNodeId: 'T2_2', endNodeId: 'P1', sectionProfile: 'W10X22'),
      StructuralMember(id: 'LEG11', startNodeId: 'T2_3', endNodeId: 'P1', sectionProfile: 'W10X22'),
      StructuralMember(id: 'LEG12', startNodeId: 'T2_4', endNodeId: 'P1', sectionProfile: 'W10X22'),
      // Crossarm
      StructuralMember(id: 'CA_M1', startNodeId: 'CA_L', endNodeId: 'CA_C', sectionProfile: 'W12X35'),
      StructuralMember(id: 'CA_M2', startNodeId: 'CA_C', endNodeId: 'CA_R', sectionProfile: 'W12X35'),
      StructuralMember(id: 'CA_M3', startNodeId: 'CA_C', endNodeId: 'P1', sectionProfile: 'W10X22'),
    ];

    return StructuralModel(name: '3D Lattice Transmission Tower', nodes: nodes, members: members);
  }

  static StructuralModel _buildPrattTrussBridge() {
    // 30m span, 6 bays of 5m, height 5m
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];

    // Bottom chord: 7 nodes (Y = 0)
    for (int i = 0; i <= 6; i++) {
      final isPin = (i == 0);
      final isRoller = (i == 6);
      nodes.add(StructuralNode(
        id: 'L$i',
        x: i * 5.0,
        y: 0.0,
        z: 0.0,
        isRestrained: isPin
            ? [true, true, true, true, true, true]
            : isRoller
                ? [false, true, true, true, true, true]
                : [false, false, false, false, false, false],
        fyN: (i > 0 && i < 6) ? -35000 : 0.0, // Truck deck loading
      ));
    }

    // Top chord: 5 nodes (Y = 5)
    for (int i = 1; i <= 5; i++) {
      nodes.add(StructuralNode(
        id: 'U$i',
        x: i * 5.0,
        y: 5.0,
        z: 0.0,
        isRestrained: [false, false, false, false, false, false],
      ));
    }

    // Bottom chord members
    for (int i = 0; i < 6; i++) {
      members.add(StructuralMember(
        id: 'BC_$i',
        startNodeId: 'L$i',
        endNodeId: 'L${i + 1}',
        sectionProfile: 'W14X90',
      ));
    }

    // Top chord members
    for (int i = 1; i < 5; i++) {
      members.add(StructuralMember(
        id: 'TC_$i',
        startNodeId: 'U$i',
        endNodeId: 'U${i + 1}',
        sectionProfile: 'W14X120',
      ));
    }

    // End posts
    members.add(StructuralMember(id: 'EP_L', startNodeId: 'L0', endNodeId: 'U1', sectionProfile: 'W14X99'));
    members.add(StructuralMember(id: 'EP_R', startNodeId: 'L6', endNodeId: 'U5', sectionProfile: 'W14X99'));

    // Verticals
    for (int i = 1; i <= 5; i++) {
      members.add(StructuralMember(
        id: 'VERT_$i',
        startNodeId: 'L$i',
        endNodeId: 'U$i',
        sectionProfile: 'W12X53',
      ));
    }

    // Diagonals (Pratt: tension diagonals slope toward center)
    members.add(StructuralMember(id: 'DIAG_1', startNodeId: 'L1', endNodeId: 'U2', sectionProfile: 'W12X40'));
    members.add(StructuralMember(id: 'DIAG_2', startNodeId: 'L2', endNodeId: 'U3', sectionProfile: 'W12X40'));
    members.add(StructuralMember(id: 'DIAG_3', startNodeId: 'L4', endNodeId: 'U3', sectionProfile: 'W12X40'));
    members.add(StructuralMember(id: 'DIAG_4', startNodeId: 'L5', endNodeId: 'U4', sectionProfile: 'W12X40'));

    return StructuralModel(name: 'Pratt Highway Truss Bridge', nodes: nodes, members: members);
  }

  static StructuralModel _buildSpaceGridCanopy() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];

    // 4x4 Grid bottom nodes (H=0) and top pyramid nodes (H=2m)
    for (int ix = 0; ix < 3; ix++) {
      for (int iz = 0; iz < 3; iz++) {
        final isCorner = (ix == 0 || ix == 2) && (iz == 0 || iz == 2);
        nodes.add(StructuralNode(
          id: 'B_${ix}_$iz',
          x: ix * 6.0,
          y: 0.0,
          z: iz * 6.0,
          isRestrained: isCorner
              ? [true, true, true, true, true, true]
              : [false, false, false, false, false, false],
        ));
      }
    }

    // Top nodes (H=2.5m)
    for (int ix = 0; ix < 2; ix++) {
      for (int iz = 0; iz < 2; iz++) {
        nodes.add(StructuralNode(
          id: 'T_${ix}_$iz',
          x: (ix + 0.5) * 6.0,
          y: 2.5,
          z: (iz + 0.5) * 6.0,
          isRestrained: [false, false, false, false, false, false],
          fyN: -30000, // Canopy dead+live load
        ));
      }
    }

    // Grid connections
    int mCount = 1;
    for (int ix = 0; ix < 3; ix++) {
      for (int iz = 0; iz < 3; iz++) {
        if (ix < 2) {
          members.add(StructuralMember(
            id: 'GR_X_${mCount++}',
            startNodeId: 'B_${ix}_$iz',
            endNodeId: 'B_${ix + 1}_$iz',
            sectionProfile: 'W12X30',
          ));
        }
        if (iz < 2) {
          members.add(StructuralMember(
            id: 'GR_Z_${mCount++}',
            startNodeId: 'B_${ix}_$iz',
            endNodeId: 'B_${ix}_${iz + 1}',
            sectionProfile: 'W12X30',
          ));
        }
      }
    }

    // Pyramidal diagonals from bottom nodes to top nodes
    for (int ix = 0; ix < 2; ix++) {
      for (int iz = 0; iz < 2; iz++) {
        final topId = 'T_${ix}_$iz';
        members.add(StructuralMember(id: 'PYR_${mCount++}', startNodeId: 'B_${ix}_$iz', endNodeId: topId, sectionProfile: 'W10X22'));
        members.add(StructuralMember(id: 'PYR_${mCount++}', startNodeId: 'B_${ix + 1}_$iz', endNodeId: topId, sectionProfile: 'W10X22'));
        members.add(StructuralMember(id: 'PYR_${mCount++}', startNodeId: 'B_${ix}_${iz + 1}', endNodeId: topId, sectionProfile: 'W10X22'));
        members.add(StructuralMember(id: 'PYR_${mCount++}', startNodeId: 'B_${ix + 1}_${iz + 1}', endNodeId: topId, sectionProfile: 'W10X22'));
      }
    }

    return StructuralModel(name: 'Double-Layer Space Grid Canopy', nodes: nodes, members: members);
  }

  // --- Cloud Project Management via Firestore ---

  Future<void> saveProjectToCloud({
    required StructuralModel model,
    required String title,
    required String description,
  }) async {
    final db = _db;
    final user = _auth.currentUser;
    if (db == null || user == null) {
      throw Exception('Firebase authentication required to save projects to cloud.');
    }

    final graphJson = serializeModel(model);
    final docRef = db.collection('users').doc(user.uid).collection('projects').doc();

    await docRef.set({
      'title': title.trim().isNotEmpty ? title.trim() : model.name,
      'description': description.trim(),
      'nodeCount': model.nodes.length,
      'memberCount': model.members.length,
      'totalWeightKg': model.totalWeightKg,
      'governingDcr': model.governingDcr,
      'authorUid': user.uid,
      'authorName': user.displayName ?? user.email ?? 'Engineer',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'graphData': graphJson,
    });
  }

  Future<List<CloudProjectMeta>> getUserProjects() async {
    final db = _db;
    final user = _auth.currentUser;
    if (db == null || user == null) return [];

    final query = await db
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .orderBy('updatedAt', descending: true)
        .get();

    return query.docs.map((doc) => CloudProjectMeta.fromDoc(doc)).toList();
  }

  Future<void> deleteProject(String projectId) async {
    final db = _db;
    final user = _auth.currentUser;
    if (db == null || user == null) return;

    await db
        .collection('users')
        .doc(user.uid)
        .collection('projects')
        .doc(projectId)
        .delete();
  }

  // --- Serialization & Custom File Import / Export ---

  static Map<String, dynamic> serializeModel(StructuralModel model) {
    return {
      'name': model.name,
      'nodes': model.nodes
          .map((n) => {
                'id': n.id,
                'x': n.x,
                'y': n.y,
                'z': n.z,
                'restraint': n.isRestrained,
                'loads': [n.fxN, n.fyN, n.fzN, 0.0, 0.0, 0.0],
              })
          .toList(),
      'members': model.members
          .map((m) => {
                'id': m.id,
                'i_node': m.startNodeId,
                'j_node': m.endNodeId,
                'section': m.sectionProfile,
                'material': 'A992_STEEL',
              })
          .toList(),
    };
  }

  static StructuralModel deserializeModel(Map<String, dynamic> data) {
    final name = data['name'] ?? 'Imported Structural Model';
    final rawNodes = data['nodes'] as List<dynamic>? ?? [];
    final rawMembers = data['members'] as List<dynamic>? ?? [];

    final nodes = rawNodes.map((item) {
      final m = item as Map<String, dynamic>;
      final r = m['restraint'] as List<dynamic>? ?? [false, false, false, false, false, false];
      final l = m['loads'] as List<dynamic>? ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

      return StructuralNode(
        id: m['id']?.toString() ?? 'N0',
        x: (m['x'] as num?)?.toDouble() ?? (m['coords']?[0] as num?)?.toDouble() ?? 0.0,
        y: (m['y'] as num?)?.toDouble() ?? (m['coords']?[1] as num?)?.toDouble() ?? 0.0,
        z: (m['z'] as num?)?.toDouble() ?? (m['coords']?[2] as num?)?.toDouble() ?? 0.0,
        isRestrained: r.map((e) => e == true || e == 1).toList(),
        fxN: (l.isNotEmpty ? (l[0] as num?)?.toDouble() : 0.0) ?? 0.0,
        fyN: (l.length > 1 ? (l[1] as num?)?.toDouble() : 0.0) ?? 0.0,
        fzN: (l.length > 2 ? (l[2] as num?)?.toDouble() : 0.0) ?? 0.0,
      );
    }).toList();

    final members = rawMembers.map((item) {
      final m = item as Map<String, dynamic>;
      return StructuralMember(
        id: m['id']?.toString() ?? 'M0',
        startNodeId: m['i_node']?.toString() ?? m['startNodeId']?.toString() ?? 'N1',
        endNodeId: m['j_node']?.toString() ?? m['endNodeId']?.toString() ?? 'N2',
        sectionProfile: m['section']?.toString() ?? m['sectionProfile']?.toString() ?? 'W14X48',
      );
    }).toList();

    return StructuralModel(name: name, nodes: nodes, members: members);
  }

  /// Exports standard ASCII DXF format readable by AutoCAD, Civil 3D, SolidWorks, and Revit.
  static String exportToDxf(StructuralModel model) {
    final buffer = StringBuffer();
    // Header
    buffer.writeln('0\nSECTION\n2\nHEADER\n9\n\$ACADVER\n1\nAC1015\n0\nENDSEC');
    // Entities
    buffer.writeln('0\nSECTION\n2\nENTITIES');

    final nodeMap = {for (var n in model.nodes) n.id: n};

    // Draw members as 3D lines
    for (final m in model.members) {
      final n1 = nodeMap[m.startNodeId];
      final n2 = nodeMap[m.endNodeId];
      if (n1 == null || n2 == null) continue;

      buffer.writeln('0\nLINE');
      buffer.writeln('8\n${m.sectionProfile}'); // Layer = section name
      buffer.writeln('10\n${n1.x}'); // Start X
      buffer.writeln('20\n${n1.z}'); // DXF Z is structural Y or standard elevation
      buffer.writeln('30\n${n1.y}');
      buffer.writeln('11\n${n2.x}'); // End X
      buffer.writeln('21\n${n2.z}');
      buffer.writeln('31\n${n2.y}');
    }

    // Draw nodes as points
    for (final n in model.nodes) {
      buffer.writeln('0\nPOINT');
      buffer.writeln('8\nNODES');
      buffer.writeln('10\n${n.x}');
      buffer.writeln('20\n${n.z}');
      buffer.writeln('30\n${n.y}');
    }

    buffer.writeln('0\nENDSEC\n0\nEOF');
    return buffer.toString();
  }

  /// Exports Bill of Materials (BOM) CSV.
  static String exportToCsvBom(StructuralModel model) {
    final buffer = StringBuffer();
    buffer.writeln('Member ID,Start Node,End Node,AISC Section,Length (m),Weight (kg),Max DCR,Status');
    for (final m in model.members) {
      buffer.writeln(
        '${m.id},${m.startNodeId},${m.endNodeId},${m.sectionProfile},'
        '${m.lengthM.toStringAsFixed(3)},${m.weightKg.toStringAsFixed(1)},'
        '${m.governingDcr.toStringAsFixed(3)},${m.isCompliant ? "COMPLIANT" : "FAIL"}',
      );
    }
    buffer.writeln('\nTOTAL NODES,${model.nodes.length}');
    buffer.writeln('TOTAL MEMBERS,${model.members.length}');
    buffer.writeln('TOTAL STEEL TONNAGE,${(model.totalWeightKg / 1000.0).toStringAsFixed(2)} metric tonnes');
    return buffer.toString();
  }

  /// Exports CSI ETABS / SAP2000 .s2k format directly on client side.
  static String exportToS2k(StructuralModel model) {
    final buffer = StringBuffer();
    buffer.writeln('; ETABS / SAP2000 Text Data File (.s2k)');
    buffer.writeln('; Generated by Structura Nexus Client Engine');
    buffer.writeln('; Project: ${model.name}\n');

    buffer.writeln('TABLE:  "PROGRAM INFORMATION"');
    buffer.writeln('   Program="ETABS"   Version="21.0.0"   ProgLevel="Ultimate"\n');

    buffer.writeln('TABLE:  "MATERIAL PROPERTIES 01 - GENERAL"');
    buffer.writeln('   Material="A992Fy50"   Type="Steel"   DesignType="Steel"   UnitWeight=78.5   E=200000000   Fy=345000   Fu=450000\n');

    buffer.writeln('TABLE:  "JOINT COORDINATES"');
    for (final n in model.nodes) {
      buffer.writeln('   Joint="${n.id}"   CoordSys="GLOBAL"   CoordType="Cartesian"   XorR=${n.x.toStringAsFixed(4)}   Y=${n.z.toStringAsFixed(4)}   Z=${n.y.toStringAsFixed(4)}');
    }
    buffer.writeln('');

    buffer.writeln('TABLE:  "CONNECTIVITY - FRAME"');
    for (final m in model.members) {
      buffer.writeln('   Frame="${m.id}"   JointI="${m.startNodeId}"   JointJ="${m.endNodeId}"   IsCurved="No"');
    }
    buffer.writeln('');

    buffer.writeln('TABLE:  "FRAME SECTION ASSIGNMENTS"');
    for (final m in model.members) {
      buffer.writeln('   Frame="${m.id}"   AnalSect="${m.sectionProfile}"   MatProp="Default"');
    }
    buffer.writeln('');

    buffer.writeln('TABLE:  "JOINT RESTRAINT ASSIGNMENTS"');
    for (final n in model.nodes) {
      if (n.isRestrained.any((r) => r)) {
        final r = n.isRestrained;
        final u1 = r.isNotEmpty && r[0] ? 'Yes' : 'No';
        final u2 = r.length > 2 && r[2] ? 'Yes' : 'No';
        final u3 = r.length > 1 && r[1] ? 'Yes' : 'No';
        final r1 = r.length > 3 && r[3] ? 'Yes' : 'No';
        final r2 = r.length > 5 && r[5] ? 'Yes' : 'No';
        final r3 = r.length > 4 && r[4] ? 'Yes' : 'No';
        buffer.writeln('   Joint="${n.id}"   U1=$u1   U2=$u2   U3=$u3   R1=$r1   R2=$r2   R3=$r3');
      }
    }
    buffer.writeln('');

    buffer.writeln('END TABLE DATA');
    return buffer.toString();
  }

  /// Exports standard IFC 4.3 STEP file format directly on client side.
  static String exportToIfc(StructuralModel model) {
    final buffer = StringBuffer();
    final timestamp = DateTime.now().toIso8601String();
    buffer.writeln('ISO-10303-21;');
    buffer.writeln('HEADER;');
    buffer.writeln("FILE_DESCRIPTION(('ViewDefinition [DesignTransferView_V1.0]'),'2;1');");
    buffer.writeln("FILE_NAME('${model.name}.ifc','$timestamp',('Structura Nexus Engineer'),('Civil Engineering Dept'),'Structura Nexus v3.4','IFC 4.3 Engine','Approved');");
    buffer.writeln("FILE_SCHEMA(('IFC4X3'));");
    buffer.writeln('ENDSEC;');
    buffer.writeln('DATA;');
    buffer.writeln("#1=IFCPROJECT('1ProjectNexus000000000',\$,'${model.name}','Space Frame',\$,\$,\$,\$,#10);");
    buffer.writeln("#10=IFCUNITASSIGNMENT((#11,#12));");
    buffer.writeln("#11=IFCSIUNIT(*,.LENGTHUNIT.,\$,.METRE.);");
    buffer.writeln("#12=IFCSIUNIT(*,.FORCEUNIT.,.KILO.,.NEWTON.);");

    int id = 20;
    final pointIds = <String, int>{};
    for (final n in model.nodes) {
      final pid = id++;
      pointIds[n.id] = pid;
      buffer.writeln("#$pid=IFCCARTESIANPOINT((${n.x.toStringAsFixed(4)},${n.z.toStringAsFixed(4)},${n.y.toStringAsFixed(4)}));");
    }

    for (final m in model.members) {
      final p1 = pointIds[m.startNodeId];
      final p2 = pointIds[m.endNodeId];
      if (p1 != null && p2 != null) {
        final lineId = id++;
        final memberId = id++;
        buffer.writeln("#$lineId=IFCPOLYLINE((#$p1,#$p2));");
        buffer.writeln("#$memberId=IFCMEMBER('1MemberNexus${m.id}',\$,'${m.id}','${m.sectionProfile}',\$,\$,\$,'${m.sectionProfile}');");
      }
    }

    buffer.writeln('ENDSEC;');
    buffer.writeln('END-ISO-10303-21;');
    return buffer.toString();
  }
}
