// ============================================================================
// Structura Nexus: Unit & Widget Tests for Building Templates and Mac AI Engine
// Tests template generation, multi-format import, and Mac-trained neural engine.
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/services/building_generator_service.dart';
import 'package:structura_nexus/services/dart_neural_engine.dart';
import 'package:structura_nexus/widgets/building_templates_dialog.dart';
import 'package:structura_nexus/widgets/mac_neural_inspector_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Building Generator & Template Tests', () {
    test('Certified building catalog contains all required high-rise & benchmark models', () {
      final templates = BuildingGeneratorService.getCertifiedBuildingTemplates();
      expect(templates.length, greaterThanOrEqualTo(9));
      expect(templates.any((t) => t.id == 'high_rise_10s'), isTrue);
      expect(templates.any((t) => t.id == 'hospital_8s'), isTrue);
      expect(templates.any((t) => t.id == 'supertall_20s'), isTrue);
      expect(templates.any((t) => t.id == 'warehouse_portal'), isTrue);
      expect(templates.any((t) => t.id == 'transmission_tower'), isTrue);
    });

    test('Parametric generator synthesizes valid 3D space frames with rigid base boundary constraints', () {
      final model = BuildingGeneratorService.generateParametricBuilding(
        name: 'Test Parametric Frame',
        numStories: 3,
        baysX: 2,
        baysZ: 2,
        bayWidthX: 6.0,
        bayDepthZ: 6.0,
        storyHeight: 3.5,
        system: BuildingSystemType.xBracedFrame,
      );

      expect(model.nodes.isNotEmpty, isTrue);
      expect(model.members.isNotEmpty, isTrue);

      // Verify ground floor nodes (Y = 0) are fully restrained (6-DOF)
      final baseNodes = model.nodes.where((n) => n.y == 0.0);
      expect(baseNodes.isNotEmpty, isTrue);
      for (final n in baseNodes) {
        expect(n.isRestrained, equals([true, true, true, true, true, true]));
      }
    });

    test('Model import parses JSON format seamlessly', () {
      const jsonStr = '''{
        "name": "Imported Test Building",
        "nodes": [
          {"id": "N1", "x": 0.0, "y": 0.0, "z": 0.0, "isRestrained": [true, true, true, true, true, true]},
          {"id": "N2", "x": 0.0, "y": 4.0, "z": 0.0, "isRestrained": [false, false, false, false, false, false], "fyN": -50000}
        ],
        "members": [
          {"id": "COL1", "startNodeId": "N1", "endNodeId": "N2", "section": "W14X90"}
        ]
      }''';

      final model = BuildingGeneratorService.importModel(jsonStr, filename: 'model.json');
      expect(model, isNotNull);
      expect(model!.name, equals('Imported Test Building'));
      expect(model.nodes.length, equals(2));
      expect(model.members.length, equals(1));
      expect(model.members.first.section, equals('W14X90'));
    });

    test('Model import parses S2K text format seamlessly', () {
      const s2kContent = '''
TABLE:  "JOINT COORDINATES"
Joint=J1 CoordSys=GLOBAL XorR=0 Y=0 Z=0 SpecialJoint=No
Joint=J2 CoordSys=GLOBAL XorR=6 Y=0 Z=4 SpecialJoint=No
TABLE:  "CONNECTIVITY - FRAME"
Frame=F1 JointI=J1 JointJ=J2 IsCurved=No SectionName=W14X90
''';

      final model = BuildingGeneratorService.importModel(s2kContent, filename: 'sap2000.s2k');
      expect(model, isNotNull);
      expect(model!.nodes.length, equals(2));
      expect(model.members.length, equals(1));
    });
  });

  group('Mac Neural AI Tensor Runtime Tests', () {
    test('Pure Dart tensor engine evaluates all 10 neural surrogate predictions without null errors', () {
      final engine = DartNeuralEngine.instance;

      final testModel = BuildingGeneratorService.generateParametricBuilding(
        name: 'AI Test Frame',
        numStories: 2,
        baysX: 1,
        baysZ: 1,
        bayWidthX: 5.0,
        bayDepthZ: 5.0,
        storyHeight: 3.5,
      );

      // 1. StructuraNet-3D
      final gnnRes = engine.predictStructuraNet3D(testModel);
      expect(gnnRes['displacements'], isNotNull);
      expect((gnnRes['displacements'] as List).length, equals(testModel.nodes.length));
      expect(gnnRes['member_forces'], isNotNull);
      expect((gnnRes['member_forces'] as List).length, equals(testModel.members.length));
      expect(gnnRes['latency_ms'], isNotNull);

      // 2. Concrete Section
      final concRes = engine.predictConcreteSection(b: 0.40, h: 0.60, fc: 35.0, rho: 0.02, puKn: 500.0);
      expect(concRes['max_phi_pn_kn'], greaterThan(0.0));
      expect(concRes['max_phi_mn_knm'], greaterThan(0.0));

      // 3. Steel Connection
      final steelRes = engine.predictSteelConnection(boltDiaMm: 24, boltCount: 6, plateThicknessMm: 20, weldSizeMm: 10, fyMpa: 345);
      expect(steelRes['rotational_stiffness_knm_rad'], greaterThan(0.0));

      // 4. Foundation SSI
      final fdnRes = engine.predictFoundationSSI(footingBM: 3.0, footingLM: 3.0, soilCohesionKpa: 25.0, soilFrictionDeg: 30.0);
      expect(fdnRes['q_ult_kpa'], greaterThan(0.0));

      // 5. Pushover PBEE
      final pushRes = engine.predictPushoverPBEE(totalHeightM: 20.0, totalSeismicWeightKn: 1500.0, yieldBaseShearKn: 400.0);
      expect(pushRes['target_displacement_m'], greaterThan(0.0));

      // 6. Aero CFD
      final aeroRes = engine.predictAeroCFD(buildingHeightM: 60.0, buildingWidthM: 25.0, buildingDepthM: 25.0, windSpeedMs: 45.0);
      expect(aeroRes['along_wind_base_shear_kn'], greaterThan(0.0));

      // 7. Composite Floor
      final compRes = engine.predictCompositeFloor(spanLengthM: 9.0, beamSpacingM: 3.0, slabThicknessMm: 120.0);
      expect(compRes['natural_frequency_hz'], greaterThan(0.0));

      // 8. Hazard Dynamic
      final hazRes = engine.predictHazardDynamicResponse(pgaG: 0.45, windSpeedMs: 30.0, buildingHeightM: 24.0);
      expect(hazRes['max_roof_drift_mm'], greaterThan(0.0));

      // 9. Modal Dynamics
      final modalRes = engine.predictModalDynamics(heightM: 24.0, weightKn: 8000.0);
      expect(modalRes['t1_s'], greaterThan(0.0));
      expect(modalRes['modal_mass_participation_pct'], greaterThan(0.0));

      // 10. Embodied Carbon
      final carbonRes = engine.predictEmbodiedCarbon(concreteM3: 400.0, steelTonnes: 120.0);
      expect(carbonRes['baseline_carbon_kgco2e'], greaterThan(0.0));
    });
  });

  group('UI Dialog Widget Tests', () {
    testWidgets('BuildingTemplatesDialog renders tabs and certified template cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final baseModel = BuildingGeneratorService.getCertifiedBuildingTemplates().first.builder();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BuildingTemplatesDialog(
            currentModel: baseModel,
            onModelSelected: (m) {},
          ),
        ),
      ));

      expect(find.text('Certified Building Templates'), findsOneWidget);
      expect(find.text('Parametric Building Synthesizer'), findsOneWidget);
      expect(find.textContaining('Import File'), findsOneWidget);

      // Search field
      expect(find.byType(TextField), findsOneWidget);

      // Verify at least one certified building card exists
      expect(find.text('10-Story Commercial Office Tower'), findsOneWidget);
    });

    testWidgets('MacNeuralInspectorDialog renders Apple Silicon MPS overview and 10 engines', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final baseModel = BuildingGeneratorService.getCertifiedBuildingTemplates().first.builder();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MacNeuralInspectorDialog(
            currentModel: baseModel,
          ),
        ),
      ));

      expect(find.textContaining('MAC-TRAINED NEURAL AI'), findsOneWidget);
      expect(find.text('Apple Silicon MPS GPU'), findsOneWidget);
      expect(find.text('Run Real-Time Mac AI Benchmark'), findsOneWidget);

      // Tap benchmark button and verify execution
      await tester.tap(find.text('Run Real-Time Mac AI Benchmark'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Benchmark Finished'), findsOneWidget);
    });
  });
}
