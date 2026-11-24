// ============================================================================
// InfoTooltip — High-Contrast Accessible visionOS Engineering Info Button (i)
// Structured Engineering Explanations: Title, Description, Standard/Range & Formula
// Interactive Tap-to-Inspect Specification Modal with Clipboard Citation
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_pod.dart';

class InfoTooltip extends StatefulWidget {
  final String message;
  final String? description;
  final String? title;
  final String? codeRef;
  final String? standardOrRange;
  final String? formula;
  final double size;
  final Color? iconColor;
  final Widget? child;
  final bool enableModalOnTap;

  const InfoTooltip({
    super.key,
    this.message = '',
    this.description,
    this.title,
    this.codeRef,
    this.standardOrRange,
    this.formula,
    this.size = 18.0,
    this.iconColor,
    this.child,
    this.enableModalOnTap = true,
  });

  /// Factory constructor to wrap an existing widget with the rich engineering tooltip
  const InfoTooltip.wrap({
    super.key,
    required Widget this.child,
    this.message = '',
    this.description,
    this.title,
    this.codeRef,
    this.standardOrRange,
    this.formula,
    this.size = 18.0,
    this.iconColor,
    this.enableModalOnTap = false,
  });

  String get effectiveDescription =>
      (description != null && description!.isNotEmpty) ? description! : message;

  String? get effectiveStandardOrRange =>
      (standardOrRange != null && standardOrRange!.isNotEmpty)
          ? standardOrRange
          : codeRef;

  @override
  State<InfoTooltip> createState() => _InfoTooltipState();
}

class _InfoTooltipState extends State<InfoTooltip> {
  bool _isHovered = false;

  void _openInteractiveSpecModal(BuildContext context) {
    if (!widget.enableModalOnTap) return;

    final baseColor = widget.iconColor ?? const Color(0xFF00F0FF);
    final title = widget.title ?? 'Engineering Specification';
    final code = widget.codeRef ?? widget.effectiveStandardOrRange ?? 'Standard Design Criterion';
    final desc = widget.effectiveDescription;
    final formula = widget.formula;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassPod(
                padding: const EdgeInsets.all(22),
                borderRadius: 22,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row with glowing Icon and close button
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: baseColor.withValues(alpha: 0.15),
                            border: Border.all(color: baseColor, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: baseColor.withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Icon(Icons.info_rounded, color: baseColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF34D399).withValues(alpha: 0.5),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassPod.divider(),
                    const SizedBox(height: 14),

                    // Governing Equation / Formula Box (if provided)
                    if (formula != null && formula.isNotEmpty) ...[
                      const Text(
                        'GOVERNING EQUATION / TENSOR FORMULATION',
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF080D17),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          formula,
                          style: const TextStyle(
                            color: Color(0xFF7EE787),
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Standard or Allowable Range
                    if (widget.effectiveStandardOrRange != null) ...[
                      const Text(
                        'DESIGN STANDARD & RECOMMENDED BOUNDS',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2433).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          widget.effectiveStandardOrRange!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Engineering Description
                    const Text(
                      'CIVIL & STRUCTURAL ENGINEERING SPECIFICATION',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions Bar: Copy Citation & Close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            final citation = [
                              '$title ($code)',
                              if (formula != null) 'Formula: $formula',
                              'Standard: ${widget.effectiveStandardOrRange ?? ""}',
                              'Description: $desc',
                            ].join('\n');
                            Clipboard.setData(ClipboardData(text: citation));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Engineering specification copied to clipboard!'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.of(ctx).pop();
                          },
                          icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF00F0FF)),
                          label: const Text(
                            'Copy Spec',
                            style: TextStyle(color: Color(0xFF00F0FF), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00F0FF),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Dismiss', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.iconColor ?? const Color(0xFF00F0FF);
    final bodyText = widget.effectiveDescription;
    final badgeText = widget.effectiveStandardOrRange;

    final RichMessage? richMsg = (widget.title != null || badgeText != null || widget.formula != null)
        ? RichMessage(
            title: widget.title,
            codeRef: badgeText,
            formula: widget.formula,
            body: bodyText,
            accentColor: baseColor,
          )
        : null;

    final interactiveChild = widget.child != null
        ? widget.child!
        : MouseRegion(
            cursor: SystemMouseCursors.help,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: widget.size + 1,
                height: widget.size + 1,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isHovered
                      ? baseColor.withValues(alpha: 0.28)
                      : baseColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: _isHovered
                        ? baseColor
                        : baseColor.withValues(alpha: 0.55),
                    width: _isHovered ? 1.2 : 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: baseColor.withValues(alpha: _isHovered ? 0.65 : 0.30),
                      blurRadius: _isHovered ? 10 : 5,
                      spreadRadius: _isHovered ? 1.0 : 0.2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: (widget.size - 3).clamp(9.0, 24.0),
                  color: _isHovered ? Colors.white : baseColor,
                ),
              ),
            ),
          );

    return Tooltip(
      message: richMsg == null ? bodyText : null,
      richMessage: richMsg?.toTextSpan(),
      waitDuration: Duration.zero,
      showDuration: const Duration(seconds: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B101B).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.65),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.85),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: baseColor.withValues(alpha: 0.22),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
      ),
      child: widget.enableModalOnTap
          ? GestureDetector(
              onTap: () => _openInteractiveSpecModal(context),
              child: interactiveChild,
            )
          : interactiveChild,
    );
  }
}

class RichMessage {
  final String? title;
  final String? codeRef;
  final String? formula;
  final String body;
  final Color accentColor;

  const RichMessage({
    this.title,
    this.codeRef,
    this.formula,
    required this.body,
    required this.accentColor,
  });

  InlineSpan toTextSpan() {
    return TextSpan(
      children: [
        if (title != null)
          TextSpan(
            text: '$title  ',
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        if (codeRef != null)
          TextSpan(
            text: '[$codeRef]\n',
            style: const TextStyle(
              color: Color(0xFF7EE787),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          )
        else if (title != null)
          const TextSpan(text: '\n'),
        if (formula != null) ...[
          const TextSpan(
            text: 'EQ: ',
            style: TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(
            text: '$formula\n',
            style: const TextStyle(
              color: Color(0xFF00F0FF),
              fontFamily: 'monospace',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        TextSpan(
          text: body,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
