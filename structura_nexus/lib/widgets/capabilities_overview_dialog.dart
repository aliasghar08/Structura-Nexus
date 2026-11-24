// ============================================================================
// CapabilitiesOverviewDialog — "What Can I Build?" Role-Based Workflow Launcher
// Summarizes all 6 Core Civil & Structural Engineering Workflows with 1-Click Demos
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'glass_pod.dart';
import 'info_tooltip.dart';

class CapabilitiesOverviewDialog extends StatelessWidget {
  final VoidCallback onTrySteelFrameDesign;
  final VoidCallback onTryConcreteAndFooting;
  final VoidCallback onTrySeismicAndCollapse;
  final VoidCallback onTryBridgeMovingLoads;
  final VoidCallback onTryAiOptimization;
  final VoidCallback onTryPeAndBimDeliverables;

  const CapabilitiesOverviewDialog({
    super.key,
    required this.onTrySteelFrameDesign,
    required this.onTryConcreteAndFooting,
    required this.onTrySeismicAndCollapse,
    required this.onTryBridgeMovingLoads,
    required this.onTryAiOptimization,
    required this.onTryPeAndBimDeliverables,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <_CapabilityWorkflowCardData>[
      _CapabilityWorkflowCardData(
        number: '01',
        title: 'Steel Frame & High-Rise Design',
        standard: 'AISC 360-16 LRFD & ASCE 7-16',
        description:
            'Model 3D multi-story frames from 12 certified templates or 2D floorplan PDFs (Vision-to-BIM), propagate tributary gravity & directional wind loads, and verify combined axial-flexural DCR (Eq. H1-1a) and P-Δ stability.',
        deliverables: '3D Stress/BMD/SFD Ribbons • Governing DCR • B2 Sway Factor',
        icon: Icons.apartment_rounded,
        accentColor: const Color(0xFF00F0FF),
        buttonLabel: 'Try Example: 10-Story Tower',
        onTry: () {
          Navigator.of(context).pop();
          onTrySteelFrameDesign();
        },
      ),
      _CapabilityWorkflowCardData(
        number: '02',
        title: 'Concrete Column, Crack & Footing Design',
        standard: 'ACI 318-19, ACI 224R-01 & Winkler SSI',
        description:
            'Generate biaxial reinforced concrete P-M interaction curves, verify Gergely-Lutz surface crack widths w_k across 4 exposure classes, apply 0.35/0.70 I_g cracked modifiers, and check foundation two-way punching shear.',
        deliverables: 'P-M Capacity Envelope • Crack Width w_k (mm) • 6-DOF Soil Springs',
        icon: Icons.view_in_ar_rounded,
        accentColor: const Color(0xFF10B981),
        buttonLabel: 'Try Example: Concrete & Footing Studio',
        onTry: () {
          Navigator.of(context).pop();
          onTryConcreteAndFooting();
        },
      ),
      _CapabilityWorkflowCardData(
        number: '03',
        title: 'Seismic Time-History & Progressive Collapse',
        standard: 'Newmark-β NLTHA, ATC-40 & UFC 4-023-03',
        description:
            'Simulate El Centro / Northridge earthquake records in 3D, evaluate FEMA 356 pushover plastic hinges, or test sudden column removal under Ω_LD = 2.0 with automated catenary tie-force sizing.',
        deliverables: 'NLTHA Roof Drift History • Catenary Tie Sizing T_p, T_i, T_v',
        icon: Icons.warning_amber_rounded,
        accentColor: const Color(0xFFEF4444),
        buttonLabel: 'Try Example: Progressive Collapse Retrofit',
        onTry: () {
          Navigator.of(context).pop();
          onTrySeismicAndCollapse();
        },
      ),
      _CapabilityWorkflowCardData(
        number: '04',
        title: 'Bridge Moving Loads & 3D Connections',
        standard: 'AASHTO LRFD HL-93 & AISC 360-16 Ch. J',
        description:
            'Scrub a 325 kN AASHTO HL-93 Design Truck across a 36m Pratt Highway Truss Bridge in 40 DSM steps to plot influence lines η(x) & fatigue Δf, and synthesize 3D bolted shear tabs, moment end-plates, and Whitmore gussets.',
        deliverables: '40-Step P/V/M Envelopes • Influence Line η(x) • 3D Hex-Bolt Mesh',
        icon: Icons.local_shipping_rounded,
        accentColor: const Color(0xFF38BDF8),
        buttonLabel: 'Try Example: HL-93 Bridge Moving Load',
        onTry: () {
          Navigator.of(context).pop();
          onTryBridgeMovingLoads();
        },
      ),
      _CapabilityWorkflowCardData(
        number: '05',
        title: 'AI Tonnage & 3D Topology Optimization',
        standard: 'Neural SIMP, WebGPU B=256 Pareto & 4-Agent Swarm',
        description:
            'Auto-size W-shapes or deploy the 4-Agent Autonomous Swarm and 3D Diagrid Topology Synthesizer to reduce structural steel tonnage and SE 2050 embodied carbon by 15% to 30% while keeping DCR ≤ 0.95.',
        deliverables: '18–30% Steel Weight Savings • 60 FPS Pareto Trade-Off Frontier',
        icon: Icons.auto_awesome_rounded,
        accentColor: const Color(0xFFA855F7),
        buttonLabel: 'Try Example: AI Auto-Sizer & Swarm',
        onTry: () {
          Navigator.of(context).pop();
          onTryAiOptimization();
        },
      ),
      _CapabilityWorkflowCardData(
        number: '06',
        title: 'Stamped PE Packets & OpenBIM Deliverables',
        standard: 'HMAC-SHA256 PE Seal • IFC 4.3 • SAP2000 .s2k • DXF',
        description:
            'Export tamper-evident Professional Engineer (PE) calculation packets with step-by-step code equations and cryptographic HMAC-SHA256 verification, or export directly to ETABS/SAP2000 (.s2k), IFC 4.3, AutoCAD (.dxf), and BOM (.csv).',
        deliverables: 'Signed PE Calculation Packet • .s2k / .ifc / .dxf / .csv Takeoff',
        icon: Icons.verified_user_rounded,
        accentColor: const Color(0xFFF59E0B),
        buttonLabel: 'Try Example: Stamped PE Calculation Packet',
        onTry: () {
          Navigator.of(context).pop();
          onTryPeAndBimDeliverables();
        },
      ),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: GlassPod(
        width: 980,
        height: 670,
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.compass_calibration_rounded,
                          color: Color(0xFF00F0FF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Flexible(
                                  child: Text(
                                    'CAPABILITIES & WORKFLOWS — WHAT CAN YOU BUILD IN STRUCTURA NEXUS?',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6),
                                InfoTooltip(
                                  title: 'Role-Based Civil & Structural Engineering Guide',
                                  standardOrRange: '1. Geometry → 2. Loads → 3. Analysis → 4. Design → 5. BIM/PE',
                                  description:
                                      'Click any "Try Example" button below to launch a live, pre-configured engineering workflow directly in the 3D workstation.',
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Follow the 5-Stage Pipeline in the top header (1. GEOMETRY → 2. LOADS & SUPPORTS → 3. ANALYSIS → 4. DESIGN & OPTIMIZE → 5. REPORTS & BIM)',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  tooltip: 'Close Capabilities Overview',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 6 Core Engineering Workflow Cards (2-Column Responsive Grid)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate((cards.length / 2).ceil(), (rowIdx) {
                    final first = cards[rowIdx * 2];
                    final second = (rowIdx * 2 + 1 < cards.length) ? cards[rowIdx * 2 + 1] : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildWorkflowCard(first)),
                          const SizedBox(width: 12),
                          if (second != null)
                            Expanded(child: _buildWorkflowCard(second))
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Tip: Hover any (i) badge across the workstation for governing code formulas & target engineering ranges, or press ⌘K / Ctrl+K to search.',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white60, fontSize: 10.5),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('RETURN TO 3D WORKSTATION', style: TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowCard(_CapabilityWorkflowCardData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.accentColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: data.accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(data.icon, color: data.accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.number}. ${data.title}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      data.standard,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: data.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              InfoTooltip(
                title: data.title,
                standardOrRange: data.standard,
                description: '${data.description}\nDeliverables: ${data.deliverables}',
                size: 15,
                iconColor: data.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 10.5,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Outputs: ${data.deliverables}',
            style: const TextStyle(
              color: Color(0xFF7EE787),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: data.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: Text(
                data.buttonLabel,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
              ),
              onPressed: data.onTry,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityWorkflowCardData {
  final String number;
  final String title;
  final String standard;
  final String description;
  final String deliverables;
  final IconData icon;
  final Color accentColor;
  final String buttonLabel;
  final VoidCallback onTry;

  const _CapabilityWorkflowCardData({
    required this.number,
    required this.title,
    required this.standard,
    required this.description,
    required this.deliverables,
    required this.icon,
    required this.accentColor,
    required this.buttonLabel,
    required this.onTry,
  });
}
