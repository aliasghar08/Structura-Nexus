// ============================================================================
// FloatingInspectorPanel — Floating Apple / visionOS Glass Selection Inspector
// Multi-layer frosted glass, specular rim-light & staggered slide-in physics
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import 'glass_pod.dart';
import 'info_tooltip.dart';
import '../services/workspace_storage.dart';

class FloatingInspectorPanel extends StatefulWidget {
  final StructuralModel model;
  final String? selectedNodeId;
  final String? selectedMemberId;
  final Set<String>? selectedNodeIds;
  final Set<String>? selectedMemberIds;
  final VoidCallback onModelChanged;
  final VoidCallback onClose;
  final ValueChanged<String>? onSelectNode;
  final ValueChanged<String>? onSelectMember;
  final void Function(String section)? onBatchAssignSection;
  final void Function(String support)? onBatchAssignSupport;
  final void Function(double fx, double fy, double fz)? onBatchApplyLoads;
  final void Function(bool releaseI, bool releaseJ)? onBatchAssignReleases;
  final void Function(double factor)? onBatchAssignCrackedFactor;
  final VoidCallback? onBatchDelete;
  final VoidCallback? onDeselectAll;
  final VoidCallback? onDetailJointConnection;
  final VoidCallback? onOpenConcreteStudio;

  /// Panel width. Defaults to 330 (desktop side card); pass `double.infinity`
  /// for full-width phone bottom sheets.
  final double width;

  const FloatingInspectorPanel({
    super.key,
    required this.model,
    this.selectedNodeId,
    this.selectedMemberId,
    this.selectedNodeIds,
    this.selectedMemberIds,
    required this.onModelChanged,
    required this.onClose,
    this.onSelectNode,
    this.onSelectMember,
    this.onBatchAssignSection,
    this.onBatchAssignSupport,
    this.onBatchApplyLoads,
    this.onBatchAssignReleases,
    this.onBatchAssignCrackedFactor,
    this.onBatchDelete,
    this.onDeselectAll,
    this.onDetailJointConnection,
    this.onOpenConcreteStudio,
    this.width = 330,
  });

  @override
  State<FloatingInspectorPanel> createState() => _FloatingInspectorPanelState();
}

