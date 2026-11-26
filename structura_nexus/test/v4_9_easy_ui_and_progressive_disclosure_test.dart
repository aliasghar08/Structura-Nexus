// ============================================================================
// Structura Nexus: v4.9 Easy UI & Progressive Disclosure Test Suite
// Verifies Essential vs Pro Suite toggle, Welcome Quickstart Launcher,
// Keyboard Shortcuts Dialog, and Empty-State Inspector Guidance.
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/models/structural_models.dart';
import 'package:structura_nexus/services/workspace_storage.dart';
import 'package:structura_nexus/widgets/welcome_quickstart_overlay.dart';
import 'package:structura_nexus/widgets/keyboard_shortcuts_dialog.dart';
import 'package:structura_nexus/widgets/floating_inspector_panel.dart';
import 'package:structura_nexus/widgets/floating_telemetry_dock.dart';
import 'package:structura_nexus/widgets/slideable_workspace_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    WorkspacePreferences.remove('hide_welcome_quickstart');
    WorkspacePreferences.remove('is_essential_mode');
    WorkspacePreferences.remove('test_ws_is_expanded');
  });

  group('v4.9 Welcome Quick-Start Launcher Tests', () {
    testWidgets('Renders all 4 plain-English cards and handles callbacks', (tester) async {
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
      expect(find.text('Explore 24 Sample Structures'), findsOneWidget);
      expect(find.text('Convert 2D Floorplan to 3D'), findsOneWidget);
      expect(find.text('Start Guided Step-by-Step Build'), findsOneWidget);
      expect(find.text('Auto-Optimize Steel & PE Report'), findsOneWidget);

      // Tap Card 1: Explore 24 Sample Structures
      await tester.tap(find.text('Explore 24 Sample Structures'));
      await tester.pumpAndSettle();
      expect(exploredSamples, isTrue);

      // Tap Card 2: Convert 2D Floorplan to 3D
      await tester.tap(find.text('Convert 2D Floorplan to 3D'));
      await tester.pumpAndSettle();
      expect(visionTriggered, isTrue);

      // Tap Card 3: Start Guided Step-by-Step Build
      await tester.tap(find.text('Start Guided Step-by-Step Build'));
      await tester.pumpAndSettle();
      expect(guidedBuildTriggered, isTrue);

      // Tap Card 4: Auto-Optimize Steel & PE Report
      await tester.tap(find.text('Auto-Optimize Steel & PE Report'));
      await tester.pumpAndSettle();
      expect(autoOptimizeTriggered, isTrue);

      // Tap dismiss icon button
      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });

    testWidgets('Checking "Do not show again" persists preference upon dismissal', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomeQuickstartOverlay(
              onExploreSamples: () {},
              onVisionToBim: () {},
              onStartGuidedBuild: () {},
              onAutoOptimizeAndReport: () {},
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(WorkspacePreferences.getBool('hide_welcome_quickstart', false), isFalse);

      // Tap checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Tap "Enter Canvas" button
      await tester.tap(find.text('Enter Canvas'));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
      expect(WorkspacePreferences.getBool('hide_welcome_quickstart', false), isTrue);
    });
  });

  group('v4.9 Keyboard Shortcuts Dialog Tests', () {
    testWidgets('Renders hotkeys legend with camera presets and editing keys', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showKeyboardShortcutsDialog(ctx),
                child: const Text('Show Shortcuts'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Shortcuts'));
      await tester.pumpAndSettle();

      expect(find.text('KEYBOARD SHORTCUTS'), findsOneWidget);
      expect(find.text('3D CAMERA & VIEWPORT PRESETS'), findsOneWidget);
      expect(find.text('MODELING & SELECTION'), findsOneWidget);
      expect(find.text('Isometric View'), findsOneWidget);
      expect(find.text('Top Plan View (X-Z)'), findsOneWidget);
      expect(find.text('Front Elevation (X-Y)'), findsOneWidget);
      expect(find.text('Recenter & Auto-Fit'), findsOneWidget);

      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();
      expect(find.text('KEYBOARD SHORTCUTS'), findsNothing);
    });
  });

  group('v4.9 Empty State Inspector Guidance Tests', () {
    testWidgets('Displays 3-bullet interaction guide when nothing is selected', (tester) async {
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
      expect(find.textContaining('Drag any joint', findRichText: true), findsOneWidget);
    });
  });

  group('v4.9 Progressive Disclosure & Essential Mode Tests', () {
    testWidgets('FloatingTelemetryDock hides Pod 4 in Essential Mode', (tester) async {
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

      expect(find.text('SAFE'), findsOneWidget);
      expect(find.text('ASCE 7-16 LOAD COMBINATIONS'), findsOneWidget);
      expect(find.text('BASE SHEAR'), findsOneWidget);
      expect(find.text('DRIFT RATIO'), findsOneWidget);
      // Pod 4 should be hidden in Essential mode
      expect(find.text('α_cr BUCKLING'), findsNothing);
    });

    testWidgets('FloatingTelemetryDock shows Pod 4 in Pro Suite Mode', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingTelemetryDock(
              isEssentialMode: false,
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

      expect(find.text('PASSED'), findsOneWidget);
      expect(find.text('α_cr BUCKLING'), findsOneWidget);
      expect(find.text('B2 SWAY AMP'), findsOneWidget);
    });

    testWidgets('SlideableWorkspaceMenu filters frontier tools in Essential Mode', (tester) async {
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

      // Core tool visible
      expect(find.text('Add 3D Joint'), findsOneWidget);
      // Swarm tool filtered out
      expect(find.text('4-Agent Autonomous Swarm'), findsNothing);
      // Show Pro Frontier Tools toggle pill present
      expect(find.text('+ Show Pro Frontier Tools'), findsOneWidget);

      await tester.tap(find.text('+ Show Pro Frontier Tools'));
      await tester.pumpAndSettle();
      expect(toggleTriggered, isTrue);
    });
  });
}
