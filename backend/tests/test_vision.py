"""
Unit & Integration Tests for Phase 6 Track 1: Vision-to-BIM Pipeline
Mocks Gemini Multimodal API response, tests 2D-to-3D geometric synthesis,
multipart file upload endpoints, and validates that the synthesized frame solves cleanly in FEA.
Copyright (c) 2026 Ali Asghar <aliasgharinnocent@yahoo.com>. All Rights Reserved.
"""

import os
import io
import json
import base64
from unittest.mock import patch, MagicMock
import pytest
from fastapi.testclient import TestClient

from backend.app.main import app
from backend.app.ai.vision_to_bim import VisionToBimProcessor, VisionToBimRequest
from backend.app.solvers.fea_engine import FEA3DSpaceFrameSolver

client = TestClient(app)


def test_vision_to_bim_default_fallback():
    """Verify default geometric synthesis produces a valid 3D space frame."""
    req = VisionToBimRequest(
        num_stories=3,
        story_height_m=3.6,
        default_column_section="W14X90",
        default_beam_section="W18X50",
    )
    res = VisionToBimProcessor.process_floorplan(req)
    assert res.success is True
    assert res.node_count > 0
    assert res.member_count > 0
    assert res.total_height_m == pytest.approx(10.8, rel=1e-2)

    # Base nodes must have fixed restraints [1, 1, 1, 1, 1, 1]
    base_nodes = [n for n in res.synthesized_model.nodes if n.coords[1] == 0.0]
    assert len(base_nodes) > 0
    for bn in base_nodes:
        assert bn.restraint == [1, 1, 1, 1, 1, 1]

    # Upper nodes must have free restraints [0, 0, 0, 0, 0, 0]
    upper_nodes = [n for n in res.synthesized_model.nodes if n.coords[1] > 0.0]
    assert len(upper_nodes) > 0
    for un in upper_nodes:
        assert un.restraint == [0, 0, 0, 0, 0, 0]


def test_vision_to_bim_gemini_mocked():
    """Mocks Gemini 1.5 Multimodal API and verifies extracted coordinates are mapped to 3D space frame."""
    mock_gemini_payload = {
        "gridlines_x_m": [0.0, 7.5, 15.0],
        "gridlines_y_m": [0.0, 8.0],
        "columns_xy_m": [
            [0.0, 0.0], [7.5, 0.0], [15.0, 0.0],
            [0.0, 8.0], [7.5, 8.0], [15.0, 8.0],
        ],
        "shear_wall_segments": [[[7.5, 0.0], [7.5, 8.0]]],
        "perimeter_boundary_m": [[0.0, 0.0], [15.0, 0.0], [15.0, 8.0], [0.0, 8.0]],
        "detected_scale_px_per_m": 32.0,
        "confidence_score": 0.99,
    }

    mock_resp = MagicMock()
    mock_resp.read.return_value = json.dumps({
        "candidates": [{
            "content": {
                "parts": [{"text": json.dumps(mock_gemini_payload)}]
            }
        }]
    }).encode("utf-8")
    mock_resp.__enter__.return_value = mock_resp

    with patch.dict(os.environ, {"GEMINI_API_KEY": "AIzaSyFakeTestKeyForVisionToBim"}):
        with patch("urllib.request.urlopen", return_value=mock_resp):
            fake_img_b64 = base64.b64encode(b"fake_floorplan_png_bytes").decode("utf-8")
            req = VisionToBimRequest(
                image_base64=fake_img_b64,
                filename="architectural_level1.png",
                num_stories=2,
                story_height_m=3.5,
                default_column_section="W14X120",
                default_beam_section="W21X62",
            )
            res = VisionToBimProcessor.process_floorplan(req)

            assert res.success is True
            # 6 columns x 3 levels (story 0, 1, 2) = 18 nodes
            assert res.node_count == 18
            assert res.extracted_features.confidence_score == 0.99
            assert res.extracted_features.gridlines_x_m == [0.0, 7.5, 15.0]

            # Verify columns have correct sections
            cols = [m for m in res.synthesized_model.members if m.id.startswith("COL_")]
            assert len(cols) == 12  # 6 cols x 2 stories
            for c in cols:
                assert c.section == "W14X120"


def test_vision_to_bim_api_json_endpoint():
    """Verify POST /api/v1/ai/vision-to-bim with JSON payload."""
    payload = {
        "num_stories": 4,
        "story_height_m": 3.6,
        "default_column_section": "W14X90",
        "default_beam_section": "W18X50",
    }
    response = client.post("/api/v1/ai/vision-to-bim", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["node_count"] > 0
    assert data["member_count"] > 0


def test_vision_to_bim_multipart_upload_endpoints():
    """Verify both /api/v1/ai/vision-to-bim and /api/v1/ai/vision-to-bim/upload handle UploadFile."""
    fake_png = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"

    # 1. Test POST /api/v1/ai/vision-to-bim with multipart form
    files = {"file": ("office_plan.png", io.BytesIO(fake_png), "image/png")}
    data = {"num_stories": "2", "story_height_m": "3.6"}
    res1 = client.post("/api/v1/ai/vision-to-bim", files=files, data=data)
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["success"] is True
    assert data1["node_count"] > 0

    # 2. Test explicit POST /api/v1/ai/vision-to-bim/upload route
    files2 = {"file": ("office_plan.pdf", io.BytesIO(fake_png), "application/pdf")}
    res2 = client.post("/api/v1/ai/vision-to-bim/upload", files=files2, data={"num_stories": "3"})
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["success"] is True
    assert data2["total_height_m"] == pytest.approx(10.8, rel=1e-2)


def test_synthesized_model_solves_in_fea():
    """Ensure the synthesized 3D space frame can be solved via FEA3DSpaceFrameSolver without matrix errors."""
    req = VisionToBimRequest(
        num_stories=2,
        story_height_m=3.5,
        default_column_section="W14X90",
        default_beam_section="W18X50",
    )
    res = VisionToBimProcessor.process_floorplan(req)
    assert res.success is True

    # Run full FEA solution on the synthesized model
    fea_result = FEA3DSpaceFrameSolver.solve(res.synthesized_model)
    assert fea_result is not None
    assert fea_result.status == "SUCCESS"
    assert len(fea_result.members) == len(res.synthesized_model.members)
    assert fea_result.global_base_shear_n >= 0.0
    assert fea_result.equilibrium.is_equilibrated is True
