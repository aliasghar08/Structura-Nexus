import 'package:vector_math/vector_math_64.dart';
import '../models/structural_models.dart';

class BenchmarkPresets {
  static StructuralModel multiStorySwayFrame() {
    final nodes = [
      // Ground supports (fixed)
      StructuralNode(id: 'N1', coords: Vector3(0.0, 0.0, 0.0), restraint: [1, 1, 1, 1, 1, 1]),
      StructuralNode(id: 'N2', coords: Vector3(6.0, 0.0, 0.0), restraint: [1, 1, 1, 1, 1, 1]),
      StructuralNode(id: 'N3', coords: Vector3(0.0, 0.0, 6.0), restraint: [1, 1, 1, 1, 1, 1]),
      StructuralNode(id: 'N4', coords: Vector3(6.0, 0.0, 6.0), restraint: [1, 1, 1, 1, 1, 1]),

      // Story 1 joints (y = 3.5m)
      StructuralNode(
        id: 'N5',
        coords: Vector3(0.0, 3.5, 0.0),
        loads: [12000.0, -35000.0, 0.0, 0.0, 0.0, 0.0],
      ),
      StructuralNode(
        id: 'N6',
        coords: Vector3(6.0, 3.5, 0.0),
        loads: [0.0, -35000.0, 0.0, 0.0, 0.0, 0.0],
      ),
      StructuralNode(
        id: 'N7',
        coords: Vector3(0.0, 3.5, 6.0),
        loads: [12000.0, -35000.0, 0.0, 0.0, 0.0, 0.0],
      ),
      StructuralNode(
        id: 'N8',
        coords: Vector3(6.0, 3.5, 6.0),
        loads: [0.0, -35000.0, 0.0, 0.0, 0.0, 0.0],
      ),

      // Story 2 roof joints (y = 7.0m)
      StructuralNode(
        id: 'N9',
        coords: Vector3(0.0, 7.0, 0.0),
        loads: [18000.0, -25000.0, 0.0, 0.0, 0.0, 0.0],
      ),
      StructuralNode(
        id: 'N10',
        coords: Vector3(6.0, 7.0, 0.0),
        loads: [0.0, -25000.0, 0.0, 0.0, 0.0, 0.0],
      ),
      StructuralNode(
        id: 'N11',
        coords: Vector3(0.0, 7.0, 6.0),
        loads: [18000.0, -25000.0, 0.0, 0.0, 0.0, 0.0],
      ),
      StructuralNode(
        id: 'N12',
        coords: Vector3(6.0, 7.0, 6.0),
        loads: [0.0, -25000.0, 0.0, 0.0, 0.0, 0.0],
      ),
    ];

    final members = [
      // Story 1 columns
      StructuralMember(id: 'COL_1', iNodeId: 'N1', jNodeId: 'N5', section: 'W14X68'),
      StructuralMember(id: 'COL_2', iNodeId: 'N2', jNodeId: 'N6', section: 'W14X68'),
      StructuralMember(id: 'COL_3', iNodeId: 'N3', jNodeId: 'N7', section: 'W14X68'),
      StructuralMember(id: 'COL_4', iNodeId: 'N4', jNodeId: 'N8', section: 'W14X68'),

      // Story 1 floor beams
      StructuralMember(id: 'BM_1', iNodeId: 'N5', jNodeId: 'N6', section: 'W14X38'),
      StructuralMember(id: 'BM_2', iNodeId: 'N6', jNodeId: 'N8', section: 'W14X30'),
      StructuralMember(id: 'BM_3', iNodeId: 'N8', jNodeId: 'N7', section: 'W14X38'),
      StructuralMember(id: 'BM_4', iNodeId: 'N7', jNodeId: 'N5', section: 'W14X30'),

      // Story 2 columns
      StructuralMember(id: 'COL_5', iNodeId: 'N5', jNodeId: 'N9', section: 'W14X48'),
      StructuralMember(id: 'COL_6', iNodeId: 'N6', jNodeId: 'N10', section: 'W14X48'),
      StructuralMember(id: 'COL_7', iNodeId: 'N7', jNodeId: 'N11', section: 'W14X48'),
      StructuralMember(id: 'COL_8', iNodeId: 'N8', jNodeId: 'N12', section: 'W14X48'),

      // Story 2 roof beams
      StructuralMember(id: 'BM_5', iNodeId: 'N9', jNodeId: 'N10', section: 'W14X30'),
      StructuralMember(id: 'BM_6', iNodeId: 'N10', jNodeId: 'N12', section: 'W12X26'),
      StructuralMember(id: 'BM_7', iNodeId: 'N12', jNodeId: 'N11', section: 'W14X30'),
      StructuralMember(id: 'BM_8', iNodeId: 'N11', jNodeId: 'N9', section: 'W12X26'),
    ];

    return StructuralModel(
      sessionId: 'preset_multi_story_sway',
      loadCombination: '1.2D+1.6L',
      nodes: nodes,
      members: members,
      deformationScale: 40.0,
      displayMode: DisplayMode.deformed,
    );
  }

