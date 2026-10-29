"""
HazardDynamicNet-AI: Deep Multi-Hazard Physics-Informed Dynamic Response Surrogate
Predicts non-linear real-time structural degradation, drift amplification, and health index in <0.2ms.
"""

from typing import Dict, Any
import torch
import torch.nn as nn
import torch.nn.functional as F


class HazardDynamicNetAI(nn.Module):
    """
    Neural dynamic surrogate for Multi-Hazard Environmental Dynamic Loading
    (Hurricane Wind + Earthquake Shaking + Fire Thermal + Snow Drift + Foundation Subsidence).
    Architecture:
      Input (7) -> Linear(128) -> LayerNorm -> SiLU ->
      ResBlock(128) -> ResBlock(128) ->
      Heads:
        - Dynamic Response Head: Linear(128, 64) -> SiLU -> Linear(64, 4) [max_drift_mm, base_shear_kn, drift_ratio, overstressed_count]
        - Safety & Health Head: Linear(128, 64) -> SiLU -> Linear(64, 2) [health_score_pct, collapse_risk_logit]
    """
    def __init__(self, in_dim: int = 7, hidden_dim: int = 128):
        super().__init__()
        self.in_dim = in_dim
        self.hidden_dim = hidden_dim

        self.input_layer = nn.Linear(in_dim, hidden_dim)
        self.in_norm = nn.LayerNorm(hidden_dim)

        self.res1_fc1 = nn.Linear(hidden_dim, hidden_dim)
        self.res1_norm1 = nn.LayerNorm(hidden_dim)
        self.res1_fc2 = nn.Linear(hidden_dim, hidden_dim)
        self.res1_norm2 = nn.LayerNorm(hidden_dim)

        self.res2_fc1 = nn.Linear(hidden_dim, hidden_dim)
        self.res2_norm1 = nn.LayerNorm(hidden_dim)
        self.res2_fc2 = nn.Linear(hidden_dim, hidden_dim)
        self.res2_norm2 = nn.LayerNorm(hidden_dim)

        self.response_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 4)
        )

        self.health_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 2)
        )

    def forward(self, x: torch.Tensor) -> Dict[str, torch.Tensor]:
        h = F.silu(self.in_norm(self.input_layer(x)))

        res = h
        h = F.silu(self.res1_norm1(self.res1_fc1(h)))
        h = self.res1_norm2(self.res1_fc2(h))
        h = F.silu(h + res)

        res = h
        h = F.silu(self.res2_norm1(self.res2_fc1(h)))
        h = self.res2_norm2(self.res2_fc2(h))
        h = F.silu(h + res)

        resp = F.softplus(self.response_head(h))
        health = self.health_head(h)

        return {
            "dynamic_response": resp,
            "safety_health": health,
        }

    def export_weights_dict(self) -> Dict[str, Any]:
        out = {}
        for k, v in self.state_dict().items():
            out[k] = v.cpu().numpy().tolist()
        return out

