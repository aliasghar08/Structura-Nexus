// ============================================================================
// WorkstationScreen — Core Real-Time Structural Engineering Workstation
// Interactive 3D WebGL Viewport, Surrogate GNN, AISC 360-16 & ASCE 7-16
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../models/structural_models.dart';
import '../data/benchmark_presets.dart';
import '../services/structural_api_service.dart';
import '../services/embedded_fea_solver.dart';
import '../services/firebase_auth_service.dart';
import '../services/building_generator_service.dart';
import '../services/tributary_load_propagator.dart';
import 'auth_screen.dart';
import '../widgets/workstation_drawer.dart';
import '../widgets/structural_3d_viewport.dart';
import '../widgets/ai_copilot_dialog.dart';
import '../widgets/generative_optimizer_dialog.dart';
import '../widgets/seismic_modal_dialog.dart';
import '../widgets/embodied_carbon_dialog.dart';
import '../widgets/auth_dialog.dart';
import '../widgets/structural_library_dialog.dart';
import '../widgets/cad_editor_dialog.dart';
import '../widgets/lateral_stability_dialog.dart';
import '../widgets/pe_packet_dialog.dart';
import '../widgets/generative_bracing_dialog.dart';
import '../widgets/building_templates_dialog.dart';
import '../widgets/mac_neural_inspector_dialog.dart';
import '../widgets/glass_pod.dart';
import '../widgets/floating_telemetry_dock.dart';
import '../widgets/floating_inspector_panel.dart';
import '../widgets/floating_workstation_header.dart';
import '../widgets/floating_copyright_watermark.dart';
import '../widgets/concrete_pm_dialog.dart';
import '../widgets/steel_connection_dialog.dart';
import '../widgets/pushover_analysis_dialog.dart';
import '../widgets/wind_cfd_dialog.dart';
import '../widgets/composite_floor_dialog.dart';
import '../widgets/environmental_stimulator_dialog.dart';
import '../widgets/vision_ingestion_dialog.dart';
import '../widgets/foundation_studio_dialog.dart';
import '../widgets/time_history_player.dart';
import '../widgets/pareto_frontier_dock.dart';
import '../widgets/autonomous_swarm_dialog.dart';
import '../widgets/slideable_workspace_menu.dart';
import '../widgets/generative_topology_dialog.dart';
import '../widgets/shop_drawing_audit_dialog.dart';
import '../widgets/collaboration_review_dialog.dart';
import '../widgets/progressive_collapse_dialog.dart';
import '../widgets/command_palette_dialog.dart';
import '../widgets/info_tooltip.dart';
import '../widgets/voice_copilot_pill.dart';
import '../services/voice_copilot_service.dart';
import '../services/workspace_storage.dart';
import '../services/dart_neural_engine.dart';

class WorkstationScreen extends StatefulWidget {
  const WorkstationScreen({super.key});

  @override
  State<WorkstationScreen> createState() => _WorkstationScreenState();
}

