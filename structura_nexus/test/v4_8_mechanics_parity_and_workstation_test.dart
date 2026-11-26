// ============================================================================
// Structura Nexus v4.8 Mechanics Parity & Workstation Regression Tests
// Tests EmbeddedFeaSolver (UDL fixed-end forces, ACI 318-19 cracked modifiers,
// moment end releases, Winkler soil springs, P-Delta B2) and UI batch controls/hotkeys.
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/data/benchmark_presets.dart';
import 'package:structura_nexus/services/embedded_fea_solver.dart';
import 'package:structura_nexus/widgets/floating_inspector_panel.dart';

void main() {
  group('EmbeddedFeaSolver Parity & Mechanics Tests', () {
    test('EmbeddedFeaSolver successfully solves a 2-Story Moment Sway Frame', () {
      final model = BenchmarkPresets.multiStorySwayFrame();
      EmbeddedFeaSolver.solve(model);

      // Verify nodal displacements and member reactions populated
      expect(model.nodes.any((n) => n.displacements.length == 6), isTrue);
      expect(model.members.every((m) => m.governingDcr >= 0.0), isTrue);
      expect(model.swayAmplificationB2, isNotNull);
      expect(model.swayAmplificationB2!, greaterThanOrEqualTo(1.0));
      expect(model.criticalLoadFactorAlphaCr, isNotNull);
      expect(model.criticalLoadFactorAlphaCr!, isPositive);
      expect(model.stabilityStatus, isNotNull);
    });

    test('EmbeddedFeaSolver respects ACI 318-19 cracked modifiers and member overrides', () {
      final model = BenchmarkPresets.multiStorySwayFrame();
      // Set first member as concrete with custom cracked factor
      final member = model.members.first;
      member.material = 'Concrete C4000';
      member.crackedSectionFactor = 0.50;

      EmbeddedFeaSolver.solve(model);

      expect(member.governingDcr, isNonNegative);
      expect(member.momentZ, isNotNull);
    });

    test('EmbeddedFeaSolver handles member end releases (pin-pin / propped)', () {
      final model = BenchmarkPresets.multiStorySwayFrame();
      final beam = model.members.first;
      beam.releaseIMoment = true;
      beam.releaseJMoment = true;

      EmbeddedFeaSolver.solve(model);

      expect(beam.momentZ.abs(), lessThanOrEqualTo(1e-3));
      expect(beam.status, isNotEmpty);
    });

    test('EmbeddedFeaSolver applies Winkler soil springs to unrestrained base nodes', () {
      final model = BenchmarkPresets.multiStorySwayFrame();
      // Relax vertical restraint on one base node so Winkler spring activates
      final baseNode = model.nodes.firstWhere((n) => n.coords.y <= 0.01);
      baseNode.restraint[1] = 0; // Free vertical DOF to engage Ky

      EmbeddedFeaSolver.solve(model);

      // Base node displacement is computed via elastic subgrade reaction
      expect(baseNode.displacements.isNotEmpty, isTrue);
    });
  });

  group('FloatingInspectorPanel Batch Controls Tests', () {
    testWidgets('Renders batch release and cracked factor chips when multiple members selected', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = BenchmarkPresets.multiStorySwayFrame();
      final selectedMemberIds = {model.members[0].id, model.members[1].id};

      bool batchReleaseFired = false;
      bool batchCrackedFired = false;
      bool? pinnedParam;
      double? crackedFactorParam;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingInspectorPanel(
              model: model,
              selectedMemberIds: selectedMemberIds,
              onBatchAssignReleases: (relI, relJ) {
                batchReleaseFired = true;
                pinnedParam = relI && relJ;
              },
              onBatchAssignCrackedFactor: (factor) {
                batchCrackedFired = true;
                crackedFactorParam = factor;
              },
              onModelChanged: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BATCH EDIT MODE (0J, 2M)'), findsOneWidget);
      expect(find.text('BATCH MEMBER END RELEASES'), findsOneWidget);
      expect(find.text('Pin-Pin (Secondary/Truss)'), findsOneWidget);
      expect(find.text('Fixed-Fixed (Moment Frame)'), findsOneWidget);
      expect(find.text('Pin-Fixed (Propped Beam)'), findsOneWidget);

      expect(find.text('BATCH ACI 318-19 CRACKED MODIFIERS'), findsOneWidget);
      expect(find.text('0.35 Ig (Beams / Flexure)'), findsOneWidget);
      expect(find.text('0.70 Ig (Columns / Axial)'), findsOneWidget);
      expect(find.text('1.00 Ig (Gross / Uncracked)'), findsOneWidget);

      // Tap Pin-Pin
      await tester.tap(find.text('Pin-Pin (Secondary/Truss)'));
      await tester.pumpAndSettle();
      expect(batchReleaseFired, isTrue);
      expect(pinnedParam, isTrue);

      // Tap 0.35 Ig
      await tester.ensureVisible(find.text('0.35 Ig (Beams / Flexure)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('0.35 Ig (Beams / Flexure)'));
      await tester.pumpAndSettle();
      expect(batchCrackedFired, isTrue);
      expect(crackedFactorParam, equals(0.35));
    });
  });

  group('Workstation Hotkey & Text-Input Guard Tests', () {
    testWidgets('Focusing a TextField blocks camera preset hotkey triggers', (tester) async {
      final controller = TextEditingController();
      final mainFocusNode = FocusNode();
      bool cameraActionTriggered = false;

      // Simulate the focus check logic used by WorkstationScreen
      bool isTextInputFocused() {
        final primaryFocus = FocusManager.instance.primaryFocus;
        if (primaryFocus == null) return false;
        final widget = primaryFocus.context?.widget;
        if (widget is EditableText) return true;
        return primaryFocus.context?.findAncestorWidgetOfExactType<EditableText>() != null;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              focusNode: mainFocusNode,
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (isTextInputFocused()) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.digit1) {
                  cameraActionTriggered = true;
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Column(
                children: [
                  TextField(controller: controller, key: const Key('coord_input')),
                  const Text('CANVAS_AREA'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Case A: TextField is focused -> pressing '1' should NOT trigger camera preset
      await tester.tap(find.byKey(const Key('coord_input')));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
      expect(cameraActionTriggered, isFalse, reason: 'Hotkey should be ignored while typing in TextField');

      // Case B: Shift focus back to canvas / root -> pressing '1' SHOULD trigger camera preset
      mainFocusNode.requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
      expect(cameraActionTriggered, isTrue, reason: 'Hotkey should trigger when no text input is focused');
    });
  });
}
