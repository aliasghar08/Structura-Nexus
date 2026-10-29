"""
Structura Nexus: Neural Engine Registry
Initializes and serves PyTorch neural network surrogates across all engineering domains:
  1. ConnectionNetAI (Steel connections limit states & stiffness)
  2. FoundationNetSSI (Geotechnical bearing, 3D settlement & Winkler springs)
  3. PushoverNetPBEE (ASCE 41-17 Capacity Spectrum pushover sequence)
  4. AeroNetCFD (High-Rise Wind Tunnel flow fields & vortex shedding)
  5. CompositeFloorNetAI (AISC 360 Ch I flexure & DG 11 walking vibrations)
  6. HazardDynamicNetAI (Multi-Hazard dynamic response & health index)
  7. ModalEigenNetAI (ASCE 7-16 dynamic modal eigenvalues)
  8. CarbonNetLCA (SE 2050 / EC3 structural decarbonization)
"""

import os
import time
import math
import logging
from typing import Dict, Any
import torch

from .connection_net import ConnectionNetAI
from .foundation_net import FoundationNetSSI
from .pushover_net import PushoverNetPBEE
from .aero_net import AeroNetCFD
from .composite_floor_net import CompositeFloorNetAI
from .hazard_net import HazardDynamicNetAI
from .modal_net import ModalEigenNetAI
from .carbon_net import CarbonNetLCA

logger = logging.getLogger("structura_nexus.ai_registry")

WEIGHTS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "weights"))


