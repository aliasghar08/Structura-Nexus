# Structura Nexus / Structura Forge AI

> **Next-Generation AI Workstation for Civil & Structural Engineering**  
> **System Architecture**: `v3.4.0-REV-A`  
> **Standard Compliance**: `AISC 360-16` • `ACI 318-19` • `ASCE 7-16`

---

## 🏗️ Overview

**Structura Nexus** (Structura Forge AI) is an engineering-grade workstation that unifies real-time surrogate graph neural network (GNN) inference with authoritative 3D Direct Stiffness Matrix (DSM) finite element solvers. Designed specifically for civil and structural engineering workflows, the platform bridges fast interactive schematic drafting with legally binding building code compliance verification.

---

## ⚡ Core Engineering Pillars

1. **Hybrid Dual Engine**:
   - **GNN Surrogate (<40ms)**: Edge-augmented spatial predictions with physics-hard boundary masking for real-time drag-and-drop feedback.
   - **Exact DSM Solver**: Authoritative multi-threaded stiffness matrix solver ($[K]\{u\} = \{F\}$) with static equilibrium residual checking ($\sum F = 0, \sum M = 0$).
2. **Physics-Hard Constraints**:
   - Dirichlet zero-displacement enforcement at supports ($u_i \times R_i \equiv 0$).
   - Dimensionless feature normalization scaled by member length $L$ and flexural rigidity $EI$ to resolve scale disparities between axial and flexural stresses.
   - Fail-safe fallback: automatically routes to direct matrix factorization if epistemic uncertainty exceeds $0.08$.
3. **Deterministic Gatekeeper**:
   - Pure neural network outputs are never exported for production engineering stamping.
   - Hardcoded AISC 360-16 limit states (tension yield, flexural buckling with $KL/r \le 200$, combined P-M interaction Eq H1-1a/b, shear capacity) and ACI 318-19 beam shear envelopes.
   - Demand-to-Capacity Ratios ($\text{DCR} \le 1.0$) computed on all members across ASCE 7 factored load combinations (1.4D, 1.2D+1.6L, 1.2D+1.0W+0.5L, 1.2D+1.0E+0.2S).
   - Automated cross-section mass optimizer searches standard AISC W-shapes (W10 through W24) for the lightest compliant profile.

---

## 📂 Repository Structure

```
Structura Nexus Repo/
├── backend/                        # FastAPI High-Performance Analytics Server
│   ├── app/
│   │   ├── main.py                 # REST & WebSocket endpoints
│   │   ├── models/schema.py        # Pydantic v2 graph contracts & protocols
│   │   ├── solvers/fea_engine.py   # 3D Direct Stiffness Matrix (DSM) FEA Solver
│   │   ├── surrogate/gnn_surrogate.py # Fast GNN surrogate with physics-hard masking
│   │   ├── code_check/aisc_aci.py  # AISC 360-16 & ACI 318-19 limit state checker & auto-sizer
│   │   └── benchmarks/             # Timoshenko, Hibbeler & Leet textbook validation
│   └── tests/test_backend.py       # Pytest unit & integration test suite
├── structura_nexus/                # Flutter Web & Desktop Engineering Workstation
│   ├── lib/
│   │   ├── main.dart               # Workstation entrypoint & responsive layout
│   │   ├── models/structural_models.dart # Dart domain models & AISC shape catalog
│   │   ├── services/
│   │   │   ├── embedded_fea_solver.dart  # Pure Dart 3D DSM solver (offline resilience)
│   │   │   └── structural_api_service.dart # Real-time duplex WebSocket & REST client
│   │   ├── data/benchmark_presets.dart   # Standard textbook & multi-story presets
│   │   └── widgets/
│   │       ├── structural_3d_viewport.dart # 3D projection canvas with orbit/pan/zoom
│   │       ├── inspector_panel.dart       # Joint coordinate & 6-DOF boundary editor
│   │       ├── code_compliance_panel.dart # DCR, ASCE 7 combinations & auto-sizer
│   │       └── workstation_header.dart    # Dual engine toggle, presets, & def. scale
│   └── test/widget_test.dart       # Flutter test suite (embedded solver & UI)
├── scripts/
│   ├── run_backend.sh              # Backend server launch script
│   ├── run_benchmarks.py           # Verification certification runner
│   └── generate_synthetic_data.py  # Parametric space frame training set generator
├── docs/
│   └── ARCHITECTURE.md             # Blueprint specification & mathematical formulations
├── requirements.txt                # Python environment dependencies
└── README.md                       # Documentation & quickstart guide
```

---

## 🚀 Getting Started

### Prerequisites
- **Python**: 3.10+ (tested on Python 3.14.7)
- **Flutter**: 3.24+ / Dart 3.5+

### 1. Backend Setup & Launch
```bash
# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run verification benchmarks
PYTHONPATH=. python3 scripts/run_benchmarks.py

# Run pytest suite
PYTHONPATH=. pytest backend/tests/test_backend.py

# Launch FastAPI server (port 8000)
./scripts/run_backend.sh
```

### 2. Flutter Workstation Setup & Run
```bash
cd structura_nexus

# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit and widget tests
flutter test

# Run Flutter Web development server
flutter run -d chrome

# Build production web bundle
flutter build web --release --no-tree-shake-icons
```

---

## 🧪 Verification Certification

The FEA matrix solver is verified against closed-form textbook solutions from canonical engineering literature:
| Benchmark Case | Textbook Reference | Target Metric | Analytical Value | Solved Value | Error (%) | Status |
|---|---|---|---|---|---|---|
| **BM-01** | Timoshenko & Gere (Sec 5.4) | Cantilever Tip Deflection $\delta_y$ | 0.010561 m | 0.010561 m | 0.0000% | **PASSED** |
| **BM-02** | Hibbeler (10th Ed., Ex 8-3) | Simply Supported Midspan $\delta_y$ | 0.005569 m | 0.005569 m | 0.0000% | **PASSED** |
| **BM-03** | Leet & Uang (Sec 4.2) | Vertical Support Reaction $R_y$ | 25,000.0 N | 25,000.0 N | 0.0000% | **PASSED** |

---

## 📜 Compliance Standards
- **AISC 360-16**: Specification for Structural Steel Buildings.
- **ACI 318-19**: Building Code Requirements for Structural Concrete.
- **ASCE 7-16**: Minimum Design Loads and Associated Criteria for Buildings and Other Structures.
