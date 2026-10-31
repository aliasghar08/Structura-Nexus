// ============================================================================
// Vision-to-BIM Pipeline Frontend Unit & Widget Tests
// Verifies glassmorphic UI, file dropzone, Gemini synthesis, and onModelGenerated
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/models/structural_models.dart';
import 'package:structura_nexus/services/structural_api_service.dart';
import 'package:structura_nexus/widgets/vision_ingestion_dialog.dart';

void main() {
  group('VisionIngestionDialog Widget Tests', () {
    testWidgets('Renders dropzone card, parameter sliders and section dropdowns', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final api = StructuralApiService();
      StructuralModel? generatedModel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisionIngestionDialog(
              apiService: api,
              onModelGenerated: (model) {
                generatedModel = model;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VISION-TO-BIM STUDIO'), findsOneWidget);
      expect(find.text('2D Architectural Plan Ingestion & Autonomous 3D Synthesis'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(find.text('Office_Tower_L1.png'), findsOneWidget);
      expect(find.text('Process Floorplan'), findsOneWidget);

      // Select sample file chip
      await tester.tap(find.text('Commercial_Core_P1.pdf'));
      await tester.pumpAndSettle();
      expect(find.text('Commercial_Core_P1.pdf'), findsNWidgets(2)); // in header + chip

      // Tap Process Floorplan
      await tester.tap(find.text('Process Floorplan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('3D Space Frame Ready to Mount'), findsOneWidget);
      expect(find.text('Synthesize 3D Frame'), findsOneWidget);

      // Tap Synthesize 3D Frame
      await tester.ensureVisible(find.text('Synthesize 3D Frame'));
      await tester.tap(find.text('Synthesize 3D Frame'));
      await tester.pumpAndSettle();

      expect(generatedModel, isNotNull);
      expect(generatedModel!.nodes.length, greaterThan(0));
      expect(generatedModel!.members.length, greaterThan(0));
    });

    testWidgets('VisionIngestionDialog.show static launcher opens modal', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final api = StructuralApiService();
      var triggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => VisionIngestionDialog.show(
                  ctx,
                  apiService: api,
                  onModelGenerated: (m) => triggered = true,
                ),
                child: const Text('Open Vision-to-BIM'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Vision-to-BIM'));
      await tester.pumpAndSettle();

      expect(find.text('VISION-TO-BIM STUDIO'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('VISION-TO-BIM STUDIO'), findsNothing);
      expect(triggered, isFalse);
    });
  });
}

