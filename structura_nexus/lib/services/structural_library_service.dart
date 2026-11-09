import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/structural_models.dart';
import 'building_generator_service.dart';
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
    return BuildingGeneratorService.getCertifiedBuildingTemplates().map((t) => {
      'id': t.id,
      'title': t.title,
      'category': t.category,
      'badge': t.badge,
      'description': t.description,
      'nodeCount': t.nodeCount,
      'memberCount': t.memberCount,
      'stories': t.stories,
      'heightM': t.heightM,
      'footprintAreaM2': t.footprintAreaM2,
      'structuralSystem': t.structuralSystem,
      'standard': t.standard,
      'factory': t.builder,
    }).toList();
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
    // Header with Author & Copyright Watermark
    buffer.writeln('999\nStructura Nexus (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved. DMCA Protected.');
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
    buffer.writeln('# Structura Nexus BOM - Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved. DMCA Protected.');
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
    buffer.writeln('; Structura Nexus (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved. DMCA Protected.');
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
    buffer.writeln("FILE_DESCRIPTION(('ViewDefinition [DesignTransferView_V1.0]','Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved. DMCA Protected.'),'2;1');");
    buffer.writeln("FILE_NAME('${model.name}.ifc','$timestamp',('Ali Asghar <aliasgharinnocent@yahoo.com>'),('Dart Nexus Lab'),'Structura Nexus v3.4','IFC 4.3 Engine','Approved');");
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
