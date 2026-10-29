"""
ModalEigenNet-AI: Deep Neural Surrogate for Dynamic Eigenvalues & Seismic Base Shear
Predicts fundamental periods (T1, T2, T3), modal mass participation, and seismic base shear in <0.2ms.
"""

from typing import Dict, Any
import torch
import torch.nn as nn
import torch.nn.functional as F


class ModalEigenNetAI(nn.Module):
    """
    Neural surrogate for dynamic modal eigenvalue analysis and ASCE 7-16 seismic response.
    Input (6): [total_height_m, total_weight_kn, framing_type, Ss, S1, lateral_stiffness]
    Outputs:
      - Periods & Frequencies: [T1_s, T2_s, T3_s, f1_hz, f2_hz, f3_hz]
      - Mass Participation: [Ux_pct, Uy_pct, Rz_pct]
      - Seismic Demands: [Cs_coeff, V_base_kn, drift_ratio_pct]
    """
    def __init__(self, in_dim: int = 6, hidden_dim: int = 128):
        super().__init__()
        self.input_layer = nn.Linear(in_dim, hidden_dim)
        self.in_norm = nn.LayerNorm(hidden_dim)

        self.res1_fc1 = nn.Linear(hidden_dim, hidden_dim)
        self.res1_norm1 = nn.LayerNorm(hidden_dim)
        self.res1_fc2 = nn.Linear(hidden_dim, hidden_dim)
        self.res1_norm2 = nn.LayerNorm(hidden_dim)

        self.period_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 6)
        )

        self.mass_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 3)
        )

        self.seismic_head = nn.Sequential(
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

        periods = F.softplus(self.period_head(h))
        mass_participation = torch.sigmoid(self.mass_head(h)) * 100.0
        seismic = F.softplus(self.seismic_head(h))

        return {
            "periods": periods,
            "mass_participation": mass_participation,
            "seismic": seismic,
        }

    def export_weights_dict(self) -> Dict[str, Any]:
        out = {}
        for k, v in self.state_dict().items():
            out[k] = v.cpu().numpy().tolist()
        return out
