// ============================================================================
// CommandPaletteDialog — Spotlight-Style Universal Engineering Command Palette
// Instant Search (⌘K / Ctrl+K), Guided Encyclopedia & 1-Click Tool Launcher
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_pod.dart';
import 'info_tooltip.dart';

class CommandPaletteAction {
  final String title;
  final String subtitle;
  final String category;
  final String codeRef;
  final String infoDescription;
  final IconData icon;
  final Color color;
  final String? shortcut;
  final VoidCallback onTrigger;

  const CommandPaletteAction({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.codeRef,
    required this.infoDescription,
    required this.icon,
    required this.color,
    this.shortcut,
    required this.onTrigger,
  });
}

class CommandPaletteDialog extends StatefulWidget {
  final List<CommandPaletteAction> actions;

  const CommandPaletteDialog({
    super.key,
    required this.actions,
  });

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  String _selectedCategory = 'ALL';
  int _highlightedIndex = 0;

  static const List<String> _categories = [
    'ALL',
    'AI & GEN',
    'ANALYSIS',
    'CAD & BIM',
    'MODELING',
    'TEMPLATES',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
        _highlightedIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<CommandPaletteAction> get _filteredActions {
    return widget.actions.where((a) {
      if (_selectedCategory != 'ALL' && a.category != _selectedCategory) {
        return false;
      }
      if (_query.isEmpty) return true;
      return a.title.toLowerCase().contains(_query) ||
          a.subtitle.toLowerCase().contains(_query) ||
          a.codeRef.toLowerCase().contains(_query) ||
          a.category.toLowerCase().contains(_query) ||
          a.infoDescription.toLowerCase().contains(_query);
    }).toList();
  }

  void _executeAction(CommandPaletteAction action) {
    Navigator.of(context).pop();
    action.onTrigger();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredActions;
    if (_highlightedIndex >= filtered.length) {
      _highlightedIndex = filtered.isEmpty ? 0 : filtered.length - 1;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown && filtered.isNotEmpty) {
              setState(() {
                _highlightedIndex = (_highlightedIndex + 1) % filtered.length;
              });
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp && filtered.isNotEmpty) {
              setState(() {
                _highlightedIndex = (_highlightedIndex - 1 + filtered.length) % filtered.length;
              });
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.enter && filtered.isNotEmpty) {
              _executeAction(filtered[_highlightedIndex]);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GlassPod(
          width: 780,
          height: 580,
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Header Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF121A2B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.55),
                    width: 1.3,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFF00F0FF), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText:
                              'Search any tool, code (AISC 360, ACI 318, ASCE 7, UFC 4-023-03), or action...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 12.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white54),
                        onPressed: () => _searchController.clear(),
                        tooltip: 'Clear search',
                      ),
                    const InfoTooltip(
                      title: 'Universal Command Palette & Encyclopedia',
                      codeRef: 'Shortcut: ⌘K / Ctrl+K',
                      message:
                          'Type to filter across all 30+ structural solvers, AI engines, CAD/BIM tools, and building templates. Hover any (i) button on the right of each row for full code formulas and instructions.',
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close Command Palette (Esc)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Category Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() {
                          _selectedCategory = cat;
                          _highlightedIndex = 0;
                        }),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF00F0FF) : const Color(0xFF141C2B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? const Color(0xFF00F0FF) : Colors.white12,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSel ? Colors.black : Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // Results List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matching engineering commands found for "$_query".',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          final isHi = i == _highlightedIndex;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: MouseRegion(
                              onEnter: (_) => setState(() => _highlightedIndex = i),
                              cursor: SystemMouseCursors.click,
                              child: InkWell(
                                onTap: () => _executeAction(item),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isHi
                                        ? const Color(0xFF1C273D)
                                        : const Color(0xFF101726),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isHi
                                          ? item.color.withValues(alpha: 0.7)
                                          : Colors.white10,
                                      width: isHi ? 1.2 : 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: item.color.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(9),
                                          border: Border.all(
                                            color: item.color.withValues(alpha: 0.45),
                                          ),
                                        ),
                                        child: Icon(item.icon, color: item.color, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    item.title,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 1.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF7EE787)
                                                        .withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: const Color(0xFF7EE787)
                                                          .withValues(alpha: 0.45),
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    item.codeRef,
                                                    style: const TextStyle(
                                                      color: Color(0xFF7EE787),
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.subtitle,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.55),
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (item.shortcut != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white10,
                                            borderRadius: BorderRadius.circular(5),
                                            border: Border.all(color: Colors.white24, width: 0.5),
                                          ),
                                          child: Text(
                                            item.shortcut!,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      InfoTooltip(
                                        title: item.title,
                                        codeRef: item.codeRef,
                                        message: item.infoDescription,
                                        size: 16,
                                        iconColor: item.color,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),

              // Footer Keyboard Hint Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Showing ${filtered.length} commands • ↑↓ Navigate • Enter Launch • Hover (i) for Engineering Guide',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'STRUCTURA NEXUS v4.5-APEX',
                    style: TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
