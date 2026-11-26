// ============================================================================
// Structura Nexus v4.6 — Engineering-First 5-Stage Pipeline, Workflow Guide Bar,
// Capabilities Overview 6x Try-Example Seeding, NextStepPromptBanner & Tablet Audit
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/main.dart';
import 'package:structura_nexus/data/benchmark_presets.dart';
import 'package:structura_nexus/widgets/workflow_guide_bar.dart';
import 'package:structura_nexus/widgets/capabilities_overview_dialog.dart';
import 'package:structura_nexus/widgets/next_step_prompt_banner.dart';
import 'package:structura_nexus/widgets/info_tooltip.dart';
import 'package:structura_nexus/widgets/floating_workstation_header.dart';
import 'package:structura_nexus/widgets/floating_telemetry_dock.dart';
import 'package:structura_nexus/widgets/floating_inspector_panel.dart';
import 'package:structura_nexus/widgets/slideable_workspace_menu.dart';
import 'package:structura_nexus/widgets/concrete_pm_dialog.dart';
import 'package:structura_nexus/widgets/time_history_player.dart';
import 'package:structura_nexus/widgets/bridge_moving_load_dock.dart';
import 'package:structura_nexus/widgets/pareto_frontier_dock.dart';
import 'package:structura_nexus/widgets/pe_packet_dialog.dart';
import 'package:structura_nexus/services/workspace_storage.dart';

