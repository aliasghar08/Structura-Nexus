import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/structural_models.dart';
import '../services/structural_library_service.dart';
import '../services/firebase_auth_service.dart';

class StructuralLibraryDialog extends StatefulWidget {
  final StructuralModel currentModel;
  final Function(StructuralModel newModel) onModelSelected;

  const StructuralLibraryDialog({
    super.key,
    required this.currentModel,
    required this.onModelSelected,
  });

  @override
  State<StructuralLibraryDialog> createState() => _StructuralLibraryDialogState();
}

class _StructuralLibraryDialogState extends State<StructuralLibraryDialog> with SingleTickerProviderStateMixin {
  final StructuralLibraryService _libService = StructuralLibraryService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  late TabController _tabController;
  final TextEditingController _importJsonController = TextEditingController();
  final TextEditingController _saveTitleController = TextEditingController();
  final TextEditingController _saveDescController = TextEditingController();

  List<CloudProjectMeta> _cloudProjects = [];
  bool _isLoadingCloud = false;
  String? _cloudError;
  String? _importError;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _saveTitleController.text = widget.currentModel.name;
    _fetchCloudProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importJsonController.dispose();
    _saveTitleController.dispose();
    _saveDescController.dispose();
    super.dispose();
  }

  Future<void> _fetchCloudProjects() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingCloud = true;
      _cloudError = null;
    });

    try {
      final projects = await _libService.getUserProjects();
      if (mounted) {
        setState(() {
          _cloudProjects = projects;
          _isLoadingCloud = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cloudError = 'Could not retrieve cloud models: $e';
          _isLoadingCloud = false;
        });
      }
    }
  }

  Future<void> _saveCurrentToCloud() async {
    final title = _saveTitleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isLoadingCloud = true);
    try {
      await _libService.saveProjectToCloud(
        model: widget.currentModel,
        title: title,
        description: _saveDescController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _feedbackMessage = 'Model "$title" securely saved to Firebase Cloud!';
          _isLoadingCloud = false;
        });
        _fetchCloudProjects();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cloudError = 'Failed to save to cloud: $e';
          _isLoadingCloud = false;
        });
      }
    }
  }

  void _importCustomJson() {
    final text = _importJsonController.text.trim();
    if (text.isEmpty) {
      setState(() => _importError = 'Please paste a valid JSON structural graph.');
      return;
    }

    try {
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      final model = StructuralLibraryService.deserializeModel(parsed);
      if (model.nodes.isEmpty || model.members.isEmpty) {
        setState(() => _importError = 'Model must contain at least 1 node and 1 member.');
        return;
      }
      widget.onModelSelected(model);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _importError = 'JSON parsing failed: $e');
    }
  }

  void _exportDxf() {
    final dxf = StructuralLibraryService.exportToDxf(widget.currentModel);
    Clipboard.setData(ClipboardData(text: dxf));
    setState(() => _feedbackMessage = 'AutoCAD DXF format copied to clipboard! (Ready to paste or save as .dxf)');
  }

  void _exportJson() {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(
      StructuralLibraryService.serializeModel(widget.currentModel),
    );
    Clipboard.setData(ClipboardData(text: jsonStr));
    setState(() => _feedbackMessage = 'Complete structural model JSON copied to clipboard!');
  }

  void _exportCsvBom() {
    final bom = StructuralLibraryService.exportToCsvBom(widget.currentModel);
    Clipboard.setData(ClipboardData(text: bom));
    setState(() => _feedbackMessage = 'Steel Bill of Materials (BOM) CSV copied to clipboard!');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 920,
        height: 680,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF30363D), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1F6FEB).withValues(alpha: 0.12),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F6FEB).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_special_rounded, color: Color(0xFF58A6FF), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STRUCTURAL PROJECT LIBRARY & CLOUD VAULT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Certified engineering templates • Firebase cloud sync • Custom file import/export',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF21262D))),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF1F6FEB),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.library_books_rounded, size: 16), text: 'Certified Templates'),
                  Tab(icon: Icon(Icons.cloud_queue_rounded, size: 16), text: 'My Cloud Models'),
                  Tab(icon: Icon(Icons.file_present_rounded, size: 16), text: 'Import / Export Files'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_feedbackMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF238636).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2EA043)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF3FB950), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _feedbackMessage!,
                        style: const TextStyle(color: Color(0xFF7EE787), fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
                      onPressed: () => setState(() => _feedbackMessage = null),
                    ),
                  ],
                ),
              ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTemplatesTab(),
                  _buildCloudProjectsTab(),
                  _buildImportExportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab 1: Templates ---
  Widget _buildTemplatesTab() {
    final templates = _libService.getCuratedTemplates();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 2.1,
      ),
      itemCount: templates.length,
      itemBuilder: (ctx, idx) {
        final t = templates[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
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
                      color: const Color(0xFF1F6FEB).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF1F6FEB)),
                    ),
                    child: Text(
                      t['badge'],
                      style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${t['nodeCount']} Joints • ${t['memberCount']} Members',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t['title'],
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  t['description'],
                  style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Text(
                    t['standard'],
                    style: const TextStyle(color: Color(0xFF7EE787), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      final model = (t['factory'] as Function())();
                      widget.onModelSelected(model);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                    label: const Text('Load Model', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F6FEB),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Tab 2: Cloud Projects ---
  Widget _buildCloudProjectsTab() {
    final user = _authService.currentUser;
    if (user == null || user.isAnonymous) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.white38),
            const SizedBox(height: 16),
            const Text(
              'Sign in with an Engineering Account to Enable Cloud Sync',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save structural projects across devices, share models with team members, and access revision histories.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // User will trigger AuthDialog from header
              },
              icon: const Icon(Icons.login_rounded, size: 16, color: Colors.white),
              label: const Text('Open Sign In Modal', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F6FEB),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Save current model bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _saveTitleController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Project Name',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _saveDescController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Project Notes (Optional)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoadingCloud ? null : _saveCurrentToCloud,
                icon: const Icon(Icons.cloud_upload_rounded, size: 16, color: Colors.white),
                label: const Text('Save Active Model', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF238636),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_cloudError != null)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDA3633).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDA3633)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFF85149), size: 16),
                const SizedBox(width: 8),
                Text(_cloudError!, style: const TextStyle(color: Color(0xFFFF7B72), fontSize: 12)),
              ],
            ),
          ),

        // List of projects
        Expanded(
          child: _isLoadingCloud
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F6FEB)))
              : _cloudProjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.inbox_rounded, size: 40, color: Colors.white24),
                          SizedBox(height: 12),
                          Text('No saved cloud models yet. Use the bar above to save this model!',
                              style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _cloudProjects.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final p = _cloudProjects[idx];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F6FEB).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.architecture_rounded, color: Color(0xFF58A6FF), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${p.nodeCount} Joints • ${p.memberCount} Members • ${(p.totalWeightKg / 1000.0).toStringAsFixed(1)} tonnes steel • DCR ${p.governingDcr.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFF85149), size: 18),
                                onPressed: () async {
                                  await _libService.deleteProject(p.id);
                                  _fetchCloudProjects();
                                },
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final model = StructuralLibraryService.deserializeModel(p.graphData);
                                  widget.onModelSelected(model);
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.download_rounded, size: 14, color: Colors.white),
                                label: const Text('Load', style: TextStyle(color: Colors.white, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F6FEB),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // --- Tab 3: Custom File Import & Export ---
  Widget _buildImportExportTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Export actions bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.ios_share_rounded, size: 18, color: Color(0xFF58A6FF)),
                    SizedBox(width: 8),
                    Text(
                      'EXPORT CURRENT WORKSTATION MODEL',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Export geometry and loading data into industry-standard formats compatible with AutoCAD, Revit, and Excel.',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _exportDxf,
                      icon: const Icon(Icons.design_services_rounded, size: 16, color: Color(0xFF58A6FF)),
                      label: const Text('Export AutoCAD DXF (.dxf)', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1F6FEB)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _exportCsvBom,
                      icon: const Icon(Icons.table_chart_rounded, size: 16, color: Color(0xFF3FB950)),
                      label: const Text('Export Steel BOM (.csv)', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2EA043)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _exportJson,
                      icon: const Icon(Icons.code_rounded, size: 16, color: Colors.orangeAccent),
                      label: const Text('Export Graph JSON (.json)', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orangeAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Import area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.file_upload_rounded, size: 18, color: Color(0xFF7EE787)),
                    const SizedBox(width: 8),
                    const Text(
                      'IMPORT USER MODEL FILE (JSON GRAPH)',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        final sample = {
                          "name": "Custom 2-Bay Frame",
                          "nodes": [
                            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0]},
                            {"id": "N2", "coords": [6.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0]},
                            {"id": "N3", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [15000, -35000, 0]},
                            {"id": "N4", "coords": [6.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, -35000, 0]}
                          ],
                          "members": [
                            {"id": "C1", "i_node": "N1", "j_node": "N3", "section": "W14X68"},
                            {"id": "C2", "i_node": "N2", "j_node": "N4", "section": "W14X68"},
                            {"id": "B1", "i_node": "N3", "j_node": "N4", "section": "W18X35"}
                          ]
                        };
                        _importJsonController.text = const JsonEncoder.withIndent('  ').convert(sample);
                      },
                      icon: const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFF58A6FF)),
                      label: const Text('Insert Sample', style: TextStyle(color: Color(0xFF58A6FF), fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paste your custom structural geometry and load definition below to render and solve in real time:',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _importJsonController,
                  maxLines: 8,
                  style: const TextStyle(color: Color(0xFF7EE787), fontFamily: 'monospace', fontSize: 11),
                  decoration: InputDecoration(
                    hintText: '{\n  "name": "My Custom Structure",\n  "nodes": [...],\n  "members": [...]\n}',
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
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDA3633).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDA3633)),
                    ),
                    child: Text(_importError!, style: const TextStyle(color: Color(0xFFFF7B72), fontSize: 11)),
                  ),

                ElevatedButton.icon(
                  onPressed: _importCustomJson,
                  icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                  label: const Text('Validate & Load into Workstation', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F6FEB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 44),
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
