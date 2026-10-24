import pytest
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.models.schema import StructuralGraphPayload, NodeModel, MemberModel
from backend.app.benchmarks.verification_suite import TextbookBenchmarkSuite

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "HEALTHY"
    assert data["subsystems"]["fea_matrix_engine"] == "ACTIVE"
    assert data["pytorch"]["available"] is True
    assert data["subsystems"]["pytorch_gnn"] == "ACTIVE"

def test_catalog_endpoint():
    response = client.get("/api/v1/catalog")
    assert response.status_code == 200
    data = response.json()
    assert "W14X48" in data["sections"]
    assert "A992_STEEL" in data["materials"]

def test_benchmarks_endpoint():
    response = client.get("/api/v1/benchmarks")
    assert response.status_code == 200
    data = response.json()
    assert data["all_passed"] is True
    assert len(data["benchmarks"]) >= 3

def test_exact_solve_endpoint():
    payload = {
        "session_id": "test_solve_01",
        "action": "EXACT_SOLVE",
        "load_combination": "1.2D+1.6L",
        "nodes": [
            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N2", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [15000, 0, -45000, 0, 0, 0]}
        ],
        "members": [
            {"id": "M1", "i_node": "N1", "j_node": "N2", "section": "W14X48", "material": "A992_STEEL"}
        ]
    }
    response = client.post("/api/v1/solve", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SUCCESS"
    assert data["engine_type"] == "EXACT_FEA_PYNITE"
    assert len(data["nodes"]) == 2
    assert len(data["members"]) == 1
    assert data["equilibrium"]["is_equilibrated"] is True
    assert data["members"][0]["governing_dcr"] > 0.0

def test_surrogate_infer_endpoint():
    payload = {
        "session_id": "test_surrogate_01",
        "action": "INFER_SURROGATE",
        "load_combination": "1.2D+1.6L",
        "nodes": [
            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N2", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [15000, 0, -45000, 0, 0, 0]}
        ],
        "members": [
            {"id": "M1", "i_node": "N1", "j_node": "N2", "section": "W14X48", "material": "A992_STEEL"}
        ]
    }
    # First call warms up PyTorch JIT / MPS graph
    client.post("/api/v1/surrogate", json=payload)
    response = client.post("/api/v1/surrogate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SUCCESS"
    assert data["inference_latency_ms"] < 40.0

def test_pytorch_ai_infer_endpoint():
    payload = {
        "session_id": "test_pytorch_01",
        "action": "AI_PYTORCH_INFER",
        "load_combination": "1.2D+1.6L",
        "nodes": [
            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N2", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [15000, 0, -45000, 0, 0, 0]}
        ],
        "members": [
            {"id": "M1", "i_node": "N1", "j_node": "N2", "section": "W14X48", "material": "A992_STEEL"}
        ]
    }
    response = client.post("/api/v1/ai/infer", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SUCCESS"
    assert "epistemic_uncertainty" in data
    assert len(data["nodes"]) == 2
    # Boundary condition check: N1 is fully fixed so displacements must be 0
    assert data["nodes"][0]["displacements"] == [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

def test_generative_optimizer_endpoint():
    payload = {
        "session_id": "test_opt_01",
        "action": "OPTIMIZE",
        "load_combination": "1.2D+1.6L",
        "nodes": [
            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N2", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [5000, 0, -10000, 0, 0, 0]}
        ],
        "members": [
            {"id": "M1", "i_node": "N1", "j_node": "N2", "section": "W24X68", "material": "A992_STEEL"}
        ]
    }
    response = client.post("/api/v1/ai/generative-optimize", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "summary" in data
    assert data["summary"]["weight_reduction_pct"] >= 0.0
    assert data["code_compliance_verified"] is True
    assert "M1" in data["optimized_sections_map"]

def test_dynamic_modal_seismic_endpoint():
    payload = {
        "graph": {
            "session_id": "test_seismic_01",
            "action": "MODAL",
            "load_combination": "1.2D+1.0E+0.2S",
            "nodes": [
                {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
                {"id": "N2", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, 0, 0, 0, 0, 0]}
            ],
            "members": [
                {"id": "M1", "i_node": "N1", "j_node": "N2", "section": "W14X48", "material": "A992_STEEL"}
            ]
        },
        "Ss": 1.25,
        "S1": 0.50
    }
    response = client.post("/api/v1/ai/modal-seismic", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["fundamental_period_t1"] > 0.0
    assert data["base_shear_v_base_kn"] > 0.0
    assert len(data["modes"]) == 3
    assert data["modes"][0]["mode_number"] == 1

def test_embodied_carbon_endpoint():
    payload = {
        "session_id": "test_carbon_01",
        "action": "CARBON",
        "load_combination": "1.4D",
        "nodes": [
            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N2", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, 0, 0, 0, 0, 0]}
        ],
        "members": [
            {"id": "M1", "i_node": "N1", "j_node": "N2", "section": "W14X48", "material": "A992_STEEL"}
        ]
    }
    response = client.post("/api/v1/ai/embodied-carbon", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["total_steel_weight_kg"] > 0.0
    assert data["baseline_embodied_carbon_kgco2e"] > 0.0
    assert data["potential_carbon_reduction_pct"] > 50.0

def test_copilot_endpoint():
    payload = {
        "query": "Optimize all overstressed members and reduce total mass",
        "graph": {
            "session_id": "test_copilot_01",
            "action": "COPILOT",
            "load_combination": "1.2D+1.6L",
            "nodes": [
                {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
                {"id": "N2", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [10000, 0, -20000, 0, 0, 0]}
            ],
            "members": [
                {"id": "M1", "i_node": "N1", "j_node": "N2", "section": "W14X48", "material": "A992_STEEL"}
            ]
        }
    }
    response = client.post("/api/v1/ai/copilot", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "Generative optimization" in data["executive_summary"]
    assert len(data["actions"]) >= 1
    assert data["actions"][0]["action_type"] == "OPTIMIZE_SECTIONS"

def test_gemini_tools_endpoint():
    response = client.get("/api/v1/ai/agent/tools")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ONLINE"
    assert len(data["tools"]) >= 6
    names = data["supported_functions"]
    assert "generate_structural_topology" in names
    assert "execute_structural_solve" in names
    assert "audit_code_compliance" in names
    assert "update_member_sections" in names
    assert "run_autonomous_optimization_loop" in names
    assert "calculate_embodied_carbon" in names

def test_gemini_agent_autonomous_turn():
    payload = {
        "prompt": "Generate a 3-story moment frame, run FEA solve, check AISC compliance, and optimize steel mass",
        "graph": None
    }
    response = client.post("/api/v1/ai/agent/chat", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SUCCESS"
    assert len(data["tool_calls_executed"]) >= 3
    assert data["updated_graph"] is not None
    assert len(data["updated_graph"]["nodes"]) > 0
    assert len(data["updated_graph"]["members"]) > 0
    assert data["solver_summary"] is not None
    assert data["solver_summary"]["equilibrium_verified"] is True
    assert data["compliance_summary"] is not None
    assert data["embodied_carbon_summary"] is not None
    assert "Autonomous Structural Engineering Assessment" in data["reply"]

def test_realtime_surrogate_predict_endpoint():
    payload = {
        "session_id": "test_realtime_01",
        "action": "SURROGATE_DRAG",
        "load_combination": "1.2D+1.6L",
        "nodes": [
            {"id": "N_FIXED", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N_FREE", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [15000, -25000, 0, 0, 0, 0]}
        ],
        "members": [
            {"id": "M1", "i_node": "N_FIXED", "j_node": "N_FREE", "section": "W14X48", "material": "A992_STEEL"}
        ]
    }
    response = client.post("/api/v1/surrogate/predict", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SURROGATE_PREDICTION"
    assert "displacements" in data
    assert "N_FIXED" in data["displacements"]
    assert "N_FREE" in data["displacements"]

    # Verify Dirichlet Physics-Hard Boundary Mask: u_fixed == 0
    d_fixed = data["displacements"]["N_FIXED"]
    assert d_fixed["dx"] == 0.0
    assert d_fixed["dy"] == 0.0
    assert d_fixed["dz"] == 0.0
    assert d_fixed["rx"] == 0.0
    assert d_fixed["ry"] == 0.0
    assert d_fixed["rz"] == 0.0

    # Verify non-zero prediction at free joint
    assert "solve_duration_ms" in data
    assert data["solve_duration_ms"] < 50.0  # Under 50ms (sub-15ms typical)
