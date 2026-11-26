// ============================================================================
// Structura Nexus: v4.9 Easy UI & Samples Test Suite
// Verifies Essential vs Pro Suite toggle, 3 spacious telemetry pods,
// Welcome Quickstart Overlay, 3-step Inspector hints, 24-sample library,
// and Header quick-cycle stepper.
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/data/benchmark_presets.dart';
import 'package:structura_nexus/models/structural_models.dart';
import 'package:structura_nexus/services/workspace_storage.dart';
import 'package:structura_nexus/widgets/welcome_quickstart_overlay.dart';
import 'package:structura_nexus/widgets/floating_inspector_panel.dart';
import 'package:structura_nexus/widgets/floating_telemetry_dock.dart';
import 'package:structura_nexus/widgets/slideable_workspace_menu.dart';
import 'package:structura_nexus/widgets/floating_workstation_header.dart';
import 'package:structura_nexus/widgets/building_templates_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    WorkspacePreferences.remove('hide_welcome_quickstart');
    WorkspacePreferences.remove('is_essential_mode');
    WorkspacePreferences.remove('test_ws_is_expanded');
  });

  group('1. Essential vs. Pro Suite Toggle & Progressive Disclosure', () {
    testWidgets('Header renders Essential / Pro toggle and switches mode', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool modeToggled = false;
      final model = BenchmarkPresets.multiStorySwayFrame();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingWorkstationHeader(
              model: model,
              isBackendConnected: true,
              isEssentialMode: true,
              onToggleWorkspaceMode: () => modeToggled = true,
              onEngineChanged: (_) {},
              onModeChanged: (_) {},
              onDeformationScaleChanged: (_) {},
              onPresetSelected: (_) {},
              onSolveTriggered: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ESSENTIAL'), findsOneWidget);
      expect(find.text('PRO SUITE'), findsOneWidget);

      await tester.tap(find.text('PRO SUITE'));
      await tester.pumpAndSettle();
      expect(modeToggled, isTrue);
    });

    testWidgets('FloatingTelemetryDock displays 3 spacious pods with exact titles in Essential mode', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingTelemetryDock(
              isEssentialMode: true,
              maxDcr: 0.85,
              isPass: true,
              baseShearKn: 125.0,
              driftRatio: 0.0035,
              alphaCr: 14.2,
              b2Amp: 1.05,
              activeLoadCombination: '1.2D + 1.6L',
              onCombinationChanged: (_) {},
              onAutoSizerPressed: () {},
              onStabilityPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pod 1: MAX STRESS (DCR) with SAFE badge
      expect(find.text('MAX STRESS (DCR)'), findsOneWidget);
      expect(find.text('SAFE'), findsOneWidget);

      // Pod 2: LOAD COMBINATION
      expect(find.text('LOAD COMBINATION'), findsOneWidget);

      // Pod 3: GLOBAL DRIFT & AUTO-SIZER
      expect(find.text('GLOBAL DRIFT & AUTO-SIZER'), findsOneWidget);

      // Pod 4 should be hidden in Essential mode
      expect(find.text('α_cr BUCKLING'), findsNothing);
    });

    testWidgets('SlideableWorkspaceMenu filters frontier tools in Essential mode', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool toggleTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SlideableWorkspaceMenu(
                  workspaceKey: 'test_ws',
                  title: 'WORKSPACE TOOLS',
                  subtitle: 'Tools',
                  badgeText: 'DRAWING',
                  initialExpanded: true,
                  isEssentialMode: true,
                  onToggleWorkspaceMode: () => toggleTriggered = true,
                  customTools: [
                    WorkspaceToolItem(
                      label: 'Add 3D Joint',
                      subtitle: 'Place joint',
                      icon: Icons.circle,
                      color: Colors.cyan,
                      category: 'DRAW & MODEL',
                      badge: 'POINT',
                      onTap: () {},
                    ),
                    WorkspaceToolItem(
                      label: '4-Agent Autonomous Swarm',
                      subtitle: 'Multi-agent optimization',
                      icon: Icons.groups_rounded,
                      color: Colors.purple,
                      category: 'ADVANCED',
                      badge: 'SWARM',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add 3D Joint'), findsOneWidget);
      expect(find.text('4-Agent Autonomous Swarm'), findsNothing);
      expect(find.text('+ Show Pro Frontier Tools'), findsOneWidget);

      await tester.tap(find.text('+ Show Pro Frontier Tools'));
      await tester.pumpAndSettle();
      expect(toggleTriggered, isTrue);
    });
  });

  group('2. Welcome Quick-Start Overlay & Guided Empty Inspector', () {
    testWidgets('Welcome overlay renders 4 plain-English 1-click cards and handles actions', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool exploredSamples = false;
      bool visionTriggered = false;
      bool guidedBuildTriggered = false;
      bool autoOptimizeTriggered = false;
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomeQuickstartOverlay(
              onExploreSamples: () => exploredSamples = true,
              onVisionToBim: () => visionTriggered = true,
              onStartGuidedBuild: () => guidedBuildTriggered = true,
              onAutoOptimizeAndReport: () => autoOptimizeTriggered = true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WELCOME TO STRUCTURA NEXUS'), findsOneWidget);
      expect(find.text('Browse 24 Sample Structures'), findsOneWidget);
      expect(find.text('Convert 2D Floorplan (PDF/PNG) to 3D'), findsOneWidget);
      expect(find.text('Build Custom Frame Step-by-Step'), findsOneWidget);
      expect(find.text('Auto-Optimize Steel & Export PE Packet'), findsOneWidget);

      // Tap Card 1
      await tester.tap(find.text('Browse 24 Sample Structures'));
      await tester.pumpAndSettle();
      expect(exploredSamples, isTrue);

      // Tap Card 2
      await tester.tap(find.text('Convert 2D Floorplan (PDF/PNG) to 3D'));
      await tester.pumpAndSettle();
      expect(visionTriggered, isTrue);

      // Tap Card 3
      await tester.tap(find.text('Build Custom Frame Step-by-Step'));
      await tester.pumpAndSettle();
      expect(guidedBuildTriggered, isTrue);

      // Tap Card 4
      await tester.tap(find.text('Auto-Optimize Steel & Export PE Packet'));
      await tester.pumpAndSettle();
      expect(autoOptimizeTriggered, isTrue);

      // Tap dismiss
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });

    testWidgets('FloatingInspectorPanel empty state displays 3-step visual hints', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = StructuralModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 800,
              child: FloatingInspectorPanel(
                model: model,
                selectedNodeId: null,
                selectedMemberId: null,
                selectedNodeIds: const {},
                selectedMemberIds: const {},
                onModelChanged: () {},
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QUICK INTERACTION GUIDE'), findsOneWidget);
      expect(find.textContaining('Click a joint', findRichText: true), findsOneWidget);
      expect(find.textContaining('Click a beam/column', findRichText: true), findsOneWidget);
      expect(find.textContaining('Shift+Click to batch edit', findRichText: true), findsOneWidget);
      expect(find.textContaining('Drag any joint in 3D', findRichText: true), findsOneWidget);
    });
  });

  group('3. 24-Sample Categorized Library & Header Quick-Switcher', () {
    testWidgets('BuildingTemplatesDialog displays filter pills and Load & Solve button', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = BenchmarkPresets.multiStorySwayFrame();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildingTemplatesDialog(
              currentModel: model,
              onModelSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify category filter pills
      expect(find.textContaining('All (24)'), findsOneWidget);
      expect(find.textContaining('Buildings'), findsOneWidget);
      expect(find.textContaining('Bridges'), findsOneWidget);
      expect(find.textContaining('Long-Span'), findsOneWidget);
      expect(find.textContaining('Concrete & Soil'), findsOneWidget);
      expect(find.textContaining('Seismic & Blast'), findsOneWidget);
      expect(find.textContaining('Benchmarks'), findsOneWidget);

      // Verify LOAD & SOLVE button is present
      expect(find.text('LOAD & SOLVE'), findsWidgets);
    });

    testWidgets('FloatingWorkstationHeader cycles samples via stepper buttons', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = BenchmarkPresets.multiStorySwayFrame();
      String? selectedPresetId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingWorkstationHeader(
              model: model,
              isBackendConnected: true,
              onEngineChanged: (_) {},
              onModeChanged: (_) {},
              onDeformationScaleChanged: (_) {},
              onPresetSelected: (presetId) => selectedPresetId = presetId,
              onSolveTriggered: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Sample 01/24 formatting
      expect(find.textContaining('Sample 01/24'), findsOneWidget);

      // Find and tap next button
      final nextBtn = find.byTooltip('Next Sample: 4-Story Educational Campus Frame');
      expect(nextBtn, findsOneWidget);
      await tester.ensureVisible(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(selectedPresetId, 'campus_4s');
    });
  });
}
