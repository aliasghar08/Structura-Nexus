// ============================================================================
// InfoTooltip — High-Contrast Accessible visionOS Engineering Info Button (i)
// Instant hover popover with optional Title & Code Reference badge over 3D WebGL
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:flutter/material.dart';

class InfoTooltip extends StatefulWidget {
  final String message;
  final String? title;
  final String? codeRef;
  final double size;
  final Color? iconColor;

  const InfoTooltip({
    super.key,
    required this.message,
    this.title,
    this.codeRef,
    this.size = 18.0,
    this.iconColor,
  });

  @override
  State<InfoTooltip> createState() => _InfoTooltipState();
}

class _InfoTooltipState extends State<InfoTooltip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.iconColor ?? const Color(0xFF00F0FF);

    final RichMessage? richMsg = (widget.title != null || widget.codeRef != null)
        ? RichMessage(
            title: widget.title,
            codeRef: widget.codeRef,
            body: widget.message,
            accentColor: baseColor,
          )
        : null;

    return Tooltip(
      message: richMsg == null ? widget.message : null,
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
      child: MouseRegion(
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
      ),
    );
  }
}

class RichMessage {
  final String? title;
  final String? codeRef;
  final String body;
  final Color accentColor;

  const RichMessage({
    this.title,
    this.codeRef,
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


