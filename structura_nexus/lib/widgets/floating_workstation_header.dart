// ============================================================================
// FloatingWorkstationHeader — Apple visionOS Floating Glass Header Island
// Canvas Page Controls: Presets, Solvers, Display Modes, Deformations, & Drawer
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/firebase_auth_service.dart';
import 'glass_pod.dart';

class FloatingWorkstationHeader extends StatelessWidget {
  final StructuralModel model;
  final bool isBackendConnected;
  final Function(EngineType) onEngineChanged;
  final Function(DisplayMode) onModeChanged;
  final Function(double) onDeformationScaleChanged;
  final Function(String) onPresetSelected;
  final VoidCallback onSolveTriggered;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenAuth;

  // Optional tool callbacks (all 17 engineering tools & suites are now housed in WorkstationDrawer)
  final VoidCallback? onOpenCopilot;
  final VoidCallback? onOpenGenerativeOptimizer;
  final VoidCallback? onOpenGenerativeBracing;
  final VoidCallback? onOpenCadStudio;
  final VoidCallback? onOpenLibrary;
  final VoidCallback? onOpenSeismicModal;
  final VoidCallback? onOpenLateralStability;
  final VoidCallback? onOpenPePacket;
  final VoidCallback? onOpenEmbodiedCarbon;
  final VoidCallback? onOpenConcreteStudio;
  final VoidCallback? onOpenSteelConnections;
  final VoidCallback? onOpenGeotechnicalFoundation;
  final VoidCallback? onOpenPushoverAnalysis;
  final VoidCallback? onOpenWindCfd;
  final VoidCallback? onOpenCompositeFloor;
  final VoidCallback? onOpenEnvironmentalStimulator;
  final VoidCallback? onOptimize;

