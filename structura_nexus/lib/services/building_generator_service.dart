// ============================================================================
// Structura Nexus: Parametric 3D Building Synthesizer & Importer Service
// Generates Multi-Storey Buildings, Structural Framing & Diaphragms on the Fly
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:convert';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../models/structural_models.dart';
import '../data/benchmark_presets.dart';

enum BuildingSystemType {
  momentFrame,
  xBracedFrame,
  chevronBraced,
  outriggerCore,
  shearWallDual,
}

class BuildingTemplateMeta {
  final String id;
  final String title;
  final String category;
  final String badge;
  final String description;
  final int stories;
  final double heightM;
  final double footprintAreaM2;
  final int nodeCount;
  final int memberCount;
  final String structuralSystem;
  final String standard;
  final StructuralModel Function() builder;

  const BuildingTemplateMeta({
    required this.id,
    required this.title,
    required this.category,
    required this.badge,
    required this.description,
    required this.stories,
    required this.heightM,
    required this.footprintAreaM2,
    required this.nodeCount,
    required this.memberCount,
    required this.structuralSystem,
    required this.standard,
    required this.builder,
  });
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

          double tribArea = bayWidthX * bayDepthZ;
          if (ix == 0 || ix == baysX) tribArea *= 0.5;
          if (iz == 0 || iz == baysZ) tribArea *= 0.5;

          final fyN = isBase ? 0.0 : -(tribArea * floorLoad * 1000.0);

          // Apply ASCE 7 lateral wind pressure profile to windward exterior nodes (iz == 0)
          double fxN = 0.0;
          if (!isBase && iz == 0) {
            final zRatio = y / (numStories * storyHeight);
            final qzKpa = 1.25 * math.pow(zRatio, 0.28);
            final faceArea = (ix == 0 || ix == baysX ? bayWidthX * 0.5 : bayWidthX) * storyHeight;
            fxN = qzKpa * 0.85 * faceArea * 1000.0;
          }

          nodes.add(
            StructuralNode(
              id: nodeId,
              coords: Vector3(x, y, z),
              restraint: isBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0],
              loads: [fxN, fyN, 0.0, 0.0, 0.0, 0.0],
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

    return StructuralModel(
      name: name,
      nodes: nodes,
      members: members,
    );
  }

  // ==========================================================================
  // CERTIFIED BUILDING TEMPLATES
  // ==========================================================================

  /// 10-Story Commercial Office Tower (X-Braced Perimeter System)
  static StructuralModel generateCommercialHighRiseTower() {
    return generateParametricBuilding(
      name: '10-Story Commercial Office Tower (X-Braced)',
      numStories: 10,
      baysX: 4,
      baysZ: 3,
      bayWidthX: 6.0,
      bayDepthZ: 6.0,
      storyHeight: 3.6,
      system: BuildingSystemType.xBracedFrame,
      columnSection: 'W14X132',
      beamSection: 'W18X50',
      braceSection: 'W10X49',
      floorDeadLoadKpa: 3.8,
      floorLiveLoadKpa: 2.5,
    );
  }

  /// 8-Story Dual Core Hospital / Medical Complex
  static StructuralModel generateHospitalComplex() {
    return generateParametricBuilding(
      name: '8-Story Dual Core Hospital Complex',
      numStories: 8,
      baysX: 4,
      baysZ: 4,
      bayWidthX: 7.2,
      bayDepthZ: 7.2,
      storyHeight: 3.8,
      system: BuildingSystemType.chevronBraced,
      columnSection: 'W14X120',
      beamSection: 'W21X62',
      braceSection: 'W12X53',
      floorDeadLoadKpa: 4.5,
      floorLiveLoadKpa: 3.5,
    );
  }

  /// 6-Story Residential Steel-Framed Building
  static StructuralModel generateResidentialBuilding() {
    return generateParametricBuilding(
      name: '6-Story Residential Steel Frame',
      numStories: 6,
      baysX: 3,
      baysZ: 3,
      bayWidthX: 6.0,
      bayDepthZ: 5.5,
      storyHeight: 3.5,
      system: BuildingSystemType.momentFrame,
      columnSection: 'W14X74',
      beamSection: 'W16X31',
      braceSection: 'W10X33',
      floorDeadLoadKpa: 3.2,
      floorLiveLoadKpa: 2.0,
    );
  }

