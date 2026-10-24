import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../models/structural_models.dart';
import 'three_js_view.dart';

class Structural3DViewport extends StatefulWidget {
  final StructuralModel model;
  final String? selectedNodeId;
  final String? selectedMemberId;
  final Function(String? nodeId)? onNodeSelected;
  final Function(String? memberId)? onMemberSelected;

  const Structural3DViewport({
    super.key,
    required this.model,
    this.selectedNodeId,
    this.selectedMemberId,
    this.onNodeSelected,
    this.onMemberSelected,
  });

  @override
  State<Structural3DViewport> createState() => _Structural3DViewportState();
}

class _Structural3DViewportState extends State<Structural3DViewport>
    with SingleTickerProviderStateMixin {
  // WebGL GPU acceleration mode (default on web)
  bool _useThreeJs = kIsWeb;
  bool _showBmd = false;
  bool _showDeformation = false;

  // Camera angles (spherical coordinates)
  double _yaw = 0.75; // Azimuth
  double _pitch = 0.35; // Elevation
  double _zoom = 42.0; // Pixels per meter
  Offset _panOffset = const Offset(0, 40);

  Offset? _lastPanPos;
  late AnimationController _vibrationController;

  @override
  void initState() {
    super.initState();
    _vibrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.model.displayMode == DisplayMode.modalVibration) {
      _vibrationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Structural3DViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model.displayMode == DisplayMode.modalVibration && !_vibrationController.isAnimating) {
      _vibrationController.repeat();
    } else if (widget.model.displayMode != DisplayMode.modalVibration && _vibrationController.isAnimating) {
      _vibrationController.stop();
    }
  }

  @override
  void dispose() {
    _vibrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _lastPanPos = details.localFocalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          if (details.pointerCount == 1 && _lastPanPos != null) {
            // Orbit camera
            final delta = details.localFocalPoint - _lastPanPos!;
            _yaw += delta.dx * 0.008;
            _pitch = (_pitch - delta.dy * 0.008).clamp(-1.4, 1.4);
          } else if (details.pointerCount > 1 && _lastPanPos != null) {
            // Pan & Zoom
            final delta = details.localFocalPoint - _lastPanPos!;
            _panOffset += delta;
            _zoom = (_zoom * details.scale).clamp(10.0, 150.0);
          }
          _lastPanPos = details.localFocalPoint;
        });
      },
      onTapUp: (details) {
        _handleTap(details.localPosition);
      },
      child: Container(
        color: const Color(0xFF090D14),
        child: Stack(
          children: [
            if (_useThreeJs)
              ThreeJsStructuralViewport(
                model: widget.model,
                showBmd: _showBmd,
                showDeformation: _showDeformation || widget.model.displayMode == DisplayMode.modalVibration,
                showStressGradient: true,
              )
            else
              AnimatedBuilder(
                animation: _vibrationController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _StructuralFramePainter(
                      model: widget.model,
                      yaw: _yaw,
                      pitch: _pitch,
                      zoom: _zoom,
                      panOffset: _panOffset,
                      selectedNodeId: widget.selectedNodeId,
                      selectedMemberId: widget.selectedMemberId,
                      vibrationPhase: _vibrationController.value,
                    ),
                  );
                },
              ),
            // Top Right Viewport Controls & WebGL Switcher
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Engine Switcher
                    InkWell(
                      onTap: () => setState(() => _useThreeJs = !_useThreeJs),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _useThreeJs ? const Color(0xFF00F0FF).withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _useThreeJs ? const Color(0xFF00F0FF) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _useThreeJs ? Icons.view_in_ar : Icons.brush,
                              size: 14,
                              color: _useThreeJs ? const Color(0xFF00F0FF) : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _useThreeJs ? 'WebGL 3D (GPU)' : 'Vector 2.5D',
                              style: TextStyle(
                                color: _useThreeJs ? const Color(0xFF00F0FF) : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // BMD Ribbon Toggle
                    InkWell(
                      onTap: () => setState(() => _showBmd = !_showBmd),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: _showBmd ? Colors.pinkAccent.withValues(alpha: 0.25) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _showBmd ? Colors.pinkAccent : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          'BMD',
                          style: TextStyle(
                            color: _showBmd ? Colors.pinkAccent : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Deformation Toggle
                    InkWell(
                      onTap: () => setState(() => _showDeformation = !_showDeformation),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: _showDeformation ? Colors.purpleAccent.withValues(alpha: 0.25) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _showDeformation ? Colors.purpleAccent : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          'Deflection ×50',
                          style: TextStyle(
                            color: _showDeformation ? Colors.purpleAccent : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Floating 3D Navigation Gizmo & Reset View Button
            Positioned(
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  _buildNavButton(Icons.zoom_in, () => setState(() => _zoom = (_zoom * 1.2).clamp(10.0, 150.0))),
                  const SizedBox(width: 8),
                  _buildNavButton(Icons.zoom_out, () => setState(() => _zoom = (_zoom / 1.2).clamp(10.0, 150.0))),
                  const SizedBox(width: 8),
                  _buildNavButton(Icons.center_focus_strong, () {
                    setState(() {
                      _yaw = 0.75;
                      _pitch = 0.35;
                      _zoom = 42.0;
                      _panOffset = const Offset(0, 40);
                    });
                  }),
                ],
              ),
            ),
            // Axis Compass Indicator (Top Left)
            Positioned(
              left: 16,
              top: 16,
              child: _buildCompass(),
            ),
            // Live Vibration Mode Banner (Top Center)
            if (widget.model.displayMode == DisplayMode.modalVibration)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00F0FF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.waves_rounded, size: 16, color: Color(0xFF00F0FF)),
                        const SizedBox(width: 8),
                        Text(
                          'SIMULATING DYNAMIC MODE ${widget.model.activeVibrationMode} VIBRATION',
                          style: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            setState(() {
                              widget.model.displayMode = DisplayMode.geometry;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF21262D),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Exit', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22).withValues(alpha: 0.85),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.white70),
      ),
    );
  }

  Widget _buildCompass() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withValues(alpha: 0.85),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('X', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          SizedBox(width: 4),
          Text('•', style: TextStyle(color: Colors.white24, fontSize: 10)),
          SizedBox(width: 4),
          Text('Y', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          SizedBox(width: 4),
          Text('•', style: TextStyle(color: Colors.white24, fontSize: 10)),
          SizedBox(width: 4),
          Text('Z', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleTap(Offset localPos) {
    // Project all nodes and find nearest within threshold
    String? tappedNodeId;
    double minDistance = 25.0;

    for (final node in widget.model.nodes) {
      final screenPos = _project3DTo2D(node.coords, context.size ?? const Size(800, 600));
      final dist = (screenPos - localPos).distance;
      if (dist < minDistance) {
        minDistance = dist;
        tappedNodeId = node.id;
      }
    }

    if (tappedNodeId != null) {
      widget.onNodeSelected?.call(tappedNodeId);
      return;
    }

    // Check members
    String? tappedMemberId;
    double minLineDist = 18.0;

    for (final member in widget.model.members) {
      final ni = widget.model.getNode(member.iNodeId);
      final nj = widget.model.getNode(member.jNodeId);
      if (ni == null || nj == null) continue;

      final pi = _project3DTo2D(ni.coords, context.size ?? const Size(800, 600));
      final pj = _project3DTo2D(nj.coords, context.size ?? const Size(800, 600));

      final dist = _pointToSegmentDistance(localPos, pi, pj);
      if (dist < minLineDist) {
        minLineDist = dist;
        tappedMemberId = member.id;
      }
    }

    widget.onMemberSelected?.call(tappedMemberId);
    if (tappedMemberId == null && tappedNodeId == null) {
      widget.onNodeSelected?.call(null);
      widget.onMemberSelected?.call(null);
    }
  }

  Offset _project3DTo2D(vm.Vector3 pt, Size size) {
    final cx = size.width / 2 + _panOffset.dx;
    final cy = size.height / 2 + _panOffset.dy;

    // Center scene around mean geometry
    final x = pt.x - 3.0;
    final y = pt.y - 2.5;
    final z = pt.z - 3.0;

    // Rotate yaw (around Y)
    final cosY = math.cos(_yaw);
    final sinY = math.sin(_yaw);
    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    // Rotate pitch (around X)
    final cosP = math.cos(_pitch);
    final sinP = math.sin(_pitch);
    final y2 = y * cosP - z1 * sinP;

    final sx = cx + x1 * _zoom;
    final sy = cy - y2 * _zoom; // Y is up in 3D, down on 2D screen

    return Offset(sx, sy);
  }

  double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final l2 = (b - a).distanceSquared;
    if (l2 == 0) return (p - a).distance;
    final t = math.max(0.0, math.min(1.0, ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2));
    final proj = Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy));
    return (p - proj).distance;
  }
}

class _StructuralFramePainter extends CustomPainter {
  final StructuralModel model;
  final double yaw;
  final double pitch;
  final double zoom;
  final Offset panOffset;
  final String? selectedNodeId;
  final String? selectedMemberId;
  final double vibrationPhase;

  _StructuralFramePainter({
    required this.model,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.panOffset,
    this.selectedNodeId,
    this.selectedMemberId,
    this.vibrationPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2 + panOffset.dx;
    final cy = size.height / 2 + panOffset.dy;

    Offset project(vm.Vector3 pt) {
      final x = pt.x - 3.0;
      final y = pt.y - 2.5;
      final z = pt.z - 3.0;

      final cosY = math.cos(yaw);
      final sinY = math.sin(yaw);
      final x1 = x * cosY - z * sinY;
      final z1 = x * sinY + z * cosY;

      final cosP = math.cos(pitch);
      final sinP = math.sin(pitch);
      final y2 = y * cosP - z1 * sinP;

      return Offset(cx + x1 * zoom, cy - y2 * zoom);
    }

    // 1. Draw Ground Plane Grid (X-Z)
    _drawGroundGrid(canvas, project);

    // 2. Draw Members
    for (final member in model.members) {
      final ni = model.getNode(member.iNodeId);
      final nj = model.getNode(member.jNodeId);
      if (ni == null || nj == null) continue;

      final isSelected = member.id == selectedMemberId;

      // Calculate deformed coordinates if applicable
      final vm.Vector3 defI;
      final vm.Vector3 defJ;

      if (model.displayMode == DisplayMode.modalVibration) {
        final offI = model.modalShapeOffsets[ni.id] ?? vm.Vector3.zero();
        final offJ = model.modalShapeOffsets[nj.id] ?? vm.Vector3.zero();
        final sway = math.sin(vibrationPhase * 2.0 * math.pi) * 0.7;
        defI = ni.coords + offI * sway;
        defJ = nj.coords + offJ * sway;
      } else {
        final defScale = model.deformationScale;
        defI = ni.coords +
            vm.Vector3(
              ni.displacements[0] * defScale,
              ni.displacements[1] * defScale,
              ni.displacements[2] * defScale,
            );
        defJ = nj.coords +
            vm.Vector3(
              nj.displacements[0] * defScale,
              nj.displacements[1] * defScale,
              nj.displacements[2] * defScale,
            );
      }

      final pUndeformedI = project(ni.coords);
      final pUndeformedJ = project(nj.coords);
      final pDeformedI = project(defI);
      final pDeformedJ = project(defJ);

      // Draw undeformed ghost line if deformed mode
      if (model.displayMode != DisplayMode.geometry) {
        final ghostPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(pUndeformedI, pUndeformedJ, ghostPaint);
      }

      // Render mode specific visual representation
      final pI = (model.displayMode == DisplayMode.geometry) ? pUndeformedI : pDeformedI;
      final pJ = (model.displayMode == DisplayMode.geometry) ? pUndeformedJ : pDeformedJ;

      _drawMemberVisual(
        canvas: canvas,
        member: member,
        pI: pI,
        pJ: pJ,
        isSelected: isSelected,
        mode: model.displayMode,
      );
    }

    // 3. Draw Nodes & Supports
    for (final node in model.nodes) {
      final isSelected = node.id == selectedNodeId;
      final vm.Vector3 defCoords;

      if (model.displayMode == DisplayMode.modalVibration) {
        final off = model.modalShapeOffsets[node.id] ?? vm.Vector3.zero();
        final sway = math.sin(vibrationPhase * 2.0 * math.pi) * 0.7;
        defCoords = node.coords + off * sway;
      } else {
        final defScale = model.deformationScale;
        defCoords = node.coords +
            vm.Vector3(
              node.displacements[0] * defScale,
              node.displacements[1] * defScale,
              node.displacements[2] * defScale,
            );
      }

      final pt = (model.displayMode == DisplayMode.geometry)
          ? project(node.coords)
          : project(defCoords);

      // Support Glyphs
      if (node.isFixed) {
        _drawFixedSupportGlyph(canvas, pt);
      } else if (node.isPinned) {
        _drawPinnedSupportGlyph(canvas, pt);
      } else if (node.isRoller) {
        _drawRollerSupportGlyph(canvas, pt);
      }

      // Applied Load Vectors
      if (node.hasLoad) {
        _drawLoadVector(canvas, pt, node.loads);
      }

      // Joint Node Dot
      final nodePaint = Paint()
        ..color = isSelected ? const Color(0xFF00F0FF) : const Color(0xFFE6EDF3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isSelected ? 6.0 : 4.0, nodePaint);

      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : Colors.black87
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pt, isSelected ? 6.0 : 4.0, borderPaint);

      // Node label
      final textSpan = TextSpan(
        text: node.id,
        style: TextStyle(
          color: isSelected ? const Color(0xFF00F0FF) : Colors.white60,
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, pt + const Offset(7, -8));
    }
  }

  void _drawGroundGrid(Canvas canvas, Offset Function(vm.Vector3) project) {
    final gridPaint = Paint()
      ..color = const Color(0xFF21262D).withValues(alpha: 0.6)
      ..strokeWidth = 0.8;

    const span = 8.0;
    const step = 2.0;

    for (double x = -2.0; x <= span; x += step) {
      final p1 = project(vm.Vector3(x, 0.0, -2.0));
      final p2 = project(vm.Vector3(x, 0.0, span));
      canvas.drawLine(p1, p2, gridPaint);
    }

    for (double z = -2.0; z <= span; z += step) {
      final p1 = project(vm.Vector3(-2.0, 0.0, z));
      final p2 = project(vm.Vector3(span, 0.0, z));
      canvas.drawLine(p1, p2, gridPaint);
    }
  }

  void _drawMemberVisual({
    required Canvas canvas,
    required StructuralMember member,
    required Offset pI,
    required Offset pJ,
    required bool isSelected,
    required DisplayMode mode,
  }) {
    Color memberColor = const Color(0xFF58A6FF); // Standard steel blue
    double strokeWidth = isSelected ? 4.5 : 2.5;

    switch (mode) {
      case DisplayMode.geometry:
      case DisplayMode.deformed:
        memberColor = isSelected ? const Color(0xFF00F0FF) : const Color(0xFF58A6FF);
        break;

      case DisplayMode.sfdRibbon:
        // Color based on shear force magnitude
        final shearMag = member.shearY.abs();
        memberColor = shearMag > 20000.0
            ? const Color(0xFFEF4444)
            : (shearMag > 5000.0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
        _drawRibbonExtrusion(canvas, pI, pJ, memberColor, member.shearY * 0.0004);
        break;

      case DisplayMode.bmdRibbon:
        // Color based on bending moment
        final momentMag = member.momentZ.abs();
        memberColor = momentMag > 30000.0
            ? const Color(0xFFFF0055)
            : (momentMag > 10000.0 ? const Color(0xFFF59E0B) : const Color(0xFF00F0FF));
        _drawRibbonExtrusion(canvas, pI, pJ, memberColor, member.momentZ * 0.0003);
        break;

      case DisplayMode.vonMisesStress:
        // Stress gradient: Blue -> Green -> Amber -> Red
        final vm = member.maxVonMisesMpa;
        if (vm > 300.0) {
          memberColor = const Color(0xFFEF4444); // Red
        } else if (vm > 180.0) {
          memberColor = const Color(0xFFF59E0B); // Amber
        } else if (vm > 80.0) {
          memberColor = const Color(0xFF10B981); // Green
        } else {
          memberColor = const Color(0xFF38BDF8); // Blue
        }
        break;

      case DisplayMode.aiscCompliance:
        if (member.governingDcr > 1.0) {
          memberColor = const Color(0xFFFF0055); // Flashing Red
          strokeWidth = 4.0;
        } else if (member.governingDcr > 0.85) {
          memberColor = const Color(0xFFF59E0B); // Amber warning
        } else if (member.axialForceN > 1000.0) {
          memberColor = const Color(0xFF00F0FF); // Solid Cyan (AISC Tension)
        } else if (member.axialForceN < -1000.0) {
          memberColor = const Color(0xFFE11D48); // Crimson (AISC Compression Buckling)
        } else {
          memberColor = const Color(0xFF10B981); // Green pass
        }
        break;

      case DisplayMode.modalVibration:
        memberColor = isSelected ? const Color(0xFF00F0FF) : const Color(0xFF38BDF8);
        strokeWidth = 3.2;
        break;
    }

    final linePaint = Paint()
      ..color = memberColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(pI, pJ, linePaint);

    if (isSelected) {
      final glowPaint = Paint()
        ..color = memberColor.withValues(alpha: 0.3)
        ..strokeWidth = strokeWidth + 5.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(pI, pJ, glowPaint);
    }
  }

  void _drawRibbonExtrusion(Canvas canvas, Offset pI, Offset pJ, Color color, double heightPx) {
    final dir = pJ - pI;
    if (dir.distance == 0) return;
    final normal = Offset(-dir.dy, dir.dx) / dir.distance;
    final offsetH = normal * heightPx.clamp(-35.0, 35.0);

    final path = Path()
      ..moveTo(pI.dx, pI.dy)
      ..lineTo(pI.dx + offsetH.dx, pI.dy + offsetH.dy)
      ..lineTo(pJ.dx + offsetH.dx, pJ.dy + offsetH.dy)
      ..lineTo(pJ.dx, pJ.dy)
      ..close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);
  }

  void _drawFixedSupportGlyph(Canvas canvas, Offset pt) {
    final basePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 2.0;
    // Ground horizontal bar
    canvas.drawLine(pt + const Offset(-10, 0), pt + const Offset(10, 0), basePaint);
    // Ground hatch lines
    for (double i = -8; i <= 8; i += 4) {
      canvas.drawLine(pt + Offset(i, 0), pt + Offset(i - 4, 6), basePaint);
    }
  }

  void _drawPinnedSupportGlyph(Canvas canvas, Offset pt) {
    final pinPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(pt.dx, pt.dy)
      ..lineTo(pt.dx - 7, pt.dy + 10)
      ..lineTo(pt.dx + 7, pt.dy + 10)
      ..close();
    canvas.drawPath(path, pinPaint);
  }

  void _drawRollerSupportGlyph(Canvas canvas, Offset pt) {
    final rollerPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(pt + const Offset(-4, 6), 3.0, rollerPaint);
    canvas.drawCircle(pt + const Offset(4, 6), 3.0, rollerPaint);
    canvas.drawLine(pt + const Offset(-9, 10), pt + const Offset(9, 10), rollerPaint);
  }

  void _drawLoadVector(Canvas canvas, Offset pt, List<double> loads) {
    final fx = loads[0];
    final fy = loads[1];

    final arrowPaint = Paint()
      ..color = const Color(0xFFFACC15)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Projected force vector
    final dir = Offset(fx * 0.001, -fy * 0.001); // screen Y is inverted
    if (dir.distance > 0.01) {
      final norm = dir / dir.distance;
      final arrowLen = 32.0;
      final endPt = pt;
      final startPt = endPt - norm * arrowLen;

      canvas.drawLine(startPt, endPt, arrowPaint);

      // Arrowhead
      final head1 = endPt - norm * 8.0 + Offset(-norm.dy, norm.dx) * 5.0;
      final head2 = endPt - norm * 8.0 - Offset(-norm.dy, norm.dx) * 5.0;
      final headPath = Path()
        ..moveTo(endPt.dx, endPt.dy)
        ..lineTo(head1.dx, head1.dy)
        ..lineTo(head2.dx, head2.dy)
        ..close();
      canvas.drawPath(headPath, Paint()..color = const Color(0xFFFACC15));
    }
  }

  @override
  bool shouldRepaint(covariant _StructuralFramePainter oldDelegate) => true;
}
