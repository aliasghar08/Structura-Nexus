// ============================================================================
// STRUCTURA NEXUS v4.1 — FRONTIER AI & ENGINE TEST SUITE
// Tests WebGPU Pareto Bridge, 60 FPS Dock, Batch Inspector & Multi-Select
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:structura_nexus/models/structural_models.dart';
import 'package:structura_nexus/services/webgpu_surrogate_bridge.dart';
import 'package:structura_nexus/widgets/pareto_frontier_dock.dart';
import 'package:structura_nexus/widgets/floating_inspector_panel.dart';

void main() {
  StructuralModel createTestModel() {
    return StructuralModel(
      nodes: [
        StructuralNode(id: 'N1', coords: Vector3(0, 0, 0), restraint: [1, 1, 1, 1, 1, 1]),
        StructuralNode(id: 'N2', coords: Vector3(6, 0, 0), restraint: [1, 1, 1, 1, 1, 1]),
        StructuralNode(id: 'N3', coords: Vector3(0, 4, 0), loads: [0, -50000, 0, 0, 0, 0]),
        StructuralNode(id: 'N4', coords: Vector3(6, 4, 0), loads: [0, -50000, 0, 0, 0, 0]),
      ],
      members: [
        StructuralMember(id: 'C1', iNodeId: 'N1', jNodeId: 'N3', section: 'W14X90'),
        StructuralMember(id: 'C2', iNodeId: 'N2', jNodeId: 'N4', section: 'W14X90'),
        StructuralMember(id: 'B1', iNodeId: 'N3', jNodeId: 'N4', section: 'W18X35'),
      ],
    );
  }

  group('Track 1: WebGPU Parallel Batch Surrogate Bridge & 60 FPS Pareto Dock', () {
    test('WebGPUSurrogateBridge evaluates 256 candidates with valid metrics', () async {
      final model = createTestModel();
      final result = await WebGPUSurrogateBridge.instance.evaluateParetoBatch(model, candidateCount: 256);

      expect(result.count, 256);
      expect(result.candidates.length, 256);
      expect(result.evalTimeMs, greaterThanOrEqualTo(0.0));

      final first = result.candidates.first;
      expect(first.steelTonnage, greaterThan(0.0));
      expect(first.embodiedCarbon, greaterThan(0.0));
      expect(first.governingDcr, greaterThan(0.0));
      expect(first.maxDriftRatio, greaterThan(0.0));
    });

    testWidgets('ParetoFrontierDock renders, morphs metrics, and commits design', (WidgetTester tester) async {
      final model = createTestModel();
      StructuralModel? committedModel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParetoFrontierDock(
              model: model,
              onCommit: (optimized) {
                committedModel = optimized;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('WEBGPU PARETO FRONTIER ENGINE'), findsOneWidget);
      expect(find.text('Commit Optimal Design'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(3));

      // Tap Commit Optimal Design button
      await tester.tap(find.text('Commit Optimal Design'));
      await tester.pumpAndSettle();

      expect(committedModel, isNotNull);
      expect(committedModel!.members.length, model.members.length);
    });
  });

  group('Track 2: Batch Multi-Select & Floating Inspector Panel', () {
    testWidgets('FloatingInspectorPanel shows BATCH EDIT MODE when >1 entity selected', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = createTestModel();
      String? assignedSection;
      String? assignedSupport;
      bool batchDeleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingInspectorPanel(
              model: model,
              selectedNodeIds: {'N1', 'N2'},
              selectedMemberIds: {'C1', 'C2', 'B1'},
              onModelChanged: () {},
              onClose: () {},
              onBatchAssignSection: (sec) => assignedSection = sec,
              onBatchAssignSupport: (sup) => assignedSupport = sup,
              onBatchDelete: () => batchDeleteCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('BATCH EDIT MODE'), findsOneWidget);
      expect(find.text('2 Joints, 3 Members'), findsOneWidget);
      expect(find.text('W14x90'), findsOneWidget);
      expect(find.text('Fixed Base'), findsOneWidget);

      // Tap batch AISC section chip
      await tester.tap(find.text('W14x90'));
      await tester.pumpAndSettle();
      expect(assignedSection, 'W14x90');

      // Tap batch support chip
      await tester.tap(find.text('Fixed Base'));
      await tester.pumpAndSettle();
      expect(assignedSupport, 'FIXED');

      // Tap Batch Delete button
      await tester.ensureVisible(find.textContaining('Batch Delete Selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Batch Delete Selected'));
      await tester.pumpAndSettle();
      expect(batchDeleteCalled, isTrue);
    });
  });
}
