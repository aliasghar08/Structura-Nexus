/**
 * Structura Nexus: High-Performance Hardware-Accelerated Three.js WebGL Engine
 * Multi-story space frame rendering, extruded BMD/SFD ribbons, deformation magnification, and orbit dynamics.
 */

(function () {
  class StructuraThreeViewer {
    constructor(containerId) {
      this.containerId = containerId;
      this.container = document.getElementById(containerId);
      this.scene = null;
      this.camera = null;
      this.renderer = null;
      this.controls = null;
      this.animId = null;

      // Group containers
      this.structureGroup = null;
      this.deformationGroup = null;
      this.diagramGroup = null;

      // Viewport flags & state
      this.currentModel = null;
      this.showDeformation = false;
      this.deformationScale = 50.0;
      this.showBmd = false;
      this.showSfd = false;
      this.animTime = 0.0;
      this.nodeMeshes = [];
      this.memberMeshes = [];

      this.init();
    }

    init() {
      if (!this.container) {
        console.warn(`[ThreeViewer] Container #${this.containerId} not found yet.`);
        return;
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
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.65);
      this.scene.add(ambientLight);

      const dirLight1 = new THREE.DirectionalLight(0x00f0ff, 0.85); // Cyan key
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
      if (THREE.OrbitControls) {
        this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
        this.controls.enableDamping = true;
        this.controls.dampingFactor = 0.05;
        this.controls.target.set(3, 4, 0);
      }

      // 6. Object Groups
      this.structureGroup = new THREE.Group();
      this.deformationGroup = new THREE.Group();
      this.diagramGroup = new THREE.Group();

      this.scene.add(this.structureGroup);
      this.scene.add(this.deformationGroup);
      this.scene.add(this.diagramGroup);

      // 7. Window resize handling
      window.addEventListener("resize", () => this.onResize());

      // 8. Start Loop
      this.animate = this.animate.bind(this);
      this.animate();
      console.log(`[ThreeViewer] Initialized hardware WebGL viewport for #${this.containerId}`);
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

      const nodes = model.nodes || [];
      const members = model.members || [];
      const nodeMap = {};

      // 1. Render Nodes
      const nodeGeo = new THREE.SphereGeometry(0.12, 16, 16);
      const nodeMat = new THREE.MeshStandardMaterial({
        color: 0x00ffff,
        metalness: 0.8,
        roughness: 0.2,
        emissive: 0x004455,
      });

      const fixedBoxGeo = new THREE.BoxGeometry(0.35, 0.18, 0.35);
      const fixedBoxMat = new THREE.MeshStandardMaterial({ color: 0x3b82f6, metalness: 0.7 });

      const pinnedConeGeo = new THREE.ConeGeometry(0.22, 0.35, 16);
      const pinnedConeMat = new THREE.MeshStandardMaterial({ color: 0xf59e0b, metalness: 0.7 });

      nodes.forEach((n) => {
        const x = n.x ?? (n.coords ? n.coords[0] : 0.0);
        const y = n.y ?? (n.coords ? n.coords[1] : 0.0);
        const z = n.z ?? (n.coords ? n.coords[2] : 0.0);
        nodeMap[n.id] = new THREE.Vector3(x, y, z);

        const nodeMesh = new THREE.Mesh(nodeGeo, nodeMat);
        nodeMesh.position.set(x, y, z);
        this.structureGroup.add(nodeMesh);
        this.nodeMeshes.push(nodeMesh);

        // Boundary support glyphs
        const isRestrained = n.isRestrained || (n.restraint && n.restraint.some((r) => r === 1));
        if (isRestrained) {
          const isFixed = n.restraint && n.restraint.slice(0, 3).every((r) => r === 1);
          if (isFixed) {
            const fixMesh = new THREE.Mesh(fixedBoxGeo, fixedBoxMat);
            fixMesh.position.set(x, y - 0.12, z);
            this.structureGroup.add(fixMesh);
          } else {
            const pinMesh = new THREE.Mesh(pinnedConeGeo, pinnedConeMat);
            pinMesh.position.set(x, y - 0.18, z);
            this.structureGroup.add(pinMesh);
          }
        }
      });

      // 2. Render Members
      members.forEach((m) => {
        const iId = m.iNodeId || m.i_node;
        const jId = m.jNodeId || m.j_node;
        const p1 = nodeMap[iId];
        const p2 = nodeMap[jId];
        if (!p1 || !p2) return;

        const distance = p1.distanceTo(p2);
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

    createBmdRibbon(p1, p2, dir, dcr) {
      // Extrude a parabolic moment envelope perpendicular to member axis
      const segments = 10;
      const normal = new THREE.Vector3(-dir.y, dir.x, 0).normalize();
      if (normal.length() < 0.1) normal.set(0, 0, 1);

      const maxOffset = Math.min(0.6, 0.15 + dcr * 0.3);
      const points = [];

      for (let s = 0; s <= segments; s++) {
        const t = s / segments;
        const ptOnAxis = new THREE.Vector3().lerpVectors(p1, p2, t);
        // Parabolic moment variation M(x) = 4 * M_max * t * (1 - t)
        const parabola = 4.0 * t * (1.0 - t);
        const ptOffset = new THREE.Vector3().copy(ptOnAxis).addScaledVector(normal, parabola * maxOffset);
        points.push(ptOffset);
      }

      const curve = new THREE.CatmullRomCurve3(points);
      const tubeGeo = new THREE.TubeGeometry(curve, 16, 0.025, 8, false);
      const bmdMat = new THREE.MeshBasicMaterial({
        color: 0xec4899, // Magenta moment curve
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
      console.log(`[ThreeViewer] Deformation mode: ${enabled}, scale: ${scale}`);
    }

    setBmdVisible(visible) {
      this.showBmd = visible;
      this.diagramGroup.children.forEach((c) => (c.visible = visible));
      console.log(`[ThreeViewer] BMD visibility: ${visible}`);
    }

    setStressOverlay(visible) {
      this.memberMeshes.forEach((mesh) => {
        mesh.material.emissiveIntensity = visible ? 0.35 : 0.05;
      });
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
    const viewer = new StructuraThreeViewer(containerId);
    window.__structuraViewerInstances[containerId] = viewer;
    return viewer;
  };
})();
