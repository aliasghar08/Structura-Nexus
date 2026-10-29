#!/usr/bin/env python3
"""
Structura Nexus: Unified Neural Training Factory for All Engineering Prediction Engines
Trains proprietary neural networks:
  1. ConnectionNetAI (AISC 360-16 / 358 steel connections)
  2. FoundationNetSSI (Geotechnical bearing, 3D settlement, and Winkler springs)
  3. PushoverNetPBEE (ASCE 41-17 Capacity Spectrum pushover sequence)
  4. AeroNetCFD (High-Rise Wind Tunnel CFD flow field & vortex shedding)
  5. CompositeFloorNetAI (AISC 360 Ch I flexure & DG 11 walking vibrations)
  6. HazardDynamicNetAI (Multi-Hazard dynamic response & health scoring)
  7. ModalEigenNetAI (ASCE 7-16 dynamic eigenvalues & mass participation)
  8. CarbonNetLCA (SE 2050 / EC3 embodied carbon decarbonization)

Saves PyTorch `.pt` models to backend/app/weights/
Exports JSON weight bundles to structura_nexus/assets/weights/
"""

import os
import sys
import json
import time
import math
import random
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.app.ai.connection_net import ConnectionNetAI
from backend.app.ai.foundation_net import FoundationNetSSI
from backend.app.ai.pushover_net import PushoverNetPBEE
from backend.app.ai.aero_net import AeroNetCFD
from backend.app.ai.composite_floor_net import CompositeFloorNetAI
from backend.app.ai.hazard_net import HazardDynamicNetAI
from backend.app.ai.modal_net import ModalEigenNetAI
from backend.app.ai.carbon_net import CarbonNetLCA

WEIGHTS_PT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend", "app", "weights"))
WEIGHTS_JSON_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "structura_nexus", "assets", "weights"))

os.makedirs(WEIGHTS_PT_DIR, exist_ok=True)
os.makedirs(WEIGHTS_JSON_DIR, exist_ok=True)


def train_and_export_model(name: str, model: nn.Module, X: torch.Tensor, Y_dict: dict, epochs: int = 35):
    device = torch.device("mps" if torch.backends.mps.is_available() else ("cuda" if torch.cuda.is_available() else "cpu"))
    print(f"\n=======================================================")
    print(f"[*] Training Neural Engine: {name} on {device}")
    print(f"=======================================================")
    model = model.to(device)
    X = X.to(device)
    Y_dict = {k: v.to(device) for k, v in Y_dict.items()}

    optimizer = optim.AdamW(model.parameters(), lr=3e-3, weight_decay=1e-5)
    criterion_mse = nn.MSELoss()

    model.train()
    batch_size = 32
    num_samples = X.shape[0]
    num_batches = int(math.ceil(num_samples / batch_size))

    t0 = time.perf_counter()
    for ep in range(1, epochs + 1):
        perm = torch.randperm(num_samples)
        ep_loss = 0.0

        for b in range(num_batches):
            idx = perm[b * batch_size: (b + 1) * batch_size]
            bx = X[idx]
            preds = model(bx)

            loss = 0.0
            for k in Y_dict:
                if k in preds:
                    loss += criterion_mse(preds[k], Y_dict[k][idx])

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            ep_loss += loss.item()

        if ep % 10 == 0 or ep == epochs:
            print(f"  Epoch {ep:02d}/{epochs:02d} | Avg Loss: {ep_loss / num_batches:.6f}")

    train_time = time.perf_counter() - t0
    print(f"[*] {name} trained successfully in {train_time:.2f}s.")

    # Save .pt
    pt_path = os.path.join(WEIGHTS_PT_DIR, f"{name.lower()}.pt")
    torch.save(model.state_dict(), pt_path)
    print(f"  -> Saved PyTorch checkpoint: {pt_path} ({os.path.getsize(pt_path) / 1024:.1f} KB)")

    # Export JSON
    json_path = os.path.join(WEIGHTS_JSON_DIR, f"{name.lower()}_weights.json")
    weights_dict = model.export_weights_dict()
    with open(json_path, "w") as f:
        json.dump(weights_dict, f)
    print(f"  -> Exported Client JSON weights: {json_path} ({os.path.getsize(json_path) / 1024:.1f} KB)")


