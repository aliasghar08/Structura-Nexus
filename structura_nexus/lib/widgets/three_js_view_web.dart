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
}

class ThreeJsStructuralViewport extends StatefulWidget {
  final StructuralModel model;
  final bool showDeformation;
  final double deformationScale;
  final bool showBmd;
  final bool showSfd;
  final bool showStressGradient;

  const ThreeJsStructuralViewport({
    super.key,
    required this.model,
    this.showDeformation = false,
    this.deformationScale = 50.0,
    this.showBmd = false,
    this.showSfd = false,
    this.showStressGradient = true,
  });

  @override
  State<ThreeJsStructuralViewport> createState() => _ThreeJsStructuralViewportState();
}

class _ThreeJsStructuralViewportState extends State<ThreeJsStructuralViewport> {
  static bool _viewRegistered = false;
  static const String _viewType = 'structura-three-view';
  static const String _containerId = 'structura-three-container';

  ThreeViewer? _viewer;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initViewer();
    });
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
