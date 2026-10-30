import 'package:flutter/material.dart';
import '../models/structural_models.dart';

class ThreeJsStructuralViewport extends StatefulWidget {
  final StructuralModel model;
  final bool showDeformation;
  final double deformationScale;
  final bool showBmd;
  final bool showSfd;
  final bool showStressGradient;
  final void Function(String nodeId, double x, double y, double z)? onNodeDragged;
  final void Function(String nodeId, double x, double y, double z)? onNodeDragEnd;

  const ThreeJsStructuralViewport({
    super.key,
    required this.model,
    this.showDeformation = false,
    this.deformationScale = 50.0,
    this.showBmd = false,
    this.showSfd = false,
    this.showStressGradient = true,
    this.onNodeDragged,
    this.onNodeDragEnd,
  });

  @override
  State<ThreeJsStructuralViewport> createState() => ThreeJsStructuralViewportState();
}

class ThreeJsStructuralViewportState extends State<ThreeJsStructuralViewport> {
  void updateDisplacements(Map<String, dynamic> displacements) {}
  void setCameraPreset(String preset) {}
  void zoomIn() {}
  void zoomOut() {}

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.view_in_ar, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'WebGL 3D GPU Engine (${widget.model.members.length} members, ${widget.model.nodes.length} joints)',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hardware-accelerated Three.js WebGL viewport active on Web platform.\nOrbit controls: Click & Drag to Rotate • Right-Click to Pan • Scroll to Zoom',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
