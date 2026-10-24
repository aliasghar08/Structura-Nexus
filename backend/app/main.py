import json
import logging
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from .models.schema import StructuralGraphPayload, SolverResponse
from .solvers.fea_engine import FEA3DSpaceFrameSolver
from .surrogate.gnn_surrogate import GNNSurrogateEngine
from .code_check.aisc_aci import AISC_W_SHAPES, MATERIALS, AISC360CodeChecker
from .benchmarks.verification_suite import TextbookBenchmarkSuite

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("structura_nexus")

app = FastAPI(
    title="Structura Forge AI / Structura Nexus Engine",
    description="Next-Generation AI Workstation Backend for Civil & Structural Engineering (AISC 360-16 / ACI 318-19 / ASCE 7-16)",
    version="3.4.0-REV-A",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {
        "service": "Structura Forge AI / Structura Nexus Workstation",
        "version": "3.4.0-REV-A",
        "standards": ["AISC 360-16", "ACI 318-19", "ASCE 7-16", "IBC 2024"],
        "status": "ONLINE",
        "engines": {
            "surrogate": "Physics-Hard GNN Edge-Surrogate (<40ms)",
            "exact_fea": "Direct Stiffness Matrix (DSM) + PyNiteFEA Core",
            "compliance": "Deterministic AISC 360-16 / ACI 318-19 Gatekeeper",
        }
    }

@app.get("/api/v1/health")
def health():
    return {
        "status": "HEALTHY",
        "subsystems": {
            "gnn_surrogate": "ACTIVE",
            "fea_matrix_engine": "ACTIVE",
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

@app.post("/api/v1/optimize")
def optimize_structure(payload: StructuralGraphPayload):
    try:
        # First solve with current members
        exact_res = FEA3DSpaceFrameSolver.solve(payload)

        # For any member with failing or sub-optimal DCR, update section
        updated_members = []
        modifications = []
        for mem in payload.members:
            # find corresponding result
            res_mem = next((r for r in exact_res.members if r.id == mem.id), None)
            new_sec = mem.section
            if res_mem and res_mem.recommended_section and res_mem.recommended_section != mem.section:
                new_sec = res_mem.recommended_section
                modifications.append({
                    "member_id": mem.id,
                    "previous_section": mem.section,
                    "optimized_section": new_sec,
                    "previous_dcr": res_mem.governing_dcr,
                })
            updated_members.append(mem.copy(update={"section": new_sec}))

        optimized_payload = payload.copy(update={"members": updated_members})
        new_res = FEA3DSpaceFrameSolver.solve(optimized_payload)

        return {
            "status": "OPTIMIZATION_COMPLETE",
            "modifications_count": len(modifications),
            "modifications": modifications,
            "optimized_solution": new_res,
        }
    except Exception as e:
        logger.error(f"Optimization error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

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
            else:  # Default "INFER_AND_VERIFY"
                # If small frame or release event, run exact solve, otherwise surrogate
                response = FEA3DSpaceFrameSolver.solve(payload)

            await websocket.send_text(response.model_dump_json())
    except WebSocketDisconnect:
        logger.info("WebSocket client disconnected normally")
    except Exception as e:
        logger.error(f"WebSocket processing exception: {str(e)}")
        await websocket.send_text(json.dumps({"status": "ERROR", "message": str(e)}))