  static StructuralModel timoshenkoCantilever() {
    return StructuralModel(
      sessionId: 'preset_timoshenko_cantilever',
      loadCombination: '1.0D',
      nodes: [
        StructuralNode(id: 'N1', coords: Vector3(0.0, 0.0, 0.0), restraint: [1, 1, 1, 1, 1, 1]),
        StructuralNode(id: 'N2', coords: Vector3(5.0, 0.0, 0.0), loads: [0.0, -25000.0, 0.0, 0.0, 0.0, 0.0]),
      ],
      members: [
        StructuralMember(id: 'M1', iNodeId: 'N1', jNodeId: 'N2', section: 'W14X48'),
      ],
      deformationScale: 25.0,
      displayMode: DisplayMode.bmdRibbon,
    );
  }

  static StructuralModel warrenTruss() {
    final nodes = [
      // Bottom chord
      StructuralNode(id: 'N1', coords: Vector3(0.0, 0.0, 0.0), restraint: [1, 1, 1, 0, 0, 0]),
      StructuralNode(id: 'N2', coords: Vector3(3.0, 0.0, 0.0)),
      StructuralNode(id: 'N3', coords: Vector3(6.0, 0.0, 0.0)),
      StructuralNode(id: 'N4', coords: Vector3(9.0, 0.0, 0.0), restraint: [0, 1, 1, 0, 0, 0]),

      // Top chord
      StructuralNode(id: 'N5', coords: Vector3(1.5, 2.5, 0.0), loads: [0.0, -40000.0, 0.0, 0.0, 0.0, 0.0]),
      StructuralNode(id: 'N6', coords: Vector3(4.5, 2.5, 0.0), loads: [0.0, -60000.0, 0.0, 0.0, 0.0, 0.0]),
      StructuralNode(id: 'N7', coords: Vector3(7.5, 2.5, 0.0), loads: [0.0, -40000.0, 0.0, 0.0, 0.0, 0.0]),
    ];

    final members = [
      // Bottom chord
      StructuralMember(id: 'BC_1', iNodeId: 'N1', jNodeId: 'N2', section: 'W10X33'),
      StructuralMember(id: 'BC_2', iNodeId: 'N2', jNodeId: 'N3', section: 'W10X33'),
      StructuralMember(id: 'BC_3', iNodeId: 'N3', jNodeId: 'N4', section: 'W10X33'),

      // Top chord
      StructuralMember(id: 'TC_1', iNodeId: 'N5', jNodeId: 'N6', section: 'W12X26'),
      StructuralMember(id: 'TC_2', iNodeId: 'N6', jNodeId: 'N7', section: 'W12X26'),

      // Diagonals / Webs
      StructuralMember(id: 'WEB_1', iNodeId: 'N1', jNodeId: 'N5', section: 'W10X33'),
      StructuralMember(id: 'WEB_2', iNodeId: 'N5', jNodeId: 'N2', section: 'W10X33'),
      StructuralMember(id: 'WEB_3', iNodeId: 'N2', jNodeId: 'N6', section: 'W10X33'),
      StructuralMember(id: 'WEB_4', iNodeId: 'N6', jNodeId: 'N3', section: 'W10X33'),
      StructuralMember(id: 'WEB_5', iNodeId: 'N3', jNodeId: 'N7', section: 'W10X33'),
      StructuralMember(id: 'WEB_6', iNodeId: 'N7', jNodeId: 'N4', section: 'W10X33'),
    ];

    return StructuralModel(
      sessionId: 'preset_warren_truss',
      loadCombination: '1.2D+1.6L',
      nodes: nodes,
      members: members,
      deformationScale: 50.0,
      displayMode: DisplayMode.aiscCompliance,
    );
  }
}
