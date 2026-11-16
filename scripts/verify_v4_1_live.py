import asyncio
import os
import shutil
from playwright.async_api import async_playwright

ICLOUD_DIR = "/Users/aliasghar08/Library/Mobile Documents/com~apple~CloudDocs/Emulator Screenshots"
ARTIFACT_DIR = "/Users/aliasghar08/.gemini/antigravity/brain/32969de3-6721-4f26-b203-93de163f3031"

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            headless=True,
            executable_path="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            args=["--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"]
        )
        context = await browser.new_context(viewport={"width": 1440, "height": 900})
        page = await context.new_page()

        target_url = "https://structura-nexus.web.app"
        print(f"Navigating to {target_url}...")
        try:
            await page.goto(target_url, wait_until="networkidle", timeout=30000)
        except Exception:
            await page.goto(target_url, wait_until="load", timeout=30000)
        await asyncio.sleep(4.0)

        # 1. Capture workstation main view
        workstation_shot = os.path.join(ARTIFACT_DIR, "v4_1_01_workstation_ready.png")
        await page.screenshot(path=workstation_shot)
        print(f"Captured workstation: {workstation_shot}")

        # 2. Click AI & GEN dropdown in floating header (approx x: 505, y: 35)
        # Let's search by text or coordinates
        print("Clicking AI & GEN menu...")
        await page.mouse.click(505, 36)
        await asyncio.sleep(1.0)

        # Capture dropdown menu
        dropdown_shot = os.path.join(ARTIFACT_DIR, "v4_1_02_ai_gen_dropdown.png")
        await page.screenshot(path=dropdown_shot)
        print(f"Captured AI & GEN dropdown: {dropdown_shot}")

        # Click "Pareto Frontier (60 FPS)" (first or second item in dropdown around x: 505, y: 95)
        print("Clicking Pareto Frontier (60 FPS)...")
        await page.mouse.click(520, 110)
        await asyncio.sleep(1.5)

        # 3. Capture Pareto Frontier Dock
        pareto_shot = os.path.join(ARTIFACT_DIR, "v4_1_03_pareto_frontier_dock.png")
        await page.screenshot(path=pareto_shot)
        print(f"Captured Pareto Frontier Dock: {pareto_shot}")

        # Drag trade-off slider
        await page.mouse.move(700, 480)
        await page.mouse.down()
        await page.mouse.move(850, 480)
        await page.mouse.up()
        await asyncio.sleep(1.0)

        pareto_morphed_shot = os.path.join(ARTIFACT_DIR, "v4_1_04_pareto_morphed.png")
        await page.screenshot(path=pareto_morphed_shot)
        print(f"Captured Morphed Pareto Dock: {pareto_morphed_shot}")

        # Click "Commit Optimal Design" button (around x: 920, y: 645)
        await page.mouse.click(920, 645)
        await asyncio.sleep(1.5)

        # 4. Multi-Select Shift-drag on canvas to trigger marquee selection
        print("Performing Shift + Drag Marquee Selection...")
        await page.keyboard.down("Shift")
        await page.mouse.move(500, 300)
        await page.mouse.down()
        await page.mouse.move(800, 550)
        await page.mouse.up()
        await page.keyboard.up("Shift")
        await asyncio.sleep(1.5)

        batch_shot = os.path.join(ARTIFACT_DIR, "v4_1_05_batch_marquee_inspector.png")
        await page.screenshot(path=batch_shot)
        print(f"Captured Marquee Multi-Select & Batch Inspector: {batch_shot}")

        # 5. Open Tools Drawer and Mac-Trained AI Inspector to verify Active Learning Card
        print("Opening Drawer for Mac-Trained AI Inspector...")
        # Drawer hamburger icon is at top-left: x: 30, y: 35
        await page.mouse.click(30, 36)
        await asyncio.sleep(1.0)

        # Click Mac AI Inspector in Drawer (around x: 120, y: 360)
        await page.mouse.click(140, 365)
        await asyncio.sleep(2.0)

        mac_ai_shot = os.path.join(ARTIFACT_DIR, "v4_1_06_mac_ai_active_learning_card.png")
        await page.screenshot(path=mac_ai_shot)
        print(f"Captured Mac AI Active Learning Card: {mac_ai_shot}")

        # Copy to iCloud
        if os.path.exists(ICLOUD_DIR):
            for src, name in [
                (workstation_shot, "structura_nexus_v4_1_01_workstation.png"),
                (pareto_shot, "structura_nexus_v4_1_02_pareto_frontier_dock.png"),
                (pareto_morphed_shot, "structura_nexus_v4_1_03_pareto_morphed.png"),
                (batch_shot, "structura_nexus_v4_1_04_batch_marquee_inspector.png"),
                (mac_ai_shot, "structura_nexus_v4_1_05_mac_ai_active_learning.png"),
            ]:
                dst = os.path.join(ICLOUD_DIR, name)
                shutil.copyfile(src, dst)
            print(f"All verification screenshots successfully copied to iCloud: {ICLOUD_DIR}")

        await browser.close()
        print("Playwright live verification completed successfully!")

if __name__ == "__main__":
    asyncio.run(main())

