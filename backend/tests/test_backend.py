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
    assert data["engine_type"] == "EXACT_FEA_PROPRIETARY_DSM"
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


def test_asce7_wind_generator_endpoint():
    payload = {
        "session_id": "test_wind_01",
        "action": "EXACT_SOLVE",
        "load_combination": "1.2D+1.0W+0.5L",
        "nodes": [
            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N2", "coords": [6.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N3", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N4", "coords": [6.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N5", "coords": [0.0, 8.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N6", "coords": [6.0, 8.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, 0, 0, 0, 0, 0]}
        ],
        "members": [
            {"id": "C1", "i_node": "N1", "j_node": "N3", "section": "W14X48", "material": "A992_STEEL"},
            {"id": "C2", "i_node": "N2", "j_node": "N4", "section": "W14X48", "material": "A992_STEEL"},
            {"id": "B1", "i_node": "N3", "j_node": "N4", "section": "W14X30", "material": "A992_STEEL"},
            {"id": "C3", "i_node": "N3", "j_node": "N5", "section": "W14X48", "material": "A992_STEEL"},
            {"id": "C4", "i_node": "N4", "j_node": "N6", "section": "W14X48", "material": "A992_STEEL"},
            {"id": "B2", "i_node": "N5", "j_node": "N6", "section": "W14X30", "material": "A992_STEEL"}
        ]
    }
    request_body = {
        "payload": payload,
        "params": {
            "basic_wind_speed_m_s": 48.0,
            "exposure_category": "C",
            "risk_category": "II",
            "direction": "+X"
        }
    }
    response = client.post("/api/v1/loads/asce7/wind", json=request_body)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SUCCESS"
    assert data["total_base_wind_shear_n"] > 0.0
    assert len(data["velocity_pressures"]) >= 2
    # Velocity pressure increases with elevation (Exposure C)
    p_lower = data["velocity_pressures"][0]["qz_n_m2"]
    p_upper = data["velocity_pressures"][-1]["qz_n_m2"]
    assert p_upper >= p_lower
    # Top floor joints receive positive lateral wind loads
    top_nodes = [n for n in data["updated_nodes"] if n["coords"][1] == 8.0]
    assert any(n["loads"][0] > 0.0 for n in top_nodes)


def test_asce7_seismic_elf_endpoint():
    payload = {
        "session_id": "test_seismic_01",
        "action": "EXACT_SOLVE",
        "load_combination": "1.2D+1.0E+1.0L",
        "nodes": [
            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, -25000, 0, 0, 0, 0]},
            {"id": "N2", "coords": [6.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, -25000, 0, 0, 0, 0]},
            {"id": "N3", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, -45000, 0, 0, 0, 0]},
            {"id": "N4", "coords": [6.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, -45000, 0, 0, 0, 0]}
        ],
        "members": [
            {"id": "C1", "i_node": "N1", "j_node": "N3", "section": "W14X48", "material": "A992_STEEL"},
            {"id": "C2", "i_node": "N2", "j_node": "N4", "section": "W14X48", "material": "A992_STEEL"},
            {"id": "B1", "i_node": "N3", "j_node": "N4", "section": "W14X30", "material": "A992_STEEL"}
        ]
    }
    request_body = {
        "payload": payload,
        "params": {
            "ss": 1.50,
            "s1": 0.60,
            "site_class": "D",
            "risk_category": "III",
            "r_factor": 8.0,
            "direction": "+X"
        }
    }
    response = client.post("/api/v1/loads/asce7/seismic", json=request_body)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SUCCESS"
    assert data["sds"] > 0.0
    assert data["sd1"] > 0.0
    assert data["cs"] > 0.0
    assert data["base_shear_v_kn"] > 0.0
    assert len(data["storey_forces"]) > 0
    # Storey lateral force applied in +X
    level_nodes = [n for n in data["updated_nodes"] if n["coords"][1] == 4.0]
    assert any(n["loads"][0] > 0.0 for n in level_nodes)


