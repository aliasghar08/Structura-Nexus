// ============================================================================
// Structura Nexus: Keyboard Shortcuts Cheat-Sheet Modal
// Plain-English reference guide for quick engineering navigation and commands
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';

void showKeyboardShortcutsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      final isCompact = size.width < 700;

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: isCompact ? size.width * 0.95 : 620,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.35), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161B22),
                    border: Border(bottom: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.keyboard_rounded, color: Color(0xFF00F0FF), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "KEYBOARD SHORTCUTS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Fast viewport controls, batch selection, undo/redo & command navigation",
                              style: TextStyle(color: Colors.white60, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                // Shortcut Groups
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCategoryHeader("3D CAMERA & VIEWPORT PRESETS"),
                        const SizedBox(height: 8),
                        _buildShortcutRow(["1"], "Isometric View", "Re-orient camera to standard 3D isometric perspective"),
                        _buildShortcutRow(["2"], "Top Plan View (X-Z)", "Align camera directly overhead for floor grid inspection"),
                        _buildShortcutRow(["3"], "Front Elevation (X-Y)", "Align camera frontally for vertical story drift checks"),
                        _buildShortcutRow(["4"], "Recenter & Auto-Fit", "Center camera target and frame the complete 3D structure"),

                        const SizedBox(height: 16),
                        _buildCategoryHeader("MODELING & SELECTION"),
                        const SizedBox(height: 8),
                        _buildShortcutRow(["Shift", "Click"], "Multi-Select (Batch Edit)", "Select multiple joints or members for batch section or release assignment"),
                        _buildShortcutRow(["Delete"], "Delete Entity", "Remove selected joint(s) or member(s) from the finite element model"),
                        _buildShortcutRow(["Esc"], "Deselect / Close", "Clear active selection or dismiss floating dialogs"),

                        const SizedBox(height: 16),
                        _buildCategoryHeader("WORKSPACE & COMMANDS"),
                        const SizedBox(height: 8),
                        _buildShortcutRow(["⌘/Ctrl", "K"], "Command Palette", "Universal fuzzy search across all 30+ engineering tools & templates"),
                        _buildShortcutRow(["⌘/Ctrl", "Z"], "Undo", "Revert the most recent structural modeling mutation"),
                        _buildShortcutRow(["⌘/Ctrl", "Shift", "Z"], "Redo", "Re-apply the previously undone structural modeling step"),
                        _buildShortcutRow(["?"], "Shortcuts Cheat-Sheet", "Toggle this keyboard shortcuts reference guide"),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161B22),
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Hotkeys automatically pause when typing in coordinates or text inputs.",
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F0FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size.zero,
                        ),
                        child: const Text("Got It", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildCategoryHeader(String title) {
  return Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00F0FF),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: Container(height: 0.5, color: const Color(0xFF00F0FF).withValues(alpha: 0.3))),
    ],
  );
}

Widget _buildShortcutRow(List<String> keys, String action, String description) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: keys.map((k) {
            return Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.white24, width: 0.8),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: Text(
                k,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action,
                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
