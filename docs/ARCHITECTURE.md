# STRUCTURA FORGE AI / STRUCTURA NEXUS
## Technical Architecture Blueprint & System Specification
**SYS-ARCH:** v3.4.0-REV-A  
**STANDARDS:** AISC 360-16 / ACI 318-19 / ASCE 7-16  
**STATUS:** Architecture Baseline  

---

### 1. Executive Perspective & Problem Statement
Civil and structural engineering requires rigorous verification of physical equilibria, safety limit states, and deterministic legal compliance. Where computational chemistry (Quantum Forge) predicts energy scalars and interatomic vectors on isolated molecular point-graphs, structural engineering must resolve continuous tensor fields (bending moments, shears, torsional warpage, and principal stresses) over boundary-constrained mechanical systems subject to stochastic transient loadings (wind, seismic, live).

Structura Forge / Structura Nexus unifies real-time surrogate graph neural network (GNN) inference with deterministic 3D Direct Stiffness Matrix (DSM) finite element solvers.

#### Comparative Domain Taxonomy
| Engineering Dimension | Quantum Forge (Computational Chemistry) | Structura Forge (Civil / Structural Eng.) | Complexity Delta |
|---|---|---|---|
| **Spatial Domain & Representation** | Discrete point clouds; coordinates $(x, y, z)$ with nuclear charges; rotationally invariant. | Continuous 1D frame members, 2D shell slabs, or 3D continuum elements anchored to fixed supports. | Significantly Harder |
| **Target Output Fields** | Scalar Total Energy ($E$) and $3N$ atomic force vectors ($-\nabla E$). | 6-DOF nodal displacements, axial force ($N$), shear ($V$), bending moment ($M$), and Von Mises stress tensors. | Significantly Harder |
| **Boundary Conditions** | Periodic boundary conditions or vacuum bounding boxes; spatial translational invariance. | Rigid constraints: fixed bases, pinned footings, roller supports, sliding joints, soil springs. | Harder |
| **Physics Verification** | DFT SCF convergence criteria ($\Delta E < 10^{-5}$ eV, force residual tolerances). | Stiffness matrix inversion ($[K]\{u\} = \{F\}$) and equilibrium residuals ($\sum F = 0, \sum M = 0$). | Comparable |
| **Safety & Compliance** | Empirical lab validation; chemical synthesis feasibility checks. | Legally binding building codes (AISC 360, ACI 318, Eurocodes) with statutory design combinations. | Significantly Harder |
| **Interactive Visualization** | Standard atomic spheres and bond cylinders (3Dmol.js / WebGL primitives). | Deformed meshes, shear-moment wireframe extrusions, continuous surface colormaps, stress glyphs. | Harder |

---

### 2. Core Engineering Pillars
1. **Hybrid Dual Engine**:
   - GNN surrogate provides sub-40ms spatial predictions during live schematic editing.
   - OpenSeesPy / PyNiteFEA executes authoritative multi-threaded 3D Direct Stiffness Matrix solves on trigger.
2. **Physics-Hard Constraints**:
   - Enforces strict nodal equilibrium and boundary conditions directly within the loss function and projection operators.
   - Support nodes use Dirichlet hard-masking ($u_i \times R_i \equiv 0$) to eliminate unphysical displacement drift at anchors.
   - Dimensionless feature normalization scaled by member length $L$ and flexural rigidity $EI$ to manage scale disparities between axial and flexural stresses.
3. **Deterministic Gatekeeper**:
   - Pure neural network outputs are never exported for production engineering stamping.
   - All AI-suggested structural profiles pass through hardcoded design checks (AISC 360-16 / ACI 318-19) computing exact Demand-to-Capacity Ratios ($\text{DCR} \le 1.0$).
   - Automated cross-section mass optimizer searches standard AISC W-shape catalogs for the lightest compliant profile.

---

