// ============================================================================
// FloatingWorkstationHeader — Apple visionOS Floating Glass Header Island
// Multi-layer frosted glass, specular rim-light & top-level tools menus
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/firebase_auth_service.dart';
import 'glass_pod.dart';

class FloatingWorkstationHeader extends StatelessWidget {
  final StructuralModel model;
  final bool isBackendConnected;
  final Function(EngineType) onEngineChanged;
  final Function(DisplayMode) onModeChanged;
  final Function(double) onDeformationScaleChanged;
  final Function(String) onPresetSelected;
  final VoidCallback onSolveTriggered;
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
  final VoidCallback? onOpenAuth;
  final VoidCallback? onOpenDrawer;

  const FloatingWorkstationHeader({
    super.key,
    required this.model,
    required this.isBackendConnected,
    required this.onEngineChanged,
    required this.onModeChanged,
    required this.onDeformationScaleChanged,
    required this.onPresetSelected,
    required this.onSolveTriggered,
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
    this.onOpenAuth,
    this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            // 0. Drawer Toggle Pill (Quick Drawer Access)
            if (onOpenDrawer != null) ...[
              GlassPod(
                padding: const EdgeInsets.all(8),
                borderRadius: 16,
                onTap: onOpenDrawer,
                child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
            ],

            // 1. Brand Capsule
            GlassPod(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              borderRadius: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF0072FF)]),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF00F0FF).withValues(alpha: 0.4), blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.architecture_rounded, color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 10),
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
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
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
                        "Autonomous Workstation • AISC 360 / ACI 318",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // 2. Central Navigation Pill (Tools & Suite, AI & Gen, CAD & BIM, Analysis)
            GlassPod(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              borderRadius: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToolsSuiteDropdown(),
                  const SizedBox(width: 6),
                  _buildCategoryMenu(
                    label: 'AI & GEN',
                    icon: Icons.psychology_rounded,
                    accentColor: const Color(0xFF00F0FF),
                    items: [
                      _MenuItemDef(
                        icon: Icons.psychology_rounded,
                        color: const Color(0xFF00F0FF),
                        title: 'AI Copilot',
                        subtitle: 'Gemini 1.5 Pro Structural Agent',
                        badge: 'GEMINI',
                        onTap: onOpenCopilot,
                      ),
                      _MenuItemDef(
                        icon: Icons.hub_rounded,
                        color: const Color(0xFF10B981),
                        title: 'Generative Opt',
                        subtitle: 'Neural Profile Auto-Sizer',
                        badge: 'GNN',
                        onTap: onOpenGenerativeOptimizer,
                      ),
                      _MenuItemDef(
                        icon: Icons.auto_awesome_rounded,
                        color: const Color(0xFF8B5CF6),
                        title: 'Gen Bracing',
                        subtitle: 'Automated Topology Placement',
                        badge: 'TOPOLOGY',
                        onTap: onOpenGenerativeBracing,
                      ),
                      _MenuItemDef(
                        icon: Icons.tune_rounded,
                        color: const Color(0xFF00F0FF),
                        title: 'Auto-Sizer',
                        subtitle: 'AISC 360 Weight Minimization',
                        badge: 'AISC',
                        onTap: onOptimize,
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  _buildCategoryMenu(
                    label: 'CAD & BIM',
                    icon: Icons.architecture_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    items: [
                      _MenuItemDef(
                        icon: Icons.architecture_rounded,
                        color: const Color(0xFFF59E0B),
                        title: 'CAD Studio',
                        subtitle: '2D / 3D Parametric Framework',
                        badge: '3D/2D',
                        onTap: onOpenCadStudio,
                      ),
                      _MenuItemDef(
                        icon: Icons.folder_special_rounded,
                        color: const Color(0xFFA855F7),
                        title: 'Cloud Library',
                        subtitle: 'AISC Catalog & DXF / BOM Export',
                        badge: 'DXF',
                        onTap: onOpenLibrary,
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  _buildCategoryMenu(
                    label: 'ANALYSIS',
                    icon: Icons.waves_rounded,
                    accentColor: const Color(0xFFEC4899),
                    items: [
                      _MenuItemDef(
                        icon: Icons.waves_rounded,
                        color: const Color(0xFFEC4899),
                        title: 'Modal Seismic',
                        subtitle: 'Dynamic Vibration Eigenvalues',
                        badge: 'EIGEN',
                        onTap: onOpenSeismicModal,
                      ),
                      _MenuItemDef(
                        icon: Icons.domain_rounded,
                        color: const Color(0xFF06B6D4),
                        title: 'Lateral Stability',
                        subtitle: 'ASCE 7 Drift & P-Δ Second-Order',
                        badge: 'ASCE 7',
                        onTap: onOpenLateralStability,
                      ),
                      _MenuItemDef(
                        icon: Icons.assignment_turned_in_rounded,
                        color: const Color(0xFF10B981),
                        title: 'PE Calcs & BIM',
                        subtitle: 'Stamped Engineering Packet',
                        badge: 'PE STAMP',
                        onTap: onOpenPePacket,
                      ),
                      _MenuItemDef(
                        icon: Icons.eco_rounded,
                        color: const Color(0xFF14B8A6),
                        title: 'Embodied Carbon',
                        subtitle: 'EC3 Life Cycle Assessment',
                        badge: 'EC3',
                        onTap: onOpenEmbodiedCarbon,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // 3. Benchmark Presets Dropdown
            _buildPresetDropdown(),
            const SizedBox(width: 10),

            // 4. Dual Engine Mode Pill Switcher
            GlassPod(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              borderRadius: 18,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _engineBadge(EngineType.hybridDual, "HYBRID DUAL"),
                  const SizedBox(width: 4),
                  _engineBadge(EngineType.surrogateGnn, "GNN SURROGATE (<40ms)"),
                  const SizedBox(width: 4),
                  _engineBadge(EngineType.exactFea, "EXACT MATRIX FEA"),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // 5. Display Mode Selector & Magnify Slider
            _buildDisplayModeSelector(),
            const SizedBox(width: 10),

            _buildDeformationSlider(),
            const SizedBox(width: 10),

            // 6. Backend Connection Indicator & Solve Trigger
            _buildConnectionIndicator(),
            const SizedBox(width: 10),

            // 7. Firebase Auth Profile
            _buildUserProfileButton(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Primary Tools & Suite Dropdown Menu
  // --------------------------------------------------------------------------
  Widget _buildToolsSuiteDropdown() {
    return PopupMenuButton<VoidCallback>(
      tooltip: 'Engineering Tools & Suite Menu',
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
      ),
      offset: const Offset(0, 48),
      onSelected: (cb) => cb(),
      itemBuilder: (context) => [
        _buildCategoryHeader('AI & GENERATIVE'),
        _buildPopupItem(
          icon: Icons.psychology_rounded,
          color: const Color(0xFF00F0FF),
          title: 'AI Copilot',
          subtitle: 'Gemini 1.5 Pro Structural Agent',
          badge: 'GEMINI',
          onTap: onOpenCopilot,
        ),
        _buildPopupItem(
          icon: Icons.hub_rounded,
          color: const Color(0xFF10B981),
          title: 'Generative Opt',
          subtitle: 'Neural Profile Auto-Sizer',
          badge: 'GNN',
          onTap: onOpenGenerativeOptimizer,
        ),
        _buildPopupItem(
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFF8B5CF6),
          title: 'Gen Bracing',
          subtitle: 'Automated Topology Placement',
          badge: 'TOPOLOGY',
          onTap: onOpenGenerativeBracing,
        ),
        _buildPopupItem(
          icon: Icons.tune_rounded,
          color: const Color(0xFF00F0FF),
          title: 'Auto-Sizer',
          subtitle: 'AISC 360 Weight Minimization',
          badge: 'AISC',
          onTap: onOptimize,
        ),
        const PopupMenuDivider(),
        _buildCategoryHeader('MODELING & CAD'),
        _buildPopupItem(
          icon: Icons.architecture_rounded,
          color: const Color(0xFFF59E0B),
          title: 'CAD Studio',
          subtitle: '2D / 3D Parametric Framework',
          badge: '3D/2D',
          onTap: onOpenCadStudio,
        ),
        _buildPopupItem(
          icon: Icons.folder_special_rounded,
          color: const Color(0xFFA855F7),
          title: 'Cloud Library',
          subtitle: 'AISC Catalog & DXF / BOM Export',
          badge: 'DXF',
          onTap: onOpenLibrary,
        ),
        const PopupMenuDivider(),
        _buildCategoryHeader('ANALYSIS & DESIGN'),
        _buildPopupItem(
          icon: Icons.waves_rounded,
          color: const Color(0xFFEC4899),
          title: 'Modal Seismic',
          subtitle: 'Dynamic Vibration Eigenvalues',
          badge: 'EIGEN',
          onTap: onOpenSeismicModal,
        ),
        _buildPopupItem(
          icon: Icons.domain_rounded,
          color: const Color(0xFF06B6D4),
          title: 'Lateral Stability',
          subtitle: 'ASCE 7 Drift & P-Δ Second-Order',
          badge: 'ASCE 7',
          onTap: onOpenLateralStability,
        ),
        _buildPopupItem(
          icon: Icons.assignment_turned_in_rounded,
          color: const Color(0xFF10B981),
          title: 'PE Calcs & BIM',
          subtitle: 'Stamped Engineering Packet',
          badge: 'PE STAMP',
          onTap: onOpenPePacket,
        ),
        _buildPopupItem(
          icon: Icons.eco_rounded,
          color: const Color(0xFF14B8A6),
          title: 'Embodied Carbon',
          subtitle: 'EC3 Life Cycle Assessment',
          badge: 'EC3',
          onTap: onOpenEmbodiedCarbon,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F6FEB), Color(0xFF00F0FF)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.tune_rounded, size: 14, color: Colors.black),
            SizedBox(width: 6),
            Text(
              'TOOLS & SUITE',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryMenu({
    required String label,
    required IconData icon,
    required Color accentColor,
    required List<_MenuItemDef> items,
  }) {
    return PopupMenuButton<VoidCallback>(
      tooltip: '$label Suite Menu',
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
      ),
      offset: const Offset(0, 44),
      onSelected: (cb) => cb(),
      itemBuilder: (context) => items
          .map(
            (item) => _buildPopupItem(
              icon: item.icon,
              color: item.color,
              title: item.title,
              subtitle: item.subtitle,
              badge: item.badge,
              onTap: item.onTap,
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: accentColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.arrow_drop_down_rounded, size: 15, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  PopupMenuEntry<VoidCallback> _buildCategoryHeader(String title) {
    return PopupMenuItem<VoidCallback>(
      enabled: false,
      height: 24,
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  PopupMenuItem<VoidCallback> _buildPopupItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback? onTap,
  }) {
    return PopupMenuItem<VoidCallback>(
      value: onTap ?? () {},
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _engineBadge(EngineType type, String label) {
    final isSelected = model.activeEngine == type;
    return GestureDetector(
      onTap: () => onEngineChanged(type),
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
              onPresetSelected(val);
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
          value: model.displayMode,
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
            if (newMode != null) onModeChanged(newMode);
          },
        ),
      ),
    );
  }

  Widget _buildDeformationSlider() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      borderRadius: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('MAGNIFY: ', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          Text('${model.deformationScale.toInt()}x', style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold)),
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                activeTrackColor: const Color(0xFF00F0FF),
                inactiveTrackColor: Colors.white10,
                thumbColor: const Color(0xFF00F0FF),
              ),
              child: Slider(
                value: model.deformationScale,
                min: 1.0,
                max: 100.0,
                onChanged: onDeformationScaleChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    return GlassPod(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      borderRadius: 18,
      onTap: onSolveTriggered,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isBackendConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isBackendConnected ? 'LIVE ENGINE' : 'OFFLINE ENGINE',
            style: TextStyle(
              color: isBackendConnected ? const Color(0xFF10B981) : Colors.white70,
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
      onTap: onOpenAuth,
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

class _MenuItemDef {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback? onTap;

  const _MenuItemDef({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });
}