  const FloatingWorkstationHeader({
    super.key,
    required this.model,
    required this.isBackendConnected,
    required this.onEngineChanged,
    required this.onModeChanged,
    required this.onDeformationScaleChanged,
    required this.onPresetSelected,
    required this.onSolveTriggered,
    this.onOpenDrawer,
    this.onOpenAuth,
    this.onOpenCopilot,
    this.onOpenGenerativeOptimizer,
    this.onOpenGenerativeBracing,
    this.onOpenCadStudio,
    this.onOpenLibrary,
    this.onOpenSeismicModal,
    this.onOpenLateralStability,
    this.onOpenPePacket,
    this.onOpenEmbodiedCarbon,
    this.onOpenConcreteStudio,
    this.onOpenSteelConnections,
    this.onOpenGeotechnicalFoundation,
    this.onOpenPushoverAnalysis,
    this.onOpenWindCfd,
    this.onOpenCompositeFloor,
    this.onOpenEnvironmentalStimulator,
    this.onOptimize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            // 1. App Drawer Launcher Pill (Opens slide-out drawer hosting all 17 engineering tools & suites)
            GlassPod(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              borderRadius: 18,
              onTap: onOpenDrawer,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_rounded, color: Color(0xFF00F0FF), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    "TOOLS & SUITE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      "DRAWER",
                      style: TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // 2. Brand Capsule
            GlassPod(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              borderRadius: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF0072FF)]),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF00F0FF).withValues(alpha: 0.4), blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.architecture_rounded, color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "STRUCTURA FORGE AI",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF21262D),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "v3.4.0-REV-A",
                              style: TextStyle(color: Color(0xFF58A6FF), fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "3D Space Frame Canvas • AISC 360 / ACI 318",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // 3. Benchmark Presets Dropdown (Directly switches 3D model on the active canvas)
            _buildPresetDropdown(),
            const SizedBox(width: 10),

            // 4. Solver Engine Mode Switcher (Selects active solver for current frame)
            GlassPod(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              borderRadius: 18,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _engineBadge(EngineType.hybridDual, "HYBRID DUAL"),
                  const SizedBox(width: 4),
                  _engineBadge(EngineType.surrogateGnn, "STRUCTURANET-3D (<2ms)"),
                  const SizedBox(width: 4),
                  _engineBadge(EngineType.exactFea, "PROPRIETARY DSM"),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // 5. Canvas Display Mode Selector (Directly configures 3D viewport rendering)
            _buildDisplayModeSelector(),
            const SizedBox(width: 10),

            // 6. Deformation Magnification Slider (Directly scales 3D displacement)
            _buildDeformationSlider(),
            const SizedBox(width: 10),

            // 7. Backend Connection Indicator & Solve Trigger (Executes solve on current frame)
            _buildConnectionIndicator(),
            const SizedBox(width: 10),

            // 8. Firebase Auth Profile
            _buildUserProfileButton(),
          ],
        ),
      ),
    );
  }

  Widget _engineBadge(EngineType type, String label) {
    final isSelected = model.activeEngine == type;
    return GestureDetector(
      onTap: () => onEngineChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F6FEB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF1F6FEB).withValues(alpha: 0.4), blurRadius: 10)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPresetDropdown() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      borderRadius: 18,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'presets',
          dropdownColor: const Color(0xFF161B22),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white54),
          items: const [
            DropdownMenuItem(
              value: 'presets',
              enabled: false,
              child: Text('LOAD BENCHMARK PRESET', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            DropdownMenuItem(
              value: 'sway',
              child: Text('3D Multi-Story Sway Frame (ASCE 7)', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
            DropdownMenuItem(
              value: 'truss',
              child: Text('Warren Bridge Truss (AISC 360)', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
            DropdownMenuItem(
              value: 'cantilever',
              child: Text('Timoshenko Cantilever Girder', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
          onChanged: (val) {
            if (val != null && val != 'presets') {
              onPresetSelected(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDisplayModeSelector() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      borderRadius: 18,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DisplayMode>(
          value: model.displayMode,
          dropdownColor: const Color(0xFF161B22),
          items: const [
            DropdownMenuItem(value: DisplayMode.geometry, child: Text('Geometry Skeleton', style: TextStyle(color: Colors.white, fontSize: 11))),
            DropdownMenuItem(value: DisplayMode.deformed, child: Text('Deformed Mesh (Amplified)', style: TextStyle(color: Colors.white, fontSize: 11))),
            DropdownMenuItem(value: DisplayMode.sfdRibbon, child: Text('Shear Force (SFD Ribbon)', style: TextStyle(color: Colors.white, fontSize: 11))),
            DropdownMenuItem(value: DisplayMode.bmdRibbon, child: Text('Bending Moment (BMD Ribbon)', style: TextStyle(color: Colors.white, fontSize: 11))),
            DropdownMenuItem(value: DisplayMode.vonMisesStress, child: Text('Von Mises Stress Colormap', style: TextStyle(color: Colors.white, fontSize: 11))),
            DropdownMenuItem(value: DisplayMode.aiscCompliance, child: Text('AISC 360-16 DCR Envelope', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold))),
            DropdownMenuItem(value: DisplayMode.modalVibration, child: Text('Dynamic Modal Vibration', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold))),
          ],
          onChanged: (newMode) {
            if (newMode != null) onModeChanged(newMode);
          },
        ),
      ),
    );
  }

  Widget _buildDeformationSlider() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      borderRadius: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('MAGNIFY: ', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          Text('${model.deformationScale.toInt()}x', style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold)),
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                activeTrackColor: const Color(0xFF00F0FF),
                inactiveTrackColor: Colors.white10,
                thumbColor: const Color(0xFF00F0FF),
              ),
              child: Slider(
                value: model.deformationScale,
                min: 1.0,
                max: 100.0,
                onChanged: onDeformationScaleChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      borderRadius: 18,
      onTap: onSolveTriggered,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isBackendConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isBackendConnected ? 'LIVE ENGINE' : 'OFFLINE ENGINE',
            style: TextStyle(
              color: isBackendConnected ? const Color(0xFF10B981) : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileButton() {
    final user = FirebaseAuthService().currentUser;
    final isLoggedIn = user != null && !user.isAnonymous;

    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      borderRadius: 18,
      onTap: onOpenAuth,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLoggedIn ? Icons.cloud_done_rounded : Icons.account_circle_outlined,
            size: 15,
            color: isLoggedIn ? const Color(0xFF3FB950) : const Color(0xFF58A6FF),
          ),
          const SizedBox(width: 6),
          Text(
            isLoggedIn
                ? (user.displayName ?? user.email?.split('@').first ?? 'Account')
                : 'Cloud / Sign In',
            style: TextStyle(
              color: isLoggedIn ? const Color(0xFF3FB950) : const Color(0xFF58A6FF),
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
