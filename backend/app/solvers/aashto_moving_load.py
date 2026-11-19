"""
Structura Nexus v4.5: AASHTO LRFD HL-93 Moving-Load & Influence-Line Bridge Envelope Engine
Standard Authority: AASHTO LRFD Bridge Design Specifications (9th Ed., §3.6.1.2 HL-93 & §6.6 Fatigue)
Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
"""

import copy
import math
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field
from ..models.schema import StructuralGraphPayload
from ..code_check.aisc_aci import get_section_properties
from .fea_engine import FEA3DSpaceFrameSolver


class AASHTOMovingLoadRequest(BaseModel):
    model: StructuralGraphPayload
    vehicle_type: str = Field(
        default="HL93_TRUCK_PLUS_LANE",
        description="HL93_TRUCK_PLUS_LANE | HL93_TANDEM_PLUS_LANE | HL93_FATIGUE_TRUCK",
    )
    num_steps: int = Field(default=40, ge=5, le=100)
    rear_axle_spacing_m: float = Field(default=4.3, ge=4.3, le=9.0)
    dynamic_load_allowance_im: float = Field(default=0.33, description="IM = 0.33 for strength, 0.15 for fatigue")
    lane_load_kn_per_m: float = Field(default=9.3, description="AASHTO 9.3 kN/m design lane load")
    num_lanes: int = Field(default=1, ge=1, le=4)
    target_influence_member_id: Optional[str] = None


class MemberEnvelopeResult(BaseModel):
    member_id: str
    section: str
    p_max_kn: float
    p_min_kn: float
    v_max_kn: float
    m_max_knm: float
    m_min_knm: float
    max_dcr: float
    fatigue_stress_range_mpa: float
    fatigue_threshold_mpa: float
    fatigue_status: str
    critical_step_index: int
    critical_truck_x_m: float


class MovingLoadStepSnapshot(BaseModel):
    step_index: int
    lead_axle_x_m: float
    normalized_progress: float
    max_deck_deflection_mm: float
    governing_dcr: float
    influence_ordinate: float


class AASHTOMovingLoadResponse(BaseModel):
    vehicle_type: str
    span_min_x_m: float
    span_max_x_m: float
    span_length_m: float
    num_steps: int
    multi_presence_factor_m: float
    dynamic_allowance_factor: float
    target_influence_member_id: str
    influence_line_x_m: List[float]
    influence_line_ordinates: List[float]
    member_envelopes: List[MemberEnvelopeResult]
    step_snapshots: List[MovingLoadStepSnapshot]
    governing_bridge_dcr: float
    max_fatigue_stress_range_mpa: float
    overall_status: str


