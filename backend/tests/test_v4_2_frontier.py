"""
STRUCTURA NEXUS v4.2 — FRONTIER TESTS
Validates Neural SIMP 3D Diagrid Topology Optimization, Shop-Drawing AISC/ACI Visual QA,
and Gemini Live Spatial Voice Co-Pilot.
"""

import pytest
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.ai.topology_diffusion import (
    TopologyDiffusionEngine,
    TopologyOptimizationRequest,
)
from backend.app.ai.shop_drawing_auditor import (
    ShopDrawingAuditor,
    ShopDrawingAuditRequest,
)
from backend.app.ai.voice_copilot import VoiceCopilotParser
from backend.app.solvers.fea_engine import FEA3DSpaceFrameSolver


@pytest.fixture
def client():
    return TestClient(app)


def test_neural_simp_topology_diagrid_equilibrium():
    """Verify Neural SIMP 3D Diagrid synthesis achieves 18-30% mass reduction and passes 12-DOF DSM solve."""
    req = TopologyOptimizationRequest(
        bounding_box_dims=[12.0, 24.0, 12.0],
        target_volume_fraction=0.35,
        topology_style="diagrid",
    )
    res = TopologyDiffusionEngine.synthesize_optimal_topology(req)
    assert res.status == "SUCCESS"
    assert 18.0 <= res.mass_reduction_pct <= 32.0
    assert res.num_nodes > 20
    assert res.num_members > 50

    # Verify 12-DOF Direct Stiffness Matrix solve
    solve_res = FEA3DSpaceFrameSolver.solve(res.synthesized_graph)
    assert solve_res.status == "SUCCESS"
    assert solve_res.equilibrium.is_equilibrated is True


def test_neural_simp_voronoi_and_truss_styles():
    """Test alternate topology styles: voronoi_exoskeleton and variable_truss."""
    req_voronoi = TopologyOptimizationRequest(
        bounding_box_dims=[10.0, 20.0, 10.0],
        target_volume_fraction=0.40,
        topology_style="voronoi_exoskeleton",
    )
    res_voronoi = TopologyDiffusionEngine.synthesize_optimal_topology(req_voronoi)
    assert res_voronoi.status == "SUCCESS"
    assert res_voronoi.topology_style == "voronoi_exoskeleton"

    req_truss = TopologyOptimizationRequest(
        bounding_box_dims=[12.0, 18.0, 12.0],
        target_volume_fraction=0.30,
        topology_style="variable_truss",
    )
    res_truss = TopologyDiffusionEngine.synthesize_optimal_topology(req_truss)
    assert res_truss.status == "SUCCESS"
    assert res_truss.topology_style == "variable_truss"


def test_shop_drawing_auditor_aisc_presets():
    """Verify AISC 360-16 Chapter J compliance for moment endplate and baseplate."""
    # Compliant preset
    req_pass = ShopDrawingAuditRequest(preset_id="Bolted_Moment_EndPlate.png")
    res_pass = ShopDrawingAuditor.audit_connection(req_pass)
    assert res_pass.overall_status == "PASSED"
    assert res_pass.compliance_score >= 95.0
    assert any("AISC-J3.4" in p.code for p in res_pass.punchlist)

    # Defective baseplate preset (insufficient edge distance)
    req_fail = ShopDrawingAuditRequest(preset_id="Column_Baseplate_Anchor.png")
    res_fail = ShopDrawingAuditor.audit_connection(req_fail)
    assert res_fail.overall_status == "REJECTED_WITH_PUNCHLIST"
    assert res_fail.compliance_score < 75.0
    critical_items = [p for p in res_fail.punchlist if p.severity == "CRITICAL_FAIL"]
    assert len(critical_items) >= 1
    assert "AISC-J3.4-EDGE-DIST" in critical_items[0].code


def test_shop_drawing_auditor_aci_rebar_cage():
    """Verify ACI 318-19 Chapter 25 compliance for tied RC column rebar cage."""
    req = ShopDrawingAuditRequest(preset_id="RC_Column_Rebar_Cage.png")
    res = ShopDrawingAuditor.audit_connection(req)
    assert res.overall_status == "PASSED"
    assert res.compliance_score >= 95.0
    assert any("ACI-25.2.1" in p.code for p in res.punchlist)
    assert any("ACI-25.7.2" in p.code for p in res.punchlist)


def test_voice_copilot_command_parsing():
    """Verify spatial voice engineering commands parse into deterministic structural actions."""
    # 1. Chevron Bracing
    cmd1 = VoiceCopilotParser.process_command("Add chevron bracing to the core bays")
    assert cmd1.action == "add_chevron_bracing"
    assert "chevron" in cmd1.spoken_feedback.lower()

    # 2. Wind Loads
    cmd2 = VoiceCopilotParser.process_command("Apply 145 mph Exposure D wind loads")
    assert cmd2.action == "apply_wind_loads"
    assert cmd2.parameters["wind_speed_mph"] == 145.0
    assert cmd2.parameters["exposure_category"] == "D"

    # 3. Highlights
    cmd3 = VoiceCopilotParser.process_command("Highlight columns with DCR above 0.85 or B2 above 1.15")
    assert cmd3.action == "highlight_members"
    assert len(cmd3.highlight_member_ids) > 0

    # 4. Auto-sizer
    cmd4 = VoiceCopilotParser.process_command("Run auto-sizer")
    assert cmd4.action == "run_auto_sizer"


def test_v4_2_fastapi_endpoints(client):
    """End-to-end HTTP integration tests for /api/v4 endpoints."""
    # Topology
    r_topo = client.post("/api/v4/ai/topology-optimize", json={
        "bounding_box_dims": [12.0, 24.0, 12.0],
        "target_volume_fraction": 0.35,
        "topology_style": "diagrid",
    })
    assert r_topo.status_code == 200
    assert r_topo.json()["status"] == "SUCCESS"

    # Shop Drawing
    r_shop = client.post("/api/v4/ai/audit-shop-drawing", json={
        "preset_id": "Bolted_Moment_EndPlate.png"
    })
    assert r_shop.status_code == 200
    assert r_shop.json()["overall_status"] == "PASSED"

    # Voice Command
    r_voice = client.post("/api/v4/ai/voice-command", json={
        "command": "Add chevron bracing to the core bays"
    })
    assert r_voice.status_code == 200
    assert r_voice.json()["action"] == "add_chevron_bracing"
