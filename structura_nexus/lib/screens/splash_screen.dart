// ============================================================================
// SplashScreen — Initial branded connecting screen for Structura Nexus
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final String statusMessage;

  const SplashScreen({
    super.key,
    this.statusMessage = 'Connecting to Structura Nexus...',
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
              statusMessage,
              style: const TextStyle(
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
}
