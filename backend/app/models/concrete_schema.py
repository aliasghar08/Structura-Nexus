"""
Structura Nexus: Concrete Column & Beam P-M Interaction Schema (ACI 318-19)
Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
"""

from typing import List, Dict, Optional, Any
from pydantic import BaseModel, Field


class ConcreteColumnPMRequest(BaseModel):
    b: float = Field(default=0.45, description="Column width in meters")
    h: float = Field(default=0.60, description="Column depth/height in meters")
    fc_mpa: float = Field(default=35.0, description="Concrete compressive strength f'c in MPa")
    fy_mpa: float = Field(default=420.0, description="Steel rebar yield strength fy in MPa")
    rebar_ratio: float = Field(default=0.022, description="Longitudinal rebar ratio rho = Ast / (b*h)")
    pu_kn: float = Field(default=1200.0, description="Factored axial load demand Pu in kN")
    mu_knm: float = Field(default=280.0, description="Factored moment demand Mu in kN*m")
    vu_kn: Optional[float] = Field(default=150.0, description="Factored shear demand Vu in kN")
    cover: Optional[float] = Field(default=0.04, description="Clear concrete cover in meters")
    tie_diameter: Optional[float] = Field(default=0.010, description="Stirrup tie diameter in meters")


class PMPoint(BaseModel):
    mn_knm: float
    pn_kn: float
    phi_mn_knm: float
    phi_pn_kn: float
    phi: float
    c_m: float
    eps_t: float


class ConcreteColumnPMResponse(BaseModel):
    b: float
    h: float
    fc_mpa: float
    fy_mpa: float
    rebar_ratio: float
    ast_mm2: float
    phi_p0_kn: float
    phi_pn_max_kn: float
    phi_mn_pure_bending_knm: float
    governing_dcr: float
    is_safe: bool
    shear_vc_kn: float
    shear_vs_kn: float
    phi_vn_kn: float
    stirrup_spacing_mm: float
    max_stirrup_spacing_mm: float
    interaction_envelope: List[PMPoint]
    nominal_points: List[List[float]]
    design_points: List[List[float]]
    operating_demand: Dict[str, float]
    latency_ms: float
    engine: str = "ACI_318_19_FIBER_ANALYTIC"


class ConcreteCrackCheckRequest(BaseModel):
    b: float = Field(default=0.35, description="Section width in meters")
    h: float = Field(default=0.60, description="Section total depth in meters")
    fc_mpa: float = Field(default=28.0, description="Concrete compressive strength f'c in MPa")
    fy_mpa: float = Field(default=420.0, description="Rebar yield strength fy in MPa")
    moment_service_knm: float = Field(default=120.0, description="Service flexural moment Ms in kN*m (1.0D + 1.0L)")
    axial_service_kn: float = Field(default=0.0, description="Service axial load in kN (compression positive)")
    bar_diameter_mm: float = Field(default=25.0, description="Longitudinal tension rebar diameter in mm")
    num_bars: int = Field(default=4, description="Number of tension reinforcement bars")
    cover_mm: float = Field(default=40.0, description="Concrete clear cover to tension face in mm")
    exposure_condition: str = Field(
        default="EXTERIOR_MOIST",
        description="INTERIOR_DRY | EXTERIOR_MOIST | DEICING_SALTS | WATER_RETAINING"
    )


class ConcreteCrackCheckResponse(BaseModel):
    status: str = "SUCCESS"
    is_compliant: bool
    computed_crack_width_mm: float
    allowable_crack_width_mm: float
    crack_width_dcr: float
    actual_bar_spacing_mm: float
    max_bar_spacing_mm: float
    spacing_dcr: float
    cracked_inertia_ratio: float  # I_cr / I_g
    exposure_condition: str
    code_governing: str = "ACI 318-19 Section 24.3.2 & ACI 224R-01"
    service_stress_fs_mpa: float
    effective_depth_d_mm: float
    neutral_axis_kd_mm: float

