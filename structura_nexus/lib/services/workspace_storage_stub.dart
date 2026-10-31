// ============================================================================
// WorkspaceStoragePlatform (Stub for VM and unit test environments)
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

class WorkspaceStoragePlatform {
  static final Map<String, String> _memoryStorage = {};

  static String? getItem(String key) => _memoryStorage[key];

  static void setItem(String key, String value) {
    _memoryStorage[key] = value;
  }

  static void removeItem(String key) {
    _memoryStorage.remove(key);
  }

  static void clear() {
    _memoryStorage.clear();
  }

  static void freezeOrbit(bool freeze) {}
}

