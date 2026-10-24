import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/structural_api_service.dart';

class LateralStabilityDialog extends StatefulWidget {
  final StructuralModel model;
  final StructuralApiService apiService;
  final VoidCallback onStructureModified;

  const LateralStabilityDialog({
    super.key,
    required this.model,
    required this.apiService,
    required this.onStructureModified,
  });

  static void show(
    BuildContext context, {
    required StructuralModel model,
    required StructuralApiService apiService,
    required VoidCallback onStructureModified,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => LateralStabilityDialog(
        model: model,
        apiService: apiService,
        onStructureModified: onStructureModified,
      ),
    );
  }

  @override
  State<LateralStabilityDialog> createState() => _LateralStabilityDialogState();
}

class _LateralStabilityDialogState extends State<LateralStabilityDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Wind state
  double _windSpeed = 45.0; // m/s
  String _exposure = 'B';
  String _riskCategory = 'II';
  String _windDirection = '+X';
  Map<String, dynamic>? _windResult;

  // Seismic state
  double _ss = 1.25; // g
  double _s1 = 0.50; // g
  String _siteClass = 'D';
  double _rFactor = 8.0; // SMF
  String _seismicDirection = '+X';
  Map<String, dynamic>? _seismicResult;

  // Buckling state
  Map<String, dynamic>? _bucklingResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _runWindGeneration() async {
    setState(() => _isLoading = true);
    final res = await widget.apiService.generateAsce7Wind(
      widget.model,
      speedMs: _windSpeed,
      exposure: _exposure,
      riskCategory: _riskCategory,
      direction: _windDirection,
    );
    setState(() {
      _isLoading = false;
      _windResult = res;
      if (res != null && res['updated_nodes'] != null) {
        widget.model.applyUpdatedNodes(res['updated_nodes'] as List);
        widget.onStructureModified();
      }
    });
  }

  void _runSeismicGeneration() async {
    setState(() => _isLoading = true);
    final res = await widget.apiService.generateAsce7Seismic(
      widget.model,
      ss: _ss,
      s1: _s1,
      siteClass: _siteClass,
      rFactor: _rFactor,
      direction: _seismicDirection,
    );
    setState(() {
      _isLoading = false;
      _seismicResult = res;
      if (res != null && res['updated_nodes'] != null) {
        widget.model.applyUpdatedNodes(res['updated_nodes'] as List);
        widget.onStructureModified();
      }
    });
  }

  void _runBucklingAnalysis() async {
    setState(() => _isLoading = true);
    final res = await widget.apiService.analyzeBuckling(widget.model);
    setState(() {
      _isLoading = false;
      _bucklingResult = res;
      if (res != null) {
        widget.model.criticalLoadFactorAlphaCr = (res['critical_load_factor_alpha_cr'] as num?)?.toDouble();
        widget.model.swayAmplificationB2 = (res['sway_amplification_b2'] as num?)?.toDouble();
        final modes = res['buckling_modes'] as List?;
        if (modes != null && modes.isNotEmpty) {
          widget.model.stabilityStatus = modes.first['aisc_stability_status'];
        }
      }
    });
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
        width: 820,
        height: 640,
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
                  child: const Icon(Icons.waves_rounded, color: Color(0xFF00F0FF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'LATERAL LOADS & SECOND-ORDER STABILITY ENGINE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'ASCE 7-16 MWFRS Wind • ELF Seismic Base Shear • Geometric Stiffness [Kg] & Eigenvalue Buckling (α_cr)',
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
            const SizedBox(height: 16),
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00F0FF),
                indicatorWeight: 3,
                labelColor: const Color(0xFF00F0FF),
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.air_rounded, size: 16), text: 'ASCE 7-16 WIND (MWFRS)'),
                  Tab(icon: Icon(Icons.vibration_rounded, size: 16), text: 'ASCE 7-16 SEISMIC (ELF)'),
                  Tab(icon: Icon(Icons.shield_rounded, size: 16), text: 'SECOND-ORDER BUCKLING (P-Δ)'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildWindTab(),
                        _buildSeismicTab(),
                        _buildBucklingTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildParameterCard(
                  title: 'Basic Wind Speed V',
                  value: '${_windSpeed.toStringAsFixed(1)} m/s (${(_windSpeed * 2.237).toStringAsFixed(0)} mph)',
                  child: Slider(
                    value: _windSpeed,
                    min: 35.0,
                    max: 65.0,
                    divisions: 30,
                    activeColor: const Color(0xFF00F0FF),
                    onChanged: (val) => setState(() => _windSpeed = val),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildParameterCard(
                  title: 'Exposure & Risk Category',
                  value: 'Exposure $_exposure • Risk Cat $_riskCategory',
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: _exposure,
                        dropdownColor: const Color(0xFF161B22),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: ['B', 'C', 'D'].map((e) => DropdownMenuItem(value: e, child: Text('Exp $e'))).toList(),
                        onChanged: (val) => setState(() => _exposure = val ?? 'B'),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _riskCategory,
                        dropdownColor: const Color(0xFF161B22),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: ['I', 'II', 'III', 'IV'].map((e) => DropdownMenuItem(value: e, child: Text('Risk $e'))).toList(),
                        onChanged: (val) => setState(() => _riskCategory = val ?? 'II'),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _windDirection,
                        dropdownColor: const Color(0xFF161B22),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: ['+X', '-X', '+Z', '-Z'].map((e) => DropdownMenuItem(value: e, child: Text('Dir $e'))).toList(),
                        onChanged: (val) => setState(() => _windDirection = val ?? '+X'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _runWindGeneration,
              icon: const Icon(Icons.flash_on_rounded, size: 16),
              label: const Text('GENERATE & APPLY MWFRS WIND PRESSURES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                foregroundColor: const Color(0xFF00F0FF),
                side: const BorderSide(color: Color(0xFF00F0FF)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_windResult != null) ...[
            const SizedBox(height: 16),
            _buildResultHeader(
              'Base Wind Shear: ${((_windResult!['total_base_wind_shear_n'] as num?)?.toDouble() ?? 0.0) / 1000.0} kN',
              'ASCE 7-16 Section 27.3.1 Directional Velocity Pressure Profile',
            ),
            const SizedBox(height: 8),
            _buildWindPressureTable(),
          ],
        ],
      ),
    );
  }

  Widget _buildSeismicTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildParameterCard(
                  title: 'Mapped MCE_R Parameters',
                  value: 'Ss = ${_ss.toStringAsFixed(2)}g • S1 = ${_s1.toStringAsFixed(2)}g',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 25, child: Text('Ss', style: TextStyle(color: Colors.white54, fontSize: 11))),
                          Expanded(
                            child: Slider(
                              value: _ss,
                              min: 0.25,
                              max: 2.50,
                              divisions: 45,
                              activeColor: const Color(0xFFF59E0B),
                              onChanged: (v) => setState(() => _ss = v),
                            ),
                          ),
                          Text('${_ss.toStringAsFixed(2)}g', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 25, child: Text('S1', style: TextStyle(color: Colors.white54, fontSize: 11))),
                          Expanded(
                            child: Slider(
                              value: _s1,
                              min: 0.10,
                              max: 1.20,
                              divisions: 22,
                              activeColor: const Color(0xFFF59E0B),
                              onChanged: (v) => setState(() => _s1 = v),
                            ),
                          ),
                          Text('${_s1.toStringAsFixed(2)}g', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildParameterCard(
                  title: 'Site Class & Framing System',
                  value: 'Site Class $_siteClass • R = ${_rFactor.toStringAsFixed(1)}',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownButton<String>(
                        value: _siteClass,
                        dropdownColor: const Color(0xFF161B22),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: ['A', 'B', 'C', 'D', 'E'].map((e) => DropdownMenuItem(value: e, child: Text('Site $e'))).toList(),
                        onChanged: (val) => setState(() => _siteClass = val ?? 'D'),
                      ),
                      DropdownButton<double>(
                        value: _rFactor,
                        dropdownColor: const Color(0xFF161B22),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: const [
                          DropdownMenuItem(value: 8.0, child: Text('R=8.0 (SMF)')),
                          DropdownMenuItem(value: 6.0, child: Text('R=6.0 (IMF)')),
                          DropdownMenuItem(value: 3.25, child: Text('R=3.25 (OCBF)')),
                          DropdownMenuItem(value: 3.0, child: Text('R=3.0 (Wall)')),
                        ],
                        onChanged: (val) => setState(() => _rFactor = val ?? 8.0),
                      ),
                      DropdownButton<String>(
                        value: _seismicDirection,
                        dropdownColor: const Color(0xFF161B22),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: ['+X', '+Z'].map((e) => DropdownMenuItem(value: e, child: Text('Dir $e'))).toList(),
                        onChanged: (val) => setState(() => _seismicDirection = val ?? '+X'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _runSeismicGeneration,
              icon: const Icon(Icons.bolt_rounded, size: 16),
              label: const Text('CALCULATE ELF BASE SHEAR & STOREY FORCES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                foregroundColor: const Color(0xFFF59E0B),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_seismicResult != null) ...[
            const SizedBox(height: 16),
            _buildResultHeader(
              'Base Shear V = ${_seismicResult!['base_shear_v_kn']} kN (Cs = ${_seismicResult!['cs']}, W = ${_seismicResult!['total_seismic_weight_kn']} kN)',
              'SDS = ${_seismicResult!['sds']}g • SD1 = ${_seismicResult!['sd1']}g • Ta = ${_seismicResult!['fundamental_period_sec']}s',
            ),
            const SizedBox(height: 8),
            _buildSeismicStoreyTable(),
          ],
        ],
      ),
    );
  }

  Widget _buildBucklingTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.purpleAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'AISC 360-16 Chapter C: Elastic Critical Buckling Analysis',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Assembles 12×12 element geometric stiffness matrices [Kg] based on axial forces P, solving generalized eigenvalue problem det([Ke] - λ[Kg]) = 0 for α_cr and B2 sway amplification.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _runBucklingAnalysis,
              icon: const Icon(Icons.psychology_rounded, size: 16),
              label: const Text('ASSEMBLE [Kg] & SOLVE CRITICAL BUCKLING (α_cr)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
                foregroundColor: Colors.purpleAccent,
                side: const BorderSide(color: Colors.purpleAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_bucklingResult != null) ...[
            const SizedBox(height: 16),
            _buildResultHeader(
              'Critical Load Factor α_cr = ${_bucklingResult!['critical_load_factor_alpha_cr']} • Sway Amplifier B2 = ${_bucklingResult!['sway_amplification_b2']}',
              'Status: ${_bucklingResult!['buckling_modes']?[0]?['aisc_stability_status'] ?? "STABLE"}',
            ),
            const SizedBox(height: 8),
            _buildBucklingModesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildParameterCard({required String title, required String value, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _buildResultHeader(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F6FEB).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1F6FEB).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildWindPressureTable() {
    final pressures = (_windResult!['velocity_pressures'] as List?) ?? [];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Level', style: TextStyle(color: Colors.white70, fontSize: 11))),
          DataColumn(label: Text('Elev (m)', style: TextStyle(color: Colors.white70, fontSize: 11))),
          DataColumn(label: Text('Kz', style: TextStyle(color: Colors.white70, fontSize: 11))),
          DataColumn(label: Text('qz (N/m²)', style: TextStyle(color: Colors.white70, fontSize: 11))),
          DataColumn(label: Text('Windward', style: TextStyle(color: Colors.white70, fontSize: 11))),
          DataColumn(label: Text('Leeward', style: TextStyle(color: Colors.white70, fontSize: 11))),
          DataColumn(label: Text('Storey F (N)', style: TextStyle(color: Colors.white70, fontSize: 11))),
        ],
        rows: pressures.map<DataRow>((p) {
          return DataRow(cells: [
            DataCell(Text('Storey ${p['storey_index']}', style: const TextStyle(color: Colors.white, fontSize: 11))),
            DataCell(Text('${p['elevation_m']} m', style: const TextStyle(color: Colors.white, fontSize: 11))),
            DataCell(Text('${p['kz']}', style: const TextStyle(color: Colors.white70, fontSize: 11))),
            DataCell(Text('${p['qz_n_m2']}', style: const TextStyle(color: Colors.white70, fontSize: 11))),
            DataCell(Text('${p['windward_pressure_n_m2']}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11))),
            DataCell(Text('${p['leeward_pressure_n_m2']}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11))),
            DataCell(Text('${p['total_storey_force_n']}', style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildSeismicStoreyTable() {
    final forces = (_seismicResult!['storey_forces'] as List?) ?? [];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Level', style: TextStyle(color: Colors.white70, fontSize: 11))),
          DataColumn(label: Text('Elevation', style: TextStyle(color: Colors.white70, fontSize: 11))),
          DataColumn(label: Text('Floor W (kN)', style: TextStyle(color: Colors.white70, fontSize: 11))),
          DataColumn(label: Text('Cvx', style: TextStyle(color: Colors.white70, fontSize: 11))),
          DataColumn(label: Text('Storey Fx (kN)', style: TextStyle(color: Colors.white70, fontSize: 11))),
          DataColumn(label: Text('Cum. Shear (kN)', style: TextStyle(color: Colors.white70, fontSize: 11))),
        ],
        rows: forces.map<DataRow>((f) {
          return DataRow(cells: [
            DataCell(Text('Storey ${f['storey_index']}', style: const TextStyle(color: Colors.white, fontSize: 11))),
            DataCell(Text('${f['elevation_m']} m', style: const TextStyle(color: Colors.white, fontSize: 11))),
            DataCell(Text('${f['storey_weight_kn']}', style: const TextStyle(color: Colors.white70, fontSize: 11))),
            DataCell(Text('${f['cvx']}', style: const TextStyle(color: Colors.white70, fontSize: 11))),
            DataCell(Text('${f['lateral_force_kn']}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold))),
            DataCell(Text('${f['storey_shear_kn']}', style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildBucklingModesList() {
    final modes = (_bucklingResult!['buckling_modes'] as List?) ?? [];
    return Column(
      children: modes.map<Widget>((m) {
        final alpha = (m['critical_load_factor_alpha_cr'] as num?)?.toDouble() ?? 1.0;
        final isStable = alpha >= 1.5;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isStable ? Colors.white10 : const Color(0xFFFF0055).withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mode ${m['mode_index']}: Critical Factor α_cr = ${alpha.toStringAsFixed(3)}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    'B2 = ${m['sway_amplification_b2']}',
                    style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isStable ? const Color(0xFF10B981) : const Color(0xFFFF0055)).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      m['aisc_stability_status'],
                      style: TextStyle(
                        color: isStable ? const Color(0xFF10B981) : const Color(0xFFFF0055),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
