"""
Structura Nexus: Geotechnical Soil-Structure Interaction (SSI) & Foundation Engine
Implements:
1. Meyerhof / Terzaghi Ultimate Bearing Capacity (Nc, Nq, Ngamma factors with shape/depth adjustments)
2. ACI 318-19 Punching Shear & One-Way Beam Shear
3. Footing Flexural Reinforcement Design (Mu, As_min, As_req)
4. Winkler Subgrade Modulus & 6-DOF Elastic Foundation Spring Matrix (Kx, Ky, Kz, Ktheta)
5. Elastic Settlement Evaluation (Bowles / Schleicher equation)
Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
"""

import math
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field


class FootingDesignRequest(BaseModel):
    axial_load_kn: float = Field(default=1600.0, description="Factored axial load Pu in kN")
    moment_x_knm: float = Field(default=120.0, description="Factored moment Mx in kN*m")
    moment_y_knm: float = Field(default=80.0, description="Factored moment My in kN*m")
    shear_h_kn: float = Field(default=95.0, description="Factored lateral shear Vu in kN")
    soil_friction_angle_deg: float = Field(default=32.0, description="Soil internal friction angle phi (degrees)")
    soil_cohesion_kpa: float = Field(default=10.0, description="Cohesion c in kPa")
    soil_unit_weight_kn_m3: float = Field(default=19.0, description="Total soil unit weight gamma (kN/m^3)")
    foundation_depth_m: float = Field(default=1.5, description="Depth of foundation embedment Df (m)")
    footing_length_m: float = Field(default=2.8, description="Footing length L in meters")
    footing_width_m: float = Field(default=2.8, description="Footing width B in meters")
    footing_thickness_m: float = Field(default=0.65, description="Footing slab thickness T in meters")
    column_width_m: float = Field(default=0.45, description="Pedestal/column dimension c1 in meters")
    column_depth_m: float = Field(default=0.45, description="Pedestal/column dimension c2 in meters")
    fc_concrete_mpa: float = Field(default=30.0, description="Concrete compressive strength f'c (MPa)")
    fy_rebar_mpa: float = Field(default=420.0, description="Steel rebar yield strength fy (MPa)")
    subgrade_modulus_kn_m3: float = Field(default=45000.0, description="Winkler modulus ks (kN/m^3)")


