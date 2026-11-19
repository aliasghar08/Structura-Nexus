// ============================================================================
// Structura Nexus v4.5 Frontier Verification Suite
// Covers:
// 1. ProgressiveCollapseDialog Auto-Retrofit & UFC 4-023-03 §3-1 Catenary Tie Sizing
// 2. ConnectionDetailDialog AISC 360-16 Ch. J Limit States & 3D Assembly Toggle
// 3. BridgeMovingLoadDock AASHTO LRFD HL-93 40-Step Envelope Scrubber
// 4. CommandPaletteDialog v4.5 Tool Entries
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/data/benchmark_presets.dart';
import 'package:structura_nexus/services/bridge_moving_load_solver.dart';
import 'package:structura_nexus/services/connection_detailer_service.dart';
import 'package:structura_nexus/widgets/bridge_moving_load_dock.dart';
import 'package:structura_nexus/widgets/command_palette_dialog.dart';
import 'package:structura_nexus/widgets/connection_detail_dialog.dart';
import 'package:structura_nexus/widgets/progressive_collapse_dialog.dart';

void main() {
  group('Structura Nexus v4.5 Frontier Suite', () {
    testWidgets('Track 1: ProgressiveCollapseDialog runs auto-retrofit & sizes UFC 4-023-03 catenary ties', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = BenchmarkPresets.multiStorySwayFrame();
      bool retrofitCommitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveCollapseDialog(
              model: model,
              onApplyRetrofitModel: (retrofitted) {
                retrofitCommitted = true;
                expect(retrofitted.members.length, greaterThanOrEqualTo(model.members.length));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final autoRetrofitBtn = find.text('AUTO-RETROFIT & SIZE CATENARY TIES');
      expect(autoRetrofitBtn, findsOneWidget);
      await tester.ensureVisible(autoRetrofitBtn);
      await tester.tap(autoRetrofitBtn);
      await tester.pumpAndSettle();

      // Verify before-vs-after banner & tie capacity readout
      expect(find.textContaining('UFC 4-023-03 RETROFIT & CATENARY TIE SYNTHESIS COMPLETE'), findsOneWidget);
      expect(find.textContaining('Required Catenary Tie T_req:'), findsOneWidget);

      final applyBtn = find.text('APPLY RETROFIT TO 3D FRAME');
      expect(applyBtn, findsOneWidget);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();
      expect(retrofitCommitted, isTrue);
    });

    testWidgets('Track 2: ConnectionDetailDialog evaluates AISC 360-16 Ch. J limit states & toggles 3D viewport assembly', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Verify deterministic service calculations
      final shearRes = ConnectionDetailerService.evaluateConnection(
        connectionType: 'SHEAR_TAB',
        shearVuKn: 210.0,
        boltGrade: 'A325',
        boltDiameterMm: 22.225,
        numBolts: 4,
      );
      expect(shearRes.limitStates.length, equals(5));
      expect(shearRes.overallStatus, equals('PASS'));

      final gussetRes = ConnectionDetailerService.evaluateConnection(
        connectionType: 'GUSSET_PLATE',
        axialPuKn: 550.0,
        numBolts: 6,
      );
      expect(gussetRes.whitmoreWidthMm, isNotNull);
      expect(gussetRes.whitmoreWidthMm!, closeTo(316.0, 1.0));

      final model = BenchmarkPresets.multiStorySwayFrame();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionDetailDialog(
              model: model,
              initialJointId: 'N1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('AISC 360-16 CHAPTER J 3D CONNECTION & BASEPLATE SYNTHESIZER'), findsOneWidget);
      expect(find.text('Bolt Single-Shear Capacity'), findsOneWidget);
      expect(find.text('Bolt Bearing & Tear-Out'), findsOneWidget);

      // Toggle 3D Connection in Viewport
      final render3dBtn = find.text('RENDER 3D CONNECTION IN VIEWPORT');
      expect(render3dBtn, findsOneWidget);
      await tester.tap(render3dBtn);
      await tester.pumpAndSettle();

      expect(find.text('3D CONNECTION ACTIVE IN VIEWPORT (CLICK TO CLEAR)'), findsOneWidget);
    });

    testWidgets('Track 3: BridgeMovingLoadDock scrubs 40-step AASHTO HL-93 envelope & influence lines', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final truss = BenchmarkPresets.warrenTruss();
      MovingLoadStepState? lastScrubbedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BridgeMovingLoadDock(
              model: truss,
              onStepScrubbed: (state) => lastScrubbedState = state,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('AASHTO LRFD HL-93 MOVING-LOAD BRIDGE ENVELOPE SCRUBBER'), findsOneWidget);
      expect(find.textContaining('GOVERNING HL-93 MEMBER FORCE ENVELOPES'), findsOneWidget);
      expect(lastScrubbedState, isNotNull);

      // Drag slider to scrub truck position
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      await tester.drag(slider, const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(lastScrubbedState!.leadAxleXM, greaterThan(0.0));
    });

    testWidgets('CommandPaletteDialog includes all v4.5 tools', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPaletteDialog(
              actions: [
                CommandPaletteAction(
                  title: 'Progressive Collapse & Catenary Tie Retrofit Studio',
                  subtitle: 'UFC 4-023-03 §3-1 tie sizing & double-span retrofit',
                  category: 'ANALYSIS',
                  codeRef: 'UFC 4-023-03',
                  infoDescription: 'Auto-retrofits catenary ties.',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  onTrigger: () {},
                ),
                CommandPaletteAction(
                  title: 'AISC 360-16 Chapter J 3D Connection & Baseplate Synthesizer',
                  subtitle: 'Shear tabs, moment end-plates, Whitmore gussets & baseplates',
                  category: 'ANALYSIS',
                  codeRef: 'AISC 360-16 Ch. J',
                  infoDescription: '3D hex bolt and plate synthesizer.',
                  icon: Icons.hardware_rounded,
                  color: Colors.cyanAccent,
                  onTrigger: () {},
                ),
                CommandPaletteAction(
                  title: 'AASHTO LRFD HL-93 Moving-Load Bridge Envelope Scrubber',
                  subtitle: '40-step axle train & influence lines',
                  category: 'ANALYSIS',
                  codeRef: 'AASHTO LRFD §3.6.1.2',
                  infoDescription: 'HL-93 moving load scrubber.',
                  icon: Icons.local_shipping_rounded,
                  color: Colors.lightBlueAccent,
                  onTrigger: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Progressive Collapse & Catenary Tie Retrofit Studio'), findsOneWidget);
      expect(find.textContaining('AISC 360-16 Chapter J 3D Connection & Baseplate Synthesizer'), findsOneWidget);
      expect(find.textContaining('AASHTO LRFD HL-93 Moving-Load Bridge Envelope Scrubber'), findsOneWidget);
    });
  });
}
