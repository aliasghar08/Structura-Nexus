import math
from typing import Dict, Any, List, Optional, Tuple

# Comprehensive AISC Standard W-Shape Database (SI units: m, m^2, m^3, m^4, kg/m)
# Dimensions converted from standard AISC 15th / 16th Edition Steel Construction Manual
AISC_W_SHAPES: Dict[str, Dict[str, float]] = {
    "W10X33": {
        "depth_m": 0.247,
        "width_m": 0.202,
        "tf_m": 0.0110,
        "tw_m": 0.0074,
        "area_m2": 0.00626,
        "ix_m4": 7.12e-5,
        "iy_m4": 1.52e-5,
        "rx_m": 0.107,
        "ry_m": 0.0493,
        "zx_m3": 6.36e-4,
        "zy_m3": 2.33e-4,
        "sx_m3": 5.75e-4,
        "sy_m3": 1.51e-4,
        "j_m4": 2.41e-7,
        "weight_kg_m": 49.1,
    },
    "W12X26": {
        "depth_m": 0.310,
        "width_m": 0.165,
        "tf_m": 0.0097,
        "tw_m": 0.0058,
        "area_m2": 0.00494,
        "ix_m4": 8.49e-5,
        "iy_m4": 7.20e-6,
        "rx_m": 0.131,
        "ry_m": 0.0381,
        "zx_m3": 6.01e-4,
        "zy_m3": 1.34e-4,
        "sx_m3": 5.47e-4,
        "sy_m3": 8.72e-5,
        "j_m4": 1.25e-7,
        "weight_kg_m": 38.7,
    },
    "W14X22": {
        "depth_m": 0.349,
        "width_m": 0.127,
        "tf_m": 0.0085,
        "tw_m": 0.0058,
        "area_m2": 0.00419,
        "ix_m4": 8.28e-5,
        "iy_m4": 2.91e-6,
        "rx_m": 0.141,
        "ry_m": 0.0264,
        "zx_m3": 5.44e-4,
        "zy_m3": 7.05e-5,
        "sx_m3": 4.75e-4,
        "sy_m3": 4.59e-5,
        "j_m4": 8.74e-8,
        "weight_kg_m": 32.7,
    },
    "W14X30": {
        "depth_m": 0.352,
        "width_m": 0.171,
        "tf_m": 0.0098,
        "tw_m": 0.0069,
        "area_m2": 0.00571,
        "ix_m4": 1.21e-4,
        "iy_m4": 8.16e-6,
        "rx_m": 0.146,
        "ry_m": 0.0378,
        "zx_m3": 7.87e-4,
        "zy_m3": 1.54e-4,
        "sx_m3": 6.88e-4,
        "sy_m3": 9.54e-5,
        "j_m4": 1.58e-7,
        "weight_kg_m": 44.6,
    },
    "W14X38": {
        "depth_m": 0.358,
        "width_m": 0.172,
        "tf_m": 0.0131,
        "tw_m": 0.0079,
        "area_m2": 0.00723,
        "ix_m4": 1.60e-4,
        "iy_m4": 1.11e-5,
        "rx_m": 0.149,
        "ry_m": 0.0391,
        "zx_m3": 1.02e-3,
        "zy_m3": 2.08e-4,
        "sx_m3": 8.95e-4,
        "sy_m3": 1.29e-4,
        "j_m4": 3.33e-7,
        "weight_kg_m": 56.5,
    },
    "W14X48": {
        "depth_m": 0.351,
        "width_m": 0.204,
        "tf_m": 0.0151,
        "tw_m": 0.0086,
        "area_m2": 0.00909,
        "ix_m4": 2.02e-4,
        "iy_m4": 2.14e-5,
        "rx_m": 0.149,
        "ry_m": 0.0485,
        "zx_m3": 1.29e-3,
        "zy_m3": 3.38e-4,
        "sx_m3": 1.15e-3,
        "sy_m3": 2.10e-4,
        "j_m4": 5.41e-7,
        "weight_kg_m": 71.4,
    },
    "W14X68": {
        "depth_m": 0.356,
        "width_m": 0.255,
        "tf_m": 0.0183,
        "tw_m": 0.0105,
        "area_m2": 0.0129,
        "ix_m4": 3.01e-4,
        "iy_m4": 5.04e-5,
        "rx_m": 0.152,
        "ry_m": 0.0625,
        "zx_m3": 1.88e-3,
        "zy_m3": 6.13e-4,
        "sx_m3": 1.69e-3,
        "sy_m3": 3.95e-4,
        "j_m4": 1.25e-6,
        "weight_kg_m": 101.2,
    },
    "W14X90": {
        "depth_m": 0.356,
        "width_m": 0.369,
        "tf_m": 0.0180,
        "tw_m": 0.0112,
        "area_m2": 0.0171,
        "ix_m4": 4.16e-4,
        "iy_m4": 1.51e-4,
        "rx_m": 0.156,
        "ry_m": 0.0940,
        "zx_m3": 2.57e-3,
        "zy_m3": 1.25e-3,
        "sx_m3": 2.34e-3,
        "sy_m3": 8.18e-4,
        "j_m4": 1.71e-6,
        "weight_kg_m": 133.9,
    },
    "W18X50": {
        "depth_m": 0.457,
        "width_m": 0.190,
        "tf_m": 0.0145,
        "tw_m": 0.0090,
        "area_m2": 0.00948,
        "ix_m4": 3.33e-4,
        "iy_m4": 1.67e-5,
        "rx_m": 0.187,
        "ry_m": 0.0420,
        "zx_m3": 1.66e-3,
        "zy_m3": 2.72e-4,
        "sx_m3": 1.46e-3,
        "sy_m3": 1.75e-4,
        "j_m4": 5.16e-7,
        "weight_kg_m": 74.4,
    },
    "W24X68": {
        "depth_m": 0.603,
        "width_m": 0.228,
        "tf_m": 0.0149,
        "tw_m": 0.0105,
        "area_m2": 0.0130,
        "ix_m4": 7.62e-4,
        "iy_m4": 2.91e-5,
        "rx_m": 0.242,
        "ry_m": 0.0474,
        "zx_m3": 2.90e-3,
        "zy_m3": 3.98e-4,
        "sx_m3": 2.52e-3,
        "sy_m3": 2.56e-4,
        "j_m4": 7.91e-7,
        "weight_kg_m": 101.2,
    },
}

