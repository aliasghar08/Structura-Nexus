// ============================================================================
// CollaborationReviewDialog — Real-Time Multi-Engineer Cloud Collaboration
// visionOS Frosted Midnight GlassPod with 1-Click Share Link, Revision Diffing,
// and Pinned 3D Joint Engineering Review Comments.
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/structural_models.dart';
import '../services/collaboration_service.dart';
import 'glass_pod.dart';

class CollaborationReviewDialog extends StatefulWidget {
  final StructuralModel model;
  final VoidCallback onStructureModified;

  const CollaborationReviewDialog({
    super.key,
    required this.model,
    required this.onStructureModified,
  });

  static Future<void> show(
    BuildContext context, {
    required StructuralModel model,
    required VoidCallback onStructureModified,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => CollaborationReviewDialog(
        model: model,
        onStructureModified: onStructureModified,
      ),
    );
  }

  @override
  State<CollaborationReviewDialog> createState() => _CollaborationReviewDialogState();
}

class _CollaborationReviewDialogState extends State<CollaborationReviewDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CollaborationService _collabService = CollaborationService();
  final TextEditingController _commentInputController = TextEditingController();
  String? _selectedAnchorNodeId;
  String _shareRole = 'VIEWER_COMMENTER';
  bool _copiedFeedback = false;
  late DiffSummary _diffSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _collabService.initSession(widget.model);

    // Compute initial structural revision diff
    final baseline = _collabService.baselineModel ?? widget.model;
    _diffSummary = StructuralDiffEngine.compare(
      baseline: baseline,
      current: widget.model,
    );

    if (widget.model.nodes.isNotEmpty) {
      _selectedAnchorNodeId = widget.model.nodes.first.id;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentInputController.dispose();
    super.dispose();
  }

  void _copyShareLink() {
    final link = _collabService.generateShareLink(role: _shareRole);
    Clipboard.setData(ClipboardData(text: link));
    setState(() => _copiedFeedback = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copiedFeedback = false);
    });
  }

  void _submitNewComment() {
    final text = _commentInputController.text.trim();
    if (text.isEmpty) return;

    List<double>? anchorCoords;
    if (_selectedAnchorNodeId != null) {
      final node = widget.model.nodes.firstWhere(
        (n) => n.id == _selectedAnchorNodeId,
        orElse: () => widget.model.nodes.first,
      );
      anchorCoords = [node.x, node.y, node.z];
    }

    _collabService.addComment(
      text: text,
      nodeId: _selectedAnchorNodeId,
      coords: anchorCoords,
    );

    _commentInputController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassPod(
        width: 880,
        height: 650,
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.hub_rounded, color: Color(0xFF00F0FF), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "REAL-TIME MULTI-ENGINEER COLLABORATION",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              "Session: ${_collabService.activeSessionId} • 12-DOF Model Revision Diff & 3D Joint Pins",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Bar
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF00F0FF),
              indicatorWeight: 3,
              labelColor: const Color(0xFF00F0FF),
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              tabs: [
                const Tab(icon: Icon(Icons.share_rounded, size: 16), text: "SHARE & PRESENCE"),
                Tab(
                  icon: const Icon(Icons.difference_rounded, size: 16),
                  text: "REVISION DIFF (${_diffSummary.addedCount + _diffSummary.modifiedCount + _diffSummary.removedCount})",
                ),
                Tab(
                  icon: const Icon(Icons.push_pin_rounded, size: 16),
                  text: "PINNED 3D COMMENTS (${_collabService.comments.length})",
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildShareTab(),
                  _buildDiffTab(),
                  _buildCommentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Share & Active Presence Tab
  Widget _buildShareTab() {
    final link = _collabService.generateShareLink(role: _shareRole);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1-Click Share Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0B101B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.link_rounded, color: Color(0xFF00F0FF), size: 18),
                    SizedBox(width: 8),
                    Text(
                      "SHAREABLE REVIEW LINK",
                      style: TextStyle(color: Color(0xFF00F0FF), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Distribute to peer structural engineers, municipal plan-checkers, or fabricators. Anyone with this link can inspect 12-DOF results, leave joint review comments, or co-model in real time.",
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 14),

                // Role Selector Pills
                Row(
                  children: [
                    const Text("Role Permission: ", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(width: 8),
                    _buildRolePill("VIEWER_COMMENTER", "Reviewer & Commenter"),
                    const SizedBox(width: 8),
                    _buildRolePill("CO_ENGINEER", "Full Co-Engineer (Edit)"),
                  ],
                ),
                const SizedBox(height: 14),

                // Link bar with Copy button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161E2E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          link,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _copyShareLink,
                        icon: Icon(_copiedFeedback ? Icons.check_circle_rounded : Icons.copy_rounded, size: 14),
                        label: Text(_copiedFeedback ? "COPIED!" : "COPY LINK"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _copiedFeedback ? const Color(0xFF10B981) : const Color(0xFF00F0FF),
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Collaborators Presence List
          const Text(
            "ACTIVE PRESENCE & COLLABORATORS",
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          ..._collabService.collaborators.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF161E2E).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                      child: Text(
                        c.displayName.isNotEmpty ? c.displayName[0] : 'U',
                        style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.displayName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text("Role: ${c.role} • Active now", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.fiber_manual_record, color: Color(0xFF10B981), size: 8),
                          SizedBox(width: 4),
                          Text("ONLINE", style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRolePill(String roleValue, String label) {
    final isSelected = _shareRole == roleValue;
    return InkWell(
      onTap: () => setState(() => _shareRole = roleValue),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF00F0FF) : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white70,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 2. Revision Diffing Tab
  Widget _buildDiffTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            _buildDiffStatCard("ADDED MEMBERS", "${_diffSummary.addedCount}", const Color(0xFF00F0FF)),
            const SizedBox(width: 12),
            _buildDiffStatCard("MODIFIED SECTIONS", "${_diffSummary.modifiedCount}", const Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            _buildDiffStatCard("REMOVED ELEMENTS", "${_diffSummary.removedCount}", const Color(0xFFEF4444)),
          ],
        ),
        const SizedBox(height: 16),

        // Diff Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B101B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: _diffSummary.diffs.isEmpty
                ? const Center(
                    child: Text(
                      "No structural modifications detected against baseline revision.\nDirect Stiffness Matrix equilibrium is identical.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                    ),
                  )
                : ListView.separated(
                    itemCount: _diffSummary.diffs.length,
                    separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (ctx, i) {
                      final diff = _diffSummary.diffs[i];
                      Color badgeColor = const Color(0xFF00F0FF);
                      String badgeText = 'ADDED';
                      if (diff.changeType == DiffChangeType.modified) {
                        badgeColor = const Color(0xFFF59E0B);
                        badgeText = 'MODIFIED';
                      } else if (diff.changeType == DiffChangeType.removed) {
                        badgeColor = const Color(0xFFEF4444);
                        badgeText = 'REMOVED';
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              diff.memberId,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                diff.details,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ),
                            if (diff.newDcr != null)
                              Text(
                                "DCR: ${diff.newDcr!.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: diff.newDcr! <= 1.0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiffStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(count, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // 3. Pinned 3D Review Comments Tab
  Widget _buildCommentsTab() {
    return Column(
      children: [
        // Comments Stream List
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B101B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: _collabService.comments.isEmpty
                ? const Center(
                    child: Text(
                      "No pinned review comments yet.\nPin comments directly to joints or members below.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    itemCount: _collabService.comments.length,
                    separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (ctx, i) {
                      final c = _collabService.comments[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              c.isResolved ? Icons.check_circle_rounded : Icons.push_pin_rounded,
                              color: c.isResolved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(c.authorName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      if (c.nodeId != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text("Node ${c.nodeId}", style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 9.5, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.text,
                                    style: TextStyle(
                                      color: c.isResolved ? Colors.white54 : Colors.white,
                                      fontSize: 11.5,
                                      decoration: c.isResolved ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                c.isResolved ? Icons.replay_rounded : Icons.done_rounded,
                                color: c.isResolved ? Colors.white54 : const Color(0xFF10B981),
                                size: 18,
                              ),
                              tooltip: c.isResolved ? "Reopen comment" : "Mark as resolved",
                              onPressed: () {
                                setState(() {
                                  _collabService.toggleResolveComment(c.id);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // New Comment Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF161E2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // Anchor Node Dropdown
              if (widget.model.nodes.isNotEmpty)
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAnchorNodeId,
                    dropdownColor: const Color(0xFF0B101B),
                    style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold),
                    items: widget.model.nodes.take(20).map((n) {
                      return DropdownMenuItem(value: n.id, child: Text("Pin @ ${n.id}"));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedAnchorNodeId = val),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _commentInputController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: "Enter 3D engineering review comment...",
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _submitNewComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Color(0xFF00F0FF)),
                onPressed: _submitNewComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
