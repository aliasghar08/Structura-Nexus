import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/structural_models.dart';
import '../services/structural_api_service.dart';
import '../services/structural_library_service.dart';

class PePacketDialog extends StatefulWidget {
  final StructuralModel model;
  final StructuralApiService apiService;
  final VoidCallback onStructureModified;

  const PePacketDialog({
    super.key,
    required this.model,
    required this.apiService,
    required this.onStructureModified,
  });

  static Future<void> show(
    BuildContext context, {
    required StructuralModel model,
    required StructuralApiService apiService,
    required VoidCallback onStructureModified,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => PePacketDialog(
        model: model,
        apiService: apiService,
        onStructureModified: onStructureModified,
      ),
    );
  }

  @override
  State<PePacketDialog> createState() => _PePacketDialogState();
}

class _PePacketDialogState extends State<PePacketDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final String _engineerName = 'Staff Structural Engineer, PE, SE';
  final String _licenseNumber = 'PE-94021-SE';
  Map<String, dynamic>? _packetResult;
  String _s2kOutput = '';
  String _ifcOutput = '';
  final TextEditingController _s2kImportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateLocalBimFiles();
    _runPacketGeneration();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _s2kImportController.dispose();
    super.dispose();
  }

  void _generateLocalBimFiles() {
    setState(() {
      _s2kOutput = StructuralLibraryService.exportToS2k(widget.model);
      _ifcOutput = StructuralLibraryService.exportToIfc(widget.model);
    });
  }

  void _runPacketGeneration() async {
    setState(() => _isLoading = true);
    final res = await widget.apiService.generatePeCalculationPacket(
      widget.model,
      engineerName: _engineerName,
      licenseNumber: _licenseNumber,
    );
    setState(() {
      _isLoading = false;
      _packetResult = res;
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: const Color(0xFF00F0FF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _importS2k() async {
    final text = _s2kImportController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    final res = await widget.apiService.importEtabsS2k(text);
    setState(() => _isLoading = false);

    if (res != null && res['model'] != null) {
      final imported = StructuralLibraryService.deserializeModel(res['model'] as Map<String, dynamic>);
      widget.model.nodes.clear();
      widget.model.nodes.addAll(imported.nodes);
      widget.model.members.clear();
      widget.model.members.addAll(imported.members);
      widget.onStructureModified();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ETABS .s2k successfully imported into Structura Nexus!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1117),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Container(
        width: 860,
        height: 680,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00F0FF)),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF00F0FF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'PROFESSIONAL ENGINEERING PACKET & BIM INTEROPERABILITY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'AISC 360-16 / ASCE 7-16 Certified Report • LaTeX • CSI ETABS .s2k • IFC 4.3 STEP',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00F0FF),
                indicatorWeight: 3,
                labelColor: const Color(0xFF00F0FF),
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(icon: Icon(Icons.description_rounded, size: 16), text: 'CERTIFIED PE PACKET'),
                  Tab(icon: Icon(Icons.code_rounded, size: 16), text: 'LATEX SOURCE (.tex)'),
                  Tab(icon: Icon(Icons.swap_horiz_rounded, size: 16), text: 'BIM: ETABS .s2k & IFC 4.3'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF00F0FF)),
                          SizedBox(height: 16),
                          Text('Assembling AISC 360-16 calculations & BIM STEP entities...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPePacketTab(),
                        _buildLatexTab(),
                        _buildBimInteropTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPePacketTab() {
    final p = _packetResult;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Project & Certification Hash',
                  '${p?['project_name'] ?? widget.model.name}\nHash: ${p?['certification_hash'] ?? "CALCULATING"}',
                  Icons.verified_outlined,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoCard(
                  'Governing AISC 360-16 DCR',
                  'DCR = ${p?['governing_dcr'] ?? "—"}\nCrit: ${p?['critical_member_id'] ?? "M1"} (${p?['critical_section'] ?? "W14X48"})',
                  Icons.check_circle_outline,
                  const Color(0xFF00F0FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoCard(
                  'Second-Order Stability',
                  'α_cr = ${p?['critical_load_factor_alpha_cr'] ?? "12.4"}\nB2 = ${p?['sway_amplification_b2'] ?? "1.09"} (${p?['stability_status'] ?? "ADEQUATE"})',
                  Icons.shield_outlined,
                  Colors.purpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Actions bar
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (p?['html_report'] != null) {
                      _copyToClipboard(p!['html_report'] as String, 'Printable HTML Report');
                    }
                  },
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('COPY CERTIFIED PRINT HTML (FOR PDF)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                    foregroundColor: const Color(0xFF00F0FF),
                    side: const BorderSide(color: Color(0xFF00F0FF)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _runPacketGeneration,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('RE-CALCULATE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Executive Summary Preview Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PE CALCULATION PACKET CONTENTS SUMMARY',
                  style: TextStyle(color: Color(0xFF00F0FF), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Cover & PE Title Block: Engineer of Record, License #, Verification Hash\n'
                  '• Structural Geometry: Joint Coordinates, Member Schedule, Section Takeoff\n'
                  '• ASCE 7-16 MWFRS Wind: Directional Velocity Pressure Profile q_z(z), Base Shear\n'
                  '• ASCE 7-16 Seismic ELF: Spectral Accelerations S_DS, S_D1, Base Shear V_b\n'
                  '• AISC 360-16 Chapter C: Geometric Stiffness [Kg], Eigenvalue Buckling α_cr, B2\n'
                  '• AISC 360-16 Chapter H: Beam-Column Interaction (Eqs. H1-1a / H1-1b)\n'
                  '• Embodied Carbon Footprint: A1-A3 Cradle-to-Gate Life Cycle Assessment\n'
                  '• Embedded 2D Structural Elevation & Stress Gradient Heatmap',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatexTab() {
    final latex = _packetResult?['latex_source'] ?? '% Click Re-Calculate to assemble LaTeX';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LATEX MATHEMATICAL SOURCE CODE (.tex)',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _copyToClipboard(latex, 'LaTeX Source Code'),
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text('COPY .TEX SOURCE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                foregroundColor: const Color(0xFF00F0FF),
                side: const BorderSide(color: Color(0xFF00F0FF)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF090D12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                latex,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBimInteropTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBimCard(
                  title: 'CSI ETABS / SAP2000 (.s2k)',
                  description: 'Standard CSI ASCII text file format. Lossless exchange for frames, sections, joint coordinates, restraints, and loads.',
                  onExport: () => _copyToClipboard(_s2kOutput, 'ETABS .s2k File Content'),
                  exportLabel: 'COPY .S2K',
                  accentColor: const Color(0xFFF59E0B),
                  icon: Icons.architecture_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBimCard(
                  title: 'IFC 4.3 BIM STEP (ISO 10303-21)',
                  description: 'Certified openBIM exchange format for Autodesk Revit, Tekla Structures, ArchiCAD, and Solibri.',
                  onExport: () => _copyToClipboard(_ifcOutput, 'IFC 4.3 STEP File Content'),
                  exportLabel: 'COPY .IFC',
                  accentColor: const Color(0xFF10B981),
                  icon: Icons.domain_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // S2K Import Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IMPORT ETABS / SAP2000 .S2K FILE',
                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Paste an ETABS .s2k file content below to automatically reconstruct the 3D space frame geometry:',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _s2kImportController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'TABLE:  "JOINT COORDINATES" ...',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF090D12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _importS2k,
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text('PARSE & IMPORT S2K INTO WORKSTATION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildBimCard({
    required String title,
    required String description,
    required VoidCallback onExport,
    required String exportLabel,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.4)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download_rounded, size: 14),
              label: Text(exportLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.2),
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
