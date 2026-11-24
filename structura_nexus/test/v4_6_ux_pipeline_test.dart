// ============================================================================
// Structura Nexus v4.6 — Engineering-First 5-Stage Pipeline, Workflow Guide Bar,
// Capabilities Overview Dialog & Structured InfoTooltip Verification Suite
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/main.dart';
import 'package:structura_nexus/data/benchmark_presets.dart';
import 'package:structura_nexus/widgets/workflow_guide_bar.dart';
import 'package:structura_nexus/widgets/capabilities_overview_dialog.dart';
import 'package:structura_nexus/widgets/info_tooltip.dart';
import 'package:structura_nexus/widgets/floating_workstation_header.dart';
import 'package:structura_nexus/widgets/floating_telemetry_dock.dart';
import 'package:structura_nexus/widgets/floating_inspector_panel.dart';
import 'package:structura_nexus/widgets/slideable_workspace_menu.dart';

void main() {
  group('Structura Nexus v4.6 Engineering-First UX Pipeline Tests', () {
    testWidgets(
      '1. Top Header displays 5-Stage Engineering Pipeline & opens stage modal with 1-line subtitles',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const StructuraNexusApp());
        await tester.pumpAndSettle();

        // Verify all 5 sequential engineering pipeline stages are visible in the header
        expect(find.text('1. GEOMETRY'), findsOneWidget);
        expect(find.text('2. LOADS & SUPPORTS'), findsOneWidget);
        expect(find.text('3. ANALYSIS'), findsOneWidget);
        expect(find.text('4. DESIGN & OPTIMIZE'), findsOneWidget);
        expect(find.text('5. REPORTS & BIM'), findsOneWidget);
        expect(find.text('WHAT CAN I BUILD?'), findsWidgets);

        // Tap Stage 1: GEOMETRY and verify modal rows show Title + 1-Line Subtitle + InfoTooltip
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
      '2. WorkflowGuideBar renders 4-step checklist with live completion states & Guide Me action',
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

        // Tap Step 3 chip
        await tester.tap(find.text('Step 3: Solve & Code Check'));
        await tester.pumpAndSettle();
        expect(selectedStep, equals(3));

        // Tap primary action button for Step 3
        await tester.tap(find.text('Run 12-DOF FEA & Auto-Size'));
        await tester.pumpAndSettle();
        expect(solveCalled, isTrue);
      },
    );

    testWidgets(
      '3. CapabilitiesOverviewDialog displays all 6 core civil/structural workflows & Try Example triggers',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool triedSteelFrame = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CapabilitiesOverviewDialog(
                onTrySteelFrameDesign: () => triedSteelFrame = true,
                onTryConcreteAndFooting: () {},
                onTrySeismicAndCollapse: () {},
                onTryBridgeMovingLoads: () {},
                onTryAiOptimization: () {},
                onTryPeAndBimDeliverables: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('CAPABILITIES & WORKFLOWS — WHAT CAN YOU BUILD IN STRUCTURA NEXUS?'),
          findsOneWidget,
        );
        expect(find.text('01. Steel Frame & High-Rise Design'), findsOneWidget);
        expect(find.text('02. Concrete Column, Crack & Footing Design'), findsOneWidget);
        expect(find.text('03. Seismic Time-History & Progressive Collapse'), findsOneWidget);
        expect(find.text('04. Bridge Moving Loads & 3D Connections'), findsOneWidget);
        expect(find.text('05. AI Tonnage & 3D Topology Optimization'), findsOneWidget);
        expect(find.text('06. Stamped PE Packets & OpenBIM Deliverables'), findsOneWidget);

        // Click "Try Example: 10-Story Tower"
        await tester.tap(find.text('Try Example: 10-Story Tower'));
        await tester.pumpAndSettle();
        expect(triedSteelFrame, isTrue);
      },
    );

    testWidgets(
      '4. Structured InfoTooltip supports title, description, and standardOrRange with zero delay',
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
      '5. Zero overlap between Header, WorkflowGuideBar, Left Toolbox, Right Inspector & Bottom Dock on 1920x1080 and 1280x800',
      (WidgetTester tester) async {
        for (final size in [const Size(1920, 1080), const Size(1280, 800)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(const StructuraNexusApp());
          await tester.pumpAndSettle();

          final headerRect = tester.getRect(find.byType(FloatingWorkstationHeader));
          final guideBarRect = tester.getRect(find.byType(WorkflowGuideBar));
          final leftMenuRect = tester.getRect(find.byType(SlideableWorkspaceMenu));
          final rightInspectorRect = tester.getRect(find.byType(FloatingInspectorPanel));
          final bottomDockRect = tester.getRect(find.byType(FloatingTelemetryDock));

          // WorkflowGuideBar sits strictly below the top header
          expect(guideBarRect.top, greaterThanOrEqualTo(headerRect.bottom - 4.0));
          // WorkflowGuideBar sits strictly between the left toolbox and right inspector
          expect(guideBarRect.left, greaterThanOrEqualTo(leftMenuRect.right));
          expect(guideBarRect.right, lessThanOrEqualTo(rightInspectorRect.left));
          // WorkflowGuideBar sits strictly above the bottom telemetry dock
          expect(guideBarRect.bottom, lessThan(bottomDockRect.top));
        }

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      },
    );
  });
}
