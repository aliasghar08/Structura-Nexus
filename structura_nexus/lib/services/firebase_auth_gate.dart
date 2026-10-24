// ============================================================================
// AuthGate — routes between AuthScreen and WorkstationApp based on Firebase
// Auth state, ensuring asynchronously restored sessions are honored.
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth_service.dart';
import '../screens/auth_screen.dart';

class AuthGate extends StatefulWidget {
  final Widget Function(BuildContext context, User? user) builder;
  const AuthGate({super.key, required this.builder});

  static const Duration firebaseWaitTimeout = Duration(seconds: 15);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _ready = false;
  User? _currentUser;
  StreamSubscription<User?>? _sub;
  bool _guestSessionActive = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final authService = FirebaseAuthService();
    await authService.initialize();

    // Subscribe to authStateChanges to receive restored user from localStorage
    try {
      _sub = authService.authStateChanges.listen(
        (User? user) {
          if (!mounted) return;
          setState(() {
            _currentUser = user;
            _ready = true;
          });
        },
        onError: (Object e) {
          debugPrint('AuthGate state error: $e');
          if (!mounted) return;
          setState(() => _ready = true);
        },
      );
    } catch (e) {
      debugPrint('AuthGate initialization fallback: $e');
      if (mounted) {
        setState(() => _ready = true);
      }
    }

    // Safety timeout in case Firebase auth hangs on network or blocked CDN
    Future.delayed(AuthGate.firebaseWaitTimeout, () {
      if (mounted && !_ready) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: const Color(0xFF080C14),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/structura_nexus_icon.jpeg',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F6FEB), Color(0xFF00F0FF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.architecture_rounded, size: 30, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00F0FF),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connecting to Structura Nexus...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If authenticated OR visitor activated guest session -> enter workstation
    if (_currentUser != null || _guestSessionActive) {
      return widget.builder(context, _currentUser);
    }

    // Otherwise render full AuthScreen
    return AuthScreen(
      onLoginSuccess: () {
        setState(() {
          _currentUser = FirebaseAuthService().currentUser;
          _guestSessionActive = true;
        });
      },
    );
  }
}
