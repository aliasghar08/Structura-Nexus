"""
STRUCTURA NEXUS v4.2.1 — SHOWCASE REEL & KEYFRAME GENERATOR
Automates 1080p Playwright capture of all v4.2.1 civil integrity and frontier engineering milestones:
1. 12-DOF Direct Stiffness 3D Viewport
2. Member End Releases & ACI 318-19 Cracked Modifiers in Selection Inspector & 3D WebGL Glyphs
3. Proprietary Concrete Studio with ACI 318-19 §24.3.2 Crack Control & Gergely-Lutz wk
4. Cryptographic PE Calculation Seal Auditor & HMAC-SHA256 Tamper Detection
5. Frontier AI & Generative Suite Menu
6. Generative 3D Diagrid Topology Synthesizer
7. Committed 3D Diagrid Exoskeleton in Viewport
8. Shop-Drawing QA Moment End-Plate (AISC J Pass)
9. Shop-Drawing QA Defect Callout & AISC J3.4 Punchlist
10. Gemini Live Spatial Voice Co-Pilot Floating Pill
11. 3D Viewport Voice Emissive Member Highlights
12. WebGPU 60 FPS Pareto Frontier HUD
13. Apple Silicon MPS Active Learning Card & 10 Surrogates
Compiles docs/Structura_Nexus_v4_2_Showcase.mp4 with ffmpeg at 1080p 60 FPS.
"""

import os
import sys
import time
import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BUILD_WEB = REPO_ROOT / "structura_nexus" / "build" / "web"
DOCS_DIR = REPO_ROOT / "docs"
SCREENSHOTS_DIR = DOCS_DIR / "screenshots"
ICLOUD_DIR = Path("/Users/aliasghar08/Library/Mobile Documents/com~apple~CloudDocs/Emulator Screenshots")
ARTIFACTS_DIR = Path("/Users/aliasghar08/.gemini/antigravity/brain/32969de3-6721-4f26-b203-93de163f3031")

SCREENSHOTS_DIR.mkdir(parents=True, exist_ok=True)
if ICLOUD_DIR.exists():
    ICLOUD_DIR.mkdir(parents=True, exist_ok=True)


