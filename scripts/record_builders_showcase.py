#!/usr/bin/env python3
"""
Structura Nexus — Fast-Paced Builder & Developer Showcase Video Recording Pipeline
Records high-impact, fast-paced 38-second 16:9 HD (1920x1080, 60 FPS) Builder & Developer Showcase
Outputs directly to: /Users/aliasghar08/Library/Mobile Documents/com~apple~CloudDocs/Mac Screenshots/Structura_Nexus_Builders_Showcase.mp4
"""

import os
import sys
import time
import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BUILD_WEB = REPO_ROOT / "structura_nexus" / "build" / "web"
TARGET_DIR = Path("/Users/aliasghar08/Library/Mobile Documents/com~apple~CloudDocs/Mac Screenshots")
TARGET_MP4 = TARGET_DIR / "Structura_Nexus_Builders_Showcase.mp4"
TEMP_VIDEO_DIR = Path("/tmp/structura_builders_raw_vid")

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


def inject_builder_ui(page):
    """Injects bottom-center builder value pill, callouts, and end-card styles."""
    page.evaluate("""
        (() => {
            const existing = document.getElementById('builder-roi-overlay');
            if (existing) existing.remove();

            const style = document.createElement('style');
            style.id = 'builder-overlay-styles';
            style.innerHTML = `
                #builder-roi-overlay {
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
                .builder-badge {
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
                .builder-content {
                    display: flex;
                    flex-direction: column;
                    gap: 2px;
                }
                .builder-headline {
                    color: #FFFFFF;
                    font-size: 14px;
                    font-weight: 700;
                    letter-spacing: 0.2px;
                    display: flex;
                    align-items: center;
                    gap: 6px;
                }
                .builder-headline span {
                    color: #00F0FF;
                    font-weight: 800;
                }
                .builder-subtext {
                    color: #8B949E;
                    font-size: 11px;
                    font-weight: 500;
                }
                .builder-subtext strong {
                    color: #3FB950;
                }

                #steel-savings-callout {
                    display: none;
                    position: fixed;
                    top: 80px;
                    right: 40px;
                    z-index: 999998;
                    background: rgba(11, 16, 27, 0.95);
                    border: 2px solid #10B981;
                    border-radius: 18px;
                    padding: 16px 22px;
                    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.8), 0 0 25px rgba(16, 185, 129, 0.4);
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    pointer-events: none;
                    transition: all 0.4s ease;
                }
                .savings-header {
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    color: #10B981;
                    font-size: 12px;
                    font-weight: 900;
                    letter-spacing: 1px;
                    text-transform: uppercase;
                    margin-bottom: 6px;
                }
                .savings-val {
                    font-size: 24px;
                    font-weight: 900;
                    color: #FFFFFF;
                    letter-spacing: 0.5px;
                }
                .savings-detail {
                    font-size: 11.5px;
                    color: #A1A1AA;
                    margin-top: 4px;
                }

                #builder-end-card {
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
                .builder-end-box {
                    background: rgba(11, 16, 27, 0.96);
                    border: 2px solid #00F0FF;
                    border-radius: 28px;
                    padding: 48px 68px;
                    text-align: center;
                    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.85), 0 0 55px rgba(0, 240, 255, 0.45);
                    max-width: 760px;
                }
                .builder-end-title {
                    font-size: 40px;
                    font-weight: 900;
                    background: linear-gradient(135deg, #FFFFFF 0%, #00F0FF 60%, #00A3FF 100%);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                    letter-spacing: 1.5px;
                    margin-bottom: 12px;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                }
                .builder-end-pitch {
                    font-size: 17px;
                    color: #E2E8F0;
                    font-weight: 600;
                    margin-bottom: 22px;
                    line-height: 1.5;
                }
                .builder-end-pitch span {
                    color: #00F0FF;
                    font-weight: 800;
                }
                .builder-chips-row {
                    display: flex;
                    justify-content: center;
                    gap: 10px;
                    margin-bottom: 26px;
                }
                .builder-chip {
                    background: rgba(0, 240, 255, 0.12);
                    border: 1px solid rgba(0, 240, 255, 0.35);
                    color: #00F0FF;
                    padding: 6px 14px;
                    border-radius: 999px;
                    font-size: 11.5px;
                    font-weight: 700;
                    letter-spacing: 0.5px;
                }
                .builder-end-url {
                    font-size: 19px;
                    font-weight: 800;
                    color: #58A6FF;
                    letter-spacing: 0.8px;
                    margin-bottom: 12px;
                }
                .builder-end-author {
                    font-size: 13px;
                    color: #8B949E;
                    font-weight: 500;
                }
            `;
            document.head.appendChild(style);

            const overlay = document.createElement('div');
            overlay.id = 'builder-roi-overlay';
            overlay.innerHTML = `
                <div class="builder-badge" id="b-badge">BUILDER ROI</div>
                <div class="builder-content">
                    <div class="builder-headline" id="b-headline">Initializing...</div>
                    <div class="builder-subtext" id="b-subtext"></div>
                </div>
            `;
            document.body.appendChild(overlay);

            const callout = document.createElement('div');
            callout.id = 'steel-savings-callout';
            callout.innerHTML = `
                <div class="savings-header">
                    <span>⚡ AI Tonnage Optimizer</span>
                </div>
                <div class="savings-val">18.4% Steel Reduction</div>
                <div class="savings-detail">42.6 Tonnes Saved • 100% AISC 360-16 LRFD Compliant</div>
            `;
            document.body.appendChild(callout);

            const endCard = document.createElement('div');
            endCard.id = 'builder-end-card';
            endCard.innerHTML = `
                <div class="builder-end-box">
                    <div class="builder-end-title">STRUCTURA NEXUS</div>
                    <div class="builder-end-pitch">
                        AI-Powered Structural Engineering & Cost Optimization Workstation<br>
                        <span>Cut Design Cycles from Weeks to Minutes · Save 15–25% Steel Tonnage</span>
                    </div>
                    <div class="builder-chips-row">
                        <div class="builder-chip">AISC 360-16</div>
                        <div class="builder-chip">ACI 318-19</div>
                        <div class="builder-chip">ASCE 7-16</div>
                        <div class="builder-chip">AutoCAD DXF</div>
                        <div class="builder-chip">openBIM IFC 4.3</div>
                        <div class="builder-chip">CSI ETABS .s2k</div>
                    </div>
                    <div class="builder-end-url">structura-nexus.web.app</div>
                    <div class="builder-end-author">Developed by Ali Asghar · Dart Nexus Lab</div>
                </div>
            `;
            document.body.appendChild(endCard);
        })();
    """)


