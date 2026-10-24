import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/main.dart';
import 'package:structura_nexus/data/benchmark_presets.dart';
import 'package:structura_nexus/services/embedded_fea_solver.dart';
import 'package:structura_nexus/services/structural_library_service.dart';

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
    expect(find.text('ASCE 7-16 LOAD COMBINATIONS'), findsOneWidget);
    expect(find.text('AI SECTION AUTO-SIZER'), findsOneWidget);
  });

  testWidgets('Tapping a feature redirects unauthenticated user to login screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: WorkstationScreen()));
    await tester.pumpAndSettle();

    // Tap AI Copilot button in toolbar
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
}
