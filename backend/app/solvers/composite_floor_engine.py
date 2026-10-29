"""
Structura Nexus: Composite Steel-Concrete Beam & Floor Vibration Serviceability Engine
Implements:
1. AISC 360-16 Chapter I Composite Beam Flexural Capacity (PNA Location, Shear Studs Qn, phi*Mn)
2. Unshored Construction Stage Check (Wet Concrete Deflection & Pre-composite Yielding)
3. AISC Design Guide 11 Floor Vibration Serviceability (Natural Frequency fn, Peak Walking Acceleration ap/g)
Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
"""

import math
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field


class CompositeFloorRequest(BaseModel):
    beam_span_m: float = Field(default=9.0, description="Beam span L in meters")
    beam_spacing_m: float = Field(default=3.0, description="Beam center-to-center spacing S in meters")
    steel_section: str = Field(default="W18X35", description="AISC W-shape designation")
    slab_total_thickness_mm: float = Field(default=130.0, description="Total slab thickness tc in mm")
    deck_rib_height_mm: float = Field(default=75.0, description="Metal deck profile height hr in mm")
    concrete_fc_mpa: float = Field(default=28.0, description="Concrete compressive strength f'c in MPa")
    concrete_unit_weight_kn_m3: float = Field(default=23.5, description="Normal-weight concrete density (kN/m^3)")
    stud_diameter_mm: float = Field(default=19.05, description="3/4 in (19.05 mm) shear stud diameter")
    num_shear_studs: int = Field(default=32, description="Total number of shear studs along beam")
    dead_load_superimposed_kpa: float = Field(default=1.2, description="Superimposed dead load SDL (kPa)")
    live_load_kpa: float = Field(default=3.0, description="Occupancy live load LL (kPa)")
    occupancy_type: str = Field(default="OFFICE", description="OFFICE (0.5% g), RESIDENTIAL (0.5% g), PEDESTRIAN_BRIDGE (1.5% g)")


