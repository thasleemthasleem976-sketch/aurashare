import sys
import json
import urllib.request
import asyncio
import websockets
import subprocess
import time
import os
import shutil

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

CHROME_PATH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
USER_DATA_DIR = r"c:\Users\Admin\Documents\aurashare\.tmp_chrome_verify"
PORT = 9444

async def cdp_eval(ws, expression, return_by_value=True):
    msg_id = int(time.time() * 1000) % 1000000
    req = {
        "id": msg_id,
        "method": "Runtime.evaluate",
        "params": {
            "expression": expression,
            "returnByValue": return_by_value,
            "awaitPromise": True
        }
    }
    await ws.send(json.dumps(req))
    while True:
        resp = await ws.recv()
        data = json.loads(resp)
        if data.get("id") == msg_id:
            return data.get("result", {}).get("result", {}).get("value")

async def run_feature_tests():
    print("=" * 65)
    print(" AURASHARE NEW FEATURES VERIFICATION TEST SUITE")
    print("=" * 65)

    # 1. Verify Downloadable Package & PWA endpoints
    print("\n[TEST 1] Verifying Offline Package & PWA Assets on HTTP Server...")
    zip_resp = urllib.request.urlopen("http://localhost:8080/downloads/AuraShare-Offline-App.zip")
    assert zip_resp.status == 200, "Download ZIP must return 200"
    zip_bytes = len(zip_resp.read())
    print(f"  -> AuraShare-Offline-App.zip HTTP 200 OK (Size: {zip_bytes} bytes)")

    manifest_resp = urllib.request.urlopen("http://localhost:8080/manifest.json")
    assert manifest_resp.status == 200, "manifest.json must return 200"
    print("  -> manifest.json HTTP 200 OK (PWA Ready)")

    sw_resp = urllib.request.urlopen("http://localhost:8080/service-worker.js")
    assert sw_resp.status == 200, "service-worker.js must return 200"
    print("  -> service-worker.js HTTP 200 OK (Cache Engine Active)")

    # 2. Verify Probe API Endpoint
    print("\n[TEST 2] Verifying /api/probe endpoint for available resources...")
    probe_bad = json.loads(urllib.request.urlopen("http://localhost:8080/api/probe?ip=192.0.2.1&port=52346").read().decode())
    print(f"  -> Probe unreachable IP (192.0.2.1): available = {probe_bad.get('available')}")
    assert probe_bad.get("available") is False

    probe_good = json.loads(urllib.request.urlopen("http://localhost:8080/api/probe?ip=127.0.0.1&port=8080").read().decode())
    print(f"  -> Probe active port 8080: available = {probe_good.get('available')}")
    assert probe_good.get("available") is True

    # 3. Launch Chrome Headless to test UI Direct IP & Auth
    if os.path.exists(USER_DATA_DIR):
        try: shutil.rmtree(USER_DATA_DIR)
        except Exception: pass

    print(f"\n[TEST 3] Launching Chrome Headless on debugging port {PORT}...")
    proc = subprocess.Popen([
        CHROME_PATH,
        "--headless=new",
        f"--remote-debugging-port={PORT}",
        f"--user-data-dir={USER_DATA_DIR}",
        "--no-first-run",
        "--no-default-browser-check",
        "http://localhost:8080"
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    time.sleep(2.5)

    try:
        req = urllib.request.urlopen(f"http://localhost:{PORT}/json/list")
        tabs = json.loads(req.read().decode())
        page_tabs = [t for t in tabs if t.get("type") == "page"]
        ws_url = page_tabs[0]["webSocketDebuggerUrl"]

        async with websockets.connect(ws_url) as ws:
            # Wait for app
            for _ in range(20):
                ready = await cdp_eval(ws, "typeof window.app !== 'undefined'")
                if ready: break
                await asyncio.sleep(0.2)

            # Test 3A: Authentication Overlay Display when not logged in
            print("\n[TEST 3A] Verifying Local Auth Protection & Modal Overlay...")
            auth_visible = await cdp_eval(ws, "!document.getElementById('authModalOverlay').classList.contains('hidden')")
            print(f"  -> Auth Overlay visible for unauthenticated visitor: {auth_visible}")
            assert auth_visible is True, "Auth overlay must be visible when not logged in"

            # Test 3B: Register a new user
            print("\n[TEST 3B] Registering new local user account...")
            await cdp_eval(ws, """
                document.getElementById('regFullName').value = 'Test User';
                document.getElementById('regEmail').value = 'test.user@aurashare.local';
                document.getElementById('regDeviceName').value = "Test User's Laptop";
                document.getElementById('regPassword').value = 'securepass123';
                document.getElementById('regConfirmPassword').value = 'securepass123';
                app.handleRegister();
            """)
            await asyncio.sleep(0.5)

            current_user = await cdp_eval(ws, "app.user.name")
            auth_hidden_after_reg = await cdp_eval(ws, "document.getElementById('authModalOverlay').classList.contains('hidden')")
            print(f"  -> Registered and logged in as: '{current_user}', Auth overlay hidden: {auth_hidden_after_reg}")
            assert current_user == "Test User"
            assert auth_hidden_after_reg is True

            # Test 3C: Logout
            print("\n[TEST 3C] Testing user logout...")
            await cdp_eval(ws, """
                app.authSession = null;
                localStorage.removeItem('aura_auth_session');
                app.checkAuth();
            """)
            await asyncio.sleep(0.3)
            auth_reappeared = await cdp_eval(ws, "!document.getElementById('authModalOverlay').classList.contains('hidden')")
            print(f"  -> Auth overlay reappeared on logout: {auth_reappeared}")
            assert auth_reappeared is True

            # Test 3D: Login with registered account
            print("\n[TEST 3D] Logging in with created credentials...")
            await cdp_eval(ws, """
                document.getElementById('loginEmail').value = 'test.user@aurashare.local';
                document.getElementById('loginPassword').value = 'securepass123';
                app.handleLogin();
            """)
            await asyncio.sleep(0.3)
            logged_in_name = await cdp_eval(ws, "app.user.name")
            print(f"  -> Successfully logged in as: '{logged_in_name}'")
            assert logged_in_name == "Test User"

            # Test 4: Direct IP Random Number Validation
            print("\n[TEST 4] Testing Direct IP Validation & Available Resource Probing...")
            await cdp_eval(ws, "app.navigate('send');")

            # 4A: Random Number Input (e.g. "987654321")
            print("  -> Opening Direct IP dialog and submitting random number '987654321'...")
            await cdp_eval(ws, """
                document.getElementById('sendDirectIpBtn').click();
                document.getElementById('directIpInput').value = '987654321';
                document.getElementById('connectDirectIpBtn').click();
            """)
            await asyncio.sleep(0.3)

            error_msg = await cdp_eval(ws, "document.getElementById('directIpStatus').innerText")
            has_error = await cdp_eval(ws, "document.getElementById('directIpStatus').classList.contains('error')")
            modal_still_open = await cdp_eval(ws, "!document.getElementById('directIpModal').classList.contains('hidden')")

            print(f"  -> Validation result: has_error = {has_error}, msg = '{error_msg}'")
            print(f"  -> Modal blocked random number: {modal_still_open}")
            assert has_error is True, "Random number must trigger validation error"
            assert modal_still_open is True, "Modal must remain open with error message"

            # 4B: Unreachable IP (e.g. 192.0.2.55)
            print("  -> Submitting unreachable IP '192.0.2.55'...")
            await cdp_eval(ws, """
                document.getElementById('directIpInput').value = '192.0.2.55';
                document.getElementById('connectDirectIpBtn').click();
            """)
            await asyncio.sleep(2.0)

            probe_error_msg = await cdp_eval(ws, "document.getElementById('directIpStatus').innerText")
            print(f"  -> Probe result: '{probe_error_msg}'")
            assert "unavailable" in probe_error_msg.lower() or "not reachable" in probe_error_msg.lower()

            print("\n" + "=" * 65)
            print(" ALL FEATURE VERIFICATIONS PASSED 100%!")
            print("=" * 65)

    finally:
        proc.terminate()
        try: proc.wait(timeout=3)
        except Exception: proc.kill()
        if os.path.exists(USER_DATA_DIR):
            try: shutil.rmtree(USER_DATA_DIR)
            except Exception: pass

if __name__ == "__main__":
    asyncio.run(run_feature_tests())
