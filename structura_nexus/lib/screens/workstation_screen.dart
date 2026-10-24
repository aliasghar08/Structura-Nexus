// ============================================================================
// WorkstationScreen — Core Real-Time Structural Engineering Workstation
// Interactive 3D WebGL Viewport, Surrogate GNN, AISC 360-16 & ASCE 7-16
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../data/benchmark_presets.dart';
import '../services/structural_api_service.dart';
import '../services/embedded_fea_solver.dart';
import '../services/firebase_auth_service.dart';
import 'auth_screen.dart';
import '../widgets/workstation_header.dart';
import '../widgets/workstation_drawer.dart';
import '../widgets/structural_3d_viewport.dart';
import '../widgets/inspector_panel.dart';
import '../widgets/code_compliance_panel.dart';
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
import '../widgets/floating_copyright_watermark.dart';

class WorkstationScreen extends StatefulWidget {
  const WorkstationScreen({super.key});

  @override
  State<WorkstationScreen> createState() => _WorkstationScreenState();
}

class _WorkstationScreenState extends State<WorkstationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late StructuralModel _model;
  final StructuralApiService _apiService = StructuralApiService();
  final RealtimeSurrogateStreamer _surrogateStreamer = RealtimeSurrogateStreamer();
  String? _selectedNodeId;
  String? _selectedMemberId;

  bool get _isUserLoggedIn {
    final user = FirebaseAuthService().currentUser;
    return user != null && !user.isAnonymous;
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
    _model = BenchmarkPresets.multiStorySwayFrame();
    EmbeddedFeaSolver.solve(_model);

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
  }

  @override
  void dispose() {
    _surrogateStreamer.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _triggerSolve() {
    setState(() {
      _apiService.sendGraphPayload(
        _model,
        action: _model.activeEngine == EngineType.surrogateGnn
            ? 'INFER_SURROGATE'
            : 'EXACT_SOLVE',
      );
    });
  }

  void _optimizeSections() async {
    final success = await _apiService.triggerRemoteOptimization(_model);
    if (success) {
      setState(() {
        _triggerSolve();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('AISC Section Optimization successfully executed!'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _loadPreset(String presetKey) {
    setState(() {
      if (presetKey == 'sway') {
        _model = BenchmarkPresets.multiStorySwayFrame();
      } else if (presetKey == 'truss') {
        _model = BenchmarkPresets.warrenTruss();
      } else if (presetKey == 'cantilever') {
        _model = BenchmarkPresets.timoshenkoCantilever();
      }
      _selectedNodeId = null;
      _selectedMemberId = null;
      _triggerSolve();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: WorkstationDrawer(
        onOpenCopilot: () => _requireAuth(
          featureName: 'AI Structural Copilot',
          onAuthenticated: () => AiCopilotDialog.show(
            context,
            model: _model,
            apiService: _apiService,
            onStructureModified: _triggerSolve,
          ),
        ),
        onOpenGenerativeOptimizer: () => _requireAuth(
          featureName: 'Generative AI Section Auto-Sizer',
          onAuthenticated: () => GenerativeOptimizerDialog.show(
            context,
            model: _model,
            apiService: _apiService,
            onStructureModified: _triggerSolve,
          ),
        ),
        onOpenGenerativeBracing: () => _requireAuth(
          featureName: 'Generative Bracing Synthesizer',
          onAuthenticated: () => GenerativeBracingDialog.show(
            context,
            model: _model,
            apiService: _apiService,
            onStructureModified: () => setState(() => _triggerSolve()),
          ),
        ),
        onOptimize: () => _requireAuth(
          featureName: 'AISC Section Auto-Sizer',
          onAuthenticated: _optimizeSections,
        ),
        onOpenCadStudio: () => _requireAuth(
          featureName: 'Structural CAD Studio',
          onAuthenticated: () {
            showDialog(
              context: context,
              builder: (ctx) => StructuralCadEditorDialog(
                initialModel: _model,
                onModelCommitted: (newModel) {
                  setState(() {
                    _model = newModel;
                    _selectedNodeId = null;
                    _selectedMemberId = null;
                    _triggerSolve();
                  });
                },
              ),
            );
          },
        ),
        onOpenLibrary: () => _requireAuth(
          featureName: 'AISC Structural Library & DXF Export',
          onAuthenticated: () {
            showDialog(
              context: context,
              builder: (ctx) => StructuralLibraryDialog(
                currentModel: _model,
                onModelSelected: (newModel) {
                  setState(() {
                    _model = newModel;
                    _selectedNodeId = null;
                    _selectedMemberId = null;
                    _triggerSolve();
                  });
                },
              ),
            );
          },
        ),
        onOpenSeismicModal: () => _requireAuth(
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
        ),
        onOpenLateralStability: () => _requireAuth(
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
        ),
        onOpenPePacket: () => _requireAuth(
          featureName: 'PE Stamped Calculation Packet',
          onAuthenticated: () => PePacketDialog.show(
            context,
            model: _model,
            apiService: _apiService,
            onStructureModified: () => setState(() => _triggerSolve()),
          ),
        ),
        onOpenEmbodiedCarbon: () => _requireAuth(
          featureName: 'Embodied Carbon Life Cycle Assessment',
          onAuthenticated: () => EmbodiedCarbonDialog.show(
            context,
            model: _model,
            apiService: _apiService,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Top Header & Engine Bar
              WorkstationHeader(
                model: _model,
                isBackendConnected: _apiService.isConnected,
                onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
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
                onPresetSelected: (presetKey) {
                  _requireAuth(
                    featureName: 'Benchmark Presets',
                    onAuthenticated: () => _loadPreset(presetKey),
                  );
                },
                onSolveTriggered: () {
                  _requireAuth(
                    featureName: 'Finite Element Solver',
                    onAuthenticated: _triggerSolve,
                  );
                },
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
              // 2. Middle Viewport & Inspector
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Structural3DViewport(
                        model: _model,
                        selectedNodeId: _selectedNodeId,
                        selectedMemberId: _selectedMemberId,
                        onNodeSelected: (id) {
                          setState(() {
                            _selectedNodeId = id;
                            if (id != null) _selectedMemberId = null;
                          });
                        },
                        onMemberSelected: (id) {
                          setState(() {
                            _selectedMemberId = id;
                            if (id != null) _selectedNodeId = null;
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
                    InspectorPanel(
                      model: _model,
                      selectedNodeId: _selectedNodeId,
                      selectedMemberId: _selectedMemberId,
                      onModelChanged: () {
                        _requireAuth(
                          featureName: 'Structural Model Editor',
                          onAuthenticated: _triggerSolve,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // 3. Bottom Code Compliance & ASCE 7 Panel
              CodeCompliancePanel(
                model: _model,
                onOptimize: () {
                  _requireAuth(
                    featureName: 'AISC Section Auto-Sizer',
                    onAuthenticated: _optimizeSections,
                  );
                },
                onCombinationChanged: (combo) {
                  setState(() {
                    _model.loadCombination = combo;
                    _triggerSolve();
                  });
                },
                onOpenLateralStability: () {
                  _requireAuth(
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
                },
              ),
            ],
          ),
          const FloatingCopyrightWatermark(),
        ],
      ),
    );
  }
}