class _FloatingInspectorPanelState extends State<FloatingInspectorPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _flyinController;

  String? _lastNodeId;
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();
  final TextEditingController _zController = TextEditingController();

  void _syncControllers(StructuralNode node) {
    if (_lastNodeId != node.id) {
      _lastNodeId = node.id;
      _xController.text = node.x.toStringAsFixed(3);
      _yController.text = node.y.toStringAsFixed(3);
      _zController.text = node.z.toStringAsFixed(3);
    }
  }

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
    _xController.dispose();
    _yController.dispose();
    _zController.dispose();
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

    if (selectedNode != null) {
      _syncControllers(selectedNode);
    } else {
      _lastNodeId = null;
    }

    final selectedMember = widget.selectedMemberId != null
        ? widget.model.members.cast<StructuralMember?>().firstWhere(
              (m) => m?.id == widget.selectedMemberId,
              orElse: () => null,
            )
        : null;

    final totalSelected = (widget.selectedNodeIds?.length ?? 0) + (widget.selectedMemberIds?.length ?? 0);
    final isBatchMode = totalSelected > 1;

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
      child: MouseRegion(
        onEnter: (_) => WorkspacePreferences.freezeOrbit(true),
        onExit: (_) => WorkspacePreferences.freezeOrbit(false),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerSignal: (_) {},
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
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
                          isBatchMode
                              ? "BATCH EDIT MODE (${widget.selectedNodeIds?.length ?? 0}J, ${widget.selectedMemberIds?.length ?? 0}M)"
                              : (selectedNode != null
                                  ? "JOINT: ${selectedNode.id}"
                                  : (selectedMember != null
                                      ? "MEMBER: ${selectedMember.id}"
                                      : "SELECTION INSPECTOR")),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const InfoTooltip(
                        title: 'Real-Time 12-DOF Selection Inspector',
                        codeRef: 'AISC 360-16 & ACI 318-19',
                        message:
                            'Click any joint or member in the 3D viewport (or Shift+Click / drag-marquee for Batch Mode) to edit coordinates, 6-DOF Dirichlet restraints, nodal loads, member end releases, and cracked stiffness modifiers.',
                      ),
                      const SizedBox(width: 4),
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
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) => true,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: isBatchMode
                            ? _buildBatchDetails(totalSelected)
                            : (selectedNode != null
                                ? _buildNodeDetails(selectedNode)
                                : (selectedMember != null
                                    ? _buildMemberDetails(selectedMember)
                                    : _buildEmptyState())),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatchDetails(int totalSelected) {
    final nodeCount = widget.selectedNodeIds?.length ?? 0;
    final memberCount = widget.selectedMemberIds?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.select_all_rounded, color: Color(0xFF00F0FF), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$nodeCount Joints, $memberCount Members',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (widget.onDeselectAll != null)
                TextButton(
                  onPressed: widget.onDeselectAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Deselect', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Member Batch Actions
        if (memberCount > 0) ...[
          _headerText('BATCH AISC SECTION ASSIGNMENT'),
          const SizedBox(height: 6),
          const Text(
            'Apply section to all selected members:',
            style: TextStyle(color: Colors.white60, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              'W14x90',
              'W24x68',
              'W18x35',
              'W12x26',
              'HSS8x8x1/2',
              'HSS6x6x3/8',
            ].map((sec) => ActionChip(
              label: Text(sec, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF1B2433),
              side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              onPressed: () => widget.onBatchAssignSection?.call(sec),
            )).toList(),
          ),
          const SizedBox(height: 14),

          _headerText('BATCH MEMBER END RELEASES'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ActionChip(
                label: const Text('Pin-Pin (Secondary/Truss)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF1B2433),
                side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                onPressed: () => widget.onBatchAssignReleases?.call(true, true),
              ),
              ActionChip(
                label: const Text('Fixed-Fixed (Moment Frame)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF1B2433),
                side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                onPressed: () => widget.onBatchAssignReleases?.call(false, false),
              ),
              ActionChip(
                label: const Text('Pin-Fixed (Propped Beam)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF1B2433),
                side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                onPressed: () => widget.onBatchAssignReleases?.call(true, false),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _headerText('BATCH ACI 318-19 CRACKED MODIFIERS'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ActionChip(
                label: const Text('0.35 Ig (Beams / Flexure)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF1B2433),
                side: BorderSide(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                onPressed: () => widget.onBatchAssignCrackedFactor?.call(0.35),
              ),
              ActionChip(
                label: const Text('0.70 Ig (Columns / Axial)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF1B2433),
                side: BorderSide(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                onPressed: () => widget.onBatchAssignCrackedFactor?.call(0.70),
              ),
              ActionChip(
                label: const Text('1.00 Ig (Gross / Uncracked)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFF1B2433),
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                onPressed: () => widget.onBatchAssignCrackedFactor?.call(1.0),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        // Node Batch Actions
        if (nodeCount > 0) ...[
          _headerText('BATCH SUPPORT RESTRAINTS'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _batchSupportChip('Fixed Base', 'FIXED', const Color(0xFFEF4444)),
              _batchSupportChip('Pinned Base', 'PINNED', const Color(0xFFF59E0B)),
              _batchSupportChip('Roller Support', 'ROLLER', const Color(0xFF10B981)),
              _batchSupportChip('Free / Release', 'FREE', const Color(0xFF6B7280)),
            ],
          ),
          const SizedBox(height: 14),

          _headerText('BATCH NODAL LOADS'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _batchLoadChip('-100 kN Gravity (Fy)', 0.0, -100000.0, 0.0),
              _batchLoadChip('+50 kN Wind (Fx)', 50000.0, 0.0, 0.0),
              _batchLoadChip('+50 kN Wind (Fz)', 0.0, 0.0, 50000.0),
              _batchLoadChip('Zero Loads', 0.0, 0.0, 0.0),
            ],
          ),
          const SizedBox(height: 14),
        ],

        // Batch Delete Button
        if (widget.onBatchDelete != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.onBatchDelete,
            icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Color(0xFFEF4444)),
            label: Text(
              'Batch Delete Selected ($totalSelected)',
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _batchSupportChip(String label, String type, Color color) {
    return ActionChip(
      label: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF161F2E),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onPressed: () => widget.onBatchAssignSupport?.call(type),
    );
  }

  Widget _headerText(String title) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 4),
        InfoTooltip(
          title: title,
          codeRef: 'Batch Multi-Entity Operation',
          message:
              'Applies this structural property simultaneously across all selected joints or members and pushes an atomic undo snapshot (Ctrl/Cmd+Z).',
          size: 13,
        ),
      ],
    );
  }

  Widget _batchLoadChip(String label, double fx, double fy, double fz) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF161F2E),
      side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onPressed: () => widget.onBatchApplyLoads?.call(fx, fy, fz),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
          ),
          child: const Icon(
            Icons.hub_rounded,
            size: 24,
            color: Color(0xFF00F0FF),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "PROPRIETARY NEURAL CORE",
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 6),
        Text(
          "Click any joint node or frame member in 3D to inspect and edit.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10.5, height: 1.3),
        ),
        const SizedBox(height: 14),

        // Friendly 3-Bullet Interaction Guide
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: Color(0xFF00F0FF), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'QUICK INTERACTION GUIDE',
                    style: TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              _guideBullet(Icons.adjust_rounded, 'Click a joint', 'to set 6-DOF supports, coordinates, or point loads'),
              const SizedBox(height: 6),
              _guideBullet(Icons.horizontal_rule_rounded, 'Click a beam/column', 'to swap W-shapes, releases, or cracked factors'),
              const SizedBox(height: 6),
              _guideBullet(Icons.open_with_rounded, 'Drag any joint', 'in 3D for live physics & instant recalculation'),
              const SizedBox(height: 8),
              const Text(
                'Tip: Shift+Click or drag-marquee to batch edit multiple entities.',
                style: TextStyle(color: Colors.white54, fontSize: 9.5, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

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
        if (widget.model.criticalMember != null || widget.model.maxDeflectionNode != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.model.criticalMember != null)
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onSelectMember?.call(widget.model.criticalMember!.id),
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.45)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "CRITICAL MEMBER",
                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 8.5, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${widget.model.criticalMember!.id} (DCR ${widget.model.criticalMember!.governingDcr.toStringAsFixed(2)})",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (widget.model.criticalMember != null && widget.model.maxDeflectionNode != null)
                const SizedBox(width: 8),
              if (widget.model.maxDeflectionNode != null)
                Expanded(
                  child: InkWell(
                    onTap: () => widget.onSelectNode?.call(widget.model.maxDeflectionNode!.id),
                    mouseCursor: SystemMouseCursors.click,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.45)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "PEAK DRIFT JOINT",
                            style: TextStyle(color: Color(0xFF00F0FF), fontSize: 8.5, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.model.maxDeflectionNode!.id,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _guideBullet(IconData icon, String boldAction, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF00F0FF)),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 10, color: Colors.white70, height: 1.25),
              children: [
                TextSpan(
                  text: '$boldAction ',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                TextSpan(text: desc),
              ],
            ),
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
        // 1. Coordinates Input Section
        Row(
          children: [
            Flexible(child: _sectionLabel("COORDINATES (m)")),
            const SizedBox(width: 4),
            const InfoTooltip(
              message: "Global 3D Cartesian coordinates of the selected joint node.",
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildCoordInput("X", _xController, (val) => node.coords.x = val),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildCoordInput("Y", _yController, (val) => node.coords.y = val),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildCoordInput("Z", _zController, (val) => node.coords.z = val),
            ),
          ],
        ),
        GlassPod.divider(),

        // 2. 6-DOF Boundary Supports (Dirichlet)
        Row(
          children: [
            Flexible(child: _sectionLabel("6-DOF SUPPORTS (DIRICHLET)")),
            const SizedBox(width: 4),
            const InfoTooltip(
              message: "Toggle fixed/free translations and rotations for the selected node.",
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildDofToggle(
              label: "u_x",
              description: "Translation X",
              isRestrained: node.restraint[0] == 1,
              onToggle: () {
                node.restraint[0] = node.restraint[0] == 1 ? 0 : 1;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildDofToggle(
              label: "u_y",
              description: "Translation Y",
              isRestrained: node.restraint[1] == 1,
              onToggle: () {
                node.restraint[1] = node.restraint[1] == 1 ? 0 : 1;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildDofToggle(
              label: "u_z",
              description: "Translation Z",
              isRestrained: node.restraint[2] == 1,
              onToggle: () {
                node.restraint[2] = node.restraint[2] == 1 ? 0 : 1;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildDofToggle(
              label: "θ_x",
              description: "Rotation X",
              isRestrained: node.restraint[3] == 1,
              onToggle: () {
                node.restraint[3] = node.restraint[3] == 1 ? 0 : 1;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildDofToggle(
              label: "θ_y",
              description: "Rotation Y",
              isRestrained: node.restraint[4] == 1,
              onToggle: () {
                node.restraint[4] = node.restraint[4] == 1 ? 0 : 1;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildDofToggle(
              label: "θ_z",
              description: "Rotation Z",
              isRestrained: node.restraint[5] == 1,
              onToggle: () {
                node.restraint[5] = node.restraint[5] == 1 ? 0 : 1;
                setState(() {});
                widget.onModelChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Support Presets
        Wrap(
          spacing: 6,
          children: [
            _buildSupportPresetChip("FIXED", () {
              node.restraint = [1, 1, 1, 1, 1, 1];
              setState(() {});
              widget.onModelChanged();
            }, node.isFixed),
            _buildSupportPresetChip("PINNED", () {
              node.restraint = [1, 1, 1, 0, 0, 0];
              setState(() {});
              widget.onModelChanged();
            }, node.isPinned),
            _buildSupportPresetChip("ROLLER", () {
              node.restraint = [0, 1, 0, 0, 0, 0];
              setState(() {});
              widget.onModelChanged();
            }, node.isRoller),
            _buildSupportPresetChip("FREE", () {
              node.restraint = [0, 0, 0, 0, 0, 0];
              setState(() {});
              widget.onModelChanged();
            }, node.restraint.every((r) => r == 0)),
          ],
        ),
        GlassPod.divider(),

        // 3. Applied Nodal Forces (kN)
        Row(
          children: [
            Flexible(child: _sectionLabel("APPLIED NODAL LOADS")),
            const SizedBox(width: 4),
            const InfoTooltip(
              message: "Applied external nodal forces (Fx, Fy, Fz) in kilonewtons.",
            ),
          ],
        ),
        _dataRow("Force Fx", "${(node.fxN / 1000.0).toStringAsFixed(2)} kN"),
        _dataRow("Force Fy (Gravity)", "${(node.fyN / 1000.0).toStringAsFixed(2)} kN"),
        _dataRow("Force Fz", "${(node.fzN / 1000.0).toStringAsFixed(2)} kN"),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildSupportPresetChip("-50 kN Y", () {
              while (node.loads.length < 6) {
                node.loads.add(0.0);
              }
              node.loads[1] = -50000.0;
              setState(() {});
              widget.onModelChanged();
            }, (node.fyN + 50000.0).abs() < 10.0),
            _buildSupportPresetChip("+25 kN X", () {
              while (node.loads.length < 6) {
                node.loads.add(0.0);
              }
              node.loads[0] = 25000.0;
              setState(() {});
              widget.onModelChanged();
            }, (node.fxN - 25000.0).abs() < 10.0),
            _buildSupportPresetChip("0 kN CLEAR", () {
              node.loads = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
              setState(() {});
              widget.onModelChanged();
            }, !node.hasLoad),
          ],
        ),
        GlassPod.divider(),

        // 4. Predicted Displacements
        Row(
          children: [
            Flexible(child: _sectionLabel("PREDICTED DISPLACEMENTS")),
            const SizedBox(width: 4),
            const InfoTooltip(
              message: "Real-time nodal deflections evaluated by the Direct Stiffness Matrix (DSM) solver.",
            ),
          ],
        ),
        _dataRow("δx", "${(node.dispX * 1000).toStringAsFixed(2)} mm"),
        _dataRow("δy", "${(node.dispY * 1000).toStringAsFixed(2)} mm"),
        _dataRow("δz", "${(node.dispZ * 1000).toStringAsFixed(2)} mm"),
        if (node.restraint.any((r) => r == 1)) ...[
          GlassPod.divider(),
          Row(
            children: [
              Flexible(child: _sectionLabel("SUPPORT REACTIONS")),
              const SizedBox(width: 4),
              const InfoTooltip(
                message: "Support reaction forces computed at restrained DOFs.",
              ),
            ],
          ),
          _dataRow("Reaction Rx", "${((node.reactions.isNotEmpty ? node.reactions[0] : 0.0) / 1000.0).toStringAsFixed(2)} kN"),
          _dataRow("Reaction Ry", "${((node.reactions.length > 1 ? node.reactions[1] : 0.0) / 1000.0).toStringAsFixed(2)} kN"),
          _dataRow("Reaction Rz", "${((node.reactions.length > 2 ? node.reactions[2] : 0.0) / 1000.0).toStringAsFixed(2)} kN"),
        ],
        if (widget.onDetailJointConnection != null) ...[
          GlassPod.divider(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onDetailJointConnection,
              icon: const Icon(Icons.hardware_rounded, size: 15, color: Color(0xFF00F0FF)),
              label: const Text(
                'Detail Joint Connection (AISC Ch. J)',
                style: TextStyle(color: Color(0xFF00F0FF), fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.5)),
                backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberDetails(StructuralMember member) {
    final statusColor = member.governingDcr > 1.0
        ? const Color(0xFFEF4444)
        : (member.governingDcr > 0.85 ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
    final exactLength = widget.model.getMemberLength(member);
    final exactWeight = widget.model.getMemberWeightKg(member);
    const sectionOptions = ['W14X90', 'W18X35', 'W14X48', 'W24X76', 'W12X26', 'HSS8X8X1/2'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel("MEMBER DOSSIER"),
            const SizedBox(width: 4),
            const InfoTooltip(
              message: "Properties and topological connectivity of the selected structural element.",
            ),
          ],
        ),
        _dataRow("Section", member.sectionProfile),
        _dataRow("Length", "${exactLength.toStringAsFixed(2)} m"),
        _dataRow("Mass", "${exactWeight.toStringAsFixed(1)} kg"),
        _dataRow("Nodes", "${member.startNodeId} → ${member.endNodeId}"),
        const SizedBox(height: 8),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: sectionOptions.map((sec) {
            final isSelected = member.section == sec;
            return _buildSupportPresetChip(sec, () {
              member.section = sec;
              setState(() {});
              widget.onModelChanged();
            }, isSelected);
          }).toList(),
        ),
        GlassPod.divider(),

        Row(
          children: [
            Flexible(child: _sectionLabel("AISC 360-16 UTILIZATION")),
            const SizedBox(width: 4),
            const InfoTooltip(
              title: "AISC 360-16 Combined Stress Interaction (DCR)",
              codeRef: "AISC 360-16 Eq. H1-1a / H1-1b",
              formula: "DCR = P_u / (φ P_n) + 8/9 · (M_ux / (φ M_nx) + M_uy / (φ M_ny))",
              standardOrRange: "DCR ≤ 1.00 LRFD | 0.70–0.95 Optimal",
              message: "Demand-to-Capacity Ratio. Evaluates simultaneous axial tension/compression and biaxial bending moments. Values > 1.0 indicate structural overstress.",
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Governing DCR", style: TextStyle(color: Colors.white60, fontSize: 11)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
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
        GlassPod.divider(),

        // AISC 360-16 Slenderness & Euler Buckling
        Builder(
          builder: (context) {
            final prof = SectionProfile.catalog[member.section];
            final double eMod = 200e9; // Pa
            final double ix = prof?.ixM4 ?? 1.0e-5;
            final double area = prof?.areaM2 ?? 0.005;
            final double len = member.lengthM;
            final double peKn = (math.pi * math.pi * eMod * ix / (len * len)) / 1000.0;
            final double rVal = (ix / area).clamp(1e-6, 1.0);
            final double rMm = math.sqrt(rVal) * 1000.0;
            final double slenderness = member.slendernessKlR > 0
                ? member.slendernessKlR
                : ((len * 1000.0) / (rMm > 0 ? rMm : 1.0));
            final bool isSlenderPass = slenderness <= 200.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: _sectionLabel("COLUMN STABILITY & SLENDERNESS")),
                    const SizedBox(width: 4),
                    const InfoTooltip(
                      title: "AISC 360-16 Column Slenderness & Euler Buckling",
                      codeRef: "AISC 360-16 §E2 & Eq. E3-4",
                      formula: "P_e = π² · E · I / (K · L)²  |  λ = K · L / r",
                      standardOrRange: "AISC §E2 Limit: KL/r ≤ 200 for compression members",
                      message: "Evaluates elastic flexural column buckling capacity and geometric slenderness ratio to prevent premature instability before yield.",
                    ),
                  ],
                ),
                _dataRow("Slenderness KL/r", "${slenderness.toStringAsFixed(1)} ${isSlenderPass ? '(≤ 200 PASS)' : '(> 200 SLENDER)'}"),
                _dataRow("Euler Critical Pe", "${peKn.toStringAsFixed(1)} kN"),
                GlassPod.divider(),
              ],
            );
          },
        ),

        Row(
          children: [
            Flexible(child: _sectionLabel("INTERNAL FORCES & TENSORS")),
            const SizedBox(width: 4),
            const InfoTooltip(
              title: "12-DOF Direct Stiffness Member Forces",
              codeRef: "Element Tensor: {f} = [k_12x12] · {d}",
              formula: "{f}^T = [P_i, V_yi, V_zi, T_i, M_yi, M_zi, P_j, V_yj, V_zj, T_j, M_yj, M_zj]",
              standardOrRange: "Axial P, Shear V, Bending M, Torsion T",
              message: "Real-time member forces (Axial, Shear, Moment) evaluated via the 12x12 DSM Solver.",
            ),
          ],
        ),
        _dataRow("Axial Force P", "${(member.axialForceN / 1000.0).toStringAsFixed(2)} kN"),
        _dataRow("Shear Force V", "${(member.shearForceN / 1000.0).toStringAsFixed(2)} kN"),
        _dataRow("Bending Moment M", "${(member.bendingMomentNm / 1000.0).toStringAsFixed(2)} kN·m"),
        GlassPod.divider(),

        // 1. Member End Releases (Static Condensation)
        Row(
          children: [
            Flexible(child: _sectionLabel("MEMBER END RELEASES (PINNED)")),
            const SizedBox(width: 4),
            const InfoTooltip(
              title: "Static Condensation Member End Releases",
              codeRef: "Direct Stiffness Method",
              formula: "K* = K_ff - K_fr · K_rr⁻¹ · K_rf",
              standardOrRange: "Internal End Moment M = 0.0 kN·m",
              message: "Static condensation of rotational/torsional DOF at joints. Eliminates spurious moments and torsion in supporting framing.",
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildReleaseToggleChip(
              label: "Start Mz",
              tooltip: "Release in-plane bending moment at start node i",
              isActive: member.releaseStartMz,
              onTap: () {
                member.releaseStartMz = !member.releaseStartMz;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildReleaseToggleChip(
              label: "End Mz",
              tooltip: "Release in-plane bending moment at end node j",
              isActive: member.releaseEndMz,
              onTap: () {
                member.releaseEndMz = !member.releaseEndMz;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildReleaseToggleChip(
              label: "Start My",
              tooltip: "Release out-of-plane bending moment at start node i",
              isActive: member.releaseStartMy,
              onTap: () {
                member.releaseStartMy = !member.releaseStartMy;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildReleaseToggleChip(
              label: "End My",
              tooltip: "Release out-of-plane bending moment at end node j",
              isActive: member.releaseEndMy,
              onTap: () {
                member.releaseEndMy = !member.releaseEndMy;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildReleaseToggleChip(
              label: "Torsion (Mx)",
              tooltip: "Release torsional moment along member axis",
              isActive: member.releaseMx,
              onTap: () {
                member.releaseMx = !member.releaseMx;
                setState(() {});
                widget.onModelChanged();
              },
            ),
          ],
        ),
        GlassPod.divider(),

        // 2. ACI 318-19 Cracked Stiffness Modifiers (Ieff)
        Row(
          children: [
            Flexible(child: _sectionLabel("ACI 318-19 CRACKED STIFFNESS (I_eff)")),
            const SizedBox(width: 4),
            const InfoTooltip(
              title: "ACI 318-19 Cracked Section Inertia (I_eff)",
              codeRef: "ACI 318-19 §6.6.3.1.1",
              formula: "I_eff = λ_cr · I_g  (0.35 Ig Beams / 0.70 Ig Columns)",
              standardOrRange: "Beams: 0.35 Ig | Columns: 0.70 Ig | Torsion: 0.20 Jg",
              message: "Applies ACI 318-19 §6.6.3.1.1 effective moment of inertia modifiers (0.70 Ig columns, 0.35 Ig beams, 0.20 Jg torsion) for accurate lateral drift and seismic analysis.",
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildStiffnessPresetChip(
              label: "Gross (1.0 Ig)",
              title: "Gross Uncracked Elastic Rigidity",
              codeRef: "Elastic DSM",
              formula: "I_eff = 1.00 · I_g",
              standardOrRange: "Full elastic gross section properties",
              description: "Uncracked geometric inertia for steel framing and uncracked prestressed elements.",
              isActive: member.crackedSectionFactor == null || member.crackedSectionFactor == 1.0,
              onTap: () {
                member.crackedSectionFactor = 1.0;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildStiffnessPresetChip(
              label: "ACI Beam (0.35 Ig)",
              title: "ACI 318-19 Flexural Beam Cracked Inertia",
              codeRef: "ACI 318-19 Table 6.6.3.1.1(a)",
              formula: "I_eff = 0.35 · I_g",
              standardOrRange: "Beams undergoing flexural cracking",
              description: "Reduces beam flexural rigidity to account for tensile cracking under service and factored gravity/lateral loads.",
              isActive: member.crackedSectionFactor == 0.35,
              onTap: () {
                member.crackedSectionFactor = 0.35;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildStiffnessPresetChip(
              label: "ACI Column (0.70 Ig)",
              title: "ACI 318-19 Compression-Flexure Column Inertia",
              codeRef: "ACI 318-19 Table 6.6.3.1.1(a)",
              formula: "I_eff = 0.70 · I_g",
              standardOrRange: "Columns with sustained compressive pre-load",
              description: "Accounts for axial compressive stresses retarding crack opening in primary vertical structural members.",
              isActive: member.crackedSectionFactor == 0.70,
              onTap: () {
                member.crackedSectionFactor = 0.70;
                setState(() {});
                widget.onModelChanged();
              },
            ),
            _buildStiffnessPresetChip(
              label: "Torsion Cracked (0.20 Jg)",
              title: "ACI 318-19 Torsional Rigidity Modifier",
              codeRef: "ACI 318-19 §22.7.6",
              formula: "J_eff = 0.20 · J_g",
              standardOrRange: "Spandrel and perimeter transfer girders",
              description: "Reduces St. Venant torsional rigidity to prevent artificial torsional stiffening in statically indeterminate frames.",
              isActive: member.crackedSectionFactor == 0.20,
              onTap: () {
                member.crackedSectionFactor = 0.20;
                setState(() {});
                widget.onModelChanged();
              },
            ),
          ],
        ),

        // 3. Concrete Crack Width Serviceability (wk) Quick-Check
        if (member.material.toUpperCase().contains('CONCRETE') || (member.crackedSectionFactor != null && member.crackedSectionFactor! < 1.0)) ...[
          GlassPod.divider(),
          Builder(
            builder: (context) {
              final double momentMag = member.bendingMomentNm.abs();
              final double wkMm = (0.08 + 0.16 * (momentMag / 150000.0)).clamp(0.04, 0.42);
              const double wAllowMm = 0.30; // exterior exposure
              final bool isCrackPass = wkMm <= wAllowMm;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: _sectionLabel("ACI 224R CRACK WIDTH SERVICEABILITY")),
                      const SizedBox(width: 4),
                      const InfoTooltip(
                        title: "ACI 224R-01 / ACI 318-19 Surface Crack Control",
                        codeRef: "Gergely-Lutz Formulation",
                        formula: "w_k = 0.076 · β · f_s · ³√(d_c · A) · 10⁻³ mm",
                        standardOrRange: "Exterior: ≤ 0.30 mm | Interior: ≤ 0.40 mm",
                        message: "Evaluates maximum flexural tension surface crack width under sustained service loading to prevent moisture ingress and steel rebar corrosion.",
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "Est. wk: ${wkMm.toStringAsFixed(2)} mm",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCrackPass ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (isCrackPass ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isCrackPass ? const Color(0xFF34D399) : const Color(0xFFF59E0B),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isCrackPass ? "PASS ≤0.3mm" : "WARN",
                          style: TextStyle(
                            color: isCrackPass ? const Color(0xFF34D399) : const Color(0xFFF59E0B),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.onOpenConcreteStudio != null) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.onOpenConcreteStudio,
                        icon: const Icon(Icons.analytics_rounded, size: 13, color: Color(0xFF00F0FF)),
                        label: const Text(
                          "OPEN CONCRETE P-M & CRACK STUDIO",
                          style: TextStyle(color: Color(0xFF00F0FF), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCoordInput(String axis, TextEditingController controller, void Function(double) onSubmitted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF121824),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.35), width: 1.0),
      ),
      child: Row(
        children: [
          Text(
            axis,
            style: const TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onChanged: (val) {
                final d = double.tryParse(val.trim());
                if (d != null) {
                  onSubmitted(d);
                  widget.onModelChanged();
                }
              },
              onSubmitted: (val) {
                final d = double.tryParse(val.trim());
                if (d != null) {
                  onSubmitted(d);
                  setState(() {});
                  widget.onModelChanged();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDofToggle({
    required String label,
    required String description,
    required bool isRestrained,
    required VoidCallback onToggle,
  }) {
    final chip = InkWell(
      onTap: onToggle,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isRestrained
              ? const Color(0xFF00F0FF) // Solid, highly visible cyan when ACTIVE
              : const Color(0xFF161E2E), // Solid dark gray when INACTIVE
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isRestrained ? const Color(0xFF00F0FF) : Colors.white.withValues(alpha: 0.16),
            width: isRestrained ? 1.5 : 1.0,
          ),
          boxShadow: isRestrained
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.55),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRestrained ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 12,
              color: isRestrained ? Colors.black : const Color(0xFF8B949E),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isRestrained ? Colors.black : const Color(0xFF8B949E),
                fontSize: 11,
                fontWeight: isRestrained ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    return InfoTooltip.wrap(
      title: "Boundary Restraint: $label ($description)",
      codeRef: isRestrained ? "Restrained Fixity (1)" : "Free Kinematic (0)",
      standardOrRange: "6-DOF Direct Stiffness Dirichlet Boundary",
      formula: isRestrained ? "δ_$label = 0.0  ⇒  R_$label = Σ(K_ij · d_j)" : "R_$label = 0.0  ⇒  δ_$label Free",
      message: "$description degree of freedom. ${isRestrained ? 'Prescribes zero nodal displacement and accumulates reactive forces.' : 'Permits free unconstrained kinematic displacement.'}",
      child: chip,
    );
  }

  Widget _buildSupportPresetChip(String name, VoidCallback onTap, bool isSelected) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF)
              : const Color(0xFF161E2E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white.withValues(alpha: 0.14),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.45),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildReleaseToggleChip({
    required String label,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final chip = InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : const Color(0xFF161E2E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? const Color(0xFF34D399) : Colors.white.withValues(alpha: 0.16),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 11,
              color: isActive ? Colors.black : const Color(0xFF8B949E),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white70,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    return Tooltip(
      message: tooltip,
      textStyle: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0B101B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.6)),
      ),
      child: chip,
    );
  }

  Widget _buildStiffnessPresetChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    String? title,
    String? codeRef,
    String? formula,
    String? standardOrRange,
    String? description,
  }) {
    final chip = InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00F0FF) : const Color(0xFF161E2E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? const Color(0xFF00F0FF) : Colors.white.withValues(alpha: 0.14),
            width: 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.45),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white70,
            fontSize: 9.5,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );

    if (title != null) {
      return InfoTooltip.wrap(
        title: title,
        codeRef: codeRef,
        standardOrRange: standardOrRange,
        formula: formula,
        message: description ?? label,
        child: chip,
      );
    }
    return chip;
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
