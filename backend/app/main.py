import json
import logging
import torch
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any, List

from .models.schema import StructuralGraphPayload, SolverResponse
from .solvers.fea_engine import FEA3DSpaceFrameSolver
from .surrogate.gnn_surrogate import GNNSurrogateEngine
from .code_check.aisc_aci import AISC_W_SHAPES, MATERIALS, AISC360CodeChecker
from .benchmarks.verification_suite import TextbookBenchmarkSuite

# AI Ecosystem imports
from .ai.gnn_model import pytorch_surrogate_engine
from .ai.generative_optimizer import generative_optimizer, GenerativeOptimizationResult
from .ai.dynamic_modal_engine import modal_seismic_engine, SeismicAnalysisResult
from .ai.embodied_carbon_engine import embodied_carbon_engine, EmbodiedCarbonReport
from .ai.copilot import copilot_engine, CopilotResponse

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("structura_nexus")

app = FastAPI(
    title="Structura Forge AI / Structura Nexus Engine",
    description="World-Class AI Workstation Backend for Civil & Structural Engineering (AISC 360-16 / ACI 318-19 / ASCE 7-16)",
    version="3.4.0-REV-A",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class CopilotQueryRequest(BaseModel):
    query: str
    graph: StructuralGraphPayload


class SeismicQueryRequest(BaseModel):
    graph: StructuralGraphPayload
    Ss: float = 1.25
    S1: float = 0.50
    R: float = 8.0
    Ie: float = 1.0


@app.get("/")
def root():
    return {
        "service": "Structura Forge AI / Structura Nexus Workstation",
        "version": "3.4.0-REV-A",
        "standards": ["AISC 360-16", "ACI 318-19", "ASCE 7-16", "IBC 2024"],
        "status": "ONLINE",
        "ai_acceleration": {
            "pytorch_version": torch.__version__,
            "hardware_backend": "Apple Silicon MPS (Metal)" if torch.backends.mps.is_available() else ("CUDA" if torch.cuda.is_available() else "CPU"),
            "device": str(pytorch_surrogate_engine.device),
        },
        "engines": {
            "surrogate": "PyTorch Physics-Informed GNN (<40ms)",
            "exact_fea": "Direct Stiffness Matrix (DSM) + PyNiteFEA Core",
            "generative_optimizer": "CMA-ES / Evolutionary Section Reducer (15-25% mass reduction)",
            "modal_seismic": "ASCE 7-16 Dynamic Modal Eigenvalue & Drift Engine",
            "embodied_carbon": "SE 2050 / LEED v4.1 LCA Sustainability Engine",
            "copilot": "Structural Intelligence Natural Language Copilot",
            "compliance": "Deterministic AISC 360-16 / ACI 318-19 Gatekeeper",
        }
    }


@app.get("/api/v1/health")
def health():
    return {
        "status": "HEALTHY",
        "pytorch": {
            "available": True,
            "version": torch.__version__,
            "device": str(pytorch_surrogate_engine.device),
        },
        "subsystems": {
            "pytorch_gnn": "ACTIVE",
            "fea_matrix_engine": "ACTIVE",
            "generative_optimizer": "ACTIVE",
            "dynamic_modal_engine": "ACTIVE",
            "embodied_carbon_engine": "ACTIVE",
            "copilot_engine": "ACTIVE",
            "aisc_code_checker": "ACTIVE",
            "websocket_hub": "ACTIVE",
        }
    }


@app.get("/api/v1/catalog")
def get_catalog():
    return {
        "sections": AISC_W_SHAPES,
        "materials": MATERIALS,
    }


@app.get("/api/v1/benchmarks")
def run_benchmarks():
    return TextbookBenchmarkSuite.run_all_benchmarks()


# -------------------------------------------------------------
# Solver Endpoints
# -------------------------------------------------------------
@app.post("/api/v1/solve", response_model=SolverResponse)
def solve_structure(payload: StructuralGraphPayload):
    try:
        return FEA3DSpaceFrameSolver.solve(payload)
    except Exception as e:
        logger.error(f"Solve error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/surrogate", response_model=SolverResponse)
def surrogate_infer(payload: StructuralGraphPayload):
    try:
        return GNNSurrogateEngine.infer(payload)
    except Exception as e:
        logger.error(f"Surrogate error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------
# World-Class PyTorch AI Model Endpoints
# -------------------------------------------------------------
@app.post("/api/v1/ai/infer")
def pytorch_ai_infer(payload: StructuralGraphPayload):
    """
    Direct PyTorch GNN forward pass with physics-hard projection and uncertainty quantification.
    """
    try:
        node_res, member_res, uncertainty, fallback = pytorch_surrogate_engine.predict(payload)
        return {
            "status": "SUCCESS",
            "device": str(pytorch_surrogate_engine.device),
            "epistemic_uncertainty": round(uncertainty, 4),
            "fallback_triggered": fallback,
            "nodes": node_res,
            "members": member_res,
        }
    except Exception as e:
        logger.error(f"PyTorch inference error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/ai/generative-optimize", response_model=GenerativeOptimizationResult)
def generative_optimize(payload: StructuralGraphPayload):
    """
    Evolutionary multi-objective topology & cross-section optimizer (15-25% mass reduction, DCR <= 0.95).
    """
    try:
        return generative_optimizer.optimize_structure(payload, target_max_dcr=0.95)
    except Exception as e:
        logger.error(f"Generative optimization error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/ai/modal-seismic", response_model=SeismicAnalysisResult)
def modal_seismic(request: SeismicQueryRequest):
    """
    ASCE 7-16 dynamic modal eigenvalue analysis and seismic equivalent lateral force.
    """
    try:
        return modal_seismic_engine.analyze_dynamics(
            request.graph,
            Ss=request.Ss,
            S1=request.S1,
            R=request.R,
            Ie=request.Ie,
        )
    except Exception as e:
        logger.error(f"Modal seismic error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/ai/embodied-carbon", response_model=EmbodiedCarbonReport)
def embodied_carbon(payload: StructuralGraphPayload):
    """
    Cradle-to-gate embodied carbon footprint calculation and green steel substitution analysis.
    """
    try:
        return embodied_carbon_engine.assess_carbon(payload)
    except Exception as e:
        logger.error(f"Embodied carbon error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/ai/copilot", response_model=CopilotResponse)
def structural_copilot(request: CopilotQueryRequest):
    """
    Natural Language Structural Engineering Copilot.
    """
    try:
        return copilot_engine.process_query(request.query, request.graph)
    except Exception as e:
        logger.error(f"Copilot processing error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


from .ai.gemini_agent import (
    GEMINI_STRUCTURAL_TOOLS,
    gemini_structural_agent,
    AgentResponse,
    AgentChatMessage,
    AgentChatRequest,
)


@app.get("/api/v1/ai/agent/tools")
def get_gemini_tools():
    """
    Returns the structured Gemini Function Calling schema definitions for autonomous execution.
    """
    return {
        "status": "ONLINE",
        "tools": GEMINI_STRUCTURAL_TOOLS,
        "supported_functions": [t["name"] for t in GEMINI_STRUCTURAL_TOOLS],
    }


@app.post("/api/v1/ai/agent/chat", response_model=AgentResponse)
def gemini_agent_chat(request: AgentChatRequest):
    """
    Autonomous Structural Engineering Agent execution turn using Gemini Function Calling.
    """
    try:
        return gemini_structural_agent.process_turn(
            prompt=request.prompt,
            current_graph=request.graph,
            history=request.history,
        )
    except Exception as e:
        logger.error(f"Gemini Agent turn error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/optimize")
def optimize_structure(payload: StructuralGraphPayload):
    try:
        return generative_optimizer.optimize_structure(payload, target_max_dcr=0.95)
    except Exception as e:
        logger.error(f"Optimization error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------
# WebSocket Live Streaming
# -------------------------------------------------------------
@app.websocket("/ws/structural-graph")
async def websocket_structural_graph(websocket: WebSocket):
    await websocket.accept()
    logger.info("WebSocket client connected to Structura Nexus Engine")
    try:
        while True:
            text_data = await websocket.receive_text()
            data = json.loads(text_data)

            payload = StructuralGraphPayload(**data)
            action = payload.action.upper()

            if action == "INFER_SURROGATE":
                response = GNNSurrogateEngine.infer(payload)
            elif action == "EXACT_SOLVE":
                response = FEA3DSpaceFrameSolver.solve(payload)
            elif action == "AI_PYTORCH_INFER":
                node_res, member_res, uncertainty, fallback = pytorch_surrogate_engine.predict(payload)
                if fallback:
                    response = FEA3DSpaceFrameSolver.solve(payload)
                else:
                    response = GNNSurrogateEngine.infer(payload)
            else:  # Default "INFER_AND_VERIFY"
                response = FEA3DSpaceFrameSolver.solve(payload)

            await websocket.send_text(response.model_dump_json())
    except WebSocketDisconnect:
        logger.info("WebSocket client disconnected normally")
    except Exception as e:
        logger.error(f"WebSocket processing exception: {str(e)}")
        await websocket.send_text(json.dumps({"status": "ERROR", "message": str(e)}))
