// ============================================================================
// WorkspaceStoragePlatform (Web implementation using window.localStorage)
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

import 'package:web/web.dart' as web;

class WorkspaceStoragePlatform {
  static String? getItem(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  static void setItem(String key, String value) {
    try {
      web.window.localStorage.setItem(key, value);
    } catch (_) {}
  }

  static void removeItem(String key) {
    try {
      web.window.localStorage.removeItem(key);
    } catch (_) {}
  }

  static void clear() {
    try {
      web.window.localStorage.clear();
    } catch (_) {}
  }

  static void freezeOrbit(bool freeze) {
    try {
      final eventName = freeze ? 'structura-freeze-orbit' : 'structura-unfreeze-orbit';
      web.window.dispatchEvent(web.CustomEvent(eventName));
    } catch (_) {}
  }
}

