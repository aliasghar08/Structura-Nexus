// ============================================================================
// Structura Nexus: Building Templates & Workspace Importer Dialog
// Browse, synthesize and import certified building space frames into workspace
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/structural_models.dart';
import '../services/building_generator_service.dart';

class BuildingTemplatesDialog extends StatefulWidget {
  final StructuralModel currentModel;
  final Function(StructuralModel newModel) onModelSelected;

  const BuildingTemplatesDialog({
    super.key,
    required this.currentModel,
    required this.onModelSelected,
  });

  @override
  State<BuildingTemplatesDialog> createState() => _BuildingTemplatesDialogState();
}

class _BuildingTemplatesDialogState extends State<BuildingTemplatesDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _importTextController = TextEditingController();

  // Parametric Generator State
  int _paramStories = 6;
  int _paramBaysX = 3;
  int _paramBaysZ = 2;
  double _paramBayWidthX = 6.0;
  double _paramBayDepthZ = 6.0;
  double _paramStoryHeight = 3.6;
  BuildingSystemType _paramSystem = BuildingSystemType.xBracedFrame;
  final String _paramColumnSection = 'W14X90';
  final String _paramBeamSection = 'W18X35';
  final String _paramBraceSection = 'W10X33';

  String? _importError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _importTextController.dispose();
    super.dispose();
  }

  void _importModelIntoWorkspace(StructuralModel model) {
    widget.onModelSelected(model);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 1080,
        height: 720,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.35), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCatalogTab(),
                    _buildParametricGeneratorTab(),
                    _buildFileImporterTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.apartment_rounded, color: Color(0xFF00F0FF), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'BUILDING TEMPLATES & WORKSPACE IMPORTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Certified commercial towers, industrial warehouses & infrastructure models ready to import into your workspace',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF0B0F17),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF00F0FF),
        indicatorWeight: 3,
        labelColor: const Color(0xFF00F0FF),
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.library_books_rounded, size: 16), text: 'Certified Building Templates'),
          Tab(icon: Icon(Icons.tune_rounded, size: 16), text: 'Parametric Building Synthesizer'),
          Tab(icon: Icon(Icons.file_upload_rounded, size: 16), text: 'Import File (.s2k, .json, .csv)'),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 1: CERTIFIED BUILDING TEMPLATES CATALOG
  // ==========================================================================
  Widget _buildCatalogTab() {
    final allTemplates = BuildingGeneratorService.getCertifiedBuildingTemplates();
    final categories = ['All', 'High-Rise & Towers', 'Commercial & Residential', 'Industrial & Long-Span', 'Infrastructure & Bridges', 'Verification Benchmarks'];

    final query = _searchController.text.trim().toLowerCase();
    final filtered = allTemplates.where((t) {
      final matchesCat = _selectedCategory == 'All' || t.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query) ||
          t.structuralSystem.toLowerCase().contains(query);
      return matchesCat && matchesQuery;
    }).toList();

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF101622),
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 16, color: Colors.white38),
                    hintText: 'Search templates by name, framing system, or code...',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF161F2E),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSel,
                        label: Text(cat, style: TextStyle(color: isSel ? const Color(0xFF00F0FF) : Colors.white70, fontSize: 11)),
                        backgroundColor: const Color(0xFF161F2E),
                        selectedColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF00F0FF),
                        side: BorderSide(color: isSel ? const Color(0xFF00F0FF) : Colors.white12),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Grid of templates
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 185,
              ),
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final t = filtered[idx];
                return _buildTemplateCard(t);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(BuildingTemplateMeta t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161F2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.6)),
                ),
                child: Text(
                  t.badge,
                  style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${t.nodeCount} Joints • ${t.memberCount} Members',
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              t.description,
              style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t.heightM.toStringAsFixed(1)}m H • ${t.footprintAreaM2.toStringAsFixed(0)} m²',
                      style: const TextStyle(color: Color(0xFF7EE787), fontSize: 11, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      t.standard,
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final model = t.builder();
                  _importModelIntoWorkspace(model);
                },
                icon: const Icon(Icons.input_rounded, size: 14, color: Color(0xFF0A0F1D)),
                label: const Text(
                  'Import',
                  style: TextStyle(color: Color(0xFF0A0F1D), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: PARAMETRIC BUILDING SYNTHESIZER
  // ==========================================================================
  Widget _buildParametricGeneratorTab() {
    final totalHeight = _paramStories * _paramStoryHeight;
    final totalArea = (_paramBaysX * _paramBayWidthX) * (_paramBaysZ * _paramBayDepthZ);
    final estNodes = (_paramStories + 1) * (_paramBaysX + 1) * (_paramBaysZ + 1);
    final estMembers = (_paramStories * (_paramBaysX + 1) * (_paramBaysZ + 1)) +
        (_paramStories * _paramBaysX * (_paramBaysZ + 1)) +
        (_paramStories * (_paramBaysX + 1) * _paramBaysZ) +
        (_paramSystem == BuildingSystemType.xBracedFrame ? _paramStories * 8 : 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF161F2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                _buildStatPill('STORIES', '$_paramStories', Icons.layers_rounded, const Color(0xFF00F0FF)),
                const SizedBox(width: 14),
                _buildStatPill('HEIGHT', '${totalHeight.toStringAsFixed(1)} m', Icons.height_rounded, const Color(0xFF7EE787)),
                const SizedBox(width: 14),
                _buildStatPill('FOOTPRINT', '${totalArea.toStringAsFixed(0)} m²', Icons.crop_square_rounded, const Color(0xFFFFA657)),
                const SizedBox(width: 14),
                _buildStatPill('EST. JOINTS', '$estNodes', Icons.hub_rounded, const Color(0xFFD2A8FF)),
                const SizedBox(width: 14),
                _buildStatPill('EST. MEMBERS', '$estMembers', Icons.architecture_rounded, const Color(0xFFFF7B72)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sliders
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF101622),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PARAMETRIC GEOMETRY CONTROLS',
                  style: TextStyle(color: Color(0xFF00F0FF), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
                const SizedBox(height: 14),

                _buildSliderRow(
                  label: 'Number of Stories',
                  valueStr: '$_paramStories Stories',
                  val: _paramStories.toDouble(),
                  min: 1,
                  max: 25,
                  divisions: 24,
                  onChanged: (v) => setState(() => _paramStories = v.round()),
                ),
                _buildSliderRow(
                  label: 'Bays along X-Axis',
                  valueStr: '$_paramBaysX Bays (${(_paramBaysX * _paramBayWidthX).toStringAsFixed(1)}m)',
                  val: _paramBaysX.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  onChanged: (v) => setState(() => _paramBaysX = v.round()),
                ),
                _buildSliderRow(
                  label: 'Bays along Z-Axis',
                  valueStr: '$_paramBaysZ Bays (${(_paramBaysZ * _paramBayDepthZ).toStringAsFixed(1)}m)',
                  val: _paramBaysZ.toDouble(),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  onChanged: (v) => setState(() => _paramBaysZ = v.round()),
                ),
                _buildSliderRow(
                  label: 'Bay Width X',
                  valueStr: '${_paramBayWidthX.toStringAsFixed(1)} m',
                  val: _paramBayWidthX,
                  min: 4.0,
                  max: 12.0,
                  divisions: 16,
                  onChanged: (v) => setState(() => _paramBayWidthX = v),
                ),
                _buildSliderRow(
                  label: 'Bay Depth Z',
                  valueStr: '${_paramBayDepthZ.toStringAsFixed(1)} m',
                  val: _paramBayDepthZ,
                  min: 4.0,
                  max: 12.0,
                  divisions: 16,
                  onChanged: (v) => setState(() => _paramBayDepthZ = v),
                ),
                _buildSliderRow(
                  label: 'Story Height',
                  valueStr: '${_paramStoryHeight.toStringAsFixed(2)} m',
                  val: _paramStoryHeight,
                  min: 2.8,
                  max: 5.0,
                  divisions: 22,
                  onChanged: (v) => setState(() => _paramStoryHeight = v),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Lateral Framing System:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 14),
                    DropdownButton<BuildingSystemType>(
                      value: _paramSystem,
                      dropdownColor: const Color(0xFF161F2E),
                      style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 12, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: BuildingSystemType.xBracedFrame, child: Text('Perimeter X-Braced Frame')),
                        DropdownMenuItem(value: BuildingSystemType.chevronBraced, child: Text('Inverted-V Chevron Bracing')),
                        DropdownMenuItem(value: BuildingSystemType.momentFrame, child: Text('Special Moment Frame (SMF)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paramSystem = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              final newModel = BuildingGeneratorService.generateParametricBuilding(
                name: 'Parametric Building (${_paramStories}S_${_paramBaysX}x$_paramBaysZ)',
                numStories: _paramStories,
                baysX: _paramBaysX,
                baysZ: _paramBaysZ,
                bayWidthX: _paramBayWidthX,
                bayDepthZ: _paramBayDepthZ,
                storyHeight: _paramStoryHeight,
                system: _paramSystem,
                columnSection: _paramColumnSection,
                beamSection: _paramBeamSection,
                braceSection: _paramBraceSection,
              );
              _importModelIntoWorkspace(newModel);
            },
            icon: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF0A0F1D)),
            label: const Text(
              'Synthesize & Import Into Workspace',
              style: TextStyle(color: Color(0xFF0A0F1D), fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueStr,
    required double val,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF00F0FF),
                inactiveTrackColor: Colors.white12,
                thumbColor: const Color(0xFF00F0FF),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: val,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              valueStr,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Color(0xFF7EE787), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: FILE IMPORTER (.S2K, .JSON, .CSV)
  // ==========================================================================
  Widget _buildFileImporterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161F2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code_rounded, size: 18, color: Color(0xFF00F0FF)),
                    const SizedBox(width: 8),
                    const Text(
                      'PASTE CUSTOM BUILDING DATA (JSON, S2K OR CSV)',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        final sample = {
                          "name": "Custom 3-Story Commercial Frame",
                          "nodes": [
                            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1]},
                            {"id": "N2", "coords": [6.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1]},
                            {"id": "N3", "coords": [0.0, 3.6, 0.0], "loads": [14000, -35000, 0]},
                            {"id": "N4", "coords": [6.0, 3.6, 0.0], "loads": [0, -35000, 0]},
                            {"id": "N5", "coords": [0.0, 7.2, 0.0], "loads": [22000, -25000, 0]},
                            {"id": "N6", "coords": [6.0, 7.2, 0.0], "loads": [0, -25000, 0]}
                          ],
                          "members": [
                            {"id": "C1", "i_node": "N1", "j_node": "N3", "section": "W14X68"},
                            {"id": "C2", "i_node": "N2", "j_node": "N4", "section": "W14X68"},
                            {"id": "B1", "i_node": "N3", "j_node": "N4", "section": "W18X35"},
                            {"id": "C3", "i_node": "N3", "j_node": "N5", "section": "W14X48"},
                            {"id": "C4", "i_node": "N4", "j_node": "N6", "section": "W14X48"},
                            {"id": "B2", "i_node": "N5", "j_node": "N6", "section": "W18X35"}
                          ]
                        };
                        _importTextController.text = const JsonEncoder.withIndent('  ').convert(sample);
                        setState(() => _importError = null);
                      },
                      icon: const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFF00F0FF)),
                      label: const Text('Insert JSON Sample', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Paste your custom structural geometry and load definition below. Supports SAP2000 (.s2k), Structura JSON (.json), and tabular CSV coordinates:',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _importTextController,
                  maxLines: 10,
                  style: const TextStyle(color: Color(0xFF7EE787), fontFamily: 'monospace', fontSize: 11),
                  decoration: InputDecoration(
                    hintText: '{\n  "name": "Custom Space Frame",\n  "nodes": [...],\n  "members": [...]\n}',
                    hintStyle: const TextStyle(color: Colors.white24, fontFamily: 'monospace'),
                    filled: true,
                    fillColor: const Color(0xFF090D14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (_importError != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDA3633).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDA3633)),
                    ),
                    child: Text(
                      _importError!,
                      style: const TextStyle(color: Color(0xFFFFA198), fontSize: 11),
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed: () {
                    final text = _importTextController.text.trim();
                    if (text.isEmpty) {
                      setState(() => _importError = 'Please paste model text or S2K syntax first.');
                      return;
                    }
                    final imported = BuildingGeneratorService.importModel(text);
                    if (imported != null && imported.nodes.isNotEmpty) {
                      _importModelIntoWorkspace(imported);
                    } else {
                      setState(() => _importError = 'Failed to parse model. Ensure valid JSON graph or S2K coordinate syntax.');
                    }
                  },
                  icon: const Icon(Icons.file_download_done_rounded, color: Color(0xFF0A0F1D)),
                  label: const Text(
                    'Parse & Import into Workspace',
                    style: TextStyle(color: Color(0xFF0A0F1D), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
