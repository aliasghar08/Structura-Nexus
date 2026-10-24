"""
Structura Nexus: ASCE 7-16 Automated Lateral Load Generator
Implements:
1. Main Wind-Force Resisting System (MWFRS) Directional Procedure (Chapters 26-27).
2. Equivalent Lateral Force (ELF) Seismic Base Shear Procedure (Chapters 11-12).
3. Automated storey tributary distribution and standard ASCE 7 load combinations.
"""

import math
from typing import List, Dict, Tuple, Any, Optional
from ..models.schema import (
    NodeModel,
    MemberModel,
    StructuralGraphPayload,
    ASCE7WindParameters,
    StoreyWindPressure,
    ASCE7WindResponse,
    ASCE7SeismicParameters,
    StoreySeismicForce,
    ASCE7SeismicResponse,
)
from ..code_check.aisc_aci import get_section_properties, get_material_properties


class ASCE7WindEngine:
    """
    ASCE 7-16 MWFRS Directional Wind Load Engine (Chapters 26 & 27).
    Calculates velocity pressure profiles qz and distributes external windward/leeward forces.
    """

    # Table 26.10-1 Terrain Exposure Constants
    EXPOSURE_CONSTANTS = {
        "B": {"alpha": 7.0, "zg": 365.76, "zmin": 4.57},
        "C": {"alpha": 9.5, "zg": 274.32, "zmin": 4.57},
        "D": {"alpha": 11.5, "zg": 213.36, "zmin": 2.13},
    }

    @classmethod
    def calculate_kz(cls, z: float, exposure: str = "B") -> float:
        """Velocity pressure exposure coefficient Kz (Table 26.10-1)."""
        exp = cls.EXPOSURE_CONSTANTS.get(exposure.upper(), cls.EXPOSURE_CONSTANTS["B"])
        alpha = exp["alpha"]
        zg = exp["zg"]
        zmin = exp["zmin"]

        effective_z = max(z, zmin)
        if effective_z > zg:
            effective_z = zg
        return 2.01 * ((effective_z / zg) ** (2.0 / alpha))

    @classmethod
    def calculate_qz(
        cls,
        z: float,
        v_m_s: float = 45.0,
        exposure: str = "B",
        kd: float = 0.85,
        kzt: float = 1.0,
        ke: float = 1.0,
    ) -> float:
        """
        Velocity pressure qz (N/m^2) in SI units:
        qz = 0.613 * Kz * Kzt * Kd * Ke * V^2 (Eq. 26.10-1)
        """
        kz = cls.calculate_kz(z, exposure)
        return 0.613 * kz * kzt * kd * ke * (v_m_s ** 2)

    @classmethod
    def generate_wind_loads(
        cls,
        payload: StructuralGraphPayload,
        params: ASCE7WindParameters,
    ) -> ASCE7WindResponse:
        nodes = [n.model_copy(deep=True) for n in payload.nodes]
        members = payload.members

        if not nodes:
            return ASCE7WindResponse(
                basic_wind_speed_m_s=params.basic_wind_speed_m_s,
                exposure_category=params.exposure_category,
                risk_category=params.risk_category,
                direction=params.direction,
                velocity_pressures=[],
                total_base_wind_shear_n=0.0,
                updated_nodes=nodes,
            )

        # 1. Geometry and Floor Levels Identification
        # Collect distinct storey elevations (Y coordinates), rounded to 0.1m
        y_coords = sorted(list({round(n.coords[1], 2) for n in nodes}))
        if len(y_coords) <= 1:
            y_coords = [0.0, max([n.coords[1] for n in nodes] + [3.5])]

        # Building bounds
        xs = [n.coords[0] for n in nodes]
        zs = [n.coords[2] for n in nodes]
        min_x, max_x = min(xs), max(xs)
        min_z, max_z = min(zs), max(zs)

        # Building dimensions
        width_x = max(max_x - min_x, 3.0)
        width_z = max(max_z - min_z, 3.0)
        height = max(y_coords)

        # Tributary width perpendicular to wind direction
        is_x_dir = "X" in params.direction.upper()
        b_width = width_z if is_x_dir else width_x
        l_depth = width_x if is_x_dir else width_z

        # Mean roof height velocity pressure qh
        qh = cls.calculate_qz(
            height,
            v_m_s=params.basic_wind_speed_m_s,
            exposure=params.exposure_category,
            kd=params.k_d,
            kzt=params.k_zt,
            ke=params.k_e,
        )

        # External pressure coefficients (Figure 27.3-1)
        # Windward: Cp = +0.8
        # Leeward: Cp = -0.5 for L/B <= 1
        l_over_b = l_depth / max(b_width, 1.0)
        if l_over_b <= 1.0:
            cp_leeward = -0.5
        elif l_over_b >= 4.0:
            cp_leeward = -0.2
        else:
            cp_leeward = -0.5 + (l_over_b - 1.0) * (0.3 / 3.0)

        cp_windward = 0.85 * 0.8  # G * Cp
        cp_leeward_net = 0.85 * abs(cp_leeward)

        storey_pressures: List[StoreyWindPressure] = []
        total_wind_shear = 0.0

        # Calculate storey tributary heights
        tributary_heights: Dict[float, float] = {}
        for i, y in enumerate(y_coords):
            if i == 0:
                h_trib = 0.5 * (y_coords[1] - y_coords[0]) if len(y_coords) > 1 else 1.5
            elif i == len(y_coords) - 1:
                h_trib = 0.5 * (y_coords[i] - y_coords[i - 1])
            else:
                h_trib = 0.5 * (y_coords[i + 1] - y_coords[i - 1])
            tributary_heights[y] = max(h_trib, 1.0)

        # 2. Compute Wind Pressures and Storey Forces
        for i, y in enumerate(y_coords):
            if y < 0.1:
                continue  # Skip base ground level

            kz = cls.calculate_kz(y, params.exposure_category)
            qz = cls.calculate_qz(
                y,
                v_m_s=params.basic_wind_speed_m_s,
                exposure=params.exposure_category,
                kd=params.k_d,
                kzt=params.k_zt,
                ke=params.k_e,
            )

            p_windward = qz * cp_windward
            p_leeward = qh * cp_leeward_net
            p_total = p_windward + p_leeward

            trib_h = tributary_heights.get(y, 3.0)
            storey_force = p_total * b_width * trib_h
            total_wind_shear += storey_force

            storey_pressures.append(
                StoreyWindPressure(
                    storey_index=i,
                    elevation_m=round(y, 2),
                    kz=round(kz, 4),
                    qz_n_m2=round(qz, 2),
                    windward_pressure_n_m2=round(p_windward, 2),
                    leeward_pressure_n_m2=round(p_leeward, 2),
                    total_storey_force_n=round(storey_force, 2),
                )
            )

            # Distribute storey force among nodes at this floor level
            level_nodes = [n for n in nodes if abs(n.coords[1] - y) < 0.25]
            if level_nodes:
                # Windward nodes receive primary tributary wind point loads
                # If direction is +X, force is in +X; if -X, force is in -X
                dir_sign = 1.0 if "+" in params.direction else -1.0
                force_per_node = storey_force / len(level_nodes) * dir_sign

                for n in level_nodes:
                    if is_x_dir:
                        n.loads[0] += force_per_node
                    else:
                        n.loads[2] += force_per_node

        return ASCE7WindResponse(
            basic_wind_speed_m_s=params.basic_wind_speed_m_s,
            exposure_category=params.exposure_category,
            risk_category=params.risk_category,
            direction=params.direction,
            velocity_pressures=storey_pressures,
            total_base_wind_shear_n=round(total_wind_shear, 2),
            updated_nodes=nodes,
        )


