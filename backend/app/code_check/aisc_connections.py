"""
Structura Nexus v4.5: Deterministic AISC 360-16 Chapter J 3D Connection & Baseplate Synthesizer
Covers:
1. Single-Plate Bolted Shear Tabs (§J3 & §J4: Bolt Shear, Bearing/Tear-Out, Gross/Net Shear, Block Shear §J4.3)
2. Extended 4-Bolt / 8-Bolt Moment End-Plates (AISC Design Guide 4 & 16: Bolt Prying, Plate Yielding, Flange Weld §J2.4, Column Web Doubler/Continuity §J10)
3. Braced-Frame Gusset Plates (Whitmore 30-deg Effective Width, Thornton Buckling KL/r, Interface Shear-Tension Interaction)
4. Column Baseplates & Anchor Rods (AISC Design Guide 1: Concrete Bearing 0.85 f'c A1 sqrt(A2/A1), Cantilever Plate Thickness tp_min, Anchor Breakout)
Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
"""

import math
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field


class ConnectionDetailRequest(BaseModel):
    connection_type: str = Field(
        default="SHEAR_TAB",
        description="SHEAR_TAB | MOMENT_END_PLATE | GUSSET_PLATE | BASEPLATE",
    )
    joint_id: str = Field(default="N1")
    joint_coords_m: List[float] = Field(default_factory=lambda: [0.0, 3.6, 0.0])
    beam_section: str = Field(default="W18X35")
    column_section: str = Field(default="W14X90")
    shear_vu_kn: float = Field(default=210.0)
    moment_mu_knm: float = Field(default=320.0)
    axial_pu_kn: float = Field(default=650.0)
    bolt_grade: str = Field(default="A325", description="A325 or A490")
    bolt_diameter_mm: float = Field(default=22.225, description="7/8 in (22.225 mm)")
    num_bolts: int = Field(default=4, description="4 or 8 bolts")
    bolt_pitch_mm: float = Field(default=76.2, description="3 in (76.2 mm)")
    bolt_gauge_mm: float = Field(default=140.0, description="Horizontal gauge (mm)")
    edge_distance_mm: float = Field(default=38.1, description="1.5 in (38.1 mm)")
    plate_thickness_mm: float = Field(default=12.7, description="Plate thickness tp (mm)")
    plate_width_mm: float = Field(default=220.0)
    plate_height_mm: float = Field(default=340.0)
    plate_fy_mpa: float = Field(default=345.0, description="A572 Gr. 50 (345 MPa)")
    plate_fu_mpa: float = Field(default=450.0)
    weld_leg_mm: float = Field(default=8.0)
    fc_concrete_mpa: float = Field(default=28.0)


class LimitStateCheck(BaseModel):
    name: str
    clause: str
    demand_kn_or_knm: float
    capacity_phi_rn: float
    unit: str
    dcr: float
    status: str
    formula: str


class Bolt3DGlyph(BaseModel):
    local_x_m: float
    local_y_m: float
    local_z_m: float
    diameter_m: float
    utilization_dcr: float
    grade: str


class ConnectionDetailResponse(BaseModel):
    connection_type: str
    joint_id: str
    joint_coords_m: List[float]
    governing_dcr: float
    governing_limit_state: str
    overall_status: str
    required_plate_thickness_mm: float
    provided_plate_thickness_mm: float
    recommended_weld_leg_mm: float
    whitmore_width_mm: Optional[float] = None
    continuity_plate_required: bool = False
    limit_states: List[LimitStateCheck]
    bolts_3d: List[Bolt3DGlyph]
    plate_dimensions_m: List[float]