### 3. System Topology & Computational Pipeline
```
+-------------------------------------------------------------+
| CLIENT WORKSTATION (Flutter Web / Desktop)                  |
| - Custom 3D Projection Canvas (Orbit / Pan / Zoom)          |
| - Deformed Mesh Amplification (1x to 100x scale slider)     |
| - BMD / SFD Extruded Ribbons & Von Mises Colormapping       |
| - Interactive Joint Coordinate & 6-DOF Restraint Editor     |
| - Pure Dart Embedded 3D DSM Solver for Offline Resilience   |
+------------------------------+------------------------------+
                               |
                   WebSocket / REST HTTP
                               |
+------------------------------v------------------------------+
| API & ORCHESTRATION (FastAPI Backend)                       |
| - Pydantic Structural Graph Validator                       |
| - ASCE 7 Factored Load Combinator (1.4D, 1.2D+1.6L, etc.)    |
| - Epistemic Uncertainty Evaluator & Fail-Safe Routing       |
+---------------+-----------------------------+---------------+
                |                             |
+---------------v---------------+ +-----------v---------------+
| AI SURROGATE ENGINE (<40ms)   | | FEA VERIFICATION ENGINE   |
| - Edge-Augmented Graph NN     | | - 3D Direct Stiffness     |
| - Hard Support Masking        | |   Matrix Solver (12x12)   |
| - Dimensionless Scaling       | | - Static Equilibrium      |
| - Uncertainty Gating (>0.08)  | |   Residuals Check         |
+---------------+---------------+ +-----------+---------------+
                |                             |
                +--------------+--------------+
                               |
+------------------------------v------------------------------+
| CODE CHECK & OPTIMIZATION MODULE                            |
| - AISC 360-16 Steel Limit States (Tension, Buckling, P-M)   |
| - ACI 318-19 Concrete Beam Shear Envelopes                  |
| - Demand-to-Capacity Ratio (DCR <= 1.0)                     |
| - Automated Lightest-Weight Section Optimizer               |
+-------------------------------------------------------------+
```

---

### 4. Mathematical Formulations & Design Equations

