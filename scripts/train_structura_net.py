#!/usr/bin/env python3
"""
Structura Nexus: Proprietary StructuraNet-3D Physics-Informed Training Pipeline
Trains StructuraNet-3D on self-generated space frames, trusses, and multi-story frames
using a Composite Physics-Informed Loss Function:
  L_total = Kinematic Loss + 0.1 * Force Loss + 0.2 * Equilibrium Residual Loss + 0.15 * Peak Sway Penalty

Exports:
- PyTorch Checkpoint: backend/app/weights/structura_net_3d.pt
- Client JSON Weights: structura_nexus/assets/weights/structura_net_3d_weights.json
"""

import os
import sys
import time
import json
import random
import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim

# Add repo root to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.app.surrogate.gnn_surrogate import StructuraNet3D, GNNSurrogateEngine
from backend.app.models.schema import StructuralGraphPayload, NodeModel, MemberModel
from backend.app.solvers.fea_engine import FEA3DSpaceFrameSolver


def generate_synthetic_3d_frame(num_stories: int = 3, num_bays: int = 2) -> StructuralGraphPayload:
    """Generates a parametric 3D space frame with realistic lateral and gravity loading."""
    nodes = []
    members = []

    bay_w = random.uniform(4.0, 8.0)
    bay_d = random.uniform(4.0, 7.0)
    story_h = random.uniform(3.0, 4.2)

    for floor in range(num_stories + 1):
        y = floor * story_h
        for bx in range(num_bays + 1):
            x = bx * bay_w
            for bz in range(2): # 2 grid lines in Z for 3D frame
                z = bz * bay_d
                node_id = f"N_{floor}_{bx}_{bz}"
                if floor == 0:
                    restraint = [1, 1, 1, 1, 1, 1]
                    loads = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
                else:
                    restraint = [0, 0, 0, 0, 0, 0]
                    wind_x = random.uniform(8000.0, 30000.0) if bx == 0 else 0.0
                    wind_z = random.uniform(3000.0, 15000.0) if bz == 0 else 0.0
                    gravity_y = -random.uniform(20000.0, 75000.0)
                    loads = [wind_x, gravity_y, wind_z, 0.0, 0.0, 0.0]

                nodes.append(NodeModel(id=node_id, coords=[x, y, z], restraint=restraint, loads=loads))

    # Columns
    for floor in range(num_stories):
        for bx in range(num_bays + 1):
            for bz in range(2):
                members.append(MemberModel(
                    id=f"COL_{floor}_{bx}_{bz}",
                    i_node=f"N_{floor}_{bx}_{bz}",
                    j_node=f"N_{floor+1}_{bx}_{bz}",
                    section=random.choice(["W14X90", "W14X68", "W14X48", "W12X53"]),
                    material="A992_STEEL"
                ))

    # Girders in X direction
    for floor in range(1, num_stories + 1):
        for bx in range(num_bays):
            for bz in range(2):
                members.append(MemberModel(
                    id=f"BMX_{floor}_{bx}_{bz}",
                    i_node=f"N_{floor}_{bx}_{bz}",
                    j_node=f"N_{floor}_{bx+1}_{bz}",
                    section=random.choice(["W18X50", "W16X31", "W14X26"]),
                    material="A992_STEEL"
                ))

    # Beams in Z direction
    for floor in range(1, num_stories + 1):
        for bx in range(num_bays + 1):
            members.append(MemberModel(
                id=f"BMZ_{floor}_{bx}_0",
                i_node=f"N_{floor}_{bx}_0",
                j_node=f"N_{floor}_{bx}_1",
                section=random.choice(["W16X26", "W14X22", "W12X19"]),
                material="A992_STEEL"
            ))

    payload = StructuralGraphPayload(
        session_id=f"train_structuranet_{int(time.time()*1000)}",
        action="EXACT_SOLVE",
        load_combination="1.2D+1.6L",
        nodes=nodes,
        members=members
    )
    return payload


