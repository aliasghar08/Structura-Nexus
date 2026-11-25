#!/usr/bin/env python3
"""
Structura Nexus — Step-by-Step 3D Building Construction & Live AI Guidance Showcase
Records building a structure from the ground up: placing joints, drawing members, extruding bays/stories,
dragging joints at 60 FPS, and AI Copilot & Swarm optimization.
Saves to BOTH:
1. /Users/aliasghar08/Desktop/Structura_Nexus_Build_And_AI_Guide.mp4
2. /Users/aliasghar08/Library/Mobile Documents/com~apple~CloudDocs/Mac Screenshots/Structura_Nexus_Build_And_AI_Guide.mp4
"""

import os
import sys
import time
import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BUILD_WEB = REPO_ROOT / "structura_nexus" / "build" / "web"

DESKTOP_DIR = Path("/Users/aliasghar08/Desktop")
ICLOUD_DIR = Path("/Users/aliasghar08/Library/Mobile Documents/com~apple~CloudDocs/Mac Screenshots")

OUT_DESKTOP = DESKTOP_DIR / "Structura_Nexus_Build_And_AI_Guide.mp4"
OUT_ICLOUD = ICLOUD_DIR / "Structura_Nexus_Build_And_AI_Guide.mp4"
OUT_FASTHOOK_DESKTOP = DESKTOP_DIR / "Structura_Nexus_Build_And_AI_Guide_FastHook.mp4"
OUT_FASTHOOK_ICLOUD = ICLOUD_DIR / "Structura_Nexus_Build_And_AI_Guide_FastHook.mp4"

TEMP_VIDEO_DIR = Path("/tmp/structura_build_guide_raw_vid")
PORT = 5059


