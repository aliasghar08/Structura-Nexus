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

# ASCE 7-16 Lateral Loads Schemas
class ASCE7WindParameters(BaseModel):
    basic_wind_speed_m_s: float = Field(default=45.0, description="Basic wind speed V (m/s)")
    exposure_category: str = Field(default="B", description="Exposure category: B, C, or D")
    risk_category: str = Field(default="II", description="Risk category: I, II, III, or IV")
    direction: str = Field(default="+X", description="+X, -X, +Z, -Z")
    k_d: float = Field(default=0.85, description="Wind directionality factor Kd")
    k_zt: float = Field(default=1.0, description="Topographic factor Kzt")
    k_e: float = Field(default=1.0, description="Ground elevation factor Ke")
    gust_factor_g: float = Field(default=0.85, description="Gust-effect factor G")

class StoreyWindPressure(BaseModel):
    storey_index: int
    elevation_m: float
    kz: float
    qz_n_m2: float
    windward_pressure_n_m2: float
    leeward_pressure_n_m2: float
    total_storey_force_n: float

class ASCE7WindResponse(BaseModel):
    status: str = "SUCCESS"
    basic_wind_speed_m_s: float
    exposure_category: str
    risk_category: str
    direction: str
    velocity_pressures: List[StoreyWindPressure]
    total_base_wind_shear_n: float
    updated_nodes: List[NodeModel]

class ASCE7SeismicParameters(BaseModel):
    ss: float = Field(default=1.25, description="Mapped MCE_R short period spectral acceleration (g)")
    s1: float = Field(default=0.50, description="Mapped MCE_R 1-second spectral acceleration (g)")
    site_class: str = Field(default="D", description="Site class: A, B, C, D, or E")
    risk_category: str = Field(default="II", description="Risk category: I, II, III, or IV")
    r_factor: float = Field(default=8.0, description="Response modification coefficient R (e.g. 8.0 for SMF)")
    direction: str = Field(default="+X", description="+X or +Z")
    importance_factor_ie: Optional[float] = None
    approx_period_sec: Optional[float] = None

class StoreySeismicForce(BaseModel):
    storey_index: int
    elevation_m: float
    storey_weight_kn: float
    cvx: float
    lateral_force_kn: float
    storey_shear_kn: float

class ASCE7SeismicResponse(BaseModel):
    status: str = "SUCCESS"
    sds: float
    sd1: float
    importance_factor_ie: float
    fundamental_period_sec: float
    cs: float
    total_seismic_weight_kn: float
    base_shear_v_kn: float
    storey_forces: List[StoreySeismicForce]
    updated_nodes: List[NodeModel]

# Second-Order Geometric Nonlinearity & Buckling Schemas
class BucklingModeResult(BaseModel):
    mode_index: int
    eigenvalue_lambda: float
    critical_load_factor_alpha_cr: float
    sway_amplification_b2: float
    aisc_stability_status: str
    mode_shape: Dict[str, List[float]]

class SecondOrderAnalysisResponse(BaseModel):
    status: str = "SUCCESS"
    critical_load_factor_alpha_cr: float
    governing_mode_index: int
    sway_amplification_b2: float
    is_stable: bool
    second_order_max_drift_ratio: float
    buckling_modes: List[BucklingModeResult]
    p_delta_magnified_moments: Dict[str, float]
    p_delta_first_order_moments: Dict[str, float]
    second_order_converged: bool
    iterations_run: int

