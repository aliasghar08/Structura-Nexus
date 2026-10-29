// ============================================================================
// WorkstationSidebar — Left Engineering Navigation & Tool Suite
// AI Copilot, Generative Optimizer, CAD Studio, Modal Dynamics, PE Calcs
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';

class WorkstationSidebar extends StatefulWidget {
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
  final bool initialExpanded;

  const WorkstationSidebar({
    super.key,
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
    this.initialExpanded = true,
  });

  @override
  State<WorkstationSidebar> createState() => _WorkstationSidebarState();
}

class _SidebarToolDef {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String category;
  final VoidCallback? onTap;
  final String? badge;

  const _SidebarToolDef({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    required this.onTap,
    this.badge,
  });
}

class _WorkstationSidebarState extends State<WorkstationSidebar> {
  late bool _isExpanded;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _hoveredTool;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
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

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _searchController.clear();
      }
    });
  }

  List<_SidebarToolDef> get _allTools => [
    // AI & GENERATIVE
    _SidebarToolDef(
      label: 'AI Copilot',
      subtitle: 'Gemini 1.5 Pro Structural Agent',
      icon: Icons.psychology_rounded,
      color: const Color(0xFF00F0FF),
      category: 'AI & GENERATIVE',
      onTap: widget.onOpenCopilot,
      badge: 'GEMINI',
    ),
    _SidebarToolDef(
      label: 'Generative Opt',
      subtitle: 'Neural Profile Auto-Sizer',
      icon: Icons.hub_rounded,
      color: const Color(0xFF10B981),
      category: 'AI & GENERATIVE',
      onTap: widget.onOpenGenerativeOptimizer,
      badge: 'GNN',
    ),
    _SidebarToolDef(
      label: 'Gen Bracing',
      subtitle: 'Automated Topology Placement',
      icon: Icons.auto_awesome_rounded,
      color: Colors.purpleAccent,
      category: 'AI & GENERATIVE',
      onTap: widget.onOpenGenerativeBracing,
    ),
    _SidebarToolDef(
      label: 'Auto-Sizer',
      subtitle: 'AISC 360 Weight Minimizer',
      icon: Icons.tune_rounded,
      color: const Color(0xFF10B981),
      category: 'AI & GENERATIVE',
      onTap: widget.onOptimize,
      badge: 'AISC',
    ),

    // MODELING & CAD
    _SidebarToolDef(
      label: 'CAD Studio',
      subtitle: '2D / 3D Parametric Framing',
      icon: Icons.architecture_rounded,
      color: const Color(0xFFF59E0B),
      category: 'MODELING & CAD',
      onTap: widget.onOpenCadStudio,
      badge: '3D/2D',
    ),
    _SidebarToolDef(
      label: 'Cloud Library',
      subtitle: 'AISC Catalog & DXF / BOM Export',
      icon: Icons.folder_special_rounded,
      color: const Color(0xFFA855F7),
      category: 'MODELING & CAD',
      onTap: widget.onOpenLibrary,
      badge: 'DXF',
    ),
    _SidebarToolDef(
      label: 'Concrete Studio',
      subtitle: 'SectionNet-PM Fiber P-M (<0.2ms)',
      icon: Icons.architecture,
      color: const Color(0xFF00F0FF),
      category: 'MODELING & CAD',
      onTap: widget.onOpenConcreteStudio,
      badge: 'ACI 318',
    ),
    _SidebarToolDef(
      label: 'Steel Connections',
      subtitle: 'Shear Tabs, End & Base Plates',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFF59E0B),
      category: 'MODELING & CAD',
      onTap: widget.onOpenSteelConnections,
      badge: 'AISC 360',
    ),
    _SidebarToolDef(
      label: 'Foundation & SSI',
      subtitle: 'Spread Footings & Soil Springs',
      icon: Icons.foundation_rounded,
      color: const Color(0xFF10B981),
      category: 'MODELING & CAD',
      onTap: widget.onOpenGeotechnicalFoundation,
      badge: 'WINKLER',
    ),
    _SidebarToolDef(
      label: 'Composite Floor',
      subtitle: 'Shear Studs & Walking Vibration',
      icon: Icons.layers_rounded,
      color: const Color(0xFF14B8A6),
      category: 'MODELING & CAD',
      onTap: widget.onOpenCompositeFloor,
      badge: 'DG 11',
    ),

    // ANALYSIS & DESIGN
    _SidebarToolDef(
      label: 'Modal Seismic',
      subtitle: 'Dynamic Frequency & Vibrations',
      icon: Icons.waves_rounded,
      color: const Color(0xFF38BDF8),
      category: 'ANALYSIS & DESIGN',
      onTap: widget.onOpenSeismicModal,
    ),
    _SidebarToolDef(
      label: 'Lateral Stability',
      subtitle: 'ASCE 7 Wind & Seismic Hazards',
      icon: Icons.shield_outlined,
      color: const Color(0xFFE11D48),
      category: 'ANALYSIS & DESIGN',
      onTap: widget.onOpenLateralStability,
      badge: 'ASCE 7',
    ),
    _SidebarToolDef(
      label: 'Non-Linear Pushover',
      subtitle: 'ASCE 41 Capacity Spectrum ADRS',
      icon: Icons.stacked_line_chart_rounded,
      color: const Color(0xFF00F0FF),
      category: 'ANALYSIS & DESIGN',
      onTap: widget.onOpenPushoverAnalysis,
      badge: 'PBEE',
    ),
    _SidebarToolDef(
      label: 'Wind Tunnel CFD',
      subtitle: 'AeroNet Corner Suctions & Strouhal',
      icon: Icons.air_rounded,
      color: const Color(0xFF06B6D4),
      category: 'ANALYSIS & DESIGN',
      onTap: widget.onOpenWindCfd,
      badge: 'CFD',
    ),
    _SidebarToolDef(
      label: 'PE Calcs & BIM',
      subtitle: 'AISC / IBC Stamped Calc Packet',
      icon: Icons.picture_as_pdf_rounded,
      color: const Color(0xFF00F0FF),
      category: 'ANALYSIS & DESIGN',
      onTap: widget.onOpenPePacket,
      badge: 'SEAL',
    ),
    _SidebarToolDef(
      label: 'Embodied Carbon',
      subtitle: 'Life Cycle Assessment (LCA CO₂e)',
      icon: Icons.eco_rounded,
      color: const Color(0xFF34D399),
      category: 'ANALYSIS & DESIGN',
      onTap: widget.onOpenEmbodiedCarbon,
      badge: 'LCA',
    ),
    _SidebarToolDef(
      label: 'Dynamic Stimulator',
      subtitle: 'Multi-Hazard Real-Time Shaking & Wind',
      icon: Icons.thunderstorm_rounded,
      color: const Color(0xFFFF5252),
      category: 'ANALYSIS & DESIGN',
      onTap: widget.onOpenEnvironmentalStimulator,
      badge: 'LIVE 3D',
    ),
  ];

  void _showShortcutsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        title: Row(
          children: const [
            Icon(Icons.keyboard_outlined, color: Color(0xFF00F0FF), size: 22),
            SizedBox(width: 10),
            Text(
              'Workstation Navigation & Shortcuts',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShortcutRow('Orbit 3D Viewport', 'Click & Drag anywhere on canvas'),
              _buildShortcutRow('Pan Viewport', 'Two-finger Drag or Right Click'),
              _buildShortcutRow('Zoom In / Out', 'Mouse Scroll Wheel or Pinch gesture'),
              _buildShortcutRow('Morph Realtime Geometry', 'Click & Drag any 3D node ball'),
              _buildShortcutRow('Inspect Member / Node', 'Single click on any element'),
              _buildShortcutRow('Re-run Finite Element Solve', 'Click Live Engine in header'),
              const Divider(color: Colors.white12, height: 24),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Real-time GNN Surrogate operates at < 0.4ms latency',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got It', style: TextStyle(color: Color(0xFF00F0FF))),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = _isExpanded ? 220.0 : 64.0;

    final filteredTools = _searchQuery.isEmpty
        ? _allTools
        : _allTools.where((t) {
            return t.label.toLowerCase().contains(_searchQuery) ||
                t.subtitle.toLowerCase().contains(_searchQuery) ||
                t.category.toLowerCase().contains(_searchQuery) ||
                (t.badge != null && t.badge!.toLowerCase().contains(_searchQuery));
          }).toList();

    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          border: Border(
            right: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Sidebar Top Header
            Container(
              height: 48,
              padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 10 : 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF161B22),
                    Color(0xFF0D1117),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
                ),
              ),
              child: _isExpanded
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00F0FF),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'TOOLS & SUITE',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            icon: const Icon(
                              Icons.keyboard_double_arrow_left_rounded,
                              color: Colors.white54,
                              size: 18,
                            ),
                            tooltip: 'Collapse Menu',
                            padding: EdgeInsets.zero,
                            onPressed: _toggleExpanded,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          icon: const Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            color: Colors.white54,
                            size: 18,
                          ),
                          tooltip: 'Expand Menu',
                          padding: EdgeInsets.zero,
                          onPressed: _toggleExpanded,
                        ),
                      ),
                    ),
            ),

            // 2. Interactive Search Filter (in expanded mode)
            if (_isExpanded)
              Container(
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _searchQuery.isNotEmpty
                        ? const Color(0xFF00F0FF).withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 11.5),
                  decoration: InputDecoration(
                    hintText: 'Search tools...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11.5),
                    prefixIcon: const Icon(Icons.search, size: 15, color: Colors.white38),
                    prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 14, color: Colors.white54),
                            padding: EdgeInsets.zero,
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    border: InputBorder.none,
                  ),
                ),
              ),

            // 3. Scrollable Tools List
            Expanded(
              child: filteredTools.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded, color: Colors.white38, size: 28),
                            const SizedBox(height: 8),
                            const Text(
                              'No matching tools',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () => _searchController.clear(),
                              child: const Text('Clear Filter', style: TextStyle(fontSize: 11, color: Color(0xFF00F0FF))),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                      children: _buildToolTree(filteredTools),
                    ),
            ),

            // 4. Bottom Engineering Telemetry & Quick Help
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildToolTree(List<_SidebarToolDef> tools) {
    if (_searchQuery.isNotEmpty) {
      // Flat list of matching tools
      return tools.map((t) => _buildToolItem(t)).toList();
    }

    final categories = ['AI & GENERATIVE', 'MODELING & CAD', 'ANALYSIS & DESIGN'];
    final widgets = <Widget>[];

    for (var i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final catTools = tools.where((t) => t.category == cat).toList();
      if (catTools.isEmpty) continue;

      if (i > 0) {
        widgets.add(const SizedBox(height: 6));
        widgets.add(Divider(color: Colors.white.withValues(alpha: 0.05), height: 1));
        widgets.add(const SizedBox(height: 6));
      }

      widgets.add(_buildSectionHeader(cat));
      for (final t in catTools) {
        widgets.add(_buildToolItem(t));
      }
    }

    return widgets;
  }

  Widget _buildSectionHeader(String title) {
    if (!_isExpanded) {
      return const SizedBox(height: 4);
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 6, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.38),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildToolItem(_SidebarToolDef tool) {
    final isHovered = _hoveredTool == tool.label;

    final itemContent = MouseRegion(
      onEnter: (_) => setState(() => _hoveredTool = tool.label),
      onExit: (_) => setState(() => _hoveredTool = null),
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: tool.color.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 42,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 8 : 0),
          decoration: BoxDecoration(
            color: isHovered
                ? tool.color.withValues(alpha: 0.10)
                : const Color(0xFF161B22).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHovered
                  ? tool.color.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.04),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              // Left active bar indicator on hover
              if (_isExpanded && isHovered)
                Container(
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: tool.color,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: tool.color.withValues(alpha: 0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              // Icon Container
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: tool.color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(tool.icon, size: 15, color: tool.color),
              ),
              if (_isExpanded) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        tool.subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 9.0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tool.badge != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: tool.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: tool.color.withValues(alpha: 0.4), width: 0.5),
                    ),
                    child: Text(
                      tool.badge!,
                      style: TextStyle(
                        color: tool.color,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );

    if (!_isExpanded) {
      return Tooltip(
        message: '${tool.label}\n${tool.subtitle}',
        waitDuration: const Duration(milliseconds: 250),
        preferBelow: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: tool.color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
        child: itemContent,
      );
    }

    return itemContent;
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 8 : 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
      ),
      child: _isExpanded
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Live GNN Latency badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'SURROGATE GNN  •  0.4ms',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Quick Navigation & Shortcuts Help button
                InkWell(
                  onTap: _showShortcutsDialog,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.help_outline_rounded, size: 14, color: Colors.white54),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Controls & Shortcuts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: IconButton(
                icon: const Icon(Icons.help_outline_rounded, size: 18, color: Colors.white54),
                tooltip: 'Controls & Shortcuts',
                padding: EdgeInsets.zero,
                onPressed: _showShortcutsDialog,
              ),
            ),
    );
  }
}
