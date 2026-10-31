import json
import base64
import logging
import torch
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, UploadFile, File, Form, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any, List, Optional

from .models.schema import (
    StructuralGraphPayload,
    SolverResponse,
    RealtimeSurrogatePredictionResponse,
    ASCE7WindParameters,
    ASCE7WindResponse,
    ASCE7SeismicParameters,
    ASCE7SeismicResponse,
    SecondOrderAnalysisResponse,
    PEPacketRequest,
    PEPacketResponse,
    S2KExportRequest,
    S2KExportResponse,
    S2KImportRequest,
    S2KImportResponse,
    IFCExportRequest,
    IFCExportResponse,
    GenerativeBracingRequest,
    GenerativeBracingResponse,
)
from .models.concrete_schema import ConcreteColumnPMRequest, ConcreteColumnPMResponse
from .solvers.fea_engine import FEA3DSpaceFrameSolver
from .solvers.asce7_loads import ASCE7WindEngine, ASCE7SeismicEngine
from .solvers.second_order_engine import SecondOrderStabilityEngine
from .reports.pe_packet_generator import PECalculationPacketGenerator
from .interop.s2k_ifc_engine import S2KEngine, IFC43Engine
from .ai.generative_bracing_optimizer import GenerativeBracingOptimizer
from .surrogate.gnn_surrogate import GNNSurrogateEngine
from .code_check.aisc_aci import AISC_W_SHAPES, MATERIALS, AISC360CodeChecker
from .code_check.aci_concrete import ACI318ConcreteChecker
from .code_check.steel_connection_engine import (
    SteelConnectionEngine,
    ShearTabRequest,
    EndPlateMomentRequest,
    BasePlateRequest,
)
from .solvers.geotechnical_ssi_engine import GeotechnicalSSIEngine, FootingDesignRequest
from .solvers.nonlinear_pushover_engine import NonlinearPushoverEngine, PushoverAnalysisRequest
from .ai.aero_cfd_engine import AeroCfdEngine, AeroCfdRequest
from .solvers.composite_floor_engine import CompositeFloorEngine, CompositeFloorRequest
from .benchmarks.verification_suite import TextbookBenchmarkSuite
from .ai.neural_engine_registry import neural_registry

# AI Ecosystem imports
from .ai.gnn_model import pytorch_surrogate_engine
from .ai.generative_optimizer import generative_optimizer, GenerativeOptimizationResult
from .ai.dynamic_modal_engine import modal_seismic_engine, SeismicAnalysisResult
from .ai.embodied_carbon_engine import embodied_carbon_engine, EmbodiedCarbonReport
from .ai.copilot import copilot_engine, CopilotResponse
from .ai.vision_to_bim import VisionToBimProcessor, VisionToBimRequest, VisionToBimResponse
from .solvers.geotechnical_engine import GeotechnicalEngine, SoilSpringsRequest, GeotechnicalAnalysisResponse
from .solvers.nltha_engine import NlthaEngine, NlthaRequest, NlthaResponse

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


class ASCE7WindRequest(BaseModel):
    payload: StructuralGraphPayload
    params: Optional[ASCE7WindParameters] = None


class ASCE7SeismicRequest(BaseModel):
    payload: StructuralGraphPayload
    params: Optional[ASCE7SeismicParameters] = None


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
            "exact_fea": "Proprietary 3D Direct Stiffness Matrix (DSM) Core",
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


