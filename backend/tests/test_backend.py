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
    response = client.post("/api/v1/surrogate", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SUCCESS"
    # Latency should be fast (sub-40ms)
    assert data["inference_latency_ms"] < 40.0