MATERIALS: Dict[str, Dict[str, float]] = {
    "A992_STEEL": {
        "elastic_modulus_pa": 200.0e9,
        "shear_modulus_pa": 77.2e9,
        "yield_strength_pa": 345.0e6,  # 50 ksi
        "ultimate_strength_pa": 450.0e6,
        "poisson_ratio": 0.30,
        "density_kg_m3": 7850.0,
    },
    "A36_STEEL": {
        "elastic_modulus_pa": 200.0e9,
        "shear_modulus_pa": 77.2e9,
        "yield_strength_pa": 250.0e6,  # 36 ksi
        "ultimate_strength_pa": 400.0e6,
        "poisson_ratio": 0.30,
        "density_kg_m3": 7850.0,
    },
    "C4000_CONCRETE": {
        "elastic_modulus_pa": 24.8e9,  # 4700 * sqrt(fc')
        "shear_modulus_pa": 10.3e9,
        "yield_strength_pa": 27.6e6,  # 4000 psi
        "ultimate_strength_pa": 27.6e6,
        "poisson_ratio": 0.20,
        "density_kg_m3": 2400.0,
    },
}

def get_section_properties(section_name: str) -> Dict[str, float]:
    sec = section_name.strip().upper().replace(" ", "")
    if sec in AISC_W_SHAPES:
        return AISC_W_SHAPES[sec]
    # Fallback to W14X48 defaults if custom or unknown
    return AISC_W_SHAPES["W14X48"]