class _WorkstationScreenState extends State<WorkstationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<Structural3DViewportState> _viewportKey = GlobalKey<Structural3DViewportState>();
  final GlobalKey<SlideableWorkspaceMenuState> _workspaceMenuKey = GlobalKey<SlideableWorkspaceMenuState>();
  late StructuralModel _model;
  final List<StructuralModel> _undoStack = [];
  final List<StructuralModel> _redoStack = [];
  final StructuralApiService _apiService = StructuralApiService();
  final RealtimeSurrogateStreamer _surrogateStreamer = RealtimeSurrogateStreamer();
  String? _selectedNodeId;
  String? _selectedMemberId;
  final Set<String> _selectedNodeIds = {};
  final Set<String> _selectedMemberIds = {};
  bool? _isInspectorOpen;
  double? _inspectorTopOffset;
  bool _isNlthaActive = false;
  bool _autoPropagateLoads = true;
  int _modelRevision = 0;
  StreamSubscription<dynamic>? _authSubscription;

  void _saveUndoState() {
    _undoStack.add(_model.copyWith());
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) {
      _showToolSnackBar('Nothing to undo.');
      return;
    }
    _redoStack.add(_model.copyWith());
    _model = _undoStack.removeLast();
    _selectedNodeId = null;
    _selectedMemberId = null;
    _selectedNodeIds.clear();
    _selectedMemberIds.clear();
    _commitModelMutation('Undo applied (${_model.nodes.length} joints, ${_model.members.length} members)');
  }

  void _redo() {
    if (_redoStack.isEmpty) {
      _showToolSnackBar('Nothing to redo.');
      return;
    }
    _undoStack.add(_model.copyWith());
    _model = _redoStack.removeLast();
    _selectedNodeId = null;
    _selectedMemberId = null;
    _selectedNodeIds.clear();
    _selectedMemberIds.clear();
    _commitModelMutation('Redo applied (${_model.nodes.length} joints, ${_model.members.length} members)');
  }

  bool _isTextInputFocused() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return false;
    final widget = primaryFocus.context?.widget;
    return widget is EditableText;
  }

  KeyEventResult _handleGlobalKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_isTextInputFocused()) return KeyEventResult.ignored;

    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final isModifier = isMac
        ? HardwareKeyboard.instance.isMetaPressed
        : HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // Cmd/Ctrl + K: Open Universal Command Palette & Encyclopedia
    if (isModifier && event.logicalKey == LogicalKeyboardKey.keyK) {
      _openCommandPalette();
      return KeyEventResult.handled;
    }

    // Cmd/Ctrl + Z: Undo
    if (isModifier && !isShift && event.logicalKey == LogicalKeyboardKey.keyZ) {
      _undo();
      return KeyEventResult.handled;
    }

    // Cmd/Ctrl + Y or Cmd/Ctrl + Shift + Z: Redo
    if ((isModifier && event.logicalKey == LogicalKeyboardKey.keyY) ||
        (isModifier && isShift && event.logicalKey == LogicalKeyboardKey.keyZ)) {
      _redo();
      return KeyEventResult.handled;
    }

    // Delete / Backspace: Delete selected
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_selectedNodeId != null ||
          _selectedMemberId != null ||
          _selectedNodeIds.isNotEmpty ||
          _selectedMemberIds.isNotEmpty) {
        _deleteSelectedElements();
        return KeyEventResult.handled;
      }
    }

    // Escape: Deselect all
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _deselectAll();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _deleteSelectedElements() {
    final nodesToDelete = Set<String>.from(_selectedNodeIds);
    if (_selectedNodeId != null) nodesToDelete.add(_selectedNodeId!);

    final membersToDelete = Set<String>.from(_selectedMemberIds);
    if (_selectedMemberId != null) membersToDelete.add(_selectedMemberId!);

    if (nodesToDelete.isEmpty && membersToDelete.isEmpty) return;

    _saveUndoState();

    final remainingMembers = _model.members.where((m) {
      if (membersToDelete.contains(m.id)) return false;
      if (nodesToDelete.contains(m.iNodeId) || nodesToDelete.contains(m.jNodeId)) return false;
      return true;
    }).toList();

    final remainingNodes = _model.nodes.where((n) => !nodesToDelete.contains(n.id)).toList();

    _model = _model.copyWith(nodes: remainingNodes, members: remainingMembers);
    _selectedNodeId = null;
    _selectedMemberId = null;
    _selectedNodeIds.clear();
    _selectedMemberIds.clear();
    _commitModelMutation('Deleted selected entities.');
  }

  void _deselectAll() {
    setState(() {
      _selectedNodeId = null;
      _selectedMemberId = null;
      _selectedNodeIds.clear();
      _selectedMemberIds.clear();
    });
  }

  void _batchAssignSection(String section) {
    if (_selectedMemberIds.isEmpty && _selectedMemberId == null) return;
    final targetIds = Set<String>.from(_selectedMemberIds);
    if (_selectedMemberId != null) targetIds.add(_selectedMemberId!);

    _saveUndoState();
    final updated = _model.members.map((m) {
      if (targetIds.contains(m.id)) {
        return m.copyWith(section: section);
      }
      return m;
    }).toList();

    _model = _model.copyWith(members: updated);
    _commitModelMutation('Assigned $section to ${targetIds.length} members');
  }

  void _batchAssignSupport(String supportType) {
    if (_selectedNodeIds.isEmpty && _selectedNodeId == null) return;
    final targetIds = Set<String>.from(_selectedNodeIds);
    if (_selectedNodeId != null) targetIds.add(_selectedNodeId!);

    List<int> restraint = [0, 0, 0, 0, 0, 0];
    if (supportType == 'FIXED') {
      restraint = [1, 1, 1, 1, 1, 1];
    } else if (supportType == 'PINNED') {
      restraint = [1, 1, 1, 0, 0, 0];
    } else if (supportType == 'ROLLER') {
      restraint = [0, 1, 0, 0, 0, 0];
    }

    _saveUndoState();
    final updated = _model.nodes.map((n) {
      if (targetIds.contains(n.id)) {
        return n.copyWith(restraint: List<int>.from(restraint));
      }
      return n;
    }).toList();

    _model = _model.copyWith(nodes: updated);
    _commitModelMutation('Assigned $supportType support to ${targetIds.length} joints');
  }

  void _batchApplyLoads(double fx, double fy, double fz) {
    if (_selectedNodeIds.isEmpty && _selectedNodeId == null) return;
    final targetIds = Set<String>.from(_selectedNodeIds);
    if (_selectedNodeId != null) targetIds.add(_selectedNodeId!);

    _saveUndoState();
    final updated = _model.nodes.map((n) {
      if (targetIds.contains(n.id)) {
        final currentLoads = List<double>.from(n.loads);
        if (fx == 0 && fy == 0 && fz == 0) {
          return n.copyWith(loads: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);
        } else {
          return n.copyWith(
            loads: [
              (currentLoads.isNotEmpty ? currentLoads[0] : 0.0) + fx,
              (currentLoads.length > 1 ? currentLoads[1] : 0.0) + fy,
              (currentLoads.length > 2 ? currentLoads[2] : 0.0) + fz,
              0.0,
              0.0,
              0.0,
            ],
          );
        }
      }
      return n;
    }).toList();

    _model = _model.copyWith(nodes: updated);
    _commitModelMutation('Applied loads across ${targetIds.length} joints');
  }

  void _commitModelMutation(String snackbarMessage, {bool refitCamera = false}) {
    setState(() {
      _modelRevision++;
      _triggerSolve();
    });

    if (refitCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewportKey.currentState?.reloadModel(refitCamera: true);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _viewportKey.currentState?.reloadModel();
      });
    }

    _showToolSnackBar(snackbarMessage);
  }

  void _setInspectorOpen(bool open) {
    setState(() => _isInspectorOpen = open);
    WorkspacePreferences.setBool('inspector_is_open', open);
  }

  void _updateInspectorTop(double delta, double maxTop) {
    setState(() {
      _inspectorTopOffset = ((_inspectorTopOffset ?? 70.0) + delta).clamp(60.0, maxTop);
    });
    WorkspacePreferences.setDouble('inspector_top_offset', _inspectorTopOffset!);
  }

  bool get _isUserLoggedIn {
    final user = FirebaseAuthService().currentUser;
    return user != null;
  }

  void _requireAuth({
    required String featureName,
    required VoidCallback onAuthenticated,
  }) {
    if (_isUserLoggedIn) {
      onAuthenticated();
      return;
    }

    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AuthScreen(
          redirectMessage: 'Please sign in or create an account to use $featureName.',
          onLoginSuccess: () {
            if (mounted) {
              setState(() {});
              onAuthenticated();
            }
          },
        ),
      ),
    ).then((authenticated) {
      if (authenticated == true && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _isInspectorOpen = WorkspacePreferences.getOptionalBool('inspector_is_open');
    _inspectorTopOffset = WorkspacePreferences.getDouble('inspector_top_offset', 70.0);
    _model = BenchmarkPresets.multiStorySwayFrame();
    EmbeddedFeaSolver.solve(_model);
    DartNeuralEngine.instance.initialize();

    // Initialize live API WebSocket connection
    _apiService.connectWebSocket(
      onUpdate: (update) {
        setState(() {
          _model.solverLatencyMs = update.latencyMs;
          _model.baseShearN = update.baseShearN;
          _model.maxDriftRatio = update.maxDriftRatio;
          _model.isEquilibrated = update.isEquilibrated;
          _model.surrogateUncertainty = update.uncertainty;
        });
      },
    );

    // Reactively refresh UI when authentication state changes
    _authSubscription = FirebaseAuthService().authStateChanges.listen((_) {
      if (mounted) setState(() {});
    });

    // v4.2 Gemini Live Spatial Voice Co-Pilot Handlers
    final voiceService = VoiceCopilotService.instance;
    voiceService.onAddChevronBracing = () {
      if (mounted) {
        setState(() {
          _addXBracing();
        });
      }
    };
    voiceService.onApplyWindLoads = (mph, exp) {
      if (mounted) {
        final fxN = 25000.0 * (mph / 145.0) * (mph / 145.0);
        setState(() {
          _applyWindLoads(fxN);
        });
      }
    };
    voiceService.onHighlightMembers = (memberIds) {
      _viewportKey.currentState?.setHighlightedMembers(memberIds);
    };
    voiceService.onRunAutoSizer = () {
      _openGenerativeOptimizer();
    };
    voiceService.onSolveModel = () {
      _triggerSolve();
    };
  }

  void _openGenerativeOptimizer() => _requireAuth(
    featureName: 'Generative AI Section Auto-Sizer',
    onAuthenticated: () => GenerativeOptimizerDialog.show(
      context,
      model: _model,
      apiService: _apiService,
      onStructureModified: _triggerSolve,
    ),
  );

  @override
  void dispose() {
    _authSubscription?.cancel();
    _surrogateStreamer.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _triggerSolve() {
    setState(() {
      _modelRevision++;
      try {
        EmbeddedFeaSolver.solve(_model);
      } catch (e) {
        debugPrint('Embedded FEA solve note: $e');
      }
      _apiService.sendGraphPayload(
        _model,
        action: _model.activeEngine == EngineType.surrogateGnn
            ? 'INFER_SURROGATE'
            : 'EXACT_SOLVE',
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportKey.currentState?.reloadModel();
    });
  }

  void _optimizeSections() {
    _saveUndoState();
    const orderedSections = [
      'W12X26',
      'W18X35',
      'W14X48',
      'W14X68',
      'W24X76',
      'W14X90',
      'W14X120',
      'W24X131',
    ];
    int modifiedCount = 0;
    for (final m in _model.members) {
      int idx = orderedSections.indexOf(m.section);
      if (idx == -1) idx = 2;
      if (m.governingDcr > 0.95 && idx < orderedSections.length - 1) {
        m.section = orderedSections[idx + 1];
        modifiedCount++;
      } else if (m.governingDcr < 0.38 && idx > 0) {
        m.section = orderedSections[idx - 1];
        modifiedCount++;
      }
    }
    _commitModelMutation(
      'AISC 360-16 Auto-Sizer optimized $modifiedCount members (Max DCR: ${_model.governingDcr.toStringAsFixed(3)})',
    );
    _apiService.triggerRemoteOptimization(_model);
  }

  void _loadPreset(String presetKey) {
    StructuralModel? newModel;
    if (presetKey == 'high_rise_10s') {
      newModel = BuildingGeneratorService.generateCommercialHighRiseTower();
    } else if (presetKey == 'hospital_8s') {
      newModel = BuildingGeneratorService.generateHospitalComplex();
    } else if (presetKey == 'residential_6s') {
      newModel = BuildingGeneratorService.generateResidentialBuilding();
    } else if (presetKey == 'supertall_20s') {
      newModel = BuildingGeneratorService.generateSuperTallOutrigger();
    } else if (presetKey == 'warehouse_portal') {
      newModel = BuildingGeneratorService.generateIndustrialWarehouse();
    } else if (presetKey == 'space_grid_canopy') {
      newModel = BuildingGeneratorService.generateSpaceGridCanopy();
    } else if (presetKey == 'campus_4s') {
      newModel = BuildingGeneratorService.generateEducationalCampus();
    } else if (presetKey == 'pratt_truss_bridge') {
      newModel = BuildingGeneratorService.generatePrattHighwayBridge();
    } else if (presetKey == 'transmission_tower') {
      newModel = BuildingGeneratorService.generateTransmissionTower();
    } else if (presetKey == 'sway') {
      newModel = BenchmarkPresets.multiStorySwayFrame();
    } else if (presetKey == 'truss') {
      newModel = BenchmarkPresets.warrenTruss();
    } else if (presetKey == 'cantilever') {
      newModel = BenchmarkPresets.timoshenkoCantilever();
    }

    if (newModel != null) {
      _importBuildingModel(newModel);
    }
  }

  void _importBuildingModel(StructuralModel newModel) {
    _saveUndoState();
    setState(() {
      _model = newModel;
      _modelRevision++;
      _selectedNodeId = null;
      _selectedMemberId = null;
    });
    _triggerSolve();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewportKey.currentState?.reloadModel(refitCamera: true);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF00F0FF), width: 1.2),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00F0FF), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Imported "${newModel.name}" (${newModel.nodes.length} Joints, ${newModel.members.length} Members) into Workspace!',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ==========================================================================
  // CONTEXTUAL SCREEN TOOLBOX: DRAWING & BUILDING STRUCTURES ON 3D CANVAS
  // ==========================================================================

  void _showAddJointDialog() {
    double defaultX = 3.0;
    double defaultY = 10.0;
    double defaultZ = 3.0;
    if (_model.nodes.isNotEmpty) {
      final minX = _model.nodes.map((n) => n.coords.x).reduce(math.min);
      final maxX = _model.nodes.map((n) => n.coords.x).reduce(math.max);
      final maxY = _model.nodes.map((n) => n.coords.y).reduce(math.max);
      final minZ = _model.nodes.map((n) => n.coords.z).reduce(math.min);
      final maxZ = _model.nodes.map((n) => n.coords.z).reduce(math.max);
      defaultX = (minX + maxX) / 2.0;
      defaultY = maxY + 3.0;
      defaultZ = (minZ + maxZ) / 2.0;
      while (_model.nodes.any((n) =>
          (n.coords.x - defaultX).abs() < 0.1 &&
          (n.coords.y - defaultY).abs() < 0.1 &&
          (n.coords.z - defaultZ).abs() < 0.1)) {
        defaultX += 3.0;
      }
    }
    final xCtrl = TextEditingController(text: defaultX.toStringAsFixed(1));
    final yCtrl = TextEditingController(text: defaultY.toStringAsFixed(1));
    final zCtrl = TextEditingController(text: defaultZ.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C1322),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00F0FF), width: 1.2),
        ),
        title: Row(
          children: const [
            Icon(Icons.add_location_alt_rounded, color: Color(0xFF00F0FF), size: 20),
            SizedBox(width: 8),
            Text('Add 3D Joint / Node', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _coordInputField('X Coordinate (m)', xCtrl),
            const SizedBox(height: 8),
            _coordInputField('Y Coordinate (Height m)', yCtrl),
            const SizedBox(height: 8),
            _coordInputField('Z Coordinate (Depth m)', zCtrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final x = double.tryParse(xCtrl.text) ?? 0.0;
              final y = double.tryParse(yCtrl.text) ?? 0.0;
              final z = double.tryParse(zCtrl.text) ?? 0.0;
              Navigator.of(ctx).pop();

              final newId = 'N_${_model.nodes.length + 1}';
              final isBase = y.abs() < 0.05;
              final node = StructuralNode(
                id: newId,
                coords: Vector3(x, y, z),
                restraint: isBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0],
                loads: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
              );
              _model.nodes.add(node);
              _selectedNodeId = newId;
              _selectedMemberId = null;
              _commitModelMutation('Added Joint $newId at ($x, $y, $z)m', refitCamera: true);
            },
            child: const Text('Add Joint', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _coordInputField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
        filled: true,
        fillColor: const Color(0xFF161F30),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  void _showDrawMemberDialog() {
    if (_model.nodes.length < 2) {
      _showToolSnackBar('Need at least 2 joints on canvas to draw a structural member.');
      return;
    }
    String startNode = _selectedNodeId ?? _model.nodes.last.id;
    final startObj = _model.nodes.firstWhere(
      (n) => n.id == startNode,
      orElse: () => _model.nodes.last,
    );
    final candidates = _model.nodes.where((n) {
      if (n.id == startNode) return false;
      final alreadyLinked = _model.members.any(
        (m) =>
            (m.iNodeId == startNode && m.jNodeId == n.id) ||
            (m.iNodeId == n.id && m.jNodeId == startNode),
      );
      return !alreadyLinked;
    }).toList();
    candidates.sort((a, b) =>
        a.coords.distanceTo(startObj.coords).compareTo(b.coords.distanceTo(startObj.coords)));
    String endNode = candidates.isNotEmpty
        ? candidates.first.id
        : _model.nodes.firstWhere((n) => n.id != startNode, orElse: () => _model.nodes.first).id;
    String chosenSection = 'W14X48';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF0C1322),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00F0FF), width: 1.2),
          ),
          title: Row(
            children: const [
              Icon(Icons.architecture_rounded, color: Color(0xFF00F0FF), size: 20),
              SizedBox(width: 8),
              Text('Draw Structural Member', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: startNode,
                dropdownColor: const Color(0xFF131A29),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(labelText: 'Start Joint (Node I)', labelStyle: TextStyle(color: Colors.white70, fontSize: 11)),
                items: _model.nodes.map((n) => DropdownMenuItem(value: n.id, child: Text('${n.id} (${n.coords.x.toStringAsFixed(1)}, ${n.coords.y.toStringAsFixed(1)}, ${n.coords.z.toStringAsFixed(1)})'))).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => startNode = val);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: endNode,
                dropdownColor: const Color(0xFF131A29),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(labelText: 'End Joint (Node J)', labelStyle: TextStyle(color: Colors.white70, fontSize: 11)),
                items: _model.nodes.map((n) => DropdownMenuItem(value: n.id, child: Text('${n.id} (${n.coords.x.toStringAsFixed(1)}, ${n.coords.y.toStringAsFixed(1)}, ${n.coords.z.toStringAsFixed(1)})'))).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => endNode = val);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: chosenSection,
                dropdownColor: const Color(0xFF131A29),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(labelText: 'AISC Section Profile', labelStyle: TextStyle(color: Colors.white70, fontSize: 11)),
                items: const [
                  DropdownMenuItem(value: 'W14X90', child: Text('W14X90 (Heavy Column)')),
                  DropdownMenuItem(value: 'W14X48', child: Text('W14X48 (Standard Column)')),
                  DropdownMenuItem(value: 'W18X35', child: Text('W18X35 (Floor Girder)')),
                  DropdownMenuItem(value: 'W12X26', child: Text('W12X26 (Secondary Beam)')),
                  DropdownMenuItem(value: 'W10X33', child: Text('W10X33 (Bracing Strut)')),
                  DropdownMenuItem(value: 'HSS8X8X.500', child: Text('HSS8X8X.500 (Tube)')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => chosenSection = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F0FF), foregroundColor: Colors.black),
              onPressed: () {
                if (startNode == endNode) {
                  _showToolSnackBar('Start and end joints must be different.');
                  return;
                }
                Navigator.of(ctx).pop();
                final newId = 'M_${_model.members.length + 1}';
                final member = StructuralMember(
                  id: newId,
                  iNodeId: startNode,
                  jNodeId: endNode,
                  section: chosenSection,
                  material: 'A992_STEEL',
                );
                _model.members.add(member);
                _selectedMemberId = newId;
                _selectedNodeId = null;
                _commitModelMutation('Drawn Member $newId ($chosenSection) connecting $startNode ➔ $endNode');
              },
              child: const Text('Draw Member', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _extrudeStory() {
    if (_model.nodes.isEmpty) {
      _showToolSnackBar('No joints on canvas to extrude. Draw joints or synthesize a frame first.');
      return;
    }
    _saveUndoState();
    double maxY = _model.nodes.map((n) => n.coords.y).reduce(math.max);
    final topNodes = _model.nodes.where((n) => (n.coords.y - maxY).abs() < 0.1).toList();
    if (topNodes.isEmpty) return;

    final double storyH = 3.6;
    final double newY = maxY + storyH;
    final Map<String, String> oldToNew = {};

    for (final oldN in topNodes) {
      final newId = 'N_${_model.nodes.length + 1}';
      final newNode = StructuralNode(
        id: newId,
        coords: Vector3(oldN.coords.x, newY, oldN.coords.z),
        restraint: [0, 0, 0, 0, 0, 0],
        loads: [0.0, -35000.0, 0.0, 0.0, 0.0, 0.0],
      );
      _model.nodes.add(newNode);
      oldToNew[oldN.id] = newId;

      _model.members.add(
        StructuralMember(
          id: 'COL_${_model.members.length + 1}',
          iNodeId: oldN.id,
          jNodeId: newId,
          section: 'W14X48',
          material: 'A992_STEEL',
        ),
      );
    }

    for (final m in List<StructuralMember>.from(_model.members)) {
      if (oldToNew.containsKey(m.iNodeId) && oldToNew.containsKey(m.jNodeId)) {
        _model.members.add(
          StructuralMember(
            id: 'BM_${_model.members.length + 1}',
            iNodeId: oldToNew[m.iNodeId]!,
            jNodeId: oldToNew[m.jNodeId]!,
            section: 'W18X35',
            material: 'A992_STEEL',
          ),
        );
      }
    }

    String loadMsg = '';
    if (_autoPropagateLoads) {
      final summary = TributaryLoadPropagator.propagate(model: _model);
      loadMsg = ' • Auto-Propagated Tributary: ${summary.totalFloorAreaM2.toStringAsFixed(0)}m² (Grav: ${summary.totalFactoredGravityLoadKn.toStringAsFixed(0)}kN, Wind V: ${summary.totalWindBaseShearKn.toStringAsFixed(0)}kN)';
    }

    _commitModelMutation('Generated Story Level ${(newY / storyH).round()} at Y=${newY.toStringAsFixed(1)}m (+${topNodes.length} columns & beams)$loadMsg', refitCamera: true);
  }

  void _extendBayX() {
    if (_model.nodes.isEmpty) return;
    _saveUndoState();
    double maxX = _model.nodes.map((n) => n.coords.x).reduce(math.max);
    final sideNodes = _model.nodes.where((n) => (n.coords.x - maxX).abs() < 0.1).toList();
    if (sideNodes.isEmpty) return;

    final double bayWidth = 6.0;
    final double newX = maxX + bayWidth;
    final Map<String, String> oldToNew = {};

    for (final oldN in sideNodes) {
      final newId = 'N_${_model.nodes.length + 1}';
      final isBase = oldN.coords.y.abs() < 0.05;
      final newNode = StructuralNode(
        id: newId,
        coords: Vector3(newX, oldN.coords.y, oldN.coords.z),
        restraint: isBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0],
        loads: isBase ? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0] : [0.0, -25000.0, 0.0, 0.0, 0.0, 0.0],
      );
      _model.nodes.add(newNode);
      oldToNew[oldN.id] = newId;

      if (!isBase) {
        _model.members.add(
          StructuralMember(
            id: 'BM_${_model.members.length + 1}',
            iNodeId: oldN.id,
            jNodeId: newId,
            section: 'W18X35',
            material: 'A992_STEEL',
          ),
        );
      }
    }

    for (final m in List<StructuralMember>.from(_model.members)) {
      if (oldToNew.containsKey(m.iNodeId) && oldToNew.containsKey(m.jNodeId)) {
        _model.members.add(
          StructuralMember(
            id: 'M_${_model.members.length + 1}',
            iNodeId: oldToNew[m.iNodeId]!,
            jNodeId: oldToNew[m.jNodeId]!,
            section: m.section,
            material: m.material,
          ),
        );
      }
    }

    String loadMsgX = '';
    if (_autoPropagateLoads) {
      final summary = TributaryLoadPropagator.propagate(model: _model);
      loadMsgX = ' • Auto-Propagated Tributary: ${summary.totalFloorAreaM2.toStringAsFixed(0)}m²';
    }

    _commitModelMutation('Extended Frame: Added +6m Bay along X-axis (X=${newX.toStringAsFixed(1)}m)$loadMsgX', refitCamera: true);
  }

  void _extendBayZ() {
    if (_model.nodes.isEmpty) return;
    _saveUndoState();
    double maxZ = _model.nodes.map((n) => n.coords.z).reduce(math.max);
    final rearNodes = _model.nodes.where((n) => (n.coords.z - maxZ).abs() < 0.1).toList();
    if (rearNodes.isEmpty) return;

    final double bayDepth = 6.0;
    final double newZ = maxZ + bayDepth;
    final Map<String, String> oldToNew = {};

    for (final oldN in rearNodes) {
      final newId = 'N_${_model.nodes.length + 1}';
      final isBase = oldN.coords.y.abs() < 0.05;
      final newNode = StructuralNode(
        id: newId,
        coords: Vector3(oldN.coords.x, oldN.coords.y, newZ),
        restraint: isBase ? [1, 1, 1, 1, 1, 1] : [0, 0, 0, 0, 0, 0],
        loads: isBase ? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0] : [0.0, -25000.0, 0.0, 0.0, 0.0, 0.0],
      );
      _model.nodes.add(newNode);
      oldToNew[oldN.id] = newId;

      if (!isBase) {
        _model.members.add(
          StructuralMember(
            id: 'BM_${_model.members.length + 1}',
            iNodeId: oldN.id,
            jNodeId: newId,
            section: 'W18X35',
            material: 'A992_STEEL',
          ),
        );
      }
    }

    for (final m in List<StructuralMember>.from(_model.members)) {
      if (oldToNew.containsKey(m.iNodeId) && oldToNew.containsKey(m.jNodeId)) {
        _model.members.add(
          StructuralMember(
            id: 'M_${_model.members.length + 1}',
            iNodeId: oldToNew[m.iNodeId]!,
            jNodeId: oldToNew[m.jNodeId]!,
            section: m.section,
            material: m.material,
          ),
        );
      }
    }

    String loadMsgZ = '';
    if (_autoPropagateLoads) {
      final summary = TributaryLoadPropagator.propagate(model: _model);
      loadMsgZ = ' • Auto-Propagated Tributary: ${summary.totalFloorAreaM2.toStringAsFixed(0)}m²';
    }

    _commitModelMutation('Extended Frame: Added +6m Bay along Z-axis (Z=${newZ.toStringAsFixed(1)}m)$loadMsgZ', refitCamera: true);
  }

  void _addXBracing() {
    _saveUndoState();
    int addedCount = 0;
    for (int i = 0; i < _model.nodes.length; i++) {
      for (int j = i + 1; j < _model.nodes.length; j++) {
        final n1 = _model.nodes[i];
        final n2 = _model.nodes[j];
        final dx = (n1.coords.x - n2.coords.x).abs();
        final dy = (n1.coords.y - n2.coords.y).abs();
        final dz = (n1.coords.z - n2.coords.z).abs();

        if (dy >= 2.5 && dy <= 5.5 && ((dx >= 3.0 && dx <= 12.0 && dz < 0.1) || (dz >= 3.0 && dz <= 12.0 && dx < 0.1))) {
          final alreadyConnected = _model.members.any((m) =>
              (m.iNodeId == n1.id && m.jNodeId == n2.id) ||
              (m.iNodeId == n2.id && m.jNodeId == n1.id));
          if (!alreadyConnected && addedCount < 8) {
            _model.members.add(
              StructuralMember(
                id: 'BRACE_${_model.members.length + 1}',
                iNodeId: n1.id,
                jNodeId: n2.id,
                section: 'W10X33',
                material: 'A992_STEEL',
              ),
            );
            addedCount++;
          }
        }
      }
    }

    _commitModelMutation('Added $addedCount Lateral Bracing Struts to bays');
  }

  void _subdivideMember() {
    StructuralMember? target;
    if (_selectedMemberId != null) {
      target = _model.members.firstWhere((m) => m.id == _selectedMemberId, orElse: () => _model.members.first);
    } else if (_model.members.isNotEmpty) {
      target = _model.members.first;
    }
    if (target == null) return;

    final nI = _model.getNode(target.iNodeId);
    final nJ = _model.getNode(target.jNodeId);
    if (nI == null || nJ == null) return;
    _saveUndoState();

    final mid = (nI.coords + nJ.coords) * 0.5;
    final midId = 'N_${_model.nodes.length + 1}';
    final midNode = StructuralNode(
      id: midId,
      coords: mid,
      restraint: [0, 0, 0, 0, 0, 0],
      loads: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    );
    _model.nodes.add(midNode);

    _model.members.removeWhere((m) => m.id == target!.id);
    _model.members.add(
      StructuralMember(
        id: '${target.id}_A',
        iNodeId: target.iNodeId,
        jNodeId: midId,
        section: target.section,
        material: target.material,
      ),
    );
    _model.members.add(
      StructuralMember(
        id: '${target.id}_B',
        iNodeId: midId,
        jNodeId: target.jNodeId,
        section: target.section,
        material: target.material,
      ),
    );

    _selectedNodeId = midId;
    _selectedMemberId = null;
    _commitModelMutation('Subdivided ${target.id} at midpoint. Added Joint $midId.');
  }

  void _showParametricBuildingDialog() {
    int stories = 3;
    int baysX = 2;
    int baysZ = 2;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF0C1322),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00F0FF), width: 1.2),
          ),
          title: Row(
            children: const [
              Icon(Icons.apartment_rounded, color: Color(0xFF00F0FF), size: 20),
              SizedBox(width: 8),
              Text('Parametric Building Synthesizer', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Number of Stories: $stories', style: const TextStyle(color: Colors.white, fontSize: 12)),
              Slider(
                value: stories.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                activeColor: const Color(0xFF00F0FF),
                onChanged: (v) => setDlgState(() => stories = v.round()),
              ),
              const SizedBox(height: 8),
              Text('Bays along X: $baysX', style: const TextStyle(color: Colors.white, fontSize: 12)),
              Slider(
                value: baysX.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: const Color(0xFF00F0FF),
                onChanged: (v) => setDlgState(() => baysX = v.round()),
              ),
              const SizedBox(height: 8),
              Text('Bays along Z: $baysZ', style: const TextStyle(color: Colors.white, fontSize: 12)),
              Slider(
                value: baysZ.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                activeColor: const Color(0xFF00F0FF),
                onChanged: (v) => setDlgState(() => baysZ = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F0FF), foregroundColor: Colors.black),
              onPressed: () {
                Navigator.of(ctx).pop();
                final synthesized = BuildingGeneratorService.generateParametricBuilding(
                  numStories: stories,
                  baysX: baysX,
                  baysZ: baysZ,
                  bayWidthX: 6.0,
                  bayDepthZ: 6.0,
                  storyHeight: 3.6,
                );
                _model = synthesized;
                _selectedNodeId = null;
                _selectedMemberId = null;
                _commitModelMutation('Synthesized $stories-Story, ${baysX}x$baysZ Bay Frame (${_model.nodes.length} joints, ${_model.members.length} members)', refitCamera: true);
              },
              child: const Text('Synthesize', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _assignSupport(List<int> restraint, String name) {
    _saveUndoState();
    int count = 0;
    if (_selectedNodeId != null) {
      final n = _model.getNode(_selectedNodeId!);
      if (n != null) {
        n.restraint = List<int>.from(restraint);
        count = 1;
      }
    } else {
      for (final n in _model.nodes) {
        if (n.coords.y.abs() < 0.1) {
          n.restraint = List<int>.from(restraint);
          count++;
        }
      }
    }
    _commitModelMutation('Assigned $name Restraints ($count joints updated)');
  }

  void _assignSection(String sectionName) {
    _saveUndoState();
    int count = 0;
    if (_selectedMemberId != null) {
      final m = _model.getMember(_selectedMemberId!);
      if (m != null) {
        m.section = sectionName;
        count = 1;
      }
    } else {
      for (final m in _model.members) {
        m.section = sectionName;
        count++;
      }
    }
    _commitModelMutation('Assigned $sectionName ($count members updated)');
  }

  void _applyGravityLoads(double fyN) {
    _saveUndoState();
    int count = 0;
    if (_selectedNodeId != null) {
      final n = _model.getNode(_selectedNodeId!);
      if (n != null) {
        n.loads[1] = fyN;
        count = 1;
      }
    } else {
      double maxY = _model.nodes.map((n) => n.coords.y).reduce(math.max);
      for (final n in _model.nodes) {
        if ((n.coords.y - maxY).abs() < 0.1) {
          n.loads[1] = fyN;
          count++;
        }
      }
    }
    _commitModelMutation('Applied ${(fyN / 1000).toStringAsFixed(1)} kN Gravity Load ($count roof joints)');
  }

  void _applyWindLoads(double fxN) {
    if (_model.nodes.isEmpty) return;
    _saveUndoState();
    double minX = _model.nodes.map((n) => n.coords.x).reduce(math.min);
    int count = 0;
    for (final n in _model.nodes) {
      if ((n.coords.x - minX).abs() < 0.1 && n.coords.y > 0.1) {
        n.loads[0] = fxN;
        count++;
      }
    }
    _commitModelMutation('Applied +${(fxN / 1000).toStringAsFixed(1)} kN Lateral Wind Shear ($count windward joints)');
  }

  void _deleteSelectedEntity() {
    if (_selectedNodeId != null) {
      final nid = _selectedNodeId!;
      final removedMembers = _model.members.where((m) => m.iNodeId == nid || m.jNodeId == nid).length;
      _model.members.removeWhere((m) => m.iNodeId == nid || m.jNodeId == nid);
      _model.nodes.removeWhere((n) => n.id == nid);
      _selectedNodeId = null;
      _commitModelMutation('Deleted Joint $nid and $removedMembers attached members', refitCamera: true);
    } else if (_selectedMemberId != null) {
      final mid = _selectedMemberId!;
      _model.members.removeWhere((m) => m.id == mid);
      _selectedMemberId = null;
      _commitModelMutation('Deleted Member $mid');
    } else {
      _showToolSnackBar('Click a joint or member on canvas to select before deleting.');
    }
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C1322),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Canvas?', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        content: const Text('This will remove all current building elements and leave a clean drawing grid.', style: TextStyle(color: Colors.white70, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              _model.nodes.clear();
              _model.members.clear();
              _selectedNodeId = null;
              _selectedMemberId = null;
              _commitModelMutation('Canvas cleared. Ready to draw new structures.', refitCamera: true);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showToolSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF131A29),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF00F0FF), width: 0.8),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00F0FF), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void onOpenCopilot() => _requireAuth(
      featureName: 'AI Structural Copilot',
      onAuthenticated: () => AiCopilotDialog.show(
        context,
        model: _model,
        apiService: _apiService,
        onStructureModified: _triggerSolve,
      ),
    );

    void onOpenGenerativeOptimizer() => _requireAuth(
      featureName: 'Generative AI Section Auto-Sizer',
      onAuthenticated: () => GenerativeOptimizerDialog.show(
        context,
        model: _model,
        apiService: _apiService,
        onStructureModified: _triggerSolve,
      ),
    );

    void onOpenGenerativeBracing() => _requireAuth(
      featureName: 'Generative Bracing Synthesizer',
      onAuthenticated: () => GenerativeBracingDialog.show(
        context,
        model: _model,
        apiService: _apiService,
        onStructureModified: () => setState(() => _triggerSolve()),
      ),
    );

    void onOptimize() => _requireAuth(
      featureName: 'AISC Section Auto-Sizer',
      onAuthenticated: _optimizeSections,
    );

    void onOpenCadStudio() => _requireAuth(
      featureName: 'Structural CAD Studio',
      onAuthenticated: () {
        showDialog(
          context: context,
          builder: (ctx) => StructuralCadEditorDialog(
            initialModel: _model,
            onModelCommitted: _importBuildingModel,
          ),
        );
      },
    );

    void onOpenLibrary() => _requireAuth(
      featureName: 'AISC Structural Library & DXF Export',
      onAuthenticated: () {
        showDialog(
          context: context,
          builder: (ctx) => StructuralLibraryDialog(
            currentModel: _model,
            onModelSelected: _importBuildingModel,
          ),
        );
      },
    );

    void onOpenBuildingTemplates() {
      showDialog(
        context: context,
        builder: (ctx) => BuildingTemplatesDialog(
          currentModel: _model,
          onModelSelected: _importBuildingModel,
        ),
      );
    }

    void onOpenMacAiInspector() {
      showDialog(
        context: context,
        builder: (ctx) => MacNeuralInspectorDialog(
          currentModel: _model,
        ),
      );
    }

    void onOpenAutonomousSwarm() {
      AutonomousSwarmDialog.show(
        context,
        model: _model,
        onStructureModified: () {
          _saveUndoState();
          _commitModelMutation('Applied Swarm-Healed AISC 360-16 Topology to 3D Frame');
        },
      );
    }

    void onOpenParetoExplorer() {
      ParetoFrontierDock.show(
        context,
        model: _model,
        onCommit: (optimized) {
          _saveUndoState();
          _model = optimized;
          _commitModelMutation('Committed Pareto Optimal Design to 3D Viewport');
          _triggerSolve();
        },
      );
    }

    void onOpenGenerativeTopology() {
      showDialog(
        context: context,
        builder: (ctx) => GenerativeTopologyDialog(
          currentModel: _model,
          onCommitModel: (newModel) {
            _saveUndoState();
            setState(() {
              _model = newModel;
              _selectedNodeId = null;
              _selectedMemberId = null;
              _selectedNodeIds.clear();
              _selectedMemberIds.clear();
            });
            _commitModelMutation('Committed 3D Diagrid Exoskeleton to Viewport');
            _triggerSolve();
          },
        ),
      );
    }

    void onOpenShopDrawingAudit() {
      showDialog(
        context: context,
        builder: (ctx) => const ShopDrawingAuditDialog(),
      );
    }

    void onOpenSeismicModal() => _requireAuth(
      featureName: 'Dynamic Modal Vibration Analysis',
      onAuthenticated: () => SeismicModalDialog.show(
        context,
        model: _model,
        apiService: _apiService,
        onActivateVibration: (modeIndex, offsets) {
          setState(() {
            _model.activeVibrationMode = modeIndex;
            _model.modalShapeOffsets = offsets;
            _model.displayMode = DisplayMode.modalVibration;
          });
        },
      ),
    );

    void onOpenLateralStability() => _requireAuth(
      featureName: 'ASCE 7 Lateral Hazard & Stability Engine',
      onAuthenticated: () {
        LateralStabilityDialog.show(
          context,
          model: _model,
          apiService: _apiService,
          onStructureModified: () {
            setState(() {
              _triggerSolve();
            });
          },
        );
      },
    );

    void onOpenPePacket() => _requireAuth(
      featureName: 'PE Stamped Calculation Packet',
      onAuthenticated: () => PePacketDialog.show(
        context,
        model: _model,
        apiService: _apiService,
        onStructureModified: () => setState(() => _triggerSolve()),
      ),
    );

    void onOpenEmbodiedCarbon() => _requireAuth(
      featureName: 'Embodied Carbon Life Cycle Assessment',
      onAuthenticated: () => EmbodiedCarbonDialog.show(
        context,
        model: _model,
        apiService: _apiService,
      ),
    );

    void onOpenConcreteStudio() => _requireAuth(
      featureName: 'Proprietary Concrete Studio',
      onAuthenticated: () {
        showDialog(
          context: context,
          builder: (ctx) => ConcretePmDialog(
            onRequireAuth: (feat, cb) => _requireAuth(featureName: feat, onAuthenticated: cb),
          ),
        );
      },
    );

    void onOpenSteelConnections() => _requireAuth(
      featureName: 'Steel Connection Studio',
      onAuthenticated: () {
        showDialog(
          context: context,
          builder: (ctx) => SteelConnectionDialog(
            onRequireAuth: (feat, cb) => _requireAuth(featureName: feat, onAuthenticated: cb),
          ),
        );
      },
    );

    void onOpenGeotechnicalFoundation() => _requireAuth(
      featureName: 'Geotechnical Foundation Studio (ACI 318-19)',
      onAuthenticated: () => FoundationStudioDialog.show(
        context,
        model: _model,
        apiService: _apiService,
        onStructureModified: () => setState(() => _triggerSolve()),
      ),
    );

    void onOpenVisionToBim() => _requireAuth(
      featureName: 'Vision-to-BIM Floorplan Ingestion',
      onAuthenticated: () => VisionIngestionDialog.show(
        context,
        apiService: _apiService,
        onModelSynthesized: _importBuildingModel,
      ),
    );

    void onOpenNltha() => _requireAuth(
      featureName: 'Dynamic Non-Linear Time History Analysis (NLTHA)',
      onAuthenticated: () {
        setState(() {
          _isNlthaActive = true;
        });
      },
    );

    void onOpenPushoverAnalysis() => _requireAuth(
      featureName: 'Non-Linear Pushover Studio',
      onAuthenticated: () {
        showDialog(
          context: context,
          builder: (ctx) => PushoverAnalysisDialog(
            onRequireAuth: (feat, cb) => _requireAuth(featureName: feat, onAuthenticated: cb),
          ),
        );
      },
    );

    void onOpenWindCfd() => _requireAuth(
      featureName: 'Wind Tunnel CFD Studio',
      onAuthenticated: () {
        showDialog(
          context: context,
          builder: (ctx) => WindCfdDialog(
            onRequireAuth: (feat, cb) => _requireAuth(featureName: feat, onAuthenticated: cb),
          ),
        );
      },
    );

    void onOpenCompositeFloor() => _requireAuth(
      featureName: 'Composite Floor Studio',
      onAuthenticated: () {
        showDialog(
          context: context,
          builder: (ctx) => CompositeFloorDialog(
            onRequireAuth: (feat, cb) => _requireAuth(featureName: feat, onAuthenticated: cb),
          ),
        );
      },
    );

    void onOpenEnvironmentalStimulator() => _requireAuth(
      featureName: 'Dynamic Environmental Stimulator',
      onAuthenticated: () {
        showDialog(
          context: context,
          builder: (ctx) => EnvironmentalStimulatorDialog(
            model: _model,
            onStructureModified: _triggerSolve,
            onModelReplaced: _importBuildingModel,
            onRequireAuth: (feat, cb) => _requireAuth(featureName: feat, onAuthenticated: cb),
          ),
        );
      },
    );

    void onOpenCollaborationReview() => _requireAuth(
      featureName: 'Real-Time Cloud Collaboration & Revision Diffing',
      onAuthenticated: () {
        CollaborationReviewDialog.show(
          context,
          model: _model,
          onStructureModified: () => setState(() => _triggerSolve()),
        );
      },
    );

    void onOpenProgressiveCollapse() => _openProgressiveCollapse();

    void onOpenCommandPalette() => _openCommandPalette();

    double maxDcr = 0.0;
    int passCount = 0;
    int failCount = 0;
    int warnCount = 0;

    for (final m in _model.members) {
      if (m.governingDcr > maxDcr) maxDcr = m.governingDcr;
      if (m.governingDcr > 1.0) {
        failCount++;
      } else if (m.governingDcr > 0.85) {
        warnCount++;
      } else {
        passCount++;
      }
    }

    final isOverallPass = failCount == 0;
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 700 || screenSize.height < 500;
    final showInspector = _isInspectorOpen ?? !isCompact;
    final defaultInspectorTop = MediaQuery.paddingOf(context).top + (isCompact ? 68.0 : 70.0);
    final maxInspectorTop = (screenSize.height - 240.0).clamp(70.0, 1000.0);
    final effectiveInspectorTop = (_inspectorTopOffset ?? defaultInspectorTop).clamp(60.0, maxInspectorTop);
    final inspectorBottomOffset = MediaQuery.paddingOf(context).bottom + (isCompact ? 200.0 : 225.0);

    return Focus(
      autofocus: true,
      onKeyEvent: _handleGlobalKeyEvent,
      child: Scaffold(
        key: _scaffoldKey,
      backgroundColor: const Color(0xFF070B12), // Deep canvas black
      drawer: WorkstationDrawer(
        onOpenCopilot: onOpenCopilot,
        onOpenGenerativeOptimizer: onOpenGenerativeOptimizer,
        onOpenGenerativeBracing: onOpenGenerativeBracing,
        onOptimize: onOptimize,
        onOpenCadStudio: onOpenCadStudio,
        onOpenLibrary: onOpenLibrary,
        onOpenBuildingTemplates: onOpenBuildingTemplates,
        onOpenMacAiInspector: onOpenMacAiInspector,
        onOpenConcreteStudio: onOpenConcreteStudio,
        onOpenSteelConnections: onOpenSteelConnections,
        onOpenGeotechnicalFoundation: onOpenGeotechnicalFoundation,
        onOpenCompositeFloor: onOpenCompositeFloor,
        onOpenSeismicModal: onOpenSeismicModal,
        onOpenLateralStability: onOpenLateralStability,
        onOpenPushoverAnalysis: onOpenPushoverAnalysis,
        onOpenWindCfd: onOpenWindCfd,
        onOpenPePacket: onOpenPePacket,
        onOpenEmbodiedCarbon: onOpenEmbodiedCarbon,
        onOpenEnvironmentalStimulator: onOpenEnvironmentalStimulator,
        onOpenVisionToBim: onOpenVisionToBim,
        onOpenNltha: onOpenNltha,
        onPresetSelected: (presetKey) => _loadPreset(presetKey),
      ),
      body: Stack(
        children: [
          // 1. Layer 0: Fullscreen Hardware-Accelerated 3D WebGL Canvas
          Positioned.fill(
            child: Structural3DViewport(
              key: _viewportKey,
              model: _model,
              modelRevision: _modelRevision,
              selectedNodeId: _selectedNodeId,
              selectedMemberId: _selectedMemberId,
              onNodeSelected: (id) {
                setState(() {
                  _selectedNodeId = id;
                  _selectedNodeIds.clear();
                  _selectedMemberIds.clear();
                  if (id != null) {
                    _selectedNodeIds.add(id);
                    _selectedMemberId = null;
                    _setInspectorOpen(true);
                  }
                });
              },
              onMemberSelected: (id) {
                setState(() {
                  _selectedMemberId = id;
                  _selectedNodeIds.clear();
                  _selectedMemberIds.clear();
                  if (id != null) {
                    _selectedMemberIds.add(id);
                    _selectedNodeId = null;
                    _setInspectorOpen(true);
                  }
                });
              },
              onMultiSelectChanged: (nodeIds, memberIds) {
                setState(() {
                  _selectedNodeIds.clear();
                  _selectedNodeIds.addAll(nodeIds);
                  _selectedMemberIds.clear();
                  _selectedMemberIds.addAll(memberIds);
                  _selectedNodeId = nodeIds.length == 1 ? nodeIds.first : null;
                  _selectedMemberId = memberIds.length == 1 ? memberIds.first : null;
                  if (nodeIds.isNotEmpty || memberIds.isNotEmpty) {
                    _setInspectorOpen(true);
                  }
                });
              },
              onNodeDragged: (nodeId, x, y, z) {
                if (!_isUserLoggedIn) {
                  _requireAuth(
                    featureName: 'Kinetic Real-Time Geometry Morphing',
                    onAuthenticated: () {},
                  );
                  return;
                }
                _model.updateNodeCoords(nodeId, x, y, z);
                _surrogateStreamer.onNodeDragged(
                  model: _model,
                  onDisplacementsUpdated: (displacements) {
                    setState(() {
                      _model.updatePredictedDisplacements(displacements);
                    });
                  },
                );
              },
              onNodeDragEnd: (nodeId, x, y, z) {
                if (!_isUserLoggedIn) return;
                setState(() {
                  _model.updateNodeCoords(nodeId, x, y, z);
                  EmbeddedFeaSolver.solve(_model);
                  _triggerSolve();
                });
              },
            ),
          ),

          // 2. Layer 1: Single Unified Floating Header Island (Top Scrolling Option Bar)
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            child: FloatingWorkstationHeader(
              model: _model,
              isBackendConnected: _apiService.isConnected,
              useThreeJs: _viewportKey.currentState?.useThreeJs ?? true,
              onToggleRenderer: () {
                _viewportKey.currentState?.toggleRenderer();
                setState(() {});
              },
              onCameraPreset: (preset) => _viewportKey.currentState?.setCameraPreset(preset),
              onZoomIn: () => _viewportKey.currentState?.zoomIn(),
              onZoomOut: () => _viewportKey.currentState?.zoomOut(),
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              onOpenCopilot: onOpenCopilot,
              onOpenGenerativeOptimizer: onOpenGenerativeOptimizer,
              onOpenGenerativeBracing: onOpenGenerativeBracing,
              onOpenCadStudio: onOpenCadStudio,
              onOpenLibrary: onOpenLibrary,
              onOpenSeismicModal: onOpenSeismicModal,
              onOpenLateralStability: onOpenLateralStability,
              onOpenPePacket: onOpenPePacket,
              onOpenEmbodiedCarbon: onOpenEmbodiedCarbon,
              onOpenConcreteStudio: onOpenConcreteStudio,
              onOpenSteelConnections: onOpenSteelConnections,
              onOpenGeotechnicalFoundation: onOpenGeotechnicalFoundation,
              onOpenPushoverAnalysis: onOpenPushoverAnalysis,
              onOpenWindCfd: onOpenWindCfd,
              onOpenCompositeFloor: onOpenCompositeFloor,
              onOpenEnvironmentalStimulator: onOpenEnvironmentalStimulator,
              onOpenVisionToBim: onOpenVisionToBim,
              onOpenNltha: onOpenNltha,
              onOptimize: onOptimize,
              onOpenBuildingTemplates: onOpenBuildingTemplates,
              onOpenMacAiInspector: onOpenMacAiInspector,
              onOpenAutonomousSwarm: onOpenAutonomousSwarm,
              onOpenParetoExplorer: onOpenParetoExplorer,
              onOpenGenerativeTopology: onOpenGenerativeTopology,
              onOpenShopDrawingAudit: onOpenShopDrawingAudit,
              onOpenCollaborationReview: onOpenCollaborationReview,
              onOpenProgressiveCollapse: onOpenProgressiveCollapse,
              onOpenCommandPalette: onOpenCommandPalette,
              onUndo: _undo,
              onRedo: _redo,
              canUndo: _undoStack.isNotEmpty,
              canRedo: _redoStack.isNotEmpty,
              onEngineChanged: (engine) {
                _requireAuth(
                  featureName: 'Solver Engine Switcher',
                  onAuthenticated: () {
                    setState(() {
                      _model.activeEngine = engine;
                      _triggerSolve();
                    });
                  },
                );
              },
              onModeChanged: (mode) => setState(() => _model.displayMode = mode),
              onDeformationScaleChanged: (scale) => setState(() => _model.deformationScale = scale),
              onPresetSelected: (presetKey) => _loadPreset(presetKey),
              onSolveTriggered: _triggerSolve,
              onOpenAuth: () {
                if (_isUserLoggedIn) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AuthDialog(
                      onAuthSuccess: () => setState(() {}),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AuthScreen(
                        onLoginSuccess: () => setState(() {}),
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // 3. Layer 2: Floating Telemetry Dock (Bottom Island)
          if (_isNlthaActive)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + (isCompact ? 175.0 : 160.0),
              left: isCompact ? 10 : 20,
              right: isCompact ? 10 : 20,
              child: TimeHistoryPlayer(
                model: _model,
                apiService: _apiService,
                onClose: () => setState(() => _isNlthaActive = false),
                onTimeStepChanged: (timeSec, nodeOffsets) {
                  setState(() {
                    for (final entry in nodeOffsets.entries) {
                      final n = _model.getNode(entry.key);
                      if (n != null && entry.value.isNotEmpty) {
                        n.dispX = entry.value[0];
                        if (entry.value.length > 1) n.dispY = entry.value[1];
                        if (entry.value.length > 2) n.dispZ = entry.value[2];
                      }
                    }
                  });
                },
              ),
            ),

          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 6,
            left: 0,
            right: 0,
            child: FloatingTelemetryDock(
              maxDcr: maxDcr,
              isPass: isOverallPass,
              passCount: passCount,
              warnCount: warnCount,
              failCount: failCount,
              baseShearKn: _model.baseShearN / 1000.0,
              driftRatio: _model.maxDriftRatio,
              alphaCr: _model.alphaCr,
              b2Amp: _model.b2SwayMultiplier,
              activeLoadCombination: _model.loadCombination,
              onCombinationChanged: (combo) {
                setState(() {
                  _model.loadCombination = combo;
                  _triggerSolve();
                });
              },
              onAutoSizerPressed: onOptimize,
              onStabilityPressed: onOpenLateralStability,
              onParetoPressed: onOpenParetoExplorer,
            ),
          ),

          // Layer 2.5: v4.2 Gemini Live Spatial Voice Co-Pilot Floating Pill
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 72,
            right: 18,
            child: VoiceCopilotPill(
              getCurrentModelState: () => _model.toGraphPayload('VOICE_STATE'),
            ),
          ),

          // 4. Layer 3: Contextual 3D Workspace Drawing & Modeling Toolbox
          SlideableWorkspaceMenu(
            key: _workspaceMenuKey,
            workspaceKey: 'main_workstation',
            title: 'WORKSPACE TOOLS',
            subtitle: '3D Drawing, Building & Modeling Tools',
            badgeText: 'DRAWING',
            initialTop: 76.0,
            initialExpanded: !isCompact,
            onAutoPropagateLoads: () {
              setState(() {
                _autoPropagateLoads = !_autoPropagateLoads;
                if (_autoPropagateLoads) {
                  _saveUndoState();
                  final summary = TributaryLoadPropagator.propagate(model: _model);
                  _commitModelMutation('Auto-Propagated Tributary Loads across ${summary.storyCount} stories (${summary.totalFloorAreaM2.toStringAsFixed(0)} m²)');
                } else {
                  _showToolSnackBar('Auto-propagation paused. Manual nodal loads active.');
                }
              });
            },
            customCategories: const ['ALL', 'DRAW & MODEL', 'ASSIGN & RESTRAIN', 'LOADS', 'CANVAS'],
            onOpenProgressiveCollapse: _openProgressiveCollapse,
            customTools: [
              // 1. DRAW & MODEL
              WorkspaceToolItem(
                label: 'Building Templates',
                subtitle: 'Browse & Import Towers, Warehouses & Bridges',
                icon: Icons.apartment_rounded,
                color: const Color(0xFF00F0FF),
                category: 'DRAW & MODEL',
                badge: '12 MODELS',
                onTap: onOpenBuildingTemplates,
              ),
              WorkspaceToolItem(
                label: 'Mac-Trained AI Suite',
                subtitle: 'Inspect & Benchmark 10 MPS Neural Engines',
                icon: Icons.memory_rounded,
                color: const Color(0xFF7EE787),
                category: 'DRAW & MODEL',
                badge: 'MPS GPU',
                onTap: onOpenMacAiInspector,
              ),
              WorkspaceToolItem(
                label: 'Add 3D Joint / Node',
                subtitle: 'Place new joint at (X, Y, Z)',
                icon: Icons.add_location_alt_rounded,
                color: const Color(0xFF00F0FF),
                category: 'DRAW & MODEL',
                badge: 'COORD',
                onTap: _showAddJointDialog,
              ),
              WorkspaceToolItem(
                label: 'Draw Member / Beam',
                subtitle: 'Link 2 joints with AISC profile',
                icon: Icons.architecture_rounded,
                color: const Color(0xFF38BDF8),
                category: 'DRAW & MODEL',
                badge: 'CONNECT',
                onTap: _showDrawMemberDialog,
              ),
              WorkspaceToolItem(
                label: 'Extrude Story (+Level)',
                subtitle: 'Duplicate top floor up (+3.6m)',
                icon: Icons.domain_add_rounded,
                color: const Color(0xFF10B981),
                category: 'DRAW & MODEL',
                badge: '+3.6m',
                onTap: _extrudeStory,
              ),
              WorkspaceToolItem(
                label: 'Extend Bay (+X Span)',
                subtitle: 'Add 6m lateral span along X',
                icon: Icons.view_column_rounded,
                color: const Color(0xFFF59E0B),
                category: 'DRAW & MODEL',
                badge: '+6m X',
                onTap: _extendBayX,
              ),
              WorkspaceToolItem(
                label: 'Extend Bay (+Z Depth)',
                subtitle: 'Add 6m depth span along Z',
                icon: Icons.aspect_ratio_rounded,
                color: const Color(0xFFF59E0B),
                category: 'DRAW & MODEL',
                badge: '+6m Z',
                onTap: _extendBayZ,
              ),
              WorkspaceToolItem(
                label: 'Add Structural X-Bracing',
                subtitle: 'Insert lateral bracing on bays',
                icon: Icons.close_rounded,
                color: Colors.purpleAccent,
                category: 'DRAW & MODEL',
                badge: 'BRACE',
                onTap: _addXBracing,
              ),
              WorkspaceToolItem(
                label: 'Subdivide Member',
                subtitle: 'Split member in half at midpoint',
                icon: Icons.call_split_rounded,
                color: const Color(0xFF00F0FF),
                category: 'DRAW & MODEL',
                badge: 'SPLIT',
                onTap: _subdivideMember,
              ),
              WorkspaceToolItem(
                label: 'Parametric Building Synthesizer',
                subtitle: 'Generate multi-story frame mesh',
                icon: Icons.apartment_rounded,
                color: const Color(0xFF10B981),
                category: 'DRAW & MODEL',
                badge: 'AUTO',
                onTap: _showParametricBuildingDialog,
              ),
              WorkspaceToolItem(
                label: 'Structural CAD Studio',
                subtitle: 'Full 2D/3D drafting canvas',
                icon: Icons.brush_rounded,
                color: const Color(0xFFF59E0B),
                category: 'DRAW & MODEL',
                badge: 'CAD',
                onTap: onOpenCadStudio,
              ),
              WorkspaceToolItem(
                label: 'Quick Command Palette (⌘K)',
                subtitle: 'Search all 30+ tools, codes & encyclopedia',
                icon: Icons.bolt_rounded,
                color: const Color(0xFF00F0FF),
                category: 'DRAW & MODEL',
                badge: '⌘K',
                codeRef: 'Shortcut: ⌘K / Ctrl+K',
                infoText:
                    'Opens the Spotlight-style Command Palette & Interactive Engineering Encyclopedia to search any solver, code reference, or modeling tool.',
                onTap: _openCommandPalette,
              ),

              // 2. ASSIGN & RESTRAIN
              WorkspaceToolItem(
                label: 'Assign Fixed Base',
                subtitle: '6-DOF fixed restraint [1,1,1,1,1,1]',
                icon: Icons.crop_square_rounded,
                color: const Color(0xFF00F0FF),
                category: 'ASSIGN & RESTRAIN',
                badge: 'FIXED',
                onTap: () => _assignSupport([1, 1, 1, 1, 1, 1], 'Fixed Base'),
              ),
              WorkspaceToolItem(
                label: 'Assign Pinned Base',
                subtitle: '3-DOF translation pinned [1,1,1,0,0,0]',
                icon: Icons.change_history_rounded,
                color: const Color(0xFF38BDF8),
                category: 'ASSIGN & RESTRAIN',
                badge: 'PINNED',
                onTap: () => _assignSupport([1, 1, 1, 0, 0, 0], 'Pinned Base'),
              ),
              WorkspaceToolItem(
                label: 'Assign Roller Support',
                subtitle: 'Vertical roller restraint [0,1,0,0,0,0]',
                icon: Icons.radio_button_unchecked_rounded,
                color: const Color(0xFF10B981),
                category: 'ASSIGN & RESTRAIN',
                badge: 'ROLLER',
                onTap: () => _assignSupport([0, 1, 0, 0, 0, 0], 'Roller Support'),
              ),
              WorkspaceToolItem(
                label: 'Assign W14X90 (Heavy Column)',
                subtitle: 'Apply heavy column section',
                icon: Icons.line_weight_rounded,
                color: const Color(0xFFF59E0B),
                category: 'ASSIGN & RESTRAIN',
                badge: 'W14X90',
                onTap: () => _assignSection('W14X90'),
              ),
              WorkspaceToolItem(
                label: 'Assign W18X35 (Girder Beam)',
                subtitle: 'Apply wide-flange girder section',
                icon: Icons.horizontal_rule_rounded,
                color: const Color(0xFFF59E0B),
                category: 'ASSIGN & RESTRAIN',
                badge: 'W18X35',
                onTap: () => _assignSection('W18X35'),
              ),
              WorkspaceToolItem(
                label: 'AISC Section Auto-Sizer',
                subtitle: 'Optimize profiles for minimum steel weight',
                icon: Icons.auto_fix_high_rounded,
                color: const Color(0xFF10B981),
                category: 'ASSIGN & RESTRAIN',
                badge: 'AISC 360',
                onTap: _optimizeSections,
              ),
              WorkspaceToolItem(
                label: 'Autonomous 4-Agent Swarm',
                subtitle: 'v4.0 Architect ↔ Auditor ↔ Self-Healer',
                icon: Icons.hub_rounded,
                color: const Color(0xFF00F0FF),
                category: 'ASSIGN & RESTRAIN',
                badge: 'v4.0 AI',
                onTap: onOpenAutonomousSwarm,
              ),

              // 3. LOADS
              WorkspaceToolItem(
                label: 'Auto-Propagate Floor & Wind Loads',
                subtitle: _autoPropagateLoads
                    ? '1.2D+1.6L (9.6 kPa) • ASCE 7-16 (45 m/s) [ACTIVE]'
                    : 'Tributary propagation paused [INACTIVE]',
                icon: Icons.sync_alt_rounded,
                color: _autoPropagateLoads ? const Color(0xFF10B981) : Colors.white38,
                category: 'LOADS',
                badge: _autoPropagateLoads ? 'AUTO ON' : 'PAUSED',
                onTap: () {
                  setState(() {
                    _autoPropagateLoads = !_autoPropagateLoads;
                    if (_autoPropagateLoads) {
                      _saveUndoState();
                      final summary = TributaryLoadPropagator.propagate(model: _model);
                      _commitModelMutation('Auto-Propagated Tributary Loads across ${summary.storyCount} stories (${summary.totalFloorAreaM2.toStringAsFixed(0)} m²)');
                    } else {
                      _showToolSnackBar('Auto-propagation paused. Manual nodal loads active.');
                    }
                  });
                },
              ),
              WorkspaceToolItem(
                label: 'Apply Floor Gravity Load',
                subtitle: 'Apply -50 kN downward load on roof/joint',
                icon: Icons.arrow_downward_rounded,
                color: Colors.redAccent,
                category: 'LOADS',
                badge: '-50 kN',
                onTap: () => _applyGravityLoads(-50000.0),
              ),
              WorkspaceToolItem(
                label: 'Apply Lateral Wind Load',
                subtitle: 'Apply +25 kN lateral shear on windward joints',
                icon: Icons.arrow_forward_rounded,
                color: const Color(0xFF00F0FF),
                category: 'LOADS',
                badge: '+25 kN',
                onTap: () => _applyWindLoads(25000.0),
              ),
              WorkspaceToolItem(
                label: 'Reset Nodal Loads',
                subtitle: 'Clear all applied loads to zero',
                icon: Icons.remove_circle_outline_rounded,
                color: Colors.white70,
                category: 'LOADS',
                badge: 'ZERO',
                onTap: () {
                  for (final n in _model.nodes) {
                    n.loads = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
                  }
                  _commitModelMutation('Cleared all applied loads.');
                },
              ),
              WorkspaceToolItem(
                label: 'Progressive Collapse (UFC 4-023-03)',
                subtitle: 'Notional column removal & catenary bridging',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFEF4444),
                category: 'LOADS',
                badge: 'ALP',
                codeRef: 'UFC 4-023-03 & GSA',
                infoText:
                    'Evaluates structural survivability under sudden column loss with Ω_LD = 2.0 dynamic amplification, ranking column vulnerability and catenary chord rotations.',
                onTap: _openProgressiveCollapse,
              ),

              // 4. CANVAS
              WorkspaceToolItem(
                label: 'Delete Selected Joint/Member',
                subtitle: 'Remove the active element from frame',
                icon: Icons.delete_sweep_rounded,
                color: Colors.redAccent,
                category: 'CANVAS',
                badge: 'DELETE',
                onTap: _deleteSelectedEntity,
              ),
              WorkspaceToolItem(
                label: 'Toggle Extruded BMD/SFD',
                subtitle: 'Cycle 3D Moment & Shear ribbon display',
                icon: Icons.show_chart_rounded,
                color: const Color(0xFF00F0FF),
                category: 'CANVAS',
                badge: '3D BMD',
                onTap: () {
                  setState(() {
                    _modelRevision++;
                    if (_model.displayMode != DisplayMode.bmdRibbon &&
                        _model.displayMode != DisplayMode.sfdRibbon) {
                      _model.displayMode = DisplayMode.bmdRibbon;
                      _showToolSnackBar('Enabled 3D Extruded Bending Moment Diagram (BMD) Ribbons');
                    } else if (_model.displayMode == DisplayMode.bmdRibbon) {
                      _model.displayMode = DisplayMode.sfdRibbon;
                      _showToolSnackBar('Enabled 3D Extruded Shear Force Diagram (SFD) Ribbons');
                    } else {
                      _model.displayMode = DisplayMode.geometry;
                      _showToolSnackBar('Restored 3D Geometry Skeleton Display');
                    }
                  });
                },
              ),
              WorkspaceToolItem(
                label: 'Re-Center Viewport (Iso 3D)',
                subtitle: 'Fit camera to entire structure',
                icon: Icons.view_in_ar_rounded,
                color: const Color(0xFF38BDF8),
                category: 'CANVAS',
                badge: 'CAMERA',
                onTap: () => _viewportKey.currentState?.setCameraPreset('ISO'),
              ),
              WorkspaceToolItem(
                label: 'Clear Canvas / Blank Grid',
                subtitle: 'Remove all elements to draw fresh',
                icon: Icons.cleaning_services_rounded,
                color: Colors.redAccent,
                category: 'CANVAS',
                badge: 'NEW',
                onTap: _clearCanvas,
              ),
            ],
            onPresetSelected: (presetKey) => _loadPreset(presetKey),
            onSolveTriggered: _triggerSolve,
          ),

          // 5. Layer 4: Floating Right Inspector Card (Slideable, Remembers Position, Open-in-place)
          if (showInspector)
            Positioned(
              top: effectiveInspectorTop,
              right: isCompact ? 10 : 20,
              left: isCompact ? 10 : null,
              bottom: inspectorBottomOffset,
              child: GestureDetector(
                onVerticalDragUpdate: (details) => _updateInspectorTop(details.delta.dy, maxInspectorTop),
                child: FloatingInspectorPanel(
                  width: isCompact ? double.infinity : 330,
                  model: _model,
                  selectedNodeId: _selectedNodeId,
                  selectedMemberId: _selectedMemberId,
                  selectedNodeIds: _selectedNodeIds,
                  selectedMemberIds: _selectedMemberIds,
                  onSelectNode: (nodeId) {
                    setState(() {
                      _selectedNodeId = nodeId;
                      _selectedNodeIds.clear();
                      _selectedNodeIds.add(nodeId);
                      _selectedMemberId = null;
                      _selectedMemberIds.clear();
                    });
                  },
                  onSelectMember: (memberId) {
                    setState(() {
                      _selectedMemberId = memberId;
                      _selectedMemberIds.clear();
                      _selectedMemberIds.add(memberId);
                      _selectedNodeId = null;
                      _selectedNodeIds.clear();
                    });
                  },
                  onBatchAssignSection: _batchAssignSection,
                  onBatchAssignSupport: _batchAssignSupport,
                  onBatchApplyLoads: _batchApplyLoads,
                  onBatchDelete: _deleteSelectedElements,
                  onDeselectAll: _deselectAll,
                  onModelChanged: () {
                    _commitModelMutation('Updated structural properties');
                  },
                  onClose: () => _setInspectorOpen(false),
                ),
              ),
            )
          else
            Positioned(
              top: effectiveInspectorTop,
              right: isCompact ? 10 : 20,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) => _updateInspectorTop(details.delta.dy, maxInspectorTop),
                  child: GlassPod(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    borderRadius: 16,
                    glowColor: const Color(0xFF00F0FF),
                    onTap: () => _setInspectorOpen(true),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.drag_indicator_rounded, size: 14, color: Color(0xFF00F0FF)),
                        SizedBox(width: 4),
                        Icon(Icons.tune_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          "INSPECTOR",
                          style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        InfoTooltip(
                          title: 'Selection Inspector Handle',
                          codeRef: 'Slideable Panel',
                          message: 'Click to expand the 12-DOF Selection Inspector, or drag vertically to reposition.',
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 5. Layer 4: Floating Copyright Watermark (Pass-through clicks)
          const FloatingCopyrightWatermark(),
        ],
      ),
    ),
  );
}

  void _openProgressiveCollapse() {
    _requireAuth(
      featureName: 'Progressive Collapse & Alternate Load Path Studio',
      onAuthenticated: () {
        showDialog(
          context: context,
          builder: (ctx) => ProgressiveCollapseDialog(
            model: _model,
            onCommitDamagedModel: (damaged) {
              _saveUndoState();
              setState(() {
                _model = damaged;
              });
              _commitModelMutation(
                'Applied UFC 4-023-03 notional column removal to 3D viewport (Press Ctrl/Cmd+Z to restore column)',
              );
            },
          ),
        );
      },
    );
  }

  void _openCommandPalette() {
    showDialog(
      context: context,
      builder: (ctx) => CommandPaletteDialog(
        actions: [
          CommandPaletteAction(
            title: 'Progressive Collapse & Alternate Path Studio',
            subtitle: 'Sudden notional column removal, catenary bridging & vulnerability ranking',
            category: 'ANALYSIS',
            codeRef: 'UFC 4-023-03 & GSA',
            infoDescription:
                'Removes perimeter, corner, or interior columns under Ω_LD = 2.0 dynamic amplification and solves the damaged 12-DOF stiffness matrix [K_damaged] for double-span catenary deflection and plastic chord rotation.',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
            shortcut: 'ALP',
            onTrigger: _openProgressiveCollapse,
          ),
          CommandPaletteAction(
            title: 'Autonomous 4-Agent Engineering Swarm',
            subtitle: 'Architect ↔ FEA Analyst ↔ Code Auditor ↔ Self-Healer',
            category: 'AI & GEN',
            codeRef: 'AISC 360-16 / ASCE 7-16',
            infoDescription:
                'Coordinates four specialized AI agents to synthesize, analyze, audit, and self-heal overstressed structural members until max DCR ≤ 1.0.',
            icon: Icons.hub_rounded,
            color: const Color(0xFF00F0FF),
            onTrigger: () => AutonomousSwarmDialog.show(
              context,
              model: _model,
              onStructureModified: () {
                _saveUndoState();
                _commitModelMutation('Applied Swarm-Healed AISC 360-16 Topology to 3D Frame');
              },
            ),
          ),
          CommandPaletteAction(
            title: '3D Topology Synthesizer (Neural SIMP & Marching Struts)',
            subtitle: 'Continuous density field optimization & 3D diagrid exoskeletons',
            category: 'AI & GEN',
            codeRef: 'Neural SIMP • 18–30% Savings',
            infoDescription:
                'Optimizes structural compliance C = F^T u(ρ) subject to target volume fraction V_target and extracts triangulated 3D diagrid exoskeletons.',
            icon: Icons.architecture_rounded,
            color: const Color(0xFF10B981),
            onTrigger: () => showDialog(
              context: context,
              builder: (_) => GenerativeTopologyDialog(
                currentModel: _model,
                onCommitModel: (synthesized) {
                  _saveUndoState();
                  _importBuildingModel(synthesized);
                },
              ),
            ),
          ),
          CommandPaletteAction(
            title: 'WebGPU 60 FPS Pareto Frontier Explorer',
            subtitle: 'Evaluate 256 structural variations in < 10 ms via WGSL shaders',
            category: 'AI & GEN',
            codeRef: 'WebGPU B=256 Compute',
            infoDescription:
                'Interactive tri-objective Pareto trade-off explorer balancing Steel Mass (kg), Peak Drift (mm), and Embodied Carbon (kg CO2e).',
            icon: Icons.scatter_plot_rounded,
            color: const Color(0xFF38BDF8),
            onTrigger: () => ParetoFrontierDock.show(
              context,
              model: _model,
              onCommit: (optimized) {
                _saveUndoState();
                _model = optimized;
                _commitModelMutation('Committed Pareto Optimal Design to 3D Viewport');
              },
            ),
          ),
          CommandPaletteAction(
            title: 'Shop-Drawing & Site Connection Visual QA',
            subtitle: 'ConnectionNet-AI multimodal fabrication & bolt/weld compliance audit',
            category: 'AI & GEN',
            codeRef: 'AISC 360-16 Ch. J & ACI 318 Ch. 25',
            infoDescription:
                'Audits bolted moment end-plates, baseplates, and rebar cages for minimum edge distances, bolt spacing, and seismic hook bends.',
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFFF59E0B),
            onTrigger: () => showDialog(
              context: context,
              builder: (_) => const ShopDrawingAuditDialog(),
            ),
          ),
          CommandPaletteAction(
            title: 'Real-Time Multi-Engineer Cloud Collaboration & Diff',
            subtitle: 'Shareable review links, 3D joint comment pins & DCR revision diffing',
            category: 'CAD & BIM',
            codeRef: 'Cloud Firestore Live',
            infoDescription:
                'Generates Co-Engineer or Viewer/Commenter links, compares structural revisions (added/modified/removed members), and renders 3D review pins.',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF00F0FF),
            onTrigger: () => CollaborationReviewDialog.show(
              context,
              model: _model,
              onStructureModified: () => setState(() => _triggerSolve()),
            ),
          ),
          CommandPaletteAction(
            title: 'Concrete Studio (P-M Interaction & ACI 224R Crack Widths)',
            subtitle: 'Biaxial fiber P-M envelope & Gergely-Lutz surface crack control',
            category: 'ANALYSIS',
            codeRef: 'ACI 318-19 & ACI 224R-01',
            infoDescription:
                'Computes reinforced concrete axial-flexural P-M capacity and checks surface crack width wk across 4 exposure classes.',
            icon: Icons.view_in_ar_rounded,
            color: const Color(0xFF00F0FF),
            onTrigger: () => showDialog(
              context: context,
              builder: (_) => const ConcretePmDialog(),
            ),
          ),
          CommandPaletteAction(
            title: 'PE Calculation Packet & Cryptographic Seal Verifier',
            subtitle: 'Stamped engineering dossier with HMAC-SHA256 tamper-evident audit',
            category: 'CAD & BIM',
            codeRef: 'HMAC-SHA256 PE Seal',
            infoDescription:
                'Generates an official calculation packet and verifies cryptographic HMAC-SHA256 digital signatures against municipal plan-check tampering.',
            icon: Icons.verified_user_rounded,
            color: const Color(0xFF10B981),
            onTrigger: () => PePacketDialog.show(
              context,
              model: _model,
              apiService: _apiService,
              onStructureModified: () => setState(() => _triggerSolve()),
            ),
          ),
          CommandPaletteAction(
            title: 'Lateral Stability, P-Delta & 12×12 [Kg] Buckling Engine',
            subtitle: 'ASCE 7-16 wind/seismic loads, α_cr buckling & B2 sway amplification',
            category: 'ANALYSIS',
            codeRef: 'ASCE 7-16 & AISC App. 8',
            infoDescription:
                'Evaluates second-order P-Delta stability, geometric stiffness [Kg] critical buckling multiplier α_cr, and directional wind/seismic shears.',
            icon: Icons.sync_alt_rounded,
            color: const Color(0xFFE11D48),
            onTrigger: () => LateralStabilityDialog.show(
              context,
              model: _model,
              apiService: _apiService,
              onStructureModified: () => setState(() => _triggerSolve()),
            ),
          ),
          CommandPaletteAction(
            title: 'AISC 360-16 Section Auto-Sizer',
            subtitle: 'Automatically size all members for minimum steel weight (DCR ≤ 1.0)',
            category: 'MODELING',
            codeRef: 'AISC 360-16 LRFD',
            infoDescription:
                'Iterates over all frame members and upgrades/downsizes W-shapes so every element satisfies governing axial-flexural interaction.',
            icon: Icons.auto_fix_high_rounded,
            color: const Color(0xFF10B981),
            onTrigger: _optimizeSections,
          ),
          CommandPaletteAction(
            title: 'Extrude Story (+1 Floor Level & Tributary Loads)',
            subtitle: 'Duplicate highest floor upward (+3.6m) with 1.2D+1.6L gravity loads',
            category: 'MODELING',
            codeRef: 'ASCE 7-16 Diaphragm',
            infoDescription:
                'Adds a complete new story level above the current roof and propagates factored gravity and wind loads automatically.',
            icon: Icons.domain_add_rounded,
            color: const Color(0xFF10B981),
            onTrigger: _extrudeStory,
          ),
          CommandPaletteAction(
            title: 'Browse 12 Pre-Engineered Building Templates',
            subtitle: 'High-rise towers, hospitals, bridges, warehouses & space canopies',
            category: 'TEMPLATES',
            codeRef: '12 Certified Models',
            infoDescription:
                'Opens the Building Templates library to preview and load complete 3D structural systems into the workstation.',
            icon: Icons.apartment_rounded,
            color: const Color(0xFF38BDF8),
            onTrigger: () => showDialog(
              context: context,
              builder: (_) => BuildingTemplatesDialog(
                currentModel: _model,
                onModelSelected: _importBuildingModel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