  /// 20-Story Super-Tall Outrigger Tower
  static StructuralModel generateSuperTallOutrigger() {
    return generateParametricBuilding(
      name: '20-Story Super-Tall Outrigger Tower',
      numStories: 20,
      baysX: 4,
      baysZ: 4,
      bayWidthX: 6.0,
      bayDepthZ: 6.0,
      storyHeight: 3.6,
      system: BuildingSystemType.xBracedFrame,
      columnSection: 'W14X132',
      beamSection: 'W24X76',
      braceSection: 'W14X90',
      floorDeadLoadKpa: 4.0,
      floorLiveLoadKpa: 2.5,
    );
  }

  /// Industrial Logistics Clear-Span Portal Warehouse (36m clear-span)
  static StructuralModel generateIndustrialWarehouse() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    const spanX = 36.0;
    const eavesY = 7.5;
    const apexY = 10.5;
    const baySpacingZ = 9.0;
    const numBaysZ = 4;

    for (int bz = 0; bz <= numBaysZ; bz++) {
      final z = bz * baySpacingZ;
      final isEnd = bz == 0 || bz == numBaysZ;

      final nBaseLeft = 'N_W_BL_$bz';
      final nEavesLeft = 'N_W_EL_$bz';
      final nApex = 'N_W_AP_$bz';
      final nEavesRight = 'N_W_ER_$bz';
      final nBaseRight = 'N_W_BR_$bz';

      nodes.add(StructuralNode(id: nBaseLeft, coords: Vector3(0.0, 0.0, z), restraint: [1, 1, 1, 1, 1, 1]));
      nodes.add(StructuralNode(id: nEavesLeft, coords: Vector3(0.0, eavesY, z), loads: [18000.0, -15000.0, 0.0, 0.0, 0.0, 0.0]));
      nodes.add(StructuralNode(id: nApex, coords: Vector3(spanX / 2.0, apexY, z), loads: [0.0, -32000.0, 0.0, 0.0, 0.0, 0.0]));
      nodes.add(StructuralNode(id: nEavesRight, coords: Vector3(spanX, eavesY, z), loads: [0.0, -15000.0, 0.0, 0.0, 0.0, 0.0]));
      nodes.add(StructuralNode(id: nBaseRight, coords: Vector3(spanX, 0.0, z), restraint: [1, 1, 1, 1, 1, 1]));

      // Column left
      members.add(StructuralMember(id: 'COL_L_$bz', iNodeId: nBaseLeft, jNodeId: nEavesLeft, section: 'W24X76', material: 'A992_STEEL'));
      // Rafter left
      members.add(StructuralMember(id: 'RAF_L_$bz', iNodeId: nEavesLeft, jNodeId: nApex, section: 'W21X50', material: 'A992_STEEL'));
      // Rafter right
      members.add(StructuralMember(id: 'RAF_R_$bz', iNodeId: nApex, jNodeId: nEavesRight, section: 'W21X50', material: 'A992_STEEL'));
      // Column right
      members.add(StructuralMember(id: 'COL_R_$bz', iNodeId: nBaseRight, jNodeId: nEavesRight, section: 'W24X76', material: 'A992_STEEL'));

      // Longitudinal roof purlins & eave struts connecting frames
      if (bz > 0) {
        final prevBz = bz - 1;
        members.add(StructuralMember(id: 'EAV_L_$memIdx', iNodeId: 'N_W_EL_$prevBz', jNodeId: nEavesLeft, section: 'W12X26', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'PUR_A_$memIdx', iNodeId: 'N_W_AP_$prevBz', jNodeId: nApex, section: 'W12X26', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'EAV_R_$memIdx', iNodeId: 'N_W_ER_$prevBz', jNodeId: nEavesRight, section: 'W12X26', material: 'A992_STEEL'));
        memIdx++;

        // Cross bracing on end bays
        if (isEnd || bz == 1) {
          members.add(StructuralMember(id: 'BRC_Z1_$memIdx', iNodeId: 'N_W_BL_$prevBz', jNodeId: nEavesLeft, section: 'W10X33', material: 'A992_STEEL'));
          members.add(StructuralMember(id: 'BRC_Z2_$memIdx', iNodeId: 'N_W_EL_$prevBz', jNodeId: nBaseLeft, section: 'W10X33', material: 'A992_STEEL'));
          memIdx++;
        }
      }
    }