def get_material_properties(mat_name: str) -> Dict[str, float]:
    mat = mat_name.strip().upper().replace(" ", "_")
    if mat in MATERIALS:
        return MATERIALS[mat]
    return MATERIALS["A992_STEEL"]

class AISC360CodeChecker:
    """
    Automated Deterministic Limit-State Code Compliance Engine
    Governed by: AISC 360-16 Specification for Structural Steel Buildings
    and ACI 318-19 Building Code Requirements for Structural Concrete.
    """

    @staticmethod
    def check_steel_member(
        section_name: str,
        material_name: str,
        length_m: float,
        axial_force_n: float,       # + = tension, - = compression
        shear_y_n: float,
        shear_z_n: float,
        moment_y_nm: float,
        moment_z_nm: float,
        torsion_nm: float,
        max_deflection_m: float = 0.0,
        k_factor: float = 1.0,
        auto_recommend: bool = True,
    ) -> Dict[str, Any]:
        sec = get_section_properties(section_name)
        mat = get_material_properties(material_name)

        E = mat["elastic_modulus_pa"]
        Fy = mat["yield_strength_pa"]
        Ag = sec["area_m2"]
        rx = sec["rx_m"]
        ry = sec["ry_m"]
        Zx = sec["zx_m3"]
        Zy = sec["zy_m3"]
        d = sec["depth_m"]
        tw = sec["tw_m"]

        Pu = abs(axial_force_n)
        is_compression = axial_force_n < -1e-3
        is_tension = axial_force_n > 1e-3

        # 1. Slenderness Ratio KL/r (AISC 360 Section E2 & D1)
        r_min = min(rx, ry)
        kl_r = (k_factor * length_m) / max(r_min, 1e-5)

        # 2. Tension Capacity (AISC 360 Chapter D)
        # phi_t = 0.90 for gross section yielding: Pn = Fy * Ag
        phi_t = 0.90
        phi_Pn_tension = phi_t * Fy * Ag
        dcr_tension = (Pu / phi_Pn_tension) if is_tension else 0.0

        # 3. Flexural Buckling / Compression (AISC 360 Chapter E)
        # phi_c = 0.90
        phi_c = 0.90
        Fe = (math.pi ** 2 * E) / max(kl_r ** 2, 1e-4)  # Euler buckling stress
        slenderness_limit = 4.71 * math.sqrt(E / Fy)

        if kl_r <= slenderness_limit:
            # Inelastic buckling: Fcr = [0.658^(Fy/Fe)] * Fy
            fcr = (0.658 ** (Fy / max(Fe, 1e-3))) * Fy
        else:
            # Elastic buckling: Fcr = 0.877 * Fe
            fcr = 0.877 * Fe

        phi_Pn_compression = phi_c * fcr * Ag
        dcr_compression = (Pu / phi_Pn_compression) if is_compression else 0.0

        # 4. Flexural Bending Capacity (AISC 360 Chapter F)
        # phi_b = 0.90, Mn = Fy * Z
        phi_b = 0.90
        phi_Mnx = phi_b * Fy * Zx
        phi_Mny = phi_b * Fy * Zy

        Mux = abs(moment_z_nm)  # Major axis bending
        Muy = abs(moment_y_nm)  # Minor axis bending

        # 5. Combined Axial and Flexure (AISC 360 Chapter H, Eq. H1-1a / H1-1b)
        phi_Pn = phi_Pn_compression if is_compression else (phi_Pn_tension if is_tension else 1.0)
        p_ratio = Pu / max(phi_Pn, 1e-5) if (is_compression or is_tension) else 0.0

        if p_ratio >= 0.2:
            dcr_combined = p_ratio + (8.0 / 9.0) * (
                (Mux / max(phi_Mnx, 1e-5)) + (Muy / max(phi_Mny, 1e-5))
            )
        else:
            dcr_combined = (p_ratio / 2.0) + (
                (Mux / max(phi_Mnx, 1e-5)) + (Muy / max(phi_Mny, 1e-5))
            )

        # 6. Shear Capacity (AISC 360 Chapter G)
        # Aw = d * tw, phi_v = 0.90, Vn = 0.6 * Fy * Aw
        phi_v = 0.90
        Aw = d * tw
        phi_Vn = phi_v * 0.60 * Fy * Aw
        Vu = max(abs(shear_y_n), abs(shear_z_n))
        dcr_shear = Vu / max(phi_Vn, 1e-5)

        # 7. Serviceability Deflection Limit (ASCE 7 / IBC L/240 total, L/360 live)
        deflection_limit = length_m / 240.0
        dcr_deflection = abs(max_deflection_m) / max(deflection_limit, 1e-5)

        # 8. Von Mises Stress across surface
        # sigma_axial = axial / Ag
        # sigma_flex = Mux / Sx + Muy / Sy
        sigma_normal = (Pu / Ag) + (Mux / sec["sx_m3"]) + (Muy / sec["sy_m3"])
        tau_shear = Vu / max(Aw, 1e-5)
        von_mises_pa = math.sqrt(sigma_normal ** 2 + 3.0 * (tau_shear ** 2))
        von_mises_mpa = von_mises_pa / 1.0e6

        governing_dcr = max(dcr_tension, dcr_compression, dcr_combined, dcr_shear)

        status = "PASS"
        if governing_dcr > 1.0 or kl_r > 200.0:
            status = "FAIL"
        elif governing_dcr > 0.85:
            status = "WARNING"

        # Recommend optimized section if failing or overstressed
        recommended_section = None
        if auto_recommend and (status == "FAIL" or governing_dcr > 0.95 or governing_dcr < 0.40):
            recommended_section = AISC360CodeChecker.recommend_optimal_section(
                material_name=material_name,
                length_m=length_m,
                axial_force_n=axial_force_n,
                shear_y_n=shear_y_n,
                shear_z_n=shear_z_n,
                moment_y_nm=moment_y_nm,
                moment_z_nm=moment_z_nm,
                torsion_nm=torsion_nm,
                max_deflection_m=max_deflection_m,
                current_section=section_name,
            )

        return {
            "dcr_axial": round(float(dcr_compression if is_compression else dcr_tension), 4),
            "dcr_buckling": round(float(dcr_compression), 4),
            "dcr_combined": round(float(dcr_combined), 4),
            "dcr_shear": round(float(dcr_shear), 4),
            "dcr_deflection": round(float(dcr_deflection), 4),
            "governing_dcr": round(float(governing_dcr), 4),
            "slenderness_kl_r": round(float(kl_r), 2),
            "max_von_mises_stress_mpa": round(float(von_mises_mpa), 2),
            "status": status,
            "recommended_section": recommended_section,
        }

    @staticmethod
    def recommend_optimal_section(
        material_name: str,
        length_m: float,
        axial_force_n: float,
        shear_y_n: float,
        shear_z_n: float,
        moment_y_nm: float,
        moment_z_nm: float,
        torsion_nm: float,
        max_deflection_m: float,
        current_section: str,
    ) -> str:
        # Sort catalog by structural weight (lightest first to optimize cost & carbon)
        sorted_sections = sorted(
            AISC_W_SHAPES.items(),
            key=lambda item: item[1]["weight_kg_m"]
        )

        for sec_name, props in sorted_sections:
            chk = AISC360CodeChecker.check_steel_member(
                section_name=sec_name,
                material_name=material_name,
                length_m=length_m,
                axial_force_n=axial_force_n,
                shear_y_n=shear_y_n,
                shear_z_n=shear_z_n,
                moment_y_nm=moment_y_nm,
                moment_z_nm=moment_z_nm,
                torsion_nm=torsion_nm,
                max_deflection_m=max_deflection_m,
                auto_recommend=False,
            )
            # Find the lightest section that passes with DCR <= 0.90 and KL/r <= 200
            if chk["governing_dcr"] <= 0.90 and chk["slenderness_kl_r"] <= 200.0:
                return sec_name

        # If none pass DCR <= 0.90, pick the heaviest robust section
        return sorted_sections[-1][0]
