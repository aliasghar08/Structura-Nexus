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

                      // 3. Central VisionOS Capsule Navigation Pills
                      _buildCapsulePill(
                        label: "AI & GEN",
                        icon: Icons.auto_awesome_rounded,
                        onTap: () => _showModalMenu(context, "AI & GENERATIVE SUITE", [
                          _MenuAction(
                            label: "AI Structural Copilot (Gemini Agent)",
                            icon: Icons.psychology_rounded,
                            onTap: () => widget.onOpenCopilot?.call(),
                          ),
                          _MenuAction(
                            label: "Generative Bracing (Pareto Optimizer)",
                            icon: Icons.hub_rounded,
                            onTap: () => widget.onOpenGenerativeBracing?.call(),
                          ),
                          _MenuAction(
                            label: "Multi-Hazard Dynamic Stimulator",
                            icon: Icons.cyclone_rounded,
                            onTap: () => widget.onOpenEnvironmentalStimulator?.call(),
                          ),
                          _MenuAction(
                            label: "AI Section Auto-Sizer",
                            icon: Icons.auto_fix_high_rounded,
                            onTap: () => widget.onOptimize?.call(),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 8),

                      _buildCapsulePill(
                        label: "CAD & BIM",
                        icon: Icons.apartment_rounded,
                        onTap: () => _showModalMenu(context, "CAD & BIM INTEROPERABILITY", [
                          _MenuAction(
                            label: "PE Calculation Packet & Digital Seal",
                            icon: Icons.assignment_turned_in_rounded,
                            onTap: () => widget.onOpenPePacket?.call(),
                          ),
                          _MenuAction(
                            label: "AI CAD 3D Drafting Studio (.dxf)",
                            icon: Icons.edit_road_rounded,
                            onTap: () => widget.onOpenCadStudio?.call(),
                          ),
                          _MenuAction(
                            label: "Structural Library & BIM Takeoff (.s2k / IFC 4.3)",
                            icon: Icons.folder_zip_rounded,
                            onTap: () => widget.onOpenLibrary?.call(),
                          ),
                          _MenuAction(
                            label: "Embodied Carbon LCA (SE 2050)",
                            icon: Icons.co2_rounded,
                            onTap: () => widget.onOpenEmbodiedCarbon?.call(),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 8),

                      _buildCapsulePill(
                        label: "ANALYSIS",
                        icon: Icons.analytics_rounded,
                        onTap: () => _showModalMenu(context, "ANALYSIS & DESIGN ENGINES", [
                          _MenuAction(
                            label: "Lateral Stability & 12x12 [Kg] Buckling",
                            icon: Icons.sync_alt_rounded,
                            onTap: () => widget.onOpenLateralStability?.call(),
                          ),
                          _MenuAction(
                            label: "Concrete Studio (ACI 318-19 P-M Envelope)",
                            icon: Icons.view_in_ar_rounded,
                            onTap: () => widget.onOpenConcreteStudio?.call(),
                          ),
                          _MenuAction(
                            label: "Dynamic Modal Vibration (ASCE 7-16)",
                            icon: Icons.waves_rounded,
                            onTap: () => widget.onOpenSeismicModal?.call(),
                          ),
                          _MenuAction(
                            label: "Pushover Capacity Spectrum (ATC-40 PBEE)",
                            icon: Icons.trending_up_rounded,
                            onTap: () => widget.onOpenPushoverAnalysis?.call(),
                          ),
                          _MenuAction(
                            label: "AeroNet Wind Boundary Layer CFD",
                            icon: Icons.air_rounded,
                            onTap: () => widget.onOpenWindCfd?.call(),
                          ),
                          _MenuAction(
                            label: "Foundation SSI (Winkler Springs)",
                            icon: Icons.terrain_rounded,
                            onTap: () => widget.onOpenGeotechnicalFoundation?.call(),
                          ),
                          _MenuAction(
                            label: "Composite Floor Vibrations (DG 11)",
                            icon: Icons.layers_rounded,
                            onTap: () => widget.onOpenCompositeFloor?.call(),
                          ),
                          _MenuAction(
                            label: "Steel Connection Studio (AISC 360)",
                            icon: Icons.hardware_rounded,
                            onTap: () => widget.onOpenSteelConnections?.call(),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 8),

                      // 4. Benchmark Presets Dropdown
                      _buildPresetDropdown(),
                      const SizedBox(width: 8),

                      // 5. Solver Engine Mode Switcher
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

  Widget _buildCapsulePill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      borderRadius: 18,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF00F0FF)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.arrow_drop_down_rounded, size: 14, color: Colors.white38),
        ],
      ),
    );
  }

  void _showModalMenu(BuildContext context, String title, List<_MenuAction> actions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117).withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((act) => InkWell(
                onTap: () {
                  Navigator.of(ctx).pop();
                  act.onTap();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(act.icon, size: 15, color: const Color(0xFF00F0FF)),
                      const SizedBox(width: 8),
                      Text(
                        act.label,
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      borderRadius: 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.straighten_rounded, size: 13, color: Color(0xFF00F0FF)),
              const SizedBox(width: 5),
              const Text(
                'DEFLECTION SCALE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.45),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  '${widget.model.deformationScale.toInt()}×',
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _scalePresetBadge(1.0, '1×'),
              const SizedBox(width: 4),
              _scalePresetBadge(25.0, '25×'),
              const SizedBox(width: 4),
              _scalePresetBadge(50.0, '50×'),
              const SizedBox(width: 4),
              _scalePresetBadge(100.0, '100×'),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: const Color(0xFF00F0FF),
                    inactiveTrackColor: Colors.white12,
                    thumbColor: const Color(0xFF00F0FF),
                    overlayColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: widget.model.deformationScale.clamp(1.0, 100.0),
                    min: 1.0,
                    max: 100.0,
                    onChanged: widget.onDeformationScaleChanged,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _rulerTick('1×', true),
                      _rulerTick('', false),
                      _rulerTick('', false),
                      _rulerTick('25×', true),
                      _rulerTick('', false),
                      _rulerTick('', false),
                      _rulerTick('50×', true),
                      _rulerTick('', false),
                      _rulerTick('', false),
                      _rulerTick('75×', true),
                      _rulerTick('', false),
                      _rulerTick('', false),
                      _rulerTick('100×', true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scalePresetBadge(double val, String label) {
    final isSelected = (widget.model.deformationScale - val).abs() < 1.0;
    return InkWell(
      onTap: () => widget.onDeformationScaleChanged(val),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white12,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white60,
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _rulerTick(String label, bool isMajor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isMajor ? 1.5 : 1.0,
          height: isMajor ? 5.0 : 3.0,
          color: isMajor ? Colors.white38 : Colors.white12,
        ),
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
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

class _MenuAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
