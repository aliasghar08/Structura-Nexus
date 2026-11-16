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

@JS('JSON.stringify')
external JSString _jsonStringify(JSAny? obj);

extension type ThreeViewer(JSObject _) implements JSObject {
  external void loadModel(JSAny model);
  external void setDeformationMode(bool enabled, double scale);
  external void setBmdVisible(bool visible);
  external void setSfdVisible(bool visible);
  external void setStressOverlay(bool visible);
  external void updatePredictedDisplacements(JSAny displacements);
  external void setCameraPreset(JSString preset);
  external void zoomIn();
  external void zoomOut();
}

extension type NodeDragDetail(JSObject _) implements JSObject {
  external JSString? get nodeId;
  external JSString? get memberId;
  external JSNumber? get x;
  external JSNumber? get y;
  external JSNumber? get z;
}

class ThreeJsStructuralViewport extends StatefulWidget {
  final StructuralModel model;
  final int modelRevision;
  final bool showDeformation;
  final double deformationScale;
  final bool showBmd;
  final bool showSfd;
  final bool showStressGradient;
  final void Function(String? nodeId)? onNodeSelected;
  final void Function(String? memberId)? onMemberSelected;
  final void Function(Set<String> nodeIds, Set<String> memberIds)? onMultiSelectChanged;
  final void Function(String nodeId, double x, double y, double z)? onNodeDragged;
  final void Function(String nodeId, double x, double y, double z)? onNodeDragEnd;

  const ThreeJsStructuralViewport({
    super.key,
    required this.model,
    this.modelRevision = 0,
    this.showDeformation = false,
    this.deformationScale = 50.0,
    this.showBmd = false,
    this.showSfd = false,
    this.showStressGradient = true,
    this.onNodeSelected,
    this.onMemberSelected,
    this.onMultiSelectChanged,
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
  JSFunction? _nodeSelectListener;
  JSFunction? _memberSelectListener;
  JSFunction? _multiSelectListener;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    _setupDragEventListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initViewer();
    });
  }

  void setCameraPreset(String preset) {
    try {
      _viewer?.setCameraPreset(preset.toJS);
    } catch (_) {}
  }

  void zoomIn() {
    try {
      _viewer?.zoomIn();
    } catch (_) {}
  }

  void zoomOut() {
    try {
      _viewer?.zoomOut();
    } catch (_) {}
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

    _nodeSelectListener = ((web.Event event) {
      final customEv = event as web.CustomEvent;
      if (customEv.detail != null) {
        final detail = NodeDragDetail(customEv.detail as JSObject);
        final id = detail.nodeId?.toDart;
        if (id != null) {
          widget.onNodeSelected?.call(id);
        }
      }
    }).toJS;

    _memberSelectListener = ((web.Event event) {
      final customEv = event as web.CustomEvent;
      if (customEv.detail != null) {
        final detail = NodeDragDetail(customEv.detail as JSObject);
        final id = detail.memberId?.toDart;
        if (id != null) {
          widget.onMemberSelected?.call(id);
        }
      }
    }).toJS;

    _multiSelectListener = ((web.Event event) {
      final customEv = event as web.CustomEvent;
      if (customEv.detail != null) {
        try {
          final jsonStr = _jsonStringify(customEv.detail).toDart;
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final nList = (map['nodeIds'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? <String>{};
          final mList = (map['memberIds'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? <String>{};
          widget.onMultiSelectChanged?.call(nList, mList);
        } catch (_) {}
      }
    }).toJS;

    web.window.addEventListener('structura-node-dragged', _dragListener);
    web.window.addEventListener('structura-node-drag-end', _dragEndListener);
    web.window.addEventListener('structura-node-selected', _nodeSelectListener);
    web.window.addEventListener('structura-member-selected', _memberSelectListener);
    web.window.addEventListener('structura-multi-selected', _multiSelectListener);
  }

  @override
  void dispose() {
    if (_dragListener != null) {
      web.window.removeEventListener('structura-node-dragged', _dragListener);
    }
    if (_dragEndListener != null) {
      web.window.removeEventListener('structura-node-drag-end', _dragEndListener);
    }
    if (_nodeSelectListener != null) {
      web.window.removeEventListener('structura-node-selected', _nodeSelectListener);
    }
    if (_memberSelectListener != null) {
      web.window.removeEventListener('structura-member-selected', _memberSelectListener);
    }
    if (_multiSelectListener != null) {
      web.window.removeEventListener('structura-multi-selected', _multiSelectListener);
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
      Future.delayed(const Duration(milliseconds: 60), () {
        if (mounted) _syncModel();
      });
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
    try {
      final jsViewer = _initStructuraThreeViewer(_containerId.toJS);
      if (jsViewer != null) {
        _viewer = ThreeViewer(jsViewer);
      }
      if (_viewer == null) return;

      final jsonPayload = jsonEncode(widget.model.toGraphPayload('THREE_VIEW'));
      final parsedObj = _jsonParse(jsonPayload.toJS);
      if (parsedObj != null) {
        _viewer!.loadModel(parsedObj);
      }
      _syncDisplayOptions();
    } catch (e) {
      debugPrint('[ThreeJsStructuralViewport] Error syncing model: $e');
    }
  }

  void _syncDisplayOptions() {
    try {
      if (_viewer == null) return;
      _viewer!.setDeformationMode(widget.showDeformation, widget.deformationScale);
      _viewer!.setBmdVisible(widget.showBmd);
      _viewer!.setSfdVisible(widget.showSfd);
      _viewer!.setStressOverlay(widget.showStressGradient);
    } catch (e) {
      debugPrint('[ThreeJsStructuralViewport] Error syncing display options: $e');
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

  void reloadModel() {
    _syncModel();
  }

  @override
  void didUpdateWidget(covariant ThreeJsStructuralViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool needsModelSync = widget.modelRevision != oldWidget.modelRevision ||
        widget.model != oldWidget.model ||
        widget.model.nodes.length != oldWidget.model.nodes.length ||
        widget.model.members.length != oldWidget.model.members.length;

    final bool needsDisplaySync = widget.showDeformation != oldWidget.showDeformation ||
        widget.deformationScale != oldWidget.deformationScale ||
        widget.showBmd != oldWidget.showBmd ||
        widget.showSfd != oldWidget.showSfd ||
        widget.showStressGradient != oldWidget.showStressGradient;

    if (needsModelSync) {
      _syncModel();
    } else if (needsDisplaySync) {
      _syncDisplayOptions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewType);
  }
}