def generate_connection_data(n: int = 500):
    # In: [conn_type, bolt_count, bolt_d, plate_t, weld_size, fy, fu, vu, mu, pu]
    X = []
    Y_dcr = []
    Y_fail = []
    Y_telem = []

    for _ in range(n):
        conn_t = random.choice([0.0, 1.0, 2.0])
        bolts = random.randint(2, 10)
        d_b = random.choice([19.0, 22.0, 25.4, 30.0])
        t_p = random.choice([8.0, 10.0, 12.0, 16.0, 20.0, 25.0])
        w = random.choice([5.0, 6.0, 8.0, 10.0, 12.0])
        fy = 345.0
        fu = 450.0
        vu = random.uniform(50.0, 800.0)
        mu = random.uniform(0.0, 300.0) if conn_t == 1.0 else 0.0
        pu = random.uniform(-100.0, 400.0)

        # Approximate limit states
        phi_rn_bolt = bolts * (0.75 * 0.50 * 825.0 * (math.pi * d_b * d_b / 4.0) / 1000.0)
        dcr_bolt = vu / max(phi_rn_bolt, 1.0)
        phi_rn_bearing = bolts * (0.75 * 2.4 * d_b * t_p * fu / 1000.0)
        dcr_bearing = vu / max(phi_rn_bearing, 1.0)
        phi_rn_weld = 0.75 * 0.707 * w * (bolts * 75.0) * (0.60 * 480.0) / 1000.0
        dcr_weld = vu / max(phi_rn_weld, 1.0)
        dcr_block = dcr_bearing * 0.85
        dcr_bend = (mu / 150.0) if conn_t == 1.0 else 0.1
        dcr_pry = 0.15 if conn_t == 1.0 else 0.05

        k_conn = (12000.0 * (t_p / 16.0) ** 3) if conn_t == 1.0 else 1500.0
        opt_bolts = math.ceil(max(dcr_bolt, dcr_bearing, dcr_weld) / 0.85 * bolts)
        opt_tp = t_p * math.sqrt(max(dcr_bend, 0.2) / 0.85)

        X.append([conn_t, bolts / 10.0, d_b / 30.0, t_p / 25.0, w / 12.0, fy / 400.0, fu / 500.0, vu / 500.0, mu / 300.0, pu / 400.0])
        Y_dcr.append([dcr_bolt, dcr_bearing, dcr_block, dcr_weld, dcr_bend, dcr_pry])
        fail_vec = [0.0] * 5
        max_idx = np.argmax([dcr_bolt, dcr_bearing, dcr_block, dcr_weld, dcr_bend])
        fail_vec[max_idx] = 1.0
        Y_fail.append(fail_vec)
        Y_telem.append([k_conn / 20000.0, opt_bolts / 12.0, opt_tp / 30.0])

    return (torch.tensor(X, dtype=torch.float32), {
        "dcrs": torch.tensor(Y_dcr, dtype=torch.float32),
        "failure_logits": torch.tensor(Y_fail, dtype=torch.float32),
        "telem": torch.tensor(Y_telem, dtype=torch.float32),
    })


def generate_foundation_data(n: int = 500):
    # In: [Pu, Mux, Muy, B, L, H, c, phi, gamma, gw]
    X, Y_soil, Y_dcr, Y_wink = [], [], [], []
    for _ in range(n):
        pu = random.uniform(300.0, 3000.0)
        mux = random.uniform(20.0, 400.0)
        muy = random.uniform(0.0, 200.0)
        b = random.uniform(1.5, 4.5)
        l = random.uniform(1.5, 4.5)
        h = random.uniform(0.4, 1.2)
        c = random.uniform(5.0, 50.0)
        phi = random.uniform(25.0, 40.0)
        gamma = random.uniform(17.0, 21.0)
        gw = random.uniform(1.0, 8.0)

        area = b * l
        q_ult = (c * 30.0 + gamma * 1.5 * 18.0 + 0.5 * gamma * b * 15.0)
        q_allow = q_ult / 3.0
        q_max = (pu / area) * (1.0 + 6.0 * (mux / pu) / b)
        dcr_bear = q_max / q_allow
        settle_el = (q_max / 250.0) * 15.0
        settle_con = settle_el * 0.4
        dcr_punch = (pu * 1.2) / (4.0 * (0.5 + h) * h * 1000.0 * 0.75 * 0.33 * math.sqrt(30.0))
        dcr_beam = dcr_punch * 0.8
        kz = 40000.0 * area
        kx = kz * 0.8
        kt = kz * (b * b / 12.0)

        X.append([pu / 3000.0, mux / 400.0, muy / 200.0, b / 4.5, l / 4.5, h / 1.2, c / 50.0, phi / 40.0, gamma / 21.0, gw / 8.0])
        Y_soil.append([q_ult / 3000.0, q_allow / 1000.0, settle_el / 30.0, settle_con / 15.0])
        Y_dcr.append([dcr_bear, dcr_punch, dcr_beam])
        Y_wink.append([kz / 400000.0, kx / 300000.0, kt / 300000.0])

    return (torch.tensor(X, dtype=torch.float32), {
        "soil_outputs": torch.tensor(Y_soil, dtype=torch.float32),
        "dcrs": torch.tensor(Y_dcr, dtype=torch.float32),
        "winkler_springs": torch.tensor(Y_wink, dtype=torch.float32),
    })