def ensure_server():
    """Start local web server serving flutter web build if not running."""
    print(f"Ensuring local HTTP server on port {PORT} serving {BUILD_WEB}...")
    try:
        subprocess.run(["pkill", "-f", f"http.server {PORT}"], stderr=subprocess.DEVNULL)
        time.sleep(0.5)
    except Exception:
        pass

    proc = subprocess.Popen(
        [sys.executable, "-m", "http.server", str(PORT), "--directory", str(BUILD_WEB)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    time.sleep(1.2)
    return proc


def inject_guide_ui(page):
    """Injects bottom-center narration pill and end card."""
    page.evaluate("""
        (() => {
            const existing = document.getElementById('guide-step-overlay');
            if (existing) existing.remove();

            const style = document.createElement('style');
            style.id = 'guide-overlay-styles';
            style.innerHTML = `
                #guide-step-overlay {
                    position: fixed;
                    bottom: 24px;
                    left: 50%;
                    transform: translateX(-50%);
                    z-index: 999999;
                    background: rgba(11, 16, 27, 0.94);
                    border: 1.5px solid #00F0FF;
                    backdrop-filter: blur(24px);
                    -webkit-backdrop-filter: blur(24px);
                    border-radius: 999px;
                    padding: 10px 26px;
                    box-shadow: 0 10px 35px rgba(0, 0, 0, 0.8), 0 0 24px rgba(0, 240, 255, 0.35);
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    display: flex;
                    align-items: center;
                    gap: 16px;
                    transition: all 0.35s cubic-bezier(0.16, 1, 0.3, 1);
                    pointer-events: none;
                    max-width: 92vw;
                }
                .guide-badge {
                    background: linear-gradient(135deg, #00F0FF, #0080FF);
                    color: #050811;
                    font-size: 11px;
                    font-weight: 900;
                    letter-spacing: 0.8px;
                    text-transform: uppercase;
                    padding: 5px 12px;
                    border-radius: 999px;
                    white-space: nowrap;
                    box-shadow: 0 0 14px rgba(0, 240, 255, 0.65);
                }
                .guide-content {
                    display: flex;
                    flex-direction: column;
                    gap: 2px;
                }
                .guide-title {
                    color: #FFFFFF;
                    font-size: 14px;
                    font-weight: 700;
                    letter-spacing: 0.2px;
                    display: flex;
                    align-items: center;
                    gap: 6px;
                }
                .guide-title span {
                    color: #00F0FF;
                    font-weight: 800;
                }
                .guide-subtext {
                    color: #8B949E;
                    font-size: 11px;
                    font-weight: 500;
                }
                .guide-subtext strong {
                    color: #10B981;
                }

                #guide-end-card {
                    display: none;
                    position: fixed;
                    inset: 0;
                    z-index: 1000000;
                    background: rgba(5, 8, 17, 0.90);
                    backdrop-filter: blur(32px);
                    -webkit-backdrop-filter: blur(32px);
                    justify-content: center;
                    align-items: center;
                    flex-direction: column;
                    opacity: 0;
                    transition: opacity 0.45s ease;
                }
                .guide-end-box {
                    background: rgba(11, 16, 27, 0.96);
                    border: 2px solid #00F0FF;
                    border-radius: 28px;
                    padding: 48px 68px;
                    text-align: center;
                    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.85), 0 0 55px rgba(0, 240, 255, 0.45);
                    max-width: 760px;
                }
                .guide-end-title {
                    font-size: 40px;
                    font-weight: 900;
                    background: linear-gradient(135deg, #FFFFFF 0%, #00F0FF 60%, #00A3FF 100%);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                    letter-spacing: 1.5px;
                    margin-bottom: 12px;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                }
                .guide-end-subtitle {
                    font-size: 17px;
                    color: #E2E8F0;
                    font-weight: 600;
                    margin-bottom: 22px;
                    line-height: 1.5;
                }
                .guide-end-subtitle span {
                    color: #00F0FF;
                    font-weight: 800;
                }
                .guide-chips-row {
                    display: flex;
                    justify-content: center;
                    gap: 10px;
                    margin-bottom: 26px;
                }
                .guide-chip {
                    background: rgba(0, 240, 255, 0.12);
                    border: 1px solid rgba(0, 240, 255, 0.35);
                    color: #00F0FF;
                    padding: 6px 14px;
                    border-radius: 999px;
                    font-size: 11.5px;
                    font-weight: 700;
                    letter-spacing: 0.5px;
                }
                .guide-end-url {
                    font-size: 19px;
                    font-weight: 800;
                    color: #58A6FF;
                    letter-spacing: 0.8px;
                    margin-bottom: 12px;
                }
                .guide-end-author {
                    font-size: 13px;
                    color: #8B949E;
                    font-weight: 500;
                }
            `;
            document.head.appendChild(style);

            const overlay = document.createElement('div');
            overlay.id = 'guide-step-overlay';
            overlay.innerHTML = `
                <div class="guide-badge" id="g-badge">LIVE CONSTRUCTION</div>
                <div class="guide-content">
                    <div class="guide-title" id="g-title">Initializing Ground-Up Construction...</div>
                    <div class="guide-subtext" id="g-subtext"></div>
                </div>
            `;
            document.body.appendChild(overlay);

            const endCard = document.createElement('div');
            endCard.id = 'guide-end-card';
            endCard.innerHTML = `
                <div class="guide-end-box">
                    <div class="guide-end-title">STRUCTURA NEXUS</div>
                    <div class="guide-end-subtitle">
                        Build, Analyze & Optimize Structures with Real-Time AI Guidance<br>
                        <span>Interactive 3D WebGL · Sub-1.5ms Physics GNN · Closed-Loop Multi-Agent Swarms</span>
                    </div>
                    <div class="guide-chips-row">
                        <div class="guide-chip">AISC 360-16 LRFD</div>
                        <div class="guide-chip">ACI 318-19</div>
                        <div class="guide-chip">ASCE 7-16</div>
                        <div class="guide-chip">openBIM IFC 4.3</div>
                        <div class="guide-chip">CSI ETABS .s2k</div>
                    </div>
                    <div class="guide-end-url">structura-nexus.web.app</div>
                    <div class="guide-end-author">Developed by Ali Asghar · Dart Nexus Lab</div>
                </div>
            `;
            document.body.appendChild(endCard);
        })();
    """)


def set_guide_pill(page, badge_text, title_html, subtext_html):
    page.evaluate(f"""
        (() => {{
            const b = document.getElementById('g-badge');
            const t = document.getElementById('g-title');
            const s = document.getElementById('g-subtext');
            if (b) b.innerText = {repr(badge_text)};
            if (t) t.innerHTML = {repr(title_html)};
            if (s) s.innerHTML = {repr(subtext_html)};
        }})();
    """)


def show_guide_end_card(page):
    page.evaluate("""
        (() => {
            const overlay = document.getElementById('guide-step-overlay');
            if (overlay) overlay.style.display = 'none';
            const endCard = document.getElementById('guide-end-card');
            if (endCard) {
                endCard.style.display = 'flex';
                setTimeout(() => { endCard.style.opacity = '1'; }, 40);
            }
        })();
    """)


def enable_continuous_orbit(page, speed=2.2):
    page.evaluate(f"""
        (() => {{
            if (window.__currentThreeViewport && window.__currentThreeViewport.controls) {{
                window.__currentThreeViewport.controls.autoRotate = true;
                window.__currentThreeViewport.controls.autoRotateSpeed = {speed};
            }}
        }})();
    """)


def dispatch_action(page, action_name):
    page.evaluate(f"""
        (() => {{
            window.dispatchEvent(new CustomEvent('structura-action', {{
                detail: {{ action: {repr(action_name)} }}
            }}));
        }})();
    """)


def smooth_mouse_move(page, start_x, start_y, end_x, end_y, steps=18):
    for i in range(1, steps + 1):
        t = i / steps
        ease = t * t * (3 - 2 * t)
        curr_x = start_x + (end_x - start_x) * ease
        curr_y = start_y + (end_y - start_y) * ease
        page.mouse.move(curr_x, curr_y)
        time.sleep(0.012)


def click_flt_element(page, text_fragment, fallback_x=None, fallback_y=None, timeout_ms=2000):
    try:
        loc = page.locator("flutter-view").get_by_text(text_fragment, exact=False)
        if loc.count() > 0:
            loc.first.click(timeout=timeout_ms, force=True)
            return True
    except Exception:
        pass

    if fallback_x is not None and fallback_y is not None:
        page.mouse.click(fallback_x, fallback_y)
        return True
    return False


def record_showcase():
    from playwright.sync_api import sync_playwright

    DESKTOP_DIR.mkdir(parents=True, exist_ok=True)
    ICLOUD_DIR.mkdir(parents=True, exist_ok=True)
    if TEMP_VIDEO_DIR.exists():
        shutil.rmtree(TEMP_VIDEO_DIR)
    TEMP_VIDEO_DIR.mkdir(parents=True, exist_ok=True)

    server_proc = ensure_server()

    try:
        with sync_playwright() as p:
            chrome_path = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
            print("Launching Chrome in background headless mode (WebGL/Metal enabled)...")

            browser = p.chromium.launch(
                headless=True,
                executable_path=chrome_path if os.path.exists(chrome_path) else None,
                args=[
                    "--enable-webgl",
                    "--ignore-gpu-blocklist",
                    "--use-gl=angle",
                    "--use-angle=metal",
                    "--window-size=1920,1080",
                    "--disable-dev-shm-usage",
                    "--no-sandbox",
                ],
            )

            context = browser.new_context(
                viewport={"width": 1920, "height": 1080},
                device_scale_factor=1.0,
                record_video_dir=str(TEMP_VIDEO_DIR),
                record_video_size={"width": 1920, "height": 1080},
            )

            context.add_init_script("""
                try {
                    localStorage.setItem('structura_workspace_demo_authenticated', 'true');
                    localStorage.setItem('structura_workspace_inspector_is_open', 'true');
                } catch(e) {}
            """)

            page = context.new_page()
            url = f"http://localhost:{PORT}/#/"
            print(f"Navigating to {url}...")
            page.goto(url, wait_until="networkidle")

            print("Waiting for Structura Nexus WebGL CanvasKit initialization...")
            page.wait_for_timeout(4500)

            inject_guide_ui(page)
            enable_continuous_orbit(page, speed=2.2)
            print("UI Guide Overlay Injected & Continuous Orbit Activated.")

            # =================================================================
            # ACT 1 (00s – 08s) | Starting Fresh: Placing 3D Joints & Fixing Base Supports
            # =================================================================
            print("\n>>> ACT 1: Placing 3D Joints & Fixing Base Supports")
            set_guide_pill(
                page,
                "STEP 1: PLACE 3D JOINTS & SUPPORTS",
                "Define Spatial Coordinates & <span>Fixed Base Foundations</span>",
                "Column base foundations placed at <strong>y = 0m (6-DOF Restraint)</strong> • Spatial grid ready",
            )

            # Move mouse to DRAW & MODEL on the left
            smooth_mouse_move(page, 960, 540, 120, 200, steps=15)
            page.wait_for_timeout(1000)

            # Clear to clean canvas
            print("Clearing canvas for fresh construction...")
            dispatch_action(page, "clear")
            page.wait_for_timeout(1200)

            # Visibly place 3D joints and foundation blocks
            print("Placing column base joints N1, N2 with fixed foundation blocks, and upper joints N3, N4...")
            smooth_mouse_move(page, 120, 200, 120, 240, steps=12)
            dispatch_action(page, "step1_place_joints")
            enable_continuous_orbit(page, speed=2.4)
            page.wait_for_timeout(2600)

            # =================================================================
            # ACT 2 (08s – 16s) | Connecting Columns & Beams + Live AI Workflow Guidance
            # =================================================================
            print("\n>>> ACT 2: Connecting Columns & Beams + Live AI Workflow Guidance")
            set_guide_pill(
                page,
                "STEP 2: DRAW STRUCTURAL MEMBERS",
                "Connect AISC W-Shapes • <span>AI Workflow Guide Tracks Stability Live</span>",
                "Columns (W14X90) & Girder (W18X35) snapped • <strong>12-DOF Direct Stiffness Equilibrium Verified</strong>",
            )

            # Move to Draw Member tool
            smooth_mouse_move(page, 120, 240, 120, 280, steps=14)
            page.wait_for_timeout(800)

            # Connect columns and girder
            print("Snapping columns and girder into place...")
            dispatch_action(page, "step2_draw_members")
            enable_continuous_orbit(page, speed=2.2)
            page.wait_for_timeout(2800)

            # Move mouse to top NextStepPromptBanner / WorkflowGuideBar
            smooth_mouse_move(page, 120, 280, 960, 80, steps=14)
            page.wait_for_timeout(1800)

            # =================================================================
            # ACT 3 (16s – 24s) | Growing the Building: Extend Bays & Extrude Stories
            # =================================================================
            print("\n>>> ACT 3: Extend Bays (+X/+Z) & Extrude Multi-Story Levels")
            set_guide_pill(
                page,
                "STEP 3: EXPAND INTO MULTI-STORY BUILDING",
                "Extend Bays & Extrude Floors • <span>Tower Grows in Real Time</span>",
                "Multi-bay expansion along X & Z • <strong>H = 14.4m+ Multi-Story Space Frame</strong>",
            )

            # Extend Bay +X
            print("Extending Bay (+X Span)...")
            smooth_mouse_move(page, 960, 80, 120, 320, steps=12)
            dispatch_action(page, "extend_bay_x")
            page.wait_for_timeout(1400)

            # Extend Bay +Z
            print("Extending Bay (+Z Depth)...")
            dispatch_action(page, "extend_bay_z")
            page.wait_for_timeout(1400)

            # Extrude Story 1
            print("Extruding Story 2 (+3.6m)...")
            dispatch_action(page, "extrude_story")
            page.wait_for_timeout(1500)

            # Extrude Story 2
            print("Extruding Story 3 (+3.6m)...")
            dispatch_action(page, "extrude_story")
            enable_continuous_orbit(page, speed=2.5)
            page.wait_for_timeout(2000)

            # =================================================================
            # ACT 4 (24s – 31s) | Kinetic 3D Joint Dragging (Sub-1.5ms Physics GNN)
            # =================================================================
            print("\n>>> ACT 4: Kinetic 3D Joint Dragging & Sub-1.5ms Physics Prediction")
            set_guide_pill(
                page,
                "STEP 4: INTERACTIVE 3D MORPHING",
                "Drag Any Joint at 60 FPS • <span>Sub-1.5ms Neural Physics GNN</span>",
                "Real-time kinetic deflection prediction + <strong>3D Extruded Bending Moment (BMD) Ribbons</strong>",
            )

            # Toggle 3D BMD ribbons
            print("Toggling 3D Extruded BMD ribbons...")
            dispatch_action(page, "toggle_bmd")
            page.wait_for_timeout(800)

            # Hover over joint and drag
            print("Dragging corner joint dynamically at 60 FPS...")
            smooth_mouse_move(page, 120, 320, 960, 480, steps=14)
            for dy in [0.4, 0.8, 1.4, 1.8, 1.4, 0.9, 0.4]:
                page.evaluate(f"""
                    window.dispatchEvent(new CustomEvent('structura-node-dragged', {{
                        detail: {{ nodeId: 'N4', x: 6.0, y: {3.6 + dy}, z: 0.0 }}
                    }}));
                """)
                time.sleep(0.06)

            # Release node -> 12-DOF DSM solve locks in exact equilibrium
            page.evaluate("""
                window.dispatchEvent(new CustomEvent('structura-node-drag-end', {
                    detail: { nodeId: 'N4', x: 6.0, y: 4.8, z: 0.0 }
                }));
            """)
            print("12-DOF DSM solve locked in with exact equilibrium verified.")
            enable_continuous_orbit(page, speed=2.2)
            page.wait_for_timeout(2200)

            # =================================================================
            # ACT 5 (31s – 39s) | Live AI Co-Pilot & Multi-Agent Swarm Optimization
            # =================================================================
            print("\n>>> ACT 5: Live AI Co-Pilot & Multi-Agent Swarm Optimization")
            set_guide_pill(
                page,
                "STEP 5: AI ENGINEERING CO-PILOT",
                "Detects Lateral Drift • <span>Adds Bracing & Optimizes Steel Tonnage</span>",
                "Architect &rarr; Auditor &rarr; Self-Healer loop • <strong>Safe DCR &le; 0.95 (Emerald Green)</strong>",
            )

            # Open Autonomous Swarm Dialog
            smooth_mouse_move(page, 960, 480, 745, 35, steps=12)
            page.mouse.click(745, 35)
            page.wait_for_timeout(700)

            click_flt_element(page, "Autonomous 4-Agent Engineering Swarm", fallback_x=930, fallback_y=420)
            page.wait_for_timeout(2200)
            print("Swarm convergence running: Architect -> FEA Analyst -> Code Auditor -> Self-Healer...")

            # Commit Swarm Solution
            click_flt_element(page, "APPLY SWARM-HEALED TOPOLOGY", fallback_x=1200, fallback_y=850)
            dispatch_action(page, "apply_ai_optimization")
            print("Applied AI-guided bracing & auto-sized sections to 3D building.")
            enable_continuous_orbit(page, speed=2.4)
            page.wait_for_timeout(2200)

            # =================================================================
            # ACT 6 (39s – 45s) | Instant Steel Takeoff (BOM), BIM Exports & End Card
            # =================================================================
            print("\n>>> ACT 6: Instant Steel Takeoff (BOM), BIM Exports & End Card")
            set_guide_pill(
                page,
                "STEP 6: READY FOR CONSTRUCTION",
                "Instant Steel Quantity Takeoff (BOM) • <span>ETABS (.s2k) & Stamped PDF</span>",
                "Total linear cut lengths, tonnage schedule, and <strong>1-click BIM interoperability</strong>",
            )

            # Open 5. REPORTS & BIM -> Steel BOM Takeoff
            smooth_mouse_move(page, 745, 35, 875, 35, steps=12)
            page.mouse.click(875, 35)
            page.wait_for_timeout(700)

            click_flt_element(page, "Steel BOM Takeoff", fallback_x=190, fallback_y=500)
            page.wait_for_timeout(1800)

            page.keyboard.press("Escape")
            page.wait_for_timeout(400)

            # At ~42.5s: Display 2.5-second Branded End Card
            print("Displaying 2.5-second Branded End Card...")
            show_guide_end_card(page)
            page.wait_for_timeout(2600)

            print("Closing browser and finalizing video capture...")
            context.close()
            browser.close()

    finally:
        server_proc.terminate()

    # Transcode WebM to 1080p 60 FPS MP4 via FFmpeg
    raw_videos = list(TEMP_VIDEO_DIR.glob("*.webm"))
    if not raw_videos:
        print("ERROR: No raw video recording found in /tmp/structura_build_guide_raw_vid")
        sys.exit(1)

    latest_webm = max(raw_videos, key=os.path.getmtime)
    print(f"\nRaw recording saved: {latest_webm} ({latest_webm.stat().st_size / (1024*1024):.2f} MB)")
    print(f"Transcoding to 1080p 60 FPS H.264 MP4: {OUT_DESKTOP} and {OUT_ICLOUD}...")

    ffmpeg_bin = shutil.which("ffmpeg") or "/opt/homebrew/Cellar/ffmpeg/9.0.2_1/bin/ffmpeg" or "/opt/homebrew/bin/ffmpeg"
    cmd = [
        ffmpeg_bin,
        "-y",
        "-ss", "00:00:07.5",
        "-i", str(latest_webm),
        "-c:v", "libx264",
        "-crf", "17",
        "-preset", "fast",
        "-pix_fmt", "yuv420p",
        "-r", "60",
        "-movflags", "+faststart",
        "-an",
        str(OUT_FASTHOOK_DESKTOP),
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        print("FFmpeg error:", res.stderr.decode("utf-8", errors="ignore"))
        sys.exit(res.returncode)

    # Save to both Desktop and iCloud Mac Screenshots
    shutil.copyfile(str(OUT_FASTHOOK_DESKTOP), str(OUT_FASTHOOK_ICLOUD))
    # Also keep standard alias for compatibility
    shutil.copyfile(str(OUT_FASTHOOK_DESKTOP), str(OUT_DESKTOP))
    shutil.copyfile(str(OUT_FASTHOOK_DESKTOP), str(OUT_ICLOUD))

    print(f"\nSUCCESS! Fast-hook showcase video successfully written to BOTH destinations:\n1. {OUT_FASTHOOK_DESKTOP}\n2. {OUT_FASTHOOK_ICLOUD}")


if __name__ == "__main__":
    record_showcase()
