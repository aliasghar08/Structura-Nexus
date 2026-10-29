"""
CompositeFloorNet-AI: Deep Neural Surrogate for AISC 360 Ch I Composite Beams & AISC DG 11 Vibrations
Predicts transformed flexural capacity, walking resonance frequency fn, and human comfort ap/g in <0.2ms.
"""

from typing import Dict, Any
import torch
import torch.nn as nn
import torch.nn.functional as F


class CompositeFloorNetAI(nn.Module):
    """
    Neural surrogate for Composite Steel-Concrete Floor Systems and Walking Vibration Dynamics.
    Architecture:
      Input (9) -> Linear(128) -> LayerNorm -> SiLU ->
      ResBlock(128) -> ResBlock(128) ->
      Heads:
        - Structural Capacity Head: Linear(128, 64) -> SiLU -> Linear(64, 4) [phi_Mn_knm, I_eff, flexure_dcr, deflection_dcr]
        - Walking Vibration Head: Linear(128, 64) -> SiLU -> Linear(64, 4) [fn_hz, ap_over_g_pct, comfort_dcr, optimal_stud_count]
    """
    def __init__(self, in_dim: int = 9, hidden_dim: int = 128):
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

        self.capacity_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 4)
        )

        self.vibration_head = nn.Sequential(
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

        capacity = F.softplus(self.capacity_head(h))
        vibration = F.softplus(self.vibration_head(h))

        return {
            "capacity": capacity,
            "vibration": vibration,
        }

    def export_weights_dict(self) -> Dict[str, Any]:
        out = {}
        for k, v in self.state_dict().items():
            out[k] = v.cpu().numpy().tolist()
        return out

