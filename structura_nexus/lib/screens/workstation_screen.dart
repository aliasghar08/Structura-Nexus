// ============================================================================
// WorkstationScreen — Core Real-Time Structural Engineering Workstation
// Interactive 3D WebGL Viewport, Surrogate GNN, AISC 360-16 & ASCE 7-16
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../data/benchmark_presets.dart';
import '../services/structural_api_service.dart';
import '../services/embedded_fea_solver.dart';
import '../services/firebase_auth_service.dart';
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
import '../services/dart_neural_engine.dart';

class WorkstationScreen extends StatefulWidget {
  const WorkstationScreen({super.key});

  @override
  State<WorkstationScreen> createState() => _WorkstationScreenState();
}

class _WorkstationScreenState extends State<WorkstationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<Structural3DViewportState> _viewportKey = GlobalKey<Structural3DViewportState>();
  late StructuralModel _model;
  final StructuralApiService _apiService = StructuralApiService();
  final RealtimeSurrogateStreamer _surrogateStreamer = RealtimeSurrogateStreamer();
  String? _selectedNodeId;
  String? _selectedMemberId;
  bool? _isInspectorOpen;
  bool _isNlthaActive = false;
  StreamSubscription<dynamic>? _authSubscription;

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
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
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
    );

    void onOpenLibrary() => _requireAuth(
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
    );

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
        onModelSynthesized: (newModel) {
          setState(() {
            _model = newModel;
            _selectedNodeId = null;
            _selectedMemberId = null;
            _triggerSolve();
          });
        },
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
            onStructureModified: () => setState(() {}),
            onModelReplaced: (newModel) {
              setState(() {
                _model = newModel;
                _selectedNodeId = null;
                _selectedMemberId = null;
                _triggerSolve();
              });
            },
            onRequireAuth: (feat, cb) => _requireAuth(featureName: feat, onAuthenticated: cb),
          ),
        );
      },
    );

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
    final inspectorTopOffset = MediaQuery.paddingOf(context).top + (isCompact ? 68.0 : 70.0);
    final inspectorBottomOffset = MediaQuery.paddingOf(context).bottom + (isCompact ? 200.0 : 225.0);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF070B12), // Deep canvas black
      drawer: WorkstationDrawer(
        onOpenCopilot: onOpenCopilot,
        onOpenGenerativeOptimizer: onOpenGenerativeOptimizer,
        onOpenGenerativeBracing: onOpenGenerativeBracing,
        onOptimize: onOptimize,
        onOpenCadStudio: onOpenCadStudio,
        onOpenLibrary: onOpenLibrary,
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
        onPresetSelected: (presetKey) {
          _requireAuth(
            featureName: 'Benchmark Presets',
            onAuthenticated: () => _loadPreset(presetKey),
          );
        },
      ),
      body: Stack(
        children: [
          // 1. Layer 0: Fullscreen Hardware-Accelerated 3D WebGL Canvas
          Positioned.fill(
            child: Structural3DViewport(
              key: _viewportKey,
              model: _model,
              selectedNodeId: _selectedNodeId,
              selectedMemberId: _selectedMemberId,
              onNodeSelected: (id) {
                setState(() {
                  _selectedNodeId = id;
                  if (id != null) {
                    _selectedMemberId = null;
                    _isInspectorOpen = true;
                  }
                });
              },
              onMemberSelected: (id) {
                setState(() {
                  _selectedMemberId = id;
                  if (id != null) {
                    _selectedNodeId = null;
                    _isInspectorOpen = true;
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
            ),
          ),

          // 4. Layer 3: Floating Right Inspector Card (Responsive Desktop Card / Mobile Overlay)
          if (showInspector)
            Positioned(
              top: inspectorTopOffset,
              right: isCompact ? 10 : 20,
              left: isCompact ? 10 : null,
              bottom: inspectorBottomOffset,
              child: FloatingInspectorPanel(
                width: isCompact ? double.infinity : 330,
                model: _model,
                selectedNodeId: _selectedNodeId,
                selectedMemberId: _selectedMemberId,
                onModelChanged: () {
                  _requireAuth(
                    featureName: 'Structural Model Editor',
                    onAuthenticated: _triggerSolve,
                  );
                },
                onClose: () => setState(() => _isInspectorOpen = false),
              ),
            )
          else
            Positioned(
              top: inspectorTopOffset,
              right: isCompact ? 10 : 20,
              child: GlassPod(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                borderRadius: 16,
                onTap: () => setState(() => _isInspectorOpen = true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.tune_rounded, size: 14, color: Color(0xFF00F0FF)),
                    SizedBox(width: 6),
                    Text(
                      "INSPECTOR",
                      style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Layer 4: Floating Copyright Watermark (Pass-through clicks)
          const FloatingCopyrightWatermark(),
        ],
      ),
    );
  }
}
