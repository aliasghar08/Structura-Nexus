// ============================================================================
// SlideableWorkspaceMenu Widget Tests
// Verifies slideable drag, open-in-place toggle, customization & persistence
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/widgets/slideable_workspace_menu.dart';
import 'package:structura_nexus/services/workspace_storage.dart';

void main() {
  group('SlideableWorkspaceMenu Widget Tests', () {
    testWidgets('Renders collapsed toggle pill by default', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SlideableWorkspaceMenu(
                  workspaceKey: 'test_ws_1',
                  initialExpanded: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WORKSPACE TOOLS'), findsOneWidget);
      expect(find.text('MENU'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator_rounded), findsOneWidget);
    });

    testWidgets('Tapping toggle pill expands menu in-place with tools and categories', (tester) async {
      var copilotTriggered = false;

      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SlideableWorkspaceMenu(
                  workspaceKey: 'test_ws_2',
                  initialExpanded: false,
                  onOpenCopilot: () => copilotTriggered = true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to expand
      await tester.tap(find.text('WORKSPACE TOOLS'));
      await tester.pumpAndSettle();

      // Menu is now open in place
      expect(find.text('WORKSPACE TOOLS'), findsOneWidget);
      expect(find.text('MENU'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('AI & GEN'), findsOneWidget);
      expect(find.text('CAD & BIM'), findsOneWidget);
      expect(find.text('ANALYSIS'), findsOneWidget);

      // Verify tools are rendered
      expect(find.text('AI Structural Copilot'), findsOneWidget);
      expect(find.text('Generative Opt Auto-Sizer'), findsOneWidget);

      // Tap a tool
      await tester.tap(find.text('AI Structural Copilot'));
      await tester.pumpAndSettle();
      expect(copilotTriggered, isTrue);

      // Tap collapse button
      await tester.tap(find.byTooltip('Collapse Menu'));
      await tester.pumpAndSettle();

      // Collapsed back to toggle pill
      expect(find.text('WORKSPACE TOOLS'), findsOneWidget);
      expect(find.byTooltip('Collapse Menu'), findsNothing);
    });

    testWidgets('Tapping customize settings reveals dock side, width, and contrast options', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SlideableWorkspaceMenu(
                  workspaceKey: 'test_ws_3',
                  initialExpanded: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap customize icon
      await tester.tap(find.byTooltip('Customize Menu (Dock side, width, contrast, reset)'));
      await tester.pumpAndSettle();

      expect(find.text('CUSTOMIZE MENU'), findsOneWidget);
      expect(find.text('DOCK SIDE:'), findsOneWidget);
      expect(find.text('LEFT'), findsOneWidget);
      expect(find.text('RIGHT'), findsOneWidget);
      expect(find.text('WIDTH:'), findsOneWidget);
      expect(find.text('260'), findsOneWidget);
      expect(find.text('310'), findsOneWidget);
      expect(find.text('380'), findsOneWidget);
      expect(find.text('SOLID 98%'), findsOneWidget);
      expect(find.text('RESET DEFAULT'), findsOneWidget);

      // Change dock side to RIGHT
      await tester.tap(find.text('RIGHT'));
      await tester.pumpAndSettle();
      expect(WorkspacePreferences.getString('test_ws_3_dock_side', 'left'), equals('right'));

      // Change width to 260
      await tester.tap(find.text('260'));
      await tester.pumpAndSettle();
      expect(WorkspacePreferences.getDouble('test_ws_3_panel_width', 310.0), equals(260.0));
    });

    testWidgets('Vertical dragging slides menu and persists position', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SlideableWorkspaceMenu(
                  workspaceKey: 'test_ws_drag',
                  initialTop: 80.0,
                  initialExpanded: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dragHandleFinder = find.byIcon(Icons.drag_indicator_rounded);
      expect(dragHandleFinder, findsOneWidget);

      // Drag down by 75 pixels
      await tester.drag(dragHandleFinder, const Offset(0, 75));
      await tester.pumpAndSettle();

      final savedTop = WorkspacePreferences.getDouble('test_ws_drag_top_offset', 80.0);
      expect(savedTop, greaterThan(80.0));
    });

    testWidgets('Category tabs filter tool list', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SlideableWorkspaceMenu(
                  workspaceKey: 'test_ws_cat',
                  initialExpanded: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially ALL tools shown
      expect(find.text('AI Structural Copilot'), findsOneWidget);
      expect(find.text('Generative Opt Auto-Sizer'), findsOneWidget);

      // Tap CAD & BIM category
      await tester.tap(find.text('CAD & BIM'));
      await tester.pumpAndSettle();

      // Only CAD & BIM tools are displayed
      expect(find.text('Structural CAD Studio'), findsOneWidget);
      expect(find.text('AI Structural Copilot'), findsNothing);
    });
  });
}
