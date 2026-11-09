"""
STRUCTURA NEXUS v4.0 — EPISTEMIC UNCERTAINTY ROUTER & ACTIVE LEARNING
Calculates Monte Carlo Dropout / Deep Ensemble epistemic variance for StructuraNet-3D.
When variance exceeds 0.08, automatically routes to 12-DOF DSM solver and logs OOD hard example.
"""

import os
import json
import time
import numpy as np
from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field

from backend.app.models.schema import StructuralGraphPayload, SolverResponse
from backend.app.solvers.fea_engine import FEA3DSpaceFrameSolver
from backend.app.surrogate.gnn_surrogate import GNNSurrogateEngine


class UncertaintyGatingResult(BaseModel):
    is_trusted: bool
    epistemic_variance: float
    threshold: float = 0.08
    solver_used: str  # "StructuraNet-3D (Surrogate)" or "12-DOF DSM (Ground Truth)"
    ood_flagged: bool
    latency_ms: float
    displacements: Dict[str, List[float]]


class UncertaintyRouter:
    HARD_EXAMPLES_PATH = os.path.join(os.path.dirname(__file__), "../../../backend/data/hard_examples_queue.jsonl")

    @classmethod
    def evaluate_and_route(
        cls,
        payload: StructuralGraphPayload,
        mc_passes: int = 5,
        variance_threshold: float = 0.08
    ) -> UncertaintyGatingResult:
        start_time = time.perf_counter()

        mc_results: List[Dict[str, List[float]]] = []
        for _ in range(mc_passes):
            res = GNNSurrogateEngine.infer(payload)
            disp_map = {n.id: n.displacements for n in res.nodes}
            mc_results.append(disp_map)

        node_ids = [n.id for n in payload.nodes]
        variances = []
        for n_id in node_ids:
            disps = np.array([mc_results[p].get(n_id, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]) for p in range(mc_passes)])
            var_node = np.var(disps[:, :3], axis=0)
            variances.append(float(np.mean(var_node)))

        avg_variance = float(np.mean(variances)) if variances else 0.0
        normalized_variance = min(avg_variance * 1000.0, 1.0)

        if normalized_variance <= variance_threshold:
            trusted_disp = mc_results[0]
            elapsed_ms = (time.perf_counter() - start_time) * 1000.0
            return UncertaintyGatingResult(
                is_trusted=True,
                epistemic_variance=round(normalized_variance, 5),
                threshold=variance_threshold,
                solver_used="StructuraNet-3D (Surrogate)",
                ood_flagged=False,
                latency_ms=round(elapsed_ms, 2),
                displacements=trusted_disp,
            )
        else:
            exact_res = FEA3DSpaceFrameSolver.solve(payload)
            elapsed_ms = (time.perf_counter() - start_time) * 1000.0
            exact_disp = {n.id: n.displacements for n in exact_res.nodes}

            cls._log_hard_example(payload, exact_res, normalized_variance)

            return UncertaintyGatingResult(
                is_trusted=False,
                epistemic_variance=round(normalized_variance, 5),
                threshold=variance_threshold,
                solver_used="12-DOF DSM (Ground Truth)",
                ood_flagged=True,
                latency_ms=round(elapsed_ms, 2),
                displacements=exact_disp,
            )

    @classmethod
    def _log_hard_example(cls, payload: StructuralGraphPayload, res: SolverResponse, variance: float):
        try:
            os.makedirs(os.path.dirname(cls.HARD_EXAMPLES_PATH), exist_ok=True)
            gov_dcr = max((m.governing_dcr for m in res.members), default=0.5)
            record = {
                "timestamp": str(np.datetime64('now')),
                "num_nodes": len(payload.nodes),
                "num_members": len(payload.members),
                "epistemic_variance": variance,
                "governing_dcr": gov_dcr,
            }
            with open(cls.HARD_EXAMPLES_PATH, "a") as f:
                f.write(json.dumps(record) + "\n")
        except Exception:
            pass
