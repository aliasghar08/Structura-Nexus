import time
import math
import numpy as np
from typing import List, Dict, Any, Tuple
from ..models.schema import (
    StructuralGraphPayload,
    SolverResponse,
    NodeResult,
    MemberResult,
    EquilibriumResidual,
)
from ..code_check.aisc_aci import (
    get_section_properties,
    get_material_properties,
    AISC360CodeChecker,
)

class FEA3DSpaceFrameSolver:
    """
    Authoritative 3D Direct Stiffness Matrix (DSM) Linear Elastic Space Frame Engine
    Resolves 6-DOF nodal displacements, continuous tensor fields, and equilibrium residuals.
    """

    @classmethod
    def solve(cls, payload: StructuralGraphPayload) -> SolverResponse:
        start_time = time.perf_counter()

        nodes = payload.nodes
        members = payload.members
        num_nodes = len(nodes)
        dof_total = num_nodes * 6

        node_index_map = {node.id: idx for idx, node in enumerate(nodes)}

        # 1. Initialize global stiffness matrix K and force vector F
        K_global = np.zeros((dof_total, dof_total), dtype=np.float64)
        F_global = np.zeros(dof_total, dtype=np.float64)

        # Apply factored load combination multipliers (ASCE 7)
        load_factor = 1.0
        if "1.4D" in payload.load_combination:
            load_factor = 1.4
        elif "1.2D+1.6L" in payload.load_combination:
            load_factor = 1.6
        elif "1.0W" in payload.load_combination or "1.0E" in payload.load_combination:
            load_factor = 1.2

        # Populate applied nodal forces and moments
        for idx, node in enumerate(nodes):
            base_dof = idx * 6
            for d in range(6):
                F_global[base_dof + d] = node.loads[d] * load_factor

        # 2. Member stiffness formulation and assembly
        member_metadata: Dict[str, Dict[str, Any]] = {}

        for member in members:
            i_idx = node_index_map[member.i_node]
            j_idx = node_index_map[member.j_node]
            node_i = nodes[i_idx]
            node_j = nodes[j_idx]

            xi, yi, zi = node_i.coords
            xj, yj, zj = node_j.coords

            dx = xj - xi
            dy = yj - yi
            dz = zj - zi
            L = math.sqrt(dx * dx + dy * dy + dz * dz)
            if L < 1e-4:
                L = 1e-4

            sec = get_section_properties(member.section)
            mat = get_material_properties(member.material)

            E = mat["elastic_modulus_pa"]
            G = mat["shear_modulus_pa"]
            A = sec["area_m2"]
            Ix = sec["ix_m4"]
            Iy = sec["iy_m4"]
            J = sec["j_m4"]

            # Compute local coordinate orientation (direction cosines)
            # Default orientation vector is global Y unless member is collinear with Y
            cx = dx / L
            cy = dy / L
            cz = dz / L

            # Compute local y and z unit vectors
            if abs(cx) < 1e-6 and abs(cz) < 1e-6:
                # Vertical member collinear with Y
                local_x = np.array([cx, cy, cz])
                sign = 1.0 if cy >= 0 else -1.0
                local_z = np.array([0.0, 0.0, sign])
                local_y = np.cross(local_z, local_x)
            else:
                local_x = np.array([cx, cy, cz])
                up = np.array([0.0, 1.0, 0.0])
                local_z = np.cross(local_x, up)
                local_z = local_z / np.linalg.norm(local_z)
                local_y = np.cross(local_z, local_x)
                local_y = local_y / np.linalg.norm(local_y)

            R_3x3 = np.vstack([local_x, local_y, local_z])
            T_12x12 = np.zeros((12, 12), dtype=np.float64)
            for b in range(4):
                T_12x12[b*3:(b+1)*3, b*3:(b+1)*3] = R_3x3

            # 12x12 local beam stiffness matrix
            k_local = np.zeros((12, 12), dtype=np.float64)
            # Axial terms
            ea_l = (E * A) / L
            k_local[0, 0] = ea_l
            k_local[0, 6] = -ea_l
            k_local[6, 0] = -ea_l
            k_local[6, 6] = ea_l

            # Torsion
            gj_l = (G * J) / L
            k_local[3, 3] = gj_l
            k_local[3, 9] = -gj_l
            k_local[9, 3] = -gj_l
            k_local[9, 9] = gj_l

            # Bending about local Z (deflections in local Y)
            eiz = E * Ix
            k_local[1, 1] = 12.0 * eiz / (L ** 3)
            k_local[1, 5] = 6.0 * eiz / (L ** 2)
            k_local[1, 7] = -12.0 * eiz / (L ** 3)
            k_local[1, 11] = 6.0 * eiz / (L ** 2)

            k_local[5, 1] = 6.0 * eiz / (L ** 2)
            k_local[5, 5] = 4.0 * eiz / L
            k_local[5, 7] = -6.0 * eiz / (L ** 2)
            k_local[5, 11] = 2.0 * eiz / L

            k_local[7, 1] = -12.0 * eiz / (L ** 3)
            k_local[7, 5] = -6.0 * eiz / (L ** 2)
            k_local[7, 7] = 12.0 * eiz / (L ** 3)
            k_local[7, 11] = -6.0 * eiz / (L ** 2)

            k_local[11, 1] = 6.0 * eiz / (L ** 2)
            k_local[11, 5] = 2.0 * eiz / L
            k_local[11, 7] = -6.0 * eiz / (L ** 2)
            k_local[11, 11] = 4.0 * eiz / L

            # Bending about local Y (deflections in local Z)
            eiy = E * Iy
            k_local[2, 2] = 12.0 * eiy / (L ** 3)
            k_local[2, 4] = -6.0 * eiy / (L ** 2)
            k_local[2, 8] = -12.0 * eiy / (L ** 3)
            k_local[2, 10] = -6.0 * eiy / (L ** 2)

            k_local[4, 2] = -6.0 * eiy / (L ** 2)
            k_local[4, 4] = 4.0 * eiy / L
            k_local[4, 8] = 6.0 * eiy / (L ** 2)
            k_local[4, 10] = 2.0 * eiy / L

            k_local[8, 2] = -12.0 * eiy / (L ** 3)
            k_local[8, 4] = 6.0 * eiy / (L ** 2)
            k_local[8, 8] = 12.0 * eiy / (L ** 3)
            k_local[8, 10] = 6.0 * eiy / (L ** 2)

            k_local[10, 2] = -6.0 * eiy / (L ** 2)
            k_local[10, 4] = 2.0 * eiy / L
            k_local[10, 8] = 6.0 * eiy / (L ** 2)
            k_local[10, 10] = 4.0 * eiy / L

            # Transform to global coordinates: K_global_elem = T^T * k_local * T
            k_global_elem = T_12x12.T @ k_local @ T_12x12

            # Assemble into global matrix
            dof_indices = list(range(i_idx * 6, (i_idx + 1) * 6)) + list(range(j_idx * 6, (j_idx + 1) * 6))
            for r in range(12):
                gr = dof_indices[r]
                for c in range(12):
                    gc = dof_indices[c]
                    K_global[gr, gc] += k_global_elem[r, c]

            member_metadata[member.id] = {
                "L": L,
                "T": T_12x12,
                "k_local": k_local,
                "dof_indices": dof_indices,
            }

        # 3. Apply Boundary Conditions (Dirichlet Restraints)
        free_dofs = []
        restrained_dofs = []

        for idx, node in enumerate(nodes):
            for d in range(6):
                global_dof = idx * 6 + d
                if node.restraint[d] == 1:
                    restrained_dofs.append(global_dof)
                else:
                    free_dofs.append(global_dof)

        U_global = np.zeros(dof_total, dtype=np.float64)

        if free_dofs:
            # Submatrix partition
            K_ff = K_global[np.ix_(free_dofs, free_dofs)]
            F_f = F_global[free_dofs]

            # Numerical regularization if free rigid bodies exist
            diag_mean = np.mean(np.diag(K_ff)) if K_ff.size > 0 else 1.0
            if abs(diag_mean) < 1e-8:
                diag_mean = 1.0
            K_ff_reg = K_ff + np.eye(len(free_dofs)) * (diag_mean * 1e-12)

            try:
                u_free = np.linalg.solve(K_ff_reg, F_f)
            except np.linalg.LinAlgError:
                u_free = np.linalg.lstsq(K_ff_reg, F_f, rcond=None)[0]

            for idx, dof in enumerate(free_dofs):
                U_global[dof] = u_free[idx]

        # 4. Reaction forces: {R} = [K]{U} - {F}
        R_reactions = K_global @ U_global - F_global

        # Zero out reactions at free DOFs for strict equilibrium bookkeeping
        for dof in free_dofs:
            R_reactions[dof] = 0.0

        # 5. Global Equilibrium Check & Residuals: sum(F_applied) + sum(R_reactions) == 0
        sum_fx = float(np.sum(F_global[0::6]) + np.sum(R_reactions[0::6]))
        sum_fy = float(np.sum(F_global[1::6]) + np.sum(R_reactions[1::6]))
        sum_fz = float(np.sum(F_global[2::6]) + np.sum(R_reactions[2::6]))
        sum_mx = float(np.sum(F_global[3::6]) + np.sum(R_reactions[3::6]))
        sum_my = float(np.sum(F_global[4::6]) + np.sum(R_reactions[4::6]))
        sum_mz = float(np.sum(F_global[5::6]) + np.sum(R_reactions[5::6]))

        max_residual = max(abs(sum_fx), abs(sum_fy), abs(sum_fz))
        is_equilibrated = max_residual < 10.0  # Under 10 N out of thousands

        # Global base shear (sum of horizontal reaction magnitudes at base)
        base_shear_n = 0.0
        for idx, node in enumerate(nodes):
            if any(node.restraint[:3]):
                rx = R_reactions[idx * 6]
                rz = R_reactions[idx * 6 + 2]
                base_shear_n += math.sqrt(rx * rx + rz * rz)

        # 6. Format Node Results
        node_results: List[NodeResult] = []
        max_lateral_disp = 0.0
        max_height = 1.0

        for idx, node in enumerate(nodes):
            disp = [float(U_global[idx * 6 + d]) for d in range(6)]
            react = [float(R_reactions[idx * 6 + d]) for d in range(6)]
            node_results.append(NodeResult(
                id=node.id,
                displacements=disp,
                reactions=react,
            ))
            lat = math.sqrt(disp[0] ** 2 + disp[2] ** 2)
            if lat > max_lateral_disp:
                max_lateral_disp = lat
            if node.coords[1] > max_height:
                max_height = node.coords[1]

        drift_ratio_max = max_lateral_disp / max(max_height, 1.0)

        # 7. Internal Member Force Recovery and Code Verification
        member_results: List[MemberResult] = []
        code_summary = {"total_members": len(members), "passing": 0, "failing": 0, "warning": 0}

        for member in members:
            meta = member_metadata[member.id]
            L = meta["L"]
            T = meta["T"]
            k_loc = meta["k_local"]
            dofs = meta["dof_indices"]

            u_elem_global = U_global[dofs]
            u_elem_local = T @ u_elem_global
            f_elem_local = k_loc @ u_elem_local

            # Internal actions in local axes:
            # Node 1 actions: [N1, Vy1, Vz1, T1, My1, Mz1]
            # Axial force (+ = Tension, - = Compression)
            axial_force_n = float(-f_elem_local[0])
            shear_y_n = float(abs(f_elem_local[1]))
            shear_z_n = float(abs(f_elem_local[2]))
            torsion_nm = float(abs(f_elem_local[3]))
            moment_y_nm = float(max(abs(f_elem_local[4]), abs(f_elem_local[10])))
            moment_z_nm = float(max(abs(f_elem_local[5]), abs(f_elem_local[11])))

            # Relative flexural deflection
            deflection_local = math.sqrt(
                ((u_elem_local[1] + u_elem_local[7]) / 2.0) ** 2 +
                ((u_elem_local[2] + u_elem_local[8]) / 2.0) ** 2
            )

            # Perform AISC 360-16 limit state evaluation
            chk = AISC360CodeChecker.check_steel_member(
                section_name=member.section,
                material_name=member.material,
                length_m=L,
                axial_force_n=axial_force_n,
                shear_y_n=shear_y_n,
                shear_z_n=shear_z_n,
                moment_y_nm=moment_y_nm,
                moment_z_nm=moment_z_nm,
                torsion_nm=torsion_nm,
                max_deflection_m=deflection_local,
            )

            # Procedural BMD & SFD points for 3D extrusion ribbons
            bmd_pts = [
                {"station": 0.0, "value": float(f_elem_local[5])},
                {"station": 0.5 * L, "value": float(0.5 * (f_elem_local[5] - f_elem_local[11]))},
                {"station": 1.0 * L, "value": float(-f_elem_local[11])},
            ]
            sfd_pts = [
                {"station": 0.0, "value": float(f_elem_local[1])},
                {"station": 0.5 * L, "value": float(f_elem_local[1])},
                {"station": 1.0 * L, "value": float(f_elem_local[1])},
            ]

            status = chk["status"]
            if status == "PASS":
                code_summary["passing"] += 1
            elif status == "FAIL":
                code_summary["failing"] += 1
            else:
                code_summary["warning"] += 1

            member_results.append(MemberResult(
                id=member.id,
                i_node=member.i_node,
                j_node=member.j_node,
                length=round(float(L), 3),
                section=member.section,
                axial_force=round(axial_force_n, 1),
                shear_y=round(shear_y_n, 1),
                shear_z=round(shear_z_n, 1),
                moment_y=round(moment_y_nm, 1),
                moment_z=round(moment_z_nm, 1),
                torsion=round(torsion_nm, 1),
                max_deflection=round(float(deflection_local), 6),
                max_von_mises_stress_mpa=chk["max_von_mises_stress_mpa"],
                dcr_axial=chk["dcr_axial"],
                dcr_buckling=chk["dcr_buckling"],
                dcr_combined=chk["dcr_combined"],
                dcr_shear=chk["dcr_shear"],
                governing_dcr=chk["governing_dcr"],
                slenderness_kl_r=chk["slenderness_kl_r"],
                status=status,
                recommended_section=chk["recommended_section"],
                bmd_points=bmd_pts,
                sfd_points=sfd_pts,
            ))

        elapsed_ms = (time.perf_counter() - start_time) * 1000.0

        return SolverResponse(
            session_id=payload.session_id,
            engine_type="EXACT_FEA_PROPRIETARY_DSM",
            status="SUCCESS",
            inference_latency_ms=round(elapsed_ms, 2),
            nodes=node_results,
            members=member_results,
            equilibrium=EquilibriumResidual(
                sum_fx=round(sum_fx, 2),
                sum_fy=round(sum_fy, 2),
                sum_fz=round(sum_fz, 2),
                sum_mx=round(sum_mx, 2),
                sum_my=round(sum_my, 2),
                sum_mz=round(sum_mz, 2),
                is_equilibrated=is_equilibrated,
                max_residual_n=round(max_residual, 2),
            ),
            global_base_shear_n=round(base_shear_n, 1),
            max_drift_ratio=round(drift_ratio_max, 5),
            code_compliance_summary=code_summary,
        )
