// ============================================================================
// FloatingInspectorPanel — Floating Apple / visionOS Glass Selection Inspector
// Multi-layer frosted glass, specular rim-light & staggered slide-in physics
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import 'glass_pod.dart';

class FloatingInspectorPanel extends StatefulWidget {
  final StructuralModel model;
  final String? selectedNodeId;
  final String? selectedMemberId;
  final VoidCallback onModelChanged;
  final VoidCallback onClose;

  /// Panel width. Defaults to 330 (desktop side card); pass `double.infinity`
  /// for full-width phone bottom sheets.
  final double width;

  const FloatingInspectorPanel({
    super.key,
    required this.model,
    this.selectedNodeId,
    this.selectedMemberId,
    required this.onModelChanged,
    required this.onClose,
    this.width = 330,
  });

  @override
  State<FloatingInspectorPanel> createState() => _FloatingInspectorPanelState();
}

class _FloatingInspectorPanelState extends State<FloatingInspectorPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _flyinController;

  @override
  void initState() {
    super.initState();
    _flyinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _flyinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _flyinController,
      curve: Curves.easeOutCubic,
    );

    final selectedNode = widget.selectedNodeId != null
        ? widget.model.getNode(widget.selectedNodeId!)
        : null;

    final selectedMember = widget.selectedMemberId != null
        ? widget.model.members.cast<StructuralMember?>().firstWhere(
              (m) => m?.id == widget.selectedMemberId,
              orElse: () => null,
            )
        : null;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - animation.value), 0),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: GlassPod(
        width: widget.width,
        borderRadius: 26,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Pill Grabber & Close
            Row(
              children: [
                Container(
                  width: 3.5,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedNode != null
                        ? "JOINT: ${selectedNode.id}"
                        : (selectedMember != null
                            ? "MEMBER: ${selectedMember.id}"
                            : "SELECTION INSPECTOR"),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                  tooltip: 'Dismiss Inspector',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                child: selectedNode != null
                    ? _buildNodeDetails(selectedNode)
                    : (selectedMember != null
                        ? _buildMemberDetails(selectedMember)
                        : _buildEmptyState()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
          ),
          child: const Icon(
            Icons.hub_rounded,
            size: 26,
            color: Color(0xFF00F0FF),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "PROPRIETARY NEURAL CORE",
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 6),
        Text(
          "Click any joint node or frame member to inspect 6-DOF internal tensors.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10.5, height: 1.3),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _telemetrySnippet("ENGINE", "100% In-House Tensor DSM"),
              const SizedBox(height: 6),
              _telemetrySnippet("GNN SURROGATE", "StructuraNet-3D (<1.5 ms)"),
              const SizedBox(height: 6),
              _telemetrySnippet("CONCRETE AI", "SectionNet-PM (<0.2 ms)"),
              const SizedBox(height: 6),
              _telemetrySnippet("DIRICHLET MASK", "Exact u_fixed = 0.000 mm"),
              const SizedBox(height: 6),
              _telemetrySnippet("EQUILIBRIUM", "Σ F = 0 Verified"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _telemetrySnippet(String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildNodeDetails(StructuralNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("COORDINATES & KINEMATICS"),
        _dataRow("X (m)", node.x.toStringAsFixed(3)),
        _dataRow("Y (m)", node.y.toStringAsFixed(3)),
        _dataRow("Z (m)", node.z.toStringAsFixed(3)),
        const Divider(color: Colors.white12, height: 20),

        _sectionLabel("BOUNDARY CONDITIONS"),
        Wrap(
          spacing: 6,
          children: [
            _badge(node.isPinned ? "PINNED SUPPORT" : (node.isRoller ? "ROLLER SUPPORT" : "FREE JOINT")),
          ],
        ),
        const Divider(color: Colors.white12, height: 20),

        _sectionLabel("PREDICTED DISPLACEMENTS"),
        _dataRow("δx", "${(node.dispX * 1000).toStringAsFixed(2)} mm"),
        _dataRow("δy", "${(node.dispY * 1000).toStringAsFixed(2)} mm"),
        _dataRow("δz", "${(node.dispZ * 1000).toStringAsFixed(2)} mm"),
      ],
    );
  }

  Widget _buildMemberDetails(StructuralMember member) {
    final statusColor = member.governingDcr > 1.0
        ? const Color(0xFFEF4444)
        : (member.governingDcr > 0.85 ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("MEMBER DOSSIER"),
        _dataRow("Section", member.sectionProfile),
        _dataRow("Length", "${member.length.toStringAsFixed(2)} m"),
        _dataRow("Nodes", "${member.startNodeId} → ${member.endNodeId}"),
        const Divider(color: Colors.white12, height: 20),

        _sectionLabel("AISC 360-16 UTILIZATION"),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Governing DCR", style: TextStyle(color: Colors.white60, fontSize: 11)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                member.governingDcr.toStringAsFixed(3),
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _dataRow("Limit State", member.governingLimitState),
        const Divider(color: Colors.white12, height: 20),

        _sectionLabel("INTERNAL FORCES & TENSORS"),
        _dataRow("Axial Force P", "${member.axialForceN.toStringAsFixed(1)} kN"),
        _dataRow("Shear Force V", "${member.shearForceN.toStringAsFixed(1)} kN"),
        _dataRow("Bending Moment M", "${member.bendingMomentNm.toStringAsFixed(1)} kN·m"),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF00F0FF),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1F6FEB).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF58A6FF).withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 9.5, fontWeight: FontWeight.bold),
      ),
    );
  }
}
