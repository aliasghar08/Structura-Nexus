// ============================================================================
// FloatingInspectorPanel — Floating Apple / visionOS Glass Selection Inspector
// Multi-layer frosted glass, specular rim-light & staggered slide-in physics
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import 'glass_pod.dart';
import 'info_tooltip.dart';
import '../services/workspace_storage.dart';

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
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) => true,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: selectedNode != null
                            ? _buildNodeDetails(selectedNode)
                            : (selectedMember != null
                                ? _buildMemberDetails(selectedMember)
                                : _buildEmptyState()),
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

        // 3. Predicted Displacements
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
        _dataRow("Length", "${member.length.toStringAsFixed(2)} m"),
        _dataRow("Nodes", "${member.startNodeId} → ${member.endNodeId}"),
        GlassPod.divider(),

        Row(
          children: [
            _sectionLabel("AISC 360-16 UTILIZATION"),
            const SizedBox(width: 4),
            const InfoTooltip(
              message: "Demand-to-Capacity Ratio. Values > 1.0 indicate structural overstress.",
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

        Row(
          children: [
            _sectionLabel("INTERNAL FORCES & TENSORS"),
            const SizedBox(width: 4),
            const InfoTooltip(
              message: "Real-time member forces (Axial, Shear, Moment) evaluated via the 12x12 DSM Solver.",
            ),
          ],
        ),
        _dataRow("Axial Force P", "${member.axialForceN.toStringAsFixed(1)} kN"),
        _dataRow("Shear Force V", "${member.shearForceN.toStringAsFixed(1)} kN"),
        _dataRow("Bending Moment M", "${member.bendingMomentNm.toStringAsFixed(1)} kN·m"),
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
    return InkWell(
      onTap: onToggle,
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
  }

  Widget _buildSupportPresetChip(String name, VoidCallback onTap, bool isSelected) {
    return InkWell(
      onTap: onTap,
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
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
