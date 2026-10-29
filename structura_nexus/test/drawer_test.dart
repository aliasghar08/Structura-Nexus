// ============================================================================
// WorkstationDrawer Widget Tests
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/widgets/workstation_drawer.dart';

void main() {
  group('WorkstationDrawer Widget Tests', () {
    testWidgets('Renders all primary tool suite buttons inside drawer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: const WorkstationDrawer(),
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('TOOLS & SUITE'), findsOneWidget);
      expect(find.text('AI Copilot'), findsOneWidget);
      expect(find.text('Generative Opt'), findsOneWidget);
      expect(find.text('Gen Bracing'), findsOneWidget);
      expect(find.text('CAD Studio'), findsOneWidget);
      expect(find.text('Cloud Library'), findsOneWidget);
      expect(find.text('Concrete Studio'), findsOneWidget);
      expect(find.text('Steel Connections'), findsOneWidget);
      expect(find.text('Foundation & SSI'), findsOneWidget);
      expect(find.text('Composite Floor'), findsOneWidget);
      expect(find.text('Modal Seismic'), findsOneWidget);
      expect(find.text('Lateral Stability'), findsOneWidget);
      expect(find.text('Non-Linear Pushover'), findsOneWidget);
      expect(find.text('Wind Tunnel CFD'), findsOneWidget);
      expect(find.text('Dynamic Stimulator'), findsOneWidget);
      expect(find.text('PE Calcs & BIM'), findsOneWidget);
      expect(find.text('Embodied Carbon'), findsOneWidget);
    });

    testWidgets('Tapping tool button inside drawer triggers callback', (tester) async {
      var copilotTriggered = false;
      var cadTriggered = false;

      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: WorkstationDrawer(
              onOpenCopilot: () => copilotTriggered = true,
              onOpenCadStudio: () => cadTriggered = true,
            ),
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap AI Copilot
      await tester.tap(find.text('AI Copilot'));
      await tester.pumpAndSettle();
      expect(copilotTriggered, isTrue);

      // Reopen drawer
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap CAD Studio
      await tester.tap(find.text('CAD Studio'));
      await tester.pumpAndSettle();
      expect(cadTriggered, isTrue);
    });

    testWidgets('Searching tools inside drawer filters displayed tools', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: const WorkstationDrawer(),
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'cad');
      await tester.pumpAndSettle();

      expect(find.text('CAD Studio'), findsOneWidget);
      expect(find.text('AI Copilot'), findsNothing);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('AI Copilot'), findsOneWidget);
      expect(find.text('CAD Studio'), findsOneWidget);
    });
  });
}
