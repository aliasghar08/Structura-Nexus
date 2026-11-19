/**
 * Structura Nexus v4.0: High-Performance Hardware-Accelerated Three.js WebGL Engine
 * Multi-story space frame rendering, extruded BMD/SFD ribbons, 3D nodal force vectors,
 * distinct Fixed/Pinned/Roller support glyphs, deformation magnification,
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
      this.diagramGroup = new THREE.Group(); // BMD ribbons
      this.sfdGroup = new THREE.Group();     // SFD ribbons
      this.loadsGroup = new THREE.Group();   // 3D Force vector arrows
      this.releasesGroup = new THREE.Group(); // Release hinges & cracked glyphs
      this.reviewPinsGroup = new THREE.Group(); // 3D Pinned Engineering Review Comments
      this.connectionsGroup = new THREE.Group(); // v4.5 3D AISC Chapter J Steel Connections & Baseplates
      this.movingTruckGroup = new THREE.Group(); // v4.5 AASHTO HL-93 3D Moving Truck & Axle Vectors
      this.releaseGlyphs = [];

      // Viewport flags & state
      this.currentModel = null;
      this.showDeformation = false;
      this.deformationScale = 50.0;
      this.showBmd = false;
      this.showSfd = false;
      this.animTime = 0.0;
      this.lastRenderedRevision = -1;
      this._lastBoundsSignature = null;
      this.selectedNodeId = null;
      this.selectedMemberId = null;
      this.selectedNodeIds = new Set();
      this.selectedMemberIds = new Set();
      this.isMarqueeSelecting = false;
      this.marqueeStart = { x: 0, y: 0 };
      this.marqueeBoxEl = null;

      // Meshes and topology references
      this.nodeMeshes = [];
      this.memberMeshes = [];
      this.supportGlyphs = {};
      this.loadGlyphs = {};
      this.nodeMap = {}; // nodeId -> THREE.Vector3
      this.baseNodePositions = {}; // nodeId -> THREE.Vector3
      this.nodeDisplacements = {}; // nodeId -> THREE.Vector3
      this.memberData = []; // [{ id, iNodeId, jNodeId, mesh, dcr, baseColor, ... }]

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

    _disposeGroup(group) {
      if (!group) return;
      while (group.children.length > 0) {
        const obj = group.children[0];
        group.remove(obj);
        if (obj.children && obj.children.length > 0) {
          this._disposeGroup(obj);
        }
        if (obj.geometry) {
          obj.geometry.dispose();
        }
        if (obj.material) {
          if (Array.isArray(obj.material)) {
            obj.material.forEach((m) => m && m.dispose && m.dispose());
          } else if (obj.material.dispose) {
            obj.material.dispose();
          }
        }
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
            this.loadModel(pending, true);
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
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.78);
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
      this.scene.add(this.sfdGroup);
      this.scene.add(this.loadsGroup);
      this.scene.add(this.releasesGroup);
      this.scene.add(this.reviewPinsGroup);
      this.scene.add(this.connectionsGroup);
      this.scene.add(this.movingTruckGroup);

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
        this.loadModel(pending, true);
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

      // Handle Shift + Click multi-selection on Node
      if (e.shiftKey && nodeHits.length > 0) {
        const hitMesh = nodeHits[0].object;
        const nid = hitMesh.userData.nodeId;
        if (this.selectedNodeIds.has(nid)) {
          this.selectedNodeIds.delete(nid);
        } else {
          this.selectedNodeIds.add(nid);
        }
        this.selectedNodeId = this.selectedNodeIds.size === 1 ? Array.from(this.selectedNodeIds)[0] : null;
        this._updateSelectionHighlight();
        window.dispatchEvent(
          new CustomEvent("structura-multi-selected", {
            detail: {
              nodeIds: Array.from(this.selectedNodeIds),
              memberIds: Array.from(this.selectedMemberIds),
            },
          })
        );
        return;
      }

      // Handle Shift + Click multi-selection on Member
      if (e.shiftKey) {
        const memberHits = this.raycaster.intersectObjects(this.memberMeshes, false);
        if (memberHits.length > 0) {
          const hitMem = memberHits[0].object;
          if (hitMem.userData && hitMem.userData.memberId) {
            const mid = hitMem.userData.memberId;
            if (this.selectedMemberIds.has(mid)) {
              this.selectedMemberIds.delete(mid);
            } else {
              this.selectedMemberIds.add(mid);
            }
            this.selectedMemberId = this.selectedMemberIds.size === 1 ? Array.from(this.selectedMemberIds)[0] : null;
            this._updateSelectionHighlight();
            window.dispatchEvent(
              new CustomEvent("structura-multi-selected", {
                detail: {
                  nodeIds: Array.from(this.selectedNodeIds),
                  memberIds: Array.from(this.selectedMemberIds),
                },
              })
            );
            return;
          }
        }

        // Shift + Drag initiated on empty space -> start screen marquee bounding box
        this.isMarqueeSelecting = true;
        this.marqueeStart = { x: e.clientX, y: e.clientY };
        if (this.controls) {
          this.controls.enabled = false;
        }
        if (!this.marqueeBoxEl) {
          this.marqueeBoxEl = document.createElement("div");
          this.marqueeBoxEl.id = "structura-marquee-box";
          this.marqueeBoxEl.style.position = "fixed";
          this.marqueeBoxEl.style.pointerEvents = "none";
          this.marqueeBoxEl.style.backgroundColor = "rgba(0, 240, 255, 0.2)";
          this.marqueeBoxEl.style.border = "1px dashed #00f0ff";
          this.marqueeBoxEl.style.zIndex = "999999";
          document.body.appendChild(this.marqueeBoxEl);
        }
        this.marqueeBoxEl.style.left = e.clientX + "px";
        this.marqueeBoxEl.style.top = e.clientY + "px";
        this.marqueeBoxEl.style.width = "0px";
        this.marqueeBoxEl.style.height = "0px";
        this.marqueeBoxEl.style.display = "block";
        return;
      }

      if (nodeHits.length > 0) {
        const hitMesh = nodeHits[0].object;
        this.isDraggingNode = true;
        this.draggedNodeMesh = hitMesh;

        if (this.controls) {
          this.controls.enabled = false;
        }

        this.setSelectedEntity(hitMesh.userData.nodeId, null);

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
            this.setSelectedEntity(null, hitMem.userData.memberId);
            window.dispatchEvent(
              new CustomEvent("structura-member-selected", {
                detail: { memberId: hitMem.userData.memberId },
              })
            );
          }
        } else {
          // Clicked empty space without shift: deselect
          this.clearSelection();
          window.dispatchEvent(
            new CustomEvent("structura-multi-selected", {
              detail: { nodeIds: [], memberIds: [] },
            })
          );
        }
      }
    }

    onPointerMove(e) {
      if (window.__structuraMenuHovered) return;

      if (this.isMarqueeSelecting && this.marqueeBoxEl) {
        const minX = Math.min(this.marqueeStart.x, e.clientX);
        const maxX = Math.max(this.marqueeStart.x, e.clientX);
        const minY = Math.min(this.marqueeStart.y, e.clientY);
        const maxY = Math.max(this.marqueeStart.y, e.clientY);
        this.marqueeBoxEl.style.left = minX + "px";
        this.marqueeBoxEl.style.top = minY + "px";
        this.marqueeBoxEl.style.width = Math.max(0, maxX - minX) + "px";
        this.marqueeBoxEl.style.height = Math.max(0, maxY - minY) + "px";
        return;
      }

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
          if (this.loadGlyphs[nodeId]) {
            this.loadGlyphs[nodeId].position.set(nx, ny, nz);
          }

          this.morphIncidentMembers(nodeId);

          window.dispatchEvent(
            new CustomEvent("structura-node-dragged", {
              detail: { nodeId, x: nx, y: ny, z: nz },
            })
          );
        }
      } else {
        const nodeIntersects = this.raycaster.intersectObjects(this.nodeMeshes, false);
        if (nodeIntersects.length > 0) {
          this.renderer.domElement.style.cursor = "grab";
        } else {
          const memIntersects = this.raycaster.intersectObjects(this.memberMeshes, false);
          if (memIntersects.length > 0) {
            this.renderer.domElement.style.cursor = "pointer";
          } else {
            this.renderer.domElement.style.cursor = "default";
          }
        }
      }
    }

    onPointerUp(e) {
      if (this.isMarqueeSelecting) {
        this.isMarqueeSelecting = false;
        if (this.marqueeBoxEl) {
          this.marqueeBoxEl.style.display = "none";
        }
        if (this.controls && !window.__structuraMenuHovered) {
          this.controls.enabled = true;
        }

        const minX = Math.min(this.marqueeStart.x, e.clientX);
        const maxX = Math.max(this.marqueeStart.x, e.clientX);
        const minY = Math.min(this.marqueeStart.y, e.clientY);
        const maxY = Math.max(this.marqueeStart.y, e.clientY);

        if ((maxX - minX > 4) || (maxY - minY > 4)) {
          const rect = this.renderer.domElement.getBoundingClientRect();
          this.nodeMeshes.forEach((mesh) => {
            const p = mesh.position.clone().project(this.camera);
            if (p.z < 1.0) {
              const sx = ((p.x + 1) / 2) * rect.width + rect.left;
              const sy = ((-p.y + 1) / 2) * rect.height + rect.top;
              if (sx >= minX && sx <= maxX && sy >= minY && sy <= maxY) {
                this.selectedNodeIds.add(mesh.userData.nodeId);
              }
            }
          });

          this.memberData.forEach((m) => {
            if (this.nodeMap[m.iNodeId] && this.nodeMap[m.jNodeId]) {
              const mid = new THREE.Vector3()
                .addVectors(this.nodeMap[m.iNodeId], this.nodeMap[m.jNodeId])
                .multiplyScalar(0.5);
              const p = mid.project(this.camera);
              if (p.z < 1.0) {
                const sx = ((p.x + 1) / 2) * rect.width + rect.left;
                const sy = ((-p.y + 1) / 2) * rect.height + rect.top;
                if (sx >= minX && sx <= maxX && sy >= minY && sy <= maxY) {
                  this.selectedMemberIds.add(m.id);
                }
              }
            }
          });

          this.selectedNodeId = this.selectedNodeIds.size === 1 ? Array.from(this.selectedNodeIds)[0] : null;
          this.selectedMemberId = this.selectedMemberIds.size === 1 ? Array.from(this.selectedMemberIds)[0] : null;
          this._updateSelectionHighlight();

          window.dispatchEvent(
            new CustomEvent("structura-multi-selected", {
              detail: {
                nodeIds: Array.from(this.selectedNodeIds),
                memberIds: Array.from(this.selectedMemberIds),
              },
            })
          );
        }
        return;
      }

      if (this.isDraggingNode && this.draggedNodeMesh) {
        const nodeId = this.draggedNodeMesh.userData.nodeId;
        const fx = this.draggedNodeMesh.position.x;
        const fy = this.draggedNodeMesh.position.y;
        const fz = this.draggedNodeMesh.position.z;

        this.isDraggingNode = false;
        this.draggedNodeMesh = null;
        if (this.controls && !window.__structuraMenuHovered) {
          this.controls.enabled = true;
        }
        this.renderer.domElement.style.cursor = "default";
        this._updateSelectionHighlight();

        if (this.dragMoved) {
          window.dispatchEvent(
            new CustomEvent("structura-node-drag-end", {
              detail: { nodeId, x: fx, y: fy, z: fz },
            })
          );
        }
      }
    }

    setSelectedEntity(nodeId, memberId) {
      this.selectedNodeId = nodeId || null;
      this.selectedMemberId = memberId || null;
      this.selectedNodeIds = new Set(nodeId ? [nodeId] : []);
      this.selectedMemberIds = new Set(memberId ? [memberId] : []);
      this._updateSelectionHighlight();
    }

    setSelectedEntities(nodeIds, memberIds) {
      this.selectedNodeIds = new Set(nodeIds || []);
      this.selectedMemberIds = new Set(memberIds || []);
      this.selectedNodeId = this.selectedNodeIds.size === 1 ? Array.from(this.selectedNodeIds)[0] : null;
      this.selectedMemberId = this.selectedMemberIds.size === 1 ? Array.from(this.selectedMemberIds)[0] : null;
      this._updateSelectionHighlight();
    }

    clearSelection() {
      this.selectedNodeId = null;
      this.selectedMemberId = null;
      this.selectedNodeIds.clear();
      this.selectedMemberIds.clear();
      this._updateSelectionHighlight();
    }

    setHighlightedMembers(memberIds) {
      this.highlightedMemberIds = new Set(memberIds || []);
      this._updateSelectionHighlight();
    }

    _updateSelectionHighlight() {
      if (!this.highlightedMemberIds) this.highlightedMemberIds = new Set();
      this.nodeMeshes.forEach((mesh) => {
        if (!mesh.material || !mesh.material.emissive) return;
        const isSel = (this.selectedNodeId && mesh.userData.nodeId === this.selectedNodeId) ||
                      (this.selectedNodeIds && this.selectedNodeIds.has(mesh.userData.nodeId));
        if (isSel) {
          mesh.material.emissive.setHex(0xffffff);
          mesh.material.emissiveIntensity = 0.95;
          mesh.scale.set(1.35, 1.35, 1.35);
        } else {
          const baseEmissive = mesh.userData.baseEmissive ?? 0x004455;
          const baseIntensity = mesh.userData.baseEmissiveIntensity ?? 0.35;
          mesh.material.emissive.setHex(baseEmissive);
          mesh.material.emissiveIntensity = baseIntensity;
          mesh.scale.set(1.0, 1.0, 1.0);
        }
      });

      this.memberData.forEach((m) => {
        if (!m.mesh || !m.mesh.material || !m.mesh.material.emissive) return;
        const isSel = (this.selectedMemberId && m.id === this.selectedMemberId) ||
                      (this.selectedMemberIds && this.selectedMemberIds.has(m.id));
        const isHigh = this.highlightedMemberIds.has(m.id);

        if (isSel) {
          m.mesh.material.emissive.setHex(0x00ffff);
          m.mesh.material.emissiveIntensity = 0.85;
        } else if (isHigh) {
          m.mesh.material.emissive.setHex(0xff0055); // Spatial voice critical highlight
          m.mesh.material.emissiveIntensity = 0.95;
        } else {
          m.mesh.material.emissive.setHex(m.baseColor);
          m.mesh.material.emissiveIntensity = m.dcr > 1.0 ? 0.4 : 0.12;
        }
      });
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

      // Update position of incident release hinge rings
      if (this.releaseGlyphs) {
        this.releaseGlyphs.forEach((rel) => {
          if (rel.iNodeId === nodeId || rel.jNodeId === nodeId) {
            const p1 = this.nodeMap[rel.iNodeId];
            const p2 = this.nodeMap[rel.jNodeId];
            if (!p1 || !p2) return;
            const dir = new THREE.Vector3().subVectors(p2, p1).normalize();
            const sign = rel.type === 'start' ? 1.0 : -1.0;
            const targetPos = rel.type === 'start' ? p1 : p2;
            const offsetDist = 0.35 * (this.geomScale || 1.0) * sign;
            rel.mesh.position.copy(targetPos).addScaledVector(dir, offsetDist);
            const ringAxis = new THREE.Vector3(0, 0, 1);
            rel.mesh.quaternion.setFromUnitVectors(ringAxis, dir);
          }
        });
      }
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

    createForceArrow(x, y, z, fx, fy, fz, geomScale = 1.0) {
      const mag = Math.hypot(fx, fy, fz);
      if (mag < 1.0) return null;

      const group = new THREE.Group();
      group.position.set(x, y, z);

      const dir = new THREE.Vector3(fx, fy, fz).normalize();
      // Color: Crimson-magenta for downward gravity, Cyan for lateral wind/seismic
      const isGravityDominant = Math.abs(fy) >= Math.hypot(fx, fz);
      const arrowColor = isGravityDominant ? 0xff2a6d : 0x00f0ff;

      // Scale length logarithmically between 0.7m and 1.6m
      const kN = mag / 1000.0;
      const totalLen = Math.min(1.65, Math.max(0.75, 0.55 + Math.log10(Math.max(kN, 1.0)) * 0.35)) * geomScale;
      const headLen = 0.28 * geomScale;
      const shaftLen = Math.max(totalLen - headLen, 0.3 * geomScale);

      // Build arrow along +Y local axis, with tip at origin (0,0,0) pointing in +Y,
      // so the arrowhead touches the node sphere cleanly
      const shaftGeo = new THREE.CylinderGeometry(0.038 * geomScale, 0.038 * geomScale, shaftLen, 10);
      const arrowMat = new THREE.MeshStandardMaterial({
        color: arrowColor,
        emissive: arrowColor,
        emissiveIntensity: 0.75,
        metalness: 0.4,
        roughness: 0.2,
      });

      const shaftMesh = new THREE.Mesh(shaftGeo, arrowMat);
      shaftMesh.position.set(0, -(headLen + shaftLen * 0.5 + 0.16 * geomScale), 0);

      const headGeo = new THREE.ConeGeometry(0.11 * geomScale, headLen, 12);
      const headMesh = new THREE.Mesh(headGeo, arrowMat);
      headMesh.position.set(0, -(headLen * 0.5 + 0.16 * geomScale), 0);

      group.add(shaftMesh);
      group.add(headMesh);

      const upAxis = new THREE.Vector3(0, 1, 0);
      group.quaternion.setFromUnitVectors(upAxis, dir);

      return group;
    }

    createReleaseHingeGlyph(nodePos, memberDir, sign = 1.0, geomScale = 1.0) {
      const ringGroup = new THREE.Group();
      const ringGeo = new THREE.TorusGeometry(0.13 * geomScale, 0.035 * geomScale, 8, 20);
      const ringMat = new THREE.MeshStandardMaterial({
        color: 0x10b981,
        emissive: 0x00f0ff,
        emissiveIntensity: 0.85,
        metalness: 0.85,
        roughness: 0.2,
      });
      const ringMesh = new THREE.Mesh(ringGeo, ringMat);
      ringGroup.add(ringMesh);

      const offsetDist = 0.35 * geomScale * sign;
      const pos = new THREE.Vector3().copy(nodePos).addScaledVector(memberDir, offsetDist);
      ringGroup.position.copy(pos);

      const ringAxis = new THREE.Vector3(0, 0, 1);
      ringGroup.quaternion.setFromUnitVectors(ringAxis, memberDir);

      return ringGroup;
    }

    createCrackedIndicator(p1, p2, dir, length, geomScale = 1.0) {
      const sleeveRadius = 0.095 * geomScale;
      const sleeveGeo = new THREE.CylinderGeometry(sleeveRadius, sleeveRadius, length * 0.92, 10, 1, true);
      const sleeveMat = new THREE.MeshBasicMaterial({
        color: 0x00f0ff,
        wireframe: true,
        transparent: true,
        opacity: 0.35,
      });
      const sleeveMesh = new THREE.Mesh(sleeveGeo, sleeveMat);
      const mid = new THREE.Vector3().addVectors(p1, p2).multiplyScalar(0.5);
      sleeveMesh.position.copy(mid);
      const axis = new THREE.Vector3(0, 1, 0);
      sleeveMesh.quaternion.setFromUnitVectors(axis, dir);
      this.releasesGroup.add(sleeveMesh);
    }

    createReviewPinGlyph(x, y, z, text, author, isResolved = false) {
      const pinGroup = new THREE.Group();
      const pinColor = isResolved ? 0x10b981 : 0xf59e0b;

      // Vertical stem
      const stemHeight = 0.45;
      const stemGeo = new THREE.CylinderGeometry(0.015, 0.005, stemHeight, 8);
      const stemMat = new THREE.MeshBasicMaterial({ color: pinColor });
      const stemMesh = new THREE.Mesh(stemGeo, stemMat);
      stemMesh.position.set(0, stemHeight / 2, 0);
      pinGroup.add(stemMesh);

      // Pin beacon head with rim glow
      const headGeo = new THREE.SphereGeometry(0.09, 16, 16);
      const headMat = new THREE.MeshStandardMaterial({
        color: pinColor,
        emissive: pinColor,
        emissiveIntensity: 0.6,
        roughness: 0.2,
        metalness: 0.8,
      });
      const headMesh = new THREE.Mesh(headGeo, headMat);
      headMesh.position.set(0, stemHeight + 0.08, 0);
      pinGroup.add(headMesh);

      pinGroup.position.set(x, y, z);
      return pinGroup;
    }

    setReviewPins(pins) {
      this._disposeGroup(this.reviewPinsGroup);
      if (!Array.isArray(pins)) return;
      for (const p of pins) {
        if (!p || !Array.isArray(p.coords) || p.coords.length < 3) continue;
        const glyph = this.createReviewPinGlyph(
          p.coords[0],
          p.coords[1],
          p.coords[2],
          p.text || '',
          p.author || '',
          !!p.isResolved
        );
        this.reviewPinsGroup.add(glyph);
      }
    }

    loadModel(model, forceRefit = false) {
      if (!model) return;
      this.currentModel = model;

      if (!this.ensureMounted()) {
        this._pendingModel = model;
        this._waitForContainer();
        return;
      }

      // Cleanly dispose all GPU geometries and materials
      this._disposeGroup(this.structureGroup);
      this._disposeGroup(this.deformationGroup);
      this._disposeGroup(this.diagramGroup);
      this._disposeGroup(this.sfdGroup);
      this._disposeGroup(this.loadsGroup);
      this._disposeGroup(this.releasesGroup);
      this._disposeGroup(this.reviewPinsGroup);

      this.nodeMeshes = [];
      this.memberMeshes = [];
      this.supportGlyphs = {};
      this.loadGlyphs = {};
      this.releaseGlyphs = [];
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
        if (this.gridHelper.geometry) this.gridHelper.geometry.dispose();
        if (this.gridHelper.material) {
          if (Array.isArray(this.gridHelper.material)) {
            this.gridHelper.material.forEach((m) => m && m.dispose && m.dispose());
          } else if (this.gridHelper.material.dispose) {
            this.gridHelper.material.dispose();
          }
        }
        const gridSpan = Math.max(Math.ceil((Math.max(spanX, spanZ) * 2.2) / 10) * 10, 40);
        const divisions = Math.min(Math.max(Math.round(gridSpan / 2), 20), 80);
        this.gridHelper = new THREE.GridHelper(gridSpan, divisions, 0x00e5ff, 0x1f293d);
        this.gridHelper.position.set(cx, -0.02, cz);
        this.scene.add(this.gridHelper);
      }

      const geomScale = Math.max(1.0, Math.min(maxDim / 18.0, 2.2));
      this.geomScale = geomScale;

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

      const rollerCylGeo = new THREE.CylinderGeometry(0.16 * geomScale, 0.16 * geomScale, 0.36 * geomScale, 14);
      rollerCylGeo.rotateZ(Math.PI / 2);
      const rollerCylMat = new THREE.MeshStandardMaterial({
        color: 0x10b981,
        metalness: 0.75,
        roughness: 0.2,
        emissive: 0x065f46,
        emissiveIntensity: 0.35,
      });

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
        nodeMesh.userData = {
          nodeId: n.id,
          isRestrained: false,
          baseEmissive: isStandalone ? 0x00f0ff : 0x004455,
          baseEmissiveIntensity: isStandalone ? 0.9 : 0.35,
        };

        this.structureGroup.add(nodeMesh);
        this.nodeMeshes.push(nodeMesh);

        // Boundary support glyphs (Fixed vs Pinned vs Roller)
        const restraint = n.restraint || [0, 0, 0, 0, 0, 0];
        const isRestrained = n.isRestrained || restraint.some((r) => r === 1);
        if (isRestrained) {
          nodeMesh.userData.isRestrained = true;
          const allTransFixed = restraint.slice(0, 3).every((r) => r === 1);
          const anyRotFixed = restraint.slice(3, 6).some((r) => r === 1);
          const isRoller = restraint[1] === 1 && !allTransFixed;

          if (allTransFixed && anyRotFixed) {
            // Fixed Base (Blue Box)
            const fixMesh = new THREE.Mesh(fixedBoxGeo.clone(), fixedBoxMat.clone());
            const yOff = 0.12 * geomScale;
            fixMesh.position.set(x, y - yOff, z);
            fixMesh.userData = { yOffset: yOff };
            this.structureGroup.add(fixMesh);
            this.supportGlyphs[n.id] = fixMesh;
          } else if (isRoller) {
            // Roller Support (Emerald Roller Cylinder)
            const rolMesh = new THREE.Mesh(rollerCylGeo.clone(), rollerCylMat.clone());
            const yOff = 0.16 * geomScale;
            rolMesh.position.set(x, y - yOff, z);
            rolMesh.userData = { yOffset: yOff };
            this.structureGroup.add(rolMesh);
            this.supportGlyphs[n.id] = rolMesh;
          } else {
            // Pinned Base (Amber Cone)
            const pinMesh = new THREE.Mesh(pinnedConeGeo.clone(), pinnedConeMat.clone());
            const yOff = 0.18 * geomScale;
            pinMesh.position.set(x, y - yOff, z);
            pinMesh.userData = { yOffset: yOff };
            this.structureGroup.add(pinMesh);
            this.supportGlyphs[n.id] = pinMesh;
          }
        }

        // 3D Nodal Force Vector Arrows
        const loads = n.loads || [0, 0, 0, 0, 0, 0];
        const fx = loads[0] || 0.0;
        const fy = loads[1] || 0.0;
        const fz = loads[2] || 0.0;
        const arrowGroup = this.createForceArrow(x, y, z, fx, fy, fz, geomScale);
        if (arrowGroup) {
          this.loadsGroup.add(arrowGroup);
          this.loadGlyphs[n.id] = arrowGroup;
        }
      });

      // Dispose template geometries/materials after cloning
      nodeGeo.dispose();
      nodeMat.dispose();
      fixedBoxGeo.dispose();
      fixedBoxMat.dispose();
      pinnedConeGeo.dispose();
      pinnedConeMat.dispose();
      rollerCylGeo.dispose();
      rollerCylMat.dispose();
      standaloneGeo.dispose();
      standaloneMat.dispose();

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
        let memberColor = 0x3b82f6;
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
          baseColor: memberColor,
        });

        // 3. Optional Extruded BMD & SFD Ribbons
        this.createBmdRibbon(p1, p2, dir, dcr, geomScale);
        this.createSfdRibbon(p1, p2, dir, dcr, geomScale);

        // 4. Circular Release-Hinge Glyphs (Emerald-Cyan Ring)
        const relStart = m.release_start_mz || m.releaseStartMz || m.release_start_my || m.releaseStartMy || m.release_i_moment || m.releaseIMoment;
        const relEnd = m.release_end_mz || m.releaseEndMz || m.release_end_my || m.releaseEndMy || m.release_j_moment || m.releaseJMoment;

        if (relStart) {
          const startRing = this.createReleaseHingeGlyph(p1, dir, 1.0, geomScale);
          if (startRing) {
            this.releasesGroup.add(startRing);
            this.releaseGlyphs.push({ mesh: startRing, iNodeId: iId, jNodeId: jId, type: 'start' });
          }
        }
        if (relEnd) {
          const endRing = this.createReleaseHingeGlyph(p2, dir, -1.0, geomScale);
          if (endRing) {
            this.releasesGroup.add(endRing);
            this.releaseGlyphs.push({ mesh: endRing, iNodeId: iId, jNodeId: jId, type: 'end' });
          }
        }

        // 5. Cracked Member Visual Indicator (ACI 318-19 I_eff < 1.0 Ig)
        const isCracked = (m.cracked_section_factor != null && m.cracked_section_factor < 1.0) ||
                          (m.crackedSectionFactor != null && m.crackedSectionFactor < 1.0) ||
                          (m.material && m.material.toUpperCase().includes('CONCRETE'));
        if (isCracked) {
          this.createCrackedIndicator(p1, p2, dir, distance, geomScale);
        }
      });

      // Center camera focus on bounding center & auto-frame only when topology bounds change or forced
      if (nodes.length > 0) {
        this.currentCenter = new THREE.Vector3(cx, cy, cz);
        this.currentMaxDim = maxDim;

        const fovRad = ((this.camera && this.camera.fov ? this.camera.fov : 45) * Math.PI) / 180;
        const fitDistance = Math.max((maxDim / 2 / Math.tan(fovRad / 2)) * 1.65, 13.0);
        this.fitDistance = fitDistance;

        const boundsSignature = `${nodes.length}:${members.length}:${cx.toFixed(1)}:${cy.toFixed(1)}:${cz.toFixed(1)}:${maxDim.toFixed(1)}`;
        const shouldRefit = forceRefit || this._lastBoundsSignature !== boundsSignature;
        this._lastBoundsSignature = boundsSignature;

        if (shouldRefit) {
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
      }

      if (this.showDeformation) {
        this._applyDeformationState();
      }
      this._updateSelectionHighlight();

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
          const nx = base.x + dx;
          const ny = base.y + dy;
          const nz = base.z + dz;
          mesh.position.set(nx, ny, nz);
          if (this.nodeMap[nodeId]) {
            this.nodeMap[nodeId].set(nx, ny, nz);
          }
          if (this.loadGlyphs[nodeId]) {
            this.loadGlyphs[nodeId].position.set(nx, ny, nz);
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
          const nx = base.x + dx;
          const ny = base.y + dy;
          const nz = base.z + dz;

          mesh.position.set(nx, ny, nz);
          if (this.nodeMap[nodeId]) {
            this.nodeMap[nodeId].set(nx, ny, nz);
          }
          if (this.loadGlyphs[nodeId]) {
            this.loadGlyphs[nodeId].position.set(nx, ny, nz);
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

    createSfdRibbon(p1, p2, dir, dcr, geomScale = 1.0) {
      const normal = new THREE.Vector3(-dir.y, dir.x, 0).normalize();
      if (normal.length() < 0.1) normal.set(0, 0, 1);

      const offsetMag = Math.min(0.75 * geomScale, Math.max(0.32 * geomScale, (0.22 + dcr * 0.35) * geomScale));
      const mid = new THREE.Vector3().lerpVectors(p1, p2, 0.5);

      const points = [
        p1.clone(),
        p1.clone().addScaledVector(normal, offsetMag),
        mid.clone().addScaledVector(normal, offsetMag),
        mid.clone().addScaledVector(normal, -offsetMag),
        p2.clone().addScaledVector(normal, -offsetMag),
        p2.clone(),
      ];

      const curve = new THREE.CatmullRomCurve3(points, false, "catmullrom", 0.05);
      const tubeGeo = new THREE.TubeGeometry(curve, 18, 0.045 * geomScale, 8, false);
      const sfdMat = new THREE.MeshBasicMaterial({
        color: 0x00f0ff,
        wireframe: false,
        transparent: true,
        opacity: 0.92,
      });

      const sfdMesh = new THREE.Mesh(tubeGeo, sfdMat);
      sfdMesh.visible = this.showSfd;
      this.sfdGroup.add(sfdMesh);
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

    setSfdVisible(visible) {
      this.showSfd = visible;
      this.sfdGroup.children.forEach((c) => (c.visible = visible));
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

    /**
     * v4.5 Track 2.2: Synthesize 3D AISC 360-16 Chapter J Steel Connection Assembly
     * Renders extruded shear tabs, extended moment end-plates, chamfered gusset plates,
     * baseplates, and 3D hex-head A325/A490 bolts color-coded by utilization DCR.
     */
    synthesizeConnectionAssembly(config) {
      if (!config) return;
      const data = typeof config === "string" ? JSON.parse(config) : config;
      this._disposeGroup(this.connectionsGroup);

      const coords = data.joint_coords_m || [0.0, 0.0, 0.0];
      const jx = coords[0] || 0.0;
      const jy = coords[1] || 0.0;
      const jz = coords[2] || 0.0;
      const scale = Math.max(1.2, (this.geomScale || 1.0) * 1.35);

      const assembly = new THREE.Group();
      assembly.position.set(jx, jy, jz);

      const cType = (data.connection_type || "SHEAR_TAB").toUpperCase();
      const dims = data.plate_dimensions_m || [0.22, 0.34, 0.015];
      const pw = Math.max(0.18, (dims[0] || 0.22) * scale);
      const ph = Math.max(0.24, (dims[1] || 0.34) * scale);
      const pt = Math.max(0.03, (dims[2] || 0.015) * scale * 2.0);

      const plateMat = new THREE.MeshStandardMaterial({
        color: 0x1e293b,
        metalness: 0.85,
        roughness: 0.22,
        emissive: 0x00f0ff,
        emissiveIntensity: 0.22,
      });

      if (cType === "GUSSET_PLATE") {
        // Chamfered triangular/polygonal braced-frame gusset plate
        const shape = new THREE.Shape();
        shape.moveTo(0, 0);
        shape.lineTo(pw * 1.2, 0);
        shape.lineTo(pw * 1.2, ph * 0.45);
        shape.lineTo(pw * 0.45, ph * 1.2);
        shape.lineTo(0, ph * 1.2);
        shape.closePath();
        const extrudeGeo = new THREE.ExtrudeGeometry(shape, {
          depth: pt,
          bevelEnabled: true,
          bevelThickness: 0.008,
          bevelSize: 0.008,
          bevelSegments: 2,
        });
        const gussetMesh = new THREE.Mesh(extrudeGeo, plateMat);
        gussetMesh.position.set(0, 0, -0.5 * pt);
        assembly.add(gussetMesh);
      } else if (cType === "BASEPLATE") {
        // Column baseplate + underlying concrete pedestal block
        const bpGeo = new THREE.BoxGeometry(pw * 1.25, pt, ph * 1.25);
        const bpMesh = new THREE.Mesh(bpGeo, plateMat);
        bpMesh.position.set(0, 0.5 * pt, 0);
        assembly.add(bpMesh);

        const pedGeo = new THREE.BoxGeometry(pw * 1.65, 0.25 * scale, ph * 1.65);
        const pedMat = new THREE.MeshStandardMaterial({
          color: 0x334155,
          roughness: 0.75,
          metalness: 0.15,
        });
        const pedMesh = new THREE.Mesh(pedGeo, pedMat);
        pedMesh.position.set(0, -0.125 * scale, 0);
        assembly.add(pedMesh);
      } else {
        // Shear Tab or Extended Moment End-Plate
        const plateGeo = new THREE.BoxGeometry(pt, ph, pw);
        const plateMesh = new THREE.Mesh(plateGeo, plateMat);
        assembly.add(plateMesh);
      }

      // 3D Hex-Head Bolt & Nut Cylinders (6 radial segments = hexagon)
      const bolts = data.bolts_3d || [];
      bolts.forEach((b) => {
        const dcr = b.utilization_dcr ?? 0.45;
        let boltColor = 0x10b981; // Emerald PASS
        if (dcr > 1.0) boltColor = 0xef4444; // Crimson OVERSTRESSED
        else if (dcr >= 0.8) boltColor = 0xf59e0b; // Amber WARN
        else boltColor = 0x00f0ff; // Cyan Nominal

        const bRad = Math.max(0.024 * scale, (b.diameter_m || 0.022) * scale * 1.1);
        const bLen = pt * 2.1;
        const hexGeo = new THREE.CylinderGeometry(bRad, bRad, bLen, 6);
        if (cType !== "BASEPLATE") {
          hexGeo.rotateZ(Math.PI / 2);
        }
        const hexMat = new THREE.MeshStandardMaterial({
          color: boltColor,
          metalness: 0.9,
          roughness: 0.15,
          emissive: boltColor,
          emissiveIntensity: 0.55,
        });
        const boltMesh = new THREE.Mesh(hexGeo, hexMat);
        boltMesh.position.set(
          (b.local_x_m || 0.0) * scale,
          (b.local_y_m || 0.0) * scale,
          (b.local_z_m || 0.0) * scale
        );
        assembly.add(boltMesh);
      });

      this.connectionsGroup.add(assembly);
    }

    clearConnections() {
      this._disposeGroup(this.connectionsGroup);
    }

    /**
     * v4.5 Track 3.2: AASHTO LRFD HL-93 Moving-Load 3D Truck Mesh & Live Axle Vectors
     */
    updateMovingLoadTruck(truckPayload) {
      if (!truckPayload) return;
      const data = typeof truckPayload === "string" ? JSON.parse(truckPayload) : truckPayload;
      this._disposeGroup(this.movingTruckGroup);

      const leadX = data.lead_x_m ?? 6.0;
      const deckY = data.deck_y_m ?? 0.0;
      const deckZ = data.deck_z_m ?? 0.0;
      const scale = Math.max(1.0, this.geomScale || 1.0);

      const truckGroup = new THREE.Group();

      // Translucent Cyan HL-93 Tractor Cab & Trailer Silhouette
      const hullMat = new THREE.MeshStandardMaterial({
        color: 0x00f0ff,
        transparent: true,
        opacity: 0.42,
        emissive: 0x00f0ff,
        emissiveIntensity: 0.45,
        roughness: 0.2,
      });

      const cabGeo = new THREE.BoxGeometry(1.8 * scale, 1.4 * scale, 1.6 * scale);
      const cabMesh = new THREE.Mesh(cabGeo, hullMat);
      cabMesh.position.set(leadX, deckY + 1.0 * scale, deckZ);
      truckGroup.add(cabMesh);

      const trailerGeo = new THREE.BoxGeometry(4.8 * scale, 1.1 * scale, 1.6 * scale);
      const trailerMesh = new THREE.Mesh(trailerGeo, hullMat.clone());
      trailerMesh.position.set(leadX - 3.4 * scale, deckY + 0.85 * scale, deckZ);
      truckGroup.add(trailerMesh);

      // Downward Axle Load Vector Arrows (35 kN, 145 kN, 145 kN)
      const axles = data.axles || [];
      axles.forEach((ax) => {
        const axX = ax.x ?? leadX;
        const loadKn = ax.load_kn ?? 145.0;
        const arrowGroup = this.createForceArrow(
          axX,
          deckY,
          deckZ,
          0.0,
          -loadKn * 1000.0,
          0.0,
          scale * 1.15
        );
        if (arrowGroup) {
          this.movingTruckGroup.add(arrowGroup);
        }
      });

      this.movingTruckGroup.add(truckGroup);

      // Live Member DCR Stress Heatmap Update
      const dcrs = data.member_dcrs;
      if (dcrs && this.memberData) {
        this.memberData.forEach((m) => {
          const dcr = dcrs[m.id];
          if (dcr !== undefined && m.mesh && m.mesh.material) {
            let col = 0x10b981;
            if (dcr > 1.0) col = 0xef4444;
            else if (dcr >= 0.85) col = 0xf59e0b;
            else if (dcr >= 0.45) col = 0x38bdf8;
            m.mesh.material.color.setHex(col);
            m.mesh.material.emissive.setHex(col);
          }
        });
      }
    }

    clearMovingLoadTruck() {
      this._disposeGroup(this.movingTruckGroup);
    }

    dispose() {
      if (this.animId) cancelAnimationFrame(this.animId);
      this._disposeGroup(this.structureGroup);
      this._disposeGroup(this.deformationGroup);
      this._disposeGroup(this.diagramGroup);
      this._disposeGroup(this.sfdGroup);
      this._disposeGroup(this.loadsGroup);
      this._disposeGroup(this.releasesGroup);
      this._disposeGroup(this.reviewPinsGroup);
      this._disposeGroup(this.connectionsGroup);
      this._disposeGroup(this.movingTruckGroup);
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
    window.__currentThreeViewport = viewer;
    return viewer;
  };
  window.setStructuralReviewPins = function (pins) {
    if (window.__currentThreeViewport) {
      window.__currentThreeViewport.setReviewPins(pins);
    }
  };
  window.render3DConnectionAssembly = function (configJson) {
    if (window.__currentThreeViewport) {
      window.__currentThreeViewport.synthesizeConnectionAssembly(configJson);
    }
  };
  window.clear3DConnectionAssemblies = function () {
    if (window.__currentThreeViewport) {
      window.__currentThreeViewport.clearConnections();
    }
  };
  window.updateMovingLoadTruck = function (truckJson) {
    if (window.__currentThreeViewport) {
      window.__currentThreeViewport.updateMovingLoadTruck(truckJson);
    }
  };
  window.clearMovingLoadTruck = function () {
    if (window.__currentThreeViewport) {
      window.__currentThreeViewport.clearMovingLoadTruck();
    }
  };
})();
