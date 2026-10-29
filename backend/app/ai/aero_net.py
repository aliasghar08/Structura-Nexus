"""
AeroNet-CFD: Deep Neural Flow Surrogate for High-Rise Wind Aerodynamics
Predicts continuous facade pressure fields Cp, corner separation vortex suctions, and vortex-shedding lock-in in <0.2ms.
"""

from typing import Dict, Any
import torch
import torch.nn as nn
import torch.nn.functional as F


class AeroNetCFD(nn.Module):
    """
    Neural surrogate for Computational Fluid Dynamics (CFD) and Boundary Layer Wind Tunnel analysis.
    Architecture:
      Input (5) -> Linear(128) -> LayerNorm -> SiLU ->
      ResBlock(128) -> ResBlock(128) ->
      Heads:
        - Cp Contour Head: Linear(128, 64) -> SiLU -> Linear(64, 6) [Cp for 6 facade zones]
        - Vortex & Aerodynamics Head: Linear(128, 64) -> SiLU -> Linear(64, 5) [fs_hz, qz_pa, v_along_kn, v_across_kn, critical_speed_ms]
        - Resonance Classification Head: Linear(128, 32) -> SiLU -> Linear(32, 2) [Logits for lock-in risk]
    """
    def __init__(self, in_dim: int = 5, hidden_dim: int = 128):
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

        self.cp_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 6)
        )

        self.aero_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 5)
        )

        self.risk_head = nn.Sequential(
            nn.Linear(hidden_dim, 32),
            nn.SiLU(),
            nn.Linear(32, 2)
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

        cp_profile = self.cp_head(h)  # Can be negative for suctions
        aero_telem = F.softplus(self.aero_head(h))
        risk_logits = self.risk_head(h)

        return {
            "cp_profile": cp_profile,
            "aero_telemetry": aero_telem,
            "risk_logits": risk_logits,
        }

    def export_weights_dict(self) -> Dict[str, Any]:
        out = {}
        for k, v in self.state_dict().items():
            out[k] = v.cpu().numpy().tolist()
        return out
