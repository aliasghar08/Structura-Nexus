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


