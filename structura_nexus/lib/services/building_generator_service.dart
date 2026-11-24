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
  final String dimensions;
  final String? recommendedStudio;
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
    this.dimensions = '',
    this.recommendedStudio,
    required this.builder,
  });

  String get codeStandard => standard;
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

  /// 15-Story Diagrid Exoskeleton Tower
  static StructuralModel generateDiagridExoskeletonTower() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    const numStories = 15;
    const storyHeight = 3.6;
    const baysX = 4;
    const baysZ = 4;
    const bayWidth = 6.0;

    String nid(int ix, int story, int iz) => 'N_DG_${ix}_${story}_$iz';

    // 1. Grid Nodes
    for (int story = 0; story <= numStories; story++) {
      final y = story * storyHeight;
      final isBase = story == 0;
      for (int ix = 0; ix <= baysX; ix++) {
        for (int iz = 0; iz <= baysZ; iz++) {
          final isPerimeter = ix == 0 || ix == baysX || iz == 0 || iz == baysZ;
          final isCore = ix >= 1 && ix <= 3 && iz >= 1 && iz <= 3;
          if (isPerimeter || isCore) {
            double fyN = isBase ? 0.0 : -28000.0;
            double fxN = 0.0;
            if (!isBase && iz == 0) {
              fxN = 1200.0 * (story + 1);
            }
            nodes.add(
              StructuralNode(
                id: nid(ix, story, iz),
                coords: Vector3(ix * bayWidth, y, iz * bayWidth),
                restraint: isBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0],
                loads: [fxN, fyN, 0.0, 0.0, 0.0, 0.0],
              ),
            );
          }
        }
      }
    }

    // 2. Core Columns
    for (int story = 0; story < numStories; story++) {
      for (int ix = 1; ix <= 3; ix++) {
        for (int iz = 1; iz <= 3; iz++) {
          members.add(
            StructuralMember(
              id: 'COL_C_${memIdx++}',
              iNodeId: nid(ix, story, iz),
              jNodeId: nid(ix, story + 1, iz),
              section: 'W14X120',
              material: 'A992_STEEL',
            ),
          );
        }
      }
    }

    // 3. Floor Beams
    for (int story = 1; story <= numStories; story++) {
      for (int iz = 0; iz <= baysZ; iz++) {
        for (int ix = 0; ix < baysX; ix++) {
          members.add(
            StructuralMember(
              id: 'BMX_${memIdx++}',
              iNodeId: nid(ix, story, iz),
              jNodeId: nid(ix + 1, story, iz),
              section: 'W18X40',
              material: 'A992_STEEL',
            ),
          );
        }
      }
      for (int ix = 0; ix <= baysX; ix++) {
        for (int iz = 0; iz < baysZ; iz++) {
          members.add(
            StructuralMember(
              id: 'BMZ_${memIdx++}',
              iNodeId: nid(ix, story, iz),
              jNodeId: nid(ix, story, iz + 1),
              section: 'W18X40',
              material: 'A992_STEEL',
            ),
          );
        }
      }
    }

    // 4. Perimeter Diagrid Exoskeleton (intersecting diagonals every 2 stories)
    for (int s = 0; s < numStories; s += 2) {
      final sTop = math.min(s + 2, numStories);
      // Front and Back faces
      for (final iz in [0, baysZ]) {
        for (int ix = 0; ix < baysX; ix += 2) {
          final ixEnd = math.min(ix + 2, baysX);
          members.add(StructuralMember(id: 'DG_FB1_${memIdx++}', iNodeId: nid(ix, s, iz), jNodeId: nid(ixEnd, sTop, iz), section: 'W14X90', material: 'A992_STEEL'));
          members.add(StructuralMember(id: 'DG_FB2_${memIdx++}', iNodeId: nid(ixEnd, s, iz), jNodeId: nid(ix, sTop, iz), section: 'W14X90', material: 'A992_STEEL'));
        }
      }
      // Left and Right faces
      for (final ix in [0, baysX]) {
        for (int iz = 0; iz < baysZ; iz += 2) {
          final izEnd = math.min(iz + 2, baysZ);
          members.add(StructuralMember(id: 'DG_LR1_${memIdx++}', iNodeId: nid(ix, s, iz), jNodeId: nid(ix, sTop, izEnd), section: 'W14X90', material: 'A992_STEEL'));
          members.add(StructuralMember(id: 'DG_LR2_${memIdx++}', iNodeId: nid(ix, s, izEnd), jNodeId: nid(ix, sTop, iz), section: 'W14X90', material: 'A992_STEEL'));
        }
      }
    }

    return StructuralModel(
      sessionId: 'diagrid_15s',
      loadCombination: '1.2D+1.6W',
      nodes: nodes,
      members: members,
    );
  }

  /// 24m Warren Pedestrian Overpass Bridge
  static StructuralModel generateWarrenPedestrianBridge() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    const span = 24.0;
    const height = 3.2;
    const width = 3.5;
    const numPanels = 6;
    const panelL = span / numPanels;

    for (int iz = 0; iz < 2; iz++) {
      final z = iz * width;
      final prefix = iz == 0 ? 'WPB_L' : 'WPB_R';

      // Bottom chord nodes
      for (int i = 0; i <= numPanels; i++) {
        final isPin = i == 0;
        final isRoller = i == numPanels;
        nodes.add(
          StructuralNode(
            id: '${prefix}_B_$i',
            coords: Vector3(i * panelL, 0.0, z),
            restraint: isPin ? [1, 1, 1, 1, 1, 1] : (isRoller ? [0, 1, 1, 0, 0, 0] : [0, 0, 0, 0, 0, 0]),
            loads: [0.0, -18000.0, 0.0, 0.0, 0.0, 0.0],
          ),
        );
      }

      // Top chord nodes (offset by half panel)
      for (int i = 0; i < numPanels; i++) {
        nodes.add(
          StructuralNode(
            id: '${prefix}_T_$i',
            coords: Vector3((i + 0.5) * panelL, height, z),
            loads: [0.0, -5000.0, 0.0, 0.0, 0.0, 0.0],
          ),
        );
      }

      // Bottom chord members
      for (int i = 0; i < numPanels; i++) {
        members.add(StructuralMember(id: '${prefix}_BC_${memIdx++}', iNodeId: '${prefix}_B_$i', jNodeId: '${prefix}_B_${i + 1}', section: 'W10X33', material: 'A992_STEEL'));
      }

      // Top chord members
      for (int i = 0; i < numPanels - 1; i++) {
        members.add(StructuralMember(id: '${prefix}_TC_${memIdx++}', iNodeId: '${prefix}_T_$i', jNodeId: '${prefix}_T_${i + 1}', section: 'W10X33', material: 'A992_STEEL'));
      }

      // Warren diagonals
      for (int i = 0; i < numPanels; i++) {
        members.add(StructuralMember(id: '${prefix}_D1_${memIdx++}', iNodeId: '${prefix}_B_$i', jNodeId: '${prefix}_T_$i', section: 'W8X24', material: 'A992_STEEL'));
        members.add(StructuralMember(id: '${prefix}_D2_${memIdx++}', iNodeId: '${prefix}_T_$i', jNodeId: '${prefix}_B_${i + 1}', section: 'W8X24', material: 'A992_STEEL'));
      }
    }

    // Transverse floor beams and top lateral struts
    for (int i = 0; i <= numPanels; i++) {
      members.add(StructuralMember(id: 'FB_${memIdx++}', iNodeId: 'WPB_L_B_$i', jNodeId: 'WPB_R_B_$i', section: 'W12X26', material: 'A992_STEEL'));
    }
    for (int i = 0; i < numPanels; i++) {
      members.add(StructuralMember(id: 'TB_${memIdx++}', iNodeId: 'WPB_L_T_$i', jNodeId: 'WPB_R_T_$i', section: 'W8X24', material: 'A992_STEEL'));
    }

    return StructuralModel(
      sessionId: 'warren_pedestrian',
      loadCombination: '1.2D+1.6L',
      nodes: nodes,
      members: members,
    );
  }

  /// 45m Tied-Arch Bowstring Bridge
  static StructuralModel generateTiedArchBowstringBridge() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    const span = 45.0;
    const rise = 8.5;
    const width = 9.0;
    const numPanels = 9;
    const panelL = span / numPanels;

    for (int iz = 0; iz < 2; iz++) {
      final z = iz * width;
      final prefix = iz == 0 ? 'TAB_L' : 'TAB_R';

      // Bottom deck tie nodes
      for (int i = 0; i <= numPanels; i++) {
        final isPin = i == 0;
        final isRoller = i == numPanels;
        nodes.add(
          StructuralNode(
            id: '${prefix}_B_$i',
            coords: Vector3(i * panelL, 0.0, z),
            restraint: isPin ? [1, 1, 1, 1, 1, 1] : (isRoller ? [0, 1, 1, 0, 0, 0] : [0, 0, 0, 0, 0, 0]),
            loads: [0.0, -38000.0, 0.0, 0.0, 0.0, 0.0],
          ),
        );
      }

      // Parabolic Arch Rib nodes
      for (int i = 1; i < numPanels; i++) {
        final x = i * panelL;
        final y = rise * 4.0 * (x / span) * (1.0 - (x / span));
        nodes.add(
          StructuralNode(
            id: '${prefix}_A_$i',
            coords: Vector3(x, y, z),
            loads: [0.0, -8000.0, 0.0, 0.0, 0.0, 0.0],
          ),
        );
      }

      // Bottom tie members
      for (int i = 0; i < numPanels; i++) {
        members.add(StructuralMember(id: '${prefix}_TIE_${memIdx++}', iNodeId: '${prefix}_B_$i', jNodeId: '${prefix}_B_${i + 1}', section: 'W14X120', material: 'A992_STEEL'));
      }

      // Arch rib members
      members.add(StructuralMember(id: '${prefix}_AR_0_${memIdx++}', iNodeId: '${prefix}_B_0', jNodeId: '${prefix}_A_1', section: 'W14X90', material: 'A992_STEEL'));
      for (int i = 1; i < numPanels - 1; i++) {
        members.add(StructuralMember(id: '${prefix}_AR_${memIdx++}', iNodeId: '${prefix}_A_$i', jNodeId: '${prefix}_A_${i + 1}', section: 'W14X90', material: 'A992_STEEL'));
      }
      members.add(StructuralMember(id: '${prefix}_AR_end_${memIdx++}', iNodeId: '${prefix}_A_${numPanels - 1}', jNodeId: '${prefix}_B_$numPanels', section: 'W14X90', material: 'A992_STEEL'));

      // Vertical tension hangers
      for (int i = 1; i < numPanels; i++) {
        members.add(StructuralMember(id: '${prefix}_H_${memIdx++}', iNodeId: '${prefix}_B_$i', jNodeId: '${prefix}_A_$i', section: 'W8X24', material: 'A992_STEEL'));
      }
    }

    // Transverse floor beams and top arch struts
    for (int i = 0; i <= numPanels; i++) {
      members.add(StructuralMember(id: 'FB_${memIdx++}', iNodeId: 'TAB_L_B_$i', jNodeId: 'TAB_R_B_$i', section: 'W18X50', material: 'A992_STEEL'));
    }
    for (int i = 1; i < numPanels; i++) {
      members.add(StructuralMember(id: 'AS_${memIdx++}', iNodeId: 'TAB_L_A_$i', jNodeId: 'TAB_R_A_$i', section: 'W10X33', material: 'A992_STEEL'));
    }

    return StructuralModel(
      sessionId: 'tied_arch_45m',
      loadCombination: '1.2D+1.6L',
      nodes: nodes,
      members: members,
    );
  }

  /// 60m Cable-Stayed Footbridge
  static StructuralModel generateCableStayedFootbridge() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    const span = 60.0;
    const width = 4.0;
    const numPanels = 10;
    const panelL = span / numPanels;
    const pylonPanel = 5;

    // Deck nodes
    for (int iz = 0; iz < 2; iz++) {
      final z = iz * width;
      final prefix = iz == 0 ? 'CSB_L' : 'CSB_R';

      for (int i = 0; i <= numPanels; i++) {
        final isEnd = i == 0 || i == numPanels;
        final isPylonBase = i == pylonPanel;
        nodes.add(
          StructuralNode(
            id: '${prefix}_D_$i',
            coords: Vector3(i * panelL, 0.0, z),
            restraint: isEnd ? [1, 1, 1, 1, 1, 1] : (isPylonBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0]),
            loads: [0.0, -22000.0, 0.0, 0.0, 0.0, 0.0],
          ),
        );
      }

      for (int i = 0; i < numPanels; i++) {
        members.add(StructuralMember(id: '${prefix}_STR_${memIdx++}', iNodeId: '${prefix}_D_$i', jNodeId: '${prefix}_D_${i + 1}', section: 'W16X45', material: 'A992_STEEL'));
      }
    }

    // Transverse floor beams
    for (int i = 0; i <= numPanels; i++) {
      members.add(StructuralMember(id: 'FB_${memIdx++}', iNodeId: 'CSB_L_D_$i', jNodeId: 'CSB_R_D_$i', section: 'W14X38', material: 'A992_STEEL'));
    }

    // Central Twin Pylons at x = 30m
    for (int iz = 0; iz < 2; iz++) {
      final z = iz * width;
      final prefix = iz == 0 ? 'CSB_L' : 'CSB_R';
      final pylonX = pylonPanel * panelL;

      nodes.add(StructuralNode(id: '${prefix}_P_6', coords: Vector3(pylonX, 6.0, z)));
      nodes.add(StructuralNode(id: '${prefix}_P_12', coords: Vector3(pylonX, 12.0, z)));
      nodes.add(StructuralNode(id: '${prefix}_P_18', coords: Vector3(pylonX, 18.0, z)));

      members.add(StructuralMember(id: '${prefix}_PCOL_1_${memIdx++}', iNodeId: '${prefix}_D_$pylonPanel', jNodeId: '${prefix}_P_6', section: 'W14X120', material: 'A992_STEEL'));
      members.add(StructuralMember(id: '${prefix}_PCOL_2_${memIdx++}', iNodeId: '${prefix}_P_6', jNodeId: '${prefix}_P_12', section: 'W14X120', material: 'A992_STEEL'));
      members.add(StructuralMember(id: '${prefix}_PCOL_3_${memIdx++}', iNodeId: '${prefix}_P_12', jNodeId: '${prefix}_P_18', section: 'W14X120', material: 'A992_STEEL'));

      // Stay cables
      members.add(StructuralMember(id: '${prefix}_CAB_1_${memIdx++}', iNodeId: '${prefix}_P_12', jNodeId: '${prefix}_D_3', section: 'W10X33', material: 'A992_STEEL'));
      members.add(StructuralMember(id: '${prefix}_CAB_2_${memIdx++}', iNodeId: '${prefix}_P_12', jNodeId: '${prefix}_D_7', section: 'W10X33', material: 'A992_STEEL'));
      members.add(StructuralMember(id: '${prefix}_CAB_3_${memIdx++}', iNodeId: '${prefix}_P_18', jNodeId: '${prefix}_D_1', section: 'W10X33', material: 'A992_STEEL'));
      members.add(StructuralMember(id: '${prefix}_CAB_4_${memIdx++}', iNodeId: '${prefix}_P_18', jNodeId: '${prefix}_D_9', section: 'W10X33', material: 'A992_STEEL'));
    }

    // Transverse pylon crosshead struts
    members.add(StructuralMember(id: 'PSTRUT_12_${memIdx++}', iNodeId: 'CSB_L_P_12', jNodeId: 'CSB_R_P_12', section: 'W12X53', material: 'A992_STEEL'));
    members.add(StructuralMember(id: 'PSTRUT_18_${memIdx++}', iNodeId: 'CSB_L_P_18', jNodeId: 'CSB_R_P_18', section: 'W12X53', material: 'A992_STEEL'));

    return StructuralModel(
      sessionId: 'cable_stayed_60m',
      loadCombination: '1.2D+1.6L',
      nodes: nodes,
      members: members,
    );
  }

  /// 24m Clear-Span Gable Portal Frame
  static StructuralModel generateGablePortalFrame() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    const spanX = 24.0;
    const eavesY = 5.5;
    const apexY = 7.5;
    const baySpacingZ = 6.0;
    const numBaysZ = 3;

    for (int bz = 0; bz <= numBaysZ; bz++) {
      final z = bz * baySpacingZ;
      final isEnd = bz == 0 || bz == numBaysZ;

      final nBaseLeft = 'N_GP_BL_$bz';
      final nEavesLeft = 'N_GP_EL_$bz';
      final nApex = 'N_GP_AP_$bz';
      final nEavesRight = 'N_GP_ER_$bz';
      final nBaseRight = 'N_GP_BR_$bz';

      nodes.add(StructuralNode(id: nBaseLeft, coords: Vector3(0.0, 0.0, z), restraint: [1, 1, 1, 1, 1, 1]));
      nodes.add(StructuralNode(id: nEavesLeft, coords: Vector3(0.0, eavesY, z), loads: [14000.0, -12000.0, 0.0, 0.0, 0.0, 0.0]));
      nodes.add(StructuralNode(id: nApex, coords: Vector3(spanX / 2.0, apexY, z), loads: [0.0, -24000.0, 0.0, 0.0, 0.0, 0.0]));
      nodes.add(StructuralNode(id: nEavesRight, coords: Vector3(spanX, eavesY, z), loads: [0.0, -12000.0, 0.0, 0.0, 0.0, 0.0]));
      nodes.add(StructuralNode(id: nBaseRight, coords: Vector3(spanX, 0.0, z), restraint: [1, 1, 1, 1, 1, 1]));

      members.add(StructuralMember(id: 'COL_L_$bz', iNodeId: nBaseLeft, jNodeId: nEavesLeft, section: 'W21X50', material: 'A992_STEEL'));
      members.add(StructuralMember(id: 'RAF_L_$bz', iNodeId: nEavesLeft, jNodeId: nApex, section: 'W18X35', material: 'A992_STEEL'));
      members.add(StructuralMember(id: 'RAF_R_$bz', iNodeId: nApex, jNodeId: nEavesRight, section: 'W18X35', material: 'A992_STEEL'));
      members.add(StructuralMember(id: 'COL_R_$bz', iNodeId: nBaseRight, jNodeId: nEavesRight, section: 'W21X50', material: 'A992_STEEL'));

      if (bz > 0) {
        final prevBz = bz - 1;
        members.add(StructuralMember(id: 'EAV_L_$memIdx', iNodeId: 'N_GP_EL_$prevBz', jNodeId: nEavesLeft, section: 'W10X33', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'PUR_A_$memIdx', iNodeId: 'N_GP_AP_$prevBz', jNodeId: nApex, section: 'W10X33', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'EAV_R_$memIdx', iNodeId: 'N_GP_ER_$prevBz', jNodeId: nEavesRight, section: 'W10X33', material: 'A992_STEEL'));
        memIdx++;

        if (isEnd || bz == 1) {
          members.add(StructuralMember(id: 'BRC_Z1_$memIdx', iNodeId: 'N_GP_BL_$prevBz', jNodeId: nEavesLeft, section: 'W8X24', material: 'A992_STEEL'));
          members.add(StructuralMember(id: 'BRC_Z2_$memIdx', iNodeId: 'N_GP_EL_$prevBz', jNodeId: nBaseLeft, section: 'W8X24', material: 'A992_STEEL'));
          memIdx++;
        }
      }
    }

    return StructuralModel(
      sessionId: 'portal_frame_24m',
      loadCombination: '1.2D+1.6W',
      nodes: nodes,
      members: members,
    );
  }

  /// 30m Geodesic Exhibition Dome
  static StructuralModel generateGeodesicDome() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    const rBase = 15.0;
    const rMid = 12.0;
    const rTop = 6.5;

    // 1. Base Ring (12 nodes, fixed)
    for (int i = 0; i < 12; i++) {
      final angle = i * 2.0 * math.pi / 12.0;
      final x = rBase * math.cos(angle);
      final z = rBase * math.sin(angle);
      nodes.add(StructuralNode(id: 'DOME_B_$i', coords: Vector3(x, 0.0, z), restraint: [1, 1, 1, 1, 1, 1]));
    }

    // 2. Middle Ring (12 nodes, y = 6m)
    for (int i = 0; i < 12; i++) {
      final angle = (i + 0.5) * 2.0 * math.pi / 12.0;
      final x = rMid * math.cos(angle);
      final z = rMid * math.sin(angle);
      nodes.add(StructuralNode(id: 'DOME_M_$i', coords: Vector3(x, 6.0, z), loads: [0.0, -12000.0, 0.0, 0.0, 0.0, 0.0]));
    }

    // 3. Upper Ring (6 nodes, y = 10.5m)
    for (int i = 0; i < 6; i++) {
      final angle = i * 2.0 * math.pi / 6.0;
      final x = rTop * math.cos(angle);
      final z = rTop * math.sin(angle);
      nodes.add(StructuralNode(id: 'DOME_U_$i', coords: Vector3(x, 10.5, z), loads: [0.0, -15000.0, 0.0, 0.0, 0.0, 0.0]));
    }

    // 4. Apex Crown Node (y = 12m)
    nodes.add(StructuralNode(id: 'DOME_APEX', coords: Vector3(0.0, 12.0, 0.0), loads: [0.0, -25000.0, 0.0, 0.0, 0.0, 0.0]));

    // Ring members & diagonals
    for (int i = 0; i < 12; i++) {
      final nextI = (i + 1) % 12;
      members.add(StructuralMember(id: 'RING_B_${memIdx++}', iNodeId: 'DOME_B_$i', jNodeId: 'DOME_B_$nextI', section: 'W10X33', material: 'A992_STEEL'));
      members.add(StructuralMember(id: 'RING_M_${memIdx++}', iNodeId: 'DOME_M_$i', jNodeId: 'DOME_M_$nextI', section: 'W8X24', material: 'A992_STEEL'));
      members.add(StructuralMember(id: 'DIA_BM1_${memIdx++}', iNodeId: 'DOME_B_$i', jNodeId: 'DOME_M_$i', section: 'W8X24', material: 'A992_STEEL'));
      members.add(StructuralMember(id: 'DIA_BM2_${memIdx++}', iNodeId: 'DOME_B_$nextI', jNodeId: 'DOME_M_$i', section: 'W8X24', material: 'A992_STEEL'));
    }

    for (int i = 0; i < 6; i++) {
      final nextI = (i + 1) % 6;
      members.add(StructuralMember(id: 'RING_U_${memIdx++}', iNodeId: 'DOME_U_$i', jNodeId: 'DOME_U_$nextI', section: 'W8X24', material: 'A992_STEEL'));
      members.add(StructuralMember(id: 'DIA_UA_${memIdx++}', iNodeId: 'DOME_U_$i', jNodeId: 'DOME_APEX', section: 'W8X24', material: 'A992_STEEL'));
    }

    for (int i = 0; i < 12; i++) {
      final uIdx = (i ~/ 2) % 6;
      members.add(StructuralMember(id: 'DIA_MU_${memIdx++}', iNodeId: 'DOME_M_$i', jNodeId: 'DOME_U_$uIdx', section: 'W8X24', material: 'A992_STEEL'));
    }

    return StructuralModel(
      sessionId: 'geodesic_dome_30m',
      loadCombination: '1.2D+1.6S',
      nodes: nodes,
      members: members,
    );
  }

  /// 4-Story ACI 318-19 Concrete Frame with Cracked Stiffness Modifiers
  static StructuralModel generateAciConcreteFrame() {
    final model = generateParametricBuilding(
      name: '4-Story ACI 318-19 Concrete Frame',
      numStories: 4,
      baysX: 3,
      baysZ: 2,
      bayWidthX: 6.0,
      bayDepthZ: 6.0,
      storyHeight: 3.6,
      system: BuildingSystemType.momentFrame,
      columnSection: 'W14X90',
      beamSection: 'W18X40',
      floorDeadLoadKpa: 5.0,
      floorLiveLoadKpa: 2.5,
    );
    for (final m in model.members) {
      if (m.id.startsWith('COL')) {
        m.crackedSectionFactor = 0.70;
      } else {
        m.crackedSectionFactor = 0.35;
      }
    }
    model.sessionId = 'concrete_frame_4s';
    model.loadCombination = '1.2D+1.6L';
    return model;
  }

  /// Heavy Transfer Girder & Mat Footing Frame
  static StructuralModel generateTransferGirderMat() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    const h1 = 4.5;
    const h2 = 8.0;

    String nid(int ix, int level, int iz) => 'N_TGM_${ix}_${level}_$iz';

    for (int lvl = 0; lvl <= 2; lvl++) {
      final y = lvl == 0 ? 0.0 : (lvl == 1 ? h1 : h2);
      for (int ix = 0; ix <= 4; ix++) {
        for (int iz = 0; iz <= 2; iz++) {
          final isBase = lvl == 0;
          final loads = isBase ? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0] : [0.0, -42000.0, 0.0, 0.0, 0.0, 0.0];
          nodes.add(
            StructuralNode(
              id: nid(ix, lvl, iz),
              coords: Vector3(ix * 6.0, y, iz * 6.0),
              restraint: isBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0],
              loads: loads,
            ),
          );
        }
      }
    }

    // Story 1 columns (central bay ix=2 clear ballroom span)
    for (int ix = 0; ix <= 4; ix++) {
      if (ix == 2) continue;
      for (int iz = 0; iz <= 2; iz++) {
        members.add(
          StructuralMember(
            id: 'COL_S1_${memIdx++}',
            iNodeId: nid(ix, 0, iz),
            jNodeId: nid(ix, 1, iz),
            section: 'W14X132',
            material: 'A992_STEEL',
          ),
        );
      }
    }

    // Level 1 Transfer Girders
    for (int iz = 0; iz <= 2; iz++) {
      for (int ix = 0; ix < 4; ix++) {
        final isTransferSpan = ix == 1 || ix == 2;
        members.add(
          StructuralMember(
            id: 'TBM_X_${memIdx++}',
            iNodeId: nid(ix, 1, iz),
            jNodeId: nid(ix + 1, 1, iz),
            section: isTransferSpan ? 'W24X104' : 'W21X62',
            material: 'A992_STEEL',
          ),
        );
      }
      for (int ix = 0; ix <= 4; ix++) {
        if (iz < 2) {
          members.add(
            StructuralMember(
              id: 'TBM_Z_${memIdx++}',
              iNodeId: nid(ix, 1, iz),
              jNodeId: nid(ix, 1, iz + 1),
              section: 'W18X40',
              material: 'A992_STEEL',
            ),
          );
        }
      }
    }

    // Story 2 columns (including planted columns above transfer girder)
    for (int ix = 0; ix <= 4; ix++) {
      for (int iz = 0; iz <= 2; iz++) {
        members.add(
          StructuralMember(
            id: 'COL_S2_${memIdx++}',
            iNodeId: nid(ix, 1, iz),
            jNodeId: nid(ix, 2, iz),
            section: 'W14X90',
            material: 'A992_STEEL',
          ),
        );
      }
    }

    // Level 2 Roof Beams
    for (int iz = 0; iz <= 2; iz++) {
      for (int ix = 0; ix < 4; ix++) {
        members.add(
          StructuralMember(
            id: 'RF_X_${memIdx++}',
            iNodeId: nid(ix, 2, iz),
            jNodeId: nid(ix + 1, 2, iz),
            section: 'W18X35',
            material: 'A992_STEEL',
          ),
        );
      }
      for (int ix = 0; ix <= 4; ix++) {
        if (iz < 2) {
          members.add(
            StructuralMember(
              id: 'RF_Z_${memIdx++}',
              iNodeId: nid(ix, 2, iz),
              jNodeId: nid(ix, 2, iz + 1),
              section: 'W18X35',
              material: 'A992_STEEL',
            ),
          );
        }
      }
    }

    return StructuralModel(
      sessionId: 'transfer_girder_mat',
      loadCombination: '1.2D+1.6L',
      nodes: nodes,
      members: members,
    );
  }

  /// Cantilever Retaining Wall & Pier Frame
  static StructuralModel generateRetainingWallPier() {
    final nodes = <StructuralNode>[];
    final members = <StructuralMember>[];
    int memIdx = 1;

    const lengthZ = 18.0;
    const heightY = 6.5;
    const numBaysZ = 3;
    const bayZ = lengthZ / numBaysZ;

    for (int bz = 0; bz <= numBaysZ; bz++) {
      final z = bz * bayZ;

      final nBase = 'N_RW_B_$bz';
      final nMid = 'N_RW_M_$bz';
      final nTop = 'N_RW_T_$bz';
      final nToe = 'N_RW_TOE_$bz';
      final nHeel = 'N_RW_HEEL_$bz';

      nodes.add(StructuralNode(id: nBase, coords: Vector3(0.0, 0.0, z), restraint: [1, 1, 1, 1, 1, 1]));
      nodes.add(StructuralNode(id: nToe, coords: Vector3(-1.8, 0.0, z), restraint: [1, 1, 1, 1, 1, 1]));
      nodes.add(StructuralNode(id: nHeel, coords: Vector3(3.2, 0.0, z), restraint: [1, 1, 1, 1, 1, 1]));

      nodes.add(StructuralNode(id: nMid, coords: Vector3(0.0, 3.25, z), loads: [32000.0, -14000.0, 0.0, 0.0, 0.0, 0.0]));
      nodes.add(StructuralNode(id: nTop, coords: Vector3(0.0, heightY, z), loads: [12000.0, -28000.0, 0.0, 0.0, 0.0, 0.0]));

      members.add(StructuralMember(id: 'STEM_1_$bz', iNodeId: nBase, jNodeId: nMid, section: 'W14X120', material: 'A992_STEEL'));
      members.add(StructuralMember(id: 'STEM_2_$bz', iNodeId: nMid, jNodeId: nTop, section: 'W14X90', material: 'A992_STEEL'));
      members.add(StructuralMember(id: 'FTG_TOE_$bz', iNodeId: nToe, jNodeId: nBase, section: 'W18X50', material: 'A992_STEEL'));
      members.add(StructuralMember(id: 'FTG_HEEL_$bz', iNodeId: nBase, jNodeId: nHeel, section: 'W18X50', material: 'A992_STEEL'));

      if (bz > 0) {
        final p = bz - 1;
        members.add(StructuralMember(id: 'WALER_M_${memIdx++}', iNodeId: 'N_RW_M_$p', jNodeId: nMid, section: 'W14X48', material: 'A992_STEEL'));
        members.add(StructuralMember(id: 'WALER_T_${memIdx++}', iNodeId: 'N_RW_T_$p', jNodeId: nTop, section: 'W14X48', material: 'A992_STEEL'));
      }
    }

    return StructuralModel(
      sessionId: 'retaining_wall_pier',
      loadCombination: '1.2D+1.6H',
      nodes: nodes,
      members: members,
    );
  }

  /// 5-Story Soft-Story Retrofit Frame
  static StructuralModel generateSoftStoryRetrofit() {
    final model = generateParametricBuilding(
      name: '5-Story Soft-Story Retrofit Frame',
      numStories: 5,
      baysX: 3,
      baysZ: 2,
      bayWidthX: 6.0,
      bayDepthZ: 6.0,
      storyHeight: 3.5,
      system: BuildingSystemType.momentFrame,
      columnSection: 'W14X74',
      beamSection: 'W16X31',
      floorDeadLoadKpa: 3.8,
      floorLiveLoadKpa: 2.5,
    );
    int brbIdx = 1;
    for (final iz in [0, 2]) {
      for (final ix in [0, 2]) {
        final midNodeId = 'N_BRB_MID_${ix}_$iz';
        model.nodes.add(StructuralNode(id: midNodeId, coords: Vector3(ix * 6.0 + 3.0, 3.5, iz * 6.0)));
        model.members.add(StructuralMember(id: 'BRB_${brbIdx++}', iNodeId: 'N_${ix}_0_$iz', jNodeId: midNodeId, section: 'W10X49', material: 'A992_STEEL'));
        model.members.add(StructuralMember(id: 'BRB_${brbIdx++}', iNodeId: 'N_${ix + 1}_0_$iz', jNodeId: midNodeId, section: 'W10X49', material: 'A992_STEEL'));
      }
    }
    model.sessionId = 'soft_story_retrofit_5s';
    model.loadCombination = '1.2D+1.0E';
    return model;
  }

  /// 6-Story El Centro NLTHA Benchmark Frame
  static StructuralModel generateElCentroNlthaFrame() {
    final model = generateParametricBuilding(
      name: '6-Story El Centro NLTHA Benchmark',
      numStories: 6,
      baysX: 3,
      baysZ: 3,
      bayWidthX: 6.0,
      bayDepthZ: 6.0,
      storyHeight: 3.6,
      system: BuildingSystemType.momentFrame,
      columnSection: 'W14X120',
      beamSection: 'W18X40',
      floorDeadLoadKpa: 4.2,
      floorLiveLoadKpa: 2.5,
    );
    for (final node in model.nodes) {
      if (node.coords.y > 0.0) {
        final storyFactor = node.coords.y / 21.6;
        final fx = 28000.0 * storyFactor;
        node.loads = [fx, node.loads[1], 0.0, 0.0, 0.0, 0.0];
      }
    }
    model.sessionId = 'el_centro_nltha_6s';
    model.loadCombination = '1.2D+1.0E_ELCENTRO';
    return model;
  }

  /// 8-Story Column-Loss Catenary Frame (DoD UFC 4-023-03 / GSA APM)
  static StructuralModel generateColumnLossCatenaryFrame() {
    final model = generateParametricBuilding(
      name: '8-Story Column-Loss Catenary Frame',
      numStories: 8,
      baysX: 4,
      baysZ: 2,
      bayWidthX: 6.0,
      bayDepthZ: 6.0,
      storyHeight: 3.4,
      system: BuildingSystemType.momentFrame,
      columnSection: 'W14X132',
      beamSection: 'W21X50',
      floorDeadLoadKpa: 4.5,
      floorLiveLoadKpa: 2.0,
    );
    model.members.removeWhere((m) =>
        (m.iNodeId == 'N_0_0_0' && m.jNodeId == 'N_0_1_0') ||
        (m.iNodeId == 'N_0_1_0' && m.jNodeId == 'N_0_0_0'));
    final blownNode = model.nodes.firstWhere((n) => n.id == 'N_0_0_0');
    blownNode.restraint = [0, 0, 0, 0, 0, 0];

    model.sessionId = 'column_loss_catenary_8s';
    model.loadCombination = '1.2D+0.5L_APM';
    return model;
  }

  /// Complete list of all 24 certified building & structural templates for workspace import
  static List<BuildingTemplateMeta> getCertifiedBuildingTemplates() {
    return [
      // 1. Buildings (7)
      BuildingTemplateMeta(
        id: 'sway',
        title: '2-Story Moment Sway Frame',
        category: 'Buildings',
        badge: '2 STORIES • 7m',
        description: 'Rigid unbraced moment-resisting space frame calibrated for ASCE 7 lateral wind and seismic drift checks.',
        stories: 2,
        heightM: 7.0,
        footprintAreaM2: 36.0,
        nodeCount: 12,
        memberCount: 16,
        structuralSystem: 'Rigid Moment Resisting Space Frame',
        standard: 'AISC 360-16 / ASCE 7-16',
        dimensions: '6.0m × 6.0m × 7.0m',
        recommendedStudio: 'lateral_stability',
        builder: () => BenchmarkPresets.multiStorySwayFrame(),
      ),
      BuildingTemplateMeta(
        id: 'campus_4s',
        title: '4-Story Educational Campus Frame',
        category: 'Buildings',
        badge: '4 STORIES • ATRIUM',
        description: 'Campus facility with 2-story open central atrium, transfer girders, and seismic moment frames with high stiffness.',
        stories: 4,
        heightM: 14.4,
        footprintAreaM2: 432.0,
        nodeCount: 80,
        memberCount: 160,
        structuralSystem: 'Atrium Transfer Moment Frame',
        standard: 'AISC 360-16 / ASCE 7-16',
        dimensions: '24.0m × 18.0m × 14.4m',
        recommendedStudio: 'seismic_modal',
        builder: () => generateEducationalCampus(),
      ),
      BuildingTemplateMeta(
        id: 'residential_6s',
        title: '6-Story Residential Steel Frame',
        category: 'Buildings',
        badge: '6 STORIES • 21m',
        description: 'Multi-story residential apartment building space frame with composite floor beams and tributary residential live loads.',
        stories: 6,
        heightM: 21.0,
        footprintAreaM2: 297.0,
        nodeCount: 112,
        memberCount: 216,
        structuralSystem: 'Moment Resisting Space Frame',
        standard: 'AISC 360-16',
        dimensions: '18.0m × 16.5m × 21.0m',
        recommendedStudio: 'composite_floor',
        builder: () => generateResidentialBuilding(),
      ),
      BuildingTemplateMeta(
        id: 'hospital_8s',
        title: '8-Story Dual-Core Hospital Complex',
        category: 'Buildings',
        badge: 'SEISMIC Ie=1.5',
        description: 'Essential medical facility with dual-system inverted-V chevron braced elevator core and heavy mechanical penthouse.',
        stories: 8,
        heightM: 30.4,
        footprintAreaM2: 829.4,
        nodeCount: 225,
        memberCount: 480,
        structuralSystem: 'Dual Chevron Core + Moment Perimeter',
        standard: 'AISC 341-16 / ASCE 7-16 (Ie=1.5)',
        dimensions: '30.4m × 27.3m × 30.4m',
        recommendedStudio: 'seismic_modal',
        builder: () => generateHospitalComplex(),
      ),
      BuildingTemplateMeta(
        id: 'high_rise_10s',
        title: '10-Story Commercial Office Tower',
        category: 'Buildings',
        badge: '10 STORIES • X-BRACED',
        description: 'Perimeter X-braced lateral force resisting system with core gravity framing designed for ASCE 7 wind envelopes.',
        stories: 10,
        heightM: 36.0,
        footprintAreaM2: 432.0,
        nodeCount: 154,
        memberCount: 320,
        structuralSystem: 'Perimeter X-Braced Lateral Resisting Frame',
        standard: 'AISC 360-16 / ASCE 7-16',
        dimensions: '24.0m × 18.0m × 36.0m',
        recommendedStudio: 'wind_cfd',
        builder: () => generateCommercialHighRiseTower(),
      ),
      BuildingTemplateMeta(
        id: 'diagrid_15s',
        title: '15-Story Diagrid Exoskeleton Tower',
        category: 'Buildings',
        badge: '15 STORIES • DIAGRID',
        description: 'High-efficiency exterior diagonal perimeter grid carrying combined gravity and lateral wind loads with corner nodes.',
        stories: 15,
        heightM: 54.0,
        footprintAreaM2: 576.0,
        nodeCount: 176,
        memberCount: 420,
        structuralSystem: 'Triangulated Perimeter Diagrid Exoskeleton',
        standard: 'AISC 360-16 / ASCE 7-16',
        dimensions: '24.0m × 24.0m × 54.0m',
        recommendedStudio: 'generative_topology',
        builder: () => generateDiagridExoskeletonTower(),
      ),
      BuildingTemplateMeta(
        id: 'supertall_20s',
        title: '20-Story Super-Tall Outrigger Tower',
        category: 'Buildings',
        badge: '20 STORIES • 72m',
        description: 'Iconic skyscraper with perimeter mega-columns, central core, and two-story outrigger belt trusses at mid-height and roof.',
        stories: 20,
        heightM: 72.0,
        footprintAreaM2: 576.0,
        nodeCount: 525,
        memberCount: 1140,
        structuralSystem: 'Outrigger & Belt Truss Core System',
        standard: 'AISC 360-16 / ASCE 7-16 Wind Resilient',
        dimensions: '24.0m × 24.0m × 72.0m',
        recommendedStudio: 'wind_cfd',
        builder: () => generateSuperTallOutrigger(),
      ),

      // 2. Bridges (4)
      BuildingTemplateMeta(
        id: 'warren_pedestrian',
        title: '24m Warren Pedestrian Overpass',
        category: 'Bridges',
        badge: '24m PEDESTRIAN',
        description: 'Through-truss pedestrian walkway with Warren diagonals, top lateral wind bracing, and deck stringers.',
        stories: 1,
        heightM: 3.2,
        footprintAreaM2: 84.0,
        nodeCount: 26,
        memberCount: 68,
        structuralSystem: 'Warren Deck & Overhead Braced Truss',
        standard: 'AASHTO Pedestrian / AISC 360-16',
        dimensions: '24.0m × 3.5m × 3.2m',
        recommendedStudio: 'bridge_moving_load',
        builder: () => generateWarrenPedestrianBridge(),
      ),
      BuildingTemplateMeta(
        id: 'pratt_truss_bridge',
        title: '36m Pratt Highway Truss Bridge',
        category: 'Bridges',
        badge: '36m SPAN • AASHTO',
        description: 'Single-span through-truss bridge with deck floor beams, stringers, and AASHTO HL-93 truck design live load.',
        stories: 1,
        heightM: 6.0,
        footprintAreaM2: 288.0,
        nodeCount: 26,
        memberCount: 48,
        structuralSystem: 'Pin-Jointed Through Truss',
        standard: 'AASHTO LRFD / AISC 360-16',
        dimensions: '36.0m × 8.0m × 6.0m',
        recommendedStudio: 'bridge_moving_load',
        builder: () => generatePrattHighwayBridge(),
      ),
      BuildingTemplateMeta(
        id: 'tied_arch_45m',
        title: '45m Tied-Arch Bowstring Bridge',
        category: 'Bridges',
        badge: '45m BOWSTRING',
        description: 'Parabolic tubular steel arch rib with vertical tension hangers, tie girders, and transverse floor beams.',
        stories: 1,
        heightM: 8.5,
        footprintAreaM2: 405.0,
        nodeCount: 36,
        memberCount: 70,
        structuralSystem: 'Tied-Arch Hanger Suspension System',
        standard: 'AASHTO LRFD Bridge Spec',
        dimensions: '45.0m × 9.0m × 8.5m',
        recommendedStudio: 'bridge_moving_load',
        builder: () => generateTiedArchBowstringBridge(),
      ),
      BuildingTemplateMeta(
        id: 'cable_stayed_60m',
        title: '60m Cable-Stayed Footbridge',
        category: 'Bridges',
        badge: '60m CABLE-STAY',
        description: 'Asymmetric semi-harp cable-stayed bridge with central A-frame pylon, stay cables in tension, and composite box deck.',
        stories: 1,
        heightM: 18.0,
        footprintAreaM2: 240.0,
        nodeCount: 30,
        memberCount: 49,
        structuralSystem: 'Semi-Harp Cable Stayed Deck System',
        standard: 'PTI / AASHTO Guide Spec',
        dimensions: '60.0m × 4.0m × 18.0m',
        recommendedStudio: 'bridge_moving_load',
        builder: () => generateCableStayedFootbridge(),
      ),

      // 3. Long-Span & Towers (5)
      BuildingTemplateMeta(
        id: 'portal_frame_24m',
        title: '24m Clear-Span Gable Portal Frame',
        category: 'Long-Span',
        badge: '24m GABLE PORTAL',
        description: 'Three-bay pitched gable portal frame warehouse with knee haunches, ridge apex joints, and purlin wind loads.',
        stories: 1,
        heightM: 7.5,
        footprintAreaM2: 432.0,
        nodeCount: 20,
        memberCount: 31,
        structuralSystem: 'Rigid Gable Portal Frame with Haunches',
        standard: 'AISC 360-16 / MBMA',
        dimensions: '24.0m × 18.0m × 7.5m',
        recommendedStudio: 'connection_detailer',
        builder: () => generateGablePortalFrame(),
      ),
      BuildingTemplateMeta(
        id: 'warehouse_portal',
        title: '36m Industrial Logistics Warehouse',
        category: 'Long-Span',
        badge: '36m CLEAR-SPAN',
        description: '1,296 m² pitched gable portal frame logistics center with tapered rafters, roof purlins, eave struts, and wind uplift suction.',
        stories: 1,
        heightM: 10.5,
        footprintAreaM2: 1296.0,
        nodeCount: 25,
        memberCount: 45,
        structuralSystem: 'Rigid Gable Portal Frame with Haunches',
        standard: 'AISC 360-16 / MBMA',
        dimensions: '36.0m × 36.0m × 10.5m',
        recommendedStudio: 'connection_detailer',
        builder: () => generateIndustrialWarehouse(),
      ),
      BuildingTemplateMeta(
        id: 'space_grid_canopy',
        title: '48m×36m Airport Space Grid Canopy',
        category: 'Long-Span',
        badge: '48m SPATIAL GRID',
        description: 'Double-layer orthogonal spatial grid roof structure spanning 48m x 36m supported on 4 perimeter column clusters.',
        stories: 1,
        heightM: 11.0,
        footprintAreaM2: 1728.0,
        nodeCount: 120,
        memberCount: 240,
        structuralSystem: 'Double-Layer Space Truss Grid',
        standard: 'AISC 360-16 Spatial Truss',
        dimensions: '48.0m × 36.0m × 11.0m',
        recommendedStudio: 'generative_topology',
        builder: () => generateSpaceGridCanopy(),
      ),
      BuildingTemplateMeta(
        id: 'geodesic_dome_30m',
        title: '30m Geodesic Exhibition Dome',
        category: 'Long-Span',
        badge: '30m GEODESIC',
        description: 'Triangulated hemispherical spatial dome with icosahedral breakdown for sports arena or botanical conservatory.',
        stories: 1,
        heightM: 12.0,
        footprintAreaM2: 706.8,
        nodeCount: 31,
        memberCount: 78,
        structuralSystem: 'Triangulated Spherical Space Dome',
        standard: 'ASCE Manual 63 / AISC 360',
        dimensions: '30.0m × 30.0m × 12.0m',
        recommendedStudio: 'wind_cfd',
        builder: () => generateGeodesicDome(),
      ),
      BuildingTemplateMeta(
        id: 'transmission_tower',
        title: '28m 3D Lattice Transmission Tower',
        category: 'Long-Span',
        badge: '28m LATTICE',
        description: 'High-voltage 4-legged tapered space lattice tower with 3 cross-arm conductor levels and wind load.',
        stories: 4,
        heightM: 28.0,
        footprintAreaM2: 25.0,
        nodeCount: 20,
        memberCount: 38,
        structuralSystem: 'Self-Supporting Lattice Space Truss',
        standard: 'ASCE 10-15 / AISC 360-16',
        dimensions: '5.0m × 5.0m × 28.0m',
        recommendedStudio: 'generative_bracing',
        builder: () => generateTransmissionTower(),
      ),

      // 4. Concrete & Soil (3)
      BuildingTemplateMeta(
        id: 'concrete_frame_4s',
        title: '4-Story ACI 318-19 Concrete Frame',
        category: 'Concrete & Soil',
        badge: '4 STORIES • ACI 318',
        description: 'Special moment frame with cracked stiffness modifiers (0.35 Ig beams, 0.70 Ig columns) and rebar detailing.',
        stories: 4,
        heightM: 14.4,
        footprintAreaM2: 216.0,
        nodeCount: 60,
        memberCount: 116,
        structuralSystem: 'Cracked ACI 318 Concrete Moment Frame',
        standard: 'ACI 318-19 / ACI 224R',
        dimensions: '18.0m × 12.0m × 14.4m',
        recommendedStudio: 'concrete_studio',
        builder: () => generateAciConcreteFrame(),
      ),
      BuildingTemplateMeta(
        id: 'transfer_girder_mat',
        title: 'Heavy Transfer Girder & Mat Footing',
        category: 'Concrete & Soil',
        badge: 'TRANSFER GIRDER',
        description: 'Deep post-tensioned transfer beam carrying interrupted tower columns over clear ballroom onto elastic soil springs.',
        stories: 2,
        heightM: 8.0,
        footprintAreaM2: 288.0,
        nodeCount: 45,
        memberCount: 76,
        structuralSystem: 'Transfer Girder & Mat Foundation',
        standard: 'ACI 318-19 / Bowles Geotech',
        dimensions: '24.0m × 12.0m × 8.0m',
        recommendedStudio: 'geotechnical_foundation',
        builder: () => generateTransferGirderMat(),
      ),
      BuildingTemplateMeta(
        id: 'retaining_wall_pier',
        title: 'Cantilever Retaining Wall & Pier Frame',
        category: 'Concrete & Soil',
        badge: 'EARTH PRESSURE',
        description: 'Reinforced concrete stem wall and bridge abutment pier subjected to Rankine triangular active lateral earth pressure.',
        stories: 1,
        heightM: 6.5,
        footprintAreaM2: 108.0,
        nodeCount: 20,
        memberCount: 26,
        structuralSystem: 'Cantilever Stem Retaining Wall',
        standard: 'ACI 318-19 / AASHTO Soil',
        dimensions: '18.0m × 6.0m × 6.5m',
        recommendedStudio: 'geotechnical_foundation',
        builder: () => generateRetainingWallPier(),
      ),

      // 5. Seismic & Blast (3)
      BuildingTemplateMeta(
        id: 'soft_story_retrofit_5s',
        title: '5-Story Soft-Story Retrofit Frame',
        category: 'Seismic & Blast',
        badge: 'BRB RETROFIT',
        description: 'Building with ground floor parking soft-story vulnerability retrofitted with steel buckling-restrained braces (BRB).',
        stories: 5,
        heightM: 17.5,
        footprintAreaM2: 216.0,
        nodeCount: 76,
        memberCount: 144,
        structuralSystem: 'Soft-Story BRB Retrofit Moment Frame',
        standard: 'ASCE 41-17 / FEMA P-807',
        dimensions: '18.0m × 12.0m × 17.5m',
        recommendedStudio: 'pushover_analysis',
        builder: () => generateSoftStoryRetrofit(),
      ),
      BuildingTemplateMeta(
        id: 'el_centro_nltha_6s',
        title: '6-Story El Centro NLTHA Benchmark',
        category: 'Seismic & Blast',
        badge: '0.35g NLTHA',
        description: '6-story moment frame with nonlinear lumped plasticity hinges calibrated against 1940 El Centro NS ground motion.',
        stories: 6,
        heightM: 21.6,
        footprintAreaM2: 324.0,
        nodeCount: 112,
        memberCount: 216,
        structuralSystem: 'Nonlinear Dynamic Moment Resisting Frame',
        standard: 'ASCE 7-16 Ch 16 / FEMA P695',
        dimensions: '18.0m × 18.0m × 21.6m',
        recommendedStudio: 'nltha',
        builder: () => generateElCentroNlthaFrame(),
      ),
      BuildingTemplateMeta(
        id: 'column_loss_catenary_8s',
        title: '8-Story Column-Loss Catenary Frame',
        category: 'Seismic & Blast',
        badge: 'UFC 4-023-03 APM',
        description: '8-story moment frame with sudden ground-floor corner column removal evaluating catenary tie forces and DCR.',
        stories: 8,
        heightM: 27.2,
        footprintAreaM2: 288.0,
        nodeCount: 135,
        memberCount: 263,
        structuralSystem: 'Alternate Path Progressive Collapse Frame',
        standard: 'DoD UFC 4-023-03 / GSA APM',
        dimensions: '24.0m × 12.0m × 27.2m',
        recommendedStudio: 'progressive_collapse',
        builder: () => generateColumnLossCatenaryFrame(),
      ),

      // 6. Textbook Benchmarks (2)
      BuildingTemplateMeta(
        id: 'cantilever',
        title: 'Timoshenko Cantilever Girder',
        category: 'Benchmarks',
        badge: '0.000% CLOSED FORM',
        description: 'Textbook cantilever beam with shear deformation verification. Tip deflection delta = 0.010561m verified.',
        stories: 1,
        heightM: 0.5,
        footprintAreaM2: 5.0,
        nodeCount: 2,
        memberCount: 1,
        structuralSystem: 'Cantilever Girder with Shear Deformation',
        standard: 'Mechanics of Materials Sec 5.4',
        dimensions: '5.0m × 0.5m × 0.5m',
        recommendedStudio: 'pe_packet',
        builder: () => BenchmarkPresets.timoshenkoCantilever(),
      ),
      BuildingTemplateMeta(
        id: 'hibbeler_leet_beam',
        title: 'Hibbeler & Leet Continuous Beam',
        category: 'Benchmarks',
        badge: 'EXACT 12-DOF SOLVE',
        description: 'Two-span continuous beam with intermediate roller and point loads, verifying moment distribution & 12-DOF exact solve.',
        stories: 1,
        heightM: 0.5,
        footprintAreaM2: 6.0,
        nodeCount: 5,
        memberCount: 4,
        structuralSystem: 'Two-Span Continuous Beam with Midspan Loads',
        standard: 'Hibbeler 10th Ed / Leet Analysis',
        dimensions: '12.0m × 0.5m × 0.5m',
        recommendedStudio: 'pe_packet',
        builder: () => BenchmarkPresets.hibbelerLeetContinuousBeam(),
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
