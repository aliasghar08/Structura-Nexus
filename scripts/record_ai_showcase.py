#!/usr/bin/env python3
"""
Structura Nexus — Background Chrome Video Recording Pipeline
Records high-impact 40-second 16:9 HD (1920x1080, 60 FPS) AI Differentiator Showcase
Outputs directly to: /Users/aliasghar08/Library/Mobile Documents/com~apple~CloudDocs/Mac Screenshots/Structura_Nexus_AI_Showcase.mp4
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
TARGET_MP4 = TARGET_DIR / "Structura_Nexus_AI_Showcase.mp4"
TEMP_VIDEO_DIR = Path("/tmp/structura_raw_vid")

PORT = 5059


def ensure_server():
    """Start local web server serving flutter web build if not running."""
    print(f"Ensuring local HTTP server on port {PORT} serving {BUILD_WEB}...")
    # Clean up any lingering process on port 5059
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


def inject_ui_elements(page):
    """Injects bottom-center comparison overlay pill and end-card styles."""
    page.evaluate("""
        (() => {
            const existing = document.getElementById('ai-comparison-overlay');
            if (existing) existing.remove();

            const style = document.createElement('style');
            style.id = 'ai-overlay-styles';
            style.innerHTML = `
                #ai-comparison-overlay {
                    position: fixed;
                    bottom: 24px;
                    left: 50%;
                    transform: translateX(-50%);
                    z-index: 999999;
                    background: rgba(11, 16, 27, 0.92);
                    border: 1.5px solid #00F0FF;
                    backdrop-filter: blur(24px);
                    -webkit-backdrop-filter: blur(24px);
                    border-radius: 999px;
                    padding: 10px 24px;
                    box-shadow: 0 10px 35px rgba(0, 0, 0, 0.7), 0 0 20px rgba(0, 240, 255, 0.35);
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    display: flex;
                    align-items: center;
                    gap: 16px;
                    transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
                    pointer-events: none;
                    max-width: 92vw;
                }
                .pill-badge {
                    background: linear-gradient(135deg, #00F0FF, #0080FF);
                    color: #050811;
                    font-size: 11px;
                    font-weight: 900;
                    letter-spacing: 0.8px;
                    text-transform: uppercase;
                    padding: 5px 12px;
                    border-radius: 999px;
                    white-space: nowrap;
                    box-shadow: 0 0 12px rgba(0, 240, 255, 0.6);
                }
                .pill-content {
                    display: flex;
                    flex-direction: column;
                    gap: 2px;
                }
                .pill-advantage {
                    color: #FFFFFF;
                    font-size: 13.5px;
                    font-weight: 700;
                    letter-spacing: 0.2px;
                    display: flex;
                    align-items: center;
                    gap: 6px;
                }
                .pill-advantage span {
                    color: #00F0FF;
                    font-weight: 800;
                }
                .pill-legacy {
                    color: #8B949E;
                    font-size: 11px;
                    font-weight: 500;
                }
                .pill-legacy strong {
                    color: #FF5252;
                }

                #end-card-overlay {
                    display: none;
                    position: fixed;
                    inset: 0;
                    z-index: 1000000;
                    background: rgba(5, 8, 17, 0.88);
                    backdrop-filter: blur(30px);
                    -webkit-backdrop-filter: blur(30px);
                    justify-content: center;
                    align-items: center;
                    flex-direction: column;
                    opacity: 0;
                    transition: opacity 0.5s ease;
                }
                .end-card-box {
                    background: rgba(11, 16, 27, 0.95);
                    border: 2px solid #00F0FF;
                    border-radius: 28px;
                    padding: 48px 64px;
                    text-align: center;
                    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.8), 0 0 50px rgba(0, 240, 255, 0.4);
                    max-width: 720px;
                }
                .end-card-title {
                    font-size: 38px;
                    font-weight: 900;
                    background: linear-gradient(135deg, #FFFFFF 0%, #00F0FF 60%, #00A3FF 100%);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                    letter-spacing: 1.5px;
                    margin-bottom: 12px;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                }
                .end-card-subtitle {
                    font-size: 16px;
                    color: #C9D1D9;
                    font-weight: 500;
                    margin-bottom: 24px;
                    line-height: 1.5;
                }
                .end-card-badge-row {
                    display: flex;
                    justify-content: center;
                    gap: 12px;
                    margin-bottom: 28px;
                }
                .end-card-chip {
                    background: rgba(0, 240, 255, 0.12);
                    border: 1px solid rgba(0, 240, 255, 0.35);
                    color: #00F0FF;
                    padding: 6px 14px;
                    border-radius: 999px;
                    font-size: 11.5px;
                    font-weight: 700;
                    letter-spacing: 0.5px;
                }
                .end-card-url {
                    font-size: 18px;
                    font-weight: 800;
                    color: #58A6FF;
                    letter-spacing: 0.8px;
                    margin-bottom: 14px;
                }
                .end-card-author {
                    font-size: 12.5px;
                    color: #8B949E;
                    font-weight: 500;
                }
            `;
            document.head.appendChild(style);

            const overlay = document.createElement('div');
            overlay.id = 'ai-comparison-overlay';
            overlay.innerHTML = `
                <div class="pill-badge" id="overlay-badge">AI ADVANTAGE</div>
                <div class="pill-content">
                    <div class="pill-advantage" id="overlay-advantage">Initializing...</div>
                    <div class="pill-legacy" id="overlay-legacy"></div>
                </div>
            `;
            document.body.appendChild(overlay);

            const endCard = document.createElement('div');
            endCard.id = 'end-card-overlay';
            endCard.innerHTML = `
                <div class="end-card-box">
                    <div class="end-card-title">STRUCTURA NEXUS</div>
                    <div class="end-card-subtitle">The Next-Generation AI Structural Engineering Engine<br>Real-Time Physics GNN • 12-DOF Direct Stiffness • Closed-Loop Swarms</div>
                    <div class="end-card-badge-row">
                        <div class="end-card-chip">AISC 360-16 LRFD</div>
                        <div class="end-card-chip">ACI 318-19</div>
                        <div class="end-card-chip">ASCE 7-16</div>
                        <div class="end-card-chip">openBIM IFC 4.3</div>
                        <div class="end-card-chip">ETABS .s2k</div>
                    </div>
                    <div class="end-card-url">structura-nexus.web.app</div>
                    <div class="end-card-author">Developed by Ali Asghar · Dart Nexus Lab</div>
                </div>
            `;
            document.body.appendChild(endCard);
        })();
    """)


def update_overlay(page, badge_text, advantage_text, legacy_text):
    """Updates the content of the bottom comparison pill."""
    page.evaluate(f"""
        (() => {{
            const badge = document.getElementById('overlay-badge');
            const adv = document.getElementById('overlay-advantage');
            const leg = document.getElementById('overlay-legacy');
            if (badge) badge.innerText = {repr(badge_text)};
            if (adv) adv.innerHTML = {repr(advantage_text)};
            if (leg) leg.innerHTML = {repr(legacy_text)};
        }})();
    """)


def show_end_card(page):
    """Displays the glassmorphic end card."""
    page.evaluate("""
        (() => {
            const overlay = document.getElementById('ai-comparison-overlay');
            if (overlay) overlay.style.display = 'none';
            const endCard = document.getElementById('end-card-overlay');
            if (endCard) {
                endCard.style.display = 'flex';
                setTimeout(() => { endCard.style.opacity = '1'; }, 50);
            }
        })();
    """)


def smooth_mouse_move(page, start_x, start_y, end_x, end_y, steps=20):
    for i in range(1, steps + 1):
        t = i / steps
        ease = t * t * (3 - 2 * t)
        curr_x = start_x + (end_x - start_x) * ease
        curr_y = start_y + (end_y - start_y) * ease
        page.mouse.move(curr_x, curr_y)
        time.sleep(0.015)


def smooth_orbit_canvas(page, cx=960, cy=520, rx=160, ry=80, steps=30):
    """Simulates realistic 3D camera orbit by clicking and dragging in canvas center."""
    page.mouse.move(cx, cy)
    page.mouse.down()
    for i in range(1, steps + 1):
        curr_x = cx + rx * (i / steps)
        curr_y = cy + ry * 0.4 * (1 if i % 2 == 0 else -1)
        page.mouse.move(curr_x, curr_y)
        time.sleep(0.02)
    page.mouse.up()


def click_flutter_element(page, text_fragment, fallback_x=None, fallback_y=None, timeout_ms=2000):
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

            # Pre-populate localStorage with demo authentication before page loads
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

            # Allow Flutter CanvasKit / WebGL engine to initialize fully
            print("Waiting for Structura Nexus WebGL CanvasKit initialization...")
            page.wait_for_timeout(5000)

            inject_ui_elements(page)
            print("UI Comparison Overlay Injected.")

            # =================================================================
            # ACT 1 (00s – 07s) | Vision-to-BIM: 2D Blueprint → 3D Space Frame
            # =================================================================
            print("\n>>> ACT 1: Vision-to-BIM Floorplan Ingestion")
            update_overlay(
                page,
                "1. VISION-TO-BIM AI",
                "2D Architectural PDF/PNG &rarr; <span>Complete 3D Space Frame in Seconds (<2s)</span>",
                "Legacy ETABS / SAP2000: <strong>Hours of tedious manual grid, node, and member coordinate entry</strong>",
            )
            time.sleep(1.0)

            # Click "1. GEOMETRY" in FloatingWorkstationHeader (x: 375, y: 35)
            smooth_mouse_move(page, 960, 540, 375, 35, steps=15)
            page.mouse.click(375, 35)
            page.wait_for_timeout(1000)

            # Click "Vision-to-BIM 2D Floorplan Ingestion"
            click_flutter_element(page, "Vision-to-BIM", fallback_x=190, fallback_y=470)
            page.wait_for_timeout(1200)

            # In VisionIngestionDialog: click "Process Floorplan"
            smooth_mouse_move(page, 375, 35, 850, 750, steps=12)
            click_flutter_element(page, "Process Floorplan", fallback_x=850, fallback_y=750)
            print("Processing floorplan vectors with Gemini...")
            page.wait_for_timeout(1600)

            # Click "Synthesize 3D Frame"
            smooth_mouse_move(page, 850, 750, 1070, 750, steps=10)
            click_flutter_element(page, "Synthesize 3D Frame", fallback_x=1070, fallback_y=750)
            print("Synthesized 3D space frame into WebGL canvas.")
            page.wait_for_timeout(1800)

            # =================================================================
            # ACT 2 (07s – 14s) | Sub-1.5ms Physics GNN (StructuraNet-3D) + 12-DOF DSM
            # =================================================================
            print("\n>>> ACT 2: StructuraNet-3D Neural GNN + 60 FPS Morphing & 12-DOF DSM")
            update_overlay(
                page,
                "2. STRUCTURANET-3D (<1.5ms GNN)",
                "Real-Time 60 FPS Kinetic Morphing + <span>0.0000% Error 12-DOF DSM Exact Equilibrium</span>",
                "Legacy SAP2000: <strong>Static iterative solver runs that freeze the entire interface</strong>",
            )

            # Smoothly orbit 3D camera
            smooth_orbit_canvas(page, cx=960, cy=500, rx=180, ry=60, steps=25)
            page.wait_for_timeout(600)

            # Toggle 3D Extruded BMD Ribbons via telemetry dock or custom event
            page.evaluate("""
                window.dispatchEvent(new CustomEvent('structura-member-selected', { detail: { memberId: 'M1' } }));
            """)
            page.wait_for_timeout(600)
            click_flutter_element(page, "3D BMD", fallback_x=1180, fallback_y=1045)
            print("Toggled 3D Bending Moment Diagram (BMD) ribbons.")
            page.wait_for_timeout(800)

            # Simulate live kinetic node dragging (<1.5ms GNN real-time inference)
            print("Kinetic node morphing: dispatching dynamic node movements...")
            for dy in [0.3, 0.7, 1.2, 1.5, 1.2, 0.8, 0.4]:
                page.evaluate(f"""
                    window.dispatchEvent(new CustomEvent('structura-node-dragged', {{
                        detail: {{ nodeId: 'N4', x: 6.0, y: {6.0 + dy}, z: 0.0 }}
                    }}));
                """)
                time.sleep(0.06)

            # Release node -> locks in exact 12-DOF Direct Stiffness Matrix solve
            page.evaluate("""
                window.dispatchEvent(new CustomEvent('structura-node-drag-end', {
                    detail: { nodeId: 'N4', x: 6.0, y: 7.2, z: 0.0 }
                }));
            """)
            print("12-DOF DSM solve locked in with exact equilibrium.")
            page.wait_for_timeout(1500)

            # =================================================================
            # ACT 3 (14s – 21s) | Custom Concrete & Geotech AI (SectionNet-PM + Soil)
            # =================================================================
            print("\n>>> ACT 3: SectionNet-PM (<0.2ms) Concrete P-M & Geotech SSI")
            update_overlay(
                page,
                "3. SECTIONNET-PM (<0.2ms)",
                "Instant ACI 318-19 Concrete P-M Capacity Envelope & <span>6-DOF Winkler Soil Springs</span>",
                "Legacy Tools: <strong>Disconnected manual Excel spreadsheets and static tabular lookups</strong>",
            )

            # Open "4. DESIGN & OPTIMIZE" (x: 745, y: 35) -> Concrete Studio
            smooth_mouse_move(page, 960, 500, 745, 35, steps=15)
            page.mouse.click(745, 35)
            page.wait_for_timeout(800)

            click_flutter_element(page, "Concrete Studio", fallback_x=560, fallback_y=420)
            page.wait_for_timeout(1600)
            print("Concrete P-M Studio opened. Animating interaction curve...")

            # Toggle exposure button in Concrete Studio
            click_flutter_element(page, "WATER RETAINING", fallback_x=700, fallback_y=550)
            page.wait_for_timeout(800)

            page.keyboard.press("Escape")
            page.wait_for_timeout(600)

            # Open "2. LOADS & SUPPORTS" (x: 495, y: 35) -> Geotechnical Foundation
            smooth_mouse_move(page, 745, 35, 495, 35, steps=12)
            page.mouse.click(495, 35)
            page.wait_for_timeout(800)

            click_flutter_element(page, "Geotechnical Foundation", fallback_x=560, fallback_y=420)
            page.wait_for_timeout(1600)
            print("Geotechnical Foundation Studio displayed with Winkler soil springs.")

            page.keyboard.press("Escape")
            page.wait_for_timeout(600)

            # =================================================================
            # ACT 4 (21s – 28s) | Closed-Loop Multi-Agent Engineering Swarm
            # =================================================================
            print("\n>>> ACT 4: Closed-Loop Multi-Agent Engineering Swarm")
            update_overlay(
                page,
                "4. MULTI-AGENT SWARM",
                "Autonomous 4-Agent Swarm: <span>Architect &rarr; FEA Analyst &rarr; Auditor &rarr; Self-Healer</span>",
                "Legacy: <strong>Tedious manual member-by-member spot checking and trial-and-error resizing</strong>",
            )

            # Open 4. DESIGN & OPTIMIZE (x: 745, y: 35)
            smooth_mouse_move(page, 495, 35, 745, 35, steps=12)
            page.mouse.click(745, 35)
            page.wait_for_timeout(800)

            # Click Autonomous 4-Agent Engineering Swarm card
            click_flutter_element(page, "Autonomous 4-Agent Engineering Swarm", fallback_x=930, fallback_y=420)
            page.wait_for_timeout(2200)
            print("Autonomous Swarm converging across design space...")

            # Click Apply Swarm-Healed Topology to 3D Frame
            click_flutter_element(page, "APPLY SWARM-HEALED TOPOLOGY", fallback_x=1200, fallback_y=850)
            print("Applied swarm-healed framing to 3D canvas.")
            page.wait_for_timeout(1200)

            # =================================================================
            # ACT 5 (28s – 34s) | AI Section Auto-Sizer & Embodied Carbon LCA
            # =================================================================
            print("\n>>> ACT 5: AI Section Auto-Sizer & Embodied Carbon LCA")
            update_overlay(
                page,
                "5. AI AUTO-SIZER & CARBON LCA",
                "Automated Tonnage Optimization (<span>15&ndash;25% Steel Savings</span>) + Real-Time LEED CO&sub2;e",
                "Legacy: <strong>Static manual section catalog selection with zero embodied carbon awareness</strong>",
            )

            # Click "AI SECTION AUTO-SIZER" in FloatingTelemetryDock (x: 780, y: 1045)
            smooth_mouse_move(page, 960, 500, 780, 1045, steps=15)
            click_flutter_element(page, "AI SECTION AUTO-SIZER", fallback_x=780, fallback_y=1045)
            print("AI Section Auto-Sizer triggered: optimized W-sections into target DCR band.")
            page.wait_for_timeout(1500)

            # Open 5. REPORTS & BIM (x: 875, y: 35) -> Embodied Carbon LCA
            smooth_mouse_move(page, 780, 1045, 875, 35, steps=12)
            page.mouse.click(875, 35)
            page.wait_for_timeout(800)

            click_flutter_element(page, "Embodied Carbon Life-Cycle", fallback_x=190, fallback_y=550)
            page.wait_for_timeout(1800)
            print("Embodied Carbon LCA displayed: Recycled EAF vs Virgin BOF steel.")

            page.keyboard.press("Escape")
            page.wait_for_timeout(800)

            # =================================================================
            # ACT 6 (34s – 40s) | Stamped PE Packet & Zero Vendor Lock-In (s2k / IFC)
            # =================================================================
            print("\n>>> ACT 6: Stamped PE Packet, CSI ETABS (.s2k), IFC 4.3 & End Card")
            update_overlay(
                page,
                "6. ZERO VENDOR LOCK-IN",
                "SHA-256 Cryptographic PE Seal + <span>Lossless CSI ETABS (.s2k) & openBIM IFC 4.3</span>",
                "Legacy Vendors: <strong>Proprietary lock-in, non-interoperable files, and manual PDF stitching</strong>",
            )

            # Open 5. REPORTS & BIM (x: 875, y: 35) -> Stamped PE Calculation Packet
            smooth_mouse_move(page, 680, 38, 875, 35, steps=12)
            page.mouse.click(875, 35)
            page.wait_for_timeout(800)

            click_flutter_element(page, "Stamped PE Calculation Packet", fallback_x=190, fallback_y=420)
            page.wait_for_timeout(1800)
            print("PE Calculation Packet loaded with AISC 360-16 derivations and SHA-256 seal.")

            # Switch to BIM / ETABS tab
            click_flutter_element(page, "BIM: ETABS", fallback_x=600, fallback_y=250)
            page.wait_for_timeout(1000)

            # Switch to VERIFY PE SEAL tab
            click_flutter_element(page, "VERIFY PE SEAL", fallback_x=800, fallback_y=250)
            page.wait_for_timeout(1000)

            page.keyboard.press("Escape")
            page.wait_for_timeout(500)

            # Final 2.5-second Glassmorphic End Card
            print("Displaying 2.5-second Glassmorphic End Card...")
            show_end_card(page)
            page.wait_for_timeout(2700)

            # Close context and browser
            print("Closing browser and finalizing video capture...")
            context.close()
            browser.close()

    finally:
        server_proc.terminate()

    # Transcode WebM to 1080p 60 FPS MP4 via FFmpeg
    raw_videos = list(TEMP_VIDEO_DIR.glob("*.webm"))
    if not raw_videos:
        print("ERROR: No raw video recording found in /tmp/structura_raw_vid")
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

    print(f"\nSUCCESS! Showcase video successfully written to:\n{TARGET_MP4}")


if __name__ == "__main__":
    record_showcase()