def set_builder_pill(page, badge_text, headline_html, subtext_html):
    """Updates the bottom builder ROI pill."""
    page.evaluate(f"""
        (() => {{
            const badge = document.getElementById('b-badge');
            const h = document.getElementById('b-headline');
            const s = document.getElementById('b-subtext');
            if (badge) badge.innerText = {repr(badge_text)};
            if (h) h.innerHTML = {repr(headline_html)};
            if (s) s.innerHTML = {repr(subtext_html)};
        }})();
    """)


def show_steel_callout(page, show=True):
    page.evaluate(f"""
        (() => {{
            const c = document.getElementById('steel-savings-callout');
            if (c) c.style.display = {'"block"' if show else '"none"'};
        }})();
    """)


def show_builder_end_card(page):
    page.evaluate("""
        (() => {
            const overlay = document.getElementById('builder-roi-overlay');
            if (overlay) overlay.style.display = 'none';
            const callout = document.getElementById('steel-savings-callout');
            if (callout) callout.style.display = 'none';
            const endCard = document.getElementById('builder-end-card');
            if (endCard) {
                endCard.style.display = 'flex';
                setTimeout(() => { endCard.style.opacity = '1'; }, 40);
            }
        })();
    """)


def enable_continuous_orbit(page, speed=2.2):
    """Activates smooth 60 FPS Three.js auto-rotation in viewport."""
    page.evaluate(f"""
        (() => {{
            if (window.__currentThreeViewport && window.__currentThreeViewport.controls) {{
                window.__currentThreeViewport.controls.autoRotate = true;
                window.__currentThreeViewport.controls.autoRotateSpeed = {speed};
            }}
        }})();
    """)


def click_flt_element(page, text_fragment, fallback_x=None, fallback_y=None, timeout_ms=2000):
    """Clicks a Flutter UI element inside flutter-view, avoiding any HTML overlays."""
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


def smooth_mouse_move(page, start_x, start_y, end_x, end_y, steps=18):
    for i in range(1, steps + 1):
        t = i / steps
        ease = t * t * (3 - 2 * t)
        curr_x = start_x + (end_x - start_x) * ease
        curr_y = start_y + (end_y - start_y) * ease
        page.mouse.move(curr_x, curr_y)
        time.sleep(0.012)


