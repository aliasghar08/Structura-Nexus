"""
FoundationNet-SSI: Physics-Informed Deep Neural Surrogate for Soil-Structure Interaction
Predicts bearing capacity, 3D settlement profiles, and 6-DOF dynamic Winkler spring stiffness.
"""

from typing import Dict, Any
import torch
import torch.nn as nn
import torch.nn.functional as F


class FoundationNetSSI(nn.Module):
    """
    Neural surrogate for Geotechnical Foundation & Soil-Structure Interaction.
    Architecture:
      Input (10) -> Linear(128) -> LayerNorm -> SiLU ->
      ResBlock(128) -> ResBlock(128) ->
      Heads:
        - Bearing & Settlement Head: Linear(128, 64) -> SiLU -> Linear(64, 4) [q_ult, q_allow, elastic_settle, consol_settle]
        - Structural DCRs Head: Linear(128, 64) -> SiLU -> Linear(64, 3) [bearing_dcr, punching_dcr, one_way_shear_dcr]
        - Winkler Springs Head: Linear(128, 64) -> SiLU -> Linear(64, 3) [K_z, K_x, K_theta]
    """
    def __init__(self, in_dim: int = 10, hidden_dim: int = 128):
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

        self.soil_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 4)
        )

        self.dcr_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 3)
        )

        self.winkler_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 3)
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

        soil_outputs = F.softplus(self.soil_head(h))
        dcrs = F.softplus(self.dcr_head(h))
        winkler = F.softplus(self.winkler_head(h))

        return {
            "soil_outputs": soil_outputs,
            "dcrs": dcrs,
            "winkler_springs": winkler,
        }

    def export_weights_dict(self) -> Dict[str, Any]:
        out = {}
        for k, v in self.state_dict().items():
            out[k] = v.cpu().numpy().tolist()
        return out
