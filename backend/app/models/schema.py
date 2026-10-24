from typing import List, Dict, Optional, Any
from pydantic import BaseModel, Field

class NodeModel(BaseModel):
    id: str
    coords: List[float] = Field(..., description="[X, Y, Z] coordinates in meters")
    restraint: List[int] = Field(
        default=[0, 0, 0, 0, 0, 0],
        description="[Rx, Ry, Rz, Rmx, Rmy, Rmz] 1=fixed, 0=free"
    )
    loads: List[float] = Field(
        default=[0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        description="[Fx, Fy, Fz, Mx, My, Mz] forces in N, moments in N*m"
    )

class MemberModel(BaseModel):
    id: str
    i_node: str
    j_node: str
    section: str = Field(default="W14X48", description="AISC shape designation or parametric profile")
    material: str = Field(default="A992_STEEL", description="A992_STEEL, A36_STEEL, C4000_CONCRETE")
    releases: Optional[List[int]] = Field(
        default=[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        description="End releases for 12 local DOF (e.g. pinned ends)"
    )

class StructuralGraphPayload(BaseModel):
    session_id: str = "usr_structura_session"
    action: str = Field(
        default="INFER_AND_VERIFY",
        description="INFER_AND_VERIFY | INFER_SURROGATE | EXACT_SOLVE | OPTIMIZE_SECTIONS"
    )
    load_combination: str = Field(
        default="1.2D+1.6L",
        description="1.4D | 1.2D+1.6L | 1.2D+1.0W+0.5L | 1.2D+1.0E+0.2S"
    )
    nodes: List[NodeModel]
    members: List[MemberModel]
    global_context: Optional[Dict[str, Any]] = None

class NodeResult(BaseModel):
    id: str
    displacements: List[float] = Field(..., description="[ux, uy, uz, rx, ry, rz] in m and rad")
    reactions: List[float] = Field(..., description="[Rx, Ry, Rz, Rmx, Rmy, Rmz] in N and N*m")

class MemberResult(BaseModel):
    id: str
    i_node: str
    j_node: str
    length: float
    section: str
    axial_force: float = Field(..., description="Axial force N (positive = tension, negative = compression)")
    shear_y: float = Field(..., description="Max local shear force Vy in N")
    shear_z: float = Field(..., description="Max local shear force Vz in N")
    moment_y: float = Field(..., description="Max local bending moment My in N*m")
    moment_z: float = Field(..., description="Max local bending moment Mz in N*m")
    torsion: float = Field(..., description="Torsional moment T in N*m")
    max_deflection: float = Field(..., description="Peak relative flexural deflection in m")
    max_von_mises_stress_mpa: float = Field(..., description="Peak Von Mises stress in MPa")
    dcr_axial: float
    dcr_buckling: float
    dcr_combined: float
    dcr_shear: float
    governing_dcr: float
    slenderness_kl_r: float
    status: str = Field(..., description="PASS | FAIL | WARNING")
    recommended_section: Optional[str] = None
    bmd_points: Optional[List[Dict[str, float]]] = None
    sfd_points: Optional[List[Dict[str, float]]] = None

class EquilibriumResidual(BaseModel):
    sum_fx: float
    sum_fy: float
    sum_fz: float
    sum_mx: float
    sum_my: float
    sum_mz: float
    is_equilibrated: bool
    max_residual_n: float

class SolverResponse(BaseModel):
    session_id: str
    engine_type: str = Field(..., description="EXACT_FEA_PYNITE | SURROGATE_GNN | HYBRID_DUAL")
    status: str = "SUCCESS"
    inference_latency_ms: float
    nodes: List[NodeResult]
    members: List[MemberResult]
    equilibrium: EquilibriumResidual
    global_base_shear_n: float
    max_drift_ratio: float
    surrogate_uncertainty: Optional[float] = None
    code_compliance_summary: Dict[str, Any]

class NodeDisplacement(BaseModel):
    dx: float
    dy: float
    dz: float
    rx: float
    ry: float
    rz: float

class RealtimeSurrogatePredictionResponse(BaseModel):
    status: str = "SURROGATE_PREDICTION"
    max_deflection_mm: float
    displacements: Dict[str, NodeDisplacement]
    member_forces: Optional[Dict[str, List[float]]] = None
    solve_duration_ms: float