void main() {
  setUp(() {
    WorkspacePreferences.setBool('hide_welcome_quickstart', true);
  });

  group('Structura Nexus v4.6 Engineering-First UX Pipeline & Polish Tests', () {
    testWidgets(
      '1. Top Header displays 5-Stage Engineering Pipeline & opens stage modal with 1-line subtitles',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const StructuraNexusApp());
        await tester.pumpAndSettle();

        expect(find.text('1. GEOMETRY'), findsOneWidget);
        expect(find.text('2. LOADS & SUPPORTS'), findsOneWidget);
        expect(find.text('3. ANALYSIS'), findsOneWidget);
        expect(find.text('4. DESIGN & OPTIMIZE'), findsOneWidget);
        expect(find.text('5. REPORTS & BIM'), findsOneWidget);
        expect(find.text('WHAT CAN I BUILD?'), findsWidgets);

        await tester.ensureVisible(find.text('1. GEOMETRY'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('1. GEOMETRY'));
        await tester.pumpAndSettle();

        expect(find.text('STAGE 1: GEOMETRY & 3D FRAMING'), findsOneWidget);
        expect(find.text('12 Certified Building & Bridge Templates'), findsOneWidget);
        expect(
          find.text('Load pre-engineered high-rise towers, hospitals, bridges, and warehouses'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2. WorkflowGuideBar renders 4-step checklist on desktop and collapses to single-line pill on 768x1024 tablet',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final model = BenchmarkPresets.multiStorySwayFrame();
        int selectedStep = 1;
        bool solveCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WorkflowGuideBar(
                model: model,
                activeStep: selectedStep,
                onStepSelected: (step) => selectedStep = step,
                onOpenTemplates: () {},
                onApplyLoadsAndSupports: () {},
                onRunFeaAndOptimize: () => solveCalled = true,
                onExportPePacket: () {},
                onOpenCapabilitiesOverview: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Step 1: Model Frame'), findsOneWidget);
        expect(find.text('Step 2: Restraints & Loads'), findsOneWidget);
        expect(find.text('Step 3: Solve & Code Check'), findsOneWidget);
        expect(find.text('Step 4: Export & Stamp'), findsOneWidget);
        expect(find.text('GUIDE ME'), findsOneWidget);

        await tester.tap(find.text('Step 3: Solve & Code Check'));
        await tester.pumpAndSettle();
        expect(selectedStep, equals(3));

        await tester.tap(find.text('Run 12-DOF FEA & Auto-Size'));
        await tester.pumpAndSettle();
        expect(solveCalled, isTrue);

        // Resize to 768x1024 tablet portrait and verify compact single-line pill
        tester.view.physicalSize = const Size(768, 1024);
        await tester.pumpAndSettle();

        expect(find.textContaining('Step 3/4: Solve & Code Check • Guide Me'), findsOneWidget);

        // Tap compact pill to expand on tablet
        await tester.tap(find.textContaining('Step 3/4: Solve & Code Check • Guide Me'));
        await tester.pumpAndSettle();
        expect(find.text('Step 1: Model Frame'), findsOneWidget);
      },
    );

    testWidgets(
      '3. End-to-End 1-Click "Try Example" Preset Seeding loads distinct models & opens studios for all 6 workflows',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const StructuraNexusApp());
        await tester.pumpAndSettle();

        Future<void> openCapabilities() async {
          await tester.tap(find.text('WHAT CAN I BUILD?').first);
          await tester.pumpAndSettle();
          expect(find.byType(CapabilitiesOverviewDialog), findsOneWidget);
        }

        // Workflow 1: Multi-Story Steel Frame Design (10-Story Office Tower: 220 joints, 590 members)
        await openCapabilities();
        await tester.tap(find.text('Try Example: 10-Story Tower'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.textContaining('Model loaded (220 joints, 590 members)'), findsOneWidget);
        expect(find.byType(NextStepPromptBanner), findsOneWidget);

        // Workflow 2: Reinforced Concrete & Footing Design (4-Story Concrete Moment Frame + ConcretePmDialog)
        await openCapabilities();
        await tester.tap(find.text('Try Example: Concrete & Footing Studio'));
        await tester.pumpAndSettle();
        expect(find.byType(ConcretePmDialog), findsOneWidget);
        // Close ConcretePmDialog
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pumpAndSettle();

        // Workflow 3: Seismic Time-History & Progressive Collapse (8-Story Hospital Complex + TimeHistoryPlayer)
        await openCapabilities();
        await tester.tap(find.text('Try Example: Progressive Collapse Retrofit'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(TimeHistoryPlayer), findsOneWidget);

        // Workflow 4: Bridge Moving-Load Envelope (36m Pratt Highway Truss Bridge + BridgeMovingLoadDock)
        await openCapabilities();
        await tester.tap(find.text('Try Example: HL-93 Bridge Moving Load'));
        await tester.pumpAndSettle();
        expect(find.byType(BridgeMovingLoadDock), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(BridgeMovingLoadDock),
            matching: find.byIcon(Icons.close_rounded),
          ),
        );
        await tester.pumpAndSettle();

        // Workflow 5: AI Tonnage & Embodied Carbon Optimization (Industrial Warehouse + ParetoFrontierDock)
        await openCapabilities();
        await tester.ensureVisible(find.text('Try Example: AI Auto-Sizer & Swarm'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Try Example: AI Auto-Sizer & Swarm'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(ParetoFrontierDock), findsOneWidget);
        Navigator.of(tester.element(find.byType(ParetoFrontierDock))).pop();
        await tester.pumpAndSettle();

        // Workflow 6: PE Calculation Packets & openBIM Exchange (4-Story Campus Frame + PePacketDialog)
        await openCapabilities();
        await tester.ensureVisible(find.text('Try Example: Stamped PE Calculation Packet'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Try Example: Stamped PE Calculation Packet'));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(PePacketDialog), findsOneWidget);
        Navigator.of(tester.element(find.byType(PePacketDialog))).pop();
        await tester.pumpAndSettle();

        // Advance past the 6-second auto-dismiss timer so no pending timers remain
        await tester.pump(const Duration(seconds: 7));
      },
    );

    testWidgets(
      '4. Contextual Post-Action NextStepPromptBanner renders after Extrude Story and FEA Solve',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const StructuraNexusApp());
        await tester.pumpAndSettle();

        // Trigger Extrude Story (+Level) in SlideableWorkspaceMenu
        await tester.tap(find.text('Extrude Story (+Level)'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('Geometry updated with tributary loads. Next: Check AISC 360-16 DCR & P-Δ Stability →'),
          findsOneWidget,
        );
        expect(find.text('INSPECT DCR'), findsOneWidget);

        // Tap INSPECT DCR on NextStepPromptBanner -> triggers solve and advances prompt to EXPORT PE PACKET
        await tester.tap(find.text('INSPECT DCR'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('Equilibrium verified (0.0000% residual). Next: Generate Stamped PE Packet →'),
          findsOneWidget,
        );
        expect(find.text('EXPORT PE PACKET'), findsOneWidget);

        // Drain 6-second timer
        await tester.pump(const Duration(seconds: 7));
      },
    );

    testWidgets(
      '5. Structured InfoTooltip supports title, description, and standardOrRange with zero delay',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: InfoTooltip(
                  title: 'Demand-Capacity Ratio (DCR)',
                  description: 'Ratio of factored internal force/moment demand to LRFD design capacity.',
                  standardOrRange:
                      'AISC 360-16 Eq. H1-1a | ≤ 0.70: Under-utilized | 0.70–0.95: Optimal | > 1.00: Overstressed (Fail)',
                ),
              ),
            ),
          ),
        );

        final infoTooltip = tester.widget<InfoTooltip>(find.byType(InfoTooltip));
        expect(infoTooltip.title, equals('Demand-Capacity Ratio (DCR)'));
        expect(infoTooltip.effectiveStandardOrRange, contains('0.70–0.95: Optimal'));
        expect(infoTooltip.effectiveDescription, contains('LRFD design capacity'));

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.waitDuration, equals(Duration.zero));
      },
    );

    testWidgets(
      '6. Zero overlap and zero RenderFlex overflow across 1920x1080 (Desktop), 1280x800 (Laptop), 768x1024 & 1024x768 (Tablet)',
      (WidgetTester tester) async {
        for (final size in [
          const Size(1920, 1080),
          const Size(1280, 800),
          const Size(768, 1024),
          const Size(1024, 768),
        ]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(const StructuraNexusApp());
          await tester.pumpAndSettle();

          final headerRect = tester.getRect(find.byType(FloatingWorkstationHeader));
          final guideBarRect = tester.getRect(find.byType(WorkflowGuideBar));
          final leftMenuRect = tester.getRect(find.byType(SlideableWorkspaceMenu));
          final rightInspectorRect = tester.getRect(find.byType(FloatingInspectorPanel));
          final bottomDockRect = tester.getRect(find.byType(FloatingTelemetryDock));

          // WorkflowGuideBar never overlaps the top header
          expect(guideBarRect.top, greaterThanOrEqualTo(headerRect.bottom - 4.0));
          // WorkflowGuideBar never overlaps the bottom telemetry dock
          expect(guideBarRect.bottom, lessThan(bottomDockRect.top));

          if (size.width >= 1100) {
            // On desktop/laptop, WorkflowGuideBar sits horizontally between left menu and right inspector
            expect(guideBarRect.left, greaterThanOrEqualTo(leftMenuRect.right));
            expect(guideBarRect.right, lessThanOrEqualTo(rightInspectorRect.left));
          } else {
            // On 768x1024 tablet, WorkflowGuideBar is a compact single-line pill above both left menu and right inspector
            expect(guideBarRect.bottom, lessThanOrEqualTo(leftMenuRect.top + 4.0));
            expect(guideBarRect.bottom, lessThanOrEqualTo(rightInspectorRect.top + 4.0));
            expect(leftMenuRect.right, lessThanOrEqualTo(rightInspectorRect.left));
          }
        }

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      },
    );
  });
}