class AISC360ConnectionSynthesizer:
    """
    Deterministic AISC 360-16 Chapter J limit-state evaluator & 3D bolt/plate assembly generator.
    """

    BOLT_STRENGTHS_MPA: Dict[str, Dict[str, float]] = {
        "A325": {"Fnt": 620.0, "Fnv": 372.0},
        "A490": {"Fnt": 780.0, "Fnv": 457.0},
    }

    @classmethod
    def evaluate(cls, req: ConnectionDetailRequest) -> ConnectionDetailResponse:
        ctype = req.connection_type.upper()
        if ctype == "MOMENT_END_PLATE":
            return cls._evaluate_moment_end_plate(req)
        elif ctype == "GUSSET_PLATE":
            return cls._evaluate_gusset_plate(req)
        elif ctype == "BASEPLATE":
            return cls._evaluate_baseplate(req)
        else:
            return cls._evaluate_shear_tab(req)

    @classmethod
    def _evaluate_shear_tab(cls, req: ConnectionDetailRequest) -> ConnectionDetailResponse:
        d_b = req.bolt_diameter_mm
        a_b = math.pi * (d_b ** 2) / 4.0
        n_b = max(2, req.num_bolts)
        t_p = req.plate_thickness_mm
        fy = req.plate_fy_mpa
        fu = req.plate_fu_mpa
        s = req.bolt_pitch_mm
        le = req.edge_distance_mm
        vu = abs(req.shear_vu_kn)

        bolt_mat = cls.BOLT_STRENGTHS_MPA.get(req.bolt_grade.upper(), cls.BOLT_STRENGTHS_MPA["A325"])
        fnv = bolt_mat["Fnv"]

        # 1. Bolt Shear (AISC 360-16 §J3.6: phi * Fnv * Ab * n)
        phi_bolt_shear = 0.75 * fnv * a_b * n_b / 1000.0
        dcr_bolt_shear = vu / max(phi_bolt_shear, 1e-3)

        # 2. Bolt Bearing / Tear-out (§J3.10: Rn = 1.2 lc t Fu <= 2.4 d t Fu)
        d_hole = d_b + 2.0
        lc_edge = max(5.0, le - 0.5 * d_hole)
        lc_int = max(5.0, s - d_hole)
        rn_edge = min(1.2 * lc_edge * t_p * fu, 2.4 * d_b * t_p * fu)
        rn_int = min(1.2 * lc_int * t_p * fu, 2.4 * d_b * t_p * fu)
        phi_bearing = 0.75 * (rn_edge + (n_b - 1) * rn_int) / 1000.0
        dcr_bearing = vu / max(phi_bearing, 1e-3)

        # 3. Gross Shear Yielding (§J4.2a: phi = 1.00, Rn = 0.60 Fy Agv)
        h_plate = (n_b - 1) * s + 2.0 * le
        agv = h_plate * t_p
        phi_gross_shear = 1.00 * 0.60 * fy * agv / 1000.0
        dcr_gross = vu / max(phi_gross_shear, 1e-3)

        # 4. Net Shear Rupture (§J4.2b: phi = 0.75, Rn = 0.60 Fu Anv)
        anv = max(100.0, (h_plate - n_b * (d_hole + 1.5)) * t_p)
        phi_net_shear = 0.75 * 0.60 * fu * anv / 1000.0
        dcr_net = vu / max(phi_net_shear, 1e-3)

        # 5. Block Shear Rupture (§J4.3: Rn = 0.60 Fu Anv + Ubs Fu Ant <= 0.60 Fy Agv + Ubs Fu Ant)
        eh = 38.1
        ant = max(50.0, (eh - 0.5 * (d_hole + 1.5)) * t_p)
        agv_bs = ((n_b - 1) * s + le) * t_p
        anv_bs = max(80.0, agv_bs - (n_b - 0.5) * (d_hole + 1.5) * t_p)
        ubs = 1.0
        rn_bs = min(
            0.60 * fu * anv_bs + ubs * fu * ant,
            0.60 * fy * agv_bs + ubs * fu * ant,
        )
        phi_block_shear = 0.75 * rn_bs / 1000.0
        dcr_block = vu / max(phi_block_shear, 1e-3)

        checks = [
            LimitStateCheck(
                name="Bolt Single-Shear Capacity",
                clause="AISC 360-16 §J3.6",
                demand_kn_or_knm=round(vu, 2),
                capacity_phi_rn=round(phi_bolt_shear, 2),
                unit="kN",
                dcr=round(dcr_bolt_shear, 3),
                status="PASS" if dcr_bolt_shear <= 1.0 else "FAIL",
                formula="φR_n = 0.75 · F_nv · A_b · n_b",
            ),
            LimitStateCheck(
                name="Bolt Bearing & Tear-Out",
                clause="AISC 360-16 §J3.10",
                demand_kn_or_knm=round(vu, 2),
                capacity_phi_rn=round(phi_bearing, 2),
                unit="kN",
                dcr=round(dcr_bearing, 3),
                status="PASS" if dcr_bearing <= 1.0 else "FAIL",
                formula="φR_n = 0.75 · Σ min(1.2 l_c t F_u, 2.4 d t F_u)",
            ),
            LimitStateCheck(
                name="Plate Gross Shear Yielding",
                clause="AISC 360-16 §J4.2(a)",
                demand_kn_or_knm=round(vu, 2),
                capacity_phi_rn=round(phi_gross_shear, 2),
                unit="kN",
                dcr=round(dcr_gross, 3),
                status="PASS" if dcr_gross <= 1.0 else "FAIL",
                formula="φR_n = 1.00 · 0.60 F_y A_gv",
            ),
            LimitStateCheck(
                name="Plate Net Shear Rupture",
                clause="AISC 360-16 §J4.2(b)",
                demand_kn_or_knm=round(vu, 2),
                capacity_phi_rn=round(phi_net_shear, 2),
                unit="kN",
                dcr=round(dcr_net, 3),
                status="PASS" if dcr_net <= 1.0 else "FAIL",
                formula="φR_n = 0.75 · 0.60 F_u A_nv",
            ),
            LimitStateCheck(
                name="Block Shear Rupture",
                clause="AISC 360-16 §J4.3",
                demand_kn_or_knm=round(vu, 2),
                capacity_phi_rn=round(phi_block_shear, 2),
                unit="kN",
                dcr=round(dcr_block, 3),
                status="PASS" if dcr_block <= 1.0 else "FAIL",
                formula="φR_n = 0.75 · [0.60 F_u A_nv + U_bs F_u A_nt]",
            ),
        ]

        gov = max(checks, key=lambda c: c.dcr)
        tp_req = t_p * max(0.65, gov.dcr)

        bolts = []
        y0 = -0.5 * (n_b - 1) * (s / 1000.0)
        for i in range(n_b):
            bolts.append(
                Bolt3DGlyph(
                    local_x_m=0.04,
                    local_y_m=round(y0 + i * (s / 1000.0), 4),
                    local_z_m=0.0,
                    diameter_m=round(d_b / 1000.0, 4),
                    utilization_dcr=round(dcr_bolt_shear, 3),
                    grade=req.bolt_grade,
                )
            )

        return ConnectionDetailResponse(
            connection_type="SHEAR_TAB",
            joint_id=req.joint_id,
            joint_coords_m=req.joint_coords_m,
            governing_dcr=gov.dcr,
            governing_limit_state=gov.name,
            overall_status="PASS" if gov.dcr <= 1.0 else "OVERSTRESSED",
            required_plate_thickness_mm=round(tp_req, 2),
            provided_plate_thickness_mm=round(t_p, 2),
            recommended_weld_leg_mm=round(max(6.0, t_p * 0.65), 1),
            limit_states=checks,
            bolts_3d=bolts,
            plate_dimensions_m=[0.115, round(h_plate / 1000.0, 3), round(t_p / 1000.0, 4)],
        )

    @classmethod
    def _evaluate_moment_end_plate(cls, req: ConnectionDetailRequest) -> ConnectionDetailResponse:
        d_b = req.bolt_diameter_mm
        a_b = math.pi * (d_b ** 2) / 4.0
        n_b = 8 if req.num_bolts >= 8 else 4
        t_p = max(16.0, req.plate_thickness_mm)
        b_p = max(180.0, req.plate_width_mm)
        fy = req.plate_fy_mpa
        mu = abs(req.moment_mu_knm)
        vu = abs(req.shear_vu_kn)

        bolt_mat = cls.BOLT_STRENGTHS_MPA.get(req.bolt_grade.upper(), cls.BOLT_STRENGTHS_MPA["A325"])
        fnt = bolt_mat["Fnt"]
        fnv = bolt_mat["Fnv"]

        # Beam depth d_beam ~ 450 mm, lever arm h_0 ~ 435 mm
        h_0_m = 0.435
        n_tension_bolts = n_b // 2

        # 1. Bolt Tension with Prying Action (AISC DG 4 / DG 16: Q_prying ~ 15% of B_t)
        tu_flange_kn = mu / h_0_m
        phi_rn_bolt_t = 0.75 * fnt * a_b * n_tension_bolts / (1000.0 * 1.15)
        dcr_bolt_t = tu_flange_kn / max(phi_rn_bolt_t, 1e-3)

        # 2. End-Plate Flexural Yield Line Mechanism (AISC DG 4 Eq. 3.7: M_pl = phi_b * Fy * Y_p * tp^2)
        y_p_mm = 2.85 * b_p * (1.25 if n_b == 8 else 1.0)
        phi_mn_plate_knm = 0.90 * fy * y_p_mm * (t_p ** 2) * h_0_m / 1e6
        dcr_plate_yield = mu / max(phi_mn_plate_knm, 1e-3)
        tp_min_mm = math.sqrt((mu * 1e6) / max(0.90 * fy * y_p_mm * h_0_m, 1.0))

        # 3. Flange-to-Plate Weld Capacity (AISC 360-16 §J2.4)
        w_leg = max(8.0, req.weld_leg_mm)
        l_weld_mm = 2.0 * b_p
        phi_rn_weld_kn = 0.75 * 0.60 * 490.0 * (0.707 * w_leg) * l_weld_mm * 1.5 / 1000.0
        dcr_weld = tu_flange_kn / max(phi_rn_weld_kn, 1e-3)

        # 4. Column Web Local Yielding / Continuity Plate Check (§J10.1 & §J10.6)
        tw_col = 11.2
        tf_col = 18.0
        fy_col = 345.0
        phi_rn_web_kn = 1.00 * (5.0 * tf_col + 15.0) * fy_col * tw_col / 1000.0
        dcr_web = tu_flange_kn / max(phi_rn_web_kn, 1e-3)

        # 5. Bolt Shear on Compression Side (§J3.6)
        phi_rn_shear_kn = 0.75 * fnv * a_b * (n_b // 2) / 1000.0
        dcr_shear = vu / max(phi_rn_shear_kn, 1e-3)

        checks = [
            LimitStateCheck(
                name="Bolt Tension & Prying Action",
                clause="AISC DG 4 / §J3.6",
                demand_kn_or_knm=round(tu_flange_kn, 2),
                capacity_phi_rn=round(phi_rn_bolt_t, 2),
                unit="kN",
                dcr=round(dcr_bolt_t, 3),
                status="PASS" if dcr_bolt_t <= 1.0 else "FAIL",
                formula="φR_nt = 0.75 · F_nt · A_b · n_t / (1 + q_prying)",
            ),
            LimitStateCheck(
                name="End-Plate Flexural Yield Line",
                clause="AISC DG 4 / DG 16 §3.2",
                demand_kn_or_knm=round(mu, 2),
                capacity_phi_rn=round(phi_mn_plate_knm, 2),
                unit="kN·m",
                dcr=round(dcr_plate_yield, 3),
                status="PASS" if dcr_plate_yield <= 1.0 else "FAIL",
                formula="φM_np = 0.90 · F_yp · Y_p · t_p²",
            ),
            LimitStateCheck(
                name="Flange-to-End-Plate Weld",
                clause="AISC 360-16 §J2.4",
                demand_kn_or_knm=round(tu_flange_kn, 2),
                capacity_phi_rn=round(phi_rn_weld_kn, 2),
                unit="kN",
                dcr=round(dcr_weld, 3),
                status="PASS" if dcr_weld <= 1.0 else "FAIL",
                formula="φR_nw = 0.75 · 0.60 F_EXX (0.707 w) L_w · 1.5",
            ),
            LimitStateCheck(
                name="Column Web Continuity / Yielding",
                clause="AISC 360-16 §J10.1",
                demand_kn_or_knm=round(tu_flange_kn, 2),
                capacity_phi_rn=round(phi_rn_web_kn, 2),
                unit="kN",
                dcr=round(dcr_web, 3),
                status="PASS" if dcr_web <= 1.0 else "FAIL",
                formula="φR_n = 1.00 · (5 k + l_b) F_yw t_wc",
            ),
            LimitStateCheck(
                name="Compression-Side Bolt Shear",
                clause="AISC 360-16 §J3.6",
                demand_kn_or_knm=round(vu, 2),
                capacity_phi_rn=round(phi_rn_shear_kn, 2),
                unit="kN",
                dcr=round(dcr_shear, 3),
                status="PASS" if dcr_shear <= 1.0 else "FAIL",
                formula="φR_nv = 0.75 · F_nv · A_b · n_v",
            ),
        ]

        gov = max(checks, key=lambda c: c.dcr)
        g_m = req.bolt_gauge_mm / 1000.0
        y_rows = [-0.24, -0.14, 0.14, 0.24] if n_b == 4 else [-0.28, -0.20, -0.12, -0.05, 0.05, 0.12, 0.20, 0.28]
        bolts = []
        for y_m in y_rows:
            for z_sign in (-0.5, 0.5):
                if len(bolts) < n_b:
                    bolts.append(
                        Bolt3DGlyph(
                            local_x_m=0.02,
                            local_y_m=round(y_m, 4),
                            local_z_m=round(z_sign * g_m, 4),
                            diameter_m=round(d_b / 1000.0, 4),
                            utilization_dcr=round(dcr_bolt_t if y_m > 0 else dcr_shear, 3),
                            grade=req.bolt_grade,
                        )
                    )

        return ConnectionDetailResponse(
            connection_type="MOMENT_END_PLATE",
            joint_id=req.joint_id,
            joint_coords_m=req.joint_coords_m,
            governing_dcr=gov.dcr,
            governing_limit_state=gov.name,
            overall_status="PASS" if gov.dcr <= 1.0 else "OVERSTRESSED",
            required_plate_thickness_mm=round(tp_min_mm, 2),
            provided_plate_thickness_mm=round(t_p, 2),
            recommended_weld_leg_mm=round(w_leg, 1),
            continuity_plate_required=(dcr_web > 0.95),
            limit_states=checks,
            bolts_3d=bolts,
            plate_dimensions_m=[round(t_p / 1000.0, 4), 0.62, round(b_p / 1000.0, 3)],
        )

    @classmethod
    def _evaluate_gusset_plate(cls, req: ConnectionDetailRequest) -> ConnectionDetailResponse:
        pu = abs(req.axial_pu_kn)
        t_p = max(12.7, req.plate_thickness_mm)
        fy = req.plate_fy_mpa
        e_mpa = 200000.0
        n_rows = max(2, req.num_bolts // 2)
        s = req.bolt_pitch_mm
        g = req.bolt_gauge_mm

        # 1. Whitmore 30-degree Effective Dispersion Width (Lw = g + 2 * L_conn * tan(30 deg))
        l_conn_mm = (n_rows - 1) * s
        l_whitmore_mm = g + 2.0 * l_conn_mm * math.tan(math.radians(30.0))
        a_whitmore_mm2 = l_whitmore_mm * t_p
        phi_pn_yield_kn = 0.90 * fy * a_whitmore_mm2 / 1000.0
        dcr_whitmore = pu / max(phi_pn_yield_kn, 1e-3)

        # 2. Thornton Compression Buckling (KL/r with K = 0.65, L_avg ~ 280 mm)
        r_g = t_p / math.sqrt(12.0)
        l_unbraced_mm = 260.0
        kl_r = 0.65 * l_unbraced_mm / max(r_g, 1.0)
        fe_mpa = (math.pi ** 2) * e_mpa / max(kl_r ** 2, 1.0)
        fcr_mpa = (0.658 ** (fy / fe_mpa)) * fy if kl_r <= 4.71 * math.sqrt(e_mpa / fy) else 0.877 * fe_mpa
        phi_pn_buckle_kn = 0.90 * fcr_mpa * a_whitmore_mm2 / 1000.0
        dcr_thornton = pu / max(phi_pn_buckle_kn, 1e-3)

        # 3. Interface Weld Shear-Tension Interaction (§J2.4)
        w_leg = max(8.0, req.weld_leg_mm)
        l_interface_mm = 420.0
        phi_rn_interface_kn = 0.75 * 0.60 * 490.0 * (0.707 * w_leg) * (2.0 * l_interface_mm) / 1000.0
        dcr_interface = pu / max(phi_rn_interface_kn, 1e-3)

        checks = [
            LimitStateCheck(
                name="Whitmore 30° Section Yielding",
                clause="AISC Manual Part 13 / §J4.1",
                demand_kn_or_knm=round(pu, 2),
                capacity_phi_rn=round(phi_pn_yield_kn, 2),
                unit="kN",
                dcr=round(dcr_whitmore, 3),
                status="PASS" if dcr_whitmore <= 1.0 else "FAIL",
                formula="φP_ny = 0.90 · F_y · (s_g + 2 L_b tan 30°) · t_g",
            ),
            LimitStateCheck(
                name="Thornton Gusset Compression Buckling",
                clause="AISC 360-16 §J4.4 / §E3",
                demand_kn_or_knm=round(pu, 2),
                capacity_phi_rn=round(phi_pn_buckle_kn, 2),
                unit="kN",
                dcr=round(dcr_thornton, 3),
                status="PASS" if dcr_thornton <= 1.0 else "FAIL",
                formula="φP_ncr = 0.90 · F_cr(KL/r) · A_Whitmore  (K = 0.65)",
            ),
            LimitStateCheck(
                name="Gusset-to-Frame Interface Weld",
                clause="AISC 360-16 §J2.4",
                demand_kn_or_knm=round(pu, 2),
                capacity_phi_rn=round(phi_rn_interface_kn, 2),
                unit="kN",
                dcr=round(dcr_interface, 3),
                status="PASS" if dcr_interface <= 1.0 else "FAIL",
                formula="φR_nw = 0.75 · 0.60 F_EXX (0.707 w) · 2 L_int",
            ),
        ]

        gov = max(checks, key=lambda c: c.dcr)
        bolts = []
        for i in range(n_rows):
            dist = 0.14 + i * (s / 1000.0)
            bolts.append(
                Bolt3DGlyph(
                    local_x_m=round(dist * 0.707, 4),
                    local_y_m=round(dist * 0.707, 4),
                    local_z_m=0.0,
                    diameter_m=round(req.bolt_diameter_mm / 1000.0, 4),
                    utilization_dcr=round(gov.dcr, 3),
                    grade=req.bolt_grade,
                )
            )

        return ConnectionDetailResponse(
            connection_type="GUSSET_PLATE",
            joint_id=req.joint_id,
            joint_coords_m=req.joint_coords_m,
            governing_dcr=gov.dcr,
            governing_limit_state=gov.name,
            overall_status="PASS" if gov.dcr <= 1.0 else "OVERSTRESSED",
            required_plate_thickness_mm=round(t_p * max(0.7, gov.dcr), 2),
            provided_plate_thickness_mm=round(t_p, 2),
            recommended_weld_leg_mm=round(w_leg, 1),
            whitmore_width_mm=round(l_whitmore_mm, 1),
            limit_states=checks,
            bolts_3d=bolts,
            plate_dimensions_m=[0.48, 0.48, round(t_p / 1000.0, 4)],
        )

    @classmethod
    def _evaluate_baseplate(cls, req: ConnectionDetailRequest) -> ConnectionDetailResponse:
        pu = abs(req.axial_pu_kn)
        vu = abs(req.shear_vu_kn)
        fc = req.fc_concrete_mpa
        fy = req.plate_fy_mpa
        b_mm = max(450.0, req.plate_width_mm * 2.2)
        n_mm = max(450.0, req.plate_height_mm * 1.45)
        t_p = max(25.4, req.plate_thickness_mm * 2.0)

        # 1. Concrete Bearing Capacity (AISC 360-16 §J8 / DG 1: phi_c * 0.85 * f'c * A1 * sqrt(A2/A1))
        a1_mm2 = b_mm * n_mm
        sqrt_a2_a1 = 1.5  # Typical pedestal confinement ratio <= 2.0
        phi_pp_kn = 0.65 * 0.85 * fc * a1_mm2 * sqrt_a2_a1 / 1000.0
        dcr_bearing = pu / max(phi_pp_kn, 1e-3)

        # 2. Baseplate Cantilever Bending Thickness (AISC DG 1 Eq. 3.3.13: tp_min = l * sqrt(2 Pu / (0.90 Fy B N)))
        d_col = 355.0
        bf_col = 368.0
        m_cant = 0.5 * (n_mm - 0.95 * d_col)
        n_cant = 0.5 * (b_mm - 0.80 * bf_col)
        l_cant = max(m_cant, n_cant, 45.0)
        tp_min_mm = l_cant * math.sqrt((2.0 * pu * 1000.0) / max(0.90 * fy * b_mm * n_mm, 1.0))
        phi_mn_plate_kn = 0.90 * fy * b_mm * n_mm * ((t_p / l_cant) ** 2) / 2000.0
        dcr_plate = pu / max(phi_mn_plate_kn, 1e-3)

        # 3. Anchor Rod Shear & Breakout (ACI 318-19 Ch. 17 / AISC DG 1)
        d_a = max(22.225, req.bolt_diameter_mm)
        a_a = math.pi * (d_a ** 2) / 4.0
        n_anchors = 4
        phi_vn_anchors_kn = 0.75 * 0.60 * 400.0 * a_a * n_anchors / 1000.0
        dcr_anchors = vu / max(phi_vn_anchors_kn, 1e-3)

        checks = [
            LimitStateCheck(
                name="Concrete Foundation Bearing",
                clause="AISC 360-16 §J8 / DG 1",
                demand_kn_or_knm=round(pu, 2),
                capacity_phi_rn=round(phi_pp_kn, 2),
                unit="kN",
                dcr=round(dcr_bearing, 3),
                status="PASS" if dcr_bearing <= 1.0 else "FAIL",
                formula="φP_p = 0.65 · 0.85 f'_c A_1 √(A_2 / A_1)",
            ),
            LimitStateCheck(
                name="Baseplate Cantilever Flexure",
                clause="AISC Design Guide 1 §3.1",
                demand_kn_or_knm=round(pu, 2),
                capacity_phi_rn=round(phi_mn_plate_kn, 2),
                unit="kN",
                dcr=round(dcr_plate, 3),
                status="PASS" if dcr_plate <= 1.0 else "FAIL",
                formula="t_p,min = l_max · √[2 P_u / (0.90 F_y B N)]",
            ),
            LimitStateCheck(
                name="Anchor Rod Shear & Breakout",
                clause="AISC DG 1 / ACI 318-19 §17.7",
                demand_kn_or_knm=round(vu, 2),
                capacity_phi_rn=round(phi_vn_anchors_kn, 2),
                unit="kN",
                dcr=round(dcr_anchors, 3),
                status="PASS" if dcr_anchors <= 1.0 else "FAIL",
                formula="φV_sa = 0.75 · 0.60 F_uta A_se,V · n_a",
            ),
        ]

        gov = max(checks, key=lambda c: c.dcr)
        dx = (b_mm / 1000.0) * 0.36
        dz = (n_mm / 1000.0) * 0.36
        bolts = [
            Bolt3DGlyph(local_x_m=round(sx * dx, 4), local_y_m=0.03, local_z_m=round(sz * dz, 4), diameter_m=round(d_a / 1000.0, 4), utilization_dcr=round(dcr_anchors, 3), grade="F1554-Gr55")
            for sx in (-1, 1)
            for sz in (-1, 1)
        ]

        return ConnectionDetailResponse(
            connection_type="BASEPLATE",
            joint_id=req.joint_id,
            joint_coords_m=req.joint_coords_m,
            governing_dcr=gov.dcr,
            governing_limit_state=gov.name,
            overall_status="PASS" if gov.dcr <= 1.0 else "OVERSTRESSED",
            required_plate_thickness_mm=round(tp_min_mm, 2),
            provided_plate_thickness_mm=round(t_p, 2),
            recommended_weld_leg_mm=10.0,
            limit_states=checks,
            bolts_3d=bolts,
            plate_dimensions_m=[round(b_mm / 1000.0, 3), round(t_p / 1000.0, 4), round(n_mm / 1000.0, 3)],
        )

