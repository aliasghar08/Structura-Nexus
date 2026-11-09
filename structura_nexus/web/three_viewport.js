/**
 * Structura Nexus: High-Performance Hardware-Accelerated Three.js WebGL Engine
 * Multi-story space frame rendering, extruded BMD/SFD ribbons, deformation magnification,
 * real-time pointer raycasting, node drag-and-morph, and 60 FPS surrogate streaming.
 */

(function () {
  class StructuraThreeViewer {
    constructor(containerId) {
      this.containerId =
        typeof containerId === "string"
          ? containerId
          : (containerId && containerId.id) || "structura-three-container";
      this.container =
        typeof containerId === "string"
          ? document.getElementById(containerId)
          : containerId instanceof HTMLElement
          ? containerId
          : document.getElementById(this.containerId);
      this.scene = null;
      this.camera = null;
      this.renderer = null;
      this.controls = null;
      this.gridHelper = null;
      this.axesHelper = null;
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
      this.lastRenderedRevision = -1;

      // Meshes and topology references
      this.nodeMeshes = [];
      this.memberMeshes = [];
      this.supportGlyphs = {};
      this.nodeMap = {}; // nodeId -> THREE.Vector3
      this.baseNodePositions = {}; // nodeId -> THREE.Vector3
      this.nodeDisplacements = {}; // nodeId -> THREE.Vector3
      this.memberData = []; // [{ id, iNodeId, jNodeId, mesh, dcr, ... }]

      // Interactive Pointer Raycasting & Dragging
      this.raycaster = new THREE.Raycaster();
      this.mouse = new THREE.Vector2();
      this.pointerDownPos = new THREE.Vector2();
      this.isDraggingNode = false;
      this.dragMoved = false;
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
        const el = document.getElementById(this.containerId);
        if (el) {
          this.container = el;
          this._waitTimer = null;
          this.init();
          if (this._pendingModel) {
            const pending = this._pendingModel;
            this._pendingModel = null;
            this.loadModel(pending);
          }
        } else if (attempts++ < 200) {
          this._waitTimer = setTimeout(poll, 30);
        } else {
          this._waitTimer = null;
          console.warn(`[ThreeViewer] Container #${this.containerId} wait timed out.`);
        }
      };
      this._waitTimer = setTimeout(poll, 30);
    }

    ensureMounted() {
      const liveEl = document.getElementById(this.containerId);
      if (liveEl && this.container !== liveEl) {
        this.container = liveEl;
      }
      if (!this.container) return false;

      if (!this.scene || !this.renderer) {
        this.init();
        return !!this.scene;
      }

      if (this.renderer.domElement.parentNode !== this.container) {
        this.container.innerHTML = "";
        this.container.appendChild(this.renderer.domElement);
        this.onResize();
      }
      return true;
    }

    init() {
      const liveEl = document.getElementById(this.containerId);
      if (liveEl) {
        this.container = liveEl;
      }
      if (!this.container) {
        this._waitForContainer();
        return;
      }
      if (this.scene && this.renderer) {
        if (this.renderer.domElement.parentNode !== this.container) {
          this.container.innerHTML = "";
          this.container.appendChild(this.renderer.domElement);
          this.onResize();
        }
        return;
      }

      const width = this.container.clientWidth || window.innerWidth || 1280;
      const height = this.container.clientHeight || window.innerHeight || 720;

      // 1. Scene & Camera
      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x0a0e17); // Dark engineering backdrop

      this.camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 2500);
      this.camera.position.set(12, 10, 16);

      // 2. WebGL Renderer (preserveDrawingBuffer ensures crisp screenshots & canvas inspection)
      this.renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: true,
        preserveDrawingBuffer: true,
      });
      this.renderer.setSize(width, height);
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
      this.renderer.shadowMap.enabled = true;
      this.container.innerHTML = "";
      this.container.appendChild(this.renderer.domElement);

      // 3. Lighting
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.75);
      this.scene.add(ambientLight);

      const dirLight1 = new THREE.DirectionalLight(0x00f0ff, 0.95); // Cyan key
      dirLight1.position.set(30, 60, 30);
      this.scene.add(dirLight1);

      const dirLight2 = new THREE.DirectionalLight(0xff007f, 0.45); // Magenta rim
      dirLight2.position.set(-30, -15, -30);
      this.scene.add(dirLight2);

      // 4. Ground Grid & Axes
      this.gridHelper = new THREE.GridHelper(60, 60, 0x00e5ff, 0x1f293d);
      this.gridHelper.position.y = -0.01;
      this.scene.add(this.gridHelper);

      this.axesHelper = new THREE.AxesHelper(4);
      this.scene.add(this.axesHelper);

      // 5. Orbit Controls (if available)
      if (typeof THREE.OrbitControls !== "undefined") {
        this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.08;
        this.controls.target.set(3, 4, 0);

        // Freeze controls when pointer is hovering/scrolling over UI menus, toolbars or side panels
        window.addEventListener("structura-freeze-orbit", () => {
          window.__structuraMenuHovered = true;
          if (this.controls) this.controls.enabled = false;
        });
        window.addEventListener("structura-unfreeze-orbit", () => {
          window.__structuraMenuHovered = false;
          if (this.controls) this.controls.enabled = true;
        });

        // Prevent OrbitControls on the Three.js canvas from zooming when hovering over UI menus,
        // without blocking wheel events on <flutter-view> / <flt-glass-pane>
        this.renderer.domElement.addEventListener(
          "wheel",
          (e) => {
            if (window.__structuraMenuHovered) {
              e.stopImmediatePropagation();
            }
          },
          { capture: true, passive: true }
        );
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
        const pending = this._pendingModel;
        this._pendingModel = null;
        this.loadModel(pending);
      }
    }

    setupPointerInteractions() {
      const dom = this.renderer.domElement;

      dom.addEventListener("pointerdown", (e) => {
        if (window.__structuraMenuHovered) {
          window.__structuraMenuHovered = false;
          if (this.controls && !this.isDraggingNode) this.controls.enabled = true;
        }
        this.onPointerDown(e);
      });
      dom.addEventListener("pointermove", (e) => {
        if (window.__structuraMenuHovered && e.target === dom) {
          window.__structuraMenuHovered = false;
          if (this.controls && !this.isDraggingNode) this.controls.enabled = true;
        }
        this.onPointerMove(e);
      });
      dom.addEventListener("pointerup", (e) => this.onPointerUp(e));
      dom.addEventListener("pointercancel", (e) => this.onPointerUp(e));

      // Fallback when Flutter accessibility semantics overlay (<flt-semantics>) is active in Chrome
      window.addEventListener("pointerdown", (e) => {
        if (e.target === dom || window.__structuraMenuHovered) return;
        const y = e.clientY;
        const x = e.clientX;
        if (y > 115 && y < window.innerHeight - 135 && x > 315 && x < window.innerWidth - 365) {
          this.onPointerDown(e);
        }
      });
    }

    updateMouseCoords(e) {
      const rect = this.renderer.domElement.getBoundingClientRect();
      this.mouse.x = ((e.clientX - rect.left) / Math.max(rect.width, 1)) * 2 - 1;
      this.mouse.y = -((e.clientY - rect.top) / Math.max(rect.height, 1)) * 2 + 1;
    }

    onPointerDown(e) {
      if (e.button !== 0 || window.__structuraMenuHovered) return;
      this.pointerDownPos.set(e.clientX, e.clientY);
      this.dragMoved = false;
      this.updateMouseCoords(e);

      this.raycaster.setFromCamera(this.mouse, this.camera);
      const nodeHits = this.raycaster.intersectObjects(this.nodeMeshes, false);

      if (nodeHits.length > 0) {
        const hitMesh = nodeHits[0].object;
        this.isDraggingNode = true;
        this.draggedNodeMesh = hitMesh;

        if (this.controls) {
          this.controls.enabled = false;
        }

        // Highlight dragged/selected node
        if (hitMesh.material && hitMesh.material.emissive) {
          hitMesh.userData.savedEmissive = hitMesh.material.emissive.getHex();
          hitMesh.material.emissive.setHex(0x00ffff);
          hitMesh.material.emissiveIntensity = 0.85;
        }

        // Setup drag plane perpendicular to camera ray at the node's position
        this.camera.getWorldDirection(this.planeNormal);
        this.planeNormal.negate();
        this.dragPlane.setFromNormalAndCoplanarPoint(this.planeNormal, hitMesh.position);

        this.renderer.domElement.style.cursor = "grabbing";

        // Dispatch selection & start event
        window.dispatchEvent(
          new CustomEvent("structura-node-selected", {
            detail: { nodeId: hitMesh.userData.nodeId },
          })
        );
        window.dispatchEvent(
          new CustomEvent("structura-node-drag-start", {
            detail: {
              nodeId: hitMesh.userData.nodeId,
              x: hitMesh.position.x,
              y: hitMesh.position.y,
              z: hitMesh.position.z,
            },
          })
        );
      } else {
        // Check if a member cylinder was clicked
        const memberHits = this.raycaster.intersectObjects(this.memberMeshes, false);
        if (memberHits.length > 0) {
          const hitMem = memberHits[0].object;
          if (hitMem.userData && hitMem.userData.memberId) {
            window.dispatchEvent(
              new CustomEvent("structura-member-selected", {
                detail: { memberId: hitMem.userData.memberId },
              })
            );
          }
        }
      }
    }

    onPointerMove(e) {
      if (window.__structuraMenuHovered) return;
      this.updateMouseCoords(e);
      this.raycaster.setFromCamera(this.mouse, this.camera);

      if (this.isDraggingNode && this.draggedNodeMesh) {
        const moveDist = Math.hypot(
          e.clientX - this.pointerDownPos.x,
          e.clientY - this.pointerDownPos.y
        );
        if (moveDist > 3) {
          this.dragMoved = true;
        }
        if (this.raycaster.ray.intersectPlane(this.dragPlane, this.planeIntersect)) {
          // Snap/round to 2 decimals for engineering precision
          const nx = Math.round(this.planeIntersect.x * 100) / 100;
          const ny = Math.max(0.0, Math.round(this.planeIntersect.y * 100) / 100);
          const nz = Math.round(this.planeIntersect.z * 100) / 100;

          const nodeId = this.draggedNodeMesh.userData.nodeId;
          this.draggedNodeMesh.position.set(nx, ny, nz);

          if (this.nodeMap[nodeId]) {
            this.nodeMap[nodeId].set(nx, ny, nz);
          }
          if (this.baseNodePositions[nodeId]) {
            this.baseNodePositions[nodeId].set(nx, ny, nz);
          }

          if (this.supportGlyphs[nodeId]) {
            const glyph = this.supportGlyphs[nodeId];
            glyph.position.set(nx, ny - (glyph.userData.yOffset || 0.15), nz);
          }

          this.morphIncidentMembers(nodeId);

          window.dispatchEvent(
            new CustomEvent("structura-node-dragged", {
              detail: { nodeId, x: nx, y: ny, z: nz },
            })
          );
        }
      } else {
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

        if (this.draggedNodeMesh.material && this.draggedNodeMesh.material.emissive) {
          const orig = this.draggedNodeMesh.userData.savedEmissive || 0x004455;
          this.draggedNodeMesh.material.emissive.setHex(orig);
          this.draggedNodeMesh.material.emissiveIntensity = 0.3;
        }

        this.isDraggingNode = false;
        this.draggedNodeMesh = null;
        if (this.controls && !window.__structuraMenuHovered) {
          this.controls.enabled = true;
        }
        this.renderer.domElement.style.cursor = "default";

        if (this.dragMoved) {
          window.dispatchEvent(
            new CustomEvent("structura-node-drag-end", {
              detail: { nodeId, x: fx, y: fy, z: fz },
            })
          );
        }
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

          const mid = new THREE.Vector3().addVectors(p1, p2).multiplyScalar(0.5);
          m.mesh.position.copy(mid);

          const dir = new THREE.Vector3().subVectors(p2, p1).normalize();
          m.mesh.quaternion.setFromUnitVectors(upAxis, dir);

          const scaleY = distance / m.initialLength;
          m.mesh.scale.set(1.0, scaleY, 1.0);
        }
      });
    }

    onResize() {
      if (!this.container || !this.renderer || !this.camera) return;
      const width = this.container.clientWidth || window.innerWidth;
      const height = this.container.clientHeight || window.innerHeight;
      if (width === 0 || height === 0) return;

      this.camera.aspect = width / height;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(width, height);
    }

    animate() {
      this.animId = requestAnimationFrame(this.animate);
      this.animTime += 0.035;

      // Ensure our WebGL canvas is always mounted in the live DOM container
      const liveEl = document.getElementById(this.containerId);
      if (liveEl && this.renderer && this.renderer.domElement.parentNode !== liveEl) {
        this.container = liveEl;
        this.container.innerHTML = "";
        this.container.appendChild(this.renderer.domElement);
        this.onResize();
      }

      if (this.controls) {
        this.controls.update();
      }

      if (this.renderer && this.scene && this.camera) {
        this.renderer.render(this.scene, this.camera);
      }
    }

    loadModel(model) {
      if (!model) return;
      this.currentModel = model;

      if (!this.ensureMounted()) {
        this._pendingModel = model;
        this._waitForContainer();
        return;
      }

      // Clear existing meshes cleanly
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
      this.nodeDisplacements = {};
      this.memberData = [];

      const nodes = model.nodes || [];
      const members = model.members || [];

      // Compute bounding box first so we can scale node/member thicknesses & ground grid nicely
      let minX = Infinity,
        maxX = -Infinity,
        minY = Infinity,
        maxY = -Infinity,
        minZ = Infinity,
        maxZ = -Infinity;
      nodes.forEach((n) => {
        const x = n.x ?? (n.coords ? n.coords[0] : 0.0);
        const y = n.y ?? (n.coords ? n.coords[1] : 0.0);
        const z = n.z ?? (n.coords ? n.coords[2] : 0.0);
        minX = Math.min(minX, x);
        maxX = Math.max(maxX, x);
        minY = Math.min(minY, y);
        maxY = Math.max(maxY, y);
        minZ = Math.min(minZ, z);
        maxZ = Math.max(maxZ, z);
      });

      const cx = nodes.length > 0 ? (minX + maxX) / 2 : 3.0;
      const cy = nodes.length > 0 ? (minY + maxY) / 2 : 3.6;
      const cz = nodes.length > 0 ? (minZ + maxZ) / 2 : 3.0;
      const spanX = nodes.length > 0 ? Math.max(maxX - minX, 1.0) : 6.0;
      const spanY = nodes.length > 0 ? Math.max(maxY - minY, 1.0) : 7.2;
      const spanZ = nodes.length > 0 ? Math.max(maxZ - minZ, 1.0) : 6.0;
      const maxDim = Math.max(spanX, spanY, spanZ, 6.0);

      // Update Ground Grid to center beneath the structure
      if (this.gridHelper) {
        this.scene.remove(this.gridHelper);
        const gridSpan = Math.max(Math.ceil(Math.max(spanX, spanZ) * 2.2 / 10) * 10, 40);
        const divisions = Math.min(Math.max(Math.round(gridSpan / 2), 20), 80);
        this.gridHelper = new THREE.GridHelper(gridSpan, divisions, 0x00e5ff, 0x1f293d);
        this.gridHelper.position.set(cx, -0.02, cz);
        this.scene.add(this.gridHelper);
      }

      const geomScale = Math.max(1.0, Math.min(maxDim / 18.0, 2.2));

      // 1. Render Nodes
      const nodeGeo = new THREE.SphereGeometry(0.14 * geomScale, 14, 14);
      const nodeMat = new THREE.MeshStandardMaterial({
        color: 0x00ffff,
        metalness: 0.8,
        roughness: 0.2,
        emissive: 0x004455,
        emissiveIntensity: 0.35,
      });

      const fixedBoxGeo = new THREE.BoxGeometry(0.36 * geomScale, 0.18 * geomScale, 0.36 * geomScale);
      const fixedBoxMat = new THREE.MeshStandardMaterial({ color: 0x3b82f6, metalness: 0.7 });

      const pinnedConeGeo = new THREE.ConeGeometry(0.24 * geomScale, 0.36 * geomScale, 14);
      const pinnedConeMat = new THREE.MeshStandardMaterial({ color: 0xf59e0b, metalness: 0.7 });

      const connectedNodeIds = new Set();
      members.forEach((m) => {
        connectedNodeIds.add(m.i || m.i_node || m.iNodeId);
        connectedNodeIds.add(m.j || m.j_node || m.jNodeId);
      });

      const standaloneGeo = new THREE.SphereGeometry(0.24 * geomScale, 16, 16);
      const standaloneMat = new THREE.MeshStandardMaterial({
        color: 0x00ffff,
        metalness: 0.4,
        roughness: 0.15,
        emissive: 0x00f0ff,
        emissiveIntensity: 0.9,
      });

      nodes.forEach((n) => {
        const x = n.x ?? (n.coords ? n.coords[0] : 0.0);
        const y = n.y ?? (n.coords ? n.coords[1] : 0.0);
        const z = n.z ?? (n.coords ? n.coords[2] : 0.0);
        this.nodeMap[n.id] = new THREE.Vector3(x, y, z);
        this.baseNodePositions[n.id] = new THREE.Vector3(x, y, z);

        const dispArr = n.displacements || [0, 0, 0, 0, 0, 0];
        this.nodeDisplacements[n.id] = new THREE.Vector3(
          dispArr[0] || 0.0,
          dispArr[1] || 0.0,
          dispArr[2] || 0.0
        );

        const isStandalone = !connectedNodeIds.has(n.id);
        const nodeMesh = new THREE.Mesh(
          (isStandalone ? standaloneGeo : nodeGeo).clone(),
          (isStandalone ? standaloneMat : nodeMat).clone()
        );
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
            const yOff = 0.12 * geomScale;
            fixMesh.position.set(x, y - yOff, z);
            fixMesh.userData = { yOffset: yOff };
            this.structureGroup.add(fixMesh);
            this.supportGlyphs[n.id] = fixMesh;
          } else {
            const pinMesh = new THREE.Mesh(pinnedConeGeo, pinnedConeMat);
            const yOff = 0.18 * geomScale;
            pinMesh.position.set(x, y - yOff, z);
            pinMesh.userData = { yOffset: yOff };
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
        const dcr = m.governingDcr ?? m.governing_dcr ?? 0.45;

        // DCR color coding (Green -> Blue -> Amber -> Red)
        let memberColor = 0x3b82f6; // Standard engineering steel blue
        if (dcr > 1.0) {
          memberColor = 0xef4444; // Critical overstressed red
        } else if (dcr >= 0.85) {
          memberColor = 0xf59e0b; // Warning amber
        } else if (dcr >= 0.45) {
          memberColor = 0x38bdf8; // Active sky-cyan
        } else {
          memberColor = 0x10b981; // Low-stress emerald
        }

        const radius = 0.08 * geomScale;
        const cylGeo = new THREE.CylinderGeometry(radius, radius, distance, 12);
        const cylMat = new THREE.MeshStandardMaterial({
          color: memberColor,
          metalness: 0.82,
          roughness: 0.25,
          emissive: memberColor,
          emissiveIntensity: dcr > 1.0 ? 0.4 : 0.12,
        });

        const cylMesh = new THREE.Mesh(cylGeo, cylMat);
        cylMesh.userData = { memberId: m.id };

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
        this.createBmdRibbon(p1, p2, dir, dcr, geomScale);
      });

      // Center camera focus on bounding center & auto-frame the structure
      if (nodes.length > 0) {
        this.currentCenter = new THREE.Vector3(cx, cy, cz);
        this.currentMaxDim = maxDim;

        const fovRad = ((this.camera && this.camera.fov ? this.camera.fov : 45) * Math.PI) / 180;
        const fitDistance = Math.max(((maxDim / 2) / Math.tan(fovRad / 2)) * 1.65, 13.0);
        this.fitDistance = fitDistance;

        if (this.controls) {
          this.controls.target.set(cx, cy, cz);
        }

        if (this.camera) {
          this.camera.position.set(
            cx + fitDistance * 0.72,
            cy + fitDistance * 0.52,
            cz + fitDistance * 0.82
          );
          this.camera.lookAt(cx, cy, cz);
        }

        if (this.controls) {
          this.controls.update();
        }
      }

      if (this.showDeformation) {
        this._applyDeformationState();
      }

      console.log(
        `[ThreeViewer] Rendered model "${model.session_id || "workspace"}": ${this.nodeMeshes.length} joints, ${this.memberMeshes.length} members`
      );
    }

    _applyDeformationState() {
      const scale = this.showDeformation ? this.deformationScale || 50.0 : 0.0;
      const upAxis = new THREE.Vector3(0, 1, 0);

      this.nodeMeshes.forEach((mesh) => {
        const nodeId = mesh.userData.nodeId;
        const base = this.baseNodePositions[nodeId];
        const disp = this.nodeDisplacements[nodeId];
        if (base) {
          const dx = disp ? disp.x * scale : 0.0;
          const dy = disp ? disp.y * scale : 0.0;
          const dz = disp ? disp.z * scale : 0.0;
          mesh.position.set(base.x + dx, base.y + dy, base.z + dz);
          if (this.nodeMap[nodeId]) {
            this.nodeMap[nodeId].set(base.x + dx, base.y + dy, base.z + dz);
          }
        }
      });

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

    /**
     * Morph the structural mesh in real time using surrogate 6-DOF predicted displacements.
     * @param {Object} displacements - Map of nodeId -> { dx, dy, dz, rx, ry, rz }
     */
    updatePredictedDisplacements(displacements) {
      if (!displacements) return;

      const scale = this.deformationScale || 50.0;
      const upAxis = new THREE.Vector3(0, 1, 0);

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

    createBmdRibbon(p1, p2, dir, dcr, geomScale = 1.0) {
      const segments = 12;
      const normal = new THREE.Vector3(-dir.y, dir.x, 0).normalize();
      if (normal.length() < 0.1) normal.set(0, 0, 1);

      const maxOffset = Math.min(0.95 * geomScale, Math.max(0.42 * geomScale, (0.28 + dcr * 0.45) * geomScale));
      const points = [];

      for (let s = 0; s <= segments; s++) {
        const t = s / segments;
        const ptOnAxis = new THREE.Vector3().lerpVectors(p1, p2, t);
        const parabola = 4.0 * t * (1.0 - t);
        const ptOffset = new THREE.Vector3()
          .copy(ptOnAxis)
          .addScaledVector(normal, parabola * maxOffset);
        points.push(ptOffset);
      }

      const curve = new THREE.CatmullRomCurve3(points);
      const tubeGeo = new THREE.TubeGeometry(curve, 16, 0.05 * geomScale, 8, false);
      const bmdMat = new THREE.MeshBasicMaterial({
        color: 0xff007f,
        wireframe: false,
        transparent: true,
        opacity: 0.92,
      });

      const bmdMesh = new THREE.Mesh(tubeGeo, bmdMat);
      bmdMesh.visible = this.showBmd;
      this.diagramGroup.add(bmdMesh);
    }

    setDeformationMode(enabled, scale = 50.0) {
      const changed = this.showDeformation !== enabled || this.deformationScale !== scale;
      this.showDeformation = enabled;
      this.deformationScale = scale;
      if (changed) {
        this._applyDeformationState();
      }
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
      const target =
        this.currentCenter ||
        (this.controls ? this.controls.target : new THREE.Vector3(3, 4, 0));
      const dist = this.fitDistance || 18.0;
      switch (preset) {
        case "TOP":
          this.camera.position.set(target.x, target.y + dist * 1.4, target.z + 0.001);
          break;
        case "FRONT":
          this.camera.position.set(target.x, target.y, target.z + dist * 1.4);
          break;
        case "ISO":
        case "RECENTER":
        default:
          this.camera.position.set(
            target.x + dist * 0.72,
            target.y + dist * 0.52,
            target.z + dist * 0.82
          );
          break;
      }
      this.camera.lookAt(target);
      if (this.controls) {
        this.controls.target.copy(target);
        this.controls.update();
      }
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

  // Expose global singleton viewer factory (never creates duplicate instances for the same containerId)
  window.StructuraThreeViewer = StructuraThreeViewer;
  window.initStructuraThreeViewer = function (containerId) {
    if (!window.__structuraViewerInstances) {
      window.__structuraViewerInstances = {};
    }
    const cId = typeof containerId === "string" ? containerId : "structura-three-container";
    if (window.__structuraViewerInstances[cId]) {
      const existing = window.__structuraViewerInstances[cId];
      existing.ensureMounted();
      return existing;
    }
    const viewer = new StructuraThreeViewer(cId);
    window.__structuraViewerInstances[cId] = viewer;
    return viewer;
  };
})();
