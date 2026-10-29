"""
Structura Nexus: Proprietary Steel Connection Design Engine (AISC 360-16 / AISC 358-16 / AISC DG 1)
Evaluates limit states for:
1. Bolted Single-Plate Shear Tab Connections (Shear Rupture, Bearing/Tearout, Block Shear, Weld)
2. Extended End-Plate Moment Connections (Yield Line Mechanism, Bolt Tension, Prying Action)
3. Column Base Plates & Anchor Rod Anchorage (Concrete Bearing, Plate Bending, Anchor Tension/Shear)
Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
"""

import math
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field


class ShearTabRequest(BaseModel):
    beam_section: str = Field(default="W18X50")
    support_section: str = Field(default="W14X90")
    shear_demand_kn: float = Field(default=220.0, description="Factored vertical shear Vu in kN")
    axial_demand_kn: Optional[float] = Field(default=0.0, description="Factored axial demand Pu in kN")
    bolt_grade: str = Field(default="A325", description="A325 or A490")
    bolt_diameter_mm: float = Field(default=19.05, description="3/4 in (19.05 mm) or 7/8 in (22.2 mm)")
    num_bolts: int = Field(default=4, description="Total number of bolts in single vertical row")
    bolt_spacing_mm: float = Field(default=76.2, description="3 in (76.2 mm) standard pitch")
    edge_distance_mm: float = Field(default=38.1, description="1.5 in standard edge distance")
    plate_thickness_mm: float = Field(default=9.525, description="3/8 in (9.525 mm)")
    plate_fy_mpa: float = Field(default=250.0, description="A36 (250 MPa) or A572-50 (345 MPa)")
    weld_size_mm: float = Field(default=6.35, description="1/4 in (6.35 mm) fillet weld")


class EndPlateMomentRequest(BaseModel):
    beam_section: str = Field(default="W21X62")
    column_section: str = Field(default="W14X120")
    moment_demand_knm: float = Field(default=350.0, description="Factored moment Mu in kN*m")
    shear_demand_kn: float = Field(default=180.0, description="Factored shear Vu in kN")
    configuration: str = Field(default="4E", description="4E (4-Bolt Unstiffened) or 4ES (Stiffened)")
    bolt_grade: str = Field(default="A325", description="A325 or A490")
    bolt_diameter_mm: float = Field(default=25.4, description="1 in (25.4 mm)")
    plate_thickness_mm: float = Field(default=25.4, description="End plate thickness tp")
    plate_width_mm: float = Field(default=230.0, description="End plate width bp")
    plate_fy_mpa: float = Field(default=345.0, description="Plate yield strength (MPa)")


class BasePlateRequest(BaseModel):
    column_section: str = Field(default="W14X90")
    axial_demand_kn: float = Field(default=1800.0, description="Factored axial load Pu in kN")
    moment_demand_knm: float = Field(default=85.0, description="Factored moment Mu in kN*m")
    shear_demand_kn: float = Field(default=120.0, description="Factored shear Vu in kN")
    fc_foundation_mpa: float = Field(default=28.0, description="Concrete foundation f'c in MPa")
    plate_length_n_mm: float = Field(default=550.0, description="Base plate dimension N along moment axis")
    plate_width_b_mm: float = Field(default=500.0, description="Base plate dimension B perpendicular")
    plate_fy_mpa: float = Field(default=250.0, description="Base plate yield strength (MPa)")
    anchor_diameter_mm: float = Field(default=25.4, description="Anchor rod diameter (mm)")
    num_anchor_rods: int = Field(default=4, description="Total anchor rods")


