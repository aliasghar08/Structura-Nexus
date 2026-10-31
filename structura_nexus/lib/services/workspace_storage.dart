// ============================================================================
// WorkspacePreferences — Persistent Workspace Customization & Position Store
// Remembers slideable dock positions, visibility, panel widths, and styles across sessions
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'workspace_storage_stub.dart'
    if (dart.library.js_interop) 'workspace_storage_web.dart';

class WorkspacePreferences {
  static const String prefix = 'structura_workspace_';

  static double getDouble(String key, double defaultValue) {
    final raw = WorkspaceStoragePlatform.getItem('$prefix$key');
    if (raw == null) return defaultValue;
    return double.tryParse(raw) ?? defaultValue;
  }

  static void setDouble(String key, double value) {
    WorkspaceStoragePlatform.setItem('$prefix$key', value.toString());
  }

  static bool getBool(String key, bool defaultValue) {
    final raw = WorkspaceStoragePlatform.getItem('$prefix$key');
    if (raw == null) return defaultValue;
    return raw == 'true';
  }

  static bool? getOptionalBool(String key) {
    final raw = WorkspaceStoragePlatform.getItem('$prefix$key');
    if (raw == null) return null;
    return raw == 'true';
  }

  static void setBool(String key, bool value) {
    WorkspaceStoragePlatform.setItem('$prefix$key', value ? 'true' : 'false');
  }

  static String getString(String key, String defaultValue) {
    final raw = WorkspaceStoragePlatform.getItem('$prefix$key');
    if (raw == null || raw.isEmpty) return defaultValue;
    return raw;
  }

  static void setString(String key, String value) {
    WorkspaceStoragePlatform.setItem('$prefix$key', value);
  }

  static void remove(String key) {
    WorkspaceStoragePlatform.removeItem('$prefix$key');
  }

  static void freezeOrbit(bool freeze) {
    WorkspaceStoragePlatform.freezeOrbit(freeze);
  }
}
