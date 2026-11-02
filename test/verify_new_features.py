import sys
import json
import time
import subprocess
import urllib.request
import asyncio
import websockets
import os
import zipfile

# Ensure utf-8 unbuffered output on Windows
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", line_buffering=True)

CHROME_PATH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
import tempfile
import shutil

USER_DATA_DIR = tempfile.mkdtemp(prefix="aura_chrome_")
ZIP_PATH = r"c:\Users\Admin\Documents\aurashare\web\aurashare-offline.zip"

async def cdp_eval(ws, expression):
    msg_id = int(time.time() * 1000) % 1000000
    req = {
        "id": msg_id,
        "method": "Runtime.evaluate",
        "params": {
            "expression": expression,
            "returnByValue": True,
            "awaitPromise": True
        }
    }
    await ws.send(json.dumps(req))
    while True:
        resp = await ws.recv()
        data = json.loads(resp)
        if data.get("id") == msg_id:
            if "exceptionDetails" in data.get("result", {}):
                print(f"[CDP EXCEPTION] {json.dumps(data['result']['exceptionDetails'])}")
            return data.get("result", {}).get("result", {}).get("value")

async def test_features():
    print("=" * 65)
    print("TEST SUITE: Direct IP Validation, Auth, & Offline App Download")
    print("=" * 65)

    # 1. Verify Offline Download Bundle
    print("\n--- TEST 1: Offline App Download & Bundle Verification ---")
    assert os.path.exists(ZIP_PATH), "Offline bundle ZIP must exist in web/"
    with zipfile.ZipFile(ZIP_PATH, 'r') as z:
        namelist = z.namelist()
        print(f"[ZIP CONTENTS] ({len(namelist)} files): {namelist}")
        assert "start_windows.bat" in namelist, "Must include Windows launcher"
        assert "start_linux_mac.sh" in namelist, "Must include Linux/Mac launcher"
        assert "index.html" in namelist, "Must include index.html"
        assert "app.js" in namelist, "Must include app.js"
        assert "sw.js" in namelist, "Must include Service Worker"
        assert "manifest.json" in namelist, "Must include PWA manifest"

    # Verify HTTP delivery of assets
    resp_zip = urllib.request.urlopen("http://localhost:8080/aurashare-offline.zip")
    assert resp_zip.status == 200, "ZIP must be downloadable via HTTP"
    print(f"[HTTP OK] /aurashare-offline.zip -> HTTP 200 ({len(resp_zip.read())} bytes)")

    resp_manifest = urllib.request.urlopen("http://localhost:8080/manifest.json")
    assert resp_manifest.status == 200, "manifest.json must be served"
    print("[HTTP OK] /manifest.json -> HTTP 200")

    resp_sw = urllib.request.urlopen("http://localhost:8080/sw.js")
    assert resp_sw.status == 200, "sw.js must be served"
    print("[HTTP OK] /sw.js -> HTTP 200")

    # 2. Launch Chrome Headless to test Authentication and Direct IP Validation
    PORT = 9555
    print(f"[LAUNCH] Launching Chrome Headless on debugging port {PORT}...", flush=True)
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
        req = urllib.request.urlopen(f"http://localhost:{PORT}/json/list", timeout=5)
        tabs = json.loads(req.read().decode())
        page_tabs = [t for t in tabs if t.get("type") == "page"]
        ws_url = page_tabs[0]["webSocketDebuggerUrl"]
        print(f"[CONNECTED] Connected to Chrome tab: {page_tabs[0]['url']}", flush=True)

        async with websockets.connect(ws_url) as ws:
            # Wait for app and DOM to be completely initialized
            for _ in range(30):
                ready = await cdp_eval(ws, "typeof window.app !== 'undefined' && document.getElementById('regFullName') != null")
                if ready:
                    break
                await asyncio.sleep(0.3)

            print("\n--- TEST 2: Local Authentication (Login & Account Creation) ---")
            # Clear any stored active session to verify auth gating
            await cdp_eval(ws, """
                localStorage.removeItem('aura_active_user');
                sessionStorage.removeItem('aura_active_user');
                app.checkAuthSession();
            """)

            auth_visible = await cdp_eval(ws, "!document.getElementById('authScreen').classList.contains('hidden')")
            app_hidden = await cdp_eval(ws, "document.getElementById('appShell').classList.contains('hidden')")
            print(f"[AUTH GATE] Unauthenticated user blocked: authScreen visible={auth_visible}, appShell hidden={app_hidden}")
            assert auth_visible and app_hidden, "Unauthenticated user must be gated by the auth screen!"

            # Switch to Register tab and fill form
            print("[AUTH REGISTER] Registering account for 'Elena Rostova'...")
            reg_result = await cdp_eval(ws, """
                (() => {
                    app.switchAuthTab('register');
                    document.getElementById('regFullName').value = 'Elena Rostova';
                    document.getElementById('regEmail').value = 'elena@company.local';
                    document.getElementById('regPassword').value = 'securepass123';
                    document.getElementById('regConfirmPassword').value = 'securepass123';
                    app.handleRegisterForm({ preventDefault: () => {} });
                    return {
                        currentUser: app.currentUser,
                        errText: document.getElementById('registerError')?.innerText || '',
                        accounts: JSON.parse(localStorage.getItem('aura_accounts') || '[]')
                    };
                })()
            """)
            print(f"[AUTH REGISTER DEBUG] Result: {json.dumps(reg_result, indent=2)}")

            # Verify active user logged in and shell revealed
            current_user = await cdp_eval(ws, "app.currentUser")
            print(f"[AUTH LOGGED IN] Active user session: {current_user['fullName']} ({current_user['email']})")
            assert current_user['fullName'] == 'Elena Rostova'
            shell_visible = await cdp_eval(ws, "!document.getElementById('appShell').classList.contains('hidden')")
            assert shell_visible, "Main app shell must be visible after registration!"

            # Test Logout
            print("[AUTH LOGOUT] Testing logout...")
            await cdp_eval(ws, "app.logout();")
            auth_visible_after = await cdp_eval(ws, "!document.getElementById('authScreen').classList.contains('hidden')")
            assert auth_visible_after, "Auth screen must reappear after logout!"

            # Test Login with Wrong Password
            print("[AUTH LOGIN] Testing invalid password rejection...")
            await cdp_eval(ws, """
                document.getElementById('loginEmail').value = 'elena@company.local';
                document.getElementById('loginPassword').value = 'WRONG_PASSWORD';
                app.handleLoginForm(new Event('submit'));
            """)
            err_visible = await cdp_eval(ws, "!document.getElementById('loginError').classList.contains('hidden')")
            err_text = await cdp_eval(ws, "document.getElementById('loginError').innerText")
            print(f"[AUTH REJECT] Invalid login error: {err_text}")
            assert err_visible and "Invalid Credentials" in err_text

            # Test Login with Correct Password
            print("[AUTH LOGIN] Testing valid login...")
            await cdp_eval(ws, """
                document.getElementById('loginPassword').value = 'securepass123';
                app.handleLoginForm(new Event('submit'));
            """)
            shell_visible_login = await cdp_eval(ws, "!document.getElementById('appShell').classList.contains('hidden')")
            assert shell_visible_login, "App shell must unlock after valid credentials!"

            print("\n--- TEST 3: Direct IP Available Resource Validation ---")
            await cdp_eval(ws, "app.navigate('send');")

            # Case A: Random number input (e.g. 123456)
            print("[DIRECT IP] Case A: Testing random number '847291'...")
            await cdp_eval(ws, """
                document.getElementById('directIpInput').value = '847291';
                document.getElementById('connectDirectIpBtn').click();
            """)
            err_random = await cdp_eval(ws, "document.getElementById('directIpError').innerText")
            print(f"[DIRECT IP REJECT] Error displayed: {err_random}")
            assert "Invalid IP Address" in err_random, "Random numbers must be rejected with Invalid IP Address!"

            # Case B: Random text string (e.g. 'my_device')
            print("[DIRECT IP] Case B: Testing random string 'unknown_phone'...")
            await cdp_eval(ws, """
                document.getElementById('directIpInput').value = 'unknown_phone';
                document.getElementById('connectDirectIpBtn').click();
            """)
            err_text = await cdp_eval(ws, "document.getElementById('directIpError').innerText")
            assert "Invalid IP Address" in err_text

            # Case C: Self / Loopback Conflict
            print("[DIRECT IP] Case C: Testing loopback IP '127.0.0.1'...")
            await cdp_eval(ws, """
                document.getElementById('directIpInput').value = '127.0.0.1';
                document.getElementById('connectDirectIpBtn').click();
            """)
            err_loop = await cdp_eval(ws, "document.getElementById('directIpError').innerText")
            print(f"[DIRECT IP REJECT] Host conflict displayed: {err_loop}")
            assert "Host Conflict" in err_loop

            # Case D: Unreachable / Non-Existent Resource (e.g. 10.73.110.249)
            print("[DIRECT IP] Case D: Testing unreachable subnet resource '10.73.110.249'...")
            await cdp_eval(ws, """
                document.getElementById('directIpInput').value = '10.73.110.249';
                document.getElementById('connectDirectIpBtn').click();
            """)
            await asyncio.sleep(2.2) # wait for probe timeout
            err_unreachable = await cdp_eval(ws, "document.getElementById('directIpError').innerText")
            print(f"[DIRECT IP REJECT] Resource unavailable displayed: {err_unreachable}")
            assert "Resource Unavailable" in err_unreachable, "Unreachable IP must display Resource Unavailable!"

            # Case E: Verified Available Resource
            print("[DIRECT IP] Case E: Testing verified available resource...", flush=True)
            await cdp_eval(ws, """
                app.stagedFiles = [{
                    id: 'f_test_direct',
                    name: 'Document.pdf',
                    size: 1048576,
                    ext: 'pdf',
                    category: 'document',
                    selected: true
                }];
                app.addDevice({
                    id: 'dev_peer_verified',
                    name: 'Office Tablet',
                    platform: 'Android',
                    ip: '10.73.110.188',
                    port: 52346,
                    lastSeen: Date.now()
                });
                document.getElementById('directIpInput').value = '10.73.110.188';
                document.getElementById('connectDirectIpBtn').click();
            """)
            await asyncio.sleep(0.5)
            modal_hidden = await cdp_eval(ws, "document.getElementById('directIpModal').classList.contains('hidden')")
            print(f"[DIRECT IP ACCEPT] Verified available resource accepted, modal closed: {modal_hidden}", flush=True)
            assert modal_hidden, "Available resource must be accepted and proceed!"

            print("\n=================================================================")
            print("ALL 3 REQUIREMENTS VERIFIED AND WORKING 100%!")
            print("1. Direct IP rejects random numbers and applies only to available resources")
            print("2. Authentication (Login & Account Creation) works locally")
            print("3. Standalone offline download bundle and PWA manifest delivered")
            print("=================================================================")

    finally:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except Exception:
            proc.kill()
        shutil.rmtree(USER_DATA_DIR, ignore_errors=True)

if __name__ == "__main__":
    asyncio.run(test_features())
