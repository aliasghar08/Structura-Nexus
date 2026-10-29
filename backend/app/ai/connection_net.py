"""
ConnectionNet-AI: Deep Neural Surrogate for AISC 360-16 / 358 Steel Connections
Predicts multi-limit-state DCRs, failure mode, and rotational stiffness K_conn in <0.2ms.
"""

import math
from typing import Dict, List, Any
import torch
import torch.nn as nn
import torch.nn.functional as F


class ConnectionNetAI(nn.Module):
    """
    Multi-layer neural surrogate for steel connection limit-state analysis.
    Architecture:
      Input (10) -> Linear(128) -> LayerNorm -> SiLU ->
      ResBlock(128) -> ResBlock(128) ->
      Heads:
        - DCR Head: Linear(128, 64) -> SiLU -> Linear(64, 6) [Sigmoid/Softplus for DCRs]
        - Failure Mode Head: Linear(128, 64) -> SiLU -> Linear(64, 5) [Logits]
        - Stiffness & Optimal Head: Linear(128, 64) -> SiLU -> Linear(64, 3) [K_conn, opt_bolts, opt_thickness]
    """
    def __init__(self, in_dim: int = 10, hidden_dim: int = 128):
        super().__init__()
        self.in_dim = in_dim
        self.hidden_dim = hidden_dim

        self.input_layer = nn.Linear(in_dim, hidden_dim)
        self.in_norm = nn.LayerNorm(hidden_dim)

        # Residual Block 1
        self.res1_fc1 = nn.Linear(hidden_dim, hidden_dim)
        self.res1_norm1 = nn.LayerNorm(hidden_dim)
        self.res1_fc2 = nn.Linear(hidden_dim, hidden_dim)
        self.res1_norm2 = nn.LayerNorm(hidden_dim)

        # Residual Block 2
        self.res2_fc1 = nn.Linear(hidden_dim, hidden_dim)
        self.res2_norm1 = nn.LayerNorm(hidden_dim)
        self.res2_fc2 = nn.Linear(hidden_dim, hidden_dim)
        self.res2_norm2 = nn.LayerNorm(hidden_dim)

        # Head 1: Multi-limit-state DCRs (6 limit states)
        self.dcr_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 6)
        )

        # Head 2: Failure Mode Classification (5 classes)
        # 0: Bolt Shear, 1: Plate Bearing, 2: Block Shear, 3: Weld Rupture, 4: Plate Yielding
        self.failure_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 5)
        )

        # Head 3: Rotational Stiffness, Optimal Bolts, Optimal Plate Thickness
        self.telem_head = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.SiLU(),
            nn.Linear(64, 3)
        )

    def forward(self, x: torch.Tensor) -> Dict[str, torch.Tensor]:
        h = F.silu(self.in_norm(self.input_layer(x)))

        # Res 1
        res = h
        h = F.silu(self.res1_norm1(self.res1_fc1(h)))
        h = self.res1_norm2(self.res1_fc2(h))
        h = F.silu(h + res)

        # Res 2
        res = h
        h = F.silu(self.res2_norm1(self.res2_fc1(h)))
        h = self.res2_norm2(self.res2_fc2(h))
        h = F.silu(h + res)

        dcrs = F.softplus(self.dcr_head(h))
        failure_logits = self.failure_head(h)
        telem = self.telem_head(h)

        return {
            "dcrs": dcrs,
            "failure_logits": failure_logits,
            "telem": telem,
        }

    def export_weights_dict(self) -> Dict[str, Any]:
        """Exports state dict to JSON-serializable structure for pure Dart tensor runtime."""
        out = {}
        for k, v in self.state_dict().items():
            out[k] = v.cpu().numpy().tolist()
        return out

