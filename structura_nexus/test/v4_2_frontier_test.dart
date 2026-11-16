// ============================================================================
// STRUCTURA NEXUS v4.2 — FRONTIER AI & ENGINE TEST SUITE
// Tests 3D Diagrid Topology Synthesizer, Shop Drawing QA, and Voice Co-Pilot
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:structura_nexus/models/structural_models.dart';
import 'package:structura_nexus/services/voice_copilot_service.dart';
import 'package:structura_nexus/widgets/generative_topology_dialog.dart';
import 'package:structura_nexus/widgets/shop_drawing_audit_dialog.dart';
import 'package:structura_nexus/widgets/voice_copilot_pill.dart';

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

  group('Track 1: Generative 3D Topology Optimization & Marching Struts Dialog', () {
    testWidgets('GenerativeTopologyDialog renders, toggles styles, and commits exoskeleton', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final model = createTestModel();
      StructuralModel? committedModel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenerativeTopologyDialog(
              currentModel: model,
              onCommitModel: (newModel) {
                committedModel = newModel;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header and Title
      expect(find.textContaining('GENERATIVE 3D TOPOLOGY SYNTHESIZER'), findsOneWidget);
      expect(find.textContaining('Neural SIMP'), findsOneWidget);

      // Verify Style Chips
      expect(find.text('3D Triangulated Diagrid'), findsOneWidget);
      expect(find.text('Voronoi Exoskeleton'), findsOneWidget);
      expect(find.text('Variable Space Truss'), findsOneWidget);

      // Tap alternate style
      await tester.tap(find.text('Voronoi Exoskeleton'));
      await tester.pumpAndSettle();

      // Verify Telemetry
      expect(find.textContaining('STEEL TONNAGE SAVINGS'), findsOneWidget);
      expect(find.textContaining('SKELETAL NODES'), findsOneWidget);

      // Tap Commit Button
      final commitBtn = find.text('Commit Exoskeleton to Viewport');
      expect(commitBtn, findsOneWidget);
      await tester.ensureVisible(commitBtn);
      await tester.tap(commitBtn);
      await tester.pumpAndSettle();

      expect(committedModel, isNotNull);
      expect(committedModel!.nodes.length, greaterThan(10));
      expect(committedModel!.members.length, greaterThan(20));
    });
  });

  group('Track 2: Shop-Drawing & Site Connection Visual QA Auditor Dialog', () {
    testWidgets('ShopDrawingAuditDialog renders presets, evaluates AISC/ACI code, and punchlist', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShopDrawingAuditDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Dialog Title
      expect(find.textContaining('SHOP-DRAWING & CONNECTION VISUAL QA AUDITOR'), findsOneWidget);
      expect(find.textContaining('ConnectionNet-AI'), findsOneWidget);

      // Verify Presets
      expect(find.text('Moment End-Plate'), findsOneWidget);
      expect(find.text('Baseplate & Anchors'), findsOneWidget);
      expect(find.text('RC Rebar Cage'), findsOneWidget);

      // Check Pass status on default preset
      expect(find.textContaining('AISC / ACI COMPLIANT'), findsOneWidget);

      // Switch to Baseplate defect preset
      await tester.tap(find.text('Baseplate & Anchors'));
      await tester.pumpAndSettle();

      expect(find.textContaining('REJECTED WITH PUNCHLIST'), findsOneWidget);
      expect(find.textContaining('AISC-J3.4-EDGE-DIST'), findsOneWidget);

      // Verify Export Punchlist button
      expect(find.text('Export Punch-List'), findsOneWidget);
      await tester.tap(find.text('Export Punch-List'));
      await tester.pump();
    });
  });

  group('Track 3: Gemini Live Spatial Voice Co-Pilot Service & Pill', () {
    test('VoiceCopilotService parses spatial engineering commands into callbacks', () async {
      final service = VoiceCopilotService.instance;

      bool chevronFired = false;
      double? windMphFired;
      List<String>? highlightedMembersFired;
      bool autoSizerFired = false;

      service.onAddChevronBracing = () => chevronFired = true;
      service.onApplyWindLoads = (mph, exp) => windMphFired = mph;
      service.onHighlightMembers = (ids) => highlightedMembersFired = ids;
      service.onRunAutoSizer = () => autoSizerFired = true;

      // 1. Chevron Bracing
      await service.simulateVoiceCommand('Add chevron bracing to the core bays');
      expect(chevronFired, isTrue);

      // 2. Wind Loads
      await service.simulateVoiceCommand('Apply 145 mph Exposure D wind loads');
      expect(windMphFired, 145.0);

      // 3. Emissive Highlights
      await service.simulateVoiceCommand('Highlight columns with DCR above 0.85 or B2 above 1.15');
      expect(highlightedMembersFired, isNotNull);
      expect(highlightedMembersFired!.isNotEmpty, isTrue);

      // 4. Auto-sizer
      await service.simulateVoiceCommand('Run auto-sizer');
      expect(autoSizerFired, isTrue);
    });

    testWidgets('VoiceCopilotPill renders, expands tray, and triggers quick commands', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: const [
                Positioned(
                  bottom: 50,
                  right: 20,
                  child: VoiceCopilotPill(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Pill Title
      expect(find.textContaining('GEMINI LIVE COPILOT'), findsOneWidget);

      // Expand tray
      final expandBtn = find.byIcon(Icons.keyboard_arrow_down_rounded);
      expect(expandBtn, findsOneWidget);
      await tester.tap(expandBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify quick command suggestions
      expect(find.text('Add chevron bracing to the core bays'), findsOneWidget);
      expect(find.text('Run auto-sizer'), findsOneWidget);

      // Tap quick command
      await tester.tap(find.text('Run auto-sizer'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(VoiceCopilotService.instance.lastSpokenFeedback, contains('auto-sizer'));
    });
  });
}
