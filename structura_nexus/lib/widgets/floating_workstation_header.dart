// ============================================================================
// FloatingWorkstationHeader — Apple visionOS Scrolling Glass Option Bar
// Interactive horizontal scrolling bar with chevron controls, mouse-drag & touch
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/firebase_auth_service.dart';
import 'glass_pod.dart';

class FloatingWorkstationHeader extends StatefulWidget {
  final StructuralModel model;
  final bool isBackendConnected;
  final bool useThreeJs;
  final VoidCallback? onToggleRenderer;
  final ValueChanged<String>? onCameraPreset;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final Function(EngineType) onEngineChanged;
  final Function(DisplayMode) onModeChanged;
  final Function(double) onDeformationScaleChanged;
  final Function(String) onPresetSelected;
  final VoidCallback onSolveTriggered;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenAuth;

  // Optional tool callbacks (all 17 engineering tools & suites are housed in WorkstationDrawer)
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
    this.useThreeJs = true,
    this.onToggleRenderer,
    this.onCameraPreset,
    this.onZoomIn,
    this.onZoomOut,
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
  State<FloatingWorkstationHeader> createState() => _FloatingWorkstationHeaderState();
}

class _FloatingWorkstationHeaderState extends State<FloatingWorkstationHeader> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 6 : 10,
      ),
      child: Row(
        children: [
          // Left Scroll Chevron Button
          _buildScrollButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Scroll options left',
            onTap: () => _scrollBy(-260),
          ),
          const SizedBox(width: 6),

          // Horizontally Scrollable Option Bar
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: const {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: RawScrollbar(
                controller: _scrollController,
                thumbColor: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                radius: const Radius.circular(4),
                thickness: 3,
                padding: const EdgeInsets.only(top: 2),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      // 1. App Drawer Launcher Pill
                      GlassPod(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        borderRadius: 18,
                        onTap: widget.onOpenDrawer,
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
                      const SizedBox(width: 8),

                      // 2. Brand Capsule
                      GlassPod(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        borderRadius: 18,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF0072FF)]),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF00F0FF).withValues(alpha: 0.4), blurRadius: 10),
                                ],
                              ),
                              child: const Icon(Icons.architecture_rounded, color: Colors.black, size: 16),
                            ),
                            const SizedBox(width: 9),
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
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.7,
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
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. Benchmark Presets Dropdown
                      _buildPresetDropdown(),
                      const SizedBox(width: 8),

                      // 4. Solver Engine Mode Switcher
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
                      const SizedBox(width: 8),

                      // 5. Canvas Display Mode Selector
                      _buildDisplayModeSelector(),
                      const SizedBox(width: 8),

                      // 6. Deformation Magnification Slider
                      _buildDeformationSlider(),
                      const SizedBox(width: 8),

                      // 7. Renderer Mode Toggle (WebGL 3D GPU / Vector 2.5D)
                      _buildRendererToggle(),
                      const SizedBox(width: 8),

                      // 8. Camera Presets (ISO / TOP / FRONT) & Zoom Controls
                      _buildCameraControls(),
                      const SizedBox(width: 8),

                      // 9. 3D Axis Compass Badge (X • Y • Z)
                      _buildCompassBadge(),
                      const SizedBox(width: 8),

                      // 10. Backend Connection Indicator & Solve Trigger
                      _buildConnectionIndicator(),
                      const SizedBox(width: 8),

                      // 11. Firebase Auth Profile
                      _buildUserProfileButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),
          // Right Scroll Chevron Button
          _buildScrollButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Scroll options right',
            onTap: () => _scrollBy(260),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GlassPod(
        padding: const EdgeInsets.all(6),
        borderRadius: 14,
        onTap: onTap,
        child: Icon(icon, size: 18, color: const Color(0xFF00F0FF)),
      ),
    );
  }

  Widget _engineBadge(EngineType type, String label) {
    final isSelected = widget.model.activeEngine == type;
    return GestureDetector(
      onTap: () => widget.onEngineChanged(type),
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
          isDense: true,
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
              widget.onPresetSelected(val);
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
          value: widget.model.displayMode,
          isDense: true,
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
            if (newMode != null) widget.onModeChanged(newMode);
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
          Text('${widget.model.deformationScale.toInt()}x', style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold)),
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
                value: widget.model.deformationScale,
                min: 1.0,
                max: 100.0,
                onChanged: widget.onDeformationScaleChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRendererToggle() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      borderRadius: 18,
      onTap: widget.onToggleRenderer,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.useThreeJs ? Icons.view_in_ar_rounded : Icons.brush_rounded,
            size: 14,
            color: widget.useThreeJs ? const Color(0xFF00F0FF) : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            widget.useThreeJs ? 'WebGL 3D (GPU)' : 'Vector 2.5D',
            style: TextStyle(
              color: widget.useThreeJs ? const Color(0xFF00F0FF) : Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      borderRadius: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cameraPresetBtn('ISO'),
          const SizedBox(width: 4),
          _cameraPresetBtn('TOP'),
          const SizedBox(width: 4),
          _cameraPresetBtn('FRONT'),
          Container(
            height: 14,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            color: Colors.white12,
          ),
          _cameraIconBtn(Icons.zoom_in_rounded, 'Zoom In', widget.onZoomIn),
          const SizedBox(width: 3),
          _cameraIconBtn(Icons.zoom_out_rounded, 'Zoom Out', widget.onZoomOut),
          const SizedBox(width: 3),
          _cameraIconBtn(
            Icons.center_focus_strong_rounded,
            'Recenter View',
            () => widget.onCameraPreset?.call('RECENTER'),
          ),
        ],
      ),
    );
  }

  Widget _cameraPresetBtn(String label) {
    return Tooltip(
      message: '$label Camera View',
      child: InkWell(
        onTap: () => widget.onCameraPreset?.call(label),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cameraIconBtn(IconData icon, String tooltip, VoidCallback? onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 15, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildCompassBadge() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      borderRadius: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('X', style: TextStyle(color: Colors.redAccent, fontSize: 10.5, fontWeight: FontWeight.bold)),
          SizedBox(width: 4),
          Text('•', style: TextStyle(color: Colors.white24, fontSize: 10)),
          SizedBox(width: 4),
          Text('Y', style: TextStyle(color: Colors.greenAccent, fontSize: 10.5, fontWeight: FontWeight.bold)),
          SizedBox(width: 4),
          Text('•', style: TextStyle(color: Colors.white24, fontSize: 10)),
          SizedBox(width: 4),
          Text('Z', style: TextStyle(color: Colors.cyanAccent, fontSize: 10.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      borderRadius: 18,
      onTap: widget.onSolveTriggered,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: widget.isBackendConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.isBackendConnected ? 'LIVE ENGINE' : 'OFFLINE ENGINE',
            style: TextStyle(
              color: widget.isBackendConnected ? const Color(0xFF10B981) : Colors.white70,
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
      onTap: widget.onOpenAuth,
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
