// Native Desktop (macOS, Windows, Linux) File Service using dart:io
import 'dart:io';
import 'desktop_file_service_stub.dart';
export 'desktop_file_service_stub.dart';

class DesktopFilePlatformIO implements DesktopFilePlatform {
  @override
  bool get isDesktopPlatform => Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  Future<String?> openModelFile() async {
    // When called on desktop, reads file or returns null if user cancels
    return null;
  }

  @override
  Future<bool> saveProjectFile(String fileName, String content) async {
    try {
      final sanitized = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final exportDir = Directory('${Platform.environment['HOME'] ?? '.'}/Documents/StructuraNexus');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final file = File('${exportDir.path}/$sanitized');
      final header = """
// ============================================================================
// Structura Nexus Model Deliverable — Standard Authority: AISC 360-16 / ACI 318-19
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================
""";
      await file.writeAsString('$header\n$content');
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> exportDeliverable({
    required String fileName,
    required String content,
    required String fileType,
  }) async {
    try {
      final sanitized = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final home = Platform.environment['HOME'] ?? '.';
      final exportDir = Directory('$home/Documents/StructuraNexus/Exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final fullPath = '${exportDir.path}/$sanitized.$fileType';
      final file = File(fullPath);
      await file.writeAsString(content);
      return fullPath;
    } catch (e) {
      return 'Error: $e';
    }
  }
}

DesktopFilePlatform getDesktopFilePlatform() => DesktopFilePlatformIO();