def train_structura_net():
    print("=================================================================")
    print("StructuraNet-3D: Self-Supervised Physics-Informed Training Loop")
    print("=================================================================")

    device = torch.device("mps" if torch.backends.mps.is_available() else ("cuda" if torch.cuda.is_available() else "cpu"))
    print(f"[*] Training device: {device}")

    # Initialize model
    model = StructuraNet3D(node_in_dim=15, edge_in_dim=10, hidden_dim=128, num_layers=4).to(device)
    optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-5)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=40, eta_min=1e-5)

    num_samples = 40
    print(f"[*] Synthesizing and solving {num_samples} diverse 3D frames with proprietary FEA...")
    dataset = []

    for i in range(num_samples):
        stories = random.choice([2, 3, 4])
        bays = random.choice([1, 2])
        payload = generate_synthetic_3d_frame(num_stories=stories, num_bays=bays)
        
        # Authoritative proprietary DSM solve
        exact_res = FEA3DSpaceFrameSolver.solve(payload)
        x, edge_index, edge_attr, node_map = GNNSurrogateEngine.vectorize_graph(payload)

        # Ground truth displacements [N, 6]
        y_disp = torch.zeros((len(payload.nodes), 6), dtype=torch.float32, device=device)
        for n in exact_res.nodes:
            idx = node_map[n.id]
            y_disp[idx] = torch.tensor(n.displacements, dtype=torch.float32, device=device)

        # Ground truth forces [E, 6]
        y_forces = torch.zeros((edge_index.size(1), 6), dtype=torch.float32, device=device)
        for m in exact_res.members:
            u = node_map[m.i_node]
            v = node_map[m.j_node]
            f_vec = torch.tensor([m.axial_force, m.shear_y, m.shear_z, m.torsion, m.moment_y, m.moment_z], dtype=torch.float32, device=device)
            for e_idx in range(edge_index.size(1)):
                if (edge_index[0, e_idx] == u and edge_index[1, e_idx] == v) or (edge_index[0, e_idx] == v and edge_index[1, e_idx] == u):
                    y_forces[e_idx] = f_vec

        applied_loads = torch.tensor([[float(n.loads[d]) for d in range(6)] for n in payload.nodes], dtype=torch.float32, device=device)
        restraints = torch.tensor([[float(n.restraint[d]) for d in range(6)] for n in payload.nodes], dtype=torch.float32, device=device)

        dataset.append({
            "x": x,
            "edge_index": edge_index,
            "edge_attr": edge_attr,
            "y_disp": y_disp,
            "y_forces": y_forces,
            "applied_loads": applied_loads,
            "restraints": restraints,
        })

    print(f"[*] Generated {len(dataset)} solved structural graphs. Commencing training epochs...")

    epochs = 35
    history = []

    model.train()
    for epoch in range(1, epochs + 1):
        total_loss = 0.0
        kinematic_loss_sum = 0.0
        force_loss_sum = 0.0
        equilibrium_loss_sum = 0.0
        peak_loss_sum = 0.0

        random.shuffle(dataset)

        for sample in dataset:
            optimizer.zero_grad()
            x = sample["x"]
            edge_index = sample["edge_index"]
            edge_attr = sample["edge_attr"]
            y_disp = sample["y_disp"]
            y_forces = sample["y_forces"]
            applied_loads = sample["applied_loads"]
            restraints = sample["restraints"]

            pred_disp, pred_forces = model(x, edge_index, edge_attr)

            # 1. Kinematic Displacement Loss: ||u - u_hat||_2^2
            loss_kinematic = F.mse_loss(pred_disp, y_disp)

            # 2. Internal Force Loss: ||f - f_hat||_2^2 (scaled)
            loss_force = F.mse_loss(pred_forces / 1e4, y_forces / 1e4)

            # 3. Physics-Informed Equilibrium Residual Loss: ||R_eq(u_hat, f_hat)||_2^2
            # Sum of forces at free nodes should balance applied loads
            free_mask = (1.0 - restraints)
            nodal_force_aggregates = torch.zeros_like(applied_loads)
            if edge_index.size(1) > 0:
                # Aggregate axial and shear predictions to nodes
                receiver_idx = edge_index[1]
                # Project edge forces into global translational forces approx
                nodal_force_aggregates.index_add_(0, receiver_idx, pred_forces)

            equilibrium_residual = (nodal_force_aggregates - applied_loads) * free_mask
            loss_equilibrium = F.mse_loss(equilibrium_residual / 1e4, torch.zeros_like(equilibrium_residual))

            # 4. Peak Sway / Maximum Deflection Penalty
            max_pred_sway = torch.max(torch.norm(pred_disp[:, :3], dim=-1))
            max_true_sway = torch.max(torch.norm(y_disp[:, :3], dim=-1))
            loss_peak = torch.abs(max_pred_sway - max_true_sway)

            # Composite Physics Loss
            loss = (
                loss_kinematic
                + 0.10 * loss_force
                + 0.20 * loss_equilibrium
                + 0.15 * loss_peak
            )

            loss.backward()
            nn.utils.clip_grad_norm_(model.parameters(), max_norm=2.0)
            optimizer.step()

            total_loss += loss.item()
            kinematic_loss_sum += loss_kinematic.item()
            force_loss_sum += loss_force.item()
            equilibrium_loss_sum += loss_equilibrium.item()
            peak_loss_sum += loss_peak.item()

        scheduler.step()
        avg_loss = total_loss / len(dataset)
        history.append({
            "epoch": epoch,
            "total_loss": round(avg_loss, 5),
            "kinematic_loss": round(kinematic_loss_sum / len(dataset), 5),
            "force_loss": round(force_loss_sum / len(dataset), 5),
            "equilibrium_loss": round(equilibrium_loss_sum / len(dataset), 5),
            "peak_loss": round(peak_loss_sum / len(dataset), 5),
        })

        if epoch % 5 == 0 or epoch == epochs:
            print(f"Epoch {epoch:2d}/{epochs:2d} | Loss: {avg_loss:.5f} | Kinematic: {kinematic_loss_sum/len(dataset):.5f} | Equilibrium Residual: {equilibrium_loss_sum/len(dataset):.5f}")

    # Save PyTorch Checkpoint
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    weights_dir = os.path.join(repo_root, "backend", "app", "weights")
    os.makedirs(weights_dir, exist_ok=True)
    pt_path = os.path.join(weights_dir, "structura_net_3d.pt")
    torch.save(model.state_dict(), pt_path)
    print(f"\n[+] Saved PyTorch checkpoint: {pt_path}")

    # Export Pure JSON Weights for Dart Runtime
    dart_weights_dir = os.path.join(repo_root, "structura_nexus", "assets", "weights")
    os.makedirs(dart_weights_dir, exist_ok=True)
    json_path = os.path.join(dart_weights_dir, "structura_net_3d_weights.json")

    weights_dict = model.export_to_json_dict()
    weights_dict["training_history"] = history
    with open(json_path, "w") as f:
        json.dump(weights_dict, f)
    print(f"[+] Exported pure Dart JSON weights: {json_path}")
    print(f"[+] Total exported weight tensors: {len(weights_dict['layers'])}")


if __name__ == "__main__":
    train_structura_net()

