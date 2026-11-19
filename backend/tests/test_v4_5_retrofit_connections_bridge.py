"""
Structura Nexus v4.5 Backend Verification Suite:
1. UFC 4-023-03 Catenary Tie-Force Sizing & Double-Span Retrofit Convergence
2. AISC 360-16 Chapter J Shear-Tab, Moment End-Plate, Gusset & Baseplate Limit States
3. AASHTO LRFD HL-93 Moving-Load Envelope Symmetry & Influence-Line Ordinates (36m Pratt Truss Bridge)
Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
"""

import math
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.models.schema import StructuralGraphPayload, NodeModel, MemberModel
from backend.app.solvers.progressive_collapse_retrofit import ProgressiveCollapseRetrofitEngine
from backend.app.code_check.aisc_connections import (
    AISC360ConnectionSynthesizer,
    ConnectionDetailRequest,
)
from backend.app.solvers.aashto_moving_load import (
    AASHTOHL93MovingLoadSolver,
    AASHTOMovingLoadRequest,
)

client = TestClient(app)


def _build_two_bay_two_story_frame() -> StructuralGraphPayload:
    nodes = [
        NodeModel(id="N1", coords=[0.0, 0.0, 0.0], restraint=[1, 1, 1, 1, 1, 1], loads=[0, 0, 0, 0, 0, 0]),
        NodeModel(id="N2", coords=[6.0, 0.0, 0.0], restraint=[1, 1, 1, 1, 1, 1], loads=[0, 0, 0, 0, 0, 0]),
        NodeModel(id="N3", coords=[12.0, 0.0, 0.0], restraint=[1, 1, 1, 1, 1, 1], loads=[0, 0, 0, 0, 0, 0]),
        NodeModel(id="N4", coords=[0.0, 3.6, 0.0], restraint=[0, 0, 0, 0, 0, 0], loads=[0, -90000.0, 0, 0, 0, 0]),
        NodeModel(id="N5", coords=[6.0, 3.6, 0.0], restraint=[0, 0, 0, 0, 0, 0], loads=[0, -180000.0, 0, 0, 0, 0]),
        NodeModel(id="N6", coords=[12.0, 3.6, 0.0], restraint=[0, 0, 0, 0, 0, 0], loads=[0, -90000.0, 0, 0, 0, 0]),
        NodeModel(id="N7", coords=[0.0, 7.2, 0.0], restraint=[0, 0, 0, 0, 0, 0], loads=[0, -90000.0, 0, 0, 0, 0]),
        NodeModel(id="N8", coords=[6.0, 7.2, 0.0], restraint=[0, 0, 0, 0, 0, 0], loads=[0, -180000.0, 0, 0, 0, 0]),
        NodeModel(id="N9", coords=[12.0, 7.2, 0.0], restraint=[0, 0, 0, 0, 0, 0], loads=[0, -90000.0, 0, 0, 0, 0]),
    ]
    members = [
        MemberModel(id="C1", i_node="N1", j_node="N4", section="W12X26", material="A992_Steel"),
        MemberModel(id="C2", i_node="N2", j_node="N5", section="W12X26", material="A992_Steel"),
        MemberModel(id="C3", i_node="N3", j_node="N6", section="W12X26", material="A992_Steel"),
        MemberModel(id="C4", i_node="N4", j_node="N7", section="W12X26", material="A992_Steel"),
        MemberModel(id="C5", i_node="N5", j_node="N8", section="W12X26", material="A992_Steel"),
        MemberModel(id="C6", i_node="N6", j_node="N9", section="W12X26", material="A992_Steel"),
        MemberModel(id="B1", i_node="N4", j_node="N5", section="W12X26", material="A992_Steel"),
        MemberModel(id="B2", i_node="N5", j_node="N6", section="W12X26", material="A992_Steel"),
        MemberModel(id="B3", i_node="N7", j_node="N8", section="W12X26", material="A992_Steel"),
        MemberModel(id="B4", i_node="N8", j_node="N9", section="W12X26", material="A992_Steel"),
    ]
    return StructuralGraphPayload(action="SOLVE", nodes=nodes, members=members)


def _build_36m_pratt_truss_bridge() -> StructuralGraphPayload:
    # 6 panels of 6.0m = 36.0m span, height = 6.0m
    nodes = []
    for i in range(7):
        x = i * 6.0
        restraint = [0, 0, 0, 0, 0, 0]
        if i == 0:
            restraint = [1, 1, 1, 1, 1, 0]
        elif i == 6:
            restraint = [0, 1, 1, 1, 1, 0]
        nodes.append(NodeModel(id=f"B{i}", coords=[x, 0.0, 0.0], restraint=restraint, loads=[0, 0, 0, 0, 0, 0]))
        if 0 < i < 6:
            nodes.append(NodeModel(id=f"T{i}", coords=[x, 6.0, 0.0], restraint=[0, 0, 1, 0, 0, 0], loads=[0, 0, 0, 0, 0, 0]))

    members = []
    # Bottom chord
    for i in range(6):
        members.append(MemberModel(id=f"BC_{i+1}", i_node=f"B{i}", j_node=f"B{i+1}", section="W14X90", material="A992_Steel"))
    # Top chord
    for i in range(1, 5):
        members.append(MemberModel(id=f"TC_{i}", i_node=f"T{i}", j_node=f"T{i+1}", section="W14X90", material="A992_Steel"))
    # End inclined portals
    members.append(MemberModel(id="EP_L", i_node="B0", j_node="T1", section="W14X90", material="A992_Steel"))
    members.append(MemberModel(id="EP_R", i_node="T5", j_node="B6", section="W14X90", material="A992_Steel"))
    # Verticals
    for i in range(1, 6):
        members.append(MemberModel(id=f"V_{i}", i_node=f"B{i}", j_node=f"T{i}", section="W14X48", material="A992_Steel"))
    # Pratt diagonals (sloping toward center)
    members.append(MemberModel(id="D_1", i_node="T1", j_node="B2", section="W14X48", material="A992_Steel"))
    members.append(MemberModel(id="D_2", i_node="T2", j_node="B3", section="W14X48", material="A992_Steel"))
    members.append(MemberModel(id="D_3", i_node="B3", j_node="T4", section="W14X48", material="A992_Steel"))
    members.append(MemberModel(id="D_4", i_node="B4", j_node="T5", section="W14X48", material="A992_Steel"))

    return StructuralGraphPayload(action="SOLVE", nodes=nodes, members=members)


