// ============================================================================
// FloatingInspectorPanel Widget Tests
// Verifies 6-DOF support toggles, coordinate inputs, presets, and tooltips
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/data/benchmark_presets.dart';
import 'package:structura_nexus/widgets/floating_inspector_panel.dart';
import 'package:structura_nexus/widgets/info_tooltip.dart';

void main() {
  group('FloatingInspectorPanel Widget Tests', () {
    testWidgets('Renders empty state when no entity is selected', (tester) async {
      final model = BenchmarkPresets.multiStorySwayFrame();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingInspectorPanel(
              model: model,
              onModelChanged: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SELECTION INSPECTOR'), findsOneWidget);
      expect(find.text('PROPRIETARY NEURAL CORE'), findsOneWidget);
    });

    testWidgets('Toggling 6-DOF support modifies node restraint and fires callback', (tester) async {
      final model = BenchmarkPresets.multiStorySwayFrame();
      final node = model.nodes.first;
      var modelChanged = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingInspectorPanel(
              model: model,
              selectedNodeId: node.id,
              onModelChanged: () => modelChanged = true,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('JOINT: ${node.id}'), findsOneWidget);
      expect(find.text('6-DOF SUPPORTS (DIRICHLET)'), findsOneWidget);

      // Verify InfoTooltip presence and instant hover configuration
      final tooltipWidgets = tester.widgetList<InfoTooltip>(find.byType(InfoTooltip));
      expect(tooltipWidgets, isNotEmpty);
      expect(tooltipWidgets.first.size, equals(18.0));

      final tooltipFinder = find.descendant(
        of: find.byType(InfoTooltip),
        matching: find.byType(Tooltip),
      );
      expect(tooltipFinder, findsWidgets);
      final firstTooltip = tester.widget<Tooltip>(tooltipFinder.first);
      expect(firstTooltip.waitDuration, equals(Duration.zero));

      // Tap u_x toggle
      final uxFinder = find.text('u_x');
      expect(uxFinder, findsOneWidget);
      final initialUx = node.restraint[0];

      await tester.tap(uxFinder);
      await tester.pumpAndSettle();

      expect(node.restraint[0], equals(initialUx == 1 ? 0 : 1));
      expect(modelChanged, isTrue);

      // Test preset FIXED - all 6 DOFs become active with solid cyan background
      await tester.tap(find.text('FIXED'));
      await tester.pumpAndSettle();
      expect(node.isFixed, isTrue);

      // Verify active 6-DOF toggle has black text on solid cyan
      final activeUxText = tester.widget<Text>(find.text('u_x'));
      expect(activeUxText.style?.color, equals(Colors.black));

      // Test preset FREE - all 6 DOFs become inactive with dark gray
      await tester.tap(find.text('FREE'));
      await tester.pumpAndSettle();
      expect(node.restraint.every((r) => r == 0), isTrue);

      final inactiveUxText = tester.widget<Text>(find.text('u_x'));
      expect(inactiveUxText.style?.color, equals(const Color(0xFF8B949E)));
    });

    testWidgets('Entering node coordinates updates StructuralNode and fires callback', (tester) async {
      final model = BenchmarkPresets.multiStorySwayFrame();
      final node = model.nodes.first;
      var modelChanged = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingInspectorPanel(
              model: model,
              selectedNodeId: node.id,
              onModelChanged: () => modelChanged = true,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the TextField for coordinate X
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(3)); // X, Y, Z

      await tester.enterText(textFields.first, '7.5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(node.coords.x, equals(7.5));
      expect(modelChanged, isTrue);
    });
  });
}
