// ============================================================================
// WorkflowGuideBar — Interactive 4-Step Civil/Structural Workflow Stepper
// Live completion states, "Guide Me" prompt bar & "What Can I Build?" trigger
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/workspace_storage.dart';
import 'glass_pod.dart';
import 'info_tooltip.dart';

class WorkflowStepDefinition {
  final int stepNumber;
  final String title;
  final String subtitle;
  final String instruction;
  final String primaryActionLabel;
  final int targetHeaderStage;
  final bool isCompleted;
  final VoidCallback onPrimaryAction;

  const WorkflowStepDefinition({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.instruction,
    required this.primaryActionLabel,
    required this.targetHeaderStage,
    required this.isCompleted,
    required this.onPrimaryAction,
  });
}

class WorkflowGuideBar extends StatefulWidget {
  final StructuralModel model;
  final int activeStep;
  final ValueChanged<int>? onStepSelected;
  final VoidCallback onOpenTemplates;
  final VoidCallback onApplyLoadsAndSupports;
  final VoidCallback onRunFeaAndOptimize;
  final VoidCallback onExportPePacket;
  final VoidCallback onOpenCapabilitiesOverview;

  const WorkflowGuideBar({
    super.key,
    required this.model,
    this.activeStep = 1,
    this.onStepSelected,
    required this.onOpenTemplates,
    required this.onApplyLoadsAndSupports,
    required this.onRunFeaAndOptimize,
    required this.onExportPePacket,
    required this.onOpenCapabilitiesOverview,
  });

  @override
  State<WorkflowGuideBar> createState() => _WorkflowGuideBarState();
}

class _WorkflowGuideBarState extends State<WorkflowGuideBar> {
  late int _selectedStep;
  bool _guideMeExpanded = true;
  bool _isDismissed = false;
  bool _expandedOnCompact = false;

  @override
  void initState() {
    super.initState();
    _selectedStep = widget.activeStep;
  }

