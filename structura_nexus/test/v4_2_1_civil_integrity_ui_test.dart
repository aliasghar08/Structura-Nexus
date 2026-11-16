// ============================================================================
// Structura Nexus v4.2.1: Civil Integrity, End Releases & PE Seal Verifier Tests
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/models/structural_models.dart';
import 'package:structura_nexus/services/embedded_fea_solver.dart';
import 'package:structura_nexus/services/structural_api_service.dart';
import 'package:structura_nexus/widgets/floating_inspector_panel.dart';
import 'package:structura_nexus/widgets/concrete_pm_dialog.dart';
import 'package:structura_nexus/widgets/pe_packet_dialog.dart';

void main() {
  group('Track 1: Member End Releases & ACI 318-19 Cracked Modifiers', () {
    testWidgets('FloatingInspectorPanel toggles member end releases and updates model', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final model = StructuralModel(
        sessionId: 'test_session',
        nodes: [
          StructuralNode(id: 'N1', x: 0, y: 0, z: 0, restraint: [1, 1, 1, 1, 1, 1]),
          StructuralNode(id: 'N2', x: 6, y: 0, z: 0, restraint: [0, 1, 1, 0, 0, 0], loads: [0, -30000, 0, 0, 0, 0]),
        ],
        members: [
          StructuralMember(id: 'M1', iNodeId: 'N1', jNodeId: 'N2', section: 'W14X48', material: 'A992_STEEL'),
        ],
      );

      bool modelChanged = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingInspectorPanel(
              model: model,
              selectedMemberId: 'M1',
              onModelChanged: () {
                modelChanged = true;
                EmbeddedFeaSolver.solve(model);
              },
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify release controls exist
      expect(find.text('MEMBER END RELEASES (PINNED)'), findsOneWidget);
      expect(find.text('Start Mz'), findsOneWidget);
      expect(find.text('End Mz'), findsOneWidget);
      expect(find.text('Torsion (Mx)'), findsOneWidget);

      // Tap End Mz release
      await tester.tap(find.text('End Mz'));
      await tester.pumpAndSettle();

      expect(model.members[0].releaseEndMz, isTrue);
      expect(modelChanged, isTrue);

      // Verify cracked stiffness controls
      expect(find.text('ACI 318-19 CRACKED STIFFNESS (I_eff)'), findsOneWidget);
      expect(find.text('ACI Beam (0.35 Ig)'), findsOneWidget);

      // Tap ACI Beam modifier
      await tester.tap(find.text('ACI Beam (0.35 Ig)'));
      await tester.pumpAndSettle();

      expect(model.members[0].crackedSectionFactor, equals(0.35));
    });

    testWidgets('ConcretePmDialog renders ACI 318-19 §24.3.2 crack serviceability control', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConcretePmDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PROPRIETARY CONCRETE STUDIO'), findsOneWidget);
      expect(find.text('ACI 318-19 §24.3.2 / ACI 224R CRACK CONTROL'), findsOneWidget);
      expect(find.textContaining('Crack Width wk:'), findsOneWidget);
      expect(find.textContaining('Bar Spacing s:'), findsOneWidget);
      expect(find.textContaining('I_eff / I_g:'), findsOneWidget);

      // Toggle exposure condition
      await tester.tap(find.text('WATER RETAINING'));
      await tester.pumpAndSettle();

      expect(find.textContaining('≤ 0.10 mm'), findsOneWidget);
    });
  });

  group('Track 2: Interactive Cryptographic PE Seal Verifier', () {
    testWidgets('PePacketDialog renders Verify PE Seal tab and tests HMAC tamper detection', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final model = StructuralModel(
        sessionId: 'test_pe_session',
        nodes: [
          StructuralNode(id: 'N1', x: 0, y: 0, z: 0, restraint: [1, 1, 1, 1, 1, 1]),
          StructuralNode(id: 'N2', x: 4, y: 0, z: 0),
        ],
        members: [
          StructuralMember(id: 'M1', iNodeId: 'N1', jNodeId: 'N2', section: 'W14X48'),
        ],
      );

      final apiService = StructuralApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PePacketDialog(
              model: model,
              apiService: apiService,
              onStructureModified: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the 4 tabs are present
      expect(find.text('CERTIFIED PE PACKET'), findsOneWidget);
      expect(find.text('LATEX SOURCE (.tex)'), findsOneWidget);
      expect(find.text('BIM: ETABS .s2k & IFC 4.3'), findsOneWidget);
      expect(find.text('VERIFY PE SEAL'), findsOneWidget);

      // Switch to Verify PE Seal tab
      await tester.tap(find.text('VERIFY PE SEAL'));
      await tester.pumpAndSettle();

      expect(find.text('CRYPTOGRAPHIC PE CALCULATION SEAL AUDITOR'), findsOneWidget);
      expect(find.text('LOAD CURRENT PACKET'), findsOneWidget);
      expect(find.text('SIMULATE TAMPERED PACKET'), findsOneWidget);

      // Tap Simulate Tampered Packet
      await tester.tap(find.text('SIMULATE TAMPERED PACKET'));
      await tester.pumpAndSettle();

      expect(find.text('SECURITY ALERT: TAMPERED OR INVALID SEAL'), findsOneWidget);
    });
  });
}
