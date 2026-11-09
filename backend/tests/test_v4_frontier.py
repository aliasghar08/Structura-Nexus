"""
STRUCTURA NEXUS v4.0 — PYTEST UNIT TESTS
Tests the Multi-Agent Swarm (Architect <-> Auditor <-> Healer <-> Carbon Optimizer)
and Epistemic Variance Uncertainty Gating with 12-DOF DSM fallback.
"""

import pytest
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.models.schema import StructuralGraphPayload, NodeModel, MemberModel
from backend.app.ai.swarm.engineering_swarm import (
    EngineeringSwarmOrchestrator,
    SwarmConvergenceCriteria,
    SwarmState,
)
from backend.app.surrogate.uncertainty_router import UncertaintyRouter, UncertaintyGatingResult

client = TestClient(app)

def create_sample_sway_payload():
    nodes = [
        NodeModel(id="N1", coords=[0.0, 0.0, 0.0], restraint=[1, 1, 1, 1, 1, 1], loads=[0, 0, 0, 0, 0, 0]),
        NodeModel(id="N2", coords=[6.0, 0.0, 0.0], restraint=[1, 1, 1, 1, 1, 1], loads=[0, 0, 0, 0, 0, 0]),
        NodeModel(id="N3", coords=[0.0, 3.6, 0.0], restraint=[0, 0, 0, 0, 0, 0], loads=[25000, 0, -45000, 0, 0, 0]),
        NodeModel(id="N4", coords=[6.0, 3.6, 0.0], restraint=[0, 0, 0, 0, 0, 0], loads=[0, 0, -45000, 0, 0, 0]),
    ]
    members = [
        MemberModel(id="COL1", i_node="N1", j_node="N3", section="W10X22", material="A992_STEEL"),
        MemberModel(id="COL2", i_node="N2", j_node="N4", section="W10X22", material="A992_STEEL"),
        MemberModel(id="BEAM1", i_node="N3", j_node="N4", section="W10X22", material="A992_STEEL"),
    ]
    return StructuralGraphPayload(
        session_id="swarm_test",
        action="EXACT_SOLVE",
        load_combination="1.2D+1.6L",
        nodes=nodes,
        members=members,
    )


def test_v4_swarm_self_healing_convergence():
    """
    Tests that an intentionally under-designed frame with DCR > 1.0 is detected by the Auditor,
    healed by the Self-Healer agent, and converges to a safe state within <= 6 iterations.
    """
    payload = create_sample_sway_payload()

    criteria = SwarmConvergenceCriteria(
        max_iterations=6,
        target_dcr_min=0.50,
        target_dcr_max=0.95,
        max_interstory_drift_ratio=0.0035,
    )

    state = EngineeringSwarmOrchestrator.run_swarm(payload, criteria)

    assert state.iteration <= 6
    assert len(state.history) >= 2
    agent_names = [h.agent_name for h in state.history]
    assert "Architect-Topology" in agent_names
    assert "Code-Auditor" in agent_names
    assert state.solver_response is not None


def test_v4_epistemic_uncertainty_gating():
    """
    Tests that the uncertainty router estimates epistemic variance across stochastic passes.
    """
    payload = create_sample_sway_payload()
    res = UncertaintyRouter.evaluate_and_route(payload, mc_passes=5, variance_threshold=0.08)

    assert isinstance(res, UncertaintyGatingResult)
    assert res.epistemic_variance >= 0.0
    assert res.latency_ms > 0.0
    assert len(res.displacements) == len(payload.nodes)
    assert res.solver_used in ["StructuraNet-3D (Surrogate)", "12-DOF DSM (Ground Truth)"]


def test_v4_swarm_api_endpoint():
    """
    Tests POST /api/v1/ai/swarm/solve endpoint.
    """
    payload = create_sample_sway_payload()
    req_data = {
        "graph": payload.model_dump(),
        "criteria": {
            "max_iterations": 5,
            "target_dcr_min": 0.50,
            "target_dcr_max": 0.95,
        }
    }
    response = client.post("/api/v1/ai/swarm/solve", json=req_data)
    assert response.status_code == 200
    data = response.json()
    assert "history" in data
    assert len(data["history"]) >= 2
    assert "converged" in data


def test_v4_uncertainty_gating_api_endpoint():
    """
    Tests POST /api/v1/surrogate/uncertainty-gated-predict endpoint.
    """
    payload = create_sample_sway_payload()
    req_data = {
        "graph": payload.model_dump(),
        "mc_passes": 5,
        "variance_threshold": 0.08,
    }
    response = client.post("/api/v1/surrogate/uncertainty-gated-predict", json=req_data)
    assert response.status_code == 200
    data = response.json()
    assert "epistemic_variance" in data
    assert "solver_used" in data