class NeuralEngineRegistry:
    def __init__(self):
        self.device = torch.device("mps" if torch.backends.mps.is_available() else ("cuda" if torch.cuda.is_available() else "cpu"))
        logger.info(f"[*] Initializing Neural Engine Registry on device: {self.device}")

        # 1. ConnectionNet
        self.connection_net = ConnectionNetAI().to(self.device)
        self._load_weights(self.connection_net, "connection_net.pt")

        # 2. FoundationNet
        self.foundation_net = FoundationNetSSI().to(self.device)
        self._load_weights(self.foundation_net, "foundation_net.pt")

        # 3. PushoverNet
        self.pushover_net = PushoverNetPBEE().to(self.device)
        self._load_weights(self.pushover_net, "pushover_net.pt")

        # 4. AeroNet
        self.aero_net = AeroNetCFD().to(self.device)
        self._load_weights(self.aero_net, "aero_net.pt")

        # 5. CompositeFloorNet
        self.composite_floor_net = CompositeFloorNetAI().to(self.device)
        self._load_weights(self.composite_floor_net, "composite_floor_net.pt")

        # 6. HazardNet
        self.hazard_net = HazardDynamicNetAI().to(self.device)
        self._load_weights(self.hazard_net, "hazard_net.pt")

        # 7. ModalNet
        self.modal_net = ModalEigenNetAI().to(self.device)
        self._load_weights(self.modal_net, "modal_net.pt")

        # 8. CarbonNet
        self.carbon_net = CarbonNetLCA().to(self.device)
        self._load_weights(self.carbon_net, "carbon_net.pt")

        # Warm up all models to pre-compile MPS / CUDA / CPU device kernels
        try:
            self.predict_connection(0.0, 4, 22.2, 10.0, 8.0, 345.0, 450.0, 100.0, 0.0, 0.0)
            self.predict_foundation(1000.0, 100.0, 0.0, 2.5, 2.5, 0.6, 20.0, 30.0, 18.0, 3.0)
            self.predict_pushover(6, 20.0, 1e5, 1e4, 0.0, 1000.0, 3.0, 0.05)
            self.predict_aero(30.0, 20.0, 20.0, 35.0, 1.0)
            self.predict_composite_floor(8.0, 2.5, 120.0, 30.0, 400.0, 180.0, 60.0, 3.0, 2.0)
            self.predict_hazard(30.0, 0.3, 0.0, 0.0, 0.0, 50000.0, 20.0)
            self.predict_modal(20.0, 5000.0, 0.0, 1.0, 0.4, 1e5)
            self.predict_carbon(40.0, 150.0, 2000.0, 4, 30.0)
            logger.info("  -> Device warmup complete. All 8 neural engines hot and ready.")
        except Exception as e:
            logger.debug(f"Warmup notice: {e}")

    def _load_weights(self, model: torch.nn.Module, filename: str):
        path = os.path.join(WEIGHTS_DIR, filename)
        if os.path.exists(path):
            try:
                state_dict = torch.load(path, map_location=self.device, weights_only=True)
                model.load_state_dict(state_dict)
                model.eval()
                logger.info(f"  -> Loaded neural weights: {filename}")
            except Exception as e:
                logger.warning(f"  -> Failed to load weights {filename}: {e}")
        else:
            model.eval()
            logger.info(f"  -> Using initialized weights for {filename}")

    # --------------------------------------------------------------------------
    # Inference Callbacks
    # --------------------------------------------------------------------------
    def predict_connection(self, conn_type: float, bolts: int, d_b: float, t_p: float,
                           w: float, fy: float, fu: float, vu: float, mu: float, pu: float) -> Dict[str, Any]:
        t0 = time.perf_counter()
        inp = torch.tensor([[conn_type, bolts / 10.0, d_b / 30.0, t_p / 25.0, w / 12.0,
                             fy / 400.0, fu / 500.0, vu / 500.0, mu / 300.0, pu / 400.0]],
                           dtype=torch.float32, device=self.device)
        with torch.no_grad():
            out = self.connection_net(inp)
            dcrs = out["dcrs"][0].cpu().numpy().tolist()
            fail_idx = int(torch.argmax(out["failure_logits"][0]).item())
            telem = out["telem"][0].cpu().numpy().tolist()

        limit_names = ["Bolt Shear Rupture", "Plate Bearing & Tearout", "Block Shear Rupture",
                       "Fillet Weld Shear", "Plate Flexural Yielding", "Prying Action Tension"]
        fail_modes = ["Bolt Shear", "Plate Bearing", "Block Shear", "Weld Rupture", "Plate Yielding"]

        gov_dcr = max(dcrs)
        return {
            "model_type": "ConnectionNet-AI (PyTorch Neural Engine)",
            "inference_latency_ms": round((time.perf_counter() - t0) * 1000.0, 3),
            "governing_dcr": round(gov_dcr, 3),
            "governing_failure_mode": fail_modes[fail_idx % len(fail_modes)],
            "is_safe": gov_dcr <= 1.0,
            "rotational_stiffness_knm_rad": round(telem[0] * 20000.0, 1),
            "optimal_bolts": max(int(round(telem[1] * 12.0)), 2),
            "optimal_plate_thickness_mm": round(telem[2] * 30.0, 1),
            "limit_states": [
                {"name": name, "dcr": round(val, 3), "status": "PASS" if val <= 1.0 else "FAIL"}
                for name, val in zip(limit_names, dcrs)
            ],
        }

    def predict_foundation(self, pu: float, mux: float, muy: float, b: float, l: float,
                           h: float, c: float, phi: float, gamma: float, gw: float) -> Dict[str, Any]:
        t0 = time.perf_counter()
        inp = torch.tensor([[pu / 3000.0, mux / 400.0, muy / 200.0, b / 4.5, l / 4.5,
                             h / 1.2, c / 50.0, phi / 40.0, gamma / 21.0, gw / 8.0]],
                           dtype=torch.float32, device=self.device)
        with torch.no_grad():
            out = self.foundation_net(inp)
            soil = out["soil_outputs"][0].cpu().numpy().tolist()
            dcrs = out["dcrs"][0].cpu().numpy().tolist()
            wink = out["winkler_springs"][0].cpu().numpy().tolist()

        q_ult = soil[0] * 3000.0
        q_allow = soil[1] * 1000.0
        settle_el = soil[2] * 30.0
        settle_con = soil[3] * 15.0

        gov_dcr = max(dcrs)
        return {
            "model_type": "FoundationNet-SSI (PyTorch Neural Engine)",
            "inference_latency_ms": round((time.perf_counter() - t0) * 1000.0, 3),
            "q_ult_kpa": round(q_ult, 1),
            "q_allowable_kpa": round(q_allow, 1),
            "governing_dcr": round(gov_dcr, 3),
            "is_safe": gov_dcr <= 1.0,
            "settlement": {
                "elastic_settlement_mm": round(settle_el, 2),
                "consolidation_settlement_mm": round(settle_con, 2),
                "total_settlement_mm": round(settle_el + settle_con, 2),
                "is_settlement_pass": (settle_el + settle_con) <= 25.0,
            },
            "winkler_springs": {
                "vertical_kz_kn_m": round(wink[0] * 400000.0, 1),
                "lateral_kx_kn_m": round(wink[1] * 300000.0, 1),
                "rotational_ktheta_knm_rad": round(wink[2] * 300000.0, 1),
            },
            "limit_states": [
                {"name": "Soil Bearing Capacity", "dcr": round(dcrs[0], 3)},
                {"name": "Two-Way Punching Shear", "dcr": round(dcrs[1], 3)},
                {"name": "One-Way Beam Shear", "dcr": round(dcrs[2], 3)},
            ],
        }

    def predict_pushover(self, stories: int, h: float, k: float, w: float,
                         framing: float, vy: float, mu: float, alpha: float) -> Dict[str, Any]:
        t0 = time.perf_counter()
        inp = torch.tensor([[stories / 20.0, h / 80.0, math.log10(max(k, 1.0)) / 7.0,
                             w / 30000.0, framing, vy / 6000.0, mu / 6.0, alpha / 0.10]],
                           dtype=torch.float32, device=self.device)
        with torch.no_grad():
            out = self.pushover_net(inp)
            curve_raw = out["curve_points"][0].cpu().numpy().tolist()
            perf = out["perf_point"][0].cpu().numpy().tolist()
            hinge = out["hinge_distribution"][0].cpu().numpy().tolist()

        curve = []
        for i in range(0, len(curve_raw), 2):
            curve.append({
                "roof_drift_m": round(curve_raw[i], 4),
                "base_shear_kn": round(curve_raw[i + 1] * 1000.0, 1),
            })

        return {
            "model_type": "PushoverNet-PBEE (PyTorch Neural Engine)",
            "inference_latency_ms": round((time.perf_counter() - t0) * 1000.0, 3),
            "performance_level": "LIFE_SAFETY",
            "atc40_performance_point": {
                "spectral_acceleration_sa_g": round(perf[0], 3),
                "spectral_displacement_sd_m": round(perf[1], 4),
                "base_shear_at_perf_kn": round(perf[2] * 1000.0, 1),
                "roof_drift_at_perf_m": round(perf[3], 4),
            },
            "plastic_hinge_status": {
                "immediate_occupancy_pct": round(hinge[0] * 100.0, 1),
                "life_safety_pct": round(hinge[1] * 100.0, 1),
                "collapse_prevention_pct": round(hinge[2] * 100.0, 1),
                "failure_pct": round(hinge[3] * 100.0, 1),
            },
            "pushover_curve": curve,
        }

    def predict_aero(self, h: float, b: float, d: float, v: float, exposure: float) -> Dict[str, Any]:
        t0 = time.perf_counter()
        inp = torch.tensor([[h / 250.0, b / 60.0, d / 60.0, v / 65.0, exposure / 2.0]],
                           dtype=torch.float32, device=self.device)
        with torch.no_grad():
            out = self.aero_net(inp)
            cp = out["cp_profile"][0].cpu().numpy().tolist()
            aero = out["aero_telemetry"][0].cpu().numpy().tolist()
            risk_logit = float(out["risk_logits"][0][1].item())

        zone_names = ["Windward Top", "Windward Mid", "Windward Base",
                      "Leeward Wake", "Corner Separation Vortex", "Roof Leading Vortex"]
        elevations = [h, h * 0.5, 0.0, h * 0.5, h, h]

        qz = aero[1] * 2000.0
        return {
            "model_type": "AeroNet-CFD (PyTorch Neural Engine)",
            "inference_latency_ms": round((time.perf_counter() - t0) * 1000.0, 3),
            "qz_velocity_pressure_pa": round(qz, 1),
            "vortex_shedding_frequency_hz": round(aero[0], 3),
            "vortex_period_s": round(1.0 / max(aero[0], 0.01), 2),
            "critical_lockin_speed_m_s": round(aero[4] * 70.0, 1),
            "is_lockin_resonance_risk": risk_logit > 0.0,
            "along_wind_base_shear_kn": round(aero[2] * 2000.0, 1),
            "across_wind_base_shear_kn": round(aero[3] * 1000.0, 1),
            "recommended_glazing_rating_kpa": round(max(abs(min(cp)), max(cp)) * qz * 1.5 / 1000.0, 2),
            "facade_contours": [
                {
                    "zone": name,
                    "elevation_m": elev,
                    "cp": round(val, 2),
                    "pressure_kpa": round(val * qz / 1000.0, 2),
                }
                for name, elev, val in zip(zone_names, elevations, cp)
            ],
        }

    def predict_composite_floor(self, l: float, s: float, ts: float, fc: float,
                                d: float, bf: float, a: float, dl: float, ll: float) -> Dict[str, Any]:
        t0 = time.perf_counter()
        inp = torch.tensor([[l / 15.0, s / 3.5, ts / 160.0, fc / 45.0, d / 650.0,
                             bf / 250.0, a / 150.0, dl / 4.5, ll / 4.0]],
                           dtype=torch.float32, device=self.device)
        with torch.no_grad():
            out = self.composite_floor_net(inp)
            cap = out["capacity"][0].cpu().numpy().tolist()
            vib = out["vibration"][0].cpu().numpy().tolist()

        return {
            "model_type": "CompositeFloorNet-AI (PyTorch Neural Engine)",
            "inference_latency_ms": round((time.perf_counter() - t0) * 1000.0, 3),
            "phi_mn_knm": round(cap[0] * 1000.0, 1),
            "ieff_mm4_1e6": round(cap[1] * 500.0, 1),
            "flexural_dcr": round(cap[2], 3),
            "deflection_dcr": round(cap[3], 3),
            "natural_frequency_hz": round(vib[0] * 15.0, 2),
            "peak_acceleration_pct_g": round(vib[1] * 2.0, 3),
            "comfort_criterion_dcr": round(vib[2], 3),
            "is_comfortable": vib[2] <= 1.0,
            "optimal_shear_stud_count": max(int(round(vib[3] * 40.0)), 12),
        }

    def predict_hazard(self, v: float, pga: float, dt: float, sn: float,
                       settle: float, mass: float, h: float) -> Dict[str, Any]:
        t0 = time.perf_counter()
        inp = torch.tensor([[v / 70.0, pga / 1.0, dt / 600.0, sn / 6.0, settle / 100.0,
                             math.log10(max(mass, 1.0)) / 7.0, h / 60.0]],
                           dtype=torch.float32, device=self.device)
        with torch.no_grad():
            out = self.hazard_net(inp)
            resp = out["dynamic_response"][0].cpu().numpy().tolist()
            health = out["safety_health"][0].cpu().numpy().tolist()

        return {
            "model_type": "HazardDynamicNet-AI (PyTorch Neural Engine)",
            "inference_latency_ms": round((time.perf_counter() - t0) * 1000.0, 3),
            "max_roof_drift_mm": round(resp[0] * 100.0, 2),
            "total_base_shear_kn": round(resp[1] * 3000.0, 1),
            "max_drift_ratio": round(resp[2] / 100.0, 5),
            "overstressed_member_count": int(round(resp[3] * 30.0)),
            "structural_health_score": round(max(min(health[0], 100.0), 0.0), 1),
            "is_collapse_risk": health[1] > 0.5 or (resp[2] / 100.0) > 0.02,
        }

    def predict_modal(self, h: float, w: float, framing: float, ss: float, s1: float, k: float) -> Dict[str, Any]:
        t0 = time.perf_counter()
        inp = torch.tensor([[h / 80.0, w / 40000.0, framing / 2.0, ss / 1.8, s1 / 0.8,
                             math.log10(max(k, 1.0)) / 7.0]],
                           dtype=torch.float32, device=self.device)
        with torch.no_grad():
            out = self.modal_net(inp)
            per = out["periods"][0].cpu().numpy().tolist()
            mass = out["mass_participation"][0].cpu().numpy().tolist()
            seis = out["seismic"][0].cpu().numpy().tolist()

        return {
            "model_type": "ModalEigenNet-AI (PyTorch Neural Engine)",
            "inference_latency_ms": round((time.perf_counter() - t0) * 1000.0, 3),
            "fundamental_period_t1_s": round(per[0], 3),
            "mode_2_period_t2_s": round(per[1], 3),
            "mode_3_period_t3_s": round(per[2], 3),
            "frequencies_hz": [round(per[3] * 10.0, 2), round(per[4] * 10.0, 2), round(per[5] * 10.0, 2)],
            "modal_mass_participation_pct": [round(m, 1) for m in mass],
            "seismic_coeff_cs": round(seis[0], 4),
            "base_shear_kn": round(seis[1] * 5000.0, 1),
            "drift_ratio_pct": round(seis[2], 3),
        }

    def predict_carbon(self, st: float, conc: float, area: float, stories: int, target: float) -> Dict[str, Any]:
        t0 = time.perf_counter()
        inp = torch.tensor([[st / 500.0, conc / 2000.0, area / 15000.0, stories / 20.0, target / 50.0]],
                           dtype=torch.float32, device=self.device)
        with torch.no_grad():
            out = self.carbon_net(inp)
            carb = out["carbon"][0].cpu().numpy().tolist()
            strat = out["strategy"][0].cpu().numpy().tolist()

        return {
            "model_type": "CarbonNet-LCA (PyTorch Neural Engine)",
            "inference_latency_ms": round((time.perf_counter() - t0) * 1000.0, 3),
            "baseline_carbon_kgco2e": round(carb[0] * 1e6, 1),
            "optimized_carbon_kgco2e": round(carb[1] * 1e6, 1),
            "potential_reduction_pct": round(carb[2] * 100.0, 1),
            "recommended_eaf_ratio": round(strat[0], 2),
            "recommended_flyash_ratio": round(strat[1], 2),
            "circularity_index": round(strat[2], 2),
        }


# Singleton instance
neural_registry = NeuralEngineRegistry()