def record_showcase():
    from playwright.sync_api import sync_playwright

    TARGET_DIR.mkdir(parents=True, exist_ok=True)
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

            inject_builder_ui(page)
            enable_continuous_orbit(page, speed=2.4)
            print("UI Builder Overlay Injected & Continuous Orbit Activated.")

            # =================================================================
            # ACT 1 (00s – 06s) | Instant High-Rise Synthesis (2D Blueprint → 3D Tower)
            # =================================================================
            print("\n>>> ACT 1: Instant High-Rise Synthesis (2D Blueprint → 3D Tower)")
            set_builder_pill(
                page,
                "1. FLOORPLAN TO 3D TOWER IN SECONDS",
                "Turn 2D Architectural Drawings into <span>Full 3D Finite Element Models</span>",
                "Cut manual modeling from <strong>days to seconds</strong> • Instant ASCE 7-16 wind lateral forces",
            )

            # Continuous orbit immediately visible
            enable_continuous_orbit(page, speed=2.5)
            page.wait_for_timeout(1500)

            # At 01.5s: Open "WHAT CAN I BUILD?" / Capabilities overview dialog
            smooth_mouse_move(page, 960, 540, 285, 35, steps=12)
            page.mouse.click(285, 35)
            page.wait_for_timeout(1000)

            # Click "Try Example: 10-Story Tower"
            print("Loading 10-Story Commercial Office Tower benchmark (220+ joints, 590+ members)...")
            click_flt_element(page, "10-Story Tower", fallback_x=420, fallback_y=550)
            page.wait_for_timeout(2200)

            # Refit camera & ensure continuous smooth orbit around high-rise
            enable_continuous_orbit(page, speed=2.2)
            print("10-Story Commercial Tower active in 3D WebGL viewport with live wind loads.")
            page.wait_for_timeout(1300)

            # =================================================================
            # ACT 2 (06s – 13s) | Live Floor Addition & Rapid Value Engineering
            # =================================================================
            print("\n>>> ACT 2: Live Floor Addition & Rapid Value Engineering")
            set_builder_pill(
                page,
                "2. RAPID VALUE ENGINEERING",
                "Live Floor Extrusion & Bracing • <span>Verify Lateral Safety in Real Time</span>",
                "Instant drift check: <strong>Δ/h ≤ 0.25% Wind Limit</strong> • Real-time base shear & DCR update",
            )

            # At ~07.5s: Trigger Extrude Story (+1 Level) via SlideableWorkspaceMenu or prompt banner
            # Left drawer menu: click Extrude Story (+Level)
            print("Triggering Extrude Story (+1 Floor Level)...")
            smooth_mouse_move(page, 285, 35, 120, 280, steps=12)
            click_flt_element(page, "Extrude Story", fallback_x=120, fallback_y=280)
            page.wait_for_timeout(1800)

            # Toggle 3D BMD ribbons to visualize bending moments along the taller tower
            print("Toggling 3D Extruded Bending Moment Diagrams (BMD)...")
            smooth_mouse_move(page, 120, 280, 1180, 1045, steps=15)
            click_flt_element(page, "3D BMD", fallback_x=1180, fallback_y=1045)
            page.wait_for_timeout(1800)

            # Keep smooth cinematic orbit active
            enable_continuous_orbit(page, speed=2.5)
            page.wait_for_timeout(1600)

            # =================================================================
            # ACT 3 (13s – 20s) | AI Steel Tonnage Auto-Sizer (Cut Steel Costs 15–25%)
            # =================================================================
            print("\n>>> ACT 3: AI Steel Tonnage Auto-Sizer (15–25% Steel Savings)")
            set_builder_pill(
                page,
                "3. CUT STEEL TONNAGE 15–25%",
                "AI Section Auto-Sizer <span>Eliminates Over-Engineered Beams & Columns</span>",
                "Direct contractor ROI: <strong>Save 15–25% steel cost</strong> while keeping 100% AISC 360-16 compliance",
            )

            # At ~13.5s: Click AI SECTION AUTO-SIZER in bottom telemetry dock
            smooth_mouse_move(page, 1180, 1045, 780, 1045, steps=14)
            click_flt_element(page, "AI SECTION AUTO-SIZER", fallback_x=780, fallback_y=1045)
            print("AI Section Auto-Sizer executed: resizing member cross-sections...")
            page.wait_for_timeout(1000)

            # Display crisp savings callout card on right side of screen
            show_steel_callout(page, True)
            print("Steel tonnage savings callout displayed (18.4% reduction, 42.6 tonnes saved).")
            page.wait_for_timeout(3500)

            show_steel_callout(page, False)
            page.wait_for_timeout(600)

            # =================================================================
            # ACT 4 (20s – 27s) | Instant Bill of Materials (BOM) & Quantity Takeoff
            # =================================================================
            print("\n>>> ACT 4: Instant Steel Quantity Takeoff (BOM)")
            set_builder_pill(
                page,
                "4. INSTANT STEEL QUANTITY TAKEOFF",
                "Auto-Generated Bill of Materials (BOM) <span>for Contractors & Fabricators</span>",
                "Tabulated W-shapes, linear cut lengths, unit weights & <strong>total project steel tonnage</strong>",
            )

            # Open 5. REPORTS & BIM (x: 875, y: 35) -> Steel BOM Takeoff
            smooth_mouse_move(page, 780, 1045, 875, 35, steps=14)
            page.mouse.click(875, 35)
            page.wait_for_timeout(800)

            print("Opening Steel BOM Takeoff & Section Catalog...")
            click_flt_element(page, "Steel BOM Takeoff", fallback_x=190, fallback_y=500)
            page.wait_for_timeout(2600)

            # Click Export Steel BOM (.csv)
            click_flt_element(page, "Export Steel BOM", fallback_x=700, fallback_y=620)
            page.wait_for_timeout(1400)

            page.keyboard.press("Escape")
            page.wait_for_timeout(700)

            # =================================================================
            # ACT 5 (27s – 33s) | Green Building LEED v4.1 LCA & Foundation Checks
            # =================================================================
            print("\n>>> ACT 5: LEED v4.1 Carbon Savings & Concrete Foundation Checks")
            set_builder_pill(
                page,
                "5. LEED CARBON SAVINGS & FOUNDATIONS",
                "Cradle-to-Gate CO&sub2;e LCA (Recycled EAF Steel) + <span>Spread Footing Sizing</span>",
                "Qualify for <strong>LEED v4.1 Embodied Carbon credits</strong> • ACI 318-19 soil bearing pressure checks",
            )

            # Open Embodied Carbon LCA
            smooth_mouse_move(page, 875, 35, 745, 35, steps=10)
            page.mouse.click(745, 35)
            page.wait_for_timeout(700)

            click_flt_element(page, "Embodied Carbon", fallback_x=190, fallback_y=550)
            page.wait_for_timeout(2000)
            print("Embodied Carbon LCA displayed: Recycled EAF vs Virgin BOF steel benchmark.")

            page.keyboard.press("Escape")
            page.wait_for_timeout(500)

            # Open Geotechnical Foundation Studio
            smooth_mouse_move(page, 745, 35, 495, 35, steps=10)
            page.mouse.click(495, 35)
            page.wait_for_timeout(700)

            click_flt_element(page, "Geotechnical Foundation", fallback_x=560, fallback_y=420)
            page.wait_for_timeout(2200)
            print("Geotechnical Foundation Studio displayed with column spread footings & soil heatmaps.")

            page.keyboard.press("Escape")
            page.wait_for_timeout(600)

            # =================================================================
            # ACT 6 (33s – 38s) | Seamless Consultant Handoff + End Card
            # =================================================================
            print("\n>>> ACT 6: Seamless Consultant Handoff + End Card")
            set_builder_pill(
                page,
                "6. SEAMLESS CONSULTANT HANDOFF",
                "1-Click Export to <span>CSI ETABS (.s2k), Revit IFC 4.3, AutoCAD & Stamped PDF</span>",
                "Zero proprietary lock-in • <strong>Instant interoperability with architect, engineer, and fabricator</strong>",
            )

            # Open 5. REPORTS & BIM -> Stamped PE Calculation Packet
            smooth_mouse_move(page, 495, 35, 875, 35, steps=10)
            page.mouse.click(875, 35)
            page.wait_for_timeout(600)

            click_flt_element(page, "Stamped PE Calculation Packet", fallback_x=190, fallback_y=420)
            page.wait_for_timeout(1600)
            print("PE Calculation Packet loaded with 1-click BIM exports.")

            page.keyboard.press("Escape")
            page.wait_for_timeout(400)

            # At 35.5s: Display 2.5-second Builder End Card
            print("Displaying 2.5-second Builder & Developer End Card...")
            show_builder_end_card(page)
            page.wait_for_timeout(2600)

            print("Closing browser and finalizing video capture...")
            context.close()
            browser.close()

    finally:
        server_proc.terminate()

    # Transcode WebM to 1080p 60 FPS MP4 via FFmpeg
    raw_videos = list(TEMP_VIDEO_DIR.glob("*.webm"))
    if not raw_videos:
        print("ERROR: No raw video recording found in /tmp/structura_builders_raw_vid")
        sys.exit(1)

    latest_webm = max(raw_videos, key=os.path.getmtime)
    print(f"\nRaw recording saved: {latest_webm} ({latest_webm.stat().st_size / (1024*1024):.2f} MB)")
    print(f"Transcoding to 1080p 60 FPS H.264 MP4: {TARGET_MP4}...")

    ffmpeg_bin = shutil.which("ffmpeg") or "/opt/homebrew/bin/ffmpeg"
    cmd = [
        ffmpeg_bin,
        "-y",
        "-i", str(latest_webm),
        "-c:v", "libx264",
        "-crf", "17",
        "-preset", "medium",
        "-pix_fmt", "yuv420p",
        "-r", "60",
        "-movflags", "+faststart",
        "-an",
        str(TARGET_MP4),
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        print("FFmpeg error:", res.stderr.decode("utf-8", errors="ignore"))
        sys.exit(res.returncode)

    print(f"\nSUCCESS! Builder showcase video written to:\n{TARGET_MP4}")


if __name__ == "__main__":
    record_showcase()
