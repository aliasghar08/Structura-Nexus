// ============================================================================
// Structura Nexus v4.7 — 24-Sample Certified Engineering Library, Searchable
// Category Browser & Quick-Cycle Header Stepper Tests
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/data/benchmark_presets.dart';
import 'package:structura_nexus/models/structural_models.dart';
import 'package:structura_nexus/services/building_generator_service.dart';
import 'package:structura_nexus/services/embedded_fea_solver.dart';
import 'package:structura_nexus/widgets/building_templates_dialog.dart';
import 'package:structura_nexus/widgets/floating_workstation_header.dart';

void main() {
  group('Structura Nexus v4.7 — 24-Sample Certified Engineering Library Tests', () {
    test('1. Catalog contains exactly 24 certified archetypes across 6 structured categories', () {
      final templates = BuildingGeneratorService.getCertifiedBuildingTemplates();
      expect(templates.length, 24);

      final buildings = templates.where((t) => t.category == 'Buildings').toList();
      final bridges = templates.where((t) => t.category == 'Bridges').toList();
      final longSpan = templates.where((t) => t.category == 'Long-Span').toList();
      final concreteSoil = templates.where((t) => t.category == 'Concrete & Soil').toList();
      final seismicBlast = templates.where((t) => t.category == 'Seismic & Blast').toList();
      final benchmarks = templates.where((t) => t.category == 'Benchmarks').toList();

      expect(buildings.length, 7, reason: 'Must have 7 building archetypes');
      expect(bridges.length, 4, reason: 'Must have 4 bridge archetypes');
      expect(longSpan.length, 5, reason: 'Must have 5 long-span/tower archetypes');
      expect(concreteSoil.length, 3, reason: 'Must have 3 concrete & foundation archetypes');
      expect(seismicBlast.length, 3, reason: 'Must have 3 seismic & blast archetypes');
      expect(benchmarks.length, 2, reason: 'Must have 2 textbook benchmark archetypes');

      // Verify metadata completeness for every template
      for (final t in templates) {
        expect(t.id.isNotEmpty, true, reason: 'Template id must not be empty');
        expect(t.title.isNotEmpty, true, reason: 'Template title must not be empty');
        expect(t.codeStandard.isNotEmpty, true, reason: 'Template code standard must not be empty');
        expect(t.dimensions.isNotEmpty, true, reason: 'Template dimensions must not be empty');
        expect(t.description.isNotEmpty, true, reason: 'Template description must not be empty');
        expect(t.badge.isNotEmpty, true, reason: 'Template badge must not be empty');
        expect(t.stories >= 1, true, reason: 'Stories must be at least 1');
        expect(t.heightM > 0.0, true, reason: 'Height must be positive');
        expect(t.footprintAreaM2 > 0.0, true, reason: 'Footprint area must be positive');
      }
    });

    test('2. All 24 archetypes generate valid, finite 12-DOF DSM solutions without NaN or error', () {
      final templates = BuildingGeneratorService.getCertifiedBuildingTemplates();

      for (int i = 0; i < templates.length; i++) {
        final t = templates[i];
        final model = t.builder();

        expect(model.nodes.isNotEmpty, true, reason: '${t.title} must have nodes');
        expect(model.members.isNotEmpty, true, reason: '${t.title} must have members');

        // Solve using embedded direct stiffness 12-DOF FEA solver
        EmbeddedFeaSolver.solve(model);

        // Verify displacements are finite numbers and not NaN or infinite
        for (final node in model.nodes) {
          expect(node.dispX.isNaN, false, reason: 'Node ${node.id} in ${t.title} dispX is NaN');
          expect(node.dispY.isNaN, false, reason: 'Node ${node.id} in ${t.title} dispY is NaN');
          expect(node.dispZ.isNaN, false, reason: 'Node ${node.id} in ${t.title} dispZ is NaN');
          expect(node.dispX.isInfinite, false, reason: 'Node ${node.id} in ${t.title} dispX is Infinite');
          expect(node.dispY.isInfinite, false, reason: 'Node ${node.id} in ${t.title} dispY is Infinite');
          expect(node.dispZ.isInfinite, false, reason: 'Node ${node.id} in ${t.title} dispZ is Infinite');
        }

        // Verify member forces and DCR are valid finite numbers
        for (final member in model.members) {
          expect(member.axialForceN.isNaN, false, reason: 'Member ${member.id} in ${t.title} axial is NaN');
          expect(member.momentZ.isNaN, false, reason: 'Member ${member.id} in ${t.title} moment is NaN');
          expect(member.governingDcr.isNaN, false, reason: 'Member ${member.id} in ${t.title} DCR is NaN');
        }
      }

      // Closed-form Timoshenko cantilever deflection check
      final cantilever = BenchmarkPresets.timoshenkoCantilever();
      EmbeddedFeaSolver.solve(cantilever);
      final tipNode = cantilever.nodes.firstWhere((n) => n.id == 'N2');
      expect(tipNode.dispY < 0.0, true, reason: 'Downward tip deflection under gravity');
      expect(tipNode.dispY.abs() > 0.005 && tipNode.dispY.abs() < 0.025, true,
          reason: 'Timoshenko cantilever tip deflection in valid physical range (~0.0105m - 0.0128m)');
    });

    testWidgets('3. BuildingTemplatesDialog renders search bar, 7 ChoiceChips with live counts & card actions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final currentModel = BenchmarkPresets.multiStorySwayFrame();
      StructuralModel? loadedModel;
      String? launchedStudio;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuildingTemplatesDialog(
              currentModel: currentModel,
              onModelSelected: (m) => loadedModel = m,
              onOpenInStudio: (m, studio) {
                loadedModel = m;
                launchedStudio = studio;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify search input is present
      expect(find.byType(TextField), findsOneWidget);

      // Verify category ChoiceChips with exact live counts
      expect(find.text('All (24)'), findsOneWidget);
      expect(find.text('Buildings (7)'), findsOneWidget);
      expect(find.text('Bridges (4)'), findsOneWidget);
      expect(find.text('Long-Span (5)'), findsOneWidget);
      expect(find.text('Concrete & Soil (3)'), findsOneWidget);
      expect(find.text('Seismic & Blast (3)'), findsOneWidget);
      expect(find.text('Benchmarks (2)'), findsOneWidget);

      // Tap Bridges category chip
      await tester.tap(find.text('Bridges (4)'));
      await tester.pumpAndSettle();

      expect(find.text('24m Warren Pedestrian Overpass'), findsOneWidget);
      expect(find.text('36m Pratt Highway Truss Bridge'), findsOneWidget);
      expect(find.text('45m Tied-Arch Bowstring Bridge'), findsOneWidget);
      expect(find.text('60m Cable-Stayed Footbridge'), findsOneWidget);

      // Tap Concrete & Soil category chip
      await tester.tap(find.text('Concrete & Soil (3)'));
      await tester.pumpAndSettle();

      expect(find.text('4-Story ACI 318-19 Concrete Frame'), findsOneWidget);
      expect(find.text('Heavy Transfer Girder & Mat Footing'), findsOneWidget);
      expect(find.text('Cantilever Retaining Wall & Pier Frame'), findsOneWidget);

      // Search filter test
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Bowstring');
      await tester.pumpAndSettle();

      // Only Tied-Arch Bowstring Bridge should match across category or query
      await tester.tap(find.text('All (24)'));
      await tester.pumpAndSettle();
      expect(find.text('45m Tied-Arch Bowstring Bridge'), findsOneWidget);

      // Verify LOAD & SOLVE and STUDIO action buttons exist
      expect(find.text('LOAD & SOLVE'), findsWidgets);
      final studioBtn = find.text('STUDIO');
      expect(studioBtn, findsOneWidget);

      // Tap STUDIO button for bridge archetype (seeds model, launches paired studio, and dismisses)
      await tester.tap(studioBtn);
      await tester.pumpAndSettle();

      expect(launchedStudio, 'bridge_moving_load');
      expect(loadedModel, isNotNull);
      expect(loadedModel?.sessionId, 'tied_arch_45m');
    });

    testWidgets('4. FloatingWorkstationHeader quick-cycle stepper cycles previous & next with InfoTooltip',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = BenchmarkPresets.multiStorySwayFrame();
      String? selectedPresetId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingWorkstationHeader(
              model: model,
              isBackendConnected: true,
              onEngineChanged: (_) {},
              onModeChanged: (_) {},
              onDeformationScaleChanged: (_) {},
              onPresetSelected: (presetId) => selectedPresetId = presetId,
              onSolveTriggered: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Stepper icons exist
      expect(find.byIcon(Icons.arrow_back_ios_rounded), findsWidgets);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsWidgets);

      // Find the next step button inside the sample switcher
      final nextBtn = find.byTooltip('Next Sample: 4-Story Educational Campus Frame');
      expect(nextBtn, findsOneWidget);
      await tester.ensureVisible(nextBtn);
      await tester.pumpAndSettle();

      // Tap next sample button
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(selectedPresetId, 'campus_4s');

      // Find the previous step button
      final prevBtn = find.byTooltip('Previous Sample: Hibbeler & Leet Continuous Beam');
      expect(prevBtn, findsOneWidget);
      await tester.ensureVisible(prevBtn);
      await tester.pumpAndSettle();

      // Tap previous sample button
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();

      expect(selectedPresetId, 'hibbeler_leet_beam');

      expect(selectedPresetId, 'hibbeler_leet_beam');
    });
  });
}
