// ============================================================================
// SplashScreen Widget Tests
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/screens/splash_screen.dart';

void main() {
  group('SplashScreen Widget Tests', () {
    testWidgets('Renders connecting status text and progress indicator', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      expect(find.text('Connecting to Structura Nexus...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Renders custom status text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(statusMessage: 'Restoring structural telemetry...'),
        ),
      );

      expect(find.text('Restoring structural telemetry...'), findsOneWidget);
    });
  });
}
