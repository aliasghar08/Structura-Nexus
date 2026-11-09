// ============================================================================
// Comprehensive Side Menu Options Verification Test
// Exercises every single tool option in SlideableWorkspaceMenu inside WorkstationScreen
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/screens/workstation_screen.dart';
import 'package:structura_nexus/screens/auth_screen.dart';

void main() {
  group('Full Side Menu Options In-Depth Verification', () {
    testWidgets('Every side menu option executes cleanly without crashing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: WorkstationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure Workstation & Workspace Tools menu are rendered
      expect(find.text('WORKSPACE TOOLS'), findsOneWidget);

      // Category tab: DRAW & MODEL
      await tester.tap(find.text('DRAW & MODEL'));
      await tester.pumpAndSettle();

      // 1. Building Templates
      expect(find.text('Building Templates'), findsOneWidget);
      await tester.tap(find.text('Building Templates'));
      await tester.pumpAndSettle();
      expect(find.text('BUILDING TEMPLATES & WORKSPACE IMPORTER'), findsOneWidget);
      Navigator.of(tester.element(find.text('BUILDING TEMPLATES & WORKSPACE IMPORTER'))).pop();
      await tester.pumpAndSettle();

      // 2. Mac-Trained AI Suite
      expect(find.text('Mac-Trained AI Suite'), findsOneWidget);
      await tester.tap(find.text('Mac-Trained AI Suite'));
      await tester.pumpAndSettle();
      expect(find.text('MAC-TRAINED NEURAL AI ENGINE & SURROGATE INSPECTOR'), findsOneWidget);
      Navigator.of(tester.element(find.text('MAC-TRAINED NEURAL AI ENGINE & SURROGATE INSPECTOR'))).pop();
      await tester.pumpAndSettle();

      // Scroll tool list down to reveal remaining modeling tools
      await tester.drag(find.byType(ListView).first, const Offset(0, -200));
      await tester.pumpAndSettle();

      // 3. Extrude Story (+Level)
      expect(find.text('Extrude Story (+Level)'), findsOneWidget);
      await tester.tap(find.text('Extrude Story (+Level)'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);

      // 4. Extend Bay (+X Span)
      expect(find.text('Extend Bay (+X Span)'), findsOneWidget);
      await tester.tap(find.text('Extend Bay (+X Span)'));
      await tester.pumpAndSettle();

      // 5. Extend Bay (+Z Depth)
      expect(find.text('Extend Bay (+Z Depth)'), findsOneWidget);
      await tester.tap(find.text('Extend Bay (+Z Depth)'));
      await tester.pumpAndSettle();

      // 6. Add Structural X-Bracing
      expect(find.text('Add Structural X-Bracing'), findsOneWidget);
      await tester.tap(find.text('Add Structural X-Bracing'));
      await tester.pumpAndSettle();

      // Switch Category tab: ASSIGN & RESTRAIN
      await tester.tap(find.text('ASSIGN & RESTRAIN'));
      await tester.pumpAndSettle();

      // 7. Assign Fixed Base
      expect(find.text('Assign Fixed Base'), findsOneWidget);
      await tester.tap(find.text('Assign Fixed Base'));
      await tester.pumpAndSettle();

      // 8. Assign Pinned Base
      expect(find.text('Assign Pinned Base'), findsOneWidget);
      await tester.tap(find.text('Assign Pinned Base'));
      await tester.pumpAndSettle();

      // 9. Assign Roller Support
      expect(find.text('Assign Roller Support'), findsOneWidget);
      await tester.tap(find.text('Assign Roller Support'));
      await tester.pumpAndSettle();

      // 10. Assign W14X90 (Heavy Column)
      expect(find.text('Assign W14X90 (Heavy Column)'), findsOneWidget);
      await tester.tap(find.text('Assign W14X90 (Heavy Column)'));
      await tester.pumpAndSettle();

      // Scroll down for remaining restraint items
      await tester.drag(find.byType(ListView).first, const Offset(0, -100));
      await tester.pumpAndSettle();

      // 11. Assign W18X35 (Girder Beam)
      expect(find.text('Assign W18X35 (Girder Beam)'), findsOneWidget);
      await tester.tap(find.text('Assign W18X35 (Girder Beam)'));
      await tester.pumpAndSettle();

      // Switch Category tab: LOADS
      await tester.ensureVisible(find.text('LOADS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LOADS'));
      await tester.pumpAndSettle();

      // 12. Apply Floor Gravity Load
      expect(find.text('Apply Floor Gravity Load'), findsOneWidget);
      await tester.tap(find.text('Apply Floor Gravity Load'));
      await tester.pumpAndSettle();

      // 13. Apply Lateral Wind Load
      expect(find.text('Apply Lateral Wind Load'), findsOneWidget);
      await tester.tap(find.text('Apply Lateral Wind Load'));
      await tester.pumpAndSettle();

      // 14. Reset Nodal Loads
      expect(find.text('Reset Nodal Loads'), findsOneWidget);
      await tester.tap(find.text('Reset Nodal Loads'));
      await tester.pumpAndSettle();

      // Switch Category tab: CANVAS
      await tester.ensureVisible(find.text('CANVAS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CANVAS'));
      await tester.pumpAndSettle();

      // 15. Toggle Extruded BMD/SFD
      expect(find.text('Toggle Extruded BMD/SFD'), findsOneWidget);
      await tester.tap(find.text('Toggle Extruded BMD/SFD'));
      await tester.pumpAndSettle();

      // 16. Re-Center Viewport (Iso 3D)
      expect(find.text('Re-Center Viewport (Iso 3D)'), findsOneWidget);
      await tester.tap(find.text('Re-Center Viewport (Iso 3D)'));
      await tester.pumpAndSettle();

      // 17. FEA SOLVE Button
      expect(find.text('FEA SOLVE'), findsOneWidget);
      await tester.tap(find.text('FEA SOLVE'));
      await tester.pumpAndSettle();

      // Verify FEA results are active
      expect(find.text('MAX DCR'), findsOneWidget);

      // Open TOOLS & SUITE Drawer from header
      final drawerButton = find.text('TOOLS & SUITE');
      expect(drawerButton, findsOneWidget);
      await tester.tap(drawerButton);
      await tester.pumpAndSettle();

      // Verify drawer header and suite items
      expect(find.text('AI Copilot'), findsOneWidget);
      expect(find.text('Modal Seismic'), findsOneWidget);
      expect(find.text('Non-Linear Pushover'), findsOneWidget);
      expect(find.text('Wind Tunnel CFD'), findsOneWidget);

      // Tap on AI Copilot in drawer (triggers AuthScreen when not signed in)
      await tester.tap(find.text('AI Copilot'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(AuthScreen))).pop();
      await tester.pumpAndSettle();
    });
  });
}