  @override
  void didUpdateWidget(covariant WorkflowGuideBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeStep != oldWidget.activeStep) {
      _selectedStep = widget.activeStep;
    }
  }

  List<WorkflowStepDefinition> _buildSteps() {
    final hasGeometry = widget.model.nodes.length >= 2 && widget.model.members.isNotEmpty;
    final hasSupportsAndLoads = widget.model.nodes.any((n) => n.restraint.any((r) => r == 1)) &&
        widget.model.nodes.any((n) => n.hasLoad);
    final hasSolvedFea = widget.model.members.any((m) => m.governingDcr > 0.0);
    final isCodePassing = hasSolvedFea && widget.model.members.every((m) => m.governingDcr <= 1.0);

    return [
      WorkflowStepDefinition(
        stepNumber: 1,
        title: 'Step 1: Model Frame',
        subtitle: 'Template / Extrude / Vision-to-BIM',
        instruction:
            "Start from 12 Certified Building/Bridge Templates, extrude stories, or convert a 2D Floorplan PDF into a 3D frame.",
        primaryActionLabel: 'Browse Templates',
        targetHeaderStage: 1,
        isCompleted: hasGeometry,
        onPrimaryAction: widget.onOpenTemplates,
      ),
      WorkflowStepDefinition(
        stepNumber: 2,
        title: 'Step 2: Restraints & Loads',
        subtitle: 'Supports / ASCE 7-16',
        instruction:
            "Verify 6-DOF base supports (Fixed/Pinned) and propagate ASCE 7-16 wind, seismic, and tributary floor gravity loads.",
        primaryActionLabel: 'ASCE 7 Loads & Stability',
        targetHeaderStage: 2,
        isCompleted: hasSupportsAndLoads,
        onPrimaryAction: widget.onApplyLoadsAndSupports,
      ),
      WorkflowStepDefinition(
        stepNumber: 3,
        title: 'Step 3: Solve & Code Check',
        subtitle: '12-DOF FEA / AISC & ACI',
        instruction:
            "Next: Click 'Run 12-DOF FEA & Auto-Size' to compute member forces and optimize AISC 360-16 Demand-Capacity Ratios (DCR ≤ 1.0).",
        primaryActionLabel: 'Run 12-DOF FEA & Auto-Size',
        targetHeaderStage: 3,
        isCompleted: isCodePassing,
        onPrimaryAction: widget.onRunFeaAndOptimize,
      ),
      WorkflowStepDefinition(
        stepNumber: 4,
        title: 'Step 4: Export & Stamp',
        subtitle: 'PE Packet / IFC / DXF / BOM',
        instruction:
            "Generate an HMAC-SHA256 Stamped PE Calculation Packet (PDF/LaTeX) or export CSI SAP2000 (.s2k), IFC 4.3, and AutoCAD (.dxf).",
        primaryActionLabel: 'Generate PE Packet',
        targetHeaderStage: 5,
        isCompleted: isCodePassing,
        onPrimaryAction: widget.onExportPePacket,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return Align(
        alignment: Alignment.topCenter,
        child: MouseRegion(
          onEnter: (_) => WorkspacePreferences.freezeOrbit(true),
          onExit: (_) => WorkspacePreferences.freezeOrbit(false),
          child: GlassPod(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            borderRadius: 16,
            onTap: () => setState(() => _isDismissed = false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.route_rounded, size: 14, color: Color(0xFF00F0FF)),
                SizedBox(width: 6),
                Text(
                  'SHOW 4-STEP ENGINEERING WORKFLOW GUIDE',
                  style: TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final steps = _buildSteps();
    final activeStepDef = steps[(_selectedStep - 1).clamp(0, steps.length - 1)];
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactViewport = screenWidth < 1100;

    if (isCompactViewport && !_expandedOnCompact) {
      final cleanStepTitle = activeStepDef.title.replaceFirst(RegExp(r'^Step \d+:\s*'), '');
      return Align(
        alignment: Alignment.topCenter,
        child: MouseRegion(
          onEnter: (_) => WorkspacePreferences.freezeOrbit(true),
          onExit: (_) => WorkspacePreferences.freezeOrbit(false),
          child: GlassPod(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            borderRadius: 16,
            onTap: () => setState(() => _expandedOnCompact = true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route_rounded, size: 14, color: Color(0xFF00F0FF)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Step ${activeStepDef.stepNumber}/4: $cleanStepTitle • Guide Me',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: activeStepDef.onPrimaryAction,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activeStepDef.primaryActionLabel,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded, size: 15, color: Color(0xFF00F0FF)),
              ],
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => WorkspacePreferences.freezeOrbit(true),
      onExit: (_) => WorkspacePreferences.freezeOrbit(false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (_) {},
        child: GlassPod(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: 18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: 4-Step Interactive Checklist + Guide Me Toggle + What Can I Build?
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "What Can I Build?" quick capability pill
                    InkWell(
                      onTap: widget.onOpenCapabilitiesOverview,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00F0FF).withValues(alpha: 0.22),
                              const Color(0xFF1F6FEB).withValues(alpha: 0.28),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.help_outline_rounded, size: 13, color: Color(0xFF00F0FF)),
                            SizedBox(width: 5),
                            Text(
                              'WHAT CAN I BUILD?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 4 Steps
                    for (int i = 0; i < steps.length; i++) ...[
                      _buildStepChip(steps[i]),
                      if (i < steps.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                    ],
                    const SizedBox(width: 8),

                    // "Guide Me" Toggle
                    InkWell(
                      onTap: () => setState(() => _guideMeExpanded = !_guideMeExpanded),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _guideMeExpanded
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _guideMeExpanded ? const Color(0xFF10B981) : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 12,
                              color: _guideMeExpanded ? const Color(0xFF10B981) : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'GUIDE ME',
                              style: TextStyle(
                                color: _guideMeExpanded ? const Color(0xFF10B981) : Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const InfoTooltip(
                      title: '4-Step Guided Structural Engineering Pipeline',
                      standardOrRange: 'Sequential Civil/Structural Workflow',
                      description:
                          'Follow Steps 1 → 4 from left to right: (1) Define 3D Geometry, (2) Assign Supports & ASCE 7 Loads, (3) Run 12-DOF FEA & Code Check, and (4) Export Stamped PE Packets or BIM files.',
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 15, color: Colors.white54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                      tooltip: 'Minimize Workflow Guide',
                      onPressed: () {
                        setState(() {
                          if (isCompactViewport && _expandedOnCompact) {
                            _expandedOnCompact = false;
                          } else {
                            _isDismissed = true;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Bottom Row: Active Step Instruction & 1-Click Action Button
              if (_guideMeExpanded) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11192A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, size: 15, color: Color(0xFF00F0FF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activeStepDef.instruction,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: activeStepDef.onPrimaryAction,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00F0FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activeStepDef.primaryActionLabel,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepChip(WorkflowStepDefinition step) {
    final isSelected = _selectedStep == step.stepNumber;
    final statusColor = step.isCompleted ? const Color(0xFF10B981) : const Color(0xFF00F0FF);

    String stepStandard;
    String stepFormula;
    String stepDesc;
    switch (step.stepNumber) {
      case 1:
        stepStandard = "BIM / FEM Modeling";
        stepFormula = "Connectivity: {Node_i, Node_j, Cross-Section}";
        stepDesc = "Model nodes, structural members, cross-sections, and stories. Select from 24 certified templates, import DXF/IFC, or extrude stories.";
        break;
      case 2:
        stepStandard = "ASCE 7-16 & 6-DOF Dirichlet Restraints";
        stepFormula = "Boundary: u_x, u_y, u_z, θ_x, θ_y, θ_z | Load: F_ext = Σ F_tributary";
        stepDesc = "Assign nodal boundary supports (Dirichlet conditions) and apply ASCE 7-16 automated tributary gravity and directional lateral loads.";
        break;
      case 3:
        stepStandard = "Direct Stiffness Method & LRFD DCR ≤ 1.00";
        stepFormula = "[K_global] · {D} = {F}  |  DCR = Pu/φPn + 8/9(Mux/φMnx + Muy/φMny)";
        stepDesc = "Solves 12x12 Timoshenko Direct Stiffness Matrix with static condensation releases, evaluates member forces, and verifies code compliance.";
        break;
      case 4:
      default:
        stepStandard = "Cryptographic HMAC-SHA256 & IFC 4.3";
        stepFormula = "Digest = HMAC_SHA256(Model_Hash, P.E._Secret_Key)";
        stepDesc = "Generate professional structural calculation reports with cryptographic PE seals, audit certificates, and export to IFC 4.3, DXF, or CSV.";
        break;
    }

    final chip = InkWell(
      onTap: () {
        setState(() {
          _selectedStep = step.stepNumber;
          _guideMeExpanded = true;
        });
        widget.onStepSelected?.call(step.stepNumber);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF).withValues(alpha: 0.18)
              : const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00F0FF)
                : (step.isCompleted
                    ? const Color(0xFF10B981).withValues(alpha: 0.45)
                    : Colors.white12),
            width: isSelected ? 1.3 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              step.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_checked_rounded,
              size: 13,
              color: statusColor,
            ),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return InfoTooltip.wrap(
      title: "Step ${step.stepNumber}: ${step.title}",
      codeRef: stepStandard,
      formula: stepFormula,
      message: stepDesc,
      child: chip,
    );
  }
}