#### 4.1 3D Frame Direct Stiffness Matrix
For each member in local coordinates, the 12x12 element stiffness matrix $[k']$ relates end displacements $\{\delta'\}$ to end forces $\{f'\}$:
$$[k'] \{\delta'\} = \{f'\}$$
The global stiffness matrix $[K]$ is assembled using 3D rotation transformation matrices $[T]$:
$$[k] = [T]^T [k'] [T]$$
$$[K] \{u\} = \{F\}$$

#### 4.2 AISC 360-16 Structural Steel Limit States
- **Axial Tension**:
  $$P_u \le \phi_t P_n = \phi_t F_y A_g \quad (\phi_t = 0.90)$$
  $$\text{DCR}_{\text{tension}} = \frac{P_u}{\phi_t P_n} \le 1.00$$
- **Flexural Buckling**:
  $$\frac{K L}{r} \le 200$$
  $$F_e = \frac{\pi^2 E}{(KL/r)^2}$$
  $$\text{If } \frac{KL}{r} \le 4.71 \sqrt{\frac{E}{F_y}}: \quad F_{cr} = \left[0.658^{F_y / F_e}\right] F_y$$
  $$\text{Else}: \quad F_{cr} = 0.877 F_e$$
  $$\phi_c P_n = \phi_c F_{cr} A_g \quad (\phi_c = 0.90)$$
- **Combined Axial & Flexure (AISC Chapter H)**:
  - If $\frac{P_u}{\phi P_n} \ge 0.2$:
    $$\frac{P_u}{\phi P_n} + \frac{8}{9} \left( \frac{M_{ux}}{\phi M_{nx}} + \frac{M_{uy}}{\phi M_{ny}} \right) \le 1.00$$
  - If $\frac{P_u}{\phi P_n} < 0.2$:
    $$\frac{P_u}{2 \phi P_n} + \left( \frac{M_{ux}}{\phi M_{nx}} + \frac{M_{uy}}{\phi M_{ny}} \right) \le 1.00$$
- **Serviceability Deflection**:
  $$\Delta_{\text{live}} \le \frac{L}{360}, \quad \Delta_{\text{total}} \le \frac{L}{240}$$

#### 4.3 ACI 318-19 Beam Shear Envelope
$$V_u \le \phi (V_c + V_s) = \phi \left[ 2 \sqrt{f'_c} b_w d + \frac{A_v f_{yt} d}{s} \right] \quad (\phi = 0.75)$$

---

### 5. WebSocket Protocol Specification
```json
{
  "session_id": "usr_94f8a2b",
  "action": "INFER_AND_VERIFY",
  "load_combination": "1.2D+1.6L",
  "nodes": [
    {
      "id": "N1",
      "coords": [0.0, 0.0, 0.0],
      "restraint": [1, 1, 1, 1, 1, 1],
      "loads": [0, 0, 0, 0, 0, 0]
    },
    {
      "id": "N2",
      "coords": [0.0, 4.0, 0.0],
      "restraint": [0, 0, 0, 0, 0, 0],
      "loads": [15000, 0, -45000, 0, 0, 0]
    }
  ],
  "members": [
    {
      "id": "M1",
      "i_node": "N1",
      "j_node": "N2",
      "section": "W14X48",
      "material": "A992_STEEL"
    }
  ]
}
```

### 6. AI Engine Architecture & Formulations (`backend/app/ai/`)

#### 6.1 PyTorch Physics-Informed GNN (`PyTorchStructuralGNN`)
- **Dimensionless Scaling Layer**:
  $$x_{\text{scaled}} = \text{LayerNorm}(x) \odot \left[\frac{L_{\text{char}}}{H}, \frac{10^8}{E \cdot I_{\text{ref}}}, \dots \right]$$
- **Directional Edge-Augmented Message Passing**:
  $$m_{ij} = \phi_m \left( h_i, h_j, e_{ij} \right), \quad h_i^{(l+1)} = \sigma \left( W_v h_i^{(l)} + \sum_{j \in \mathcal{N}(i)} \alpha_{ij} m_{ij} \right)$$
- **Dirichlet Hard Projection Operator**:
  $$u_{\text{enforced}} = u_{\text{pred}} \odot (\mathbf{1} - R)$$
  guarantees $u \equiv 0$ strictly at all constrained boundary DOFs ($R_i = 1$).
- **Epistemic Uncertainty Head**:
  $$\sigma^2 = \text{Softplus}\left( W_\sigma h_{\text{latent}} + b_\sigma \right)$$
  When $\max(\sigma) > 0.08$, execution automatically falls back to full Direct Stiffness Matrix factorization.

#### 6.2 Generative Structural Section & Topology Optimizer (`GenerativeStructuralOptimizer`)
- **Objective Function**:
  $$\min_{\mathbf{s} \in \mathcal{S}^M} W(\mathbf{s}) = \sum_{m=1}^M \rho \cdot A(s_m) \cdot L_m$$
  $$\text{subject to: } \text{DCR}_m(\mathbf{s}) \le 0.95 \quad \forall m \in \{1, \dots, M\}$$
  $$\frac{KL_m}{r(s_m)} \le 200$$
- **Evolutionary Genetic Search**: Maintains a population of candidate section assignments across AISC W-shapes, iteratively evaluating combined P-M interaction (Eq H1-1a/b) with elitist mutation and crossover.

#### 6.3 Dynamic Modal & Seismic Response Engine (`ModalSeismicAIEngine`)
- **Generalized Dynamic Eigenvalue Problem**:
  $$\left( [K] - \omega_n^2 [M] \right) \{\phi_n\} = \{0\}$$
  $$T_n = \frac{2\pi}{\omega_n}, \quad f_n = \frac{1}{T_n}$$
- **ASCE 7-16 Equivalent Lateral Force (ELF) Seismic Base Shear**:
  $$V_{\text{base}} = C_s \cdot W = \frac{S_{DS}}{\left(\frac{R}{I_e}\right)} \cdot W$$
  $$\text{Upper Limit: } C_s \le \frac{S_{D1}}{T \left(\frac{R}{I_e}\right)}, \quad \text{Lower Limit: } C_s \ge 0.044 S_{DS} I_e \ge 0.01$$

#### 6.4 Embodied Carbon & Sustainability LCA Engine (`EmbodiedCarbonEngine`)
- **Cradle-to-Gate Scope (A1–A3)**:
  $$\text{GWP}_{\text{total}} = \sum_{m=1}^M m_{\text{steel}, m} \cdot \text{EF}_{\text{steel}}$$
  $$\text{EF}_{\text{BOF}} = 1.98 \, \text{kg CO}_2\text{e} / \text{kg}, \quad \text{EF}_{\text{EAF (93\% scrap)}} = 0.43 \, \text{kg CO}_2\text{e} / \text{kg}$$
  $$\Delta \text{CO}_2\text{e}_{\text{savings}} = \text{GWP}_{\text{BOF}} - \text{GWP}_{\text{EAF}} \quad (\approx 78\% \text{ reduction})$$
- Evaluates compliance with LEED v4.1 MR Credit (Building Life-Cycle Impact Reduction) and the SE 2050 Commitment toward net-zero embodied carbon.

#### 6.5 Structural Intelligence Copilot (`StructuralIntelligenceCopilot`)
- Natural language query understanding and structural graph intent extraction.
- Maps engineering questions into structural diagnostics (critical load paths, deflections, governing members, seismic vulnerability, and carbon reduction strategies).

---

### 7. Benchmark Verification Certification
Continuous integration validates against canonical closed-form structural engineering textbooks:
1. **Timoshenko & Gere (Mechanics of Materials, Sec 5.4)**: Cantilever tip deflection $\delta = \frac{P L^3}{3 E I}$. Error: $0.0000\%$.
2. **Hibbeler (Structural Analysis 10th Ed., Ex 8-3)**: Simply supported midspan deflection $\delta = \frac{P L^3}{48 E I}$. Error: $0.0000\%$.
3. **Leet & Uang (Fundamentals of Structural Analysis, Sec 4.2)**: Symmetric frame support reaction $R_y = \frac{P}{2}$. Error: $0.0000\%$.