class ASCE7SeismicEngine:
    """
    ASCE 7-16 Equivalent Lateral Force (ELF) Seismic Engine (Chapters 11 & 12).
    Calculates seismic base shear V = Cs * W and vertical storey distribution Fx.
    """

    SITE_COEFFICIENTS = {
        "A": {"Fa": 0.8, "Fv": 0.8},
        "B": {"Fa": 1.0, "Fv": 1.0},
        "C": {"Fa": 1.2, "Fv": 1.5},
        "D": {"Fa": 1.3, "Fv": 1.9},
        "E": {"Fa": 1.8, "Fv": 2.8},
    }

    RISK_IMPORTANCE = {
        "I": 1.00,
        "II": 1.00,
        "III": 1.25,
        "IV": 1.50,
    }

    @classmethod
    def generate_seismic_loads(
        cls,
        payload: StructuralGraphPayload,
        params: ASCE7SeismicParameters,
    ) -> ASCE7SeismicResponse:
        nodes = [n.model_copy(deep=True) for n in payload.nodes]
        members = payload.members

        if not nodes:
            return ASCE7SeismicResponse(
                sds=0.0,
                sd1=0.0,
                importance_factor_ie=1.0,
                fundamental_period_sec=0.5,
                cs=0.05,
                total_seismic_weight_kn=0.0,
                base_shear_v_kn=0.0,
                storey_forces=[],
                updated_nodes=nodes,
            )

        # 1. Site Coefficients and Design Spectral Accelerations
        site = cls.SITE_COEFFICIENTS.get(params.site_class.upper(), cls.SITE_COEFFICIENTS["D"])
        fa = site["Fa"]
        fv = site["Fv"]

        sms = fa * params.ss
        sm1 = fv * params.s1
        sds = (2.0 / 3.0) * sms
        sd1 = (2.0 / 3.0) * sm1

        ie = params.importance_factor_ie or cls.RISK_IMPORTANCE.get(params.risk_category.upper(), 1.00)

        # 2. Approximate Fundamental Period T (Section 12.8.2.1)
        max_height = max([n.coords[1] for n in nodes] + [3.5])
        # Steel Moment Frame: Ct = 0.0724, x = 0.8
        approx_t = 0.0724 * (max_height ** 0.8)
        period_t = params.approx_period_sec or max(approx_t, 0.20)

        # 3. Seismic Response Coefficient Cs (Section 12.8.1.1)
        r = max(params.r_factor, 1.0)
        cs_nominal = sds / (r / ie)

        # Upper limit (Eq. 12.8-3)
        cs_max = sd1 / (period_t * (r / ie))

        # Lower limits (Eqs. 12.8-5 & 12.8-6)
        cs_min1 = max(0.044 * sds * ie, 0.01)
        cs_min2 = (0.5 * params.s1) / (r / ie) if params.s1 >= 0.6 else 0.0
        cs_min = max(cs_min1, cs_min2)

        cs = max(min(cs_nominal, cs_max), cs_min)

        # 4. Total Effective Seismic Weight W (kN)
        # Sum member structural weights + floor dead load tributary
        total_steel_weight_n = 0.0
        node_map = {n.id: n.coords for n in nodes}
        for m in members:
            p1 = node_map.get(m.i_node)
            p2 = node_map.get(m.j_node)
            if p1 and p2:
                length = math.dist(p1, p2)
                sec = get_section_properties(m.section)
                area = sec.get("area_m2", 0.005)
                # Steel density: 7850 kg/m^3 -> 77.0 kN/m^3
                weight_n = length * area * 7850.0 * 9.81
                total_steel_weight_n += weight_n

        # Add lumped floor dead weight (assume 3.5 kN/m^2 tributary floor area)
        xs = [n.coords[0] for n in nodes]
        zs = [n.coords[2] for n in nodes]
        footprint_area = max(max(xs) - min(xs), 3.0) * max(max(zs) - min(zs), 3.0)

        y_levels = sorted(list({round(n.coords[1], 2) for n in nodes if n.coords[1] > 0.5}))
        if not y_levels:
            y_levels = [3.5]

        num_floors = len(y_levels)
        superimposed_dead_n = num_floors * footprint_area * 3500.0  # 3.5 kPa

        total_weight_n = total_steel_weight_n + superimposed_dead_n
        total_weight_kn = total_weight_n / 1000.0

        # Base Shear V (kN)
        base_shear_kn = cs * total_weight_kn
        base_shear_n = base_shear_kn * 1000.0

        # 5. Vertical Distribution Factor Exponent k (Section 12.8.3)
        if period_t <= 0.5:
            k_exp = 1.0
        elif period_t >= 2.5:
            k_exp = 2.0
        else:
            k_exp = 1.0 + ((period_t - 0.5) / 2.0) * 1.0

        # Storey masses & heights
        storey_weight_kn = total_weight_kn / max(len(y_levels), 1)
        w_h_k_terms = []
        for y in y_levels:
            w_h_k = storey_weight_kn * (y ** k_exp)
            w_h_k_terms.append((y, w_h_k))

        sum_w_h_k = sum(term[1] for term in w_h_k_terms) if w_h_k_terms else 1.0

        storey_forces: List[StoreySeismicForce] = []
        is_x_dir = "X" in params.direction.upper()
        dir_sign = 1.0 if "+" in params.direction else -1.0

        cum_shear_kn = 0.0
        for i, (y, w_h_k) in enumerate(reversed(w_h_k_terms)):
            cvx = w_h_k / sum_w_h_k
            fx_kn = cvx * base_shear_kn
            cum_shear_kn += fx_kn

            storey_forces.append(
                StoreySeismicForce(
                    storey_index=len(y_levels) - 1 - i,
                    elevation_m=round(y, 2),
                    storey_weight_kn=round(storey_weight_kn, 2),
                    cvx=round(cvx, 4),
                    lateral_force_kn=round(fx_kn, 2),
                    storey_shear_kn=round(cum_shear_kn, 2),
                )
            )

            # Distribute lateral force to floor joints
            level_nodes = [n for n in nodes if abs(n.coords[1] - y) < 0.25]
            if level_nodes:
                fx_per_node_n = (fx_kn * 1000.0 / len(level_nodes)) * dir_sign
                for n in level_nodes:
                    if is_x_dir:
                        n.loads[0] += fx_per_node_n
                    else:
                        n.loads[2] += fx_per_node_n

        return ASCE7SeismicResponse(
            sds=round(sds, 3),
            sd1=round(sd1, 3),
            importance_factor_ie=round(ie, 2),
            fundamental_period_sec=round(period_t, 3),
            cs=round(cs, 4),
            total_seismic_weight_kn=round(total_weight_kn, 2),
            base_shear_v_kn=round(base_shear_kn, 2),
            storey_forces=sorted(storey_forces, key=lambda s: s.elevation_m),
            updated_nodes=nodes,
        )
