// ============================================================================
// Structura Nexus — Application Entrypoint
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_auth_service.dart';
import 'screens/workstation_screen.dart';

// Re-export WorkstationScreen for testing & backward compatibility
export 'screens/workstation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuthService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }
  runApp(const StructuraNexusApp());
}

class StructuraNexusApp extends StatelessWidget {
  const StructuraNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Structura Forge AI / Structura Nexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D14),
        primaryColor: const Color(0xFF1F6FEB),
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      home: const WorkstationScreen(),
    );
  }
}
