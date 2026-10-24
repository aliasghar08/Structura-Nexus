// ============================================================================
// WorkstationSidebar Widget Tests
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/widgets/workstation_sidebar.dart';

void main() {
  group('WorkstationSidebar Widget Tests', () {
    testWidgets('Renders all primary tool suite buttons in expanded mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkstationSidebar(initialExpanded: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TOOLS & SUITE'), findsOneWidget);
      expect(find.text('AI Copilot'), findsOneWidget);
      expect(find.text('Generative Opt'), findsOneWidget);
      expect(find.text('Gen Bracing'), findsOneWidget);
      expect(find.text('CAD Studio'), findsOneWidget);
      expect(find.text('Cloud Library'), findsOneWidget);
      expect(find.text('Modal Seismic'), findsOneWidget);
      expect(find.text('Lateral Stability'), findsOneWidget);
      expect(find.text('PE Calcs & BIM'), findsOneWidget);
      expect(find.text('Embodied Carbon'), findsOneWidget);
    });

    testWidgets('Tapping tool button triggers corresponding callback', (tester) async {
      var copilotTriggered = false;
      var cadTriggered = false;

      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkstationSidebar(
              initialExpanded: true,
              onOpenCopilot: () => copilotTriggered = true,
              onOpenCadStudio: () => cadTriggered = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('AI Copilot'));
      await tester.pumpAndSettle();
      expect(copilotTriggered, isTrue);

      await tester.tap(find.text('CAD Studio'));
      await tester.pumpAndSettle();
      expect(cadTriggered, isTrue);
    });

    testWidgets('Tapping collapse button toggles sidebar width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkstationSidebar(initialExpanded: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap collapse button
      await tester.tap(find.byTooltip('Collapse Menu'));
      await tester.pumpAndSettle();

      // Header text is collapsed
      expect(find.text('TOOLS & SUITE'), findsNothing);
      expect(find.byTooltip('Expand Menu'), findsOneWidget);
    });
  });
}