@app.post("/api/v1/surrogate/predict", response_model=RealtimeSurrogatePredictionResponse)
def predict_realtime_response(payload: StructuralGraphPayload):
    """
    Sub-15ms PyTorch Geometric GNN forward pass with physics-hard boundary condition masking.
    Bypasses stiffness matrix inversion during live interactive UI joint dragging.
    """
    try:
        return GNNSurrogateEngine.predict_realtime(payload)
    except Exception as e:
        logger.error(f"Surrogate predict error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------
# ASCE 7-16 Automated Lateral Loads & Second-Order Stability
# -------------------------------------------------------------
@app.post("/api/v1/loads/asce7/wind", response_model=ASCE7WindResponse)
def generate_asce7_wind(request: ASCE7WindRequest):
    """
    ASCE 7-16 MWFRS Directional Wind Pressure calculation and nodal load distribution.
    """
    try:
        params = request.params or ASCE7WindParameters()
        return ASCE7WindEngine.generate_wind_loads(request.payload, params)
    except Exception as e:
        logger.error(f"ASCE 7 Wind error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/loads/asce7/seismic", response_model=ASCE7SeismicResponse)
def generate_asce7_seismic(request: ASCE7SeismicRequest):
    """
    ASCE 7-16 Equivalent Lateral Force (ELF) base shear and vertical storey distribution.
    """
    try:
        params = request.params or ASCE7SeismicParameters()
        return ASCE7SeismicEngine.generate_seismic_loads(request.payload, params)
    except Exception as e:
        logger.error(f"ASCE 7 Seismic error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/analysis/buckling", response_model=SecondOrderAnalysisResponse)
def analyze_second_order_buckling(payload: StructuralGraphPayload):
    """
    Second-Order Geometric Stiffness [Kg] assembly, Generalized Eigenvalue Buckling (alpha_cr),
    AISC 360-16 B2 sway amplification factor, and iterative P-Delta analysis.
    """
    try:
        return SecondOrderStabilityEngine.analyze_stability(payload)
    except Exception as e:
        logger.error(f"Buckling analysis error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------
# Professional PE Calculation Packet Generator
# -------------------------------------------------------------
pe_generator = PECalculationPacketGenerator()

@app.post("/api/v1/reports/pe-packet", response_model=PEPacketResponse)
def generate_pe_calculation_packet(request: PEPacketRequest):
    """
    Generates certified, multi-page professional engineering calculation packet
    in LaTeX (.tex) and printable HTML formats, with AISC 360-16 checks and SVG elevation.
    """
    try:
        model_dict = request.model.model_dump()
        gen = PECalculationPacketGenerator(
            project_name=model_dict.get("name", "Structura Nexus Space Frame"),
            engineer_name=request.engineer_name or "Staff Structural Engineer, PE, SE",
            license_number=request.license_number or "PE-94021-SE",
            jurisdiction=request.jurisdiction or "AISC 360-16 / ASCE 7-16 / IBC 2024",
        )
        packet = gen.generate_packet(model_data=model_dict)
        return PEPacketResponse(
            status="SUCCESS",
            project_name=packet["project_name"],
            governing_dcr=packet["governing_dcr"],
            total_steel_weight_kg=packet["total_steel_weight_kg"],
            total_embodied_carbon_tco2e=packet["total_embodied_carbon_tco2e"],
            critical_member_id=packet["critical_member_id"],
            critical_section=packet["critical_section"],
            critical_load_factor_alpha_cr=packet["critical_load_factor_alpha_cr"],
            sway_amplification_b2=packet["sway_amplification_b2"],
            stability_status=packet["stability_status"],
            certification_hash=packet["certification_hash"],
            member_count=packet["member_count"],
            node_count=packet["node_count"],
            latex_source=packet["latex_source"],
            html_report=packet["html_report"],
            svg_elevation=packet["svg_elevation"],
        )
    except Exception as e:
        logger.error(f"PE Packet Generation error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------
# BIM & CAD Interoperability Endpoints (ETABS / SAP2000 .s2k & IFC 4.3)
# -------------------------------------------------------------
@app.post("/api/v1/interop/s2k/export", response_model=S2KExportResponse)
def export_etabs_s2k(request: S2KExportRequest):
    """
    Exports structural model to ETABS / SAP2000 .s2k text file format.
    """
    try:
        model_dict = request.model.model_dump()
        s2k_text = S2KEngine.export_to_s2k(model_dict)
        filename = f"{model_dict.get('name', 'model').replace(' ', '_')}.s2k"
        return S2KExportResponse(status="SUCCESS", filename=filename, s2k_content=s2k_text)
    except Exception as e:
        logger.error(f"S2K export error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/interop/s2k/import", response_model=S2KImportResponse)
def import_etabs_s2k(request: S2KImportRequest):
    """
    Imports and parses an ETABS / SAP2000 .s2k file into a Structura Nexus model.
    """
    try:
        parsed_model = S2KEngine.import_from_s2k(request.s2k_content)
        return S2KImportResponse(status="SUCCESS", model=parsed_model)
    except Exception as e:
        logger.error(f"S2K import error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/interop/ifc/export", response_model=IFCExportResponse)
def export_ifc_43(request: IFCExportRequest):
    """
    Exports structural model to certified IFC 4.3 STEP physical file format (ISO 10303-21).
    """
    try:
        model_dict = request.model.model_dump()
        ifc_text = IFC43Engine.export_to_ifc(model_dict)
        filename = f"{model_dict.get('name', 'model').replace(' ', '_')}.ifc"
        return IFCExportResponse(status="SUCCESS", filename=filename, ifc_content=ifc_text)
    except Exception as e:
        logger.error(f"IFC export error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------------------------------------------
# Generative Topology & Bracing Optimization
# -------------------------------------------------------------
bracing_optimizer = GenerativeBracingOptimizer()

@app.post("/api/v1/optimization/generative-bracing", response_model=GenerativeBracingResponse)
def generative_bracing_optimization(request: GenerativeBracingRequest):
    """
    Synthesizes and evaluates alternative lateral bracing topologies (X-Brace, Chevron, Diagonal)
    to minimize steel weight while strictly satisfying lateral drift limits (Delta <= H/400).
    """
    try:
        model_dict = request.model.model_dump()
        result = bracing_optimizer.optimize_bracing(
            model_data=model_dict,
            target_drift_ratio=request.target_drift_ratio,
            candidate_sections=request.candidate_sections,
        )
        return GenerativeBracingResponse(
            status="SUCCESS",
            project_name=result["project_name"],
            building_height_m=result["building_height_m"],
            drift_limit_ratio=result["drift_limit_ratio"],
            max_allowable_drift_mm=result["max_allowable_drift_mm"],
            baseline_unbraced_drift_mm=result["baseline_unbraced_drift_mm"],
            baseline_weight_tonnes=result["baseline_weight_tonnes"],
            optimal_topology=result["optimal_topology"],
            optimal_system_name=result["optimal_system_name"],
            optimized_drift_mm=result["optimized_drift_mm"],
            drift_reduction_percentage=result["drift_reduction_percentage"],
            added_steel_tonnes=result["added_steel_tonnes"],
            stability_alpha_cr=result["stability_alpha_cr"],
            sway_b2=result["sway_b2"],
            candidates_evaluated=result["candidates_evaluated"],
            new_nodes=result["new_nodes"],
            new_members=result["new_members"],
        )
    except Exception as e:
        logger.error(f"Generative bracing optimization error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/code-check/concrete/column-pm", response_model=ConcreteColumnPMResponse)
def analyze_concrete_column_pm(request: ConcreteColumnPMRequest):
    """
    Evaluates reinforced concrete column & beam cross-sections per ACI 318-19.
    Returns Whitney stress-block interaction envelopes (Mn, Pn) and design (phi*Mn, phi*Pn),
    axial compression caps, exact DCR, and shear stirrup verification.
    """
    try:
        return ACI318ConcreteChecker.analyze_column_pm(request)
    except Exception as e:
        logger.error(f"ACI concrete column P-M analysis error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/code-check/steel/shear-tab")
def check_shear_tab_connection(request: ShearTabRequest):
    """
    Evaluates bolted single-plate shear tab connections per AISC 360-16.
    Accelerated with ConnectionNet-AI neural surrogate forward pass.
    """
    try:
        res = SteelConnectionEngine.evaluate_shear_tab(request)
        ai_pred = neural_registry.predict_connection(
            conn_type=0.0,
            bolts=request.num_bolts,
            d_b=request.bolt_diameter_mm,
            t_p=request.plate_thickness_mm,
            w=request.weld_size_mm,
            fy=request.plate_fy_mpa,
            fu=450.0,
            vu=request.shear_demand_kn,
            mu=0.0,
            pu=0.0,
        )
        res["ai_acceleration"] = ai_pred
        return res
    except Exception as e:
        logger.error(f"Shear tab check error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/code-check/steel/end-plate")
def check_end_plate_moment_connection(request: EndPlateMomentRequest):
    """
    Evaluates extended end-plate moment connections per AISC 358-16 / AISC 360-16.
    Accelerated with ConnectionNet-AI neural surrogate forward pass.
    """
    try:
        res = SteelConnectionEngine.evaluate_end_plate_moment(request)
        num_bolts = 8 if getattr(request, "configuration", "4E") in ["4ES", "8ES"] else 4
        ai_pred = neural_registry.predict_connection(
            conn_type=1.0,
            bolts=num_bolts,
            d_b=request.bolt_diameter_mm,
            t_p=request.plate_thickness_mm,
            w=8.0,
            fy=request.plate_fy_mpa,
            fu=450.0,
            vu=request.shear_demand_kn,
            mu=request.moment_demand_knm,
            pu=0.0,
        )
        res["ai_acceleration"] = ai_pred
        return res
    except Exception as e:
        logger.error(f"End-plate moment check error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/code-check/steel/base-plate")
def check_base_plate_connection(request: BasePlateRequest):
    """
    Evaluates column base plates and anchor rod anchorage per AISC Design Guide 1 and ACI 318-19.
    Accelerated with ConnectionNet-AI neural surrogate forward pass.
    """
    try:
        res = SteelConnectionEngine.evaluate_base_plate(request)
        ai_pred = neural_registry.predict_connection(
            conn_type=2.0,
            bolts=request.num_anchor_rods,
            d_b=request.anchor_diameter_mm,
            t_p=25.0,
            w=10.0,
            fy=request.plate_fy_mpa,
            fu=450.0,
            vu=request.shear_demand_kn,
            mu=request.moment_demand_knm,
            pu=request.axial_demand_kn,
        )
        res["ai_acceleration"] = ai_pred
        return res
    except Exception as e:
        logger.error(f"Base plate check error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/geotechnical/foundation")
def analyze_geotechnical_foundation(request: FootingDesignRequest):
    """
    Evaluates isolated spread footings, Meyerhof bearing capacity, ACI 318-19 punching/beam shear,
    Winkler soil spring stiffness matrix, and immediate elastic settlement.
    Accelerated with FoundationNet-SSI deep neural surrogate.
    """
    try:
        res = GeotechnicalSSIEngine.evaluate_footing(request)
        pu = getattr(request, "axial_load_kn", getattr(request, "column_pu_kn", 1200.0))
        mux = getattr(request, "moment_x_knm", getattr(request, "column_mux_knm", 150.0))
        muy = getattr(request, "moment_y_knm", getattr(request, "column_muy_knm", 0.0))
        b = getattr(request, "footing_width_m", getattr(request, "footing_b_m", 2.5))
        l = getattr(request, "footing_length_m", getattr(request, "footing_l_m", 2.5))
        h = getattr(request, "footing_thickness_m", 0.65)
        c = getattr(request, "soil_cohesion_kpa", 20.0)
        phi = getattr(request, "soil_friction_angle_deg", getattr(request, "soil_friction_deg", 32.0))
        gamma = getattr(request, "soil_unit_weight_kn_m3", 18.5)
        gw = getattr(request, "foundation_depth_m", getattr(request, "water_table_depth_m", 3.0))
        ai_pred = neural_registry.predict_foundation(
            pu=pu, mux=mux, muy=muy, b=b, l=l, h=h, c=c, phi=phi, gamma=gamma, gw=gw,
        )
        res["ai_acceleration"] = ai_pred
        return res
    except Exception as e:
        logger.error(f"Geotechnical foundation error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/analysis/nonlinear-pushover")
def run_nonlinear_pushover_analysis(request: PushoverAnalysisRequest):
    """
    Executes incremental non-linear static pushover analysis per ASCE 41-17 / FEMA 356.
    Accelerated with PushoverNet-PBEE deep sequence surrogate.
    """
    try:
        res = NonlinearPushoverEngine.run_pushover(request)
        h = getattr(request, "building_height_m", getattr(request, "total_height_m", 24.0))
        stories = getattr(request, "num_stories", 6)
        w = getattr(request, "seismic_weight_kn", getattr(request, "total_seismic_weight_kn", 12000.0))
        framing = 0.0 if getattr(request, "lateral_system", "STEEL_SMF") in ["STEEL_SMF", "MOMENT_FRAME"] else 1.0
        ai_pred = neural_registry.predict_pushover(
            stories=stories,
            h=h,
            k=getattr(request, "lateral_stiffness_kn_m", 3.5e5),
            w=w,
            framing=framing,
            vy=getattr(request, "yield_base_shear_kn", 2400.0),
            mu=getattr(request, "ductility_capacity_mu", 4.0),
            alpha=getattr(request, "post_yield_stiffness_ratio_alpha", 0.05),
        )
        res["ai_acceleration"] = ai_pred
        return res
    except Exception as e:
        logger.error(f"Non-linear pushover error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/ai/aero-cfd")
def analyze_aerodynamics_cfd(request: AeroCfdRequest):
    """
    AeroNet-CFD high-rise aerodynamic surrogate per ASCE 7-16 Chapter 31.
    Computes 3D facade Cp pressure fields, Strouhal vortex shedding frequency, and lock-in resonance.
    """
    try:
        res = AeroCfdEngine.evaluate_aerodynamics(request)
        v = getattr(request, "design_wind_speed_m_s", getattr(request, "wind_speed_ms", 40.0))
        exp_str = getattr(request, "terrain_category", getattr(request, "terrain_exposure", "C"))
        exp = 1.0 if exp_str == "C" else (0.0 if exp_str == "B" else 2.0)
        ai_pred = neural_registry.predict_aero(
            h=request.building_height_m,
            b=request.building_width_m,
            d=request.building_depth_m,
            v=v,
            exposure=exp,
        )
        res["ai_acceleration"] = ai_pred
        return res
    except Exception as e:
        logger.error(f"Aero CFD error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/analysis/composite-floor")
def analyze_composite_floor(request: CompositeFloorRequest):
    """
    Evaluates composite steel-concrete deck beams (AISC 360-16 Ch I) and walking floor vibration (DG 11).
    Accelerated with CompositeFloorNet-AI neural surrogate.
    """
    try:
        res = CompositeFloorEngine.evaluate_composite_floor(request)
        ts = getattr(request, "slab_total_thickness_mm", getattr(request, "slab_thickness_mm", 125.0))
        fc = getattr(request, "concrete_fc_mpa", getattr(request, "fc_concrete_mpa", 30.0))
        dl = getattr(request, "dead_load_superimposed_kpa", getattr(request, "dead_load_kpa", 3.5))
        ll = getattr(request, "live_load_kpa", 2.5)
        ai_pred = neural_registry.predict_composite_floor(
            l=request.beam_span_m,
            s=request.beam_spacing_m,
            ts=ts,
            fc=fc,
            d=460.0,
            bf=190.0,
            a=72.0,
            dl=dl,
            ll=ll,
        )
        res["ai_acceleration"] = ai_pred
        return res
    except Exception as e:
        logger.error(f"Composite floor error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


# --------------------------------------------------------------------------
# Direct Dedicated Neural Engine Endpoints
# --------------------------------------------------------------------------
@app.post("/api/v1/ai/connection-net")
def api_connection_net(
    conn_type: float = 0.0,
    bolts: int = 4,
    bolt_d: float = 22.2,
    plate_t: float = 10.0,
    weld_size: float = 8.0,
    fy: float = 345.0,
    fu: float = 450.0,
    vu: float = 180.0,
    mu: float = 0.0,
    pu: float = 0.0,
):
    return neural_registry.predict_connection(conn_type, bolts, bolt_d, plate_t, weld_size, fy, fu, vu, mu, pu)


@app.post("/api/v1/ai/foundation-net")
def api_foundation_net(
    pu: float = 1200.0,
    mux: float = 150.0,
    muy: float = 0.0,
    b: float = 2.5,
    l: float = 2.5,
    h: float = 0.65,
    c: float = 20.0,
    phi: float = 32.0,
    gamma: float = 18.5,
    gw: float = 4.0,
):
    return neural_registry.predict_foundation(pu, mux, muy, b, l, h, c, phi, gamma, gw)


@app.post("/api/v1/ai/pushover-net")
def api_pushover_net(
    stories: int = 8,
    height_m: float = 28.0,
    stiffness: float = 3.5e5,
    weight_kn: float = 12000.0,
    framing: float = 0.0,
    vy_kn: float = 2400.0,
    mu: float = 4.0,
    alpha: float = 0.05,
):
    return neural_registry.predict_pushover(stories, height_m, stiffness, weight_kn, framing, vy_kn, mu, alpha)


@app.post("/api/v1/ai/aero-net")
def api_aero_net(
    height_m: float = 45.0,
    width_m: float = 24.0,
    depth_m: float = 20.0,
    wind_speed_ms: float = 40.0,
    exposure: float = 1.0,
):
    return neural_registry.predict_aero(height_m, width_m, depth_m, wind_speed_ms, exposure)


@app.post("/api/v1/ai/composite-floor-net")
def api_composite_floor_net(
    span_m: float = 10.0,
    spacing_m: float = 2.8,
    slab_mm: float = 125.0,
    fc_mpa: float = 30.0,
    steel_d_mm: float = 460.0,
    steel_bf_mm: float = 190.0,
    steel_area_cm2: float = 72.0,
    dl_kpa: float = 3.5,
    ll_kpa: float = 2.5,
):
    return neural_registry.predict_composite_floor(span_m, spacing_m, slab_mm, fc_mpa, steel_d_mm, steel_bf_mm, steel_area_cm2, dl_kpa, ll_kpa)


@app.post("/api/v1/ai/hazard-stimulate")
def api_hazard_stimulate(
    wind_speed_ms: float = 0.0,
    pga_g: float = 0.0,
    delta_temp_c: float = 0.0,
    snow_load_kpa: float = 0.0,
    settlement_mm: float = 0.0,
    total_mass_kg: float = 50000.0,
    building_height_m: float = 24.0,
):
    return neural_registry.predict_hazard(wind_speed_ms, pga_g, delta_temp_c, snow_load_kpa, settlement_mm, total_mass_kg, building_height_m)


@app.post("/api/v1/ai/modal-net")
def api_modal_net(
    height_m: float = 24.0,
    weight_kn: float = 8000.0,
    framing: float = 0.0,
    ss: float = 1.25,
    s1: float = 0.50,
    stiffness: float = 5e5,
):
    return neural_registry.predict_modal(height_m, weight_kn, framing, ss, s1, stiffness)


@app.post("/api/v1/ai/carbon-net")
def api_carbon_net(
    steel_tonnes: float = 50.0,
    concrete_m3: float = 200.0,
    area_m2: float = 2500.0,
    stories: int = 6,
    target_reduction: float = 30.0,
):
    return neural_registry.predict_carbon(steel_tonnes, concrete_m3, area_m2, stories, target_reduction)



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
# Phase 6: Vision-to-BIM, Geotechnical Soil Springs & NLTHA Endpoints
# -------------------------------------------------------------
class GeotechnicalEvaluateRequest(BaseModel):
    graph: StructuralGraphPayload
    spring_params: Optional[SoilSpringsRequest] = None


class NlthaRunRequest(BaseModel):
    graph: StructuralGraphPayload
    nltha_params: Optional[NlthaRequest] = None


@app.post("/api/v1/ai/vision-to-bim", response_model=VisionToBimResponse)
async def vision_to_bim(
    raw_request: Request,
):
    """
    Multimodal Vision-to-BIM Floorplan Ingestion:
    Extracts structural gridlines, column locations, shear walls, and synthesizes 3D space frame.
    Supports both JSON body (VisionToBimRequest) and multipart/form-data upload.
    """
    try:
        content_type = raw_request.headers.get("content-type", "") if raw_request else ""
        if "multipart/form-data" in content_type:
            form = await raw_request.form()
            uploaded_file = form.get("file")
            b64_img = None
            filename = "floorplan.png"
            if isinstance(uploaded_file, UploadFile):
                content = await uploaded_file.read()
                b64_img = base64.b64encode(content).decode("utf-8")
                filename = uploaded_file.filename or filename

            req = VisionToBimRequest(
                image_base64=b64_img,
                filename=filename,
                num_stories=int(form.get("num_stories", 3)),
                story_height_m=float(form.get("story_height_m", 3.6)),
                default_column_section=str(form.get("default_column_section", "W14X90")),
                default_beam_section=str(form.get("default_beam_section", "W18X50")),
            )
            return VisionToBimProcessor.process_floorplan(req)
        else:
            body = await raw_request.json()
            req = VisionToBimRequest(**body)
            return VisionToBimProcessor.process_floorplan(req)
    except Exception as e:
        logger.error(f"Vision-to-BIM processing error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/ai/vision-to-bim/upload", response_model=VisionToBimResponse)
async def vision_to_bim_upload(
    file: UploadFile = File(...),
    num_stories: int = Form(3),
    story_height_m: float = Form(3.6),
    default_column_section: str = Form("W14X90"),
    default_beam_section: str = Form("W18X50"),
):
    """
    Explicit multipart/form-data upload route for 2D architectural plans (PDF, PNG, JPEG).
    """
    try:
        content = await file.read()
        b64_img = base64.b64encode(content).decode("utf-8")
        req = VisionToBimRequest(
            image_base64=b64_img,
            filename=file.filename or "floorplan.png",
            num_stories=num_stories,
            story_height_m=story_height_m,
            default_column_section=default_column_section,
            default_beam_section=default_beam_section,
        )
        return VisionToBimProcessor.process_floorplan(req)
    except Exception as e:
        logger.error(f"Vision-to-BIM upload processing error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/geotechnical/evaluate", response_model=GeotechnicalAnalysisResponse)
def evaluate_geotechnical_foundations(request: GeotechnicalEvaluateRequest):
    """
    Evaluates 6-DOF Winkler soil springs, contact pressure distributions, and ACI 318-19 punching shear.
    """
    try:
        return GeotechnicalEngine.evaluate_foundations(
            payload=request.graph,
            req=request.spring_params or SoilSpringsRequest(),
        )
    except Exception as e:
        logger.error(f"Geotechnical evaluation error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/solvers/nltha/earthquakes")
def list_nltha_earthquakes():
    """
    Returns available canonical earthquake accelerogram records.
    """
    return NlthaEngine.get_available_earthquakes()


@app.post("/api/v1/solvers/nltha", response_model=NlthaResponse)
def run_nltha(request: NlthaRunRequest):
    """
    Non-Linear Time History Analysis (NLTHA) using Newmark-Beta integration with Rayleigh damping.
    """
    try:
        return NlthaEngine.solve_nltha(
            payload=request.graph,
            req=request.nltha_params or NlthaRequest(),
        )
    except Exception as e:
        logger.error(f"NLTHA engine execution error: {str(e)}", exc_info=True)
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