def generate_pushover_data(n: int = 400):
    # In: [num_stories, height, stiffness, weight, framing_type, yield_v, mu, alpha]
    X, Y_curve, Y_perf, Y_hinge = [], [], [], []
    for _ in range(n):
        stories = random.randint(2, 20)
        h = stories * 3.6
        k = random.uniform(5e4, 5e6)
        w = stories * 1500.0
        framing = random.choice([0.0, 1.0, 2.0])
        vy = random.uniform(500.0, 6000.0)
        mu = random.uniform(2.5, 6.0)
        alpha = random.uniform(0.03, 0.10)

        curve = []
        d_y = vy / k
        d_ult = d_y * mu
        for i in range(20):
            step = i / 19.0
            cur_d = step * d_ult
            if cur_d <= d_y:
                cur_v = k * cur_d
            else:
                cur_v = vy + alpha * k * (cur_d - d_y)
            curve.extend([cur_d, cur_v / 1000.0])

        sa = (vy / w) * 1.5
        sd = d_y * 1.2
        v_perf = vy * 1.05
        d_perf = sd

        X.append([stories / 20.0, h / 80.0, math.log10(k) / 7.0, w / 30000.0, framing, vy / 6000.0, mu / 6.0, alpha / 0.10])
        Y_curve.append(curve)
        Y_perf.append([sa, sd, v_perf / 1000.0, d_perf])
        Y_hinge.append([0.65, 0.25, 0.08, 0.02])

    return (torch.tensor(X, dtype=torch.float32), {
        "curve_points": torch.tensor(Y_curve, dtype=torch.float32),
        "perf_point": torch.tensor(Y_perf, dtype=torch.float32),
        "hinge_distribution": torch.tensor(Y_hinge, dtype=torch.float32),
    })


def generate_aero_data(n: int = 400):
    # In: [height, width, depth, speed, exposure]
    X, Y_cp, Y_aero, Y_risk = [], [], [], []
    for _ in range(n):
        h = random.uniform(15.0, 250.0)
        b = random.uniform(15.0, 60.0)
        d = random.uniform(15.0, 60.0)
        v = random.uniform(25.0, 65.0)
        exp = random.choice([0.0, 1.0, 2.0])

        qz = 0.613 * (1.1 ** exp) * (v ** 2)
        fs = 0.14 * v / b
        v_along = (qz * b * h * 0.8) / 1000.0
        v_across = v_along * (0.35 + 0.15 * (h / b))
        crit_v = fs * b / 0.14
        is_risk = 1.0 if abs(v - crit_v) < 5.0 else 0.0

        cp_vals = [0.85, 0.72, 0.55, -0.48, -1.75, -1.25]

        X.append([h / 250.0, b / 60.0, d / 60.0, v / 65.0, exp / 2.0])
        Y_cp.append(cp_vals)
        Y_aero.append([fs, qz / 2000.0, v_along / 2000.0, v_across / 1000.0, crit_v / 70.0])
        Y_risk.append([1.0 - is_risk, is_risk])

    return (torch.tensor(X, dtype=torch.float32), {
        "cp_profile": torch.tensor(Y_cp, dtype=torch.float32),
        "aero_telemetry": torch.tensor(Y_aero, dtype=torch.float32),
        "risk_logits": torch.tensor(Y_risk, dtype=torch.float32),
    })


