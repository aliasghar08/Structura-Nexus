// ============================================================================
// Structura Nexus v4.4-APEX — Progressive Collapse, Command Palette & Rich (i)
// Unit & Widget Verification Suite
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/data/benchmark_presets.dart';
import 'package:structura_nexus/services/progressive_collapse_engine.dart';
import 'package:structura_nexus/widgets/command_palette_dialog.dart';
import 'package:structura_nexus/widgets/info_tooltip.dart';
import 'package:structura_nexus/widgets/progressive_collapse_dialog.dart';
import 'package:structura_nexus/widgets/slideable_workspace_menu.dart';

void main() {
  group('Structura Nexus v4.4-APEX Advancement & Usability Suite', () {
    test('ProgressiveCollapseEngine evaluates UFC 4-023-03 column removal & vulnerability sweep', () {
      final model = BenchmarkPresets.multiStorySwayFrame();
      final candidates = ProgressiveCollapseEngine.findCandidateColumns(model);
      expect(candidates, isNotEmpty);

      final sweep = ProgressiveCollapseEngine.runVulnerabilitySweep(
        model: model,
        dynamicIncreaseFactor: 2.0,
      );
      expect(sweep, isNotEmpty);

      final mostCritical = sweep.first;
      expect(mostCritical.dynamicAmplificationFactor, equals(2.0));
      expect(mostCritical.catenaryDeflectionMm, greaterThan(0.0));
      expect(mostCritical.damagedMaxDcr, greaterThan(0.0));
      expect(mostCritical.damagedModel.members.length, equals(model.members.length - 1));
    });

    testWidgets('Rich InfoTooltip renders glowing (i) icon and rich code reference span', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InfoTooltip(
                title: 'AISC 360-16 Section Auto-Sizer',
                codeRef: 'AISC 360-16 §H1.1',
                message: 'Optimizes wide-flange steel profiles so governing DCR <= 1.0.',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(InfoTooltip), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('SlideableWorkspaceMenu renders hover (i) InfoTooltip on every tool row', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SlideableWorkspaceMenu(
                  initialExpanded: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header + Footer + visible tool rows all have InfoTooltip buttons
      expect(find.byType(InfoTooltip), findsWidgets);
    });

    testWidgets('CommandPaletteDialog searches and filters engineering commands with (i) tooltips', (tester) async {
      bool triggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPaletteDialog(
              actions: [
                CommandPaletteAction(
                  title: 'Progressive Collapse & Alternate Path Studio',
                  subtitle: 'UFC 4-023-03 column loss & catenary bridging',
                  category: 'ANALYSIS',
                  codeRef: 'UFC 4-023-03',
                  infoDescription: 'Evaluates notional column removal under Omega_LD = 2.0.',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  shortcut: 'ALP',
                  onTrigger: () => triggered = true,
                ),
                CommandPaletteAction(
                  title: 'Concrete Studio (ACI 318-19)',
                  subtitle: 'Biaxial P-M & crack width serviceability',
                  category: 'ANALYSIS',
                  codeRef: 'ACI 318-19',
                  infoDescription: 'Checks Whitney stress block and Gergely-Lutz crack width.',
                  icon: Icons.view_in_ar_rounded,
                  color: Colors.cyanAccent,
                  onTrigger: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Progressive Collapse'), findsOneWidget);
      expect(find.textContaining('Concrete Studio'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'UFC 4-023-03');
      await tester.pumpAndSettle();

      expect(find.textContaining('Progressive Collapse'), findsOneWidget);
      expect(find.textContaining('Concrete Studio'), findsNothing);

      await tester.tap(find.textContaining('Progressive Collapse'));
      await tester.pumpAndSettle();
      expect(triggered, isTrue);
    });

    testWidgets('ProgressiveCollapseDialog renders vulnerability ranking & catenary diagram', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = BenchmarkPresets.multiStorySwayFrame();
      bool committed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveCollapseDialog(
              model: model,
              onCommitDamagedModel: (_) => committed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('PROGRESSIVE COLLAPSE & ALTERNATE LOAD PATH STUDIO'), findsOneWidget);
      expect(find.textContaining('COLUMN REMOVAL VULNERABILITY RANKING'), findsOneWidget);
      expect(find.byType(InfoTooltip), findsWidgets);

      final simulateBtn = find.textContaining('SIMULATE');
      expect(simulateBtn, findsOneWidget);
      await tester.tap(simulateBtn);
      await tester.pumpAndSettle();
      expect(committed, isTrue);
    });
  });
}

