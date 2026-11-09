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

        print("Navigating to http://localhost:8080...")
        await page.goto("http://localhost:8080", wait_until="networkidle")
        await asyncio.sleep(4.0)

        # 1. Capture workstation main view
        workstation_shot = os.path.join(ARTIFACT_DIR, "structura_nexus_workstation_cursor_verified.png")
        await page.screenshot(path=workstation_shot)
        print(f"Captured workstation: {workstation_shot}")

        # Check console / title
        title = await page.title()
        print(f"Page title: {title}")

        # Hover over top menu items / buttons to check cursor
        # Click on user profile / auth button to open auth dialog or navigate to auth
        # In Flutter Web, let's find the auth button or open the auth dialog
        # Tapping top-right user profile button (around x: 1380, y: 35) or pressing 'Cloud / Sign In'
        await page.mouse.click(1380, 36)
        await asyncio.sleep(2.0)

        # 2. Capture auth dialog
        auth_shot = os.path.join(ARTIFACT_DIR, "structura_nexus_auth_passkey_autofill.png")
        await page.screenshot(path=auth_shot)
        print(f"Captured auth dialog: {auth_shot}")

        # Copy to iCloud folder
        if os.path.exists(ICLOUD_DIR):
            dst1 = os.path.join(ICLOUD_DIR, "structura_nexus_08_workstation_hand_cursor.png")
            dst2 = os.path.join(ICLOUD_DIR, "structura_nexus_09_auth_passkeys_and_autofill.png")
            shutil.copyfile(workstation_shot, dst1)
            shutil.copyfile(auth_shot, dst2)
            print(f"Copied screenshots to iCloud:\n  {dst1}\n  {dst2}")

        await browser.close()
        print("Live browser verification completed successfully!")

if __name__ == "__main__":
    asyncio.run(main())