def run_showcase_capture():
    from playwright.sync_api import sync_playwright

    print("======================================================================")
    print(" STRUCTURA NEXUS v4.2.1 — SHOWCASE REEL KEYFRAME GENERATION")
    print("======================================================================")

    port = 5058
    server_proc = subprocess.Popen(
        [sys.executable, "-m", "http.server", str(port), "--directory", str(BUILD_WEB)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    time.sleep(1.5)

    captured_files = []

    try:
        with sync_playwright() as p:
            chrome_path = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
            browser = p.chromium.launch(
                headless=True,
                executable_path=chrome_path if os.path.exists(chrome_path) else None,
                args=["--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"],
            )
            page = browser.new_page(viewport={"width": 1920, "height": 1080}, device_scale_factor=1.0)

            print(f"Loading Structura Nexus at http://localhost:{port}/#/")
            page.goto(f"http://localhost:{port}/#/", wait_until="networkidle")
            page.wait_for_timeout(4500)

            def save_frame(frame_id, title):
                print(f"  • Captured: {title} ({frame_id}.png)")
                out_repo = SCREENSHOTS_DIR / f"{frame_id}.png"
                page.screenshot(path=str(out_repo))
                captured_files.append(out_repo)

                if ICLOUD_DIR.exists():
                    out_icloud = ICLOUD_DIR / f"{frame_id}.png"
                    shutil.copyfile(str(out_repo), str(out_icloud))

                if ARTIFACTS_DIR.exists():
                    out_art = ARTIFACTS_DIR / f"{frame_id}.png"
                    shutil.copyfile(str(out_repo), str(out_art))

            # 1. Main Viewport & Direct Stiffness Matrix State
            save_frame("v4_2_01_workstation_ready_3d", "12-DOF Direct Stiffness 3D Viewport")

            # 2. Select Member M1 and Toggle Member End Releases & Cracked Stiffness
            print("Selecting member M1 in viewport & opening Floating Inspector Panel...")
            page.evaluate("""
                window.dispatchEvent(new CustomEvent('structura-member-selected', { detail: { memberId: 'M1' } }));
            """)
            page.wait_for_timeout(1200)

            # In FloatingInspectorPanel (docked on right around x: 1720, y: 350-550):
            # Click "Start Mz" pill (approx x: 1680, y: 550) or locate text
            print("Toggling Start Mz release and ACI Beam (0.35 Ig) cracked stiffness...")
            try:
                start_mz_btn = page.get_by_text("Start Mz", exact=True)
                if start_mz_btn.count() > 0:
                    start_mz_btn.first.click()
                    page.wait_for_timeout(500)
                
                end_mz_btn = page.get_by_text("End Mz", exact=True)
                if end_mz_btn.count() > 0:
                    end_mz_btn.first.click()
                    page.wait_for_timeout(500)

                beam_crack_btn = page.get_by_text("ACI Beam (0.35 Ig)", exact=False)
                if beam_crack_btn.count() > 0:
                    beam_crack_btn.first.click()
                    page.wait_for_timeout(800)
            except Exception as e:
                print(f"Note on inspector interaction: {e}")

            save_frame("v4_2_02_member_releases_and_cracked_stiffness_inspector", "Member End Releases & ACI 318-19 Cracked Modifiers")

            # Deselect member
            page.evaluate("""
                window.dispatchEvent(new CustomEvent('structura-multi-selected', { detail: { nodeIds: [], memberIds: [] } }));
            """)
            page.wait_for_timeout(800)

            # 3. Open Concrete Studio (ACI 318-19 Crack Control)
            print("Opening TOOLS & SUITE Drawer to launch Concrete Studio...")
            page.mouse.click(35, 38)
            page.wait_for_timeout(1000)

            # Click Concrete Studio (around x: 140, y: 220)
            concrete_item = page.get_by_text("Concrete Studio", exact=False)
            if concrete_item.count() > 0:
                concrete_item.first.click()
            else:
                page.mouse.click(140, 220)
            page.wait_for_timeout(2000)

            # Toggle Exposure Condition to Water Retaining in Concrete Studio
            water_btn = page.get_by_text("WATER RETAINING", exact=True)
            if water_btn.count() > 0:
                water_btn.first.click()
                page.wait_for_timeout(800)

            save_frame("v4_2_03_concrete_crack_serviceability_studio", "Proprietary Concrete Studio (ACI 318-19 & ACI 224R Crack Control)")
            page.keyboard.press("Escape")
            page.wait_for_timeout(800)

            # 4. Open PE Calculation Packet & Digital Seal Verifier
            print("Opening PE Calculation Packet & Digital Seal Auditor...")
            page.mouse.click(35, 38)
            page.wait_for_timeout(1000)
            pe_item = page.get_by_text("PE Calcs & BIM", exact=False)
            if pe_item.count() > 0:
                pe_item.first.click()
            else:
                page.mouse.click(140, 290)
            page.wait_for_timeout(2000)

            # Switch to "VERIFY PE SEAL" tab
            verify_tab = page.get_by_text("VERIFY PE SEAL", exact=True)
            if verify_tab.count() > 0:
                verify_tab.first.click()
                page.wait_for_timeout(1000)

            # Click LOAD CURRENT PACKET button
            load_btn = page.get_by_text("LOAD CURRENT PACKET", exact=True)
            if load_btn.count() > 0:
                load_btn.first.click()
                page.wait_for_timeout(1500)

            save_frame("v4_2_04_pe_packet_hmac_seal_auditor", "Cryptographic PE Calculation Seal Auditor & HMAC-SHA256 Interlock")
            page.keyboard.press("Escape")
            page.wait_for_timeout(800)

            # 5. Click "AI & GEN" in floating header
            print("Opening AI & GEN dropdown menu...")
            page.mouse.click(670, 38)
            page.wait_for_timeout(1000)
            save_frame("v4_2_05_ai_generative_menu", "Frontier AI & Generative Suite Menu")

            # 6. Click "3D Topology Synthesizer (Neural SIMP)" (second item in menu: x: 670, y: 155)
            print("Opening 3D Topology Synthesizer...")
            page.mouse.click(670, 155)
            page.wait_for_timeout(1500)
            save_frame("v4_2_06_generative_3d_topology_synthesizer", "Generative 3D Diagrid Topology Synthesizer")

            # 7. Click "Commit Exoskeleton to Viewport" (bottom right of dialog: x: 1250, y: 885)
            print("Committing Exoskeleton to Viewport...")
            page.mouse.click(1250, 885)
            page.wait_for_timeout(2000)
            save_frame("v4_2_07_topology_exoskeleton_committed_3d", "Committed 3D Diagrid Exoskeleton in Viewport")

            # 8. Open Shop-Drawing & Site QA (click AI & GEN at 670, 38 then item 3 at 670, 205)
            print("Opening Shop-Drawing & Site Connection Visual QA Auditor...")
            page.mouse.click(670, 38)
            page.wait_for_timeout(800)
            page.mouse.click(670, 205)
            page.wait_for_timeout(1500)
            save_frame("v4_2_08_shop_drawing_visual_qa_moment", "Shop-Drawing QA Moment End-Plate (AISC J Pass)")

            # 9. Switch to Baseplate & Anchors preset in Shop Drawing Dialog (tab 2: x: 960, y: 245)
            print("Switching to Baseplate & Anchors Defect preset...")
            page.mouse.click(960, 245)
            page.wait_for_timeout(1200)
            save_frame("v4_2_09_shop_drawing_visual_qa_baseplate_defect", "Shop-Drawing QA Defect Callout & AISC J3.4 Punchlist")

            # Close dialog (close button top-right: x: 1350, y: 195)
            page.mouse.click(1350, 195)
            page.wait_for_timeout(800)

            # 10. Expand Gemini Live Spatial Voice Co-Pilot pill (bottom right: pill is at x: 1880, y: 970)
            print("Expanding Gemini Live Spatial Voice Co-Pilot Pill...")
            page.mouse.click(1880, 970)
            page.wait_for_timeout(800)
            save_frame("v4_2_10_live_spatial_voice_copilot_tray", "Gemini Live Spatial Voice Co-Pilot Floating Pill")

            # 11. Trigger "Highlight columns with DCR above 0.85" quick chip (around x: 1720, y: 1045)
            print("Triggering Voice Critical Emissive Highlights...")
            page.mouse.click(1720, 1045)
            page.wait_for_timeout(1200)
            save_frame("v4_2_11_voice_emissive_critical_highlights_3d", "3D Viewport Voice Emissive Member Highlights")

            # 12. Open Pareto Frontier (60 FPS) Dock (AI & GEN -> item 4: x: 670, y: 255)
            print("Opening WebGPU Pareto Frontier Dock...")
            page.mouse.click(670, 38)
            page.wait_for_timeout(800)
            page.mouse.click(670, 255)
            page.wait_for_timeout(1500)
            page.mouse.move(800, 550)
            page.mouse.down()
            page.mouse.move(1050, 550)
            page.mouse.up()
            page.wait_for_timeout(1000)
            save_frame("v4_2_12_webgpu_pareto_frontier_hud", "WebGPU 60 FPS Pareto Frontier HUD")

            # Close Pareto dock (x: 1220, y: 395)
            page.mouse.click(1220, 395)
            page.wait_for_timeout(800)

            # 13. Open Mac AI Surrogates & Active Learning Card (top-left hamburger drawer x: 35, y: 38)
            print("Opening Mac AI Surrogates dialog...")
            page.mouse.click(35, 38)
            page.wait_for_timeout(1000)
            page.mouse.click(140, 365)
            page.wait_for_timeout(1500)
            save_frame("v4_2_13_mac_mps_active_learning_card", "Apple Silicon MPS Active Learning Card & 10 Surrogates")

            browser.close()

    finally:
        server_proc.terminate()

    print(f"\nCaptured {len(captured_files)} 1080p keyframes successfully.")
    compile_mp4_showcase(captured_files)


def compile_mp4_showcase(image_files):
    mp4_out = DOCS_DIR / "Structura_Nexus_v4_2_Showcase.mp4"
    ffmpeg_bin = "/opt/homebrew/bin/ffmpeg"
    if not os.path.exists(ffmpeg_bin):
        ffmpeg_bin = shutil.which("ffmpeg")

    if not ffmpeg_bin:
        print("Warning: ffmpeg not found. Skipping MP4 compilation.")
        return

    print("\nStitching video with FFmpeg -> docs/Structura_Nexus_v4_2_Showcase.mp4")

    concat_list = DOCS_DIR / "ffmpeg_input.txt"
    with open(concat_list, "w") as f:
        for img in image_files:
            f.write(f"file '{img.resolve()}'\n")
            f.write("duration 3.5\n")
        if image_files:
            f.write(f"file '{image_files[-1].resolve()}'\n")

    cmd = [
        ffmpeg_bin,
        "-y",
        "-f", "concat",
        "-safe", "0",
        "-i", str(concat_list),
        "-vf", "scale=1920:1080,fps=60,format=yuv420p",
        "-c:v", "libx264",
        "-crf", "18",
        "-preset", "slow",
        "-an",
        str(mp4_out),
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode == 0:
        size_mb = mp4_out.stat().st_size / (1024 * 1024)
        print(f"Video created successfully: {mp4_out} ({size_mb:.2f} MB)")
        if ICLOUD_DIR.exists():
            shutil.copyfile(str(mp4_out), str(ICLOUD_DIR / "Structura_Nexus_v4_2_Showcase.mp4"))
            print("Copied showcase video to iCloud Emulator Screenshots directory.")
    else:
        print(f"FFmpeg error: {res.stderr.decode('utf-8', errors='ignore')[:300]}")


if __name__ == "__main__":
    run_showcase_capture()