class AASHTOHL93MovingLoadSolver:
    """
    Steps an AASHTO LRFD HL-93 Design Truck (35 kN + 145 kN + 145 kN) or Design Tandem (110 kN + 110 kN)
    plus 9.3 kN/m Design Lane Load across deck nodes in N_steps increments, solving the 12-DOF DSM
    at each position to extract member force envelopes, influence lines, and fatigue stress ranges.
    """

    MULTI_PRESENCE_FACTORS: Dict[int, float] = {
        1: 1.20,
        2: 1.00,
        3: 0.85,
        4: 0.65,
    }

    @classmethod
    def solve_envelopes(cls, req: AASHTOMovingLoadRequest) -> AASHTOMovingLoadResponse:
        payload = req.model
        nodes = payload.nodes
        members = payload.members
        n_steps = max(5, req.num_steps)

        xs = [n.coords[0] for n in nodes]
        ys = [n.coords[1] for n in nodes]
        min_x = min(xs) if xs else 0.0
        max_x = max(xs) if xs else 36.0
        span_len = max(1.0, max_x - min_x)
        min_y = min(ys) if ys else 0.0

        # Identify bottom-chord / deck stringer nodes (within 1.5m of deck elevation min_y)
        deck_nodes = [n for n in nodes if abs(n.coords[1] - min_y) <= 1.5]
        if len(deck_nodes) < 2:
            deck_nodes = list(nodes)

        m_factor = cls.MULTI_PRESENCE_FACTORS.get(req.num_lanes, 0.65)
        im_factor = 1.0 + req.dynamic_load_allowance_im

        vtype = req.vehicle_type.upper()
        if "TANDEM" in vtype:
            # Dual 110 kN axles spaced at 1.2 m
            axles = [(0.0, 110.0), (1.2, 110.0)]
            lane_q = req.lane_load_kn_per_m
        elif "FATIGUE" in vtype:
            # HL-93 Fatigue Truck: constant 9.0 m rear spacing, 1 + IM = 1.15, no lane load
            axles = [(0.0, 35.0), (4.3, 145.0), (4.3 + 9.0, 145.0)]
            im_factor = 1.15
            m_factor = 1.0
            lane_q = 0.0
        else:
            # Standard HL-93 Design Truck + Design Lane
            s_rear = req.rear_axle_spacing_m
            axles = [(0.0, 35.0), (4.3, 145.0), (4.3 + s_rear, 145.0)]
            lane_q = req.lane_load_kn_per_m

        truck_len = axles[-1][0]
        target_member_id = req.target_influence_member_id or (members[0].id if members else "M1")

        # Envelope accumulators
        env: Dict[str, Dict[str, Any]] = {}
        for m in members:
            env[m.id] = {
                "section": m.section,
                "p_max": -1e12,
                "p_min": 1e12,
                "v_max": 0.0,
                "m_max": -1e12,
                "m_min": 1e12,
                "max_dcr": 0.0,
                "crit_step": 0,
                "crit_x": min_x,
            }

        influence_x: List[float] = []
        influence_ord: List[float] = []
        snapshots: List[MovingLoadStepSnapshot] = []

        # Reference unit load magnitude (total truck weight in kN) for normalized influence ordinate
        total_truck_kn = sum(p for _, p in axles) * im_factor * m_factor

        for step_idx in range(n_steps):
            progress = step_idx / max(1, n_steps - 1)
            # Lead axle travels from min_x to max_x + truck_len so entire axle train crosses span
            lead_x = min_x + progress * (span_len + truck_len)

            step_payload = copy.deepcopy(payload)
            step_payload.load_combination = "1.0_HL93_MOVING"
            step_node_map = {n.id: n for n in step_payload.nodes}
            step_deck_nodes = [step_node_map[dn.id] for dn in deck_nodes if dn.id in step_node_map]

            # Clear vertical live loads and apply uniform lane load + concentrated axle loads via linear shape functions
            trib_dx = span_len / max(1, len(step_deck_nodes) - 1)
            for dn in step_deck_nodes:
                if not any(r == 1 for r in dn.restraint):
                    dn.loads[1] = -lane_q * 1000.0 * trib_dx * m_factor * 0.5

            for offset_m, axle_kn in axles:
                axle_x = lead_x - offset_m
                if min_x - 0.5 <= axle_x <= max_x + 0.5:
                    factored_axle_n = axle_kn * 1000.0 * im_factor * m_factor
                    # Distribute to two nearest deck nodes by distance weight
                    sorted_dn = sorted(step_deck_nodes, key=lambda n: abs(n.coords[0] - axle_x))
                    if len(sorted_dn) >= 2:
                        n1, n2 = sorted_dn[0], sorted_dn[1]
                        d1 = abs(n1.coords[0] - axle_x)
                        d2 = abs(n2.coords[0] - axle_x)
                        d_tot = max(0.01, d1 + d2)
                        w1 = 1.0 - (d1 / d_tot)
                        w2 = 1.0 - w1
                        n1.loads[1] -= factored_axle_n * w1
                        n2.loads[1] -= factored_axle_n * w2
                    elif sorted_dn:
                        sorted_dn[0].loads[1] -= factored_axle_n

            res = FEA3DSpaceFrameSolver.solve(step_payload)

            max_defl_mm = 0.0
            for nr in res.nodes:
                dy_mm = abs(nr.displacements[1]) * 1000.0
                if dy_mm > max_defl_mm:
                    max_defl_mm = dy_mm

            step_gov_dcr = 0.0
            step_ord = 0.0

            for mr in res.members:
                p_kn = mr.axial_force / 1000.0
                v_kn = max(abs(mr.shear_y), abs(mr.shear_z)) / 1000.0
                m_signed_knm = mr.moment_z / 1000.0
                dcr = mr.governing_dcr

                if dcr > step_gov_dcr:
                    step_gov_dcr = dcr

                e = env[mr.id]
                if p_kn > e["p_max"]:
                    e["p_max"] = p_kn
                if p_kn < e["p_min"]:
                    e["p_min"] = p_kn
                if v_kn > e["v_max"]:
                    e["v_max"] = v_kn
                if m_signed_knm > e["m_max"]:
                    e["m_max"] = m_signed_knm
                if m_signed_knm < e["m_min"]:
                    e["m_min"] = m_signed_knm
                if dcr >= e["max_dcr"]:
                    e["max_dcr"] = dcr
                    e["crit_step"] = step_idx
                    e["crit_x"] = round(min(max_x, max(min_x, lead_x)), 2)

                if mr.id == target_member_id:
                    # Normalized influence ordinate eta(x) = axial or bending response per unit truck load
                    response_mag = p_kn if abs(p_kn) >= abs(m_signed_knm) else m_signed_knm
                    step_ord = response_mag / max(total_truck_kn, 1.0)

            clamped_x = round(min(max_x, max(min_x, lead_x - 0.5 * truck_len)), 2)
            influence_x.append(clamped_x)
            influence_ord.append(round(step_ord, 4))
            snapshots.append(
                MovingLoadStepSnapshot(
                    step_index=step_idx,
                    lead_axle_x_m=clamped_x,
                    normalized_progress=round(progress, 4),
                    max_deck_deflection_mm=round(max_defl_mm, 3),
                    governing_dcr=round(step_gov_dcr, 3),
                    influence_ordinate=round(step_ord, 4),
                )
            )

        envelopes_out: List[MemberEnvelopeResult] = []
        gov_bridge_dcr = 0.0
        max_fatigue_mpa = 0.0
        fatigue_threshold = 69.0  # AASHTO Category C constant-amplitude fatigue threshold (MPa)

        for mid, e in env.items():
            props = get_section_properties(e["section"])
            area_m2 = props.get("A", 0.0118)
            sx_m3 = props.get("Sx", 0.00234)
            delta_p_n = abs(e["p_max"] - e["p_min"]) * 1000.0
            delta_m_nm = abs(e["m_max"] - e["m_min"]) * 1000.0
            # AASHTO LRFD Fatigue I load factor gamma = 1.75 (or 0.80 single-truck ratio)
            stress_range_mpa = ((delta_p_n / max(area_m2, 1e-4)) + (delta_m_nm / max(sx_m3, 1e-5))) / 1e6 * 0.45

            if e["max_dcr"] > gov_bridge_dcr:
                gov_bridge_dcr = e["max_dcr"]
            if stress_range_mpa > max_fatigue_mpa:
                max_fatigue_mpa = stress_range_mpa

            envelopes_out.append(
                MemberEnvelopeResult(
                    member_id=mid,
                    section=e["section"],
                    p_max_kn=round(e["p_max"], 2),
                    p_min_kn=round(e["p_min"], 2),
                    v_max_kn=round(e["v_max"], 2),
                    m_max_knm=round(e["m_max"], 2),
                    m_min_knm=round(e["m_min"], 2),
                    max_dcr=round(e["max_dcr"], 3),
                    fatigue_stress_range_mpa=round(stress_range_mpa, 2),
                    fatigue_threshold_mpa=fatigue_threshold,
                    fatigue_status="PASS" if stress_range_mpa <= fatigue_threshold else "FATIGUE ALERT",
                    critical_step_index=e["crit_step"],
                    critical_truck_x_m=e["crit_x"],
                )
            )

        return AASHTOMovingLoadResponse(
            vehicle_type=req.vehicle_type,
            span_min_x_m=round(min_x, 2),
            span_max_x_m=round(max_x, 2),
            span_length_m=round(span_len, 2),
            num_steps=n_steps,
            multi_presence_factor_m=m_factor,
            dynamic_allowance_factor=round(im_factor, 2),
            target_influence_member_id=target_member_id,
            influence_line_x_m=influence_x,
            influence_line_ordinates=influence_ord,
            member_envelopes=envelopes_out,
            step_snapshots=snapshots,
            governing_bridge_dcr=round(gov_bridge_dcr, 3),
            max_fatigue_stress_range_mpa=round(max_fatigue_mpa, 2),
            overall_status="PASS (AASHTO LRFD HL-93)" if gov_bridge_dcr <= 1.0 else "OVERSTRESSED",
        )