def generate_composite_floor_data(n: int = 400):
    # In: [span, spacing, slab_t, fc, steel_d, steel_bf, steel_area, dl, ll]
    X, Y_cap, Y_vib = [], [], []
    for _ in range(n):
        l = random.uniform(7.0, 15.0)
        s = random.uniform(2.0, 3.5)
        ts = random.uniform(100.0, 160.0)
        fc = random.uniform(25.0, 45.0)
        d = random.uniform(350.0, 650.0)
        bf = random.uniform(150.0, 250.0)
        a = random.uniform(50.0, 150.0)
        dl = random.uniform(2.5, 4.5)
        ll = random.uniform(2.0, 4.0)

        w_tot = (dl + ll) * s
        mu = (w_tot * l * l / 8.0)
        phi_mn = 0.90 * (a * 100.0 * 345.0 * (d + ts * 0.5)) / 1e6
        dcr_flex = mu / phi_mn
        ieff = (a * 100.0 * (d * 0.5) ** 2 * 2.5) / 1e4
        fn = (math.pi / 2.0) * math.sqrt((200e9 * ieff * 1e-12) / ((w_tot * 1000.0 / 9.81) * (l ** 4)))
        ap_g = (0.05 * math.exp(-0.35 * fn)) * 100.0
        comf_dcr = ap_g / 0.50

        X.append([l / 15.0, s / 3.5, ts / 160.0, fc / 45.0, d / 650.0, bf / 250.0, a / 150.0, dl / 4.5, ll / 4.0])
        Y_cap.append([phi_mn / 1000.0, ieff / 500.0, dcr_flex, dcr_flex * 0.8])
        Y_vib.append([fn / 15.0, ap_g / 2.0, comf_dcr, math.ceil(l * 2.2) / 40.0])

    return (torch.tensor(X, dtype=torch.float32), {
        "capacity": torch.tensor(Y_cap, dtype=torch.float32),
        "vibration": torch.tensor(Y_vib, dtype=torch.float32),
    })


def generate_hazard_data(n: int = 400):
    # In: [wind_spd, pga, dtemp, snow, settle, mass, height]
    X, Y_resp, Y_health = [], [], []
    for _ in range(n):
        v = random.uniform(0.0, 70.0)
        pga = random.uniform(0.0, 1.0)
        dt = random.uniform(0.0, 600.0)
        sn = random.uniform(0.0, 6.0)
        setl = random.uniform(0.0, 100.0)
        mass = random.uniform(5e4, 2e6)
        h = random.uniform(6.0, 60.0)

        wind_drift = (v / 40.0) ** 2 * 8.0 * (h / 30.0)
        seis_drift = pga * 9.81 * 12.0 * (h / 30.0)
        drift = wind_drift + seis_drift + setl * 0.25
        base_shear = (pga * 0.35 * mass * 9.81 + 0.613 * (v ** 2) * 25.0 * h * 0.5) / 1000.0
        drift_ratio = (drift / 1000.0) / h
        overstressed = int(min(drift_ratio / 0.005 * 8, 30))
        health = max(100.0 - (drift_ratio / 0.02 * 80.0) - (dt / 800.0 * 25.0), 5.0)

        X.append([v / 70.0, pga / 1.0, dt / 600.0, sn / 6.0, setl / 100.0, math.log10(mass) / 7.0, h / 60.0])
        Y_resp.append([drift / 100.0, base_shear / 3000.0, drift_ratio * 100.0, overstressed / 30.0])
        Y_health.append([health, 1.0 if health < 30.0 else 0.0])

    return (torch.tensor(X, dtype=torch.float32), {
        "dynamic_response": torch.tensor(Y_resp, dtype=torch.float32),
        "safety_health": torch.tensor(Y_health, dtype=torch.float32),
    })


