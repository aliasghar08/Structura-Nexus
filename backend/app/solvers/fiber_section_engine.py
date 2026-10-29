"""
Structura Nexus: Proprietary Non-Linear Fiber Section Integrator & Concrete Mechanics Engine
Pure Python/NumPy 2D fiber discretization engine implementing:
1. Concrete Fiber Grid (Ny x Nz) with Hognestad Parabolic-Plastic Constitutive Law.
2. Discrete Steel Rebar Fibers with Elasto-Plastic Strain Hardening.
3. ACI 318-19 Non-Linear Strain-Compatibility Integration for Axial-Flexural (P-M) Envelopes.
4. Nominal (Pn, Mn) and Design (phi*Pn, phi*Mn) 32-point Envelopes with Transitioning Strength Reduction (phi).
5. Exact Demand-to-Capacity Ratio (DCR_PM) Evaluator and ACI Shear Capacity (phi*Vn).
6. Synthetic Data Generator for Training SectionNet-PM.
"""

import math
import numpy as np
from typing import List, Dict, Tuple, Any, Optional

class ConcreteFiberSectionIntegrator:
    """
    High-fidelity non-linear 2D fiber discretization engine for reinforced concrete cross-sections.
    """

    def __init__(
        self,
        b: float = 0.40,           # Width (m)
        h: float = 0.50,           # Height (m)
        cover: float = 0.04,       # Clear cover to stirrups (m)
        fc_mpa: float = 35.0,      # Concrete compressive strength f'c (MPa)
        fy_mpa: float = 420.0,     # Steel yield strength fy (MPa)
        rebar_ratio: float = 0.02, # Longitudinal reinforcement ratio rho = Ast / (b*h)
        tie_diameter: float = 0.01,# Stirrup tie bar diameter (m)
        tie_spacing: float = 0.15, # Stirrup spacing s (m)
        num_fibers_y: int = 40,    # Number of fibers along height
        num_fibers_z: int = 20,    # Number of fibers along width
    ):
        self.b = max(b, 0.15)
        self.h = max(h, 0.15)
        self.cover = max(cover, 0.02)
        self.fc_mpa = max(fc_mpa, 15.0)
        self.fy_mpa = max(fy_mpa, 250.0)
        self.rebar_ratio = min(max(rebar_ratio, 0.005), 0.08)
        self.tie_diameter = max(tie_diameter, 0.008)
        self.tie_spacing = max(tie_spacing, 0.05)
        self.ny = num_fibers_y
        self.nz = num_fibers_z

        # Material parameters in SI (Pa, N, m)
        self.fc = self.fc_mpa * 1e6
        self.fy = self.fy_mpa * 1e6
        self.Es = 200e9 # 200 GPa
        self.Ec = 4700.0 * math.sqrt(self.fc_mpa) * 1e6 # ACI 318 Ec (Pa)
        self.eps_0 = 2.0 * self.fc / self.Ec            # Strain at peak concrete stress
        self.eps_cu = 0.003                             # ACI maximum usable concrete compressive strain

        # Discretize concrete fibers
        self._build_concrete_fibers()
        # Discretize discrete rebar fibers
        self._build_rebar_fibers()

    def _build_concrete_fibers(self):
        """Constructs 2D grid of concrete fibers centered around plastic centroid."""
        dy = self.h / self.ny
        dz = self.b / self.nz
        fiber_area = dy * dz

        # Centroid is at (0, 0)
        # y ranges from -h/2 (bottom) to +h/2 (top)
        # z ranges from -b/2 to +b/2
        y_coords = np.linspace(-self.h / 2.0 + dy / 2.0, self.h / 2.0 - dy / 2.0, self.ny)
        z_coords = np.linspace(-self.b / 2.0 + dz / 2.0, self.b / 2.0 - dz / 2.0, self.nz)

        Y, Z = np.meshgrid(y_coords, z_coords, indexing='ij')
        self.concrete_y = Y.flatten()
        self.concrete_z = Z.flatten()
        self.concrete_area = np.full(self.concrete_y.shape, fiber_area)

    def _build_rebar_fibers(self):
        """Places discrete longitudinal reinforcement around perimeter."""
        total_steel_area = self.b * self.h * self.rebar_ratio
        effective_depth_y = self.h / 2.0 - self.cover - self.tie_diameter
        effective_width_z = self.b / 2.0 - self.cover - self.tie_diameter

        # Typical 8-bar peripheral configuration
        # 4 corner bars + 2 middle-top/bottom + 2 side-middle
        num_bars = 8
        bar_area = total_steel_area / num_bars

        rebar_y = []
        rebar_z = []

        # 4 corners
        for sy in [-1.0, 1.0]:
            for sz in [-1.0, 1.0]:
                rebar_y.append(sy * effective_depth_y)
                rebar_z.append(sz * effective_width_z)

        # 2 middle top/bottom
        rebar_y.append(effective_depth_y)
        rebar_z.append(0.0)
        rebar_y.append(-effective_depth_y)
        rebar_z.append(0.0)

        # 2 middle left/right
        rebar_y.append(0.0)
        rebar_z.append(effective_width_z)
        rebar_y.append(0.0)
        rebar_z.append(-effective_width_z)

        self.rebar_y = np.array(rebar_y, dtype=np.float64)
        self.rebar_z = np.array(rebar_z, dtype=np.float64)
        self.rebar_area = np.full(self.rebar_y.shape, bar_area, dtype=np.float64)

    def concrete_stress(self, strain: np.ndarray) -> np.ndarray:
        """
        Modified Hognestad parabolic stress-strain relationship for concrete in compression.
        Positive strain = compression. Zero tension capacity (cracked section).
        """
        stress = np.zeros_like(strain)
        # Compression (strain > 0)
        comp_mask = strain > 0
        eps = strain[comp_mask]

        # Parabolic ascending branch (0 <= eps <= eps_0)
        parabolic_mask = eps <= self.eps_0
        stress_comp = np.zeros_like(eps)
        stress_comp[parabolic_mask] = self.fc * (
            2.0 * (eps[parabolic_mask] / self.eps_0) - (eps[parabolic_mask] / self.eps_0) ** 2
        )

        # Plastic/softening plateau (eps_0 < eps <= eps_cu)
        plateau_mask = (eps > self.eps_0) & (eps <= self.eps_cu)
        stress_comp[plateau_mask] = self.fc * (
            1.0 - 0.15 * ((eps[plateau_mask] - self.eps_0) / max(self.eps_cu - self.eps_0, 1e-6))
        )

        # Crushed beyond eps_cu
        crushed_mask = eps > self.eps_cu
        stress_comp[crushed_mask] = self.fc * 0.85

        stress[comp_mask] = stress_comp
        return stress

    def steel_stress(self, strain: np.ndarray) -> np.ndarray:
        """
        Elasto-plastic stress-strain relationship with slight post-yield strain hardening.
        Positive = compression, Negative = tension.
        """
        ey = self.fy / self.Es
        stress = np.zeros_like(strain)

        # Elastic
        elastic_mask = np.abs(strain) <= ey
        stress[elastic_mask] = self.Es * strain[elastic_mask]

        # Plastic with 1% strain hardening
        plastic_pos = strain > ey
        stress[plastic_pos] = self.fy + 0.01 * self.Es * (strain[plastic_pos] - ey)

        plastic_neg = strain < -ey
        stress[plastic_neg] = -self.fy + 0.01 * self.Es * (strain[plastic_neg] + ey)

        return stress

    def evaluate_strain_state(self, c: float, eps_top: float) -> Tuple[float, float, float]:
        """
        Integrates internal normal force P and bending moment M for given neutral axis depth c.
        Returns: (Pn in N, Mn in N-m, phi strength reduction factor)
        c: neutral axis depth measured from extreme compression fiber (m).
        eps_top: extreme compression fiber strain (typically eps_cu = 0.003).
        """
        y_top = self.h / 2.0
        # Strain profile: eps(y) = eps_top * (1 - (y_top - y) / c)
        if abs(c) < 1e-5:
            curvature = 0.0
            concrete_strains = np.full_like(self.concrete_y, -0.005) # Pure tension
            rebar_strains = np.full_like(self.rebar_y, -0.005)
            eps_t = 0.005
        elif c > 1e4: # Pure uniform axial compression
            curvature = 0.0
            concrete_strains = np.full_like(self.concrete_y, eps_top)
            rebar_strains = np.full_like(self.rebar_y, eps_top)
            eps_t = -eps_top
        else:
            curvature = eps_top / c
            concrete_strains = eps_top - curvature * (y_top - self.concrete_y)
            rebar_strains = eps_top - curvature * (y_top - self.rebar_y)
            # Net tensile strain at centroid of extreme tension rebar layer (lowest y)
            y_extreme_tension_rebar = np.min(self.rebar_y)
            eps_t = -(eps_top - curvature * (y_top - y_extreme_tension_rebar))

        # Stresses
        sig_c = self.concrete_stress(concrete_strains)
        sig_s = self.steel_stress(rebar_strains)

        # Normal force Pn (Positive = Compression)
        P_concrete = np.sum(sig_c * self.concrete_area)
        # Deduct concrete displaced by rebar in compression
        rebar_comp_mask = rebar_strains > 0
        sig_c_at_rebar = self.concrete_stress(rebar_strains)
        P_steel = np.sum(sig_s * self.rebar_area) - np.sum(sig_c_at_rebar[rebar_comp_mask] * self.rebar_area[rebar_comp_mask])
        Pn = P_concrete + P_steel

        # Bending moment Mn about section centroid (y = 0)
        M_concrete = np.sum(sig_c * self.concrete_area * self.concrete_y)
        M_steel = np.sum(sig_s * self.rebar_area * self.rebar_y) - np.sum(
            sig_c_at_rebar[rebar_comp_mask] * self.rebar_area[rebar_comp_mask] * self.rebar_y[rebar_comp_mask]
        )
        Mn = abs(M_concrete + M_steel)

        # ACI 318-19 Strength Reduction Factor (phi) for tied columns
        # phi = 0.65 for eps_t <= 0.002 (compression-controlled)
        # phi = 0.90 for eps_t >= 0.005 (tension-controlled)
        # Linear transition in between: 0.65 + 0.25 * (eps_t - 0.002) / 0.003
        if eps_t <= 0.002:
            phi = 0.65
        elif eps_t >= 0.005:
            phi = 0.90
        else:
            phi = 0.65 + 0.25 * ((eps_t - 0.002) / 0.003)

        return Pn, Mn, phi

    def compute_interaction_envelope(self, num_points: int = 32) -> Dict[str, Any]:
        """
        Sweeps neutral axis depths from pure axial tension through balanced point to pure compression.
        Produces full nominal (Pn, Mn) and design (phi*Pn, phi*Mn) 32-point interaction curves.
        """
        y_top = self.h / 2.0
        y_bot_rebar = np.min(self.rebar_y)
        d = y_top - y_bot_rebar # Effective depth

        # 1. Pure axial tension (Pn_ten, Mn = 0)
        Pn_tension = -np.sum(self.rebar_area) * self.fy
        phi_Pn_tension = 0.90 * Pn_tension

        # 2. Pure axial compression (ACI 318-19 maximum axial strength cap)
        Ag = self.b * self.h
        Ast = np.sum(self.rebar_area)
        # Po = 0.85*fc*(Ag - Ast) + fy*Ast
        Po = 0.85 * self.fc * (Ag - Ast) + self.fy * Ast
        # ACI 318 tied column cap: Pn_max = 0.80 * Po
        Pn_cap = 0.80 * Po
        phi_Pn_cap = 0.65 * Pn_cap

        # Generate neutral axis depths spanning tension failure -> balanced -> compression failure
        # c_balanced approx d * (eps_cu / (eps_cu + fy/Es))
        cb = d * (self.eps_cu / (self.eps_cu + self.fy / self.Es))

        c_values = np.concatenate([
            np.linspace(0.04 * d, cb, num_points // 2),
            np.linspace(cb * 1.05, 3.0 * self.h, (num_points // 2) - 2),
            [1e5] # Large c for pure axial compression
        ])

        pn_list = [Pn_tension]
        mn_list = [0.0]
        phi_pn_list = [phi_Pn_tension]
        phi_mn_list = [0.0]

        for c in c_values:
            Pn, Mn, phi = self.evaluate_strain_state(c, self.eps_cu)
            # Apply axial compression cap
            Pn_capped = min(Pn, Pn_cap) if Pn > 0 else Pn
            phi_Pn_capped = min(phi * Pn, phi_Pn_cap) if Pn > 0 else phi * Pn

            pn_list.append(float(Pn_capped))
            mn_list.append(float(Mn))
            phi_pn_list.append(float(phi_Pn_capped))
            phi_mn_list.append(float(phi * Mn))

        # Sort envelope points clockwise from lowest P to highest P
        combined = sorted(zip(phi_pn_list, phi_mn_list, pn_list, mn_list), key=lambda pt: pt[0])

        phi_pn_sorted = [pt[0] for pt in combined]
        phi_mn_sorted = [pt[1] for pt in combined]
        pn_sorted = [pt[2] for pt in combined]
        mn_sorted = [pt[3] for pt in combined]

        # Resample to exactly `num_points` along the boundary
        target_pts = num_points
        indices = np.linspace(0, len(phi_pn_sorted) - 1, target_pts).astype(int)

        curve_points = [
            {"phi_pn_kn": round(phi_pn_sorted[i] / 1e3, 1), "phi_mn_knm": round(phi_mn_sorted[i] / 1e3, 1)}
            for i in indices
        ]

        # Max design capacities
        max_phi_pn_kn = round(phi_Pn_cap / 1e3, 1)
        max_phi_mn_knm = round(max(phi_mn_sorted) / 1e3, 1)

        # Shear capacity per ACI 318-19 Section 22.5
        # Vc = 0.17 * lambda * sqrt(f'c) * bw * d
        lambda_lightweight = 1.0 # Normal weight concrete
        Vc = 0.17 * lambda_lightweight * math.sqrt(self.fc_mpa) * 1e6 * self.b * d
        # Vs = (Av * fyt * d) / s (2 legs for closed tie)
        Av = 2.0 * (math.pi * (self.tie_diameter / 2.0) ** 2)
        Vs = (Av * self.fy * d) / self.tie_spacing
        phi_Vn = 0.75 * (Vc + Vs)

        return {
            "num_points": len(curve_points),
            "curve_points": curve_points,
            "max_phi_pn_kn": max_phi_pn_kn,
            "max_phi_mn_knm": max_phi_mn_knm,
            "phi_vn_kn": round(phi_Vn / 1e3, 1),
            "vc_kn": round(Vc / 1e3, 1),
            "vs_kn": round(Vs / 1e3, 1),
            "po_kn": round(Po / 1e3, 1),
            "balanced_cb_m": round(cb, 4),
            "effective_depth_d_m": round(d, 4),
            "rebar_ratio": round(self.rebar_ratio, 4),
        }

    def evaluate_demand(self, Pu_kn: float, Mu_knm: float, Vu_kn: float = 0.0) -> Dict[str, Any]:
        """
        Evaluates exact Demand-to-Capacity Ratio (DCR) for given applied factored demands.
        Computes radial projection of (Mu, Pu) onto the (phi*Mn, phi*Pn) envelope.
        """
        envelope = self.compute_interaction_envelope(num_points=48)
        pts = envelope["curve_points"]
        Pu = Pu_kn
        Mu = abs(Mu_knm)
        Vu = abs(Vu_kn)

        # Check shear DCR
        phi_vn = envelope["phi_vn_kn"]
        dcr_v = Vu / max(phi_vn, 1e-3)

        # Radial DCR computation: ray from (0, 0) through (Mu, Pu)
        demand_radius = math.sqrt(Mu * Mu + Pu * Pu)
        if demand_radius < 1e-4:
            dcr_pm = 0.0
            phi_pn_cap_at_angle = envelope["max_phi_pn_kn"]
            phi_mn_cap_at_angle = 0.0
        else:
            angle = math.atan2(Pu, Mu)
            # Find closest ray intersection along polygon
            best_capacity_radius = 1e-3
            for i in range(len(pts) - 1):
                p1_m, p1_p = pts[i]["phi_mn_knm"], pts[i]["phi_pn_kn"]
                p2_m, p2_p = pts[i+1]["phi_mn_knm"], pts[i+1]["phi_pn_kn"]

                # Segment intersection with ray (0,0) -> (cos(a), sin(a))
                dx = p2_m - p1_m
                dy = p2_p - p1_p
                denom = math.cos(angle) * dy - math.sin(angle) * dx
                if abs(denom) > 1e-6:
                    t = (p1_m * dy - p1_p * dx) / denom
                    s = (p1_m * math.sin(angle) - p1_p * math.cos(angle)) / denom
                    if t > 0 and 0.0 <= s <= 1.0:
                        best_capacity_radius = max(best_capacity_radius, t)

            dcr_pm = demand_radius / max(best_capacity_radius, 1e-3)

        governing_dcr = max(dcr_pm, dcr_v)
        is_pass = governing_dcr <= 1.0

        # Optimal rebar ratio recommendation to achieve target 0.85 DCR
        current_rho = self.rebar_ratio
        if governing_dcr > 0.05:
            target_dcr = 0.85
            ratio_factor = governing_dcr / target_dcr
            optimal_rho = min(max(current_rho * math.sqrt(ratio_factor), 0.01), 0.04)
        else:
            optimal_rho = 0.01

        return {
            "pu_kn": Pu_kn,
            "mu_knm": round(Mu_knm, 1),
            "vu_kn": round(Vu_kn, 1),
            "dcr_pm": round(dcr_pm, 3),
            "dcr_shear": round(dcr_v, 3),
            "governing_dcr": round(governing_dcr, 3),
            "is_pass": is_pass,
            "status": "PASS" if is_pass else "OVERSTRESSED",
            "optimal_rebar_ratio": round(optimal_rho, 4),
            "optimal_rebar_pct": round(optimal_rho * 100.0, 2),
            "envelope": envelope,
        }

    @classmethod
    def generate_synthetic_dataset(cls, num_samples: int = 1000) -> List[Dict[str, Any]]:
        """
        Generates synthetic dataset of reinforced concrete sections and their solved capacities
        for training SectionNet-PM.
        """
        np.random.seed(42)
        dataset = []

        b_choices = np.linspace(0.25, 0.90, 15)
        h_choices = np.linspace(0.30, 1.20, 20)
        fc_choices = [25.0, 30.0, 35.0, 40.0, 50.0, 60.0]
        fy_choices = [400.0, 420.0, 500.0]
        rho_choices = np.linspace(0.01, 0.045, 12)

        for i in range(num_samples):
            b = float(np.random.choice(b_choices))
            h = float(np.random.choice(h_choices))
            cover = 0.04
            fc = float(np.random.choice(fc_choices))
            fy = float(np.random.choice(fy_choices))
            rho = float(np.random.choice(rho_choices))
            tie_d = 0.010 if b <= 0.50 else 0.012
            tie_s = float(np.random.choice([0.10, 0.15, 0.20, 0.25]))

            solver = cls(
                b=b, h=h, cover=cover, fc_mpa=fc, fy_mpa=fy,
                rebar_ratio=rho, tie_diameter=tie_d, tie_spacing=tie_s
            )
            env = solver.compute_interaction_envelope(num_points=32)

            # Generate random factored demands Pu, Mu, Vu
            max_p = env["max_phi_pn_kn"]
            max_m = env["max_phi_mn_knm"]
            max_v = env["phi_vn_kn"]

            Pu = float(np.random.uniform(0.05, 0.95) * max_p)
            Mu = float(np.random.uniform(0.05, 0.95) * max_m)
            Vu = float(np.random.uniform(0.05, 0.85) * max_v)

            demand_res = solver.evaluate_demand(Pu, Mu, Vu)

            # Flatten 32 envelope points (64 values: alternating phi_mn and phi_pn)
            flat_envelope = []
            for pt in env["curve_points"]:
                flat_envelope.append(pt["phi_mn_knm"])
                flat_envelope.append(pt["phi_pn_kn"])

            dataset.append({
                # 10-dimensional input vector
                "inputs": [
                    b, h, cover, fc, fy, rho, tie_d, tie_s, Pu, Mu
                ],
                "flat_envelope_64": flat_envelope,
                "dcr_pm": demand_res["dcr_pm"],
                "dcr_shear": demand_res["dcr_shear"],
                "optimal_rebar_ratio": demand_res["optimal_rebar_ratio"],
                "max_phi_pn_kn": env["max_phi_pn_kn"],
                "max_phi_mn_knm": env["max_phi_mn_knm"],
                "phi_vn_kn": env["phi_vn_kn"],
            })

        return dataset

