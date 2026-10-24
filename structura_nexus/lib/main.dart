import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/structural_models.dart';
import 'data/benchmark_presets.dart';
import 'services/structural_api_service.dart';
import 'services/embedded_fea_solver.dart';
import 'services/firebase_auth_service.dart';
import 'widgets/workstation_header.dart';
import 'widgets/structural_3d_viewport.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/code_compliance_panel.dart';
import 'widgets/ai_copilot_dialog.dart';
import 'widgets/generative_optimizer_dialog.dart';
import 'widgets/seismic_modal_dialog.dart';
import 'widgets/embodied_carbon_dialog.dart';
import 'widgets/auth_dialog.dart';
import 'widgets/structural_library_dialog.dart';
import 'widgets/cad_editor_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuthService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }
  runApp(const StructuraNexusApp());
}

class StructuraNexusApp extends StatelessWidget {
  const StructuraNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structura Forge AI / Structura Nexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D14),
        primaryColor: const Color(0xFF1F6FEB),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      home: const WorkstationScreen(),
    );
  }
}

class WorkstationScreen extends StatefulWidget {
  const WorkstationScreen({super.key});

  @override
  State<WorkstationScreen> createState() => _WorkstationScreenState();
}

class _WorkstationScreenState extends State<WorkstationScreen> {
  late StructuralModel _model;
  final StructuralApiService _apiService = StructuralApiService();
  String? _selectedNodeId;
  String? _selectedMemberId;

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
      body: Column(
        children: [
          // 1. Top Header & Engine Bar
          WorkstationHeader(
            model: _model,
            isBackendConnected: _apiService.isConnected,
            onEngineChanged: (engine) {
              setState(() {
                _model.activeEngine = engine;
                _triggerSolve();
              });
            },
            onModeChanged: (mode) => setState(() => _model.displayMode = mode),
            onDeformationScaleChanged: (scale) => setState(() => _model.deformationScale = scale),
            onPresetSelected: _loadPreset,
            onSolveTriggered: _triggerSolve,
            onOpenCopilot: () => AiCopilotDialog.show(
              context,
              model: _model,
              apiService: _apiService,
              onStructureModified: _triggerSolve,
            ),
            onOpenGenerativeOptimizer: () => GenerativeOptimizerDialog.show(
              context,
              model: _model,
              apiService: _apiService,
              onStructureModified: _triggerSolve,
            ),
            onOpenSeismicModal: () => SeismicModalDialog.show(
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
            onOpenEmbodiedCarbon: () => EmbodiedCarbonDialog.show(
              context,
              model: _model,
              apiService: _apiService,
            ),
            onOpenLibrary: () {
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
            onOpenCadStudio: () {
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
            onOpenAuth: () {
              showDialog(
                context: context,
                builder: (ctx) => AuthDialog(
                  onAuthSuccess: () => setState(() {}),
                ),
              );
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
                  ),
                ),
                InspectorPanel(
                  model: _model,
                  selectedNodeId: _selectedNodeId,
                  selectedMemberId: _selectedMemberId,
                  onModelChanged: _triggerSolve,
                ),
              ],
            ),
          ),
          // 3. Bottom Code Compliance & ASCE 7 Panel
          CodeCompliancePanel(
            model: _model,
            onOptimize: _optimizeSections,
            onCombinationChanged: (combo) {
              setState(() {
                _model.loadCombination = combo;
                _triggerSolve();
              });
            },
          ),
        ],
      ),
    );
  }
}
