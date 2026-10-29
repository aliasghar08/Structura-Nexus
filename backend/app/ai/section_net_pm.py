"""
Structura Nexus: SectionNet-PM Proprietary Concrete Cross-Section Neural Network
Predicts full ACI 318-19 non-linear (phi*Mn, phi*Pn) interaction envelopes, governing DCR,
and optimal reinforcement ratios in <0.2ms.
"""

import math
from typing import Dict, Any, List, Tuple, Optional
import torch
import torch.nn as nn
import torch.nn.functional as F

class ResMLPBlock(nn.Module):
    def __init__(self, dim: int = 128):
        super().__init__()
        self.fc1 = nn.Linear(dim, dim)
        self.norm1 = nn.LayerNorm(dim)
        self.fc2 = nn.Linear(dim, dim)
        self.norm2 = nn.LayerNorm(dim)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        res = x
        h = F.silu(self.norm1(self.fc1(x)))
        h = self.norm2(self.fc2(h))
        return F.silu(res + h)

class SectionNetPM(nn.Module):
    """
    Residual Multi-Layer Perceptron predicting:
    1. 32-point (phi*Mn, phi*Pn) interaction envelope coordinates (64 float outputs).
    2. Governing DCR_PM, Shear DCR_V, and optimal rebar ratio rho_opt.
    """
    def __init__(self, in_dim: int = 10, hidden_dim: int = 128, num_blocks: int = 3):
        super().__init__()
        self.in_dim = in_dim
        self.hidden_dim = hidden_dim

        # Input projection
        self.input_proj = nn.Sequential(
            nn.Linear(in_dim, hidden_dim),
            nn.LayerNorm(hidden_dim),
            nn.SiLU(),
        )

        # Residual backbone
        self.blocks = nn.ModuleList([ResMLPBlock(hidden_dim) for _ in range(num_blocks)])

        # Envelope head: 64 outputs (32 pairs of phi_mn and phi_pn)
        self.envelope_head = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, 64),
        )

        # Telemetry & DCR head: [dcr_pm, dcr_v, optimal_rebar_ratio]
        self.dcr_head = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim // 2),
            nn.SiLU(),
            nn.Linear(hidden_dim // 2, 3),
        )

        self._init_weights()

    def _init_weights(self):
        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.kaiming_normal_(m.weight, nonlinearity='relu')
                if m.bias is not None:
                    nn.init.zeros_(m.bias)

    def forward(self, x: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor]:
        """
        x: [batch, 10] normalized vector:
           [b, h, cover, fc, fy, rho, tie_d, tie_s, Pu, Mu]
        Returns:
           pred_envelope: [batch, 64]
           pred_telemetry: [batch, 3] (dcr_pm, dcr_v, rho_opt)
        """
        h = self.input_proj(x)
        for block in self.blocks:
            h = block(h)

        envelope = self.envelope_head(h)
        telemetry = self.dcr_head(h)
        return envelope, telemetry

    def export_to_json_dict(self) -> Dict[str, Any]:
        """Exports all weights and biases to pure JSON serializable Python dict."""
        weights_dict = {
            "model_type": "SectionNetPM",
            "version": "1.0-PROPRIETARY",
            "in_dim": self.in_dim,
            "hidden_dim": self.hidden_dim,
            "layers": {}
        }

        # Helper to export linear and norm layers
        def export_linear(name: str, layer: nn.Linear):
            weights_dict["layers"][f"{name}.weight"] = layer.weight.detach().cpu().tolist()
            if layer.bias is not None:
                weights_dict["layers"][f"{name}.bias"] = layer.bias.detach().cpu().tolist()

        def export_norm(name: str, layer: nn.LayerNorm):
            weights_dict["layers"][f"{name}.weight"] = layer.weight.detach().cpu().tolist()
            weights_dict["layers"][f"{name}.bias"] = layer.bias.detach().cpu().tolist()

        export_linear("input_proj.0", self.input_proj[0])
        export_norm("input_proj.1", self.input_proj[1])

        for i, blk in enumerate(self.blocks):
            export_linear(f"block_{i}.fc1", blk.fc1)
            export_norm(f"block_{i}.norm1", blk.norm1)
            export_linear(f"block_{i}.fc2", blk.fc2)
            export_norm(f"block_{i}.norm2", blk.norm2)

        export_linear("envelope_head.0", self.envelope_head[0])
        export_linear("envelope_head.2", self.envelope_head[2])

        export_linear("dcr_head.0", self.dcr_head[0])
        export_linear("dcr_head.2", self.dcr_head[2])

        return weights_dict

