// ============================================================================
// FloatingWorkstationHeader — Apple visionOS Scrolling Glass Option Bar
// Interactive horizontal scrolling bar with chevron controls, mouse-drag & touch
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/firebase_auth_service.dart';
import '../services/workspace_storage.dart';
import '../services/building_generator_service.dart';
import 'glass_pod.dart';
import 'info_tooltip.dart';
import 'keyboard_shortcuts_dialog.dart';

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
  final VoidCallback? onOpenVisionToBim;
  final VoidCallback? onOpenNltha;
  final VoidCallback? onOptimize;
  final VoidCallback? onOpenBuildingTemplates;
  final VoidCallback? onOpenMacAiInspector;
  final VoidCallback? onOpenAutonomousSwarm;
  final VoidCallback? onOpenParetoExplorer;
  final VoidCallback? onOpenGenerativeTopology;
  final VoidCallback? onOpenShopDrawingAudit;
  final VoidCallback? onOpenCollaborationReview;
  final VoidCallback? onOpenProgressiveCollapse;
  final VoidCallback? onOpenConnectionDetailer;
  final VoidCallback? onOpenBridgeMovingLoad;
  final VoidCallback? onOpenCommandPalette;
  final VoidCallback? onOpenCapabilitiesOverview;
  final int? activeWorkflowStage;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;
  final bool isEssentialMode;
  final VoidCallback? onToggleWorkspaceMode;
  final VoidCallback? onOpenShortcuts;

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
    this.onOpenVisionToBim,
    this.onOpenNltha,
    this.onOptimize,
    this.onOpenBuildingTemplates,
    this.onOpenMacAiInspector,
    this.onOpenAutonomousSwarm,
    this.onOpenParetoExplorer,
    this.onOpenGenerativeTopology,
    this.onOpenShopDrawingAudit,
    this.onOpenCollaborationReview,
    this.onOpenProgressiveCollapse,
    this.onOpenConnectionDetailer,
    this.onOpenBridgeMovingLoad,
    this.onOpenCommandPalette,
    this.onOpenCapabilitiesOverview,
    this.activeWorkflowStage,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
    this.isEssentialMode = true,
    this.onToggleWorkspaceMode,
    this.onOpenShortcuts,
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

    return MouseRegion(
      onEnter: (_) => WorkspacePreferences.freezeOrbit(true),
      onExit: (_) => WorkspacePreferences.freezeOrbit(false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (_) {},
        child: Padding(
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
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) => true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            // 1. App Drawer Launcher Pill
                            _HoverableSpecularPill(
                              label: "TOOLS & SUITE",
                              icon: Icons.menu_rounded,
                              onTap: widget.onOpenDrawer,
                        trailingBadge: Container(
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
                                      "STRUCTURA NEXUS",
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
                                        "v4.5.0-APEX",
                                        style: TextStyle(color: Color(0xFF58A6FF), fontSize: 8.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const InfoTooltip(
                                      title: 'Structura Nexus v4.5-APEX',
                                      codeRef: 'AISC 360-16 • ACI 318-19 • ASCE 7-16 • UFC 4-023-03 • AASHTO HL-93',
                                      message:
                                          'Autonomous Frontier Structural & Civil Engineering Workstation combining an exact 12-DOF Direct Stiffness Matrix (DSM) solver (0.0000% benchmark error) with 10 Apple Silicon MPS neural surrogates and WebGPU batch optimization.',
                                      size: 13,
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

                      // 2.2 ESSENTIAL / PRO SUITE Mode Switcher Pill
                      _buildModeSwitcherPill(),
                      const SizedBox(width: 8),

                      // 2.5 Universal Command Palette & Encyclopedia Pill (⌘K)
                      if (widget.onOpenCommandPalette != null) ...[
                        _HoverableSpecularPill(
                          label: "QUICK CMD",
                          icon: Icons.bolt_rounded,
                          onTap: widget.onOpenCommandPalette,
                          infoTitle: 'Universal Command Palette & Encyclopedia',
                          infoCode: 'Shortcut: ⌘K / Ctrl+K',
                          infoMessage:
                              'Instant Spotlight-style fuzzy search across all 30+ structural solvers, AI engines, CAD/BIM tools, and building templates with built-in engineering guides.',
                          trailingBadge: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF00F0FF).withValues(alpha: 0.55),
                                width: 0.5,
                              ),
                            ),
                            child: const Text(
                              "⌘K",
                              style: TextStyle(
                                color: Color(0xFF00F0FF),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // 2.6 "? WHAT CAN I BUILD?" Capabilities Launcher Pill
                      if (widget.onOpenCapabilitiesOverview != null) ...[
                        _HoverableSpecularPill(
                          label: "WHAT CAN I BUILD?",
                          icon: Icons.help_outline_rounded,
                          onTap: widget.onOpenCapabilitiesOverview,
                          infoTitle: 'Interactive Engineering Capabilities Overview',
                          infoCode: '6 Civil/Structural Workflows',
                          infoMessage:
                              'Explore all 6 core civil & structural engineering workflows (Buildings, Bridges, Seismic NLTHA, Progressive Collapse, Steel/Concrete Design, and Stamped PE Reports) with 1-click "Try Example" launchers.',
                          trailingBadge: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.55),
                                width: 0.5,
                              ),
                            ),
                            child: const Text(
                              "GUIDE",
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // 2.7 KEYBOARD SHORTCUTS (?)
                      _HoverableSpecularPill(
                        label: "SHORTCUTS (?)",
                        icon: Icons.keyboard_rounded,
                        onTap: widget.onOpenShortcuts != null
                            ? widget.onOpenShortcuts!
                            : () => showKeyboardShortcutsDialog(context),
                        infoTitle: 'Keyboard Shortcuts Reference',
                        infoCode: 'Press ? anytime',
                        infoMessage:
                            'Fast viewport navigation (1-4 Camera views), multi-selection (Shift+Click), and modeling commands.',
                        trailingBadge: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.55),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            "?",
                            style: TextStyle(
                              color: Color(0xFF00F0FF),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. Sequential 5-Stage Civil/Structural Engineering Pipeline
                      // Stage 1: GEOMETRY
                      _buildCapsulePill(
                        label: "1. GEOMETRY",
                        icon: Icons.apartment_rounded,
                        isActiveStage: widget.activeWorkflowStage == 1,
                        infoTitle: 'Stage 1: 3D Structural Geometry & Framing',
                        infoCode: 'Templates • Vision-to-BIM • CAD',
                        infoMessage:
                            'Define or import your 3D structural frame: choose from 12 certified building/bridge templates, convert a 2D floorplan blueprint to 3D, or draft members in CAD.',
                        onTap: () => _showModalMenu(context, "STAGE 1: GEOMETRY & 3D FRAMING", [
                          _MenuAction(
                            label: "12 Certified Building & Bridge Templates",
                            subtitle: "Load pre-engineered high-rise towers, hospitals, bridges, and warehouses",
                            icon: Icons.apartment_rounded,
                            infoText:
                                'Load 12 complete 3D structural benchmarks: 10-story office tower, hospital, 20-story outrigger supertall, Pratt bridge, and space canopy.',
                            onTap: () {
                              if (widget.onOpenBuildingTemplates != null) {
                                widget.onOpenBuildingTemplates!();
                              } else {
                                widget.onOpenLibrary?.call();
                              }
                            },
                          ),
                          _MenuAction(
                            label: "Vision-to-BIM 2D Floorplan Ingestion",
                            subtitle: "Convert 2D architectural floorplan blueprints into 3D structural framing",
                            icon: Icons.document_scanner_rounded,
                            infoText:
                                'Extracts structural column grids, beam spans, and core walls from 2D architectural floorplan blueprints into a 3D finite element model.',
                            onTap: () => widget.onOpenVisionToBim?.call(),
                          ),
                          _MenuAction(
                            label: "AI CAD 3D Drafting Studio (.dxf)",
                            subtitle: "Draw joints, beams, columns, and bracing on an interactive snap grid",
                            icon: Icons.edit_road_rounded,
                            infoText:
                                'Interactive 2D/3D CAD drafting viewport with snap-to-grid, member drawing, and AutoCAD DXF export.',
                            onTap: () => widget.onOpenCadStudio?.call(),
                          ),
                          _MenuAction(
                            label: "AI Structural Copilot (Gemini Framing Agent)",
                            subtitle: "Synthesize custom multi-story frames or ask structural mechanics questions",
                            icon: Icons.psychology_rounded,
                            infoText:
                                'Conversational structural engineering assistant capable of explaining failure modes, synthesizing frames, and recommending code-compliant retrofits.',
                            onTap: () => widget.onOpenCopilot?.call(),
                          ),
                          _MenuAction(
                            label: "AISC Section Catalog & Profile Browser",
                            subtitle: "Inspect W-shapes, HSS tubes, and RC sections with full geometric properties",
                            icon: Icons.folder_zip_rounded,
                            infoText:
                                'Browse the complete AISC 360-16 steel catalog (A, Ix, Iy, Zx, Zy, J) and assign sections to frame members.',
                            onTap: () => widget.onOpenLibrary?.call(),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 8),

                      // Stage 2: LOADS & SUPPORTS
                      _buildCapsulePill(
                        label: "2. LOADS & SUPPORTS",
                        icon: Icons.compress_rounded,
                        isActiveStage: widget.activeWorkflowStage == 2,
                        infoTitle: 'Stage 2: Restraints, Tributary Gravity & ASCE 7 Lateral Loads',
                        infoCode: 'ASCE 7-16 • AASHTO HL-93 • 6-DOF Supports',
                        infoMessage:
                            'Configure boundary conditions (fixed, pinned, roller, member end releases) and apply ASCE 7-16 wind/seismic lateral forces, tributary floor loads, or AASHTO bridge trucks.',
                        onTap: () => _showModalMenu(context, "STAGE 2: SUPPORTS & ASCE 7 / AASHTO LOADS", [
                          _MenuAction(
                            label: "ASCE 7-16 Wind, Seismic & P-Delta Lateral Loads",
                            subtitle: "Configure wind speed V, seismic Cs, and directional sway combinations",
                            icon: Icons.sync_alt_rounded,
                            infoText:
                                'Computes ASCE 7-16 Ch. 27 directional wind pressures and §12.8 Equivalent Lateral Force (ELF) seismic story shears across floor diaphragms.',
                            onTap: () => widget.onOpenLateralStability?.call(),
                          ),
                          if (widget.onOpenBridgeMovingLoad != null)
                            _MenuAction(
                              label: "AASHTO LRFD HL-93 Moving-Load Bridge Truck",
                              subtitle: "Step the 325 kN design truck + 9.3 kN/m lane load across bridge spans",
                              icon: Icons.local_shipping_rounded,
                              infoText:
                                  'Steps the AASHTO HL-93 Design Truck (35 + 145 + 145 kN, IM=1.33) + 9.3 kN/m lane load across the bridge deck in 40 DSM steps with influence lines η(x).',
                              onTap: () => widget.onOpenBridgeMovingLoad?.call(),
                            ),
                          if (!widget.isEssentialMode) ...[
                            _MenuAction(
                              label: "AeroNet Atmospheric Wind Boundary-Layer CFD",
                              subtitle: "Simulate wind velocity profiles, Cp pressure contours, and vortex shedding",
                              icon: Icons.air_rounded,
                              infoText:
                                  'Atmospheric boundary layer velocity profile, Cp pressure contours, and vortex shedding lock-in frequency analysis.',
                              onTap: () => widget.onOpenWindCfd?.call(),
                            ),
                            _MenuAction(
                              label: "Multi-Hazard Dynamic Environmental Stimulator",
                              subtitle: "Apply live coupled seismic ground motion, wind gusts, and blast waves",
                              icon: Icons.cyclone_rounded,
                              infoText:
                                  'Live 60 FPS 3D simulation of coupled seismic ground motion, vortex-induced wind resonance, and blast wave overpressure.',
                              onTap: () => widget.onOpenEnvironmentalStimulator?.call(),
                            ),
                          ],
                          _MenuAction(
                            label: "Geotechnical Foundation Supports & Winkler Springs",
                            subtitle: "Model elastic soil springs (ks), footing dimensions, and base restraints",
                            icon: Icons.terrain_rounded,
                            infoText:
                                'Soil-Structure Interaction with Winkler subgrade springs (k_s), Terzaghi bearing capacity, and ACI 318-19 §22.6 two-way punching shear.',
                            onTap: () => widget.onOpenGeotechnicalFoundation?.call(),
                          ),
                          if (widget.isEssentialMode && widget.onToggleWorkspaceMode != null)
                            _MenuAction(
                              label: "+ Show Pro Frontier Tools (AeroNet CFD & Multi-Hazard)",
                              subtitle: "Switch to Pro Suite mode to unlock atmospheric CFD wind tunnels and dynamic stimulators",
                              icon: Icons.rocket_launch_rounded,
                              onTap: widget.onToggleWorkspaceMode!,
                            ),
                        ]),
                      ),
                      const SizedBox(width: 8),

                      // Stage 3: ANALYSIS
                      _buildCapsulePill(
                        label: "3. ANALYSIS",
                        icon: Icons.analytics_rounded,
                        isActiveStage: widget.activeWorkflowStage == 3,
                        infoTitle: 'Stage 3: 12-DOF FEA, Buckling, NLTHA & Progressive Collapse',
                        infoCode: '12-DOF DSM • Newmark-β • UFC 4-023-03',
                        infoMessage:
                            'Execute exact 12-DOF Direct Stiffness Matrix (0.0000% error) analysis, 12×12 [Kg] eigenvalue buckling, Newmark-β seismic time-history, and UFC 4-023-03 column-removal collapse.',
                        onTap: () => _showModalMenu(context, "STAGE 3: STRUCTURAL & DYNAMIC ANALYSIS ENGINES", [
                          _MenuAction(
                            label: "Execute 12-DOF Direct Stiffness Matrix (DSM) Solve",
                            subtitle: "Compute exact 3D displacements {u}, reactions, and N/V/M forces (0.0000% error)",
                            icon: Icons.play_circle_fill_rounded,
                            infoText:
                                'Assembles and solves the global 12-DOF space-frame stiffness matrix [K]{u}={F} with static condensation for member end releases.',
                            onTap: widget.onSolveTriggered,
                          ),
                          _MenuAction(
                            label: "Lateral Stability, P-Delta & 12×12 [Kg] Buckling",
                            subtitle: "Compute elastic critical buckling factor α_cr and AISC App. 8 B2 sway amplifier",
                            icon: Icons.sync_alt_rounded,
                            infoText:
                                'Assembles 12×12 geometric stiffness matrix [Kg] to compute elastic critical buckling load factor α_cr and AISC 360-16 Appendix 8 B2 sway amplification.',
                            onTap: () => widget.onOpenLateralStability?.call(),
                          ),
                          _MenuAction(
                            label: "Dynamic Modal Vibration & Eigenmodes (ASCE 7-16)",
                            subtitle: "Extract natural frequencies ω_n, periods T_n, and 3D mode shape animations",
                            icon: Icons.waves_rounded,
                            infoText:
                                'Solves generalized eigenvalue problem det([K] - ω²[M]) = 0 for natural frequencies, periods, and 3D mode shape animations.',
                            onTap: () => widget.onOpenSeismicModal?.call(),
                          ),
                          if (!widget.isEssentialMode) ...[
                            if (widget.onOpenProgressiveCollapse != null)
                              _MenuAction(
                                label: "Progressive Collapse & Alternate Path (UFC 4-023-03)",
                                subtitle: "Simulate sudden column loss (Ω_LD = 2.0) and double-span catenary bridging",
                                icon: Icons.warning_amber_rounded,
                                infoText:
                                    'Simulates sudden notional column loss under Ω_LD = 2.0 dynamic amplification, evaluating double-span catenary bridging and vulnerability rankings.',
                                onTap: () => widget.onOpenProgressiveCollapse?.call(),
                              ),
                            _MenuAction(
                              label: "Dynamic Time-History (NLTHA) Earthquake Player",
                              subtitle: "Run Newmark-β step-by-step response under El Centro, Northridge & Kobe records",
                              icon: Icons.movie_filter_rounded,
                              infoText:
                                  'Newmark-Beta (γ=0.5, β=0.25) step-by-step non-linear seismic time history integration under El Centro, Northridge, and Kobe ground motions.',
                              onTap: () => widget.onOpenNltha?.call(),
                            ),
                            _MenuAction(
                              label: "Non-Linear Static Pushover Curve (ATC-40 / FEMA 356)",
                              subtitle: "Trace Base Shear V vs. Roof Drift Δ with IO / LS / CP plastic hinge limits",
                              icon: Icons.trending_up_rounded,
                              infoText:
                                  'Non-linear static pushover curve (Base Shear V vs. Roof Drift Δ) with FEMA 356 IO / LS / CP plastic hinge performance levels.',
                              onTap: () => widget.onOpenPushoverAnalysis?.call(),
                            ),
                          ],
                          if (widget.isEssentialMode && widget.onToggleWorkspaceMode != null)
                            _MenuAction(
                              label: "+ Show Pro Frontier Tools (NLTHA, Pushover & Progressive Collapse)",
                              subtitle: "Switch to Pro Suite mode to unlock non-linear time history and column removal simulations",
                              icon: Icons.rocket_launch_rounded,
                              onTap: widget.onToggleWorkspaceMode!,
                            ),
                        ]),
                      ),
                      const SizedBox(width: 8),

                      // Stage 4: DESIGN & OPTIMIZE
                      _buildCapsulePill(
                        label: "4. DESIGN & OPTIMIZE",
                        icon: Icons.auto_awesome_rounded,
                        isActiveStage: widget.activeWorkflowStage == 4,
                        infoTitle: 'Stage 4: Code Checking, Connection Detailing & AI Optimization',
                        infoCode: 'AISC 360-16 • ACI 318-19 • SIMP • WebGPU Pareto',
                        infoMessage:
                            'Verify AISC 360-16 steel DCR, detail 3D bolted connections, check ACI 318-19 concrete P-M & crack widths, or run AI Auto-Sizer, 4-Agent Swarm, and WebGPU Pareto optimization.',
                        onTap: () => _showModalMenu(context, "STAGE 4: CODE DESIGN, CONNECTIONS & AI OPTIMIZATION", [
                          _MenuAction(
                            label: "AISC 360-16 AI Section Auto-Sizer",
                            subtitle: "Automatically assign minimum-weight W-shapes so every member satisfies DCR ≤ 1.0",
                            icon: Icons.auto_fix_high_rounded,
                            infoText:
                                'Automatically assigns minimum-weight AISC 360-16 W-shapes so every member satisfies Demand-Capacity Ratio DCR ≤ 1.0.',
                            onTap: () => widget.onOptimize?.call(),
                          ),
                          if (widget.onOpenConnectionDetailer != null)
                            _MenuAction(
                              label: "AISC 360-16 Ch. J 3D Connection & Baseplate Synthesizer",
                              subtitle: "Design shear tabs, moment end-plates, Whitmore gussets, and 3D hex bolts",
                              icon: Icons.hardware_rounded,
                              infoText:
                                  'Evaluates bolted shear tabs, extended moment end-plates, Whitmore 30° gussets, and column baseplates, synthesizing 3D hex-bolt assemblies in Three.js.',
                              onTap: () => widget.onOpenConnectionDetailer?.call(),
                            ),
                          _MenuAction(
                            label: "Concrete Studio (ACI 318-19 P-M & ACI 224R Crack Widths)",
                            subtitle: "Verify biaxial RC column P-M capacity, I_eff stiffness, and surface crack width w_k",
                            icon: Icons.view_in_ar_rounded,
                            infoText:
                                'Biaxial reinforced concrete column P-M interaction diagram (Whitney stress block) and ACI 224R-01 Gergely-Lutz surface crack width serviceability.',
                            onTap: () => widget.onOpenConcreteStudio?.call(),
                          ),
                          if (!widget.isEssentialMode) ...[
                            if (widget.onOpenAutonomousSwarm != null)
                              _MenuAction(
                                label: "Autonomous 4-Agent Engineering Swarm (Self-Healer)",
                                subtitle: "Architect ↔ FEA Analyst ↔ Code Auditor ↔ Self-Healer iterative loop",
                                icon: Icons.hub_rounded,
                                infoText:
                                    'Multi-agent collaboration (Architect, FEA Analyst, Code Auditor, Self-Healer) that iteratively resolves overstressed members and drift violations.',
                                onTap: () => widget.onOpenAutonomousSwarm?.call(),
                              ),
                            if (widget.onOpenGenerativeTopology != null)
                              _MenuAction(
                                label: "3D Diagrid Topology Synthesizer (Neural SIMP)",
                                subtitle: "Optimize continuous density field ρ(x,y,z) for 18–30% steel mass reduction",
                                icon: Icons.architecture_rounded,
                                infoText:
                                    'Continuous neural density field ρ(x,y,z) optimization and Marching Struts discretizer generating 3D diagrid exoskeletons with 18–30% steel mass reduction.',
                                onTap: () => widget.onOpenGenerativeTopology?.call(),
                              ),
                            if (widget.onOpenParetoExplorer != null)
                              _MenuAction(
                                label: "WebGPU 60 FPS Pareto Frontier Explorer (B=256)",
                                subtitle: "Trade off Steel Mass (kg), Peak Drift (mm), and Carbon (kg CO2e) in real time",
                                icon: Icons.scatter_plot_rounded,
                                infoText:
                                    'Evaluates 256 structural variations in parallel via WebGPU WGSL shaders, trading off steel mass, roof drift, and embodied carbon in real time.',
                                onTap: () => widget.onOpenParetoExplorer?.call(),
                              ),
                            _MenuAction(
                              label: "Generative Lateral Bracing Optimizer",
                              subtitle: "Synthesize X-brace, Chevron, or Diagrid bracing to maximize buckling α_cr",
                              icon: Icons.grid_4x4_rounded,
                              infoText:
                                  'Synthesizes optimal lateral bracing topologies (X-brace, Chevron, Diagrid) to maximize elastic critical buckling factor α_cr.',
                              onTap: () => widget.onOpenGenerativeBracing?.call(),
                            ),
                          ],
                          _MenuAction(
                            label: "Composite Floor Walking Vibration Check (AISC DG 11)",
                            subtitle: "Verify human comfort peak acceleration a_p/g and composite shear studs",
                            icon: Icons.layers_rounded,
                            infoText:
                                'AISC Design Guide 11 human walking comfort acceleration check (a_p/g) and shear stud composite beam action.',
                            onTap: () => widget.onOpenCompositeFloor?.call(),
                          ),
                          _MenuAction(
                            label: "Steel Moment & Shear Connection Calculator",
                            subtitle: "Check bolt shear, flange weld capacity, and baseplate bearing stress",
                            icon: Icons.construction_rounded,
                            infoText:
                                'Designs bolted end-plate moment connections, shear tabs, and column baseplates for bolt shear, prying, and weld capacity.',
                            onTap: () => widget.onOpenSteelConnections?.call(),
                          ),
                          if (widget.isEssentialMode && widget.onToggleWorkspaceMode != null)
                            _MenuAction(
                              label: "+ Show Pro Frontier Tools (Swarm, Diagrid SIMP, WebGPU Pareto)",
                              subtitle: "Switch to Pro Suite mode to unlock autonomous 4-agent swarms and WebGPU Pareto explorers",
                              icon: Icons.rocket_launch_rounded,
                              onTap: widget.onToggleWorkspaceMode!,
                            ),
                        ]),
                      ),
                      const SizedBox(width: 8),

                      // Stage 5: REPORTS & BIM
                      _buildCapsulePill(
                        label: "5. REPORTS & BIM",
                        icon: Icons.verified_user_rounded,
                        isActiveStage: widget.activeWorkflowStage == 5,
                        infoTitle: 'Stage 5: Stamped PE Calculation Packets, BIM Export & QA',
                        infoCode: 'HMAC-SHA256 PE Seal • IFC 4.3 • SAP2000 .s2k',
                        infoMessage:
                            'Export cryptographically sealed PE calculation packets (PDF/LaTeX), CSI SAP2000 (.s2k), openBIM IFC 4.3, AutoCAD (.dxf), SE 2050 carbon audits, and live cloud reviews.',
                        onTap: () => _showModalMenu(context, "STAGE 5: PE CALCULATION PACKETS, BIM & QA", [
                          _MenuAction(
                            label: "Stamped PE Calculation Packet & HMAC-SHA256 Seal Verifier",
                            subtitle: "Generate step-by-step AISC/ACI equation dossier with tamper-evident seal",
                            icon: Icons.verified_user_rounded,
                            infoText:
                                'Generates a Professional Engineer (PE) calculation dossier with step-by-step AISC/ACI equations and cryptographic HMAC-SHA256 tamper verification.',
                            onTap: () => widget.onOpenPePacket?.call(),
                          ),
                          _MenuAction(
                            label: "BIM Interoperability & Steel BOM Takeoff (.s2k / IFC 4.3 / .csv)",
                            subtitle: "Export CSI SAP2000/ETABS (.s2k), openBIM IFC 4.3, and steel tonnage schedules",
                            icon: Icons.folder_zip_rounded,
                            infoText:
                                'Full AISC section catalog browser, bill of materials (BOM) steel tonnage takeoff, and SAP2000 (.s2k) / IFC 4.3 export.',
                            onTap: () => widget.onOpenLibrary?.call(),
                          ),
                          if (widget.onOpenShopDrawingAudit != null)
                            _MenuAction(
                              label: "Shop-Drawing & Site Connection Visual QA (ConnectionNet-AI)",
                              subtitle: "Audit fabrication drawings and site photos for AISC Ch. J & ACI Ch. 25 compliance",
                              icon: Icons.assignment_turned_in_rounded,
                              infoText:
                                  'Multimodal inspection of fabrication shop drawings and site photos against AISC 360-16 Chapter J bolt edge/pitch limits and ACI 318-19 rebar hooks.',
                              onTap: () => widget.onOpenShopDrawingAudit?.call(),
                            ),
                          _MenuAction(
                            label: "Embodied Carbon Life-Cycle Assessment (SE 2050 LCA)",
                            subtitle: "Audit cradle-to-gate Global Warming Potential (kg CO2e) & LEED v4.1 credits",
                            icon: Icons.co2_rounded,
                            infoText:
                                'Calculates cradle-to-gate Global Warming Potential (kg CO2e) against SE 2050 structural carbon benchmarks.',
                            onTap: () => widget.onOpenEmbodiedCarbon?.call(),
                          ),
                          if (widget.onOpenCollaborationReview != null)
                            _MenuAction(
                              label: "Real-Time Multi-Engineer Cloud Collaboration & Diff",
                              subtitle: "Share review links, pin 3D comments on joints, and compare revision DCR diffs",
                              icon: Icons.people_alt_rounded,
                              infoText:
                                  'Generate role-based review links (Co-Engineer vs. Viewer), compare model revision DCR diffs, and pin 3D comments directly onto structural joints.',
                              onTap: () => widget.onOpenCollaborationReview?.call(),
                            ),
                        ]),
                      ),
                      const SizedBox(width: 8),

                      // Apple Silicon MPS Neural Surrogate Inspector Pill
                      _HoverableSpecularPill(
                        label: "MAC-TRAINED AI",
                        icon: Icons.memory_rounded,
                        onTap: widget.onOpenMacAiInspector,
                        infoTitle: 'Apple Silicon MPS Neural Surrogate Suite',
                        infoCode: '10 PyTorch / SIMD Engines',
                        infoMessage:
                            'Inspect and benchmark all 10 physics-informed neural networks (StructuraNet-3D, SectionNet-PM, BucklingNet, AeroNet, ConnectionNet) running in <0.2 ms.',
                        trailingBadge: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7EE787).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF7EE787).withValues(alpha: 0.5),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            "MPS • 10 NETS",
                            style: TextStyle(
                              color: Color(0xFF7EE787),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
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
                            const SizedBox(width: 2),
                            const InfoTooltip(
                              title: 'Solver Engine Selector',
                              codeRef: '12-DOF DSM + GNN Surrogate',
                              message:
                                  '• HYBRID DUAL: Runs sub-millisecond GNN surrogate during live dragging and verifies against exact 12-DOF Direct Stiffness Matrix (DSM).\n• STRUCTURANET-3D: Pure neural inference (<0.2 ms).\n• PROPRIETARY DSM: Exact analytical stiffness matrix solver (0.0000% benchmark error).',
                              size: 13,
                            ),
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

                      // 8. Undo / Redo History Controls
                      if (widget.onUndo != null || widget.onRedo != null) ...[
                        GlassPod(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          borderRadius: 16,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'Undo (Ctrl+Z)',
                                child: InkWell(
                                  onTap: widget.canUndo ? widget.onUndo : null,
                                  mouseCursor: widget.canUndo ? SystemMouseCursors.click : SystemMouseCursors.basic,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.undo_rounded,
                                      size: 15,
                                      color: widget.canUndo ? const Color(0xFF00F0FF) : Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Tooltip(
                                message: 'Redo (Ctrl+Y)',
                                child: InkWell(
                                  onTap: widget.canRedo ? widget.onRedo : null,
                                  mouseCursor: widget.canRedo ? SystemMouseCursors.click : SystemMouseCursors.basic,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.redo_rounded,
                                      size: 15,
                                      color: widget.canRedo ? const Color(0xFF00F0FF) : Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // 9. Camera Presets (ISO / TOP / FRONT) & Zoom Controls
                      _buildCameraControls(),
                      const SizedBox(width: 8),

                      // 9. 3D Axis Compass Badge (X • Y • Z)
                      _buildCompassBadge(),
                      const SizedBox(width: 8),

                      // 10. Backend Connection Indicator & Solve Trigger
                      _buildConnectionIndicator(),
                    ],
                  ),
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
          const SizedBox(width: 8),

          // Pinned Cloud Account / Sign-In Capsule (Always visible regardless of horizontal scroll)
          _buildUserProfileButton(),
        ],
      ),
    ),
    ),
    );
  }

  Widget _buildCapsulePill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    String? infoTitle,
    String? infoCode,
    String? infoMessage,
    bool isActiveStage = false,
  }) {
    return _HoverableSpecularPill(
      label: label,
      icon: icon,
      onTap: onTap,
      infoTitle: infoTitle,
      infoCode: infoCode,
      infoMessage: infoMessage,
      trailingBadge: isActiveStage
          ? Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF00F0FF),
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  void _showModalMenu(BuildContext context, String title, List<_MenuAction> actions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
        ),
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
                const SizedBox(width: 6),
                InfoTooltip(
                  title: title,
                  standardOrRange: 'Structura Nexus 5-Stage Pipeline',
                  description:
                      'Click any engineering module row to launch its interactive studio. Hover the (i) icon on any tool for governing design codes and technical details.',
                  size: 14,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: actions
                      .map(
                        (act) => InkWell(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            act.onTap();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 360,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(act.icon, size: 16, color: const Color(0xFF00F0FF)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        act.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (act.subtitle != null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          act.subtitle!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 10,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (act.infoText != null) ...[
                                  const SizedBox(width: 6),
                                  InfoTooltip(
                                    title: act.label,
                                    description: act.infoText!,
                                    size: 14,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onEngineChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    const Color(0xFF1F6FEB).withValues(alpha: 0.70),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.0)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

  Widget _buildQuickStepButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: const Color(0xFF00F0FF).withValues(alpha: 0.15),
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            child: Icon(icon, size: 13, color: const Color(0xFF00F0FF)),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetDropdown() {
    final templates = BuildingGeneratorService.getCertifiedBuildingTemplates();
    int activeIndex = templates.indexWhere((t) =>
        t.id == widget.model.sessionId ||
        widget.model.sessionId.contains(t.id) ||
        widget.model.name.contains(t.title));
    if (activeIndex < 0) activeIndex = 0;

    final currentSample = templates[activeIndex];
    final nextSample = templates[(activeIndex + 1) % templates.length];
    final prevSample = templates[(activeIndex - 1 + templates.length) % templates.length];

    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      borderRadius: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stepper Previous ◀
          _buildQuickStepButton(
            icon: Icons.arrow_back_ios_rounded,
            tooltip: 'Previous Sample: ${prevSample.title}',
            onTap: () => widget.onPresetSelected(prevSample.id),
          ),
          const SizedBox(width: 4),

          // Central Dropdown Pill
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: 'presets',
              isDense: true,
              dropdownColor: const Color(0xFF161F2E),
              icon: const Icon(Icons.keyboard_arrow_down, size: 15, color: Colors.white54),
              items: [
                DropdownMenuItem(
                  value: 'presets',
                  enabled: false,
                  child: Text(
                    'Sample ${(activeIndex + 1).toString().padLeft(2, '0')}/24: ${currentSample.title}',
                    style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const DropdownMenuItem(
                  value: 'open_templates_browser',
                  child: Text(
                    '🏢 Browse All 24 Certified Archetypes...',
                    style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                ...templates.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final t = entry.value;
                  return DropdownMenuItem(
                    value: t.id,
                    child: Text(
                      '$idx. [${t.category}] ${t.title} (${t.codeStandard})',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                if (val != null && val != 'presets') {
                  if (val == 'open_templates_browser') {
                    widget.onOpenBuildingTemplates?.call();
                  } else {
                    widget.onPresetSelected(val);
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 4),

          // Stepper Next ▶
          _buildQuickStepButton(
            icon: Icons.arrow_forward_ios_rounded,
            tooltip: 'Next Sample: ${nextSample.title}',
            onTap: () => widget.onPresetSelected(nextSample.id),
          ),
          const SizedBox(width: 4),

          // InfoTooltip: Sample X / 24 • Next: <Sample Title>
          InfoTooltip(
            title: 'Certified Engineering Sample Library',
            codeRef: 'Sample ${activeIndex + 1} / ${templates.length}',
            message:
                'Sample ${activeIndex + 1} / ${templates.length} • Next: ${nextSample.title}\n\n'
                '• Active Archetype: ${currentSample.title}\n'
                '• Category: ${currentSample.category} • Standard: ${currentSample.codeStandard}\n'
                '• Dimensions: ${currentSample.dimensions}\n'
                '• Framing: ${currentSample.structuralSystem}\n'
                '• Mesh: ${currentSample.nodeCount} Joints, ${currentSample.memberCount} Members\n\n'
                'Click ◀ or ▶ to quick-cycle between all 24 certified building, bridge, long-span & seismic archetypes.',
            size: 13,
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcherPill() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      borderRadius: 16,
      glowColor: widget.isEssentialMode
          ? const Color(0xFF10B981).withValues(alpha: 0.2)
          : const Color(0xFFA855F7).withValues(alpha: 0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: widget.isEssentialMode ? null : widget.onToggleWorkspaceMode,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isEssentialMode ? const Color(0xFF10B981) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 13,
                    color: widget.isEssentialMode ? Colors.black : Colors.white60,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "ESSENTIAL",
                    style: TextStyle(
                      color: widget.isEssentialMode ? Colors.black : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 3),
          InkWell(
            onTap: !widget.isEssentialMode ? null : widget.onToggleWorkspaceMode,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: !widget.isEssentialMode ? const Color(0xFFA855F7) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.rocket_launch_rounded,
                    size: 13,
                    color: !widget.isEssentialMode ? Colors.white : Colors.white60,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "PRO SUITE",
                    style: TextStyle(
                      color: !widget.isEssentialMode ? Colors.white : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          InfoTooltip(
            title: widget.isEssentialMode ? 'Essential Mode (Daily Engineering)' : 'Pro Suite Mode (Frontier Research)',
            codeRef: widget.isEssentialMode ? 'AISC 360 • ACI 318 • ASCE 7' : 'WebGPU • NLTHA • CFD • GNN',
            message: widget.isEssentialMode
                ? 'Essential Mode streamlines the interface to core daily engineering workflows: 3D Framing, 6-DOF Supports, ASCE 7 Loads, 12-DOF FEA Solve, AISC/ACI Checks, and PE Packet / BIM export.\n\nClick "PRO SUITE" to unlock advanced frontier modules.'
                : 'Pro Suite Mode unlocks all advanced research capsules: 4-Agent Autonomous Swarm, WebGPU Pareto Explorer, AeroNet Wind Tunnel CFD, Non-Linear Time History (NLTHA), and Progressive Collapse.',
            size: 13,
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayModeSelector() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      borderRadius: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
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
          const SizedBox(width: 2),
          const InfoTooltip(
            title: '3D Viewport Visualization Mode',
            codeRef: 'Three.js WebGL GPU',
            message:
                '• Geometry Skeleton: Undisplaced structural wireframe & profiles\n• Deformed Mesh: Elastic deflected shape {u}\n• SFD / BMD Ribbons: 3D extruded Shear & Bending Moment diagrams\n• AISC 360-16 DCR Envelope: Pass (Green) / Warn (Amber) / Fail (Red) stress heatmap.',
            size: 13,
          ),
        ],
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
              const SizedBox(width: 3),
              const InfoTooltip(
                title: 'Elastic Deflection Magnification',
                codeRef: 'Visual Amplification Factor',
                message:
                    'Multiplies true nodal displacements (ux, uy, uz) by 1× to 100× in the 3D viewport so subtle millimeter-level deflections and sway curvature are clearly visible.',
                size: 12.5,
              ),
              const SizedBox(width: 6),
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
      mouseCursor: SystemMouseCursors.click,
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
          const SizedBox(width: 4),
          const InfoTooltip(
            title: 'Graphics Pipeline Switcher',
            codeRef: 'Three.js WebGL vs CustomPainter',
            message:
                'Switches between hardware-accelerated Three.js 3D WebGL rendering (with PBR lighting, release rings, and cracked sleeves) and crisp 2.5D vector projection.',
            size: 13,
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
        mouseCursor: SystemMouseCursors.click,
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
        mouseCursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
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
          SizedBox(width: 4),
          InfoTooltip(
            title: '3D Structural Coordinate Convention',
            codeRef: 'Right-Hand Cartesian Axes',
            message:
                '• X (Red): Lateral horizontal bay span (East-West)\n• Y (Green): Vertical elevation / story height (Upward +Y)\n• Z (Cyan): Transverse depth span (North-South).',
            size: 13,
          ),
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
          const SizedBox(width: 4),
          const InfoTooltip(
            title: 'Dual Cloud & In-Browser FEA Runtime',
            codeRef: '100% Offline Capable',
            message:
                'Click to trigger an immediate 12-DOF matrix solve. Even when offline, the embedded pure-Dart 12-DOF Direct Stiffness solver and all 10 SIMD neural networks run locally at 0.0000% error.',
            size: 13,
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileButton() {
    final user = FirebaseAuthService().currentUser;
    final isDemo = WorkspacePreferences.getBool('demo_authenticated', false);
    final isLoggedIn = user != null || isDemo;
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return GlassPod(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: 7,
      ),
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
          if (!isCompact) ...[
            const SizedBox(width: 6),
            Text(
              isLoggedIn
                  ? (isDemo
                      ? 'Verified PE Engineer'
                      : (user?.isAnonymous ?? false
                          ? 'Guest Engineer'
                          : (user?.displayName ?? user?.email?.split('@').first ?? 'Account')))
                  : 'Cloud / Sign In',
              style: TextStyle(
                color: isLoggedIn ? const Color(0xFF3FB950) : const Color(0xFF58A6FF),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuAction {
  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? infoText;

  const _MenuAction({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.infoText,
  });
}

class _HoverableSpecularPill extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailingBadge;
  final String? infoTitle;
  final String? infoCode;
  final String? infoMessage;

  const _HoverableSpecularPill({
    required this.label,
    required this.icon,
    this.onTap,
    this.trailingBadge,
    this.infoTitle,
    this.infoCode,
    this.infoMessage,
  });

  @override
  State<_HoverableSpecularPill> createState() => _HoverableSpecularPillState();
}

class _HoverableSpecularPillState extends State<_HoverableSpecularPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GlassPod(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        borderRadius: 18,
        onTap: widget.onTap,
        glowColor: _isHovered ? Colors.white.withValues(alpha: 0.35) : null,
        baseColor: _isHovered ? const Color(0xFF1E2838) : const Color(0xFF0C1322),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: _isHovered
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0.10),
                    ],
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: const Color(0xFF00F0FF)),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.trailingBadge != null) ...[
                const SizedBox(width: 6),
                widget.trailingBadge!,
              ] else ...[
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 14,
                  color: _isHovered ? Colors.white : Colors.white38,
                ),
              ],
              if (widget.infoMessage != null) ...[
                const SizedBox(width: 2),
                InfoTooltip(
                  title: widget.infoTitle ?? widget.label,
                  codeRef: widget.infoCode,
                  message: widget.infoMessage!,
                  size: 12.5,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