class GeotechnicalSSIEngine:
    """Authoritative Foundation and Soil-Structure Interaction Evaluator."""

    @classmethod
    def evaluate_footing(cls, req: FootingDesignRequest) -> Dict[str, Any]:
        phi_rad = math.radians(req.soil_friction_angle_deg)
        c = req.soil_cohesion_kpa
        gamma = req.soil_unit_weight_kn_m3
        df = req.foundation_depth_m
        b = req.footing_width_m
        l = req.footing_length_m
        t = req.footing_thickness_m
        c1 = req.column_width_m
        c2 = req.column_depth_m
        fc = req.fc_concrete_mpa
        fy = req.fy_rebar_mpa

        # Self weight of footing & soil overburden
        vol_concrete = b * l * t
        w_concrete_kn = vol_concrete * 24.0
        vol_soil = b * l * max(df - t, 0.0)
        w_soil_kn = vol_soil * gamma
        total_p_service = (req.axial_load_kn / 1.4) + w_concrete_kn + w_soil_kn
        total_pu = req.axial_load_kn + 1.2 * w_concrete_kn + 1.2 * w_soil_kn

        # 1. Meyerhof Bearing Capacity Factors (AASHTO / Bowles)
        # Nq = exp(pi * tan(phi)) * tan^2(45 + phi/2)
        nq = math.exp(math.pi * math.tan(phi_rad)) * (math.tan(math.radians(45.0 + req.soil_friction_angle_deg / 2.0)) ** 2)
        nc = (nq - 1.0) / max(math.tan(phi_rad), 1e-4) if req.soil_friction_angle_deg > 0 else 5.14
        # Meyerhof Ngamma = (Nq - 1) * tan(1.4 * phi)
        ngamma = (nq - 1.0) * math.tan(1.4 * phi_rad)

        # Shape factors (Meyerhof)
        sc = 1.0 + 0.2 * (b / l) * (math.tan(math.radians(45.0 + req.soil_friction_angle_deg / 2.0)) ** 2)
        sq = 1.0 + 0.1 * (b / l) * (math.tan(math.radians(45.0 + req.soil_friction_angle_deg / 2.0)) ** 2)
        sgamma = sq

        # Ultimate bearing capacity q_ult (kPa)
        q_overburden = gamma * df
        q_ult_kpa = (c * nc * sc) + (q_overburden * nq * sq) + (0.5 * gamma * b * ngamma * sgamma)
        safety_factor = 3.0
        q_allowable_kpa = q_ult_kpa / safety_factor

        # Base contact pressure distribution
        area = b * l
        ex = req.moment_x_knm / max(req.axial_load_kn, 1.0)
        ey = req.moment_y_knm / max(req.axial_load_kn, 1.0)
        kern_x = l / 6.0
        kern_y = b / 6.0
        within_kern = (ex <= kern_x) and (ey <= kern_y)

        # Max soil pressure under service load
        q_max_service_kpa = (total_p_service / area) * (1.0 + (6.0 * ex / l) + (6.0 * ey / b))
        q_min_service_kpa = (total_p_service / area) * (1.0 - (6.0 * ex / l) - (6.0 * ey / b))
        dcr_bearing = q_max_service_kpa / max(q_allowable_kpa, 1.0)

        # Max factored soil pressure for structural concrete checks
        q_max_factored_kpa = (total_pu / area) * (1.0 + (6.0 * ex / l) + (6.0 * ey / b))

        # 2. ACI 318-19 Two-Way Punching Shear
        # Effective depth d
        cover_m = 0.075  # 75 mm for concrete cast against earth
        bar_dia_m = 0.020
        d_m = t - cover_m - bar_dia_m

        # Critical perimeter at d/2 from column face
        b0_m = 2.0 * ((c1 + d_m) + (c2 + d_m))
        area_punched = (c1 + d_m) * (c2 + d_m)
        vu_punch_kn = req.axial_load_kn - (q_max_factored_kpa * area_punched)

        # Nominal punching capacity per ACI 318-19 Table 22.6.5.2
        beta_c = max(c1, c2) / max(min(c1, c2), 1e-4)
        alpha_s = 40.0  # interior column
        vc1 = 0.33 * math.sqrt(fc) * 1e3 * b0_m * d_m
        vc2 = 0.17 * (1.0 + 2.0 / beta_c) * math.sqrt(fc) * 1e3 * b0_m * d_m
        vc3 = 0.083 * (alpha_s * d_m / b0_m + 2.0) * math.sqrt(fc) * 1e3 * b0_m * d_m
        vc_punch_kn = min(vc1, vc2, vc3)
        phi_punch = 0.75
        phi_vc_punch_kn = phi_punch * vc_punch_kn
        dcr_punching = vu_punch_kn / max(phi_vc_punch_kn, 1.0)

        # 3. ACI 318-19 One-Way Beam Shear
        # Critical section at d from column face
        cantilever_l = (l - c1) / 2.0
        shear_dist = max(cantilever_l - d_m, 0.0)
        vu_oneway_kn = q_max_factored_kpa * b * shear_dist
        vc_oneway_kn = 0.17 * math.sqrt(fc) * 1e3 * b * d_m
        phi_vc_oneway_kn = 0.75 * vc_oneway_kn
        dcr_oneway = vu_oneway_kn / max(phi_vc_oneway_kn, 1.0)

        # 4. Footing Flexural Design
        # Cantilever moment at column face
        mu_flex_knm = (q_max_factored_kpa * b * (cantilever_l ** 2)) / 2.0
        # Required rebar As
        # Mu = phi * As * fy * (d - a/2)
        phi_flex = 0.90
        # Initial estimate j approx 0.90
        as_req_mm2 = (mu_flex_knm * 1e6) / (phi_flex * fy * (0.90 * d_m * 1e3))
        as_min_mm2 = 0.0018 * b * 1e3 * t * 1e3  # Temperature and shrinkage per ACI 318
        as_design_mm2 = max(as_req_mm2, as_min_mm2)
        bar_area_mm2 = math.pi * ((bar_dia_m * 1e3) / 2.0) ** 2
        num_bars = math.ceil(as_design_mm2 / bar_area_mm2)

        # 5. Winkler Soil Springs Matrix & Elastic Settlement
        ks = req.subgrade_modulus_kn_m3
        kz_kn_m = ks * (b * l)
        kx_kn_m = 0.80 * kz_kn_m
        ky_kn_m = 0.80 * kz_kn_m
        # Rotational springs K_theta = ks * I_footing
        ix = (b * (l ** 3)) / 12.0
        iy = (l * (b ** 3)) / 12.0
        k_theta_x_knm_rad = ks * ix
        k_theta_y_knm_rad = ks * iy

        # Immediate elastic settlement (Bowles formula)
        # Se = q0 * B * (1 - nu^2) / Es * Is
        es_kpa = 35000.0  # typical medium-dense sand/stiff clay (35 MPa)
        nu_soil = 0.30
        shape_influence_is = 0.88  # flexible square footing
        settlement_elastic_mm = (q_max_service_kpa * b * (1.0 - nu_soil ** 2) / es_kpa) * shape_influence_is * 1000.0

        limit_states = [
            {"name": "Soil Bearing Capacity", "capacity_kpa": round(q_allowable_kpa, 1), "demand_kpa": round(q_max_service_kpa, 1), "dcr": round(dcr_bearing, 3)},
            {"name": "Two-Way Punching Shear", "capacity_kn": round(phi_vc_punch_kn, 1), "demand_kn": round(vu_punch_kn, 1), "dcr": round(dcr_punching, 3)},
            {"name": "One-Way Beam Shear", "capacity_kn": round(phi_vc_oneway_kn, 1), "demand_kn": round(vu_oneway_kn, 1), "dcr": round(dcr_oneway, 3)},
        ]
        governing = max(limit_states, key=lambda ls: ls["dcr"])

        return {
            "foundation_type": "ISOLATED_SPREAD_FOOTING",
            "footing_dimensions_m": [round(l, 2), round(b, 2), round(t, 2)],
            "q_ult_kpa": round(q_ult_kpa, 1),
            "q_allowable_kpa": round(q_allowable_kpa, 1),
            "q_max_service_kpa": round(q_max_service_kpa, 1),
            "q_min_service_kpa": round(q_min_service_kpa, 1),
            "within_kern_no_uplift": within_kern,
            "governing_limit_state": governing["name"],
            "governing_dcr": governing["dcr"],
            "is_safe": governing["dcr"] <= 1.0,
            "reinforcement": {
                "as_design_mm2": round(as_design_mm2, 1),
                "recommended_bars": f"{num_bars} x #6 (20mm) @ {round((b*1000)/(num_bars-1), 0)}mm",
                "moment_mu_knm": round(mu_flex_knm, 1),
            },
            "winkler_springs": {
                "vertical_kz_kn_m": round(kz_kn_m, 1),
                "lateral_kx_kn_m": round(kx_kn_m, 1),
                "rotational_ktheta_knm_rad": round(k_theta_x_knm_rad, 1),
            },
            "settlement": {
                "elastic_settlement_mm": round(settlement_elastic_mm, 1),
                "allowable_settlement_mm": 25.0,  # 25 mm (1 in) standard building limit
                "is_settlement_pass": settlement_elastic_mm <= 25.0,
            },
            "limit_states": limit_states,
        }

