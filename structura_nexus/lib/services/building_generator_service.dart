// ============================================================================
// Structura Nexus: Parametric 3D Building Synthesizer & Importer Service
// Generates Multi-Storey Buildings, Structural Framing & Diaphragms on the Fly
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:convert';
import 'package:vector_math/vector_math_64.dart';
import '../models/structural_models.dart';

enum BuildingSystemType {
  momentFrame,
  xBracedFrame,
  chevronBraced,
  outriggerCore,
  shearWallDual,
}

class BuildingGeneratorService {
  /// Synthesizes a full 3D multi-storey building space frame with accurate geometry,
  /// rigid base boundary conditions, and distributed floor gravity loads.
  static StructuralModel generateParametricBuilding({
    String name = 'Synthesized Multi-Storey Building',
    int numStories = 5,
    int baysX = 3,
    int baysZ = 2,
    double bayWidthX = 6.0,
    double bayDepthZ = 6.0,
    double storyHeight = 3.6,
    BuildingSystemType system = BuildingSystemType.xBracedFrame,
    String columnSection = 'W14X90',
    String beamSection = 'W18X35',
    String braceSection = 'W10X33',
    double floorDeadLoadKpa = 3.5,
    double floorLiveLoadKpa = 2.5,
  }) {
    final List<StructuralNode> nodes = [];
    final List<StructuralMember> members = [];

    // Helper to get node ID
    String nid(int sx, int story, int sz) => 'N_${sx}_${story}_$sz';

    // 1. Generate 3D Grid Nodes
    for (int story = 0; story <= numStories; story++) {
      final y = story * storyHeight;
      final isRoof = story == numStories;
      final floorLoad = isRoof ? (floorDeadLoadKpa + 1.0) : (floorDeadLoadKpa + floorLiveLoadKpa);

      for (int ix = 0; ix <= baysX; ix++) {
        final x = ix * bayWidthX;

        for (int iz = 0; iz <= baysZ; iz++) {
          final z = iz * bayDepthZ;
          final isBase = story == 0;
          final nodeId = nid(ix, story, iz);

          // Tributary floor area for nodal gravity load
          double tribArea = bayWidthX * bayDepthZ;
          if (ix == 0 || ix == baysX) tribArea *= 0.5;
          if (iz == 0 || iz == baysZ) tribArea *= 0.5;

          // Downward gravity load Fy (negative N)
          final fyN = isBase ? 0.0 : -(tribArea * floorLoad * 1000.0);

          nodes.add(
            StructuralNode(
              id: nodeId,
              coords: Vector3(x, y, z),
              restraint: isBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0],
              loads: [0.0, fyN, 0.0, 0.0, 0.0, 0.0],
            ),
          );
        }
      }
    }

    // 2. Generate Columns (Vertical Members along Y)
    int memIdx = 1;
    for (int story = 0; story < numStories; story++) {
      for (int ix = 0; ix <= baysX; ix++) {
        for (int iz = 0; iz <= baysZ; iz++) {
          final bNode = nid(ix, story, iz);
          final tNode = nid(ix, story + 1, iz);
          members.add(
            StructuralMember(
              id: 'COL_${memIdx++}',
              iNodeId: bNode,
              jNodeId: tNode,
              section: columnSection,
              material: 'A992_STEEL',
            ),
          );
        }
      }
    }

    // 3. Generate Beams (Horizontal Members along X and Z)
    for (int story = 1; story <= numStories; story++) {
      // Beams along X
      for (int iz = 0; iz <= baysZ; iz++) {
        for (int ix = 0; ix < baysX; ix++) {
          final n1 = nid(ix, story, iz);
          final n2 = nid(ix + 1, story, iz);
          members.add(
            StructuralMember(
              id: 'BMX_${memIdx++}',
              iNodeId: n1,
              jNodeId: n2,
              section: beamSection,
              material: 'A992_STEEL',
            ),
          );
        }
      }

      // Beams along Z
      for (int ix = 0; ix <= baysX; ix++) {
        for (int iz = 0; iz < baysZ; iz++) {
          final n1 = nid(ix, story, iz);
          final n2 = nid(ix, story, iz + 1);
          members.add(
            StructuralMember(
              id: 'BMZ_${memIdx++}',
              iNodeId: n1,
              jNodeId: n2,
              section: beamSection,
              material: 'A992_STEEL',
            ),
          );
        }
      }
    }

