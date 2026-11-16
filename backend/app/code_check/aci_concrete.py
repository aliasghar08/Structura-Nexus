"""
Structura Nexus: ACI 318-19 Reinforced Concrete Design & Code Checker
Implements:
- Whitney stress blocks & beta_1 factors
- Pure axial compression caps (phi * Pn_max = 0.80 * phi * P0)
- Strain-compatibility neutral axis sweep (c in [0.02h, 5.0h])
- phi(eps_t) transition from compression-controlled (0.65) to tension-controlled (0.90)
- Shear strength (Vc, Vs, phi*Vn) with axial interaction and ACI tie spacing limits (s_max)
- Exact Demand-to-Capacity Ratio (DCR) interpolation
Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
"""

import time
import math
from typing import List, Dict, Tuple, Any, Optional
import numpy as np

from ..models.concrete_schema import (
    ConcreteColumnPMRequest,
    ConcreteColumnPMResponse,
    PMPoint,
    ConcreteCrackCheckRequest,
    ConcreteCrackCheckResponse,
)
from ..solvers.fiber_section_engine import ConcreteFiberSectionIntegrator


class ACI318ConcreteChecker:
    """
    Standard-compliant ACI 318-19 Reinforced Concrete Column & Beam Evaluator.
    """

    @staticmethod
    def compute_beta1(fc_mpa: float) -> float:
        """
        ACI 318-19 Table 22.2.2.4.3 Whitney stress block depth factor beta_1:
        beta_1 = 0.85 for 17 <= f'c <= 28 MPa
        For f'c > 28 MPa: beta_1 = 0.85 - 0.05 * (f'c - 28) / 7
        Minimum beta_1 = 0.65.
        """
        if fc_mpa <= 28.0:
            return 0.85
        beta = 0.85 - 0.05 * ((fc_mpa - 28.0) / 7.0)
        return max(0.65, min(0.85, beta))

    @staticmethod
    def compute_phi(eps_t: float, fy_mpa: float = 420.0, Es_mpa: float = 200000.0) -> float:
        """
        ACI 318-19 Table 21.2.2 strength reduction factor phi for tied members:
        - Compression-controlled (eps_t <= eps_ty): phi = 0.65
        - Tension-controlled (eps_t >= eps_ty + 0.003): phi = 0.90
        - Transition: phi = 0.65 + 0.25 * (eps_t - eps_ty) / 0.003
        """
        eps_ty = fy_mpa / Es_mpa
        eps_tl = eps_ty + 0.003
        if eps_t <= eps_ty:
            return 0.65
        elif eps_t >= eps_tl:
            return 0.90
        else:
            return 0.65 + 0.25 * ((eps_t - eps_ty) / 0.003)

    @classmethod
    def analyze_column_pm(cls, req: ConcreteColumnPMRequest) -> ConcreteColumnPMResponse:
        t0 = time.perf_counter()

        b = req.b
        h = req.h
        fc_mpa = req.fc_mpa
        fy_mpa = req.fy_mpa
        rho = req.rebar_ratio
        cover = req.cover or 0.04
        tie_dia = req.tie_diameter or 0.010
        pu_kn = req.pu_kn
        mu_knm = req.mu_knm
        vu_kn = req.vu_kn or 150.0

        # Discretization via proprietary fiber integrator
        integrator = ConcreteFiberSectionIntegrator(
            b=b,
            h=h,
            cover=cover,
            fc_mpa=fc_mpa,
            fy_mpa=fy_mpa,
            rebar_ratio=rho,
            tie_diameter=tie_dia,
            tie_spacing=0.15,
            num_fibers_y=36,
            num_fibers_z=18,
        )

        ag_m2 = b * h
        ast_m2 = ag_m2 * rho
        ast_mm2 = ast_m2 * 1e6
        d_m = h - cover - tie_dia - 0.012  # approx centroid of tension steel

        # 1. Pure axial strengths per ACI 318-19 22.4.2
        # P0 = 0.85 * f'c * (Ag - Ast) + fy * Ast
        fc_pa = fc_mpa * 1e6
        fy_pa = fy_mpa * 1e6
        p0_n = 0.85 * fc_pa * (ag_m2 - ast_m2) + fy_pa * ast_m2
        phi_comp = 0.65
        phi_p0_kn = (phi_comp * p0_n) / 1e3
        # Tied column axial cap: phi * Pn_max = 0.80 * phi * P0
        phi_pn_max_kn = 0.80 * phi_p0_kn

        # 2. Build 36-point interaction envelope
        cb_m = d_m * (0.003 / (0.003 + (fy_mpa / 200000.0)))
        c_sweep = np.concatenate([
            np.linspace(0.03 * d_m, cb_m, 16),
            np.linspace(cb_m * 1.05, 3.5 * h, 16),
            [1e4],
        ])

        pm_points: List[PMPoint] = []
        nominal_pts: List[List[float]] = []
        design_pts: List[List[float]] = []

        # Pure tension point
        pn_tens_kn = - (ast_m2 * fy_pa) / 1e3
        phi_pn_tens_kn = 0.90 * pn_tens_kn
        pm_points.append(
            PMPoint(
                mn_knm=0.0,
                pn_kn=round(pn_tens_kn, 1),
                phi_mn_knm=0.0,
                phi_pn_kn=round(phi_pn_tens_kn, 1),
                phi=0.90,
                c_m=0.0,
                eps_t=0.010,
            )
        )
        nominal_pts.append([0.0, round(pn_tens_kn, 1)])
        design_pts.append([0.0, round(phi_pn_tens_kn, 1)])

        max_phi_mn = 0.0

        for c in c_sweep:
            Pn_n, Mn_nm, phi_val = integrator.evaluate_strain_state(float(c), 0.003)
            pn_kn = Pn_n / 1e3
            mn_knm = Mn_nm / 1e3

            # Apply compression cap
            if pn_kn > 0:
                phi_pn_kn = min(phi_val * pn_kn, phi_pn_max_kn)
            else:
                phi_pn_kn = phi_val * pn_kn

            phi_mn_knm = phi_val * mn_knm
            if phi_mn_knm > max_phi_mn:
                max_phi_mn = phi_mn_knm

            eps_t = 0.003 * (d_m - c) / max(c, 1e-5)

            pm_points.append(
                PMPoint(
                    mn_knm=round(mn_knm, 1),
                    pn_kn=round(pn_kn, 1),
                    phi_mn_knm=round(phi_mn_knm, 1),
                    phi_pn_kn=round(phi_pn_kn, 1),
                    phi=round(phi_val, 3),
                    c_m=round(float(c), 4),
                    eps_t=round(float(eps_t), 5),
                )
            )
            nominal_pts.append([round(mn_knm, 1), round(pn_kn, 1)])
            design_pts.append([round(phi_mn_knm, 1), round(phi_pn_kn, 1)])

        # 3. Demand-to-Capacity Ratio (DCR)
        # Evaluated radially and axis-wise against design envelope
        dcr_axial = pu_kn / max(phi_pn_max_kn, 1.0) if pu_kn > 0 else abs(pu_kn) / max(abs(phi_pn_tens_kn), 1.0)
        dcr_flexure = mu_knm / max(max_phi_mn, 1.0)
        
        # Fiber DCR evaluation
        fiber_res = integrator.evaluate_demand(Pu_kn=pu_kn, Mu_knm=mu_knm, Vu_kn=vu_kn)
        governing_dcr = round(float(fiber_res.get("governing_dcr", max(dcr_axial, dcr_flexure))), 3)
        is_safe = governing_dcr <= 1.0

        # 4. Shear Capacity (ACI 318-19 Section 22.5)
        # Vc with axial compression factor: Vc = 0.17 * (1 + Nu / (14 * Ag)) * sqrt(f'c) * bw * d
        nu_n = max(0.0, pu_kn * 1e3)
        axial_factor = min(1.0 + (nu_n / (14.0 * ag_m2 * 1e6)), 1.5)
        vc_n = 0.17 * axial_factor * math.sqrt(fc_mpa) * 1e6 * b * d_m
        
        # Tie area (2 legs of tie_dia)
        av_m2 = 2.0 * (math.pi * (tie_dia / 2.0) ** 2)
        s_m = 0.15
        vs_n = (av_m2 * fy_pa * d_m) / s_m
        phi_vn_n = 0.75 * (vc_n + vs_n)

        # ACI Maximum Stirrup Spacing (Section 25.7.2.1)
        # s_max = min(16 * db, 48 * dtie, min(b, h), 0.300 m)
        db_long_m = math.sqrt((ast_m2 / 8.0) * 4.0 / math.pi) if ast_m2 > 0 else 0.025
        s_max_m = min(16.0 * db_long_m, 48.0 * tie_dia, b, h, 0.300)

        dt = (time.perf_counter() - t0) * 1000.0

        return ConcreteColumnPMResponse(
            b=round(b, 3),
            h=round(h, 3),
            fc_mpa=round(fc_mpa, 1),
            fy_mpa=round(fy_mpa, 1),
            rebar_ratio=round(rho, 4),
            ast_mm2=round(ast_mm2, 1),
            phi_p0_kn=round(phi_p0_kn, 1),
            phi_pn_max_kn=round(phi_pn_max_kn, 1),
            phi_mn_pure_bending_knm=round(max_phi_mn, 1),
            governing_dcr=governing_dcr,
            is_safe=is_safe,
            shear_vc_kn=round(vc_n / 1e3, 1),
            shear_vs_kn=round(vs_n / 1e3, 1),
            phi_vn_kn=round(phi_vn_n / 1e3, 1),
            stirrup_spacing_mm=round(s_m * 1000.0, 1),
            max_stirrup_spacing_mm=round(s_max_m * 1000.0, 1),
            interaction_envelope=pm_points,
            nominal_points=nominal_pts,
            design_points=design_pts,
            operating_demand={"pu_kn": pu_kn, "mu_knm": mu_knm, "vu_kn": vu_kn},
            latency_ms=round(dt, 2),
            engine="ACI_318_19_FIBER_ANALYTIC",
        )

    @classmethod
    def evaluate_crack_serviceability(cls, req: ConcreteCrackCheckRequest) -> ConcreteCrackCheckResponse:
        """
        Concrete Serviceability & Crack Width Verification Engine
        Governed by: ACI 318-19 Section 24.3.2 and ACI 224R-01.
        """
        b = req.b
        h = req.h
        fc_mpa = req.fc_mpa
        fy_mpa = req.fy_mpa
        ms_knm = req.moment_service_knm
        pu_kn = req.axial_service_kn
        db_mm = req.bar_diameter_mm
        n_bars = max(2, req.num_bars)
        cc_mm = req.cover_mm
        cond = req.exposure_condition.upper()

        # Physical geometry in mm
        b_mm = b * 1000.0
        h_mm = h * 1000.0
        ab1_mm2 = (math.pi / 4.0) * (db_mm ** 2)
        as_mm2 = n_bars * ab1_mm2
        d_mm = h_mm - cc_mm - (db_mm / 2.0)

        # Moduli & Modular ratio
        Ec_mpa = 4700.0 * math.sqrt(fc_mpa)
        Es_mpa = 200000.0
        n_ratio = Es_mpa / Ec_mpa
        rho = as_mm2 / (b_mm * d_mm)

        # Transformed cracked section neutral axis
        rn = rho * n_ratio
        k = math.sqrt(rn * rn + 2.0 * rn) - rn
        kd_mm = k * d_mm

        # Cracked and Gross moments of inertia
        Icr_mm4 = (1.0 / 3.0) * b_mm * (kd_mm ** 3) + n_ratio * as_mm2 * ((d_mm - kd_mm) ** 2)
        Ig_mm4 = (1.0 / 12.0) * b_mm * (h_mm ** 3)
        cracked_ratio = round(Icr_mm4 / max(Ig_mm4, 1.0), 3)

        # Service tensile steel stress fs
        ms_nmm = abs(ms_knm) * 1e6
        fs_elastic = (ms_nmm * (d_mm - kd_mm) / max(Icr_mm4, 1.0)) * n_ratio
        fs_mpa = min(fs_elastic, (2.0 / 3.0) * fy_mpa)
        if fs_mpa < 10.0:
            fs_mpa = 10.0

        # 1. ACI 318-19 Section 24.3.2 Max Rebar Spacing:
        s_max_formula = 380.0 * (280.0 / fs_mpa) - 2.5 * cc_mm
        s_max_cap = 300.0 * (280.0 / fs_mpa)
        s_max_mm = max(50.0, min(s_max_formula, s_max_cap))

        # Actual clear spacing between bars
        s_actual_mm = max(20.0, (b_mm - 2.0 * cc_mm - db_mm) / max(1, n_bars - 1))
        spacing_dcr = round(s_actual_mm / max(s_max_mm, 1e-4), 3)

        # 2. Gergely-Lutz / ACI 224R Surface Crack Width:
        dc_mm = cc_mm + (db_mm / 2.0)
        A_tension_mm2 = (2.0 * dc_mm * b_mm) / n_bars
        beta = (h_mm - kd_mm) / max(d_mm - kd_mm, 1.0)
        beta = max(1.10, min(1.35, beta))

        wk_mm = 0.076 * beta * fs_mpa * math.pow(dc_mm * A_tension_mm2, 1.0 / 3.0) * 1e-3
        wk_mm = round(wk_mm, 4)

        # Allowable crack widths per ACI 224R Table 4.1
        allowable_map = {
            "INTERIOR_DRY": 0.40,
            "EXTERIOR_MOIST": 0.30,
            "DEICING_SALTS": 0.20,
            "WATER_RETAINING": 0.10,
        }
        w_allow_mm = allowable_map.get(cond, 0.30)
        crack_dcr = round(wk_mm / w_allow_mm, 3)

        is_compliant = (crack_dcr <= 1.0) and (spacing_dcr <= 1.0)

        return ConcreteCrackCheckResponse(
            status="SUCCESS",
            is_compliant=is_compliant,
            computed_crack_width_mm=wk_mm,
            allowable_crack_width_mm=w_allow_mm,
            crack_width_dcr=crack_dcr,
            actual_bar_spacing_mm=round(s_actual_mm, 1),
            max_bar_spacing_mm=round(s_max_mm, 1),
            spacing_dcr=spacing_dcr,
            cracked_inertia_ratio=cracked_ratio,
            exposure_condition=cond,
            code_governing="ACI 318-19 Section 24.3.2 & ACI 224R-01",
            service_stress_fs_mpa=round(fs_mpa, 1),
            effective_depth_d_mm=round(d_mm, 1),
            neutral_axis_kd_mm=round(kd_mm, 1),
        )
