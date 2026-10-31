// ============================================================================
// SlideableWorkspaceMenu — Customizable, Pronounced Slideable Engineering Side Menu
// Open-in-place toggle, slideable vertical drag, persistent positioning across sessions
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../services/workspace_storage.dart';
import 'glass_pod.dart';
import 'info_tooltip.dart';

class SlideableWorkspaceMenu extends StatefulWidget {
  final String workspaceKey;
  final double initialTop;
  final bool initialExpanded;
  final VoidCallback? onOpenCopilot;
  final VoidCallback? onOpenGenerativeOptimizer;
  final VoidCallback? onOpenGenerativeBracing;
  final VoidCallback? onOptimize;
  final VoidCallback? onOpenCadStudio;
  final VoidCallback? onOpenLibrary;
  final VoidCallback? onOpenConcreteStudio;
  final VoidCallback? onOpenSteelConnections;
  final VoidCallback? onOpenGeotechnicalFoundation;
  final VoidCallback? onOpenCompositeFloor;
  final VoidCallback? onOpenSeismicModal;
  final VoidCallback? onOpenLateralStability;
  final VoidCallback? onOpenPushoverAnalysis;
  final VoidCallback? onOpenWindCfd;
  final VoidCallback? onOpenPePacket;
  final VoidCallback? onOpenEmbodiedCarbon;
  final VoidCallback? onOpenEnvironmentalStimulator;
  final VoidCallback? onOpenVisionToBim;
  final VoidCallback? onOpenNltha;
  final ValueChanged<String>? onPresetSelected;
  final VoidCallback? onSolveTriggered;

  const SlideableWorkspaceMenu({
    super.key,
    this.workspaceKey = 'main_workstation',
    this.initialTop = 76.0,
    this.initialExpanded = false,
    this.onOpenCopilot,
    this.onOpenGenerativeOptimizer,
    this.onOpenGenerativeBracing,
    this.onOptimize,
    this.onOpenCadStudio,
    this.onOpenLibrary,
    this.onOpenConcreteStudio,
    this.onOpenSteelConnections,
    this.onOpenGeotechnicalFoundation,
    this.onOpenCompositeFloor,
    this.onOpenSeismicModal,
    this.onOpenLateralStability,
    this.onOpenPushoverAnalysis,
    this.onOpenWindCfd,
    this.onOpenPePacket,
    this.onOpenEmbodiedCarbon,
    this.onOpenEnvironmentalStimulator,
    this.onOpenVisionToBim,
    this.onOpenNltha,
    this.onPresetSelected,
    this.onSolveTriggered,
  });

  @override
  State<SlideableWorkspaceMenu> createState() => SlideableWorkspaceMenuState();
}

class _ToolDef {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String category;
  final VoidCallback? onTap;
  final String? badge;

  const _ToolDef({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    required this.onTap,
    this.badge,
  });
}

class SlideableWorkspaceMenuState extends State<SlideableWorkspaceMenu> {
  late double _topOffset;
  late bool _isExpanded;
  late String _dockSide;
  late double _panelWidth;
  late bool _isSolidContrast;

  bool _showCustomizer = false;
  String _activeCategory = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _hoveredTool;

