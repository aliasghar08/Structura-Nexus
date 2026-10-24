import 'package:flutter/material.dart';
import '../models/structural_models.dart';

class InspectorPanel extends StatelessWidget {
  final StructuralModel model;
  final String? selectedNodeId;
  final String? selectedMemberId;
  final VoidCallback onModelChanged;

  const InspectorPanel({
    super.key,
    required this.model,
    this.selectedNodeId,
    this.selectedMemberId,
    required this.onModelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inspector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                Icon(
                  selectedNodeId != null
                      ? Icons.adjust_rounded
                      : (selectedMemberId != null ? Icons.linear_scale_rounded : Icons.info_outline_rounded),
                  size: 16,
                  color: const Color(0xFF00F0FF),
                ),
                const SizedBox(width: 8),
                Text(
                  selectedNodeId != null
                      ? 'JOINT INSPECTOR: $selectedNodeId'
                      : (selectedMemberId != null
                          ? 'MEMBER DOSSIER: $selectedMemberId'
                          : 'SELECTION INSPECTOR'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (selectedNodeId != null) ...[
                  _buildNodeInspector(model.getNode(selectedNodeId!)!),
                ] else if (selectedMemberId != null) ...[
                  _buildMemberInspector(
                    model.members.firstWhere((m) => m.id == selectedMemberId),
                  ),
                ] else ...[
                  _buildEmptyState(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.touch_app_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        const Text(
          'No Entity Selected',
          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Click any joint node or frame member in the 3D viewport to inspect boundary conditions, internal tensors, and AISC 360-16 limit states.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildNodeInspector(StructuralNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('COORDINATES [X, Y, Z] (m)'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildCoordField('X', node.coords.x, (v) => node.coords.x = v)),
            const SizedBox(width: 6),
            Expanded(child: _buildCoordField('Y', node.coords.y, (v) => node.coords.y = v)),
            const SizedBox(width: 6),
            Expanded(child: _buildCoordField('Z', node.coords.z, (v) => node.coords.z = v)),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('6-DOF BOUNDARY RESTRAINTS (DIRICHLET)'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildRestraintChip('Rx', node.restraint[0] == 1, (val) => node.restraint[0] = val ? 1 : 0),
            _buildRestraintChip('Ry', node.restraint[1] == 1, (val) => node.restraint[1] = val ? 1 : 0),
            _buildRestraintChip('Rz', node.restraint[2] == 1, (val) => node.restraint[2] = val ? 1 : 0),
            _buildRestraintChip('Rmx', node.restraint[3] == 1, (val) => node.restraint[3] = val ? 1 : 0),
            _buildRestraintChip('Rmy', node.restraint[4] == 1, (val) => node.restraint[4] = val ? 1 : 0),
            _buildRestraintChip('Rmz', node.restraint[5] == 1, (val) => node.restraint[5] = val ? 1 : 0),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('APPLIED POINT FORCES (N)'),
        const SizedBox(height: 8),
        _buildLoadInputRow('Fx (Lateral Wind)', node.loads[0], (v) => node.loads[0] = v),
        _buildLoadInputRow('Fy (Gravity/Dead)', node.loads[1], (v) => node.loads[1] = v),
        _buildLoadInputRow('Fz (Transverse)', node.loads[2], (v) => node.loads[2] = v),
        const SizedBox(height: 16),
        _buildSectionTitle('SOLVED NODAL DISPLACEMENTS'),
        const SizedBox(height: 8),
        _buildReadoutRow('Deflection Δx', '${(node.displacements[0] * 1000).toStringAsFixed(3)} mm'),
        _buildReadoutRow('Deflection Δy', '${(node.displacements[1] * 1000).toStringAsFixed(3)} mm'),
        _buildReadoutRow('Deflection Δz', '${(node.displacements[2] * 1000).toStringAsFixed(3)} mm'),
        const SizedBox(height: 16),
        _buildSectionTitle('EQUILIBRIUM REACTIONS'),
        const SizedBox(height: 8),
        _buildReadoutRow('Rx Support', '${(node.reactions[0] / 1000).toStringAsFixed(2)} kN'),
        _buildReadoutRow('Ry Support', '${(node.reactions[1] / 1000).toStringAsFixed(2)} kN'),
        _buildReadoutRow('Rz Support', '${(node.reactions[2] / 1000).toStringAsFixed(2)} kN'),
      ],
    );
  }

  Widget _buildMemberInspector(StructuralMember member) {
    final sec = SectionProfile.catalog[member.section] ?? SectionProfile.catalog['W14X48']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('AISC STEEL PROFILE'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: member.section,
              isExpanded: true,
              dropdownColor: const Color(0xFF161B22),
              items: SectionProfile.catalog.keys.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                    '$name (${SectionProfile.catalog[name]!.weightKgM.toStringAsFixed(1)} kg/m)',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: (newSec) {
                if (newSec != null) {
                  member.section = newSec;
                  onModelChanged();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('SECTION CHARACTERISTICS'),
        const SizedBox(height: 8),
        _buildReadoutRow('Cross Area Ag', '${(sec.areaM2 * 10000).toStringAsFixed(2)} cm²'),
        _buildReadoutRow('Major Inertia Ix', '${(sec.ixM4 * 1e8).toStringAsFixed(1)} cm⁴'),
        _buildReadoutRow('Minor Inertia Iy', '${(sec.iyM4 * 1e8).toStringAsFixed(1)} cm⁴'),
        _buildReadoutRow('Radius of Gyration rx', '${(sec.rxM * 100).toStringAsFixed(2)} cm'),
        _buildReadoutRow('Radius of Gyration ry', '${(sec.ryM * 100).toStringAsFixed(2)} cm'),
        _buildReadoutRow('Slenderness KL/r', member.slendernessKlR.toStringAsFixed(1)),
        const SizedBox(height: 16),
        _buildSectionTitle('AISC 360-16 LIMIT STATES'),
        const SizedBox(height: 8),
        _buildDcrIndicator('Axial Capacity DCR', member.dcrAxial),
        _buildDcrIndicator('Flexural Buckling DCR', member.dcrBuckling),
        _buildDcrIndicator('Combined P-M DCR', member.dcrCombined),
        _buildDcrIndicator('Beam Shear DCR', member.dcrShear),
        const SizedBox(height: 16),
        _buildSectionTitle('INTERNAL FORCE TENSORS'),
        const SizedBox(height: 8),
        _buildReadoutRow('Axial Force (N)', '${(member.axialForceN / 1000).toStringAsFixed(2)} kN'),
        _buildReadoutRow('Shear Vy', '${(member.shearY / 1000).toStringAsFixed(2)} kN'),
        _buildReadoutRow('Bending Mz', '${(member.momentZ / 1000).toStringAsFixed(2)} kN·m'),
        _buildReadoutRow('Von Mises Stress', '${member.maxVonMisesMpa.toStringAsFixed(1)} MPa'),
        if (member.recommendedSection != null && member.recommendedSection != member.section) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 AI SECTION OPTIMIZER RECOMMENDATION',
                  style: TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upgrade to ${member.recommendedSection} for optimal DCR ≤ 0.90.',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    member.section = member.recommendedSection!;
                    onModelChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Apply Optimal Section', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildCoordField(String axis, double value, Function(double) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Text('$axis: ', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Expanded(
            child: Text(
              value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestraintChip(String label, bool isRestrained, Function(bool) onToggle) {
    return FilterChip(
      label: Text(label, style: TextStyle(color: isRestrained ? Colors.black : Colors.white70, fontSize: 10)),
      selected: isRestrained,
      selectedColor: const Color(0xFF00F0FF),
      backgroundColor: const Color(0xFF0D1117),
      checkmarkColor: Colors.black,
      onSelected: (val) {
        onToggle(val);
        onModelChanged();
      },
    );
  }

  Widget _buildLoadInputRow(String label, double val, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(
            '${(val / 1000).toStringAsFixed(1)} kN',
            style: const TextStyle(color: Color(0xFFFACC15), fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReadoutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDcrIndicator(String label, double dcr) {
    final isFail = dcr > 1.0;
    final isWarn = dcr > 0.85;
    final color = isFail ? const Color(0xFFFF0055) : (isWarn ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(
                '${(dcr * 100).toStringAsFixed(1)}% (DCR ${dcr.toStringAsFixed(3)})',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: (dcr / 1.2).clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }
}
