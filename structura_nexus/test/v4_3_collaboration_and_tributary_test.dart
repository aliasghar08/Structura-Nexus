// ============================================================================
// Structura Nexus v4.3: Automated Tributary Propagation, Desktop File Packaging
// and Real-Time Multi-Engineer Cloud Collaboration Test Suite
// Standard Authorities: ASCE 7-16 • AISC 360-16 • ACI 318-19 • IBC 2024
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/models/structural_models.dart';
import 'package:structura_nexus/services/tributary_load_propagator.dart';
import 'package:structura_nexus/services/desktop_file_service.dart';
import 'package:structura_nexus/services/collaboration_service.dart';
import 'package:structura_nexus/widgets/collaboration_review_dialog.dart';

void main() {
  group('Track 1: Automated Tributary Floor & ASCE 7-16 Lateral Load Propagator', () {
    test('Calculates tributary areas and assigns factored gravity floor loads', () {
      // Create a 2-bay x 2-bay floor diaphragm at Y=3.6m
      final nodes = [
        // Ground supports (pinned)
        StructuralNode(id: 'N1', x: 0, y: 0, z: 0, restraint: [1, 1, 1, 0, 0, 0]),
        StructuralNode(id: 'N2', x: 6, y: 0, z: 0, restraint: [1, 1, 1, 0, 0, 0]),
        StructuralNode(id: 'N3', x: 0, y: 0, z: 6, restraint: [1, 1, 1, 0, 0, 0]),
        StructuralNode(id: 'N4', x: 6, y: 0, z: 6, restraint: [1, 1, 1, 0, 0, 0]),

        // Story 1 Floor Diaphragm (Y=3.6m)
        StructuralNode(id: 'N5', x: 0, y: 3.6, z: 0), // Corner node
        StructuralNode(id: 'N6', x: 6, y: 3.6, z: 0), // Corner node
        StructuralNode(id: 'N7', x: 0, y: 3.6, z: 6), // Corner node
        StructuralNode(id: 'N8', x: 6, y: 3.6, z: 6), // Corner node
      ];

      final members = [
        StructuralMember(id: 'C1', iNodeId: 'N1', jNodeId: 'N5', section: 'W14X48'),
        StructuralMember(id: 'C2', iNodeId: 'N2', jNodeId: 'N6', section: 'W14X48'),
        StructuralMember(id: 'C3', iNodeId: 'N3', jNodeId: 'N7', section: 'W14X48'),
        StructuralMember(id: 'C4', iNodeId: 'N4', jNodeId: 'N8', section: 'W14X48'),
        StructuralMember(id: 'B1', iNodeId: 'N5', jNodeId: 'N6', section: 'W18X35'),
        StructuralMember(id: 'B2', iNodeId: 'N7', jNodeId: 'N8', section: 'W18X35'),
        StructuralMember(id: 'B3', iNodeId: 'N5', jNodeId: 'N7', section: 'W18X35'),
        StructuralMember(id: 'B4', iNodeId: 'N6', jNodeId: 'N8', section: 'W18X35'),
      ];

      final model = StructuralModel(sessionId: 'trib_test', nodes: nodes, members: members);

      final summary = TributaryLoadPropagator.propagate(
        model: model,
        deadLoadKpa: 4.8,
        liveLoadKpa: 2.4,
        windSpeedMps: 45.0,
        exposure: 'B',
        applyLateral: true,
      );

      expect(summary.storyCount, equals(1));
      expect(summary.floorElevations, contains(3.6));
      expect(summary.affectedNodesCount, equals(4));
      expect(summary.totalFloorAreaM2, greaterThan(0.0));
      expect(summary.totalFactoredGravityLoadKn, greaterThan(0.0));
      expect(summary.totalWindBaseShearKn, greaterThan(0.0));

      // Verify node loads and tags
      final node5 = model.getNode('N5')!;
      expect(node5.loadSource, equals('TRIBUTARY_AUTO'));
      expect(node5.tributaryAreaM2, isNotNull);
      expect(node5.loads[1], lessThan(0.0)); // Downward gravity load Fy < 0
      expect(node5.loads[0], greaterThanOrEqualTo(0.0)); // Lateral windward shear Fx >= 0
    });
  });

  group('Track 2: Native Desktop Packaging & Deliverable Export', () {
    test('DesktopFileService exports deliverable with author metadata', () async {
      final fileService = DesktopFileService();
      expect(fileService.isDesktopPlatform, isA<bool>());

      final exportResult = await fileService.exportDeliverable(
        fileName: 'Test_Frame_Model',
        content: '{"nodes": [], "members": []}',
        fileType: 'structura.json',
      );

      expect(exportResult, isNotEmpty);
    });
  });

  group('Track 3: Real-Time Multi-Engineer Cloud Collaboration & Revision Diffing', () {
    test('StructuralDiffEngine detects added, modified, and removed members', () {
      final baseline = StructuralModel(
        sessionId: 'base_sess',
        nodes: [
          StructuralNode(id: 'N1', x: 0, y: 0, z: 0),
          StructuralNode(id: 'N2', x: 4, y: 0, z: 0),
          StructuralNode(id: 'N3', x: 8, y: 0, z: 0),
        ],
        members: [
          StructuralMember(id: 'M1', iNodeId: 'N1', jNodeId: 'N2', section: 'W14X48'),
          StructuralMember(id: 'M2', iNodeId: 'N2', jNodeId: 'N3', section: 'W18X35'),
        ],
      );

      final current = StructuralModel(
        sessionId: 'curr_sess',
        nodes: [
          StructuralNode(id: 'N1', x: 0, y: 0, z: 0),
          StructuralNode(id: 'N2', x: 4, y: 0, z: 0),
          StructuralNode(id: 'N4', x: 12, y: 0, z: 0),
        ],
        members: [
          // M1 modified (upsized to W14X90 with releaseEndMz)
          StructuralMember(id: 'M1', iNodeId: 'N1', jNodeId: 'N2', section: 'W14X90', releaseEndMz: true),
          // M2 removed
          // M3 added
          StructuralMember(id: 'M3', iNodeId: 'N2', jNodeId: 'N4', section: 'W24X68'),
        ],
      );

      final diffSummary = StructuralDiffEngine.compare(baseline: baseline, current: current);

      expect(diffSummary.hasChanges, isTrue);
      expect(diffSummary.addedCount, equals(1));
      expect(diffSummary.modifiedCount, equals(1));
      expect(diffSummary.removedCount, equals(1));

      final addedDiff = diffSummary.diffs.firstWhere((d) => d.changeType == DiffChangeType.added);
      expect(addedDiff.memberId, equals('M3'));
      expect(addedDiff.newSection, equals('W24X68'));

      final modDiff = diffSummary.diffs.firstWhere((d) => d.changeType == DiffChangeType.modified);
      expect(modDiff.memberId, equals('M1'));
      expect(modDiff.oldSection, equals('W14X48'));
      expect(modDiff.newSection, equals('W14X90'));
      expect(modDiff.details, contains('Releases modified'));

      final remDiff = diffSummary.diffs.firstWhere((d) => d.changeType == DiffChangeType.removed);
      expect(remDiff.memberId, equals('M2'));
    });

    test('CollaborationService manages comments and generates shareable review link', () async {
      final collabService = CollaborationService();
      final model = StructuralModel(
        sessionId: 'collab_test',
        nodes: [StructuralNode(id: 'N1', x: 0, y: 3.6, z: 0)],
        members: [],
      );

      final sessionId = await collabService.initSession(model, role: 'CO_ENGINEER');
      expect(sessionId, isNotEmpty);
      expect(collabService.canEdit, isTrue);

      final shareLink = collabService.generateShareLink(role: 'VIEWER_COMMENTER');
      expect(shareLink, contains('https://structura-nexus.web.app/?session='));
      expect(shareLink, contains('role=VIEWER_COMMENTER'));

      // Add 3D review comment
      final comment = await collabService.addComment(
        text: 'Check column splice weld at Node N1',
        nodeId: 'N1',
        coords: [0.0, 3.6, 0.0],
      );

      expect(comment.text, equals('Check column splice weld at Node N1'));
      expect(comment.isResolved, isFalse);
      expect(collabService.comments, contains(comment));

      // Resolve comment
      collabService.toggleResolveComment(comment.id);
      expect(collabService.comments.firstWhere((c) => c.id == comment.id).isResolved, isTrue);
    });

    testWidgets('CollaborationReviewDialog renders Share, Revision Diff & 3D Comments tabs', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final model = StructuralModel(
        sessionId: 'dialog_test',
        nodes: [
          StructuralNode(id: 'N1', x: 0, y: 0, z: 0),
          StructuralNode(id: 'N2', x: 6, y: 3.6, z: 0),
        ],
        members: [
          StructuralMember(id: 'M1', iNodeId: 'N1', jNodeId: 'N2', section: 'W14X48'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollaborationReviewDialog(
              model: model,
              onStructureModified: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('REAL-TIME MULTI-ENGINEER COLLABORATION'), findsOneWidget);
      expect(find.text('SHARE & PRESENCE'), findsOneWidget);
      expect(find.textContaining('REVISION DIFF'), findsOneWidget);
      expect(find.textContaining('PINNED 3D COMMENTS'), findsOneWidget);
      expect(find.text('SHAREABLE REVIEW LINK'), findsOneWidget);
      expect(find.text('COPY LINK'), findsOneWidget);

      // Tap Revision Diff tab
      await tester.tap(find.textContaining('REVISION DIFF'));
      await tester.pumpAndSettle();
      expect(find.text('ADDED MEMBERS'), findsOneWidget);
      expect(find.text('MODIFIED SECTIONS'), findsOneWidget);
      expect(find.text('REMOVED ELEMENTS'), findsOneWidget);

      // Tap Pinned 3D Comments tab
      await tester.tap(find.textContaining('PINNED 3D COMMENTS'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Pin @ N1'), findsOneWidget);

      // Enter a new review comment
      await tester.enterText(find.byType(TextField), 'Verified direct stiffness boundary conditions.');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Verified direct stiffness boundary conditions.'), findsOneWidget);
    });
  });
}