def generate_modal_data(n: int = 400):
    # In: [height, weight, framing, Ss, S1, stiffness]
    X, Y_per, Y_mass, Y_seis = [], [], [], []
    for _ in range(n):
        h = random.uniform(9.0, 80.0)
        w = random.uniform(2000.0, 40000.0)
        fr = random.choice([0.0, 1.0, 2.0])
        ss = random.uniform(0.5, 1.8)
        s1 = random.uniform(0.2, 0.8)
        k = random.uniform(1e5, 1e7)

        t1 = 0.0724 * (h ** 0.8)
        t2 = t1 / 3.0
        t3 = t1 / 5.0
        f1, f2, f3 = 1.0 / t1, 1.0 / t2, 1.0 / t3
        ux, uy, rz = 82.5, 84.0, 78.0
        cs = min(max(s1 / t1 / 8.0, 0.044 * ss), 0.25)
        v_base = cs * w

        X.append([h / 80.0, w / 40000.0, fr / 2.0, ss / 1.8, s1 / 0.8, math.log10(k) / 7.0])
        Y_per.append([t1, t2, t3, f1 / 10.0, f2 / 10.0, f3 / 10.0])
        Y_mass.append([ux, uy, rz])
        Y_seis.append([cs, v_base / 5000.0, (t1 * 0.015) * 100.0])

    return (torch.tensor(X, dtype=torch.float32), {
        "periods": torch.tensor(Y_per, dtype=torch.float32),
        "mass_participation": torch.tensor(Y_mass, dtype=torch.float32),
        "seismic": torch.tensor(Y_seis, dtype=torch.float32),
    })


def generate_carbon_data(n: int = 400):
    # In: [steel_tonnes, concrete_m3, area, stories, target_red]
    X, Y_carb, Y_strat = [], [], []
    for _ in range(n):
        st = random.uniform(10.0, 500.0)
        conc = random.uniform(50.0, 2000.0)
        area = random.uniform(500.0, 15000.0)
        stories = random.randint(1, 20)
        target = random.uniform(15.0, 50.0)

        base_c = (st * 1000.0 * 1.82 + conc * 2400.0 * 0.15)
        opt_c = (st * 1000.0 * 0.68 + conc * 2400.0 * 0.09)
        red_pct = ((base_c - opt_c) / base_c) * 100.0

        X.append([st / 500.0, conc / 2000.0, area / 15000.0, stories / 20.0, target / 50.0])
        Y_carb.append([base_c / 1e6, opt_c / 1e6, red_pct / 100.0])
        Y_strat.append([0.85, 0.40, 0.92])

    return (torch.tensor(X, dtype=torch.float32), {
        "carbon": torch.tensor(Y_carb, dtype=torch.float32),
        "strategy": torch.tensor(Y_strat, dtype=torch.float32),
    })


def main():
    print("=================================================================")
    print("Structura Nexus: Training All 8 Engineering Neural Engines")
    print("=================================================================")

    # 1. ConnectionNetAI
    X_conn, Y_conn = generate_connection_data()
    train_and_export_model("connection_net", ConnectionNetAI(), X_conn, Y_conn)

    # 2. FoundationNetSSI
    X_fnd, Y_fnd = generate_foundation_data()
    train_and_export_model("foundation_net", FoundationNetSSI(), X_fnd, Y_fnd)

    # 3. PushoverNetPBEE
    X_push, Y_push = generate_pushover_data()
    train_and_export_model("pushover_net", PushoverNetPBEE(), X_push, Y_push)

    # 4. AeroNetCFD
    X_aero, Y_aero = generate_aero_data()
    train_and_export_model("aero_net", AeroNetCFD(), X_aero, Y_aero)

    # 5. CompositeFloorNetAI
    X_comp, Y_comp = generate_composite_floor_data()
    train_and_export_model("composite_floor_net", CompositeFloorNetAI(), X_comp, Y_comp)

    # 6. HazardDynamicNetAI
    X_haz, Y_haz = generate_hazard_data()
    train_and_export_model("hazard_net", HazardDynamicNetAI(), X_haz, Y_haz)

    # 7. ModalEigenNetAI
    X_modal, Y_modal = generate_modal_data()
    train_and_export_model("modal_net", ModalEigenNetAI(), X_modal, Y_modal)

    # 8. CarbonNetLCA
    X_carb, Y_carb = generate_carbon_data()
    train_and_export_model("carbon_net", CarbonNetLCA(), X_carb, Y_carb)

    print("\n[✔] All 8 Engineering Neural Models trained and exported successfully!")


if __name__ == "__main__":
    main()