  @override
  void initState() {
    super.initState();
    _topOffset = WorkspacePreferences.getDouble(
      '${widget.workspaceKey}_top_offset',
      widget.initialTop,
    );
    _isExpanded = WorkspacePreferences.getBool(
      '${widget.workspaceKey}_is_expanded',
      widget.initialExpanded,
    );
    _dockSide = WorkspacePreferences.getString(
      '${widget.workspaceKey}_dock_side',
      'left',
    );
    _panelWidth = WorkspacePreferences.getDouble(
      '${widget.workspaceKey}_panel_width',
      310.0,
    );
    _isSolidContrast = WorkspacePreferences.getBool(
      '${widget.workspaceKey}_solid_contrast',
      true,
    );

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _showCustomizer = false;
        _searchController.clear();
      }
    });
    WorkspacePreferences.setBool('${widget.workspaceKey}_is_expanded', _isExpanded);
  }

  void openMenu() {
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
      WorkspacePreferences.setBool('${widget.workspaceKey}_is_expanded', true);
    }
  }

  void closeMenu() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _showCustomizer = false;
      });
      WorkspacePreferences.setBool('${widget.workspaceKey}_is_expanded', false);
    }
  }

  void _updateTopOffset(double delta, double maxTop) {
    setState(() {
      _topOffset = (_topOffset + delta).clamp(60.0, maxTop);
    });
    WorkspacePreferences.setDouble('${widget.workspaceKey}_top_offset', _topOffset);
  }

  void _setDockSide(String side) {
    setState(() => _dockSide = side);
    WorkspacePreferences.setString('${widget.workspaceKey}_dock_side', side);
  }

  void _setPanelWidth(double width) {
    setState(() => _panelWidth = width);
    WorkspacePreferences.setDouble('${widget.workspaceKey}_panel_width', width);
  }

  void _toggleContrast(bool solid) {
    setState(() => _isSolidContrast = solid);
    WorkspacePreferences.setBool('${widget.workspaceKey}_solid_contrast', solid);
  }

  void _resetLayout() {
    setState(() {
      _topOffset = widget.initialTop;
      _dockSide = 'left';
      _panelWidth = 310.0;
      _isSolidContrast = true;
      _showCustomizer = false;
    });
    WorkspacePreferences.setDouble('${widget.workspaceKey}_top_offset', widget.initialTop);
    WorkspacePreferences.setString('${widget.workspaceKey}_dock_side', 'left');
    WorkspacePreferences.setDouble('${widget.workspaceKey}_panel_width', 310.0);
    WorkspacePreferences.setBool('${widget.workspaceKey}_solid_contrast', true);
  }

  List<_ToolDef> get _allTools => [
    // 1. AI & GENERATIVE
    _ToolDef(
      label: 'AI Structural Copilot',
      subtitle: 'Gemini 1.5 Pro Autonomous Agent',
      icon: Icons.psychology_rounded,
      color: const Color(0xFF00F0FF),
      category: 'AI & GEN',
      onTap: widget.onOpenCopilot,
      badge: 'GEMINI',
    ),
    _ToolDef(
      label: 'Generative Opt Auto-Sizer',
      subtitle: 'Neural Profile Sizing & GNN',
      icon: Icons.hub_rounded,
      color: const Color(0xFF10B981),
      category: 'AI & GEN',
      onTap: widget.onOpenGenerativeOptimizer,
      badge: 'GNN',
    ),
    _ToolDef(
      label: 'Generative Bracing',
      subtitle: 'Pareto Topology & Lateral Stiffening',
      icon: Icons.auto_awesome_rounded,
      color: Colors.purpleAccent,
      category: 'AI & GEN',
      onTap: widget.onOpenGenerativeBracing,
      badge: 'SYNTHESIS',
    ),
    _ToolDef(
      label: 'AISC Section Auto-Sizer',
      subtitle: 'Weight Minimization & Governing DCR',
      icon: Icons.tune_rounded,
      color: const Color(0xFF10B981),
      category: 'AI & GEN',
      onTap: widget.onOptimize,
      badge: 'AISC 360',
    ),

    // 2. MODELING, CAD & BIM
    _ToolDef(
      label: 'Structural CAD Studio',
      subtitle: '2D & 3D Drafting / Frame Modeler',
      icon: Icons.architecture_rounded,
      color: const Color(0xFFF59E0B),
      category: 'CAD & BIM',
      onTap: widget.onOpenCadStudio,
      badge: '3D/2D',
    ),
    _ToolDef(
      label: 'Vision-to-BIM Floorplan',
      subtitle: 'AI Spatial Ingestion (.png/.jpg)',
      icon: Icons.document_scanner_rounded,
      color: const Color(0xFF00F0FF),
      category: 'CAD & BIM',
      onTap: widget.onOpenVisionToBim,
      badge: 'VISION',
    ),
    _ToolDef(
      label: 'Structural Library & BIM',
      subtitle: 'AISC Catalog & DXF / IFC 4.3 Export',
      icon: Icons.folder_special_rounded,
      color: const Color(0xFFA855F7),
      category: 'CAD & BIM',
      onTap: widget.onOpenLibrary,
      badge: 'DXF/IFC',
    ),
    _ToolDef(
      label: 'Concrete Studio (ACI 318)',
      subtitle: 'SectionNet Fiber P-M (<0.2ms)',
      icon: Icons.view_in_ar_rounded,
      color: const Color(0xFF00F0FF),
      category: 'CAD & BIM',
      onTap: widget.onOpenConcreteStudio,
      badge: 'ACI 318',
    ),
    _ToolDef(
      label: 'Steel Connection Studio',
      subtitle: 'Moment, Shear Tabs & Base Plates',
      icon: Icons.hardware_rounded,
      color: const Color(0xFFF59E0B),
      category: 'CAD & BIM',
      onTap: widget.onOpenSteelConnections,
      badge: 'AISC 360',
    ),
    _ToolDef(
      label: 'Foundation SSI Studio',
      subtitle: 'Soil Springs & Punching Shear',
      icon: Icons.terrain_rounded,
      color: const Color(0xFF10B981),
      category: 'CAD & BIM',
      onTap: widget.onOpenGeotechnicalFoundation,
      badge: 'WINKLER',
    ),
    _ToolDef(
      label: 'Composite Floor Studio',
      subtitle: 'Shear Studs & Walking Vibrations',
      icon: Icons.layers_rounded,
      color: const Color(0xFF14B8A6),
      category: 'CAD & BIM',
      onTap: widget.onOpenCompositeFloor,
      badge: 'DG 11',
    ),

    // 3. ANALYSIS & SIMULATION
    _ToolDef(
      label: 'Dynamic Modal Vibration',
      subtitle: 'Eigenmodes & Resonance Spectrum',
      icon: Icons.waves_rounded,
      color: const Color(0xFF38BDF8),
      category: 'ANALYSIS',
      onTap: widget.onOpenSeismicModal,
      badge: 'ASCE 7',
    ),
    _ToolDef(
      label: 'Lateral Stability Engine',
      subtitle: 'ASCE 7 Wind & [Kg] Buckling',
      icon: Icons.sync_alt_rounded,
      color: const Color(0xFFE11D48),
      category: 'ANALYSIS',
      onTap: widget.onOpenLateralStability,
      badge: 'P-DELTA',
    ),
    _ToolDef(
      label: 'Dynamic NLTHA Player',
      subtitle: 'Non-Linear Time History Timeline',
      icon: Icons.movie_filter_rounded,
      color: const Color(0xFF00F0FF),
      category: 'ANALYSIS',
      onTap: widget.onOpenNltha,
      badge: 'NLTHA',
    ),
    _ToolDef(
      label: 'Pushover Capacity Spectrum',
      subtitle: 'ATC-40 PBEE Performance Point',
      icon: Icons.stacked_line_chart_rounded,
      color: const Color(0xFF00F0FF),
      category: 'ANALYSIS',
      onTap: widget.onOpenPushoverAnalysis,
      badge: 'PBEE',
    ),
    _ToolDef(
      label: 'Wind Tunnel CFD Studio',
      subtitle: 'AeroNet Corner Suctions & Strouhal',
      icon: Icons.air_rounded,
      color: const Color(0xFF06B6D4),
      category: 'ANALYSIS',
      onTap: widget.onOpenWindCfd,
      badge: 'CFD',
    ),
    _ToolDef(
      label: 'PE Calculation Packet',
      subtitle: 'Stamped PDF Engineering Seal',
      icon: Icons.picture_as_pdf_rounded,
      color: const Color(0xFF00F0FF),
      category: 'ANALYSIS',
      onTap: widget.onOpenPePacket,
      badge: 'SEAL',
    ),
    _ToolDef(
      label: 'Embodied Carbon LCA',
      subtitle: 'SE 2050 Global Warming Potential',
      icon: Icons.co2_rounded,
      color: const Color(0xFF34D399),
      category: 'ANALYSIS',
      onTap: widget.onOpenEmbodiedCarbon,
      badge: 'LCA',
    ),
    _ToolDef(
      label: 'Dynamic Multi-Hazard Stimulator',
      subtitle: 'Live 3D Ground Motion & Vortex',
      icon: Icons.cyclone_rounded,
      color: const Color(0xFFFF5252),
      category: 'ANALYSIS',
      onTap: widget.onOpenEnvironmentalStimulator,
      badge: 'LIVE 3D',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 700;
    final maxTop = (screenSize.height - 220.0).clamp(80.0, 1000.0);
    final clampedTop = _topOffset.clamp(60.0, maxTop);

    final isLeft = _dockSide == 'left';
    final effectiveWidth = isCompact ? (screenSize.width - 24).clamp(240.0, 360.0) : _panelWidth;

    return Positioned(
      top: clampedTop,
      left: isLeft ? 12 : null,
      right: !isLeft ? 12 : null,
      child: Material(
        color: Colors.transparent,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                alignment: Alignment(isLeft ? -1.0 : 1.0, 0.0),
                child: child,
              ),
            );
          },
          child: _isExpanded
              ? _buildExpandedMenu(context, effectiveWidth, screenSize.height - clampedTop - 110.0)
              : _buildCollapsedPill(context, isLeft, maxTop),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Collapsed State: Pronounced, slideable toggle handle
  // --------------------------------------------------------------------------
  Widget _buildCollapsedPill(BuildContext context, bool isLeft, double maxTop) {
    return MouseRegion(
      onEnter: (_) => WorkspacePreferences.freezeOrbit(true),
      onExit: (_) => WorkspacePreferences.freezeOrbit(false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (_) {},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) => _updateTopOffset(details.delta.dy, maxTop),
          child: Container(
            key: const ValueKey('collapsed_toggle_pill'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.75),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: GlassPod(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              borderRadius: 16,
              glowColor: const Color(0xFF00F0FF),
              onTap: toggleExpanded,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Slideable tactile drag grip
                  Tooltip(
                    message: 'Slideable menu handle. Drag vertically to position; click to open menu.',
                    waitDuration: Duration.zero,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.drag_indicator_rounded,
                        size: 16,
                        color: Color(0xFF00F0FF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.menu_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  const Text(
                    'WORKSPACE TOOLS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4), width: 0.5),
                    ),
                    child: const Text(
                      'MENU',
                      style: TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isLeft ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
                    size: 13,
                    color: const Color(0xFF00F0FF),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Expanded State: Full slideable, pronounced, customizable menu panel
  // --------------------------------------------------------------------------
  Widget _buildExpandedMenu(BuildContext context, double width, double maxHeight) {
    final height = maxHeight.clamp(260.0, 680.0);
    final isLeft = _dockSide == 'left';

    final filtered = _allTools.where((t) {
      final matchesCategory = _activeCategory == 'ALL' || t.category == _activeCategory;
      if (!matchesCategory) return false;
      if (_searchQuery.isEmpty) return true;
      return t.label.toLowerCase().contains(_searchQuery) ||
          t.subtitle.toLowerCase().contains(_searchQuery) ||
          t.category.toLowerCase().contains(_searchQuery) ||
          (t.badge != null && t.badge!.toLowerCase().contains(_searchQuery));
    }).toList();

    return MouseRegion(
      onEnter: (_) => WorkspacePreferences.freezeOrbit(true),
      onExit: (_) => WorkspacePreferences.freezeOrbit(false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (_) {},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            key: const ValueKey('expanded_workspace_menu'),
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _isSolidContrast
                  ? const Color(0xFF090D16).withValues(alpha: 0.98)
                  : const Color(0xFF0C1322).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.40),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.85),
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.20),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                children: [
                  // 1. Pronounced Top Drag Header
                  _buildTopDragHeader(context, isLeft),

                  // 2. Customization Toolbar (Slide-down options)
                  if (_showCustomizer) _buildCustomizerBar(),

                  // 3. Search & Filter Bar
                  _buildSearchBar(),

                  // 4. Category Pills
                  _buildCategorySelector(),

                  const SizedBox(height: 4),
                  GlassPod.divider(),

                  // 5. Scrollable Tool Items
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off_rounded, color: Colors.white38, size: 28),
                                const SizedBox(height: 6),
                                const Text(
                                  'No matching tools in this category',
                                  style: TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _activeCategory = 'ALL');
                                  },
                                  child: const Text('Reset Search & Filter', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11)),
                                ),
                              ],
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) => true,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              physics: const ClampingScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) => _buildToolRow(filtered[i]),
                            ),
                          ),
                  ),

                  // 6. Bottom Benchmark Presets & Solvers
                  _buildFooterActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Header with Tactile Drag Grip, Title, Customizer & Collapse Button
  // --------------------------------------------------------------------------
  Widget _buildTopDragHeader(BuildContext context, bool isLeft) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxTop = (screenSize.height - 220.0).clamp(80.0, 1000.0);

    return GestureDetector(
      onVerticalDragUpdate: (details) => _updateTopOffset(details.delta.dy, maxTop),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF131A29),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10), width: 1),
          ),
        ),
        child: Row(
          children: [
            // Slideable Tactile Handle
            Tooltip(
              message: 'Drag to slide vertically. Position is remembered.',
              waitDuration: Duration.zero,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.drag_indicator_rounded,
                  size: 16,
                  color: Color(0xFF00F0FF),
                ),
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: Text(
                          'WORKSPACE TOOLS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4), width: 0.5),
                        ),
                        child: const Text(
                          'MENU',
                          style: TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Slideable • Drag to move',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 9.0,
                    ),
                  ),
                ],
              ),
            ),

            const InfoTooltip(
              message: 'Customizable & slideable workspace menu. Drag to move, customize dock side and size.',
              size: 16,
            ),
            const SizedBox(width: 4),

            // Customize settings toggle
            IconButton(
              icon: Icon(
                _showCustomizer ? Icons.tune_rounded : Icons.tune_outlined,
                size: 17,
                color: _showCustomizer ? const Color(0xFF00F0FF) : Colors.white70,
              ),
              tooltip: 'Customize Menu (Dock side, width, contrast, reset)',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => setState(() => _showCustomizer = !_showCustomizer),
            ),

            const SizedBox(width: 2),

            // Collapse Button (closes menu, restoring the collapsed toggle pill)
            IconButton(
              icon: Icon(
                isLeft ? Icons.keyboard_double_arrow_left_rounded : Icons.keyboard_double_arrow_right_rounded,
                size: 18,
                color: Colors.white70,
              ),
              tooltip: 'Collapse Menu',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: toggleExpanded,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Customization Toolbar
  // --------------------------------------------------------------------------
  Widget _buildCustomizerBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1624),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.25), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.tune_rounded, size: 13, color: Color(0xFF00F0FF)),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'CUSTOMIZE MENU',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Group 1: Dock Side & Width
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('DOCK SIDE:', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.bold)),
              _buildOptionPill(
                label: 'LEFT',
                isSelected: _dockSide == 'left',
                onTap: () => _setDockSide('left'),
              ),
              _buildOptionPill(
                label: 'RIGHT',
                isSelected: _dockSide == 'right',
                onTap: () => _setDockSide('right'),
              ),
              const SizedBox(width: 2),
              Text('WIDTH:', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.bold)),
              _buildOptionPill(
                label: '260',
                isSelected: _panelWidth == 260.0,
                onTap: () => _setPanelWidth(260.0),
              ),
              _buildOptionPill(
                label: '310',
                isSelected: _panelWidth == 310.0,
                onTap: () => _setPanelWidth(310.0),
              ),
              _buildOptionPill(
                label: '380',
                isSelected: _panelWidth == 380.0,
                onTap: () => _setPanelWidth(380.0),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Group 2: Contrast & Reset
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('CONTRAST:', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.bold)),
              _buildOptionPill(
                label: 'SOLID 98%',
                isSelected: _isSolidContrast,
                onTap: () => _toggleContrast(true),
              ),
              _buildOptionPill(
                label: 'FROST 92%',
                isSelected: !_isSolidContrast,
                onTap: () => _toggleContrast(false),
              ),
              const SizedBox(width: 2),
              InkWell(
                onTap: _resetLayout,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 0.5),
                  ),
                  child: const Text(
                    'RESET DEFAULT',
                    style: TextStyle(color: Colors.redAccent, fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF1E2638),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white12,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 8.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Instant Search Bar
  // --------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF141B2B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _searchQuery.isNotEmpty
                ? const Color(0xFF00F0FF).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 11.5),
          decoration: InputDecoration(
            hintText: 'Search engineering tools...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
            prefixIcon: const Icon(Icons.search_rounded, size: 15, color: Color(0xFF00F0FF)),
            prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 14, color: Colors.white70),
                    padding: EdgeInsets.zero,
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Category Selection Tabs
  // --------------------------------------------------------------------------
  Widget _buildCategorySelector() {
    final categories = ['ALL', 'AI & GEN', 'CAD & BIM', 'ANALYSIS'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: categories.map((cat) {
          final isSel = _activeCategory == cat;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => setState(() => _activeCategory = cat),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF00F0FF) : const Color(0xFF141B2B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSel ? const Color(0xFF00F0FF) : Colors.white10,
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSel ? Colors.black : Colors.white70,
                        fontSize: 9,
                        fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Individual Tool Item Row
  // --------------------------------------------------------------------------
  Widget _buildToolRow(_ToolDef tool) {
    final isHovered = _hoveredTool == tool.label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredTool = tool.label),
        onExit: (_) => setState(() => _hoveredTool = null),
        child: InkWell(
          onTap: () {
            tool.onTap?.call();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6.5),
            decoration: BoxDecoration(
              color: isHovered
                  ? const Color(0xFF1E283D)
                  : const Color(0xFF121927).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isHovered
                    ? tool.color.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                // Glowing Icon Pod
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tool.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: tool.color.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(tool.icon, size: 15, color: tool.color),
                ),
                const SizedBox(width: 8),

                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tool.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        tool.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tool Badge
                if (tool.badge != null)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: tool.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: tool.color.withValues(alpha: 0.45),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      tool.badge!,
                      style: TextStyle(
                        color: tool.color,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Bottom Footer with Benchmark Presets & Solver Trigger
  // --------------------------------------------------------------------------
  Widget _buildFooterActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1522),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onSolveTriggered,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F0FF), Color(0xFF0072FF)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.bolt_rounded, size: 14, color: Colors.black),
                        SizedBox(width: 4),
                        Text(
                          'FEA SOLVE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                tooltip: 'Load Benchmark Presets',
                onSelected: (key) => widget.onPresetSelected?.call(key),
                color: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                ),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'sway',
                    child: Text('Multi-Story Sway Frame', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                  const PopupMenuItem(
                    value: 'truss',
                    child: Text('Warren Bridge Truss', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                  const PopupMenuItem(
                    value: 'cantilever',
                    child: Text('Timoshenko Cantilever', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E283D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bookmarks_outlined, size: 13, color: Color(0xFF00F0FF)),
                      SizedBox(width: 4),
                      Text(
                        'PRESETS',
                        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.arrow_drop_down, size: 14, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
