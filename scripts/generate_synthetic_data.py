#!/usr/bin/env python3
"""
Synthetic Structural Topology Generator
Generates parametric stochastic 3D space frames, trusses, and grillage systems
with exact FEA ground truth labels for Edge-GNN surrogate model training.
"""
import os
import sys
import json
import random
from typing import List, Dict, Any

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.app.models.schema import StructuralGraphPayload, NodeModel, MemberModel
from backend.app.solvers.fea_engine import FEA3DSpaceFrameSolver
from backend.app.code_check.aisc_aci import AISC_W_SHAPES

def generate_multi_story_frame(
    bays_x: int = 2,
    bays_z: int = 1,
    stories: int = 2,
    bay_width: float = 6.0,
    story_height: float = 3.5,
) -> StructuralGraphPayload:
    nodes = []
    members = []
    node_id_grid = {}

    # Create nodes grid
    for s in range(stories + 1):
        y = s * story_height
        for bx in range(bays_x + 1):
            x = bx * bay_width
            for bz in range(bays_z + 1):
                z = bz * bay_width
                nid = f"N_S{s}_X{bx}_Z{bz}"
                node_id_grid[(s, bx, bz)] = nid

                # Ground nodes are fixed supports
                if s == 0:
                    restraints = [1, 1, 1, 1, 1, 1]
                    loads = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
                else:
                    restraints = [0, 0, 0, 0, 0, 0]
                    # Apply stochastic gravity load and lateral wind load
                    fx = random.uniform(5000.0, 25000.0) if bx == 0 else 0.0
                    fy = -random.uniform(20000.0, 80000.0)
                    loads = [fx, fy, 0.0, 0.0, 0.0, 0.0]

                nodes.append(NodeModel(id=nid, coords=[x, y, z], restraint=restraints, loads=loads))

    # Create columns (vertical members)
    member_idx = 1
    section_keys = list(AISC_W_SHAPES.keys())

    for s in range(stories):
        for bx in range(bays_x + 1):
            for bz in range(bays_z + 1):
                i_node = node_id_grid[(s, bx, bz)]
                j_node = node_id_grid[(s + 1, bx, bz)]
                sec = "W14X68" if s == 0 else "W14X48"
                members.append(MemberModel(
                    id=f"COL_{member_idx}",
                    i_node=i_node,
                    j_node=j_node,
                    section=sec,
                    material="A992_STEEL"
                ))
                member_idx += 1

    # Create floor beams in X and Z directions
    for s in range(1, stories + 1):
        # X-direction beams
        for bz in range(bays_z + 1):
            for bx in range(bays_x):
                i_node = node_id_grid[(s, bx, bz)]
                j_node = node_id_grid[(s, bx + 1, bz)]
                members.append(MemberModel(
                    id=f"BEAM_X_{member_idx}",
                    i_node=i_node,
                    j_node=j_node,
                    section="W14X30",
                    material="A992_STEEL"
                ))
                member_idx += 1

        # Z-direction beams
        for bx in range(bays_x + 1):
            for bz in range(bays_z):
                i_node = node_id_grid[(s, bx, bz)]
                j_node = node_id_grid[(s, bx, bz + 1)]
                members.append(MemberModel(
                    id=f"BEAM_Z_{member_idx}",
                    i_node=i_node,
                    j_node=j_node,
                    section="W12X26",
                    material="A992_STEEL"
                ))
                member_idx += 1

    return StructuralGraphPayload(
        session_id=f"synthetic_frame_{stories}story_{bays_x}x{bays_z}",
        action="INFER_AND_VERIFY",
        load_combination="1.2D+1.6L",
        nodes=nodes,
        members=members,
    )

def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "data", "synthetic_dataset")
    os.makedirs(out_dir, exist_ok=True)

    print("Generating sample synthetic multi-story frame topologies...")
    sample_payload = generate_multi_story_frame(bays_x=2, bays_z=1, stories=2)
    print(f"Generated frame with {len(sample_payload.nodes)} nodes and {len(sample_payload.members)} members.")

    print("Solving exact ground truth FEA...")
    solution = FEA3DSpaceFrameSolver.solve(sample_payload)
    print(f"Solved in {solution.inference_latency_ms} ms. Base shear: {solution.global_base_shear_n} N.")
    print(f"Compliance summary: {solution.code_compliance_summary}")

    out_file = os.path.join(out_dir, "sample_training_frame.json")
    with open(out_file, "w") as f:
        json.dump({
            "graph": sample_payload.model_dump(),
            "ground_truth": solution.model_dump(),
        }, f, indent=2)

    print(f"Saved verified dataset pair to: {out_file}")

if __name__ == "__main__":
    main()
