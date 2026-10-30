/**
 * Structura Nexus: High-Performance Hardware-Accelerated Three.js WebGL Engine
 * Multi-story space frame rendering, extruded BMD/SFD ribbons, deformation magnification,
 * real-time pointer raycasting, node drag-and-morph, and 60 FPS surrogate streaming.
 */

(function () {
  class StructuraThreeViewer {
    constructor(containerId) {
      this.containerId = typeof containerId === "string" ? containerId : (containerId && containerId.id) || "structura-three-container";
      this.container = typeof containerId === "string" ? document.getElementById(containerId) : (containerId instanceof HTMLElement ? containerId : document.getElementById(this.containerId));
      this.scene = null;
      this.camera = null;
      this.renderer = null;
      this.controls = null;
      this.animId = null;
      this._waitTimer = null;
      this._pendingModel = null;

      // Group containers - guaranteed non-null
      this.structureGroup = new THREE.Group();
      this.deformationGroup = new THREE.Group();
      this.diagramGroup = new THREE.Group();

      // Viewport flags & state
      this.currentModel = null;
      this.showDeformation = false;
      this.deformationScale = 50.0;
      this.showBmd = false;
      this.showSfd = false;
      this.animTime = 0.0;

      // Meshes and topology references
      this.nodeMeshes = [];
      this.memberMeshes = [];
      this.supportGlyphs = {};
      this.nodeMap = {}; // nodeId -> THREE.Vector3
      this.baseNodePositions = {}; // nodeId -> THREE.Vector3
      this.memberData = []; // [{ id, iNodeId, jNodeId, mesh, dcr, ... }]

      // Interactive Pointer Raycasting & Dragging
      this.raycaster = new THREE.Raycaster();
      this.mouse = new THREE.Vector2();
      this.isDraggingNode = false;
      this.draggedNodeMesh = null;
      this.dragPlane = new THREE.Plane();
      this.planeIntersect = new THREE.Vector3();
      this.planeNormal = new THREE.Vector3();

      if (this.container) {
        this.init();
      } else {
        this._waitForContainer();
      }
    }

    _waitForContainer() {
      if (this._waitTimer) return;
      let attempts = 0;
      const poll = () => {
        this.container = document.getElementById(this.containerId);
        if (this.container) {
          this._waitTimer = null;
          this.init();
          if (this._pendingModel) {
            this.loadModel(this._pendingModel);
            this._pendingModel = null;
          }
        } else if (attempts++ < 120) {
          this._waitTimer = setTimeout(poll, 30);
        } else {
          this._waitTimer = null;
          console.warn(`[ThreeViewer] Container #${this.containerId} wait timed out.`);
        }
      };
      this._waitTimer = setTimeout(poll, 30);
    }

    init() {
      if (!this.container) {
        this.container = document.getElementById(this.containerId);
      }
      if (!this.container) {
        this._waitForContainer();
        return;
      }
      if (this.scene) {
        return; // already initialized
      }

      const width = this.container.clientWidth || 800;
      const height = this.container.clientHeight || 600;

      // 1. Scene & Camera
      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x0a0e17); // Dark engineering backdrop

      this.camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 1000);
      this.camera.position.set(12, 10, 16);

      // 2. WebGL Renderer
      this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(window.devicePixelRatio || 1);
      this.renderer.shadowMap.enabled = true;
      this.container.innerHTML = "";
      this.container.appendChild(this.renderer.domElement);

      // 3. Lighting
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.70);
      this.scene.add(ambientLight);

      const dirLight1 = new THREE.DirectionalLight(0x00f0ff, 0.90); // Cyan key
      dirLight1.position.set(20, 40, 20);
      this.scene.add(dirLight1);

      const dirLight2 = new THREE.DirectionalLight(0xff007f, 0.45); // Magenta rim
      dirLight2.position.set(-20, -10, -20);
      this.scene.add(dirLight2);

      // 4. Ground Grid & Axes
      const gridHelper = new THREE.GridHelper(30, 30, 0x00e5ff, 0x1f293d);
      gridHelper.position.y = -0.01;
      this.scene.add(gridHelper);

      const axesHelper = new THREE.AxesHelper(3);
      this.scene.add(axesHelper);

      // 5. Orbit Controls (if available)
      if (typeof THREE.OrbitControls !== "undefined") {
        this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.05;
        this.controls.target.set(3, 4, 0);
      }

      // 6. Object Groups
      this.scene.add(this.structureGroup);
      this.scene.add(this.deformationGroup);
      this.scene.add(this.diagramGroup);

      // 7. Event Listeners (Window Resize & Interactive Node Dragging)
      window.addEventListener("resize", () => this.onResize());
      this.setupPointerInteractions();

      // 8. Start Loop
      this.animate = this.animate.bind(this);
      this.animate();
      console.log(`[ThreeViewer] Initialized hardware WebGL viewport for #${this.containerId}`);

      if (this._pendingModel) {
        this.loadModel(this._pendingModel);
        this._pendingModel = null;
      }
    }

    setupPointerInteractions() {
      const dom = this.renderer.domElement;

      dom.addEventListener("pointerdown", (e) => this.onPointerDown(e));
      dom.addEventListener("pointermove", (e) => this.onPointerMove(e));
      dom.addEventListener("pointerup", (e) => this.onPointerUp(e));
      dom.addEventListener("pointercancel", (e) => this.onPointerUp(e));
    }

    updateMouseCoords(e) {
      const rect = this.renderer.domElement.getBoundingClientRect();
      this.mouse.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
      this.mouse.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;
    }

    onPointerDown(e) {
      if (e.button !== 0) return; // Primary button only
      this.updateMouseCoords(e);

      this.raycaster.setFromCamera(this.mouse, this.camera);
      const intersects = this.raycaster.intersectObjects(this.nodeMeshes, false);

      if (intersects.length > 0) {
        const hitMesh = intersects[0].object;
        this.isDraggingNode = true;
        this.draggedNodeMesh = hitMesh;

        if (this.controls) {
          this.controls.enabled = false;
        }

        // Highlight dragged node
        if (hitMesh.material && hitMesh.material.emissive) {
          hitMesh.userData.savedEmissive = hitMesh.material.emissive.getHex();
          hitMesh.material.emissive.setHex(0x00ffff);
          hitMesh.material.emissiveIntensity = 0.8;
        }

        // Setup drag plane perpendicular to camera ray at the node's position
        this.camera.getWorldDirection(this.planeNormal);
        this.planeNormal.negate();
        this.dragPlane.setFromNormalAndCoplanarPoint(this.planeNormal, hitMesh.position);

        this.renderer.domElement.style.cursor = "grabbing";

        // Dispatch start event
        window.dispatchEvent(new CustomEvent("structura-node-drag-start", {
          detail: {
            nodeId: hitMesh.userData.nodeId,
            x: hitMesh.position.x,
            y: hitMesh.position.y,
            z: hitMesh.position.z,
          }
        }));
      }
    }

    onPointerMove(e) {
      this.updateMouseCoords(e);
      this.raycaster.setFromCamera(this.mouse, this.camera);

      if (this.isDraggingNode && this.draggedNodeMesh) {
        if (this.raycaster.ray.intersectPlane(this.dragPlane, this.planeIntersect)) {
          // Snap/round to 2 decimals for engineering precision
          const nx = Math.round(this.planeIntersect.x * 100) / 100;
          const ny = Math.max(0.0, Math.round(this.planeIntersect.y * 100) / 100); // Ground bound
          const nz = Math.round(this.planeIntersect.z * 100) / 100;

          const nodeId = this.draggedNodeMesh.userData.nodeId;
          this.draggedNodeMesh.position.set(nx, ny, nz);

          // Update cached node coordinate
          if (this.nodeMap[nodeId]) {
            this.nodeMap[nodeId].set(nx, ny, nz);
          }

          // Move support glyph if attached
          if (this.supportGlyphs[nodeId]) {
            const glyph = this.supportGlyphs[nodeId];
            glyph.position.set(nx, ny - (glyph.userData.yOffset || 0.15), nz);
          }

          // Morph all incident structural member cylinders in real time (60 FPS)
          this.morphIncidentMembers(nodeId);

          // Dispatch 60 FPS real-time drag event for surrogate streaming
          window.dispatchEvent(new CustomEvent("structura-node-dragged", {
            detail: { nodeId, x: nx, y: ny, z: nz }
          }));
        }
      } else {
        // Hover raycast for visual feedback
        const intersects = this.raycaster.intersectObjects(this.nodeMeshes, false);
        if (intersects.length > 0) {
          this.renderer.domElement.style.cursor = "grab";
        } else {
          this.renderer.domElement.style.cursor = "default";
        }
      }
    }

    onPointerUp(e) {
      if (this.isDraggingNode && this.draggedNodeMesh) {
        const nodeId = this.draggedNodeMesh.userData.nodeId;
        const fx = this.draggedNodeMesh.position.x;
        const fy = this.draggedNodeMesh.position.y;
        const fz = this.draggedNodeMesh.position.z;

        // Restore material emissive
        if (this.draggedNodeMesh.material && this.draggedNodeMesh.material.emissive) {
          const orig = this.draggedNodeMesh.userData.savedEmissive || 0x004455;
          this.draggedNodeMesh.material.emissive.setHex(orig);
          this.draggedNodeMesh.material.emissiveIntensity = 0.3;
        }

        this.isDraggingNode = false;
        this.draggedNodeMesh = null;
        if (this.controls) {
          this.controls.enabled = true;
        }
        this.renderer.domElement.style.cursor = "default";

        // Dispatch pointer release event to trigger deterministic background FEA
        window.dispatchEvent(new CustomEvent("structura-node-drag-end", {
          detail: { nodeId, x: fx, y: fy, z: fz }
        }));
      }
    }

    morphIncidentMembers(nodeId) {
      const p = this.nodeMap[nodeId];
      if (!p) return;

      const upAxis = new THREE.Vector3(0, 1, 0);

      this.memberData.forEach((m) => {
        if (m.iNodeId === nodeId || m.jNodeId === nodeId) {
          const p1 = this.nodeMap[m.iNodeId];
          const p2 = this.nodeMap[m.jNodeId];
          if (!p1 || !p2) return;

          const distance = p1.distanceTo(p2);
          if (distance < 0.05) return;

          // Midpoint position
          const mid = new THREE.Vector3().addVectors(p1, p2).multiplyScalar(0.5);
          m.mesh.position.copy(mid);

          // Orientation toward p2
          const dir = new THREE.Vector3().subVectors(p2, p1).normalize();
          m.mesh.quaternion.setFromUnitVectors(upAxis, dir);

          // Scale along length (Y-axis of cylinder)
          const scaleY = distance / m.initialLength;
          m.mesh.scale.set(1.0, scaleY, 1.0);
        }
      });
    }

    onResize() {
      if (!this.container || !this.renderer || !this.camera) return;
      const width = this.container.clientWidth;
      const height = this.container.clientHeight;
      if (width === 0 || height === 0) return;

      this.camera.aspect = width / height;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(width, height);
    }

    animate() {
      this.animId = requestAnimationFrame(this.animate);
      this.animTime += 0.035;

      if (this.controls) {
        this.controls.update();
      }

      // Animate deformation vibration if active
      if (this.showDeformation && this.deformationGroup.children.length > 0) {
        const osc = Math.sin(this.animTime);
        this.deformationGroup.children.forEach((mesh) => {
          if (mesh.userData && mesh.userData.originalGeometry && mesh.userData.dispVector) {
            const v = mesh.userData.dispVector;
            mesh.position.set(
              mesh.userData.basePos.x + v.x * osc * this.deformationScale,
              mesh.userData.basePos.y + v.y * osc * this.deformationScale,
              mesh.userData.basePos.z + v.z * osc * this.deformationScale
            );
          }
        });
      }

      this.renderer.render(this.scene, this.camera);
    }

    loadModel(model) {
      if (!model) return;
      this.currentModel = model;

      if (!this.scene) {
        if (!this.container) {
          this.container = document.getElementById(this.containerId);
        }
        if (this.container) {
          this.init();
        }
      }

      if (!this.scene || !this.structureGroup) {
        this._pendingModel = model;
        this._waitForContainer();
        return;
      }

      // Clear existing
      while (this.structureGroup.children.length > 0) {
        const obj = this.structureGroup.children[0];
        this.structureGroup.remove(obj);
        if (obj.geometry) obj.geometry.dispose();
      }
      while (this.deformationGroup.children.length > 0) {
        const obj = this.deformationGroup.children[0];
        this.deformationGroup.remove(obj);
      }
      while (this.diagramGroup.children.length > 0) {
        const obj = this.diagramGroup.children[0];
        this.diagramGroup.remove(obj);
      }

      this.nodeMeshes = [];
      this.memberMeshes = [];
      this.supportGlyphs = {};
      this.nodeMap = {};
      this.baseNodePositions = {};
      this.memberData = [];

      const nodes = model.nodes || [];
      const members = model.members || [];

      // 1. Render Nodes
      const nodeGeo = new THREE.SphereGeometry(0.14, 16, 16);
      const nodeMat = new THREE.MeshStandardMaterial({
        color: 0x00ffff,
        metalness: 0.8,
        roughness: 0.2,
        emissive: 0x004455,
        emissiveIntensity: 0.3,
      });

      const fixedBoxGeo = new THREE.BoxGeometry(0.35, 0.18, 0.35);
      const fixedBoxMat = new THREE.MeshStandardMaterial({ color: 0x3b82f6, metalness: 0.7 });

      const pinnedConeGeo = new THREE.ConeGeometry(0.22, 0.35, 16);
      const pinnedConeMat = new THREE.MeshStandardMaterial({ color: 0xf59e0b, metalness: 0.7 });

      nodes.forEach((n) => {
        const x = n.x ?? (n.coords ? n.coords[0] : 0.0);
        const y = n.y ?? (n.coords ? n.coords[1] : 0.0);
        const z = n.z ?? (n.coords ? n.coords[2] : 0.0);
        this.nodeMap[n.id] = new THREE.Vector3(x, y, z);
        this.baseNodePositions[n.id] = new THREE.Vector3(x, y, z);

        const nodeMesh = new THREE.Mesh(nodeGeo.clone(), nodeMat.clone());
        nodeMesh.position.set(x, y, z);
        nodeMesh.userData = { nodeId: n.id, isRestrained: false };

        this.structureGroup.add(nodeMesh);
        this.nodeMeshes.push(nodeMesh);

        // Boundary support glyphs
        const isRestrained = n.isRestrained || (n.restraint && n.restraint.some((r) => r === 1));
        if (isRestrained) {
          nodeMesh.userData.isRestrained = true;
          const isFixed = n.restraint && n.restraint.slice(0, 3).every((r) => r === 1);
          if (isFixed) {
            const fixMesh = new THREE.Mesh(fixedBoxGeo, fixedBoxMat);
            fixMesh.position.set(x, y - 0.12, z);
            fixMesh.userData = { yOffset: 0.12 };
            this.structureGroup.add(fixMesh);
            this.supportGlyphs[n.id] = fixMesh;
          } else {
            const pinMesh = new THREE.Mesh(pinnedConeGeo, pinnedConeMat);
            pinMesh.position.set(x, y - 0.18, z);
            pinMesh.userData = { yOffset: 0.18 };
            this.structureGroup.add(pinMesh);
            this.supportGlyphs[n.id] = pinMesh;
          }
        }
      });

      // 2. Render Members
      members.forEach((m) => {
        const iId = m.iNodeId || m.i_node;
        const jId = m.jNodeId || m.j_node;
        const p1 = this.nodeMap[iId];
        const p2 = this.nodeMap[jId];
        if (!p1 || !p2) return;

        const distance = Math.max(p1.distanceTo(p2), 0.05);
        const dcr = m.governingDcr ?? m.governing_dcr ?? 0.65;

        // DCR color coding (Green -> Amber -> Red)
        let memberColor = 0x10b981; // Safe green
        if (dcr > 1.0) {
          memberColor = 0xef4444; // Critical overstressed red
        } else if (dcr >= 0.85) {
          memberColor = 0xf59e0b; // Warning amber
        } else if (dcr >= 0.65) {
          memberColor = 0x3b82f6; // Optimal blue
        }

        const cylGeo = new THREE.CylinderGeometry(0.08, 0.08, distance, 16);
        const cylMat = new THREE.MeshStandardMaterial({
          color: memberColor,
          metalness: 0.85,
          roughness: 0.25,
          emissive: memberColor,
          emissiveIntensity: dcr > 1.0 ? 0.35 : 0.08,
        });

        const cylMesh = new THREE.Mesh(cylGeo, cylMat);

        // Position cylinder at midpoint and rotate toward p2
        const mid = new THREE.Vector3().addVectors(p1, p2).multiplyScalar(0.5);
        cylMesh.position.copy(mid);

        const dir = new THREE.Vector3().subVectors(p2, p1).normalize();
        const axis = new THREE.Vector3(0, 1, 0);
        cylMesh.quaternion.setFromUnitVectors(axis, dir);

        this.structureGroup.add(cylMesh);
        this.memberMeshes.push(cylMesh);

        this.memberData.push({
          id: m.id,
          iNodeId: iId,
          jNodeId: jId,
          mesh: cylMesh,
          initialLength: distance,
          dcr: dcr,
        });

        // 3. Optional Extruded BMD (Bending Moment Diagram) Ribbon
        this.createBmdRibbon(p1, p2, dir, dcr);
      });

      // Center camera focus on bounding center
      if (nodes.length > 0) {
        let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity, minZ = Infinity, maxZ = -Infinity;
        nodes.forEach((n) => {
          const x = n.x ?? (n.coords ? n.coords[0] : 0.0);
          const y = n.y ?? (n.coords ? n.coords[1] : 0.0);
          const z = n.z ?? (n.coords ? n.coords[2] : 0.0);
          minX = Math.min(minX, x); maxX = Math.max(maxX, x);
          minY = Math.min(minY, y); maxY = Math.max(maxY, y);
          minZ = Math.min(minZ, z); maxZ = Math.max(maxZ, z);
        });

        const cx = (minX + maxX) / 2;
        const cy = (minY + maxY) / 2;
        const cz = (minZ + maxZ) / 2;
        if (this.controls) {
          this.controls.target.set(cx, cy, cz);
        }
      }
    }

    /**
     * Morph the structural mesh in real time using surrogate 6-DOF predicted displacements.
     * @param {Object} displacements - Map of nodeId -> { dx, dy, dz, rx, ry, rz }
     */
    updatePredictedDisplacements(displacements) {
      if (!displacements) return;

      const scale = this.deformationScale || 50.0;
      const upAxis = new THREE.Vector3(0, 1, 0);

      // 1. Displace nodes
      this.nodeMeshes.forEach((mesh) => {
        const nodeId = mesh.userData.nodeId;
        const base = this.baseNodePositions[nodeId];
        const disp = displacements[nodeId];

        if (base && disp) {
          const dx = (disp.dx || 0.0) * scale;
          const dy = (disp.dy || 0.0) * scale;
          const dz = (disp.dz || 0.0) * scale;

          mesh.position.set(base.x + dx, base.y + dy, base.z + dz);
          if (this.nodeMap[nodeId]) {
            this.nodeMap[nodeId].set(base.x + dx, base.y + dy, base.z + dz);
          }
        }
      });

      // 2. Morph member cylinders to span between displaced nodes
      this.memberData.forEach((m) => {
        const p1 = this.nodeMap[m.iNodeId];
        const p2 = this.nodeMap[m.jNodeId];
        if (!p1 || !p2) return;

        const distance = p1.distanceTo(p2);
        if (distance < 0.05) return;

        const mid = new THREE.Vector3().addVectors(p1, p2).multiplyScalar(0.5);
        m.mesh.position.copy(mid);

        const dir = new THREE.Vector3().subVectors(p2, p1).normalize();
        m.mesh.quaternion.setFromUnitVectors(upAxis, dir);

        const scaleY = distance / m.initialLength;
        m.mesh.scale.set(1.0, scaleY, 1.0);
      });
    }

    createBmdRibbon(p1, p2, dir, dcr) {
      const segments = 10;
      const normal = new THREE.Vector3(-dir.y, dir.x, 0).normalize();
      if (normal.length() < 0.1) normal.set(0, 0, 1);

      const maxOffset = Math.min(0.6, 0.15 + dcr * 0.3);
      const points = [];

      for (let s = 0; s <= segments; s++) {
        const t = s / segments;
        const ptOnAxis = new THREE.Vector3().lerpVectors(p1, p2, t);
        const parabola = 4.0 * t * (1.0 - t);
        const ptOffset = new THREE.Vector3().copy(ptOnAxis).addScaledVector(normal, parabola * maxOffset);
        points.push(ptOffset);
      }

      const curve = new THREE.CatmullRomCurve3(points);
      const tubeGeo = new THREE.TubeGeometry(curve, 16, 0.025, 8, false);
      const bmdMat = new THREE.MeshBasicMaterial({
        color: 0xec4899,
        wireframe: false,
        transparent: true,
        opacity: 0.85,
      });

      const bmdMesh = new THREE.Mesh(tubeGeo, bmdMat);
      bmdMesh.visible = this.showBmd;
      this.diagramGroup.add(bmdMesh);
    }

    setDeformationMode(enabled, scale = 50.0) {
      this.showDeformation = enabled;
      this.deformationScale = scale;
    }

    setBmdVisible(visible) {
      this.showBmd = visible;
      this.diagramGroup.children.forEach((c) => (c.visible = visible));
    }

    setStressOverlay(visible) {
      this.memberMeshes.forEach((mesh) => {
        mesh.material.emissiveIntensity = visible ? 0.35 : 0.05;
      });
    }

    setCameraPreset(preset) {
      if (!this.camera) return;
      const target = this.controls ? this.controls.target : new THREE.Vector3(3, 4, 0);
      switch (preset) {
        case 'TOP':
          this.camera.position.set(target.x, target.y + 24, target.z + 0.001);
          break;
        case 'FRONT':
          this.camera.position.set(target.x, target.y, target.z + 24);
          break;
        case 'ISO':
        case 'RECENTER':
        default:
          this.camera.position.set(target.x + 9, target.y + 7, target.z + 14);
          break;
      }
      if (this.controls) this.controls.update();
    }

    zoomIn() {
      if (!this.camera) return;
      const target = this.controls ? this.controls.target : new THREE.Vector3(3, 4, 0);
      const offset = new THREE.Vector3().subVectors(this.camera.position, target);
      offset.multiplyScalar(0.85);
      this.camera.position.copy(target).add(offset);
      if (this.controls) this.controls.update();
    }

    zoomOut() {
      if (!this.camera) return;
      const target = this.controls ? this.controls.target : new THREE.Vector3(3, 4, 0);
      const offset = new THREE.Vector3().subVectors(this.camera.position, target);
      offset.multiplyScalar(1.18);
      this.camera.position.copy(target).add(offset);
      if (this.controls) this.controls.update();
    }

    dispose() {
      if (this.animId) cancelAnimationFrame(this.animId);
      if (this.renderer && this.renderer.domElement) {
        this.renderer.domElement.remove();
      }
      this.scene = null;
      this.camera = null;
      this.renderer = null;
    }
  }

  // Expose global viewer factory
  window.StructuraThreeViewer = StructuraThreeViewer;
  window.initStructuraThreeViewer = function (containerId) {
    if (!window.__structuraViewerInstances) {
      window.__structuraViewerInstances = {};
    }
    const cId = typeof containerId === "string" ? containerId : "structura-three-container";
    if (window.__structuraViewerInstances[cId] && window.__structuraViewerInstances[cId].scene) {
      return window.__structuraViewerInstances[cId];
    }
    const viewer = new StructuraThreeViewer(containerId);
    window.__structuraViewerInstances[cId] = viewer;
    return viewer;
  };
})();
