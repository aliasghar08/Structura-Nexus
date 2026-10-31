import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../models/structural_models.dart';
import '../services/workspace_storage.dart';

enum CadTool {
  select,
  drawBeam,
  addJoint,
  assignSupport,
  applyLoad,
}

enum CadPlane {
  isometric3D,
  planXY,
  elevationXZ,
  sideYZ,
}

class StructuralCadEditorDialog extends StatefulWidget {
  final StructuralModel initialModel;
  final Function(StructuralModel updatedModel) onModelCommitted;

  const StructuralCadEditorDialog({
    super.key,
    required this.initialModel,
    required this.onModelCommitted,
  });

  @override
  State<StructuralCadEditorDialog> createState() => _StructuralCadEditorDialogState();
}

class _StructuralCadEditorDialogState extends State<StructuralCadEditorDialog> {
  late List<StructuralNode> _nodes;
  late List<StructuralMember> _members;
  late String _modelName;

  // History stack for Undo / Redo
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];

  // Workspace Customization & Position Memory
  bool _isCadToolbarExpanded = true;
  double _cadToolbarTopOffset = 12.0;

  // Active Tool & Plane
  CadTool _activeTool = CadTool.select;
  CadPlane _activePlane = CadPlane.isometric3D;
  String _selectedSection = 'W14X48';

  // Precision Snaps
  bool _snapToGrid = true;
  bool _orthoMode = false;
  double _gridSpacing = 1.0; // meters

  // Interaction State
  String? _selectedNodeId;
  String? _selectedMemberId;
  StructuralNode? _drawStartNode;
  vm.Vector3? _hoverWorldPos;

  // Camera Orbit / Pan / Zoom
  double _yaw = 0.75;
  double _pitch = 0.35;
  double _zoom = 38.0;
  Offset _panOffset = const Offset(0, 30);
  Offset? _lastPan;

  // Command Console
  final TextEditingController _cmdController = TextEditingController();
  final List<String> _consoleLogs = [
    'STRUCTURA CAD/BIM GENERATIVE ENGINE v3.4 READY.',
    'Type AutoCAD commands (e.g. LINE 0,0,0 6,0,0) or Natural Directives (e.g. "add 3-story frame").',
  ];

  @override
  void initState() {
    super.initState();
    _isCadToolbarExpanded = WorkspacePreferences.getBool('cad_studio_tools_expanded', true);
    _cadToolbarTopOffset = WorkspacePreferences.getDouble('cad_studio_tools_top', 12.0);
    _modelName = widget.initialModel.name;
    _nodes = widget.initialModel.nodes.map((n) => n.copyWith()).toList();
    _members = widget.initialModel.members.map((m) => m.copyWith()).toList();
  }

  @override
  void dispose() {
    _cmdController.dispose();
    super.dispose();
  }

  void _saveSnapshot() {
    _undoStack.add({
      'name': _modelName,
      'nodes': _nodes.map((n) => n.copyWith()).toList(),
      'members': _members.map((m) => m.copyWith()).toList(),
    });
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final current = {
      'name': _modelName,
      'nodes': _nodes.map((n) => n.copyWith()).toList(),
      'members': _members.map((m) => m.copyWith()).toList(),
    };
    _redoStack.add(current);
    final previous = _undoStack.removeLast();
    setState(() {
      _modelName = previous['name'];
      _nodes = previous['nodes'];
      _members = previous['members'];
      _selectedNodeId = null;
      _selectedMemberId = null;
      _drawStartNode = null;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final current = {
      'name': _modelName,
      'nodes': _nodes.map((n) => n.copyWith()).toList(),
      'members': _members.map((m) => m.copyWith()).toList(),
    };
    _undoStack.add(current);
    final next = _redoStack.removeLast();
    setState(() {
      _modelName = next['name'];
      _nodes = next['nodes'];
      _members = next['members'];
    });
  }

  // --- AI Command Line Parser (AutoCAD & Generative AI) ---

  void _executeCommand(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return;
    _cmdController.clear();
    _consoleLogs.add('> $raw');

    final lower = raw.toLowerCase();

    _saveSnapshot();

    try {
      if (lower.startsWith('line ') || lower.startsWith('l ')) {
        // e.g. LINE 0,0,0 6,4,0 [W16X26]
        final parts = raw.split(' ').where((s) => s.isNotEmpty).toList();
        if (parts.length >= 3) {
          final p1 = _parseCoords(parts[1]);
          final p2 = _parseCoords(parts[2]);
          final sec = parts.length >= 4 ? parts[3].toUpperCase() : _selectedSection;

          final n1 = _getOrCreateNode(p1.x, p1.y, p1.z);
          final n2 = _getOrCreateNode(p2.x, p2.y, p2.z);
          final mId = 'M${_members.length + 1}';
          _members.add(StructuralMember(id: mId, startNodeId: n1.id, endNodeId: n2.id, sectionProfile: sec));
          _consoleLogs.add('✓ Created member $mId from ${n1.id} to ${n2.id} ($sec)');
        }
      } else if (lower.startsWith('point ') || lower.startsWith('pt ') || lower.startsWith('joint ')) {
        // e.g. POINT 6,4,0
        final parts = raw.split(' ').where((s) => s.isNotEmpty).toList();
        if (parts.length >= 2) {
          final p = _parseCoords(parts[1]);
          final n = _getOrCreateNode(p.x, p.y, p.z);
          _consoleLogs.add('✓ Created joint ${n.id} at (${p.x}, ${p.y}, ${p.z})');
        }
      } else if (lower.contains('fix base') || lower.contains('fix all bases') || lower.contains('fix footings')) {
        int count = 0;
        for (int i = 0; i < _nodes.length; i++) {
          if (_nodes[i].y <= 0.05) {
            _nodes[i] = _nodes[i].copyWith(isRestrained: [true, true, true, true, true, true]);
            count++;
          }
        }
        _consoleLogs.add('✓ Fixed 6-DOF boundary restraints on $count base joints.');
      } else if (lower.contains('pin base') || lower.contains('pin footings')) {
        int count = 0;
        for (int i = 0; i < _nodes.length; i++) {
          if (_nodes[i].y <= 0.05) {
            _nodes[i] = _nodes[i].copyWith(isRestrained: [true, true, true, false, false, false]);
            count++;
          }
        }
        _consoleLogs.add('✓ Applied pinned footings to $count base joints.');
      } else if (lower.startsWith('wind ') || lower.contains('lateral load')) {
        // e.g. WIND 25 (apply 25kN wind load to top nodes)
        final numMatch = RegExp(r'[-+]?\d*\.?\d+').firstMatch(raw);
        final valKn = numMatch != null ? double.parse(numMatch.group(0)!) : 20.0;
        final valN = valKn * 1000.0;
        double maxY = _nodes.map((n) => n.y).fold(0.0, math.max);
        int count = 0;
        for (int i = 0; i < _nodes.length; i++) {
          if ((_nodes[i].y - maxY).abs() < 0.1 && _nodes[i].x <= 0.1) {
            _nodes[i] = _nodes[i].copyWith(fxN: valN);
            count++;
          }
        }
        _consoleLogs.add('✓ Applied lateral wind load ${valKn}kN at $count roof joints (Y = ${maxY}m).');
      } else if (lower.contains('frame') || lower.contains('story') || lower.contains('bay')) {
        // AI Generative Frame Generator
        // e.g. "add 3-story frame" or "3-bay 2-story frame"
        int stories = 2;
        int bays = 2;
        double bayWidth = 6.0;
        double storyHeight = 3.5;

        if (lower.contains('1-story') || lower.contains('1 story')) stories = 1;
        if (lower.contains('2-story') || lower.contains('2 story')) stories = 2;
        if (lower.contains('3-story') || lower.contains('3 story')) stories = 3;
        if (lower.contains('4-story') || lower.contains('4 story')) stories = 4;

        if (lower.contains('1-bay') || lower.contains('1 bay')) bays = 1;
        if (lower.contains('2-bay') || lower.contains('2 bay')) bays = 2;
        if (lower.contains('3-bay') || lower.contains('3 bay')) bays = 3;

        _generateMultiBayFrame(bays: bays, stories: stories, bayWidth: bayWidth, storyHeight: storyHeight);
        _consoleLogs.add('✓ AI Generative: Synthesized $bays-bay x $stories-story frame (Span ${bayWidth}m, Story ${storyHeight}m).');
      } else if (lower.contains('cross-bracing') || lower.contains('bracing') || lower.contains('brace')) {
        _generateCrossBracing();
        _consoleLogs.add('✓ AI Generative: Injected diagonal X-bracing along external bays.');
      } else if (lower.startsWith('subdivide') || lower.startsWith('div ')) {
        _subdivideSelectedMember(2);
        _consoleLogs.add('✓ Subdivided selected member into 2 continuous elements.');
      } else {
        _consoleLogs.add('⚠ Unrecognized directive. Try: LINE, POINT, FIX BASE, WIND 25, "add 3-story frame", or BRACE.');
      }
    } catch (e) {
      _consoleLogs.add('❌ Command error: $e');
    }

    setState(() {});
  }

  vm.Vector3 _parseCoords(String token) {
    final parts = token.replaceAll('(', '').replaceAll(')', '').split(',');
    double x = parts.isNotEmpty ? double.tryParse(parts[0]) ?? 0.0 : 0.0;
    double y = parts.length > 1 ? double.tryParse(parts[1]) ?? 0.0 : 0.0;
    double z = parts.length > 2 ? double.tryParse(parts[2]) ?? 0.0 : 0.0;
    return vm.Vector3(x, y, z);
  }

  StructuralNode _getOrCreateNode(double x, double y, double z) {
    for (final n in _nodes) {
      if ((n.x - x).abs() < 0.05 && (n.y - y).abs() < 0.05 && (n.z - z).abs() < 0.05) {
        return n;
      }
    }
    final nId = 'N${_nodes.length + 1}';
    final newNode = StructuralNode(
      id: nId,
      x: x,
      y: y,
      z: z,
      isRestrained: y <= 0.05 ? [true, true, true, true, true, true] : [false, false, false, false, false, false],
    );
    _nodes.add(newNode);
    return newNode;
  }

  void _generateMultiBayFrame({required int bays, required int stories, required double bayWidth, required double storyHeight}) {
    _nodes.clear();
    _members.clear();

    for (int s = 0; s <= stories; s++) {
      for (int b = 0; b <= bays; b++) {
        final nId = 'N_${s}_$b';
        final isBase = (s == 0);
        _nodes.add(StructuralNode(
          id: nId,
          x: b * bayWidth,
          y: s * storyHeight,
          z: 0.0,
          isRestrained: isBase ? [true, true, true, true, true, true] : [false, false, false, false, false, false],
          fyN: (s > 0) ? -25000.0 : 0.0,
          fxN: (s == stories && b == 0) ? 18000.0 : 0.0,
        ));
      }
    }

    int mIdx = 1;
    // Columns
    for (int s = 0; s < stories; s++) {
      for (int b = 0; b <= bays; b++) {
        _members.add(StructuralMember(
          id: 'C${mIdx++}',
          startNodeId: 'N_${s}_$b',
          endNodeId: 'N_${s + 1}_$b',
          sectionProfile: 'W14X68',
        ));
      }
    }

    // Beams
    for (int s = 1; s <= stories; s++) {
      for (int b = 0; b < bays; b++) {
        _members.add(StructuralMember(
          id: 'B${mIdx++}',
          startNodeId: 'N_${s}_$b',
          endNodeId: 'N_${s}_${b + 1}',
          sectionProfile: 'W18X35',
        ));
      }
    }
  }

  void _generateCrossBracing() {
    double maxY = _nodes.map((n) => n.y).fold(0.0, math.max);
    double maxX = _nodes.map((n) => n.x).fold(0.0, math.max);

    final n1 = _getOrCreateNode(0.0, 0.0, 0.0);
    final n2 = _getOrCreateNode(maxX, maxY, 0.0);
    final n3 = _getOrCreateNode(0.0, maxY, 0.0);
    final n4 = _getOrCreateNode(maxX, 0.0, 0.0);

    _members.add(StructuralMember(id: 'BR_${_members.length + 1}', startNodeId: n1.id, endNodeId: n2.id, sectionProfile: 'W10X22'));
    _members.add(StructuralMember(id: 'BR_${_members.length + 1}', startNodeId: n3.id, endNodeId: n4.id, sectionProfile: 'W10X22'));
  }

  void _subdivideSelectedMember(int segments) {
    if (_selectedMemberId == null) return;
    final mem = _members.firstWhere((m) => m.id == _selectedMemberId);
    final n1 = _nodes.firstWhere((n) => n.id == mem.startNodeId);
    final n2 = _nodes.firstWhere((n) => n.id == mem.endNodeId);

    _members.removeWhere((m) => m.id == _selectedMemberId);

    final intermediateNodes = <StructuralNode>[n1];
    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final x = n1.x + t * (n2.x - n1.x);
      final y = n1.y + t * (n2.y - n1.y);
      final z = n1.z + t * (n2.z - n1.z);
      final n = _getOrCreateNode(x, y, z);
      intermediateNodes.add(n);
    }
    intermediateNodes.add(n2);

    for (int i = 0; i < intermediateNodes.length - 1; i++) {
      _members.add(StructuralMember(
        id: 'M${_members.length + 1}',
        startNodeId: intermediateNodes[i].id,
        endNodeId: intermediateNodes[i + 1].id,
        sectionProfile: mem.sectionProfile,
      ));
    }
    _selectedMemberId = null;
  }

  // --- Viewport Projection & Click Handlers ---

  vm.Vector3 _screenToWorld(Offset screenPos, Size canvasSize) {
    final cx = canvasSize.width / 2 + _panOffset.dx;
    final cy = canvasSize.height / 2 + _panOffset.dy;

    double dx = (screenPos.dx - cx) / _zoom;
    double dy = (cy - screenPos.dy) / _zoom;

    double x = dx;
    double y = dy;
    double z = 0.0;

    if (_snapToGrid) {
      x = (x / _gridSpacing).round() * _gridSpacing;
      y = (y / _gridSpacing).round() * _gridSpacing;
      z = (z / _gridSpacing).round() * _gridSpacing;
    }

    return vm.Vector3(x, y, z);
  }

  void _handleCanvasTap(Offset localPos, Size canvasSize) {
    final worldPos = _screenToWorld(localPos, canvasSize);

    _saveSnapshot();

    if (_activeTool == CadTool.addJoint) {
      final n = _getOrCreateNode(worldPos.x, worldPos.y, worldPos.z);
      _consoleLogs.add('✓ Placed Joint ${n.id} at (${n.x.toStringAsFixed(1)}, ${n.y.toStringAsFixed(1)}, ${n.z.toStringAsFixed(1)})');
      setState(() {});
      return;
    }

    // Check hit node
    StructuralNode? hitNode;
    for (final n in _nodes) {
      final s = _project3D(vm.Vector3(n.x, n.y, n.z), canvasSize);
      if ((s - localPos).distance < 14.0) {
        hitNode = n;
        break;
      }
    }

    if (_activeTool == CadTool.drawBeam) {
      if (hitNode != null) {
        if (_drawStartNode == null) {
          setState(() {
            _drawStartNode = hitNode;
            _consoleLogs.add('• Selected start joint ${hitNode!.id}. Click destination joint or grid point.');
          });
        } else if (_drawStartNode!.id != hitNode.id) {
          final mId = 'M${_members.length + 1}';
          _members.add(StructuralMember(
            id: mId,
            startNodeId: _drawStartNode!.id,
            endNodeId: hitNode.id,
            sectionProfile: _selectedSection,
          ));
          _consoleLogs.add('✓ Connected beam $mId [${_drawStartNode!.id} -> ${hitNode.id}] ($_selectedSection)');
          setState(() {
            _drawStartNode = null;
          });
        }
      } else {
        // Clicked on grid: create node and connect
        final newN = _getOrCreateNode(worldPos.x, worldPos.y, worldPos.z);
        if (_drawStartNode == null) {
          setState(() {
            _drawStartNode = newN;
            _consoleLogs.add('• Placed start joint ${newN.id}. Click destination joint.');
          });
        } else {
          final mId = 'M${_members.length + 1}';
          _members.add(StructuralMember(
            id: mId,
            startNodeId: _drawStartNode!.id,
            endNodeId: newN.id,
            sectionProfile: _selectedSection,
          ));
          _consoleLogs.add('✓ Connected beam $mId [${_drawStartNode!.id} -> ${newN.id}] ($_selectedSection)');
          setState(() {
            _drawStartNode = null;
          });
        }
      }
      return;
    }

    if (_activeTool == CadTool.assignSupport) {
      if (hitNode != null) {
        final idx = _nodes.indexWhere((n) => n.id == hitNode!.id);
        final currentFixed = _nodes[idx].isRestrained.every((r) => r);
        final currentPinned = _nodes[idx].isRestrained[0] && _nodes[idx].isRestrained[1] && !_nodes[idx].isRestrained[3];

        List<bool> nextRestraints;
        String desc;
        if (!currentFixed && !currentPinned) {
          nextRestraints = [true, true, true, true, true, true];
          desc = 'FIXED BASE (6-DOF)';
        } else if (currentFixed) {
          nextRestraints = [true, true, true, false, false, false];
          desc = 'PINNED FOOTING';
        } else {
          nextRestraints = [false, false, false, false, false, false];
          desc = 'FREE JOINT';
        }

        _nodes[idx] = _nodes[idx].copyWith(isRestrained: nextRestraints);
        _consoleLogs.add('✓ Joint ${hitNode.id} boundary toggled to $desc');
        setState(() {});
      }
      return;
    }

    if (_activeTool == CadTool.applyLoad) {
      if (hitNode != null) {
        final idx = _nodes.indexWhere((n) => n.id == hitNode!.id);
        final currentFy = _nodes[idx].fyN;
        final newFy = currentFy == 0.0 ? -35000.0 : 0.0;
        _nodes[idx] = _nodes[idx].copyWith(fyN: newFy);
        _consoleLogs.add('✓ Joint ${hitNode.id} vertical point load set to ${newFy / 1000.0} kN');
        setState(() {});
      }
      return;
    }

    // Select Tool
    setState(() {
      _selectedNodeId = hitNode?.id;
      _drawStartNode = null;
      if (hitNode != null) {
        _consoleLogs.add('• Selected Joint ${hitNode.id} (${hitNode.x}, ${hitNode.y}, ${hitNode.z})');
      }
    });
  }

  Offset _project3D(vm.Vector3 pt, Size size) {
    final cx = size.width / 2 + _panOffset.dx;
    final cy = size.height / 2 + _panOffset.dy;

    if (_activePlane == CadPlane.planXY) {
      return Offset(cx + pt.x * _zoom, cy - pt.y * _zoom);
    } else if (_activePlane == CadPlane.elevationXZ) {
      return Offset(cx + pt.x * _zoom, cy - pt.z * _zoom);
    } else if (_activePlane == CadPlane.sideYZ) {
      return Offset(cx + pt.z * _zoom, cy - pt.y * _zoom);
    }

    // Isometric 3D Projection
    final cosYaw = math.cos(_yaw);
    final sinYaw = math.sin(_yaw);
    final cosPitch = math.cos(_pitch);
    final sinPitch = math.sin(_pitch);

    final x1 = pt.x * cosYaw - pt.z * sinYaw;
    final z1 = pt.x * sinYaw + pt.z * cosYaw;

    final y2 = pt.y * cosPitch - z1 * sinPitch;

    return Offset(cx + x1 * _zoom, cy - y2 * _zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 1280,
        height: 820,
        decoration: BoxDecoration(
          color: const Color(0xFF090D14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF30363D), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1F6FEB).withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTopToolRibbon(),
            Expanded(
              child: Row(
                children: [
                  _buildLeftToolbar(),
                  Expanded(child: _buildCanvasArea()),
                  _buildRightPropertiesPanel(),
                ],
              ),
            ),
            _buildBottomCommandConsole(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopToolRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1F6FEB).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1F6FEB)),
            ),
            child: const Icon(Icons.architecture_rounded, color: Color(0xFF58A6FF), size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STRUCTURA CAD / BIM GENERATIVE STUDIO',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1),
              ),
              Text(
                'Precision 3D Frame Drafting • AI Generative Console • BIM Snapping Engine',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),

          // Plane Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                _buildPlaneButton(CadPlane.isometric3D, '3D Iso'),
                _buildPlaneButton(CadPlane.planXY, 'XY Plan'),
                _buildPlaneButton(CadPlane.elevationXZ, 'XZ Elev'),
                _buildPlaneButton(CadPlane.sideYZ, 'YZ Side'),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Snaps
          FilterChip(
            label: const Text('GRID SNAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            selected: _snapToGrid,
            selectedColor: const Color(0xFF1F6FEB).withValues(alpha: 0.3),
            onSelected: (val) => setState(() => _snapToGrid = val),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('ORTHO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            selected: _orthoMode,
            selectedColor: const Color(0xFF238636).withValues(alpha: 0.3),
            onSelected: (val) => setState(() => _orthoMode = val),
          ),
          const SizedBox(width: 16),

          // Undo / Redo
          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 18, color: Colors.white70),
            onPressed: _undoStack.isNotEmpty ? _undo : null,
            tooltip: 'Undo (Ctrl+Z)',
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, size: 18, color: Colors.white70),
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            tooltip: 'Redo (Ctrl+Y)',
          ),
          const SizedBox(width: 16),

          // Commit button
          ElevatedButton.icon(
            onPressed: () {
              final newModel = StructuralModel(
                name: _modelName,
                nodes: _nodes,
                members: _members,
              );
              widget.onModelCommitted(newModel);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
            label: const Text('Commit to Solver', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF238636),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaneButton(CadPlane plane, String label) {
    final isSel = _activePlane == plane;
    return GestureDetector(
      onTap: () => setState(() => _activePlane = plane),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1F6FEB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLeftToolbar() {
    if (!_isCadToolbarExpanded) {
      return Container(
        width: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF0D121D),
          border: Border(
            right: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.3), width: 1.5),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Slideable drag handle
            Tooltip(
              message: 'Drag to slide CAD menu vertically. Position remembered.',
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _cadToolbarTopOffset = (_cadToolbarTopOffset + details.delta.dy).clamp(0.0, 300.0);
                  });
                  WorkspacePreferences.setDouble('cad_studio_tools_top', _cadToolbarTopOffset);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.drag_indicator_rounded, size: 16, color: Color(0xFF00F0FF)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.keyboard_double_arrow_right_rounded, size: 18, color: Color(0xFF00F0FF)),
              tooltip: 'Expand CAD Tools Menu',
              onPressed: () {
                setState(() => _isCadToolbarExpanded = true);
                WorkspacePreferences.setBool('cad_studio_tools_expanded', true);
              },
            ),
          ],
        ),
      );
    }

    return Container(
      width: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF0C1322),
        border: Border(
          right: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.3), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: _cadToolbarTopOffset),
          // Drag handle & collapse row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _cadToolbarTopOffset = (_cadToolbarTopOffset + details.delta.dy).clamp(0.0, 300.0);
                  });
                  WorkspacePreferences.setDouble('cad_studio_tools_top', _cadToolbarTopOffset);
                },
                child: Tooltip(
                  message: 'Slideable CAD menu. Drag to position.',
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.drag_indicator_rounded, size: 14, color: Color(0xFF00F0FF)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.keyboard_double_arrow_left_rounded, size: 16, color: Colors.white70),
                tooltip: 'Collapse CAD Tools Menu',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () {
                  setState(() => _isCadToolbarExpanded = false);
                  WorkspacePreferences.setBool('cad_studio_tools_expanded', false);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildToolIconButton(CadTool.select, Icons.near_me_rounded, 'Select / Inspect'),
          _buildToolIconButton(CadTool.drawBeam, Icons.polyline_rounded, 'Draw Beam (Line)'),
          _buildToolIconButton(CadTool.addJoint, Icons.control_point_rounded, 'Add Joint (Point)'),
          _buildToolIconButton(CadTool.assignSupport, Icons.anchor_rounded, 'Assign Restraints'),
          _buildToolIconButton(CadTool.applyLoad, Icons.vertical_align_bottom_rounded, 'Apply Joint Loads'),
          const Divider(color: Colors.white12, height: 20),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFF85149), size: 20),
            onPressed: () {
              _saveSnapshot();
              setState(() {
                _nodes.clear();
                _members.clear();
                _selectedNodeId = null;
                _selectedMemberId = null;
                _consoleLogs.add('✓ Canvas cleared.');
              });
            },
            tooltip: 'Clear Canvas',
          ),
        ],
      ),
    );
  }

  Widget _buildToolIconButton(CadTool tool, IconData icon, String tooltip) {
    final isSel = _activeTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => setState(() {
            _activeTool = tool;
            _drawStartNode = null;
          }),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSel ? const Color(0xFF1F6FEB) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSel ? const Color(0xFF58A6FF) : Colors.transparent),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSel ? Colors.white : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onScaleStart: (details) {
            _lastPan = details.localFocalPoint;
          },
          onScaleUpdate: (details) {
            setState(() {
              if (details.pointerCount == 1 && _lastPan != null) {
                final delta = details.localFocalPoint - _lastPan!;
                if (_activePlane == CadPlane.isometric3D) {
                  _yaw += delta.dx * 0.008;
                  _pitch = (_pitch - delta.dy * 0.008).clamp(-1.4, 1.4);
                } else {
                  _panOffset += delta;
                }
              } else if (details.pointerCount > 1 && _lastPan != null) {
                final delta = details.localFocalPoint - _lastPan!;
                _panOffset += delta;
                _zoom = (_zoom * details.scale).clamp(10.0, 150.0);
              }
              _lastPan = details.localFocalPoint;
            });
          },
          onTapUp: (details) => _handleCanvasTap(details.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _CadCanvasPainter(
              nodes: _nodes,
              members: _members,
              activePlane: _activePlane,
              activeTool: _activeTool,
              selectedNodeId: _selectedNodeId,
              selectedMemberId: _selectedMemberId,
              drawStartNode: _drawStartNode,
              hoverWorldPos: _hoverWorldPos,
              yaw: _yaw,
              pitch: _pitch,
              zoom: _zoom,
              panOffset: _panOffset,
              snapToGrid: _snapToGrid,
              gridSpacing: _gridSpacing,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRightPropertiesPanel() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(left: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ELEMENT PROPERTIES',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),

          // Active AISC section
          const Text('AISC Section Profile:', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSection,
                dropdownColor: const Color(0xFF161B22),
                isExpanded: true,
                items: [
                  'W10X22',
                  'W12X26',
                  'W12X35',
                  'W14X48',
                  'W14X68',
                  'W14X90',
                  'W16X36',
                  'W18X35',
                  'W18X50',
                  'W24X68'
                ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSection = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Grid Spacing
          const Text('Grid Spacing:', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            children: [0.5, 1.0, 2.0, 5.0].map((spacing) {
              final isSel = _gridSpacing == spacing;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gridSpacing = spacing),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF1F6FEB) : const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isSel ? const Color(0xFF58A6FF) : Colors.white12),
                    ),
                    alignment: Alignment.center,
                    child: Text('${spacing}m', style: TextStyle(color: isSel ? Colors.white : Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
          const Divider(color: Colors.white12, height: 28),

          // Model stats
          const Text('Structure Statistics', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildStatRow('Total Joints:', '${_nodes.length}'),
          _buildStatRow('Total Members:', '${_members.length}'),
          _buildStatRow('Base Supports:', '${_nodes.where((n) => n.isRestrained.any((r) => r)).length}'),
          _buildStatRow('Loaded Joints:', '${_nodes.where((n) => n.fyN != 0.0 || n.fxN != 0.0).length}'),

          const Spacer(),

          // Quick Generative Actions
          const Text('AI Generative Actions:', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _executeCommand('add 3-story frame'),
            icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF58A6FF)),
            label: const Text('Add 3-Story Frame', style: TextStyle(color: Colors.white, fontSize: 11)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1F6FEB)),
              minimumSize: const Size(double.infinity, 36),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => _executeCommand('cross-bracing'),
            icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF7EE787)),
            label: const Text('Add X-Bracing', style: TextStyle(color: Colors.white, fontSize: 11)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2EA043)),
              minimumSize: const Size(double.infinity, 36),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => _executeCommand('fix all bases'),
            icon: const Icon(Icons.anchor_rounded, size: 14, color: Colors.orangeAccent),
            label: const Text('Fix All Footings', style: TextStyle(color: Colors.white, fontSize: 11)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orangeAccent),
              minimumSize: const Size(double.infinity, 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomCommandConsole() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Console output preview
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: ListView.builder(
              reverse: true,
              itemCount: math.min(2, _consoleLogs.length),
              itemBuilder: (ctx, idx) {
                final log = _consoleLogs[_consoleLogs.length - 1 - idx];
                return Text(
                  log,
                  style: const TextStyle(color: Color(0xFF7EE787), fontFamily: 'monospace', fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Command input bar
          Row(
            children: [
              const Text(
                'COMMAND >',
                style: TextStyle(color: Color(0xFF58A6FF), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _cmdController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Type AutoCAD command or prompt (e.g. LINE 0,0,0 6,4,0 W16X26 or "add 2-story frame")',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _executeCommand,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF1F6FEB)),
                onPressed: () => _executeCommand(_cmdController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Custom Canvas Painter ---

class _CadCanvasPainter extends CustomPainter {
  final List<StructuralNode> nodes;
  final List<StructuralMember> members;
  final CadPlane activePlane;
  final CadTool activeTool;
  final String? selectedNodeId;
  final String? selectedMemberId;
  final StructuralNode? drawStartNode;
  final vm.Vector3? hoverWorldPos;
  final double yaw;
  final double pitch;
  final double zoom;
  final Offset panOffset;
  final bool snapToGrid;
  final double gridSpacing;

  _CadCanvasPainter({
    required this.nodes,
    required this.members,
    required this.activePlane,
    required this.activeTool,
    this.selectedNodeId,
    this.selectedMemberId,
    this.drawStartNode,
    this.hoverWorldPos,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.panOffset,
    required this.snapToGrid,
    required this.gridSpacing,
  });

  Offset _project(vm.Vector3 pt, Size size) {
    final cx = size.width / 2 + panOffset.dx;
    final cy = size.height / 2 + panOffset.dy;

    if (activePlane == CadPlane.planXY) {
      return Offset(cx + pt.x * zoom, cy - pt.y * zoom);
    } else if (activePlane == CadPlane.elevationXZ) {
      return Offset(cx + pt.x * zoom, cy - pt.z * zoom);
    } else if (activePlane == CadPlane.sideYZ) {
      return Offset(cx + pt.z * zoom, cy - pt.y * zoom);
    }

    final cosYaw = math.cos(yaw);
    final sinYaw = math.sin(yaw);
    final cosPitch = math.cos(pitch);
    final sinPitch = math.sin(pitch);

    final x1 = pt.x * cosYaw - pt.z * sinYaw;
    final z1 = pt.x * sinYaw + pt.z * cosYaw;

    final y2 = pt.y * cosPitch - z1 * sinPitch;

    return Offset(cx + x1 * zoom, cy - y2 * zoom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const gridExtent = 20.0;
    for (double i = -gridExtent; i <= gridExtent; i += gridSpacing) {
      final p1 = _project(vm.Vector3(i, 0.0, -gridExtent), size);
      final p2 = _project(vm.Vector3(i, 0.0, gridExtent), size);
      canvas.drawLine(p1, p2, gridPaint);

      final p3 = _project(vm.Vector3(-gridExtent, 0.0, i), size);
      final p4 = _project(vm.Vector3(gridExtent, 0.0, i), size);
      canvas.drawLine(p3, p4, gridPaint);
    }

    // Origin Axes (X: Red, Y: Green, Z: Blue)
    final o = _project(vm.Vector3.zero(), size);
    canvas.drawLine(o, _project(vm.Vector3(3.0, 0, 0), size), Paint()..color = const Color(0xFFF85149)..strokeWidth = 2.0);
    canvas.drawLine(o, _project(vm.Vector3(0, 3.0, 0), size), Paint()..color = const Color(0xFF3FB950)..strokeWidth = 2.0);
    canvas.drawLine(o, _project(vm.Vector3(0, 0, 3.0), size), Paint()..color = const Color(0xFF58A6FF)..strokeWidth = 2.0);

    final nodeMap = {for (var n in nodes) n.id: n};

    // Draw Members
    for (final m in members) {
      final n1 = nodeMap[m.startNodeId];
      final n2 = nodeMap[m.endNodeId];
      if (n1 == null || n2 == null) continue;

      final p1 = _project(vm.Vector3(n1.x, n1.y, n1.z), size);
      final p2 = _project(vm.Vector3(n2.x, n2.y, n2.z), size);

      final isSel = (m.id == selectedMemberId);
      final memberPaint = Paint()
        ..color = isSel ? Colors.yellowAccent : const Color(0xFF8B949E)
        ..strokeWidth = isSel ? 3.5 : 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, memberPaint);
    }

    // Draw Rubberband line when drawing beam
    if (drawStartNode != null && hoverWorldPos != null) {
      final p1 = _project(vm.Vector3(drawStartNode!.x, drawStartNode!.y, drawStartNode!.z), size);
      final p2 = _project(hoverWorldPos!, size);
      final rubberPaint = Paint()
        ..color = const Color(0xFF58A6FF)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(p1, p2, rubberPaint);
    }

    // Draw Nodes
    for (final n in nodes) {
      final p = _project(vm.Vector3(n.x, n.y, n.z), size);
      final isSel = (n.id == selectedNodeId);
      final isDrawStart = (n.id == drawStartNode?.id);
      final isFixed = n.isRestrained.any((r) => r);

      // Support symbol
      if (isFixed) {
        final suppPaint = Paint()
          ..color = const Color(0xFFDA3633)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromCenter(center: p + const Offset(0, 6), width: 10, height: 4), suppPaint);
      }

      // Load arrow
      if (n.fyN < 0) {
        final arrowPaint = Paint()
          ..color = const Color(0xFFFF7B72)
          ..strokeWidth = 2.0;
        canvas.drawLine(p - const Offset(0, 24), p, arrowPaint);
      }

      final nodePaint = Paint()
        ..color = isDrawStart
            ? const Color(0xFF3FB950)
            : isSel
                ? Colors.yellowAccent
                : isFixed
                    ? const Color(0xFFF85149)
                    : const Color(0xFF58A6FF)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(p, isSel || isDrawStart ? 6.0 : 4.5, nodePaint);
      canvas.drawCircle(p, isSel || isDrawStart ? 6.0 : 4.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.0);
    }
  }

  @override
  bool shouldRepaint(covariant _CadCanvasPainter old) => true;
}