def test_ufc_4_023_03_tie_sizing_and_double_span_retrofit():
    ties = ProgressiveCollapseRetrofitEngine.size_ufc_catenary_ties(
        dead_load_kpa=4.8,
        live_load_kpa=2.4,
        span_l1_m=6.0,
        span_l2_m=6.0,
    )
    # w_F = 1.2*4.8 + 0.5*2.4 = 6.96 kPa
    assert abs(ties.floor_load_wf_kpa - 6.96) < 1e-3
    assert ties.provided_tie_capacity_kn >= ties.governing_tie_demand_kn
    assert ties.tie_dcr <= 1.0

    frame = _build_two_bay_two_story_frame()
    report = ProgressiveCollapseRetrofitEngine.auto_retrofit(
        payload=frame,
        removed_member_id="C2",
        dynamic_amplification_factor=2.0,
        theta_allow_rad=0.035,
    )
    assert report.converged is True
    assert report.theta_after_rad <= report.theta_allow_rad
    assert report.dcr_alp_after <= 0.95
    assert report.robustness_after >= 85.0
    assert report.added_steel_mass_kg > 0.0


def test_aisc_360_16_chapter_j_connections_and_endpoint():
    # 1. Shear Tab against hand calculation: 4x 7/8" (22.225 mm) A325 bolts
    # Ab = pi * 22.225^2 / 4 = 387.95 mm^2
    # phi_Rn_bolt_shear = 0.75 * 372 * 387.95 * 4 / 1000 = 432.95 kN
    shear_req = ConnectionDetailRequest(
        connection_type="SHEAR_TAB",
        shear_vu_kn=210.0,
        bolt_grade="A325",
        bolt_diameter_mm=22.225,
        num_bolts=4,
        plate_thickness_mm=12.7,
    )
    shear_res = AISC360ConnectionSynthesizer.evaluate(shear_req)
    bolt_shear_check = shear_res.limit_states[0]
    assert abs(bolt_shear_check.capacity_phi_rn - 432.95) < 0.5
    assert shear_res.overall_status == "PASS"
    assert len(shear_res.bolts_3d) == 4

    # 2. Extended Moment End-Plate (8-bolt)
    moment_req = ConnectionDetailRequest(
        connection_type="MOMENT_END_PLATE",
        moment_mu_knm=320.0,
        shear_vu_kn=180.0,
        num_bolts=8,
        plate_thickness_mm=25.4,
    )
    moment_res = AISC360ConnectionSynthesizer.evaluate(moment_req)
    assert len(moment_res.limit_states) == 5
    assert len(moment_res.bolts_3d) == 8

    # 3. Braced-Frame Gusset Plate (Whitmore 30-deg check)
    gusset_req = ConnectionDetailRequest(
        connection_type="GUSSET_PLATE",
        axial_pu_kn=550.0,
        num_bolts=6,
        bolt_pitch_mm=76.2,
        bolt_gauge_mm=140.0,
        plate_thickness_mm=16.0,
    )
    gusset_res = AISC360ConnectionSynthesizer.evaluate(gusset_req)
    # Whitmore width Lw = 140 + 2 * (2 * 76.2) * tan(30) = 140 + 304.8 * 0.57735 = 316.0 mm
    assert gusset_res.whitmore_width_mm is not None
    assert abs(gusset_res.whitmore_width_mm - 316.0) < 0.5

    # 4. Baseplate via FastAPI endpoint
    resp = client.post(
        "/api/v1/design/connection-detail",
        json={
            "connection_type": "BASEPLATE",
            "axial_pu_kn": 1200.0,
            "shear_vu_kn": 95.0,
            "plate_thickness_mm": 25.4,
            "fc_concrete_mpa": 28.0,
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["connection_type"] == "BASEPLATE"
    assert len(data["limit_states"]) == 3


def test_aashto_hl93_moving_load_pratt_truss_symmetry_and_influence_lines():
    bridge = _build_36m_pratt_truss_bridge()
    req = AASHTOMovingLoadRequest(
        model=bridge,
        vehicle_type="HL93_TRUCK_PLUS_LANE",
        num_steps=40,
        target_influence_member_id="BC_3",
    )
    res = AASHTOHL93MovingLoadSolver.solve_envelopes(req)
    assert res.span_length_m == 36.0
    assert len(res.step_snapshots) == 40
    assert len(res.influence_line_ordinates) == 40
    assert len(res.member_envelopes) == len(bridge.members)

    # Check envelope symmetry between symmetric left/right bottom chord panels BC_1 and BC_6
    env_map = {e.member_id: e for e in res.member_envelopes}
    bc1 = env_map["BC_1"]
    bc6 = env_map["BC_6"]
    assert abs(bc1.p_max_kn - bc6.p_max_kn) / max(1.0, abs(bc1.p_max_kn)) < 0.15
    assert res.max_fatigue_stress_range_mpa > 0.0

