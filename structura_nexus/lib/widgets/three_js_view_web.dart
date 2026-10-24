import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../models/structural_models.dart';

@JS('initStructuraThreeViewer')
external JSObject? _initStructuraThreeViewer(JSString containerId);

@JS('JSON.parse')
external JSAny? _jsonParse(JSString jsonStr);

extension type ThreeViewer(JSObject _) implements JSObject {
  external void loadModel(JSAny model);
  external void setDeformationMode(bool enabled, double scale);
  external void setBmdVisible(bool visible);
  external void setStressOverlay(bool visible);
  external void updatePredictedDisplacements(JSAny displacements);
}

extension type NodeDragDetail(JSObject _) implements JSObject {
  external JSString? get nodeId;
  external JSNumber? get x;
  external JSNumber? get y;
  external JSNumber? get z;
}

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
  static bool _viewRegistered = false;
  static const String _viewType = 'structura-three-view';
  static const String _containerId = 'structura-three-container';

  ThreeViewer? _viewer;
  JSFunction? _dragListener;
  JSFunction? _dragEndListener;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    _setupDragEventListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initViewer();
    });
  }

  void _setupDragEventListeners() {
    _dragListener = ((web.Event event) {
      final customEv = event as web.CustomEvent;
      if (customEv.detail != null) {
        final detail = NodeDragDetail(customEv.detail as JSObject);
        final id = detail.nodeId?.toDart;
        final x = detail.x?.toDartDouble;
        final y = detail.y?.toDartDouble;
        final z = detail.z?.toDartDouble;
        if (id != null && x != null && y != null && z != null) {
          widget.onNodeDragged?.call(id, x, y, z);
        }
      }
    }).toJS;

    _dragEndListener = ((web.Event event) {
      final customEv = event as web.CustomEvent;
      if (customEv.detail != null) {
        final detail = NodeDragDetail(customEv.detail as JSObject);
        final id = detail.nodeId?.toDart;
        final x = detail.x?.toDartDouble;
        final y = detail.y?.toDartDouble;
        final z = detail.z?.toDartDouble;
        if (id != null && x != null && y != null && z != null) {
          widget.onNodeDragEnd?.call(id, x, y, z);
        }
      }
    }).toJS;

    web.window.addEventListener('structura-node-dragged', _dragListener);
    web.window.addEventListener('structura-node-drag-end', _dragEndListener);
  }

  @override
  void dispose() {
    if (_dragListener != null) {
      web.window.removeEventListener('structura-node-dragged', _dragListener);
    }
    if (_dragEndListener != null) {
      web.window.removeEventListener('structura-node-drag-end', _dragEndListener);
    }
    super.dispose();
  }

  void _registerViewFactory() {
    if (_viewRegistered) return;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final div = web.document.createElement('div') as web.HTMLDivElement;
      div.id = _containerId;
      div.style.width = '100%';
      div.style.height = '100%';
      div.style.overflow = 'hidden';
      div.style.backgroundColor = '#0a0e17';
      return div;
    });
    _viewRegistered = true;
  }

  void _initViewer() {
    try {
      final jsViewer = _initStructuraThreeViewer(_containerId.toJS);
      if (jsViewer != null) {
        _viewer = ThreeViewer(jsViewer);
        _syncModel();
      }
    } catch (e) {
      debugPrint('[ThreeJsStructuralViewport] Initialization notice: $e');
    }
  }

  void _syncModel() {
    if (_viewer == null) return;
    try {
      final jsonPayload = jsonEncode(widget.model.toGraphPayload('THREE_VIEW'));
      final parsedObj = _jsonParse(jsonPayload.toJS);
      if (parsedObj != null) {
        _viewer!.loadModel(parsedObj);
      }
      _viewer!.setDeformationMode(widget.showDeformation, widget.deformationScale);
      _viewer!.setBmdVisible(widget.showBmd);
      _viewer!.setStressOverlay(widget.showStressGradient);
    } catch (e) {
      debugPrint('[ThreeJsStructuralViewport] Error syncing model: $e');
    }
  }

  /// Update deformed visualization in real time with 6-DOF surrogate predicted deflections.
  void updateDisplacements(Map<String, dynamic> displacements) {
    if (_viewer == null) return;
    try {
      final jsonStr = jsonEncode(displacements);
      final parsed = _jsonParse(jsonStr.toJS);
      if (parsed != null) {
        _viewer!.updatePredictedDisplacements(parsed);
      }
    } catch (e) {
      debugPrint('[ThreeJsStructuralViewport] Error updating displacements: $e');
    }
  }

  @override
  void didUpdateWidget(covariant ThreeJsStructuralViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncModel();
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewType);
  }
}
