// ============================================================================
// AuthScreen Tests (Sign In, Register, Forgot Password Dialog)
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structura_nexus/screens/auth_screen.dart';

void main() {
  group('AuthScreen Widget Tests', () {
    testWidgets('Renders Sign In page elements correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      await tester.pumpAndSettle();

      expect(find.text('STRUCTURA NEXUS'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text('REGISTER'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('AUTHENTICATE & ENTER'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Explore Workstation as Guest Engineer'), findsOneWidget);
    });

    testWidgets('Switches to Register tab and shows Full Name input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      await tester.pumpAndSettle();

      // Tap REGISTER tab
      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('CREATE ENGINEERING ACCOUNT'), findsOneWidget);
      expect(find.text('Forgot password?'), findsNothing);
    });

    testWidgets('Tapping Forgot Password opens Reset Password dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      await tester.pumpAndSettle();

      // Tap Forgot password?
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Email'), findsWidgets);
      expect(find.text('Dispatch Reset Link'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel dismisses dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsNothing);
    });

    testWidgets('Guest engineer button triggers onLoginSuccess callback', (tester) async {
      var successCalled = false;
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            onLoginSuccess: () => successCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explore Workstation as Guest Engineer'));
      await tester.pumpAndSettle();

      expect(successCalled, isTrue);
    });

    testWidgets('Register tab validates empty fields and shows prompt', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CREATE ENGINEERING ACCOUNT'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);
    });

    testWidgets('Register tab validates weak password under 6 chars', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'engineer@structura.io');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '12345');
      await tester.pumpAndSettle();

      await tester.tap(find.text('CREATE ENGINEERING ACCOUNT'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('Back to Workstation button is visible and navigates to Workstation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Back to Workstation'), findsOneWidget);
      await tester.tap(find.text('Back to Workstation'));
      await tester.pumpAndSettle();

      expect(find.text('STRUCTURA NEXUS'), findsOneWidget);
    });

    testWidgets('Supports password managers with AutofillGroup and hints', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      await tester.pumpAndSettle();

      // Ensure AutofillGroup wraps the credentials
      expect(find.byType(AutofillGroup), findsOneWidget);

      // Verify email TextField has email autofill hints
      final emailFinder = find.widgetWithText(TextField, 'Email');
      expect(emailFinder, findsOneWidget);
      final emailWidget = tester.widget<TextField>(emailFinder);
      expect(emailWidget.autofillHints, contains(AutofillHints.email));

      // Verify password TextField has password autofill hints
      final passwordFinder = find.widgetWithText(TextField, 'Password');
      expect(passwordFinder, findsOneWidget);
      final passwordWidget = tester.widget<TextField>(passwordFinder);
      expect(passwordWidget.autofillHints, contains(AutofillHints.password));
    });

    testWidgets('Renders Passkey biometric button and clickable cursor', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      await tester.pumpAndSettle();

      // Passkey button is rendered
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data?.contains('Passkey') == true || w.data?.contains('Security Key') == true)),
        findsOneWidget,
      );

      // Ensure clickable cursor is specified on OutlinedButton
      final outlinedButtons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
      expect(outlinedButtons.isNotEmpty, isTrue);
      for (final btn in outlinedButtons) {
        expect(btn.style?.mouseCursor?.resolve({}), SystemMouseCursors.click);
      }
    });
  });
}