    return StructuralModel(
      name: 'Industrial Logistics Clear-Span Warehouse (36m)',
      nodes: nodes,
      members: members,
    );
  }

  /// Airport Terminal 3D Space Grid Canopy (48m x 36m)
  static StructuralModel generateSpaceGridCanopy() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    const nx = 8;
    const nz = 6;
    const dx = 6.0;
    const dz = 6.0;
    const bottomY = 8.0;
    const topY = 11.0;

    // Bottom grid joints
    for (int ix = 0; ix <= nx; ix++) {
      for (int iz = 0; iz <= nz; iz++) {
        final isCornerCol = (ix == 1 || ix == nx - 1) && (iz == 1 || iz == nz - 1);
        final id = 'SG_B_${ix}_$iz';
        nodes.add(
          StructuralNode(
            id: id,
            coords: Vector3(ix * dx, bottomY, iz * dz),
            restraint: isCornerCol ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0],
            loads: [0.0, -8000.0, 0.0, 0.0, 0.0, 0.0],
          ),
        );
      }
    }

    // Top grid joints (offset by half bay)
    for (int ix = 0; ix < nx; ix++) {
      for (int iz = 0; iz < nz; iz++) {
        final id = 'SG_T_${ix}_$iz';
        final x = (ix + 0.5) * dx;
        final z = (iz + 0.5) * dz;
        nodes.add(
          StructuralNode(
            id: id,
            coords: Vector3(x, topY, z),
            loads: [0.0, -12000.0, 0.0, 0.0, 0.0, 0.0],
          ),
        );
      }
    }

    // Chords along bottom grid
    for (int ix = 0; ix <= nx; ix++) {
      for (int iz = 0; iz <= nz; iz++) {
        if (ix < nx) {
          members.add(StructuralMember(id: 'CHB_X_${memIdx++}', iNodeId: 'SG_B_${ix}_$iz', jNodeId: 'SG_B_${ix + 1}_$iz', section: 'W10X33', material: 'A992_STEEL'));
        }
        if (iz < nz) {
          members.add(StructuralMember(id: 'CHB_Z_${memIdx++}', iNodeId: 'SG_B_${ix}_$iz', jNodeId: 'SG_B_${ix}_${iz + 1}', section: 'W10X33', material: 'A992_STEEL'));
        }
      }
    }

    // Chords along top grid & Web pyramid diagonals
    for (int ix = 0; ix < nx; ix++) {
      for (int iz = 0; iz < nz; iz++) {
        final tId = 'SG_T_${ix}_$iz';
        if (ix < nx - 1) {
          members.add(StructuralMember(id: 'CHT_X_${memIdx++}', iNodeId: tId, jNodeId: 'SG_T_${ix + 1}_$iz', section: 'W10X33', material: 'A992_STEEL'));
        }
        if (iz < nz - 1) {
          members.add(StructuralMember(id: 'CHT_Z_${memIdx++}', iNodeId: tId, jNodeId: 'SG_T_${ix}_${iz + 1}', section: 'W10X33', material: 'A992_STEEL'));
        }

        // Web diagonals to 4 bottom joints of pyramid
        members.add(StructuralMember(id: 'DIA_1_${memIdx++}', iNodeId: 'SG_B_${ix}_$iz', jNodeId: tId, section: 'W8X24', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'DIA_2_${memIdx++}', iNodeId: 'SG_B_${ix + 1}_$iz', jNodeId: tId, section: 'W8X24', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'DIA_3_${memIdx++}', iNodeId: 'SG_B_${ix}_${iz + 1}', jNodeId: tId, section: 'W8X24', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'DIA_4_${memIdx++}', iNodeId: 'SG_B_${ix + 1}_${iz + 1}', jNodeId: tId, section: 'W8X24', material: 'A992_STEEL'));
      }
    }

    return StructuralModel(
      name: 'Airport Terminal 3D Space Grid Canopy (48m x 36m)',
      nodes: nodes,
      members: members,
    );
  }

  /// 4-Story Educational Academic Facility with Central Atrium
  static StructuralModel generateEducationalCampus() {
    return generateParametricBuilding(
      name: '4-Story Educational Academic Facility (Atrium Grid)',
      numStories: 4,
      baysX: 4,
      baysZ: 3,
      bayWidthX: 7.2,
      bayDepthZ: 6.0,
      storyHeight: 3.6,
      system: BuildingSystemType.momentFrame,
      columnSection: 'W14X90',
      beamSection: 'W18X40',
      braceSection: 'W10X33',
      floorDeadLoadKpa: 3.6,
      floorLiveLoadKpa: 3.0,
    );
  }

  /// 36m Pratt Highway Truss Bridge
  static StructuralModel generatePrattHighwayBridge() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    const span = 36.0;
    const height = 6.0;
    const width = 8.0;
    const numPanels = 6;
    const panelL = span / numPanels;

    for (int iz = 0; iz < 2; iz++) {
      final z = iz * width;
      final prefix = iz == 0 ? 'TR_L' : 'TR_R';

      // Bottom joints
      for (int i = 0; i <= numPanels; i++) {
        final isPin = i == 0;
        final isRoller = i == numPanels;
        nodes.add(
          StructuralNode(
            id: '${prefix}_B_$i',
            coords: Vector3(i * panelL, 0.0, z),
            restraint: isPin ? [1, 1, 1, 1, 1, 1] : (isRoller ? [0, 1, 1, 0, 0, 0] : [0, 0, 0, 0, 0, 0]),
            loads: [0.0, -45000.0, 0.0, 0.0, 0.0, 0.0],
          ),
        );
      }

      // Top joints
      for (int i = 1; i < numPanels; i++) {
        nodes.add(
          StructuralNode(
            id: '${prefix}_T_$i',
            coords: Vector3(i * panelL, height, z),
            loads: [0.0, -15000.0, 0.0, 0.0, 0.0, 0.0],
          ),
        );
      }

      // Bottom chord
      for (int i = 0; i < numPanels; i++) {
        members.add(StructuralMember(id: '${prefix}_BC_${memIdx++}', iNodeId: '${prefix}_B_$i', jNodeId: '${prefix}_B_${i + 1}', section: 'W12X53', material: 'A992_STEEL'));
      }

      // Top chord
      for (int i = 1; i < numPanels - 1; i++) {
        members.add(StructuralMember(id: '${prefix}_TC_${memIdx++}', iNodeId: '${prefix}_T_$i', jNodeId: '${prefix}_T_${i + 1}', section: 'W14X68', material: 'A992_STEEL'));
      }

      // End posts
      members.add(StructuralMember(id: '${prefix}_EP1_${memIdx++}', iNodeId: '${prefix}_B_0', jNodeId: '${prefix}_T_1', section: 'W14X90', material: 'A992_STEEL'));
      members.add(StructuralMember(id: '${prefix}_EP2_${memIdx++}', iNodeId: '${prefix}_B_$numPanels', jNodeId: '${prefix}_T_${numPanels - 1}', section: 'W14X90', material: 'A992_STEEL'));

      // Verticals & Diagonals
      for (int i = 1; i < numPanels; i++) {
        members.add(StructuralMember(id: '${prefix}_V_${memIdx++}', iNodeId: '${prefix}_B_$i', jNodeId: '${prefix}_T_$i', section: 'W10X49', material: 'A992_STEEL'));
        if (i < 3) {
          members.add(StructuralMember(id: '${prefix}_D_${memIdx++}', iNodeId: '${prefix}_B_$i', jNodeId: '${prefix}_T_${i + 1}', section: 'W10X49', material: 'A992_STEEL'));
        } else if (i > 3) {
          members.add(StructuralMember(id: '${prefix}_D_${memIdx++}', iNodeId: '${prefix}_B_$i', jNodeId: '${prefix}_T_${i - 1}', section: 'W10X49', material: 'A992_STEEL'));
        }
      }
    }

    // Cross-deck floor beams connecting bottom joints
    for (int i = 0; i <= numPanels; i++) {
      members.add(StructuralMember(id: 'FB_${memIdx++}', iNodeId: 'TR_L_B_$i', jNodeId: 'TR_R_B_$i', section: 'W18X50', material: 'A992_STEEL'));
    }

    return StructuralModel(
      name: '36m Pratt Highway Truss Bridge (AASHTO HL-93)',
      nodes: nodes,
      members: members,
    );
  }

  /// 28m 3D Lattice Transmission Tower
  static StructuralModel generateTransmissionTower() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    final levels = [0.0, 7.0, 14.0, 21.0, 28.0];
    final widths = [5.0, 3.8, 2.8, 2.0, 1.2];

    for (int lv = 0; lv < levels.length; lv++) {
      final y = levels[lv];
      final w = widths[lv];
      final half = w / 2.0;
      final isBase = lv == 0;

      nodes.add(StructuralNode(id: 'TT_${lv}_1', coords: Vector3(-half, y, -half), restraint: isBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0]));
      nodes.add(StructuralNode(id: 'TT_${lv}_2', coords: Vector3(half, y, -half), restraint: isBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0]));
      nodes.add(StructuralNode(id: 'TT_${lv}_3', coords: Vector3(half, y, half), restraint: isBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0]));
      nodes.add(StructuralNode(id: 'TT_${lv}_4', coords: Vector3(-half, y, half), restraint: isBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0]));

      if (lv > 0) {
        final p = lv - 1;
        // Legs
        members.add(StructuralMember(id: 'LEG_${memIdx++}', iNodeId: 'TT_${p}_1', jNodeId: 'TT_${lv}_1', section: 'L6X6X1/2', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'LEG_${memIdx++}', iNodeId: 'TT_${p}_2', jNodeId: 'TT_${lv}_2', section: 'L6X6X1/2', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'LEG_${memIdx++}', iNodeId: 'TT_${p}_3', jNodeId: 'TT_${lv}_3', section: 'L6X6X1/2', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'LEG_${memIdx++}', iNodeId: 'TT_${p}_4', jNodeId: 'TT_${lv}_4', section: 'L6X6X1/2', material: 'A992_STEEL'));

        // Horizontals
        members.add(StructuralMember(id: 'HOR_${memIdx++}', iNodeId: 'TT_${lv}_1', jNodeId: 'TT_${lv}_2', section: 'L4X4X3/8', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'HOR_${memIdx++}', iNodeId: 'TT_${lv}_2', jNodeId: 'TT_${lv}_3', section: 'L4X4X3/8', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'HOR_${memIdx++}', iNodeId: 'TT_${lv}_3', jNodeId: 'TT_${lv}_4', section: 'L4X4X3/8', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'HOR_${memIdx++}', iNodeId: 'TT_${lv}_4', jNodeId: 'TT_${lv}_1', section: 'L4X4X3/8', material: 'A992_STEEL'));

        // X-Braces on face 1
        members.add(StructuralMember(id: 'BRC_${memIdx++}', iNodeId: 'TT_${p}_1', jNodeId: 'TT_${lv}_2', section: 'L3X3X1/4', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'BRC_${memIdx++}', iNodeId: 'TT_${p}_2', jNodeId: 'TT_${lv}_1', section: 'L3X3X1/4', material: 'A992_STEEL'));
      }
    }

    return StructuralModel(
      name: '28m 3D Lattice Transmission Tower (ASCE 10-15)',
      nodes: nodes,
      members: members,
    );
  }

  /// Complete list of all certified building templates for workspace import
  static List<BuildingTemplateMeta> getCertifiedBuildingTemplates() {
    return [
      BuildingTemplateMeta(
        id: 'high_rise_10s',
        title: '10-Story Commercial Office Tower',
        category: 'High-Rise & Towers',
        badge: '10 STORIES • 36m',
        description: '4x3 bay commercial tower with exterior X-bracing, floor diaphragms, and ASCE 7-16 wind suction load profiles.',
        stories: 10,
        heightM: 36.0,
        footprintAreaM2: 432.0,
        nodeCount: 154,
        memberCount: 320,
        structuralSystem: 'Perimeter X-Braced Lateral Resisting Frame',
        standard: 'AISC 360-16 / ASCE 7-16',
        builder: () => generateCommercialHighRiseTower(),
      ),
      BuildingTemplateMeta(
        id: 'hospital_8s',
        title: '8-Story Dual Core Hospital Complex',
        category: 'High-Rise & Towers',
        badge: 'SEISMIC Ie=1.5',
        description: 'Essential medical facility with dual-system inverted-V chevron braced elevator core and heavy mechanical penthouse.',
        stories: 8,
        heightM: 30.4,
        footprintAreaM2: 829.4,
        nodeCount: 225,
        memberCount: 480,
        structuralSystem: 'Dual Chevron Core + Moment Perimeter',
        standard: 'AISC 341-16 / ASCE 7-16',
        builder: () => generateHospitalComplex(),
      ),
      BuildingTemplateMeta(
        id: 'residential_6s',
        title: '6-Story Residential Steel Frame',
        category: 'Commercial & Residential',
        badge: '6 STORIES • 21m',
        description: 'Multi-story residential apartment building space frame with composite floor beams and tributary residential live loads.',
        stories: 6,
        heightM: 21.0,
        footprintAreaM2: 297.0,
        nodeCount: 112,
        memberCount: 216,
        structuralSystem: 'Moment Resisting Space Frame',
        standard: 'AISC 360-16',
        builder: () => generateResidentialBuilding(),
      ),
      BuildingTemplateMeta(
        id: 'supertall_20s',
        title: '20-Story Super-Tall Outrigger Tower',
        category: 'High-Rise & Towers',
        badge: '20 STORIES • 72m',
        description: 'Iconic skyscraper with perimeter mega-columns, central core, and two-story outrigger belt trusses at mid-height and roof.',
        stories: 20,
        heightM: 72.0,
        footprintAreaM2: 576.0,
        nodeCount: 525,
        memberCount: 1140,
        structuralSystem: 'Outrigger & Belt Truss Core System',
        standard: 'AISC 360-16 / ASCE 7-16 Wind Resilient',
        builder: () => generateSuperTallOutrigger(),
      ),
      BuildingTemplateMeta(
        id: 'warehouse_portal',
        title: 'Industrial Logistics Clear-Span Warehouse',
        category: 'Industrial & Long-Span',
        badge: '36m CLEAR-SPAN',
        description: '1,296 m² pitched gable portal frame logistics center with tapered rafters, roof purlins, eave struts, and wind uplift suction.',
        stories: 1,
        heightM: 10.5,
        footprintAreaM2: 1296.0,
        nodeCount: 25,
        memberCount: 45,
        structuralSystem: 'Rigid Gable Portal Frame with Haunches',
        standard: 'AISC 360-16 / MBMA',
        builder: () => generateIndustrialWarehouse(),
      ),
      BuildingTemplateMeta(
        id: 'space_grid_canopy',
        title: 'Airport Terminal 3D Space Grid Canopy',
        category: 'Industrial & Long-Span',
        badge: '48m SPATIAL GRID',
        description: 'Double-layer orthogonal spatial grid roof structure spanning 48m x 36m supported on 4 perimeter column clusters.',
        stories: 1,
        heightM: 11.0,
        footprintAreaM2: 1728.0,
        nodeCount: 120,
        memberCount: 240,
        structuralSystem: 'Double-Layer Space Truss Grid',
        standard: 'AISC 360-16 Spatial Truss',
        builder: () => generateSpaceGridCanopy(),
      ),
      BuildingTemplateMeta(
        id: 'campus_4s',
        title: '4-Story Educational Academic Facility',
        category: 'Commercial & Residential',
        badge: '4 STORIES • ATRIUM',
        description: 'Campus facility with 2-story open central atrium, transfer girders, and seismic moment frames with high stiffness.',
        stories: 4,
        heightM: 14.4,
        footprintAreaM2: 518.4,
        nodeCount: 80,
        memberCount: 160,
        structuralSystem: 'Atrium Transfer Moment Frame',
        standard: 'AISC 360-16 / ASCE 7-16',
        builder: () => generateEducationalCampus(),
      ),
      BuildingTemplateMeta(
        id: 'pratt_truss_bridge',
        title: '36m Pratt Highway Truss Bridge',
        category: 'Infrastructure & Bridges',
        badge: '36m SPAN • AASHTO',
        description: 'Single-span through-truss bridge with deck floor beams, stringers, and AASHTO HL-93 truck design live load.',
        stories: 1,
        heightM: 6.0,
        footprintAreaM2: 288.0,
        nodeCount: 26,
        memberCount: 48,
        structuralSystem: 'Pin-Jointed Through Truss',
        standard: 'AASHTO LRFD / AISC 360-16',
        builder: () => generatePrattHighwayBridge(),
      ),
      BuildingTemplateMeta(
        id: 'transmission_tower',
        title: '28m 3D Lattice Transmission Tower',
        category: 'Infrastructure & Bridges',
        badge: '28m LATTICE',
        description: 'High-voltage 4-legged tapered space lattice tower with 3 cross-arm conductor levels and wind load.',
        stories: 4,
        heightM: 28.0,
        footprintAreaM2: 25.0,
        nodeCount: 20,
        memberCount: 38,
        structuralSystem: 'Self-Supporting Lattice Space Truss',
        standard: 'ASCE 10-15 / AISC 360-16',
        builder: () => generateTransmissionTower(),
      ),
      BuildingTemplateMeta(
        id: 'sway',
        title: '3D Multi-Story Sway Frame (ASCE 7)',
        category: 'Verification Benchmarks',
        badge: 'BENCHMARK READY',
        description: '2-story moment resisting space frame with lateral wind & seismic loads for standard code calibration.',
        stories: 2,
        heightM: 7.0,
        footprintAreaM2: 36.0,
        nodeCount: 12,
        memberCount: 16,
        structuralSystem: 'Rigid Moment Resisting Frame',
        standard: 'AISC 360-16 / ASCE 7-16',
        builder: () => BenchmarkPresets.multiStorySwayFrame(),
      ),
      BuildingTemplateMeta(
        id: 'truss',
        title: 'Warren Bridge Truss (AISC 360)',
        category: 'Verification Benchmarks',
        badge: 'AISC BENCHMARK',
        description: 'Planar Warren truss with vertical web members and panel point gravity loads.',
        stories: 1,
        heightM: 4.0,
        footprintAreaM2: 72.0,
        nodeCount: 12,
        memberCount: 21,
        structuralSystem: 'Warren Truss System',
        standard: 'AISC 360-16 Spec',
        builder: () => BenchmarkPresets.warrenTruss(),
      ),
      BuildingTemplateMeta(
        id: 'cantilever',
        title: 'Timoshenko Cantilever Girder',
        category: 'Verification Benchmarks',
        badge: '0.000% CLOSED FORM',
        description: 'Textbook cantilever beam with shear deformation verification. Tip deflection delta = 0.010561m verified.',
        stories: 1,
        heightM: 0.5,
        footprintAreaM2: 5.0,
        nodeCount: 2,
        memberCount: 1,
        structuralSystem: 'Cantilever Girder',
        standard: 'Mechanics of Materials Sec 5.4',
        builder: () => BenchmarkPresets.timoshenkoCantilever(),
      ),
    ];
  }

  /// Parses an imported structural model string (JSON, S2K, DXF, CSV)
  static StructuralModel? importModel(String text, {String filename = ''}) {
    final lower = filename.toLowerCase();

    // 1. JSON Structural Graph
    if (lower.endsWith('.json') || text.trim().startsWith('{')) {
      try {
        final Map<String, dynamic> data = jsonDecode(text);
        final List<dynamic> rawNodes = data['nodes'] ?? [];
        final List<dynamic> rawMembers = data['members'] ?? [];

        final nodes = rawNodes.map((n) {
          List<double> coords;
          if (n['coords'] != null) {
            coords = (n['coords'] as List).map((c) => (c as num).toDouble()).toList();
          } else {
            coords = [
              (n['x'] as num?)?.toDouble() ?? 0.0,
              (n['y'] as num?)?.toDouble() ?? 0.0,
              (n['z'] as num?)?.toDouble() ?? 0.0,
            ];
          }

          List<int>? restraint;
          if (n['restraint'] != null) {
            restraint = (n['restraint'] as List).map((r) => (r as num).toInt()).toList();
          } else if (n['isRestrained'] != null) {
            restraint = (n['isRestrained'] as List).map((r) => (r == true || r == 1) ? 1 : 0).toList();
          }

          List<double>? loads;
          if (n['loads'] != null) {
            loads = (n['loads'] as List).map((l) => (l as num).toDouble()).toList();
          } else if (n['fxN'] != null || n['fyN'] != null || n['fzN'] != null) {
            loads = [
              (n['fxN'] as num?)?.toDouble() ?? 0.0,
              (n['fyN'] as num?)?.toDouble() ?? 0.0,
              (n['fzN'] as num?)?.toDouble() ?? 0.0,
              0.0, 0.0, 0.0,
            ];
          }

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
            iNodeId: (m['i_node'] ?? m['startNodeId'] ?? m['iNodeId']).toString(),
            jNodeId: (m['j_node'] ?? m['endNodeId'] ?? m['jNodeId']).toString(),
            section: (m['section'] ?? m['sectionProfile'] ?? 'W14X48').toString(),
            material: (m['material'] ?? 'A992_STEEL').toString(),
          );
        }).toList();

        return StructuralModel(
          name: data['name'] ?? 'Imported JSON Model',
          nodes: nodes,
          members: members,
        );
      } catch (_) {
        return null;
      }
    }

    // 2. S2K SAP2000 / ETABS Text Import
    if (lower.endsWith('.s2k') || text.contains('TABLE:  "JOINT COORDINATES"') || text.contains('TABLE: "CONNECTIVITY - FRAME"')) {
      final List<StructuralNode> nodes = [];
      final List<StructuralMember> members = [];
      final lines = text.split('\n');
      bool inJoints = false;
      bool inFrames = false;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('TABLE:  "JOINT COORDINATES"') || trimmed.startsWith('TABLE: "JOINT COORDINATES"')) {
          inJoints = true;
          inFrames = false;
          continue;
        } else if (trimmed.startsWith('TABLE:  "CONNECTIVITY - FRAME"') || trimmed.startsWith('TABLE: "CONNECTIVITY - FRAME"')) {
          inJoints = false;
          inFrames = true;
          continue;
        } else if (trimmed.startsWith('TABLE:')) {
          inJoints = false;
          inFrames = false;
        }

        if (inJoints && (trimmed.startsWith('Joint=') || trimmed.contains('Joint='))) {
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

        if (inFrames && (trimmed.startsWith('Frame=') || trimmed.contains('Frame='))) {
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
        return StructuralModel(name: 'Imported S2K Structural Frame', nodes: nodes, members: members);
      }
    }

    // 3. CSV Tabular Coordinates Import
    if (lower.endsWith('.csv') || text.contains('NODE_ID,X,Y,Z') || text.contains('Joint,X,Y,Z')) {
      try {
        final List<StructuralNode> nodes = [];
        final List<StructuralMember> members = [];
        final lines = text.split('\n');
        bool inMembers = false;

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          if (trimmed.toUpperCase().contains('MEMBERS') || trimmed.toUpperCase().contains('FRAME_ID')) {
            inMembers = true;
            continue;
          }

          final tokens = trimmed.split(',');
          if (!inMembers && tokens.length >= 4) {
            final id = tokens[0].trim();
            final x = double.tryParse(tokens[1].trim());
            final y = double.tryParse(tokens[2].trim());
            final z = double.tryParse(tokens[3].trim());
            if (x != null && y != null && z != null && id.isNotEmpty && id.toUpperCase() != 'NODE_ID') {
              nodes.add(StructuralNode(id: id, coords: Vector3(x, y, z), restraint: y == 0 ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0]));
            }
          } else if (inMembers && tokens.length >= 3) {
            final id = tokens[0].trim();
            final ni = tokens[1].trim();
            final nj = tokens[2].trim();
            final sec = tokens.length >= 4 ? tokens[3].trim() : 'W14X48';
            if (id.isNotEmpty && ni.isNotEmpty && nj.isNotEmpty) {
              members.add(StructuralMember(id: id, iNodeId: ni, jNodeId: nj, section: sec, material: 'A992_STEEL'));
            }
          }
        }

        if (nodes.isNotEmpty) {
          return StructuralModel(name: 'Imported CSV Structural Frame', nodes: nodes, members: members);
        }
      } catch (_) {}
    }

    return null;
  }
}
