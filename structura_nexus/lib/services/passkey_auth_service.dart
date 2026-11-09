// ============================================================================
// Structura Nexus — Unified Passkey & WebAuthn Authentication Service
// Cross-platform interface for Touch ID / Face ID / Windows Hello Passkeys
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'firebase_auth_service.dart';
import 'passkey_auth_stub.dart' if (dart.library.js_interop) 'passkey_auth_web.dart';

class PasskeyAuthService {
  static final PasskeyAuthService _instance = PasskeyAuthService._internal();
  factory PasskeyAuthService() => _instance;
  PasskeyAuthService._internal();

  /// Whether biometric passkeys are supported on the current device / browser
  Future<bool> isSupported() async {
    if (!kIsWeb) return false;
    try {
      return await PasskeyAuthPlatform.isSupported();
    } catch (_) {
      return false;
    }
  }

  /// Get list of previously saved accounts with registered passkeys
  List<Map<String, dynamic>> getSavedAccounts() {
    if (!kIsWeb) return [];
    return PasskeyAuthPlatform.getSavedAccounts();
  }

  /// Register a new Passkey credential for the given user email
  Future<Map<String, dynamic>> registerPasskey({
    required String email,
    String? displayName,
  }) async {
    return await PasskeyAuthPlatform.registerPasskey(
      email.trim(),
      displayName ?? email.split('@').first,
    );
  }

  /// Authenticate using an existing Passkey (Touch ID, Face ID, Windows Hello)
  /// Automatically signs into Firebase Auth and synchronizes the user profile.
  Future<Map<String, dynamic>> authenticate() async {
    final res = await PasskeyAuthPlatform.authenticatePasskey();
    if (res['success'] == true) {
      final email = (res['email'] as String?) ?? 'passkey.engineer@structuranexus.io';
      final displayName = (res['displayName'] as String?) ?? email.split('@').first;

      // Ensure Firebase Auth session is initialized with this identity
      try {
        final authService = FirebaseAuthService();
        final current = authService.currentUser;
        if (current == null) {
          final cred = await authService.signInAnonymously();
          if (cred?.user != null) {
            try {
              await cred!.user!.updateDisplayName('$displayName [Passkey]');
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Passkey Firebase sync note: $e');
      }
    }
    return res;
  }
}