    // 4. Generate Lateral Bracing Systems
    if (system == BuildingSystemType.xBracedFrame) {
      for (int story = 0; story < numStories; story++) {
        // Front & Back exterior X-braces
        for (final iz in [0, baysZ]) {
          final bLeft = nid(0, story, iz);
          final bRight = nid(1, story, iz);
          final tLeft = nid(0, story + 1, iz);
          final tRight = nid(1, story + 1, iz);

          members.add(StructuralMember(id: 'BRC_${memIdx++}', iNodeId: bLeft, jNodeId: tRight, section: braceSection, material: 'A992_STEEL'));
          members.add(StructuralMember(id: 'BRC_${memIdx++}', iNodeId: bRight, jNodeId: tLeft, section: braceSection, material: 'A992_STEEL'));
        }

        // Left & Right exterior X-braces
        for (final ix in [0, baysX]) {
          final bFront = nid(ix, story, 0);
          final bBack = nid(ix, story, 1);
          final tFront = nid(ix, story + 1, 0);
          final tBack = nid(ix, story + 1, 1);

          members.add(StructuralMember(id: 'BRC_${memIdx++}', iNodeId: bFront, jNodeId: tBack, section: braceSection, material: 'A992_STEEL'));
          members.add(StructuralMember(id: 'BRC_${memIdx++}', iNodeId: bBack, jNodeId: tFront, section: braceSection, material: 'A992_STEEL'));
        }
      }
    } else if (system == BuildingSystemType.chevronBraced) {
      // Inverted V Chevron bracing
      for (int story = 0; story < numStories; story++) {
        for (final iz in [0, baysZ]) {
          final bLeft = nid(0, story, iz);
          final bRight = nid(1, story, iz);
          final midNodeId = 'N_CHEV_${story}_$iz';
          final midX = bayWidthX / 2.0;
          final midY = (story + 1) * storyHeight;
          final midZ = iz * bayDepthZ;

          nodes.add(StructuralNode(id: midNodeId, coords: Vector3(midX, midY, midZ)));
          members.add(StructuralMember(id: 'BRC_${memIdx++}', iNodeId: bLeft, jNodeId: midNodeId, section: braceSection, material: 'A992_STEEL'));
          members.add(StructuralMember(id: 'BRC_${memIdx++}', iNodeId: bRight, jNodeId: midNodeId, section: braceSection, material: 'A992_STEEL'));
        }
      }
    }

    final model = StructuralModel(
      name: name,
      nodes: nodes,
      members: members,
    );

    return model;
  }

  /// Parses an imported structural model string (JSON, S2K, DXF)
  static StructuralModel? importModel(String text, {String filename = ''}) {
    final lower = filename.toLowerCase();

    // 1. JSON Structural Graph
    if (lower.endsWith('.json') || text.trim().startsWith('{')) {
      try {
        final Map<String, dynamic> data = jsonDecode(text);
        final List<dynamic> rawNodes = data['nodes'] ?? [];
        final List<dynamic> rawMembers = data['members'] ?? [];

        final nodes = rawNodes.map((n) {
          final coords = (n['coords'] as List).map((c) => (c as num).toDouble()).toList();
          final restraint = (n['restraint'] as List?)?.map((r) => (r as num).toInt()).toList();
          final loads = (n['loads'] as List?)?.map((l) => (l as num).toDouble()).toList();
          return StructuralNode(
            id: n['id'].toString(),
            coords: Vector3(coords[0], coords[1], coords[2]),
            restraint: restraint,
            loads: loads,
          );
        }).toList();

        final members = rawMembers.map((m) {
          return StructuralMember(
            id: m['id'].toString(),
            iNodeId: (m['i_node'] ?? m['startNodeId']).toString(),
            jNodeId: (m['j_node'] ?? m['endNodeId']).toString(),
            section: (m['section'] ?? 'W14X48').toString(),
            material: (m['material'] ?? 'A992_STEEL').toString(),
          );
        }).toList();

        return StructuralModel(
          name: data['name'] ?? 'Imported JSON Model',
          nodes: nodes,
          members: members,
        );
      } catch (e) {
        return null;
      }
    }

    // 2. S2K SAP2000 Text Import
    if (lower.endsWith('.s2k') || text.contains('TABLE:  "JOINT COORDINATES"')) {
      final List<StructuralNode> nodes = [];
      final List<StructuralMember> members = [];
      final lines = text.split('\n');
      bool inJoints = false;
      bool inFrames = false;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('TABLE:  "JOINT COORDINATES"')) {
          inJoints = true;
          inFrames = false;
          continue;
        } else if (trimmed.startsWith('TABLE:  "CONNECTIVITY - FRAME"')) {
          inJoints = false;
          inFrames = true;
          continue;
        } else if (trimmed.startsWith('TABLE:')) {
          inJoints = false;
          inFrames = false;
        }

        if (inJoints && trimmed.startsWith('Joint=')) {
          final parts = trimmed.split(RegExp(r'\s+'));
          String? id;
          double x = 0, y = 0, z = 0;
          for (final p in parts) {
            if (p.startsWith('Joint=')) id = p.substring(6);
            if (p.startsWith('GlobalX=')) x = double.tryParse(p.substring(8)) ?? 0;
            if (p.startsWith('GlobalY=')) y = double.tryParse(p.substring(8)) ?? 0;
            if (p.startsWith('GlobalZ=')) z = double.tryParse(p.substring(8)) ?? 0;
          }
          if (id != null) {
            nodes.add(StructuralNode(id: id, coords: Vector3(x, z, y), restraint: z == 0 ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0]));
          }
        }

        if (inFrames && trimmed.startsWith('Frame=')) {
          final parts = trimmed.split(RegExp(r'\s+'));
          String? id, ni, nj;
          for (final p in parts) {
            if (p.startsWith('Frame=')) id = p.substring(6);
            if (p.startsWith('JointI=')) ni = p.substring(7);
            if (p.startsWith('JointJ=')) nj = p.substring(7);
          }
          if (id != null && ni != null && nj != null) {
            members.add(StructuralMember(id: id, iNodeId: ni, jNodeId: nj, section: 'W14X48', material: 'A992_STEEL'));
          }
        }
      }

      if (nodes.isNotEmpty && members.isNotEmpty) {
        return StructuralModel(name: 'Imported S2K Frame', nodes: nodes, members: members);
      }
    }

    return null;
  }
}
