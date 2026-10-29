import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/main.dart';
import 'package:structura_nexus/data/benchmark_presets.dart';
import 'package:structura_nexus/services/embedded_fea_solver.dart';
import 'package:structura_nexus/services/structural_library_service.dart';
import 'package:structura_nexus/services/dart_neural_engine.dart';

void main() {
  test('Embedded FEA Solver solves multi-story sway frame', () {
    final model = BenchmarkPresets.multiStorySwayFrame();
    EmbeddedFeaSolver.solve(model);

    expect(model.nodes.length, 12);
    expect(model.members.length, 16);
    expect(model.baseShearN, greaterThan(0.0));
    expect(model.isEquilibrated, isTrue);
    expect(model.members.any((m) => m.governingDcr > 0.0), isTrue);
  });

  testWidgets('Workstation screen renders correctly', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: WorkstationScreen()));
    await tester.pumpAndSettle();

    expect(find.text('STRUCTURA FORGE AI'), findsOneWidget);
    expect(find.text('TOOLS & SUITE'), findsOneWidget);
    expect(find.text('DRAWER'), findsOneWidget);
    expect(find.text('HYBRID DUAL'), findsOneWidget);
    expect(find.text('STRUCTURANET-3D (<2ms)'), findsOneWidget);
    expect(find.text('PROPRIETARY DSM'), findsOneWidget);
    expect(find.text('ASCE 7-16 LOAD COMBINATIONS'), findsOneWidget);
    expect(find.text('AI SECTION AUTO-SIZER'), findsOneWidget);
    expect(find.textContaining('aliasgharinnocent@yahoo.com'), findsOneWidget);
    expect(find.textContaining('DMCA Protected'), findsOneWidget);

    // Verify all tools are accessible in the App Drawer
    await tester.tap(find.text('TOOLS & SUITE'));
    await tester.pumpAndSettle();
    expect(find.text('AI & GENERATIVE'), findsOneWidget);
    expect(find.text('MODELING & CAD'), findsOneWidget);
    expect(find.text('ANALYSIS & DESIGN'), findsOneWidget);
  });

  testWidgets('Tapping a feature redirects unauthenticated user to login screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: WorkstationScreen()));
    await tester.pumpAndSettle();

    // Open TOOLS & SUITE drawer
    await tester.tap(find.text('TOOLS & SUITE'));
    await tester.pumpAndSettle();

    // Tap AI Copilot button in drawer
    await tester.tap(find.text('AI Copilot'));
    await tester.pumpAndSettle();

    // Expect to be redirected to AuthScreen with custom message
    expect(find.text('STRUCTURA NEXUS'), findsOneWidget);
    expect(find.text('Please sign in or create an account to use AI Structural Copilot.'), findsOneWidget);
    expect(find.text('Back to Workstation'), findsOneWidget);

    // Tap Back to Workstation to return
    await tester.tap(find.text('Back to Workstation'));
    await tester.pumpAndSettle();

    // Back in workstation
    expect(find.text('STRUCTURA FORGE AI'), findsOneWidget);
  });

  test('StructuralLibraryService exports valid AutoCAD DXF format', () {
    final model = BenchmarkPresets.timoshenkoCantilever();
    final dxf = StructuralLibraryService.exportToDxf(model);

    expect(dxf, contains('SECTION'));
    expect(dxf, contains('\$ACADVER'));
    expect(dxf, contains('ENTITIES'));
    expect(dxf, contains('LINE'));
    expect(dxf, contains('POINT'));
    expect(dxf, contains('EOF'));
  });

  test('StructuralLibraryService exports Bill of Materials (BOM) CSV', () {
    final model = BenchmarkPresets.multiStorySwayFrame();
    final bom = StructuralLibraryService.exportToCsvBom(model);

    expect(bom, contains('Member ID,Start Node,End Node,AISC Section,Length (m)'));
    expect(bom, contains('TOTAL STEEL TONNAGE'));
    expect(bom, contains('COL_1'));
  });

  test('StructuralLibraryService JSON roundtrip preserves graph fidelity', () {
    final model = BenchmarkPresets.warrenTruss();
    final jsonMap = StructuralLibraryService.serializeModel(model);
    final deserialized = StructuralLibraryService.deserializeModel(jsonMap);

    expect(deserialized.nodes.length, model.nodes.length);
    expect(deserialized.members.length, model.members.length);
    expect(deserialized.nodes.first.x, model.nodes.first.x);
    expect(deserialized.members.first.sectionProfile, model.members.first.sectionProfile);
  });

  test('Realtime surrogate drag updates node coordinates and predicted displacements', () {
    final model = BenchmarkPresets.timoshenkoCantilever();
    final initialX = model.nodes[1].x;

    // Simulate pointer drag delta
    model.updateNodeCoords(model.nodes[1].id, initialX + 0.5, model.nodes[1].y, model.nodes[1].z);
    expect(model.nodes[1].x, closeTo(initialX + 0.5, 1e-4));

    // Simulate 60 FPS surrogate predicted displacement update
    model.updatePredictedDisplacements({
      model.nodes[1].id: {
        'dx': 0.0125,
        'dy': -0.0450,
        'dz': 0.0000,
        'rx': 0.0,
        'ry': 0.0,
        'rz': -0.0035,
      }
    });

    expect(model.nodes[1].displacements[0], closeTo(0.0125, 1e-4));
    expect(model.nodes[1].displacements[1], closeTo(-0.0450, 1e-4));
    expect(model.nodes[1].displacements[5], closeTo(-0.0035, 1e-4));
  });

  test('DartNeuralEngine: In-browser SectionNet-PM predicts ACI envelope and optimal rebar', () {
    final res = DartNeuralEngine.instance.predictConcreteSection(
      b: 0.45,
      h: 0.60,
      fc: 35.0,
      fy: 420.0,
      rho: 0.02,
      puKn: 1200.0,
      muKnm: 250.0,
    );

    expect(res['latency_ms'], lessThan(5.0));
    expect(res['curve_points'].length, 32);
    expect(res['max_phi_pn_kn'], greaterThan(1000.0));
    expect(res['governing_dcr'], greaterThan(0.0));
    expect(res['optimal_rebar_ratio'], inInclusiveRange(0.01, 0.05));
  });

  test('DartNeuralEngine: In-browser StructuraNet-3D enforces hard Dirichlet boundary condition', () {
    final model = BenchmarkPresets.multiStorySwayFrame();
    final res = DartNeuralEngine.instance.predictStructuraNet3D(model);

    expect(res['latency_ms'], lessThan(5.0));
    expect(res['is_equilibrated'], isTrue);

    // Fixed base nodes must have zero displacement
    for (final node in model.nodes.where((n) => n.isRestrainedY)) {
      expect(node.dispY, equals(0.0));
    }
  });

  test('DartNeuralEngine: In-browser ConnectionNet-AI predicts steel limit states and stiffness', () {
    final res = DartNeuralEngine.instance.predictSteelConnection(
      connectionType: 'shear_tab',
      boltCount: 4,
      boltDiaMm: 22.2,
      demandVuKn: 200.0,
    );
    expect(res['latency_ms'], lessThan(5.0));
    expect(res['model_type'], contains('ConnectionNet-AI'));
    expect(res['governing_dcr'], greaterThan(0.0));
    expect(res['limit_states'].length, equals(6));
  });

  test('DartNeuralEngine: In-browser FoundationNet-SSI predicts soil bearing, settlement and Winkler springs', () {
    final res = DartNeuralEngine.instance.predictFoundationSSI(
      columnPuKn: 1400.0,
      footingBM: 3.0,
      footingLM: 3.0,
    );
    expect(res['latency_ms'], lessThan(5.0));
    expect(res['model_type'], contains('FoundationNet-SSI'));
    expect(res['q_ult_kpa'], greaterThan(500.0));
    expect(res['winkler_springs']['vertical_kz_kn_m'], greaterThan(0.0));
  });

  test('DartNeuralEngine: In-browser PushoverNet-PBEE predicts non-linear capacity curve and performance point', () {
    final res = DartNeuralEngine.instance.predictPushoverPBEE(
      numStories: 10,
      totalHeightM: 35.0,
    );
    expect(res['latency_ms'], lessThan(5.0));
    expect(res['model_type'], contains('PushoverNet-PBEE'));
    expect(res['pushover_curve'].length, equals(20));
    expect(res['performance_level'], equals('LIFE_SAFETY'));
  });

  test('DartNeuralEngine: In-browser AeroNet-CFD predicts facade Cp flow field and vortex frequency', () {
    final res = DartNeuralEngine.instance.predictAeroCFD(
      buildingHeightM: 60.0,
      buildingWidthM: 25.0,
      windSpeedMs: 42.0,
    );
    expect(res['latency_ms'], lessThan(5.0));
    expect(res['model_type'], contains('AeroNet-CFD'));
    expect(res['vortex_shedding_frequency_hz'], greaterThan(0.0));
    expect(res['facade_contours'].length, equals(6));
  });

  test('DartNeuralEngine: In-browser CompositeFloorNet-AI predicts flexure capacity and DG 11 vibrations', () {
    final res = DartNeuralEngine.instance.predictCompositeFloor(
      spanLengthM: 10.0,
      beamSpacingM: 3.0,
    );
    expect(res['latency_ms'], lessThan(5.0));
    expect(res['model_type'], contains('CompositeFloorNet-AI'));
    expect(res['phi_mn_knm'], greaterThan(0.0));
    expect(res['natural_frequency_hz'], greaterThan(0.0));
  });

  test('DartNeuralEngine: In-browser HazardDynamicNet-AI predicts dynamic response and health score', () {
    final res = DartNeuralEngine.instance.predictHazardDynamicResponse(
      windSpeedMs: 35.0,
      pgaG: 0.35,
      buildingHeightM: 24.0,
    );
    expect(res['latency_ms'], lessThan(5.0));
    expect(res['model_type'], contains('HazardDynamicNet-AI'));
    expect(res['max_roof_drift_mm'], greaterThan(0.0));
    expect(res['structural_health_score'], inInclusiveRange(0.0, 100.0));
  });
}
