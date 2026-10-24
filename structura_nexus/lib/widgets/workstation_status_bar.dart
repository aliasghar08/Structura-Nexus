// ============================================================================
// WorkstationStatusBar — Non-Overlapping Workstation Footer & Legal Status Bar
// Ground Truth Solver Status, Real-Time Telemetry & DMCA Copyright Notice
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';

class WorkstationStatusBar extends StatelessWidget {
  final StructuralModel? model;

  const WorkstationStatusBar({super.key, this.model});

  static const String ownerName = 'Ali Asghar';
  static const String ownerEmail = 'aliasgharinnocent@yahoo.com';
  static const String appTitle = 'Structura Nexus';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF070A0F),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Left: Real-Time Engine & DSM Ground Truth Status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF00F0FF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'DETERMINISTIC DSM FEA (12×12)  •  GNN SURROGATE READY',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),

          // 2. Center: Copyright & Legal Attribution (In-Flow, Never Blocks Any UI Button)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 11,
                    color: Color(0xFF00F0FF),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '$appTitle © $ownerName · $ownerEmail · All Rights Reserved · DMCA Protected',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Right: Standard Specification & Active Revision
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AISC 360-16 / ASCE 7-16  •  v3.4.0-REV-A',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