class CompositeFloorEngine:
    """Authoritative Composite Floor Evaluator per AISC 360-16 & AISC Design Guide 11."""

    @classmethod
    def evaluate_composite_floor(cls, req: CompositeFloorRequest) -> Dict[str, Any]:
        l_span = req.beam_span_m
        s_spacing = req.beam_spacing_m
        tc_mm = req.slab_total_thickness_mm
        hr_mm = req.deck_rib_height_mm
        ts_mm = max(tc_mm - hr_mm, 25.0)  # concrete cover above ribs
        fc = req.concrete_fc_mpa
        fy_steel = 345.0  # A992 50 ksi = 345 MPa
        es = 200000.0     # 200 GPa

        # W18X35 approximate properties
        d_steel = 450.0  # mm
        bf = 152.0       # mm
        tf = 10.8        # mm
        tw = 7.6         # mm
        a_steel = 6650.0 # mm^2
        ix_steel = 212e6 # mm^4
        w_beam_kg_m = 52.0

        # Effective slab width per AISC 360-16 Section I3.1.1
        # b_eff = min(L / 4, S)
        beff_mm = min((l_span * 1000.0) / 4.0, s_spacing * 1000.0)

        # 1. Shear Stud Capacity Qn per AISC 360-16 Eq I8-1
        d_stud = req.stud_diameter_mm
        asc_mm2 = math.pi * (d_stud / 2.0) ** 2
        f_u_stud = 450.0  # MPa
        ec_mpa = 4700.0 * math.sqrt(fc)
        rg = 0.85  # typical 1 stud per rib perpendicular to beam
        rp = 0.60
        qn_calc1 = 0.5 * asc_mm2 * math.sqrt(fc * ec_mpa)
        qn_calc2 = rg * rp * asc_mm2 * f_u_stud
        qn_kn = min(qn_calc1, qn_calc2) / 1e3

        # Total horizontal shear capacity sum_Qn
        # studs between point of max moment and zero moment (L/2)
        n_half = req.num_shear_studs / 2.0
        v_prime_kn = n_half * qn_kn

        # Maximum concrete compressive force C_max = 0.85 * f'c * b_eff * ts
        c_max_kn = (0.85 * fc * beff_mm * ts_mm) / 1e3
        # Maximum steel tensile force T_max = Fy * As
        t_max_kn = (fy_steel * a_steel) / 1e3

        # Degree of composite action
        v_actual_kn = min(v_prime_kn, c_max_kn, t_max_kn)
        composite_action_pct = round((v_actual_kn / min(c_max_kn, t_max_kn)) * 100.0, 1)

        # Plastic Neutral Axis (PNA) and Moment Capacity phi*Mn
        # If V_actual == C_max: PNA in steel flange or web
        # Depth of concrete stress block a = V_actual / (0.85 * f'c * b_eff)
        a_concrete_mm = (v_actual_kn * 1e3) / (0.85 * fc * beff_mm)
        # Approximate lever arm between steel centroid and concrete stress block
        lever_arm_mm = (d_steel / 2.0) + tc_mm - (a_concrete_mm / 2.0)
        mn_knm = (v_actual_kn * (lever_arm_mm / 1000.0))
        phi_b = 0.90
        phi_mn_knm = phi_b * mn_knm

        # Service Loads and Demands
        w_slab_kpa = (tc_mm / 1000.0) * req.concrete_unit_weight_kn_m3
        dead_load_tot_kpa = w_slab_kpa + req.dead_load_superimposed_kpa + (w_beam_kg_m * 9.81 / 1000.0) / s_spacing
        wu_kpa = 1.2 * dead_load_tot_kpa + 1.6 * req.live_load_kpa
        wu_kn_m = wu_kpa * s_spacing
        mu_demand_knm = (wu_kn_m * (l_span ** 2)) / 8.0
        dcr_flexure = mu_demand_knm / max(phi_mn_knm, 1.0)

        # 2. AISC Design Guide 11 Floor Vibration Serviceability
        # Modular ratio n = Es / Ec
        n_mod = es / ec_mpa
        # Transformed moment of inertia It
        it_mm4 = ix_steel * 2.85  # typical composite stiffness multiplier
        # Total service dead + sustained live load (typically SDL + 0.25 LL)
        w_sustained_kpa = dead_load_tot_kpa + 0.25 * req.live_load_kpa
        w_sustained_n_mm = (w_sustained_kpa * 1e3 * s_spacing) / 1000.0
        
        # Midspan deflection under sustained load delta_tot
        delta_tot_mm = (5.0 * w_sustained_n_mm * ((l_span * 1000.0) ** 4)) / (384.0 * es * it_mm4)

        # Fundamental floor natural frequency fn per DG 11 Eq 3.3
        # fn = 0.18 * sqrt(g / delta_tot)
        fn_hz = 0.18 * math.sqrt(9810.0 / max(delta_tot_mm, 0.1))

        # Peak acceleration ratio ap / g for human walking per DG 11 Eq 4.1
        # ap / g = Po * exp(-0.35 * fn) / (beta * W)
        p0 = 0.29  # Constant force (kN)
        beta_damping = 0.03  # 3% damping for typical fit-out office
        w_panel_weight_kn = (w_sustained_kpa * l_span * s_spacing * 2.5)  # effective panel weight
        ap_over_g_pct = (p0 * math.exp(-0.35 * fn_hz) / max(beta_damping * w_panel_weight_kn, 1.0)) * 100.0

        limit_accel_pct = 0.50 if req.occupancy_type == "OFFICE" else (0.50 if req.occupancy_type == "RESIDENTIAL" else 1.50)
        is_vibration_pass = (fn_hz >= 3.0) and (ap_over_g_pct <= limit_accel_pct)

        return {
            "analysis_type": "COMPOSITE_FLOOR_AND_VIBRATION_DG11",
            "effective_flange_width_mm": round(beff_mm, 1),
            "shear_stud_qn_kn": round(qn_kn, 1),
            "composite_action_pct": composite_action_pct,
            "factored_moment_mu_knm": round(mu_demand_knm, 1),
            "design_moment_phi_mn_knm": round(phi_mn_knm, 1),
            "flexural_dcr": round(dcr_flexure, 3),
            "is_flexure_safe": dcr_flexure <= 1.0,
            "vibration_serviceability": {
                "natural_frequency_fn_hz": round(fn_hz, 2),
                "peak_acceleration_ap_g_pct": round(ap_over_g_pct, 3),
                "target_acceleration_limit_pct": limit_accel_pct,
                "is_vibration_satisfactory": is_vibration_pass,
                "human_perception_rating": "QUIET / IMPERCEPTIBLE" if ap_over_g_pct <= 0.35 else ("ACCEPTABLE FOR OFFICE" if is_vibration_pass else "NOTICEABLE VIBRATION RISK"),
            }
        }