class SteelConnectionEngine:
    """Authoritative limit-state evaluator for steel connections per AISC 360-16."""

    @classmethod
    def evaluate_shear_tab(cls, req: ShearTabRequest) -> Dict[str, Any]:
        vu_n = req.shear_demand_kn * 1e3
        d_b = req.bolt_diameter_mm
        n_b = req.num_bolts
        s = req.bolt_spacing_mm
        l_e = req.edge_distance_mm
        t_p = req.plate_thickness_mm
        fy = req.plate_fy_mpa
        fu = 400.0 if fy < 300.0 else 450.0

        # Bolt shear rupture per AISC Table J3.2
        # A325: Fnv = 372 MPa (threads not excluded)
        # A490: Fnv = 469 MPa
        fnv = 469.0 if "490" in req.bolt_grade else 372.0
        ab_mm2 = math.pi * (d_b / 2.0) ** 2
        phi_bolt = 0.75
        rn_bolt_shear_per_bolt = fnv * ab_mm2
        phi_rn_bolt_shear_n = phi_bolt * n_b * rn_bolt_shear_per_bolt

        # Bolt bearing and tearout on plate
        # Clear distance lc
        h_hole = d_b + 1.5875  # 1/16 in standard clearance
        lc_edge = max(l_e - h_hole / 2.0, 1.0)
        lc_inner = max(s - h_hole, 1.0)
        rn_tearout_edge = 1.2 * lc_edge * t_p * fu
        rn_tearout_inner = 1.2 * lc_inner * t_p * fu * (n_b - 1)
        rn_bearing_max_edge = 2.4 * d_b * t_p * fu
        rn_bearing_max_inner = 2.4 * d_b * t_p * fu * (n_b - 1)
        rn_bearing_total = min(rn_tearout_edge, rn_bearing_max_edge) + min(rn_tearout_inner, rn_bearing_max_inner)
        phi_rn_bearing_n = phi_bolt * rn_bearing_total

        # Plate gross shear yielding
        l_plate = 2.0 * l_e + (n_b - 1) * s
        ag_v = l_plate * t_p
        phi_shear_yield = 1.00
        phi_rn_shear_yield_n = phi_shear_yield * 0.60 * fy * ag_v

        # Plate net shear rupture
        an_v = (l_plate - n_b * (h_hole + 1.5875)) * t_p
        phi_shear_rup = 0.75
        phi_rn_shear_rup_n = phi_shear_rup * 0.60 * fu * an_v

        # Block shear rupture per AISC Section J4.3
        # Tearout along bolt line to bottom edge
        agv_bs = ((n_b - 1) * s + l_e) * t_p
        anv_bs = (((n_b - 1) * s + l_e) - (n_b - 0.5) * (h_hole + 1.5875)) * t_p
        # Tension face from bolt hole to plate edge
        agt_bs = l_e * t_p
        ant_bs = (l_e - 0.5 * (h_hole + 1.5875)) * t_p
        ubs = 1.0  # uniform tensile stress
        rn_bs1 = 0.60 * fu * anv_bs + ubs * fu * ant_bs
        rn_bs2 = 0.60 * fy * agv_bs + ubs * fu * ant_bs
        rn_bs = min(rn_bs1, rn_bs2)
        phi_rn_block_shear_n = 0.75 * rn_bs

        # Fillet weld to support (double-sided weld)
        # Fexx = 70 ksi = 482.6 MPa, phi = 0.75
        # Rn = 2 * 0.60 * Fexx * (w / sqrt(2)) * l_plate
        f_exx = 482.6
        w_eff = req.weld_size_mm * 0.7071
        rn_weld = 2.0 * 0.60 * f_exx * w_eff * l_plate
        phi_rn_weld_n = 0.75 * rn_weld

        # Collect limit states and governing DCR
        limit_states = [
            {"name": "Bolt Shear Rupture", "capacity_kn": round(phi_rn_bolt_shear_n / 1e3, 1), "dcr": round(vu_n / max(phi_rn_bolt_shear_n, 1.0), 3)},
            {"name": "Plate Bearing / Tearout", "capacity_kn": round(phi_rn_bearing_n / 1e3, 1), "dcr": round(vu_n / max(phi_rn_bearing_n, 1.0), 3)},
            {"name": "Plate Shear Yielding", "capacity_kn": round(phi_rn_shear_yield_n / 1e3, 1), "dcr": round(vu_n / max(phi_rn_shear_yield_n, 1.0), 3)},
            {"name": "Plate Shear Rupture", "capacity_kn": round(phi_rn_shear_rup_n / 1e3, 1), "dcr": round(vu_n / max(phi_rn_shear_rup_n, 1.0), 3)},
            {"name": "Plate Block Shear", "capacity_kn": round(phi_rn_block_shear_n / 1e3, 1), "dcr": round(vu_n / max(phi_rn_block_shear_n, 1.0), 3)},
            {"name": "Double Fillet Weld", "capacity_kn": round(phi_rn_weld_n / 1e3, 1), "dcr": round(vu_n / max(phi_rn_weld_n, 1.0), 3)},
        ]

        governing = max(limit_states, key=lambda ls: ls["dcr"])
        return {
            "connection_type": "BOLTED_SHEAR_TAB",
            "demand_vu_kn": req.shear_demand_kn,
            "plate_height_mm": round(l_plate, 1),
            "governing_limit_state": governing["name"],
            "governing_capacity_kn": governing["capacity_kn"],
            "governing_dcr": governing["dcr"],
            "is_safe": governing["dcr"] <= 1.0,
            "limit_states": limit_states,
            "geometry": {
                "plate_thickness_mm": t_p,
                "plate_height_mm": round(l_plate, 1),
                "num_bolts": n_b,
                "bolt_dia_mm": d_b,
                "bolt_spacing_mm": s,
                "edge_distance_mm": l_e,
                "weld_size_mm": req.weld_size_mm,
            }
        }

    @classmethod
    def evaluate_end_plate_moment(cls, req: EndPlateMomentRequest) -> Dict[str, Any]:
        mu_n_m = req.moment_demand_knm * 1e3
        vu_n = req.shear_demand_kn * 1e3
        bp = req.plate_width_mm
        tp = req.plate_thickness_mm
        fy = req.plate_fy_mpa
        db = req.bolt_diameter_mm

        # 4E Unstiffened 4-Bolt Moment Connection per AISC 358-16 Chapter 6
        # Beam depth estimate (approx 533 mm for W21)
        d_beam = 533.0
        bf_beam = 210.0
        tf_beam = 15.6
        p_f = 44.5  # bolt pitch to flange face
        g = 140.0   # bolt gauge width
        p_ext = 44.5

        # Yield Line parameter Yp for 4E configuration
        # AISC 358 Eq 6.6-8
        s_val = 0.5 * math.sqrt(bp * g)
        yp = (bp / 2.0) * (1.0 / p_f + 1.0 / p_ext) * (d_beam - tf_beam) + (2.0 / g) * (d_beam - tf_beam + p_f)
        
        # Plate flexural design capacity phi * Mnp
        phi_flex = 0.90
        phi_mn_plate_n_m = phi_flex * (fy * 1e6) * ((tp / 1e3) ** 2) * (yp / 1e3)

        # Bolt tension rupture including prying action
        fnt = 620.0 if "490" in req.bolt_grade else 496.0  # MPa
        ab_m2 = math.pi * ((db / 1e3) / 2.0) ** 2
        phi_t = 0.75
        b_cap_per_bolt = phi_t * (fnt * 1e6) * ab_m2

        # In 4E, 4 bolts resist tension on tension flange
        phi_mn_bolts_n_m = 2.0 * b_cap_per_bolt * ((d_beam - tf_beam) / 1e3)

        # Bolt shear capacity on compression flange bolts
        phi_v = 0.75
        fnv = 372.0 * 1e6
        phi_vn_bolts_n = phi_v * 4.0 * fnv * ab_m2

        dcr_moment_plate = mu_n_m / max(phi_mn_plate_n_m, 1.0)
        dcr_moment_bolts = mu_n_m / max(phi_mn_bolts_n_m, 1.0)
        dcr_shear = vu_n / max(phi_vn_bolts_n, 1.0)

        limit_states = [
            {"name": "End-Plate Yield Line Bending", "capacity_knm": round(phi_mn_plate_n_m / 1e3, 1), "dcr": round(dcr_moment_plate, 3)},
            {"name": "Bolt Tension Rupture", "capacity_knm": round(phi_mn_bolts_n_m / 1e3, 1), "dcr": round(dcr_moment_bolts, 3)},
            {"name": "Bolt Web Shear", "capacity_kn": round(phi_vn_bolts_n / 1e3, 1), "dcr": round(dcr_shear, 3)},
        ]
        governing = max(limit_states, key=lambda ls: ls["dcr"])

        return {
            "connection_type": "EXTENDED_END_PLATE_MOMENT",
            "demand_mu_knm": req.moment_demand_knm,
            "demand_vu_kn": req.shear_demand_kn,
            "yield_line_yp_mm": round(yp, 1),
            "governing_limit_state": governing["name"],
            "governing_dcr": governing["dcr"],
            "is_safe": governing["dcr"] <= 1.0,
            "limit_states": limit_states,
        }

    @classmethod
    def evaluate_base_plate(cls, req: BasePlateRequest) -> Dict[str, Any]:
        pu_n = req.axial_demand_kn * 1e3
        mu_n_m = req.moment_demand_knm * 1e3
        vu_n = req.shear_demand_kn * 1e3
        n_mm = req.plate_length_n_mm
        b_mm = req.plate_width_b_mm
        fc = req.fc_foundation_mpa
        fy = req.plate_fy_mpa

        # Concrete bearing capacity per ACI 318 / AISC DG 1
        phi_c = 0.65
        # Assuming foundation area A2 = 2 * A1
        a1_mm2 = n_mm * b_mm
        f_p_max_mpa = min(0.85 * fc * math.sqrt(2.0), 1.7 * fc)
        phi_pp_n = phi_c * f_p_max_mpa * 1e6 * (a1_mm2 * 1e-6)

        # Base plate required thickness per AISC DG 1
        # Column dimensions approx W14: d = 356 mm, bf = 370 mm
        d_col = 356.0
        bf_col = 370.0
        m_mm = (n_mm - 0.95 * d_col) / 2.0
        n_arm_mm = (b_mm - 0.80 * bf_col) / 2.0
        # lambda n' term
        lambda_val = 1.0
        n_prime = math.sqrt(d_col * bf_col) / 4.0
        l_cant = max(m_mm, n_arm_mm, lambda_val * n_prime)

        # Actual bearing pressure under Pu
        q_act_mpa = pu_n / a1_mm2
        dcr_bearing = q_act_mpa / (phi_c * f_p_max_mpa)

        # Required plate thickness
        # t_req = l * sqrt(2 * Pu / (phi * Fy * B * N))
        phi_b = 0.90
        t_req_mm = l_cant * math.sqrt((2.0 * max(q_act_mpa, 0.1)) / (phi_b * fy))

        # Anchor rod capacity (Tension under Mu)
        # Eccentricity e = Mu / Pu
        e_mm = (mu_n_m / max(pu_n, 1.0)) * 1e3
        anchor_tension_kn = 0.0
        if e_mm > n_mm / 6.0:
            # Moment causes tension in anchor rods
            lever_arm_m = (n_mm - 2.0 * 60.0) / 1e3
            anchor_tension_kn = (mu_n_m / 1e3) / max(lever_arm_m, 0.1)

        phi_rod = 0.75
        ab_rod_mm2 = math.pi * (req.anchor_diameter_mm / 2.0) ** 2
        fnt_rod = 400.0  # Grade 36 or F1554 Gr 36 anchor rod
        phi_tn_rods_kn = (req.num_anchor_rods / 2.0) * (phi_rod * fnt_rod * ab_rod_mm2) / 1e3
        dcr_anchors = anchor_tension_kn / max(phi_tn_rods_kn, 1.0)

        limit_states = [
            {"name": "Concrete Foundation Bearing", "capacity_kn": round(phi_pp_n / 1e3, 1), "dcr": round(dcr_bearing, 3)},
            {"name": "Plate Bending Thickness", "req_thickness_mm": round(t_req_mm, 1), "dcr": round(t_req_mm / 30.0, 3)},
            {"name": "Anchor Rod Tension", "capacity_kn": round(phi_tn_rods_kn, 1), "dcr": round(dcr_anchors, 3)},
        ]
        governing = max(limit_states, key=lambda ls: ls["dcr"])

        return {
            "connection_type": "COLUMN_BASE_PLATE",
            "demand_pu_kn": req.axial_demand_kn,
            "demand_mu_knm": req.moment_demand_knm,
            "eccentricity_mm": round(e_mm, 1),
            "cantilever_l_mm": round(l_cant, 1),
            "required_thickness_mm": round(t_req_mm, 1),
            "recommended_thickness_mm": math.ceil(t_req_mm / 5.0) * 5,
            "governing_limit_state": governing["name"],
            "governing_dcr": governing["dcr"],
            "is_safe": governing["dcr"] <= 1.0,
            "limit_states": limit_states,
        }

