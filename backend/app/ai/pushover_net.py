"""
PushoverNet-PBEE: Deep Sequence Neural Surrogate for ASCE 41-17 Non-Linear Pushover
Predicts entire non-linear pushover curve, hinge evolution, and ATC-40 ADRS Performance Point in <0.3ms.
"""

from typing import Dict, Any
import torch
import torch.nn as nn
import torch.nn.functional as F


class PushoverNetPBEE(nn.Module):
    """
    Neural surrogate for Non-Linear Static Pushover & Performance-Based Earthquake Engineering.
    Architecture:
      Input (8) -> Linear(128) -> LayerNorm -> SiLU ->
      ResBlock(128) -> ResBlock(128) ->
      Heads:
        - Pushover Curve Head: Linear(128, 128) -> SiLU -> Linear(128, 40) [20 pairs of (drift_m, base_shear_kn)]
        - Performance Point Head: Linear(128, 64) -> SiLU -> Linear(64, 4) [Sa, Sd, V_perf, Delta_perf]
        - Hinge State Distribution Head: Linear(128, 64) -> SiLU -> Linear(64, 4) [IO_pct, LS_pct, CP_pct, Failure_pct]
    """
    def __init__(self, in_dim: int = 8, hidden_dim: int = 128):
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

        self.curve_head = nn.Sequential(
            nn.Linear(hidden_dim, 128),
            nn.SiLU(),
            nn.Linear(128, 40)
        )

        self.perf_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 4)
        )

        self.hinge_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 4)
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

        curve_points = F.softplus(self.curve_head(h))
        perf_point = F.softplus(self.perf_head(h))
        hinge_distribution = F.softmax(self.hinge_head(h), dim=-1)

        return {
            "curve_points": curve_points,
            "perf_point": perf_point,
            "hinge_distribution": hinge_distribution,
        }

    def export_weights_dict(self) -> Dict[str, Any]:
        out = {}
        for k, v in self.state_dict().items():
            out[k] = v.cpu().numpy().tolist()
        return out

