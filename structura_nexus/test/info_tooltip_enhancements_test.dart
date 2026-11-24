// ============================================================================
// InfoTooltip & Engineering Clarity Enhancements Unit & Widget Tests
// Verifies Interactive Spec Modal, Formula Cards, Euler Buckling, and Crack Width Checks
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/data/benchmark_presets.dart';
import 'package:structura_nexus/widgets/info_tooltip.dart';
import 'package:structura_nexus/widgets/floating_inspector_panel.dart';
import 'package:structura_nexus/widgets/floating_telemetry_dock.dart';
import 'package:structura_nexus/widgets/workflow_guide_bar.dart';

void main() {
  group('InfoTooltip & Engineering Clarity Enhancements Tests', () {
    testWidgets('1. InfoTooltip renders zero-delay tooltip and opens interactive spec modal on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InfoTooltip(
                title: 'Euler Critical Column Buckling',
                codeRef: 'AISC 360-16 §E2',
                formula: 'P_e = π² · E · I / (K · L)²',
                standardOrRange: 'KL/r ≤ 200 for compression members',
                message:
                    'Evaluates elastic flexural buckling capacity and geometric slenderness ratio to prevent premature instability before material yield.',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the (i) info icon button is present
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

      // Tap the (i) info icon button to open the interactive spec modal
      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pumpAndSettle();

      // Verify modal dialog appeared with title, code reference, formula card, and description
      expect(find.text('Euler Critical Column Buckling'), findsOneWidget);
      expect(find.text('AISC 360-16 §E2'), findsOneWidget);
      expect(find.text('P_e = π² · E · I / (K · L)²'), findsOneWidget);
      expect(find.text('KL/r ≤ 200 for compression members'), findsOneWidget);
      expect(find.text('GOVERNING EQUATION / TENSOR FORMULATION'), findsOneWidget);
      expect(find.text('Copy Spec'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      // Dismiss the modal
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.text('GOVERNING EQUATION / TENSOR FORMULATION'), findsNothing);
    });

    testWidgets('2. InfoTooltip.wrap wraps arbitrary widget with rich engineering tooltip',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InfoTooltip.wrap(
                title: 'Direct Stiffness Method',
                codeRef: '12-DOF Direct Stiffness',
                formula: '[K_global] · {D} = {F}',
                message: 'Global linear algebraic stiffness matrix relating displacements to nodal forces.',
                child: const Text('CUSTOM_CHIP_LABEL'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CUSTOM_CHIP_LABEL'), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('3. FloatingInspectorPanel exposes Euler buckling Pe, slenderness, and crack width quick-checks',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = BenchmarkPresets.multiStorySwayFrame();
      final member = model.members.first;
      member.crackedSectionFactor = 0.35; // Concrete beam cracked modifier

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingInspectorPanel(
              model: model,
              selectedMemberId: member.id,
              selectedMemberIds: {member.id},
              onModelChanged: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Column Stability & Slenderness section is displayed
      expect(find.text('COLUMN STABILITY & SLENDERNESS'), findsOneWidget);
      expect(find.text('Slenderness KL/r'), findsOneWidget);
      expect(find.text('Euler Critical Pe'), findsOneWidget);

      // Verify ACI 224R Crack Width section is displayed for cracked member
      expect(find.text('ACI 224R CRACK WIDTH SERVICEABILITY'), findsOneWidget);
      expect(find.textContaining('Est. wk:'), findsOneWidget);
      expect(find.text('PASS ≤0.3mm'), findsOneWidget);
    });

    testWidgets('4. FloatingTelemetryDock and WorkflowGuideBar render with enriched InfoTooltips',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = BenchmarkPresets.multiStorySwayFrame();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                WorkflowGuideBar(
                  model: model,
                  onOpenTemplates: () {},
                  onApplyLoadsAndSupports: () {},
                  onRunFeaAndOptimize: () {},
                  onExportPePacket: () {},
                  onOpenCapabilitiesOverview: () {},
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: FloatingTelemetryDock(
                    maxDcr: 0.65,
                    isPass: true,
                    passCount: 16,
                    warnCount: 0,
                    failCount: 0,
                    driftRatio: 0.0018,
                    baseShearKn: 480.0,
                    alphaCr: 14.5,
                    b2Amp: 1.07,
                    activeLoadCombination: '1.2D+1.6L',
                    onCombinationChanged: (_) {},
                    onAutoSizerPressed: () {},
                    onParetoPressed: () {},
                    onStabilityPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify telemetry metrics and actions exist
      expect(find.text('BASE SHEAR'), findsOneWidget);
      expect(find.text('DRIFT RATIO'), findsOneWidget);
      expect(find.text('α_cr BUCKLING'), findsOneWidget);
      expect(find.text('B2 SWAY AMP'), findsOneWidget);
      expect(find.text('AI SECTION AUTO-SIZER'), findsOneWidget);
      expect(find.text('PARETO'), findsOneWidget);

      // Verify workflow guide steps
      expect(find.text('Step 1: Model Frame'), findsOneWidget);
      expect(find.text('Step 2: Restraints & Loads'), findsOneWidget);
      expect(find.text('Step 3: Solve & Code Check'), findsOneWidget);
      expect(find.text('Step 4: Export & Stamp'), findsOneWidget);
    });
  });
}
