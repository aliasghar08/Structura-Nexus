// ============================================================================
// STRUCTURA NEXUS v4.1 — WebGPU Surrogate Bridge Conditional Export
// Exports web implementation in browser environments and stub in VM/unit test runners.
// Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
// ============================================================================

export 'webgpu_surrogate_bridge_stub.dart'
    if (dart.library.js_interop) 'webgpu_surrogate_bridge_web.dart';
