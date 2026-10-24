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
    this.onOptimize,
    this.initialExpanded = true,
  });

  @override
  State<WorkstationSidebar> createState() => _WorkstationSidebarState();
}

class _WorkstationSidebarState extends State<WorkstationSidebar> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = _isExpanded ? 210.0 : 64.0;

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
        ),
        child: Column(
          children: [
            // Sidebar Top Header
            Container(
              height: 48,
              padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 10 : 4),
              decoration: BoxDecoration(
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
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00F0FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'TOOLS & SUITE',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
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

          // Scrollable Tools List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              children: [
                // SECTION: AI & GENERATIVE
                _buildSectionHeader('AI & GENERATIVE'),
                _buildToolItem(
                  label: 'AI Copilot',
                  icon: Icons.psychology_rounded,
                  color: const Color(0xFF00F0FF),
                  onTap: widget.onOpenCopilot,
                  badge: 'GEMINI',
                ),
                _buildToolItem(
                  label: 'Generative Opt',
                  icon: Icons.hub_rounded,
                  color: const Color(0xFF10B981),
                  onTap: widget.onOpenGenerativeOptimizer,
                  badge: 'GNN',
                ),
                _buildToolItem(
                  label: 'Gen Bracing',
                  icon: Icons.auto_awesome_rounded,
                  color: Colors.purpleAccent,
                  onTap: widget.onOpenGenerativeBracing,
                ),
                _buildToolItem(
                  label: 'Auto-Sizer',
                  icon: Icons.tune_rounded,
                  color: const Color(0xFF10B981),
                  onTap: widget.onOptimize,
                  badge: 'AISC',
                ),

                const SizedBox(height: 10),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 10),

                // SECTION: MODELING & CAD
                _buildSectionHeader('MODELING & CAD'),
                _buildToolItem(
                  label: 'CAD Studio',
                  icon: Icons.architecture_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: widget.onOpenCadStudio,
                  badge: '3D/2D',
                ),
                _buildToolItem(
                  label: 'Cloud Library',
                  icon: Icons.folder_special_rounded,
                  color: const Color(0xFFA855F7),
                  onTap: widget.onOpenLibrary,
                  badge: 'DXF',
                ),

                const SizedBox(height: 10),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 10),

                // SECTION: ANALYSIS & STABILITY
                _buildSectionHeader('ANALYSIS & DESIGN'),
                _buildToolItem(
                  label: 'Modal Seismic',
                  icon: Icons.waves_rounded,
                  color: const Color(0xFF38BDF8),
                  onTap: widget.onOpenSeismicModal,
                ),
                _buildToolItem(
                  label: 'Lateral Stability',
                  icon: Icons.shield_outlined,
                  color: const Color(0xFFE11D48),
                  onTap: widget.onOpenLateralStability,
                  badge: 'ASCE 7',
                ),
                _buildToolItem(
                  label: 'PE Calcs & BIM',
                  icon: Icons.picture_as_pdf_rounded,
                  color: const Color(0xFF00F0FF),
                  onTap: widget.onOpenPePacket,
                  badge: 'SEAL',
                ),
                _buildToolItem(
                  label: 'Embodied Carbon',
                  icon: Icons.eco_rounded,
                  color: const Color(0xFF34D399),
                  onTap: widget.onOpenEmbodiedCarbon,
                  badge: 'LCA',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
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
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildToolItem({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    String? badge,
  }) {
    final itemContent = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: color.withValues(alpha: 0.1),
      child: Container(
        height: 38,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 10 : 0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment:
              _isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            if (_isExpanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: color,
                      fontSize: 8.5,
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
    );

    if (!_isExpanded) {
      return Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 300),
        preferBelow: false,
        child: itemContent,
      );
    }

    return itemContent;
  }
}
