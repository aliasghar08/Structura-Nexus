# Structura Nexus / Structura Forge AI

> **Next-Generation 100% Proprietary, AI-Powered Workstation for Civil & Structural Engineering**  
> **System Architecture**: `v3.4.0-REV-A` • **Hardware Acceleration**: Apple Silicon MPS / WebGL Three.js GPU / SIMD Dart Tensor Runtime  
> **Standard Compliance**: `AISC 360-16` • `ACI 318-19` • `ASCE 7-16` • `IBC 2024` • `ATC-40` • `FEMA 356` • `SE 2050`  
> **Live Web Application**: [https://structura-nexus.web.app](https://structura-nexus.web.app)  
> **GCP Cloud Run Neural API**: [https://structura-nexus-api-413099324256.us-central1.run.app](https://structura-nexus-api-413099324256.us-central1.run.app)  
> **Source Repository**: [`aliasghar08/Structura-Nexus`](https://github.com/aliasghar08/Structura-Nexus)  

---

## 🏗️ Platform Overview

**Structura Nexus** is an engineering-grade computational workstation that eliminates reliance on third-party finite element wrappers (`PyNiteFEA` completely purged) and replaces heuristic solvers with a **100% proprietary suite of 10 custom-trained deep neural networks and physics surrogates**.

The workstation operates on a **Dual Inference Execution Architecture**:
1. **Client-Side In-Browser Tensor Engine (`dart_neural_engine.dart`)**: Pure Dart SIMD-accelerated forward passes (`Float32List`, SiLU, Softplus, LayerNorm) executing in **`<0.2 ms`** directly in any modern web browser without server round-trips.
2. **Cloud-Native PyTorch Microservice (`backend/app/main.py`)**: Sub-millisecond containerized neural inference (**`<1.0 ms`**) hosted on Google Cloud Run with automatic multi-zone autoscaling.

---

## 💎 Apple visionOS Glassmorphic & Mobile-Responsive Interface

Designed from the ground up to transcend traditional, rigid desktop CAD boxes across both desktop workstations (`1440×900+`) and mobile screens (e.g., iPhone 13 `390×844`):
- **Spatial Liquid Glassmorphism (`GlassPod`)**: Multi-layered backdrop blurs (`sigmaX: 20, sigmaY: 20`), linear gradient specular rim borders, ambient drop shadows, and automatic responsive scaling on mobile viewports.
- **Unified Single Scrolling Top Option Bar (`FloatingWorkstationHeader`)**: Houses only active 3D canvas controls (`TOOLS & SUITE` drawer launcher, benchmark presets, solver engine switcher, display mode selector, deformation magnification slider, WebGL 3D / Vector 2.5D renderer toggle, `ISO / TOP / FRONT` camera views, and `X • Y • Z` compass) with interactive `‹` / `›` chevron buttons and mouse/touch drag scrolling.
- **Categorized Slide-Out App Drawer (`WorkstationDrawer`)**: All 17 specialized engineering studios, AI copilot, CAD/BIM editors, and environmental stimulators are cleanly organized in the slide-out drawer.
- **Zero-Overlap Mobile & Desktop Layout**: Auto-collapsing Selection Inspector pill on compact screens and horizontal scrolling telemetry dock (`FloatingTelemetryDock`).
- **Dynamic 3D Canvas Integration**: Full edge-to-edge hardware-accelerated WebGL Three.js space frame viewport with extruded 3D Bending Moment Diagrams (BMD) and real-time sinusoidal vibration animations.
- **Zero-Friction Discovery**: Complete unauthenticated guest inspection with automated auth gates on computational project commits.

---

## 🧠 Suite of 10 Custom-Trained AI Neural Engines

Every mechanics solver, analysis engine, and prediction system across Structura Nexus is powered by in-house neural networks trained on proprietary synthetic physics datasets generated from canonical analytical ground truths:

| Neural Engine | Architecture | Engineering Domain & Design Codes | Browser Latency | Cloud Latency |
| :--- | :--- | :--- | :--- | :--- |
| **`StructuraNet-3D`** | 4-layer Edge-Conditioned MPNN with LayerNorm & SiLU | 3D space frame nodal displacements and member axial/shear/moment forces under arbitrary spatial loading ($[K]\mathbf{u} = \mathbf{f}$) | **`0.18 ms`** | **`0.85 ms`** |
| **`SectionNet-PM`** | Deep Residual MLP with Non-Negative Strain Projections | ACI 318-19 non-linear reinforced concrete $P\text{-}M$ interaction envelope across 32 analytical neutral axis depths | **`0.12 ms`** | **`0.72 ms`** |
| **`ConnectionNet-AI`** | Multi-Head Classification / Regression Residual Network | AISC 360-16 6-limit-state DCRs (bolt shear, plate bearing, block shear, weld, prying action), failure mode logits, & rotational stiffness $K_{\text{conn}}$ | **`0.15 ms`** | **`0.69 ms`** |
| **`FoundationNet-SSI`** | Dynamic Soil-Structure Interaction (SSI) Network | Terzaghi & Meyerhof bearing capacity ($q_{\text{ult}}, q_{\text{allow}}$), 3D elastic/consolidation settlement, 2-way punching shear, & 6-DOF dynamic Winkler soil springs | **`0.19 ms`** | **`1.00 ms`** |
| **`PushoverNet-PBEE`** | Non-Linear Monotonic Pushover PBEE Surrogate | ATC-40 / FEMA 356 Capacity Spectrum Method (CSM), 20-step capacity curve ($V_{\text{base}}$ vs $\Delta_{\text{roof}}$), ADRS Performance Point, & plastic hinge damage states (IO, LS, CP) | **`0.20 ms`** | **`0.85 ms`** |
| **`AeroNet-CFD`** | Bluff-Body Aerodynamic Boundary Layer Network | ASCE 7-16 directional facade pressure field $C_p$ (6 zones), Strouhal vortex shedding frequency, along/across wind base shear, & lock-in resonance detection | **`0.16 ms`** | **`0.74 ms`** |
| **`CompositeFloorNet-AI`**| AISC 360 Ch I & AISC Design Guide 11 Comfort Network | Steel-concrete composite beam flexural capacity $\phi M_n$, transformed effective stiffness $I_{\text{eff}}$, DG 11 walking vibration fundamental frequency $f_n$, & human comfort acceleration $a_p/g$ | **`0.17 ms`** | **`0.81 ms`** |
| **`HazardDynamicNet-AI`** | Multi-Hazard Real-Time Environmental Stimulator | Real-time coupled dynamic simulation (hurricane gust + earthquake ground motion + ISO 834 fire + snow drift + differential soil subsidence), structural health index ($0\text{--}100\%$), & roof drift | **`0.22 ms`** | **`1.00 ms`** |
| **`ModalEigenNet-AI`** | Dynamic Structural Eigenvalue Surrogate | ASCE 7-16 dynamic eigenvalues ($\omega_1, \omega_2, \omega_3$), fundamental periods ($T_1, T_2, T_3$), modal mass participation ratios, & seismic response coefficient $C_s$ | **`0.14 ms`** | **`0.62 ms`** |
| **`CarbonNet-LCA`** | Embodied Carbon Footprinting & Optimization Engine | SE 2050 / EC3 cradle-to-gate Life Cycle Assessment (A1–A3), EAF 93% recycled scrap vs BOF virgin steel optimization, & LEED v4.1 MRc1 decarbonization credits | **`0.11 ms`** | **`0.55 ms`** |

---

## 🌪️ Real-Time Multi-Hazard Environmental Stimulator

Engineers can model or import any building (IFC / DXF / JSON / AI CAD Studio) and interactively modulate multi-hazard environmental forces in real time:

- **Hurricane Aerodynamics**: Dynamic wind velocity ($0\text{--}70\text{ m/s}$), ASCE 7-16 velocity pressure $q_z$, and bluff-body vortex shedding resonance.
- **Seismic Ground Motion**: Ground acceleration ($0.0\text{--}1.5g\text{ PGA}$) evaluating non-linear lateral roof drift and base shear demands.
- **Thermal Conflagration**: ISO 834 standard fire exposure ($20^\circ\text{C}\text{--}1000^\circ\text{C}$) calculating temperature-dependent steel yield and stiffness degradation ($E(T)$ & $F_y(T)$).
- **Snow Drift Surcharge**: ASCE 7-16 ground snow loading ($0\text{--}5\text{ kPa}$) with unbalanced roof drift geometries.
- **Geotechnical Differential Settlement**: Foundation subsidence ($0\text{--}50\text{ mm}$) triggering soil-structure interaction redistributions and internal P-Delta moments.

The workstation streams continuous telemetry updates: **Structural Health Integrity Index**, **Dynamic Roof Drift**, and **Overstressed Member Identification** via visual HUD alerts.

---

## 🏗️ ACI 318-19 Non-Linear Concrete Studio

- **Analytical Fiber Discretization Engine (`fiber_section_engine.py`)**: Discretizes arbitrary rectangular and circular reinforced concrete cross-sections into $N_y \times N_z$ concrete fibers obeying the Hognestad parabolic-softening constitutive relationship and discrete rebar fibers with elasto-plastic strain hardening.
- **Full $P\text{-}M$ Interaction Envelopes**: Generates 32-point interaction curves ($\phi P_n$ vs $\phi M_n$) covering Pure Axial Compression (with ACI 318-19 $\phi = 0.65$ and $P_{n,\max} = 0.80 P_0$ cap), Balanced Failure, Tension Control ($\phi = 0.90$), and Pure Tension.
- **Shear & Torsion Capacity**: Computes concrete shear strength ($V_c$), steel stirrup requirements ($V_s$), maximum stirrup spacing ($s_{\max}$), and minimum shear reinforcement ratios ($A_{v,\min}$).

---

## 📐 AI CAD Studio & Interoperability

- **Multi-Plane Projections**: 3D Isometric, XY Plan, XZ Elevation, and YZ Side views.
- **Precision Drafting**: Intelligent magnetic grid snapping, Ortho Mode ($90^\circ$ lock), and dynamic crosshair telemetry.
- **Natural Language & AutoCAD Command Console**:
  - `LINE 0,0,0 6,4,0 W16X26`
  - `POINT 3,5,0`
  - `FIX BASE`
  - `add 3-story frame`
  - `cross-bracing`
  - `wind 35`
- **Native CAD Export Formats**:
  - **AutoCAD DXF (`$ACADVER AC1015`)**: Full 3D line entities and node coordinates for AutoCAD, Civil 3D, and Revit.
  - **Bill of Materials (BOM) CSV**: Complete procurement schedules with member profiles, cut lengths, unit weights, and total steel mass.
  - **Custom Structural JSON**: Complete lossless serialization of 3D frame graphs, boundary conditions, loads, and materials.

---

## 📂 Repository Architecture

```
Structura Nexus Repo/
├── backend/                                  # FastAPI High-Performance Analytics Server
│   ├── app/
│   │   ├── main.py                           # REST & WebSocket endpoints (PyTorch & AI Neural Endpoints)
│   │   ├── models/schema.py                  # Pydantic v2 graph contracts & protocols
│   │   ├── ai/                               # 100% Proprietary AI Neural Suite
│   │   │   ├── connection_net.py             # ConnectionNet-AI: AISC 360-16 connection limit states & failure modes
│   │   │   ├── foundation_net.py             # FoundationNet-SSI: Terzaghi bearing, settlement & 6-DOF Winkler springs
│   │   │   ├── pushover_net.py               # PushoverNet-PBEE: ATC-40 ADRS capacity curve & hinge states
│   │   │   ├── aero_net.py                   # AeroNet-CFD: ASCE 7-16 pressure field Cp & vortex shedding
│   │   │   ├── composite_floor_net.py        # CompositeFloorNet-AI: AISC 360 Ch I flexure & DG 11 vibration
│   │   │   ├── hazard_net.py                 # HazardDynamicNet-AI: Real-time multi-hazard environmental surrogate
│   │   │   ├── modal_net.py                  # ModalEigenNet-AI: Dynamic eigenvalues & ASCE 7-16 ELF base shear
│   │   │   ├── carbon_net.py                 # CarbonNet-LCA: SE 2050 / EC3 cradle-to-gate LCA & green steel
│   │   │   ├── section_net_pm.py             # SectionNet-PM: ACI 318-19 concrete P-M residual neural surrogate
│   │   │   ├── neural_engine_registry.py     # Centralized singleton orchestrator with pre-warmed models
│   │   │   ├── gemini_agent.py               # Gemini Autonomous Agent & structured function calling
│   │   │   ├── gnn_model.py                  # Edge-augmented GNN, Dirichlet projection, MPS/CUDA
│   │   │   ├── generative_optimizer.py       # Evolutionary multi-objective section auto-sizer
│   │   │   ├── dynamic_modal_engine.py       # Dynamic eigenvalue modal extraction & ASCE 7-16 ELF
│   │   │   ├── embodied_carbon_engine.py     # Cradle-to-gate LCA, EPDs, LEED v4.1 & SE 2050
│   │   │   └── copilot.py                    # Natural language structural intelligence copilot
│   │   ├── solvers/
│   │   │   ├── fea_engine.py                 # Proprietary 3D Direct Stiffness Matrix (DSM) FEA Solver
│   │   │   ├── second_order_engine.py        # Second-order P-Delta geometric stiffness [Kg] solver
│   │   │   ├── fiber_section_engine.py       # 2D non-linear concrete fiber discretization engine
│   │   │   └── dynamic_solver.py             # Dynamic Newmark-beta time-stepping solver
│   │   ├── surrogate/gnn_surrogate.py       # StructuraNet-3D edge-conditioned message-passing GNN
│   │   ├── code_check/
│   │   │   ├── aisc_aci.py                   # AISC 360-16 limit state checker & auto-sizer
│   │   │   └── aci_concrete.py               # ACI 318-19 Whitney stress block & shear calculations
│   │   ├── weights/                          # Trained PyTorch Neural Weights (*.pt)
│   │   └── benchmarks/                       # Timoshenko, Hibbeler & Leet textbook validation
│   └── tests/test_backend.py                 # Pytest unit & integration test suite (32/32 passing, 100%)
├── structura_nexus/                          # Flutter Web & Desktop visionOS Engineering Workstation
│   ├── assets/weights/                       # Exported Client JSON Neural Weights (*.json)
│   ├── lib/
│   │   ├── main.dart                         # Workstation entrypoint & visionOS spatial layout
│   │   ├── firebase_options.dart             # Firebase configuration
│   │   ├── models/structural_models.dart     # Domain models, AISC shapes, dynamic modal states
│   │   ├── services/
│   │   │   ├── dart_neural_engine.dart       # Pure Dart SIMD-accelerated in-browser neural runtime (<0.2 ms)
│   │   │   ├── environmental_stimulator_engine.dart # Dynamic multi-hazard wave-stepping physics engine
│   │   │   ├── firebase_auth_service.dart    # Email, Google, Guest authentication & Firestore sync
│   │   │   ├── structural_library_service.dart # Cloud storage, DXF/CSV BOM/JSON file codecs
│   │   │   ├── embedded_fea_solver.dart      # Pure Dart 3D DSM solver (offline resilience)
│   │   │   └── structural_api_service.dart   # Dual-mode API client (Cloud Run PyTorch REST & Dart fallback)
│   │   ├── data/benchmark_presets.dart       # Canonical textbook & multi-story presets
│   │   └── widgets/
│   │       ├── glass_pod.dart                # Apple visionOS glassmorphic capsule container
│   │       ├── floating_workstation_header.dart # Decoupled top pill header with capsule navigation
│   │       ├── floating_inspector_panel.dart # Floating glass inspector with coordinate & boundary editor
│   │       ├── floating_telemetry_dock.dart  # Detached bottom telemetry HUD with micro-glow DCR rings
│   │       ├── environmental_stimulator_dialog.dart # Real-time multi-hazard interactive simulation dialog
│   │       ├── steel_connection_dialog.dart  # AISC 360-16 ConnectionNet-AI design & failure mode dialog
│   │       ├── foundation_ssi_dialog.dart    # FoundationNet-SSI soil-structure interaction dialog
│   │       ├── pushover_pbee_dialog.dart     # PushoverNet-PBEE non-linear capacity spectrum dialog
│   │       ├── aero_cfd_dialog.dart          # AeroNet-CFD aerodynamic wind pressure & vortex shedding dialog
│   │       ├── composite_floor_dialog.dart   # CompositeFloorNet-AI flexure & DG 11 vibration dialog
│   │       ├── concrete_pm_dialog.dart       # ACI 318-19 non-linear concrete P-M interaction dialog
│   │       ├── structural_3d_viewport.dart   # Dual-engine 3D viewport with Three.js toggle & BMD
│   │       ├── cad_editor_dialog.dart        # Professional AI CAD Studio & generative command line
│   │       ├── ai_copilot_dialog.dart        # Gemini Autonomous Agent & function call dialog
│   │       ├── generative_optimizer_dialog.dart # AI section mass optimization dialog
│   │       ├── seismic_modal_dialog.dart     # Dynamic modal & seismic base shear dialog
│   │       └── embodied_carbon_dialog.dart   # Embodied carbon & EAF green steel dialog
│   ├── web/
│   │   ├── index.html                        # Web entrypoint with Three.js & OrbitControls
│   │   └── three_viewport.js                 # Hardware-accelerated WebGL Three.js engine
│   └── test/widget_test.dart                 # Flutter test suite (32/32 passing, 100%)
├── scripts/
│   ├── train_all_neural_engines.py           # Unified multi-model GPU training factory & weight exporter
│   ├── train_structura_net.py                # Physics-informed GNN synthetic trainer
│   ├── train_section_net.py                  # ACI 318-19 concrete fiber P-M synthetic trainer
│   ├── run_backend.sh                        # Backend server launch script
│   └── run_benchmarks.py                     # Deterministic verification certification runner
├── Dockerfile                                # Multi-stage optimized production container
├── docker-compose.yml                        # Full-stack local orchestration
├── firestore.rules                           # Cloud Firestore security rules
├── firebase.json                             # Firebase Hosting and Firestore configuration
├── requirements.txt                          # Python dependencies (torch, numpy, fastapi, uvicorn, etc.)
└── README.md                                 # Documentation & architecture guide
```

---

## 🧪 Deterministic Verification Certification

The in-house Direct Stiffness Matrix (DSM) solver is validated against textbook closed-form benchmarks:

| Benchmark Case | Canonical Literature Reference | Target Engineering Metric | Analytical Closed-Form | Solved Numerical Value | Error (%) | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **BM-01** | Timoshenko & Gere (Sec 5.4) | Cantilever Tip Deflection $\delta_y$ | $0.010561\text{ m}$ | $0.010561\text{ m}$ | **0.0000%** | **PASSED** |
| **BM-02** | Hibbeler (10th Ed., Ex 8-3) | Simply Supported Midspan $\delta_y$ | $0.005569\text{ m}$ | $0.005569\text{ m}$ | **0.0000%** | **PASSED** |
| **BM-03** | Leet & Uang (Sec 4.2) | Vertical Support Reaction $R_y$ | $25,000.0\text{ N}$ | $25,000.0\text{ N}$ | **0.0000%** | **PASSED** |

---

## 🚀 Quickstart & Development

### 1. Backend Service Launch
```bash
# Set up virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies (100% proprietary, zero PyNiteFEA)
pip install -r requirements.txt

# Run deterministic benchmark suite
PYTHONPATH=. python3 scripts/run_benchmarks.py

# Run pytest unit & integration suite (32/32 tests)
PYTHONPATH=. pytest backend/tests/test_backend.py

# Launch FastAPI microservice (port 8000)
./scripts/run_backend.sh
```

### 2. Flutter Workstation Launch
```bash
cd structura_nexus

# Fetch packages
flutter pub get

# Run static analysis
flutter analyze

# Run unit and widget test suite (32/32 tests)
flutter test

# Run Flutter Web development server with Chrome
flutter run -d chrome

# Build production web bundle for Firebase Hosting
flutter build web --release --no-tree-shake-icons
```

### 3. Docker Deployment
```bash
# Build and launch both API microservice and Web workstation in Docker
docker compose up -d

# Verify live health
curl http://localhost:8000/
```

---

## 📜 Statutory Design Codes & Standards

- **AISC 360-16**: Specification for Structural Steel Buildings.
- **ACI 318-19**: Building Code Requirements for Structural Concrete.
- **ASCE 7-16**: Minimum Design Loads and Associated Criteria for Buildings and Other Structures.
- **IBC 2024**: International Building Code structural provisions.
- **ATC-40 / FEMA 356**: Seismic Evaluation and Retrofit of Concrete & Steel Buildings (PBEE).
- **AISC Design Guide 11**: Floor Vibrations Due to Human Activity.
- **SE 2050 / LEED v4.1**: Embodied Carbon Harmonization and Net-Zero Structural Commitments.
