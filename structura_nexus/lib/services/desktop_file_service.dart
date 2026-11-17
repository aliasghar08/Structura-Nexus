// ============================================================================
// DesktopFileService — Cross-Platform Native File I/O & Document Handler
// Handles native desktop file associations (.s2k, .ifc, .dxf, .structura.json)
// and deliverable exports with embedded author/DMCA headers.
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'desktop_file_service_stub.dart'
    if (dart.library.io) 'desktop_file_service_io.dart'
    if (dart.library.js_interop) 'desktop_file_service_web.dart';

class DesktopFileService {
  static final DesktopFileService _instance = DesktopFileService._internal();
  factory DesktopFileService() => _instance;
  DesktopFileService._internal();

  final DesktopFilePlatform _platform = getDesktopFilePlatform();

  bool get isDesktopPlatform => _platform.isDesktopPlatform;

  Future<String?> openModelFile() => _platform.openModelFile();

  Future<bool> saveProjectFile(String fileName, String content) =>
      _platform.saveProjectFile(fileName, content);

  Future<String> exportDeliverable({
    required String fileName,
    required String content,
    required String fileType,
  }) =>
      _platform.exportDeliverable(
        fileName: fileName,
        content: content,
        fileType: fileType,
      );
}