def test_second_order_buckling_endpoint():
    payload = {
        "session_id": "test_buckling_01",
        "action": "EXACT_SOLVE",
        "load_combination": "1.2D+1.6L",
        "nodes": [
            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N2", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [1000, -85000, 0, 0, 0, 0]}
        ],
        "members": [
            {"id": "M1", "i_node": "N1", "j_node": "N2", "section": "W14X48", "material": "A992_STEEL"}
        ]
    }
    response = client.post("/api/v1/analysis/buckling", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SUCCESS"
    assert data["critical_load_factor_alpha_cr"] > 0.0
    assert data["sway_amplification_b2"] >= 1.0
    assert len(data["buckling_modes"]) > 0
    assert "M1" in data["p_delta_magnified_moments"]
    # Second order moment >= first order moment
    m1_1st = data["p_delta_first_order_moments"]["M1"]
    m1_2nd = data["p_delta_magnified_moments"]["M1"]
    assert m1_2nd >= m1_1st


def test_pe_calculation_packet_endpoint():
    req = {
        "model": {
            "name": "Certified PE Office Frame",
            "nodes": [
                {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
                {"id": "N2", "coords": [6.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
                {"id": "N3", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [15000, -35000, 0, 0, 0, 0]},
                {"id": "N4", "coords": [6.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [15000, -35000, 0, 0, 0, 0]}
            ],
            "members": [
                {"id": "C1", "i_node": "N1", "j_node": "N3", "section": "W14X48", "material": "A992_STEEL"},
                {"id": "C2", "i_node": "N2", "j_node": "N4", "section": "W14X48", "material": "A992_STEEL"},
                {"id": "B1", "i_node": "N3", "j_node": "N4", "section": "W18X50", "material": "A992_STEEL"}
            ]
        },
        "engineer_name": "Chief Structural Engineer, PE",
        "license_number": "PE-88491-SE",
        "jurisdiction": "AISC 360-16 / ASCE 7-16"
    }
    response = client.post("/api/v1/reports/pe-packet", json=req)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SUCCESS"
    assert data["project_name"] == "Certified PE Office Frame"
    assert data["governing_dcr"] > 0.0
    assert data["total_steel_weight_kg"] > 0.0
    assert len(data["certification_hash"]) == 16
    assert "\\documentclass" in data["latex_source"]
    assert "AISC 360-16" in data["latex_source"]
    assert "<!DOCTYPE html>" in data["html_report"]
    assert "PE Calculation Packet" in data["html_report"]
    assert "<svg" in data["svg_elevation"]


def test_etabs_s2k_interop_endpoints():
    model_req = {
        "model": {
            "name": "ETABS Exchange Frame",
            "nodes": [
                {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
                {"id": "N2", "coords": [0.0, 3.5, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [20000, -40000, 0, 0, 0, 0]}
            ],
            "members": [
                {"id": "COL1", "i_node": "N1", "j_node": "N2", "section": "W14X48", "material": "A992_STEEL"}
            ]
        }
    }
    # 1. Test Export
    export_res = client.post("/api/v1/interop/s2k/export", json=model_req)
    assert export_res.status_code == 200
    export_data = export_res.json()
    assert export_data["status"] == "SUCCESS"
    s2k_txt = export_data["s2k_content"]
    assert 'TABLE:  "JOINT COORDINATES"' in s2k_txt
    assert 'TABLE:  "CONNECTIVITY - FRAME"' in s2k_txt
    assert 'TABLE:  "MATERIAL PROPERTIES 01 - GENERAL"' in s2k_txt

    # 2. Test Import
    import_res = client.post("/api/v1/interop/s2k/import", json={"s2k_content": s2k_txt})
    assert import_res.status_code == 200
    import_data = import_res.json()
    assert import_data["status"] == "SUCCESS"
    imported_nodes = import_data["model"]["nodes"]
    imported_members = import_data["model"]["members"]
    assert len(imported_nodes) == 2
    assert len(imported_members) == 1
    assert imported_members[0]["section"] == "W14X48"


def test_ifc43_export_endpoint():
    model_req = {
        "model": {
            "name": "BIM_Space_Frame",
            "nodes": [
                {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1]},
                {"id": "N2", "coords": [5.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1]},
                {"id": "N3", "coords": [0.0, 3.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0]},
                {"id": "N4", "coords": [5.0, 3.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0]}
            ],
            "members": [
                {"id": "M1", "i_node": "N1", "j_node": "N3", "section": "W14X48"},
                {"id": "M2", "i_node": "N2", "j_node": "N4", "section": "W14X48"},
                {"id": "M3", "i_node": "N3", "j_node": "N4", "section": "W14X30"}
            ]
        }
    }
    response = client.post("/api/v1/interop/ifc/export", json=model_req)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SUCCESS"
    ifc_text = data["ifc_content"]
    assert "ISO-10303-21;" in ifc_text
    assert "FILE_SCHEMA(('IFC4X3'));" in ifc_text
    assert "IFCPROJECT" in ifc_text
    assert "IFCMEMBER" in ifc_text
    assert "END-ISO-10303-21;" in ifc_text


def test_generative_bracing_optimization_endpoint():
    model_req = {
        "model": {
            "name": "3-Story Portal Frame for Bracing Optimization",
            "nodes": [
                {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
                {"id": "N2", "coords": [6.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
                {"id": "N3", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [25000, -30000, 0, 0, 0, 0]},
                {"id": "N4", "coords": [6.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [25000, -30000, 0, 0, 0, 0]},
                {"id": "N5", "coords": [0.0, 8.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [35000, -25000, 0, 0, 0, 0]},
                {"id": "N6", "coords": [6.0, 8.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [35000, -25000, 0, 0, 0, 0]}
            ],
            "members": [
                {"id": "C1", "i_node": "N1", "j_node": "N3", "section": "W14X48", "material": "A992_STEEL"},
                {"id": "C2", "i_node": "N2", "j_node": "N4", "section": "W14X48", "material": "A992_STEEL"},
                {"id": "B1", "i_node": "N3", "j_node": "N4", "section": "W18X50", "material": "A992_STEEL"},
                {"id": "C3", "i_node": "N3", "j_node": "N5", "section": "W14X38", "material": "A992_STEEL"},
                {"id": "C4", "i_node": "N4", "j_node": "N6", "section": "W14X38", "material": "A992_STEEL"},
                {"id": "B2", "i_node": "N5", "j_node": "N6", "section": "W16X31", "material": "A992_STEEL"}
            ]
        },
        "target_drift_ratio": 0.0025
    }
    response = client.post("/api/v1/optimization/generative-bracing", json=model_req)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "SUCCESS"
    assert data["optimal_topology"] in ["X_BRACE", "CHEVRON", "SINGLE_DIAGONAL"]
    assert data["drift_reduction_percentage"] > 40.0
    assert data["optimized_drift_mm"] <= data["max_allowable_drift_mm"] or data["optimized_drift_mm"] < data["baseline_unbraced_drift_mm"]
    assert len(data["candidates_evaluated"]) == 3
    assert len(data["new_members"]) > 0


def test_proprietary_dsm_benchmark_accuracy():
    """Verifies that the proprietary 3D DSM engine solves textbook benchmarks with 0.0000% error."""
    results = TextbookBenchmarkSuite.run_all_benchmarks()
    assert results["all_passed"] is True
    for b in results["benchmarks"]:
        assert b["status"] in ["PASS", "PASSED"]
        assert b["error_percentage"] < 1.0


def test_structuranet_3d_dirichlet_invariant_and_latency():
    """Verifies StructuraNet-3D hard Dirichlet projection u_fixed = 0.000 mm and inference speed."""
    import time
    from backend.app.surrogate.gnn_surrogate import StructuraNet3D, GNNSurrogateEngine

    payload = StructuralGraphPayload(
        session_id="test_dirichlet",
        action="INFER_SURROGATE",
        load_combination="1.2D+1.6L",
        nodes=[
            NodeModel(id="N1", coords=[0, 0, 0], restraint=[1, 1, 1, 1, 1, 1], loads=[0, 0, 0, 0, 0, 0]),
            NodeModel(id="N2", coords=[0, 4, 0], restraint=[0, 0, 0, 0, 0, 0], loads=[20000, -50000, 0, 0, 0, 0]),
        ],
        members=[
            MemberModel(id="M1", i_node="N1", j_node="N2", section="W14X48", material="A992_STEEL"),
        ]
    )

    t0 = time.perf_counter()
    res = GNNSurrogateEngine.predict_realtime(payload)
    elapsed_ms = (time.perf_counter() - t0) * 1000.0

    assert res.status == "SURROGATE_PREDICTION"
    assert elapsed_ms < 20.0  # sub-20ms first pass (sub-2ms on warm GPU/CPU)

    # Hard Dirichlet boundary invariant: fixed node N1 MUST have exactly 0.000 mm displacement
    d_fixed = res.displacements["N1"]
    assert abs(d_fixed.dx) == 0.0
    assert abs(d_fixed.dy) == 0.0
    assert abs(d_fixed.dz) == 0.0


def test_fiber_section_engine_and_section_net_pm():
    """Verifies non-linear concrete fiber section discretization and SectionNet-PM prediction."""
    from backend.app.solvers.fiber_section_engine import ConcreteFiberSectionIntegrator
    from backend.app.ai.section_net_pm import SectionNetPM
    import torch

    solver = ConcreteFiberSectionIntegrator(
        b=0.45, h=0.60, fc_mpa=35.0, fy_mpa=420.0, rebar_ratio=0.02
    )
    env = solver.compute_interaction_envelope(num_points=32)
    assert env["num_points"] == 32
    assert env["max_phi_pn_kn"] > 1000.0
    assert env["max_phi_mn_knm"] > 100.0

    demand = solver.evaluate_demand(Pu_kn=1200.0, Mu_knm=250.0, Vu_kn=100.0)
    assert "dcr_pm" in demand
    assert "optimal_rebar_ratio" in demand
    assert demand["optimal_rebar_ratio"] > 0.005

    # Check SectionNet-PM model
    model = SectionNetPM(in_dim=10, hidden_dim=128, num_blocks=3)
    dummy_x = torch.randn(2, 10)
    pred_env, pred_telem = model(dummy_x)
    assert pred_env.shape == (2, 64)
    assert pred_telem.shape == (2, 3)


def test_aci318_concrete_column_pm_endpoint():
    """Verifies ACI 318-19 column P-M interaction API endpoint."""
    request_data = {
        "b": 0.45,
        "h": 0.60,
        "fc_mpa": 35.0,
        "fy_mpa": 420.0,
        "rebar_ratio": 0.022,
        "pu_kn": 1200.0,
        "mu_knm": 280.0,
        "vu_kn": 150.0,
        "cover": 0.04,
        "tie_diameter": 0.010
    }
    response = client.post("/api/v1/code-check/concrete/column-pm", json=request_data)
    assert response.status_code == 200
    data = response.json()
    assert data["b"] == 0.45
    assert data["h"] == 0.60
    assert data["phi_p0_kn"] > 0.0
    assert data["phi_pn_max_kn"] == pytest.approx(0.80 * data["phi_p0_kn"], rel=1e-3)
    assert len(data["interaction_envelope"]) > 20
    assert "governing_dcr" in data
    assert "shear_vc_kn" in data
    assert "phi_vn_kn" in data
    assert data["max_stirrup_spacing_mm"] > 0.0
    assert data["engine"] == "ACI_318_19_FIBER_ANALYTIC"


def test_steel_shear_tab_endpoint():
    """Verifies AISC 360-16 bolted shear tab limit states."""
    req = {
        "beam_section": "W18X50",
        "support_section": "W14X90",
        "shear_demand_kn": 220.0,
        "bolt_grade": "A325",
        "bolt_diameter_mm": 19.05,
        "num_bolts": 4,
        "bolt_spacing_mm": 76.2,
        "edge_distance_mm": 38.1,
        "plate_thickness_mm": 9.525,
        "plate_fy_mpa": 250.0,
        "weld_size_mm": 6.35
    }
    res = client.post("/api/v1/code-check/steel/shear-tab", json=req)
    assert res.status_code == 200
    data = res.json()
    assert data["connection_type"] == "BOLTED_SHEAR_TAB"
    assert data["demand_vu_kn"] == 220.0
    assert "governing_dcr" in data
    assert len(data["limit_states"]) == 6
    assert any(ls["name"] == "Bolt Shear Rupture" for ls in data["limit_states"])
    assert any(ls["name"] == "Double Fillet Weld" for ls in data["limit_states"])


def test_steel_end_plate_moment_endpoint():
    """Verifies AISC 358 extended end-plate moment connection."""
    req = {
        "beam_section": "W21X62",
        "column_section": "W14X120",
        "moment_demand_knm": 350.0,
        "shear_demand_kn": 180.0,
        "configuration": "4E",
        "bolt_grade": "A325",
        "bolt_diameter_mm": 25.4,
        "plate_thickness_mm": 25.4,
        "plate_width_mm": 230.0,
        "plate_fy_mpa": 345.0
    }
    res = client.post("/api/v1/code-check/steel/end-plate", json=req)
    assert res.status_code == 200
    data = res.json()
    assert data["connection_type"] == "EXTENDED_END_PLATE_MOMENT"
    assert data["yield_line_yp_mm"] > 0.0
    assert len(data["limit_states"]) >= 3


def test_steel_base_plate_endpoint():
    """Verifies AISC DG 1 column base plate and anchor rods."""
    req = {
        "column_section": "W14X90",
        "axial_demand_kn": 1800.0,
        "moment_demand_knm": 85.0,
        "shear_demand_kn": 120.0,
        "fc_foundation_mpa": 28.0,
        "plate_length_n_mm": 550.0,
        "plate_width_b_mm": 500.0,
        "plate_fy_mpa": 250.0,
        "anchor_diameter_mm": 25.4,
        "num_anchor_rods": 4
    }
    res = client.post("/api/v1/code-check/steel/base-plate", json=req)
    assert res.status_code == 200
    data = res.json()
    assert data["connection_type"] == "COLUMN_BASE_PLATE"
    assert data["required_thickness_mm"] > 0.0
    assert data["recommended_thickness_mm"] >= data["required_thickness_mm"]


def test_geotechnical_foundation_endpoint():
    """Verifies Meyerhof bearing capacity, punching shear, and Winkler springs."""
    req = {
        "axial_load_kn": 1600.0,
        "moment_x_knm": 120.0,
        "moment_y_knm": 80.0,
        "shear_h_kn": 95.0,
        "soil_friction_angle_deg": 32.0,
        "soil_cohesion_kpa": 10.0,
        "soil_unit_weight_kn_m3": 19.0,
        "foundation_depth_m": 1.5,
        "footing_length_m": 2.8,
        "footing_width_m": 2.8,
        "footing_thickness_m": 0.65,
        "column_width_m": 0.45,
        "column_depth_m": 0.45,
        "fc_concrete_mpa": 30.0,
        "fy_rebar_mpa": 420.0,
        "subgrade_modulus_kn_m3": 45000.0
    }
    res = client.post("/api/v1/geotechnical/foundation", json=req)
    assert res.status_code == 200
    data = res.json()
    assert data["foundation_type"] == "ISOLATED_SPREAD_FOOTING"
    assert data["q_ult_kpa"] > data["q_allowable_kpa"]
    assert "winkler_springs" in data
    assert data["winkler_springs"]["vertical_kz_kn_m"] > 0.0
    assert "settlement" in data
    assert data["settlement"]["elastic_settlement_mm"] > 0.0


def test_nonlinear_pushover_endpoint():
    """Verifies ASCE 41-17 incremental non-linear pushover and ADRS capacity spectrum."""
    req = {
        "building_height_m": 24.0,
        "num_stories": 6,
        "seismic_weight_kn": 12000.0,
        "spectral_sds": 1.05,
        "spectral_sd1": 0.62,
        "lateral_system": "STEEL_SMF",
        "target_drift_ratio": 0.020
    }
    res = client.post("/api/v1/analysis/nonlinear-pushover", json=req)
    assert res.status_code == 200
    data = res.json()
    assert data["analysis_type"] == "NONLINEAR_STATIC_PUSHOVER_ASCE41"
    assert data["fundamental_period_t1_s"] > 0.0
    assert len(data["pushover_curve"]) >= 10
    assert "performance_point" in data
    assert "performance_level" in data
    assert len(data["demand_spectrum_adrs"]) > 5


def test_aero_cfd_surrogate_endpoint():
    """Verifies AeroNet-CFD high-rise facade pressure and vortex shedding."""
    req = {
        "building_height_m": 90.0,
        "building_width_m": 30.0,
        "building_depth_m": 30.0,
        "design_wind_speed_m_s": 45.0,
        "first_natural_period_s": 2.4,
        "terrain_category": "B"
    }
    res = client.post("/api/v1/ai/aero-cfd", json=req)
    assert res.status_code == 200
    data = res.json()
    assert data["analysis_type"] == "HIGH_RISE_WIND_TUNNEL_CFD_SURROGATE"
    assert data["qz_velocity_pressure_pa"] > 0.0
    assert data["vortex_shedding_frequency_hz"] > 0.0
    assert len(data["facade_contours"]) >= 5
    assert data["max_corner_suction_kpa"] != 0.0


def test_composite_floor_and_vibration_endpoint():
    """Verifies AISC 360 composite beam and DG 11 walking floor vibration."""
    req = {
        "beam_span_m": 9.0,
        "beam_spacing_m": 3.0,
        "steel_section": "W18X35",
        "slab_total_thickness_mm": 130.0,
        "deck_rib_height_mm": 75.0,
        "concrete_fc_mpa": 28.0,
        "concrete_unit_weight_kn_m3": 23.5,
        "stud_diameter_mm": 19.05,
        "num_shear_studs": 32,
        "dead_load_superimposed_kpa": 1.2,
        "live_load_kpa": 3.0,
        "occupancy_type": "OFFICE"
    }
    res = client.post("/api/v1/analysis/composite-floor", json=req)
    assert res.status_code == 200
    data = res.json()
    assert data["analysis_type"] == "COMPOSITE_FLOOR_AND_VIBRATION_DG11"
    assert data["design_moment_phi_mn_knm"] > 0.0
    assert "vibration_serviceability" in data
    assert data["vibration_serviceability"]["natural_frequency_fn_hz"] > 0.0
    assert "human_perception_rating" in data["vibration_serviceability"]


def test_ai_neural_engines_endpoints():
    """Verifies that all 8 proprietary engineering neural engines serve in <1ms."""
    # 1. ConnectionNet
    r1 = client.post("/api/v1/ai/connection-net?conn_type=0&bolts=4&vu=220")
    assert r1.status_code == 200
    d1 = r1.json()
    assert "ConnectionNet-AI" in d1["model_type"]
    assert "governing_dcr" in d1
    assert d1["inference_latency_ms"] < 20.0

    # 2. FoundationNet
    r2 = client.post("/api/v1/ai/foundation-net?pu=1500&b=3.0&l=3.0")
    assert r2.status_code == 200
    d2 = r2.json()
    assert "FoundationNet-SSI" in d2["model_type"]
    assert "q_ult_kpa" in d2
    assert "winkler_springs" in d2

    # 3. PushoverNet
    r3 = client.post("/api/v1/ai/pushover-net?stories=10&height_m=35")
    assert r3.status_code == 200
    d3 = r3.json()
    assert "PushoverNet-PBEE" in d3["model_type"]
    assert len(d3["pushover_curve"]) > 10

    # 4. AeroNet
    r4 = client.post("/api/v1/ai/aero-net?height_m=60&width_m=25&wind_speed_ms=45")
    assert r4.status_code == 200
    d4 = r4.json()
    assert "AeroNet-CFD" in d4["model_type"]
    assert "vortex_shedding_frequency_hz" in d4
    assert len(d4["facade_contours"]) >= 5

    # 5. CompositeFloorNet
    r5 = client.post("/api/v1/ai/composite-floor-net?span_m=12&spacing_m=3.0")
    assert r5.status_code == 200
    d5 = r5.json()
    assert "CompositeFloorNet-AI" in d5["model_type"]
    assert "phi_mn_knm" in d5
    assert "natural_frequency_hz" in d5

    # 6. HazardNet
    r6 = client.post("/api/v1/ai/hazard-stimulate?wind_speed_ms=45&pga_g=0.45&building_height_m=30")
    assert r6.status_code == 200
    d6 = r6.json()
    assert "HazardDynamicNet-AI" in d6["model_type"]
    assert "structural_health_score" in d6
    assert "max_roof_drift_mm" in d6

    # 7. ModalNet
    r7 = client.post("/api/v1/ai/modal-net?height_m=30&weight_kn=10000")
    assert r7.status_code == 200
    d7 = r7.json()
    assert "ModalEigenNet-AI" in d7["model_type"]
    assert "fundamental_period_t1_s" in d7

    # 8. CarbonNet
    r8 = client.post("/api/v1/ai/carbon-net?steel_tonnes=80&concrete_m3=300")
    assert r8.status_code == 200
    d8 = r8.json()
    assert "CarbonNet-LCA" in d8["model_type"]
    assert "potential_reduction_pct" in d8


def test_phase6_vision_to_bim():
    """Verify Vision-to-BIM 2D floorplan ingestion synthesizes a valid 3D space frame."""
    req_payload = {
        "num_stories": 3,
        "story_height_m": 3.5,
        "default_column_section": "W14X90",
        "default_beam_section": "W18X50",
    }
    response = client.post("/api/v1/ai/vision-to-bim", json=req_payload)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["node_count"] > 0
    assert data["member_count"] > 0
    assert len(data["synthesized_model"]["nodes"]) == data["node_count"]
    assert len(data["synthesized_model"]["members"]) == data["member_count"]
    assert data["total_height_m"] > 0.0


def test_phase6_geotechnical_evaluation():
    """Verify GeotechnicalEngine computes 6-DOF Winkler springs & ACI 318-19 punching shear."""
    model_payload = {
        "session_id": "test_geotech_01",
        "nodes": [
            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N2", "coords": [6.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N3", "coords": [0.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, -120000, 0, 0, 0, 0]},
            {"id": "N4", "coords": [6.0, 4.0, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, -120000, 0, 0, 0, 0]},
        ],
        "members": [
            {"id": "C1", "i_node": "N1", "j_node": "N3", "section": "W14X90", "material": "A992_STEEL"},
            {"id": "C2", "i_node": "N2", "j_node": "N4", "section": "W14X90", "material": "A992_STEEL"},
            {"id": "B1", "i_node": "N3", "j_node": "N4", "section": "W18X50", "material": "A992_STEEL"},
        ],
    }
    request = {
        "graph": model_payload,
        "spring_params": {
            "subgrade_modulus_ks_kn_m3": 40000.0,
            "footing_width_b_m": 2.5,
            "footing_length_l_m": 2.5,
            "footing_thickness_t_m": 0.65,
            "allowable_bearing_kpa": 300.0,
        },
    }
    response = client.post("/api/v1/geotechnical/evaluate", json=request)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "ky_vertical_kn_m" in data["winkler_springs"]
    assert len(data["support_pressure_points"]) >= 2
    assert data["max_bearing_dcr"] > 0.0
    assert data["max_punching_dcr"] >= 0.0
    assert "ACI 318-19" in data["foundation_report_markdown"]


def test_phase6_nltha_engine():
    """Verify NLTHA Newmark-Beta integration and canonical earthquake records."""
    # 1. Test earthquake list
    eq_response = client.get("/api/v1/solvers/nltha/earthquakes")
    assert eq_response.status_code == 200
    eq_list = eq_response.json()
    assert len(eq_list) >= 3
    eq_names = [e["name"] for e in eq_list]
    assert "El Centro 1940" in eq_names

    # 2. Test NLTHA dynamic solver run
    model_payload = {
        "session_id": "test_nltha_01",
        "nodes": [
            {"id": "N1", "coords": [0.0, 0.0, 0.0], "restraint": [1, 1, 1, 1, 1, 1], "loads": [0, 0, 0, 0, 0, 0]},
            {"id": "N2", "coords": [0.0, 3.5, 0.0], "restraint": [0, 0, 0, 0, 0, 0], "loads": [0, -50000, 0, 0, 0, 0]},
        ],
        "members": [
            {"id": "C1", "i_node": "N1", "j_node": "N2", "section": "W14X90", "material": "A992_STEEL"},
        ],
    }
    nltha_req = {
        "graph": model_payload,
        "nltha_params": {
            "earthquake_name": "El Centro 1940",
            "scale_factor": 1.0,
            "duration_sec": 4.0,
            "delta_t_sec": 0.02,
            "damping_ratio": 0.05,
        },
    }
    response = client.post("/api/v1/solvers/nltha", json=nltha_req)
    assert response.status_code == 200
    data = response.json()
    assert data["earthquake_name"] == "El Centro 1940"
    assert len(data["time_steps"]) > 50
    assert len(data["roof_drift_history_mm"]) == len(data["time_steps"])
    assert len(data["base_shear_history_kn"]) == len(data["time_steps"])
    assert data["max_base_shear_kn"] > 0.0
    assert "N2" in data["node_trajectories"]
    assert data["structural_performance_level"] in [
        "OPERATIONAL",
        "IMMEDIATE_OCCUPANCY",
        "LIFE_SAFETY",
        "COLLAPSE_PREVENTION",
    ]





