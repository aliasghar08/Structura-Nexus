import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/firebase_auth_service.dart';

class WorkstationHeader extends StatelessWidget {
  final StructuralModel model;
  final bool isBackendConnected;
  final Function(EngineType) onEngineChanged;
  final Function(DisplayMode) onModeChanged;
  final Function(double) onDeformationScaleChanged;
  final Function(String) onPresetSelected;
  final VoidCallback onSolveTriggered;
  final VoidCallback? onOpenCopilot;
  final VoidCallback? onOpenGenerativeOptimizer;
  final VoidCallback? onOpenSeismicModal;
  final VoidCallback? onOpenEmbodiedCarbon;
  final VoidCallback? onOpenLibrary;
  final VoidCallback? onOpenCadStudio;
  final VoidCallback? onOpenAuth;
  final VoidCallback? onOpenPePacket;
  final VoidCallback? onOpenGenerativeBracing;

  const WorkstationHeader({
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
    this.onOpenSeismicModal,
    this.onOpenEmbodiedCarbon,
    this.onOpenLibrary,
    this.onOpenCadStudio,
    this.onOpenAuth,
    this.onOpenPePacket,
    this.onOpenGenerativeBracing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
          // 1. Branding
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/structura_nexus_icon.jpeg',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F6FEB), Color(0xFF00F0FF)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.architecture_rounded, size: 18, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'STRUCTURA FORGE AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF21262D),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'v3.4.0-REV-A',
                          style: TextStyle(color: Color(0xFF58A6FF), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Civil & Structural AI Engineering Workstation  •  AISC 360 / ACI 318',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          // 2. Benchmark Presets Dropdown
          _buildPresetDropdown(),
          const SizedBox(width: 16),
          // AI Intelligence Action Buttons
          _buildAiActionButton(
            label: 'AI Copilot',
            icon: Icons.psychology_rounded,
            color: const Color(0xFF00F0FF),
            onTap: onOpenCopilot,
          ),
          const SizedBox(width: 8),
          _buildAiActionButton(
            label: 'Generative Opt',
            icon: Icons.hub_rounded,
            color: const Color(0xFF10B981),
            onTap: onOpenGenerativeOptimizer,
          ),
          const SizedBox(width: 8),
          _buildAiActionButton(
            label: 'Modal Seismic',
            icon: Icons.waves_rounded,
            color: const Color(0xFF38BDF8),
            onTap: onOpenSeismicModal,
          ),
          const SizedBox(width: 8),
          _buildAiActionButton(
            label: 'Embodied Carbon',
            icon: Icons.eco_rounded,
            color: const Color(0xFF34D399),
            onTap: onOpenEmbodiedCarbon,
          ),
          const SizedBox(width: 14),
          // CAD Studio & Cloud Library Buttons
          _buildAiActionButton(
            label: 'CAD Studio',
            icon: Icons.architecture_rounded,
            color: const Color(0xFFF59E0B),
            onTap: onOpenCadStudio,
          ),
          const SizedBox(width: 8),
          _buildAiActionButton(
            label: 'Cloud Library',
            icon: Icons.folder_special_rounded,
            color: const Color(0xFFA855F7),
            onTap: onOpenLibrary,
          ),
          const SizedBox(width: 8),
          _buildAiActionButton(
            label: 'PE Calcs & BIM',
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFF00F0FF),
            onTap: onOpenPePacket,
          ),
          const SizedBox(width: 8),
          _buildAiActionButton(
            label: 'Gen Bracing',
            icon: Icons.auto_awesome_rounded,
            color: Colors.purpleAccent,
            onTap: onOpenGenerativeBracing,
          ),
          const SizedBox(width: 16),
          // 3. Dual Engine Selector
          _buildEngineSelector(),
          const SizedBox(width: 24),
          // 4. Viewport Display Mode Switcher
          _buildDisplayModeSelector(),
          const SizedBox(width: 16),
          // 5. Deformation Amplification Slider
          _buildDeformationSlider(),
          const SizedBox(width: 16),
          // 6. Backend Connection Indicator & Solve Trigger
          _buildConnectionIndicator(),
          const SizedBox(width: 16),
          // 7. Firebase Auth Profile
          _buildUserProfileButton(),
        ],
      ),
    ),
  );
  }

  Widget _buildUserProfileButton() {
    final user = FirebaseAuthService().currentUser;
    final isLoggedIn = user != null && !user.isAnonymous;

    return InkWell(
      onTap: onOpenAuth,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isLoggedIn
              ? const Color(0xFF238636).withValues(alpha: 0.18)
              : const Color(0xFF1F6FEB).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLoggedIn ? const Color(0xFF2EA043) : const Color(0xFF1F6FEB).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLoggedIn ? Icons.cloud_done_rounded : Icons.account_circle_outlined,
              size: 16,
              color: isLoggedIn ? const Color(0xFF3FB950) : const Color(0xFF58A6FF),
            ),
            const SizedBox(width: 6),
            Text(
              isLoggedIn
                  ? (user.displayName ?? user.email?.split('@').first ?? 'Account')
                  : 'Cloud / Sign In',
              style: TextStyle(
                color: isLoggedIn ? const Color(0xFF3FB950) : const Color(0xFF58A6FF),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
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

  Widget _buildEngineSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEngineBtn(EngineType.hybridDual, 'HYBRID DUAL', Icons.auto_awesome),
          _buildEngineBtn(EngineType.surrogateGnn, 'GNN SURROGATE (<40ms)', Icons.speed),
          _buildEngineBtn(EngineType.exactFea, 'EXACT MATRIX FEA', Icons.calculate_outlined),
        ],
      ),
    );
  }

  Widget _buildEngineBtn(EngineType type, String label, IconData icon) {
    final isSelected = model.activeEngine == type;
    return InkWell(
      onTap: () => onEngineChanged(type),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F6FEB) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: isSelected ? Colors.white : Colors.white54),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('MAGNIFY: ', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        Text('${model.deformationScale.toInt()}x', style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold)),
        SizedBox(
          width: 90,
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
    );
  }

  Widget _buildConnectionIndicator() {
    return InkWell(
      onTap: onSolveTriggered,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isBackendConnected ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFF21262D),
          border: Border.all(color: isBackendConnected ? const Color(0xFF10B981) : Colors.white24),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
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
      ),
    );
  }

  Widget _buildAiActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
