import sys
import json
import time
import subprocess
import urllib.request
import asyncio
import websockets
import os
import shutil

# Ensure utf-8 output on Windows
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")

CHROME_PATH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
USER_DATA_DIR = r"c:\Users\Admin\Documents\aurashare\.tmp_chrome_e2e"

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

async def run_e2e_test():
    if os.path.exists(USER_DATA_DIR):
        try:
            shutil.rmtree(USER_DATA_DIR)
        except Exception:
            pass

    # 1. Start Chrome Headless with Remote Debugging on a clean custom port (9333)
    PORT = 9333
    print(f"[STEP 1] Starting Chrome in Headless Mode with Remote Debugging on port {PORT}...")
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
        # 2. Get Tab 1 (Sender)
        req = urllib.request.urlopen(f"http://localhost:{PORT}/json/list")
        tabs = json.loads(req.read().decode())
        page_tabs = [t for t in tabs if t.get("type") == "page"]
        tab1_ws_url = page_tabs[0]["webSocketDebuggerUrl"]
        print(f"[SUCCESS] Tab 1 (Sender) connected: {page_tabs[0]['title']} ({page_tabs[0]['url']})")

        # 3. Open Tab 2 (Receiver)
        new_tab_req = urllib.request.Request(f"http://localhost:{PORT}/json/new?http://localhost:8080", method="PUT")
        tab2_meta = json.loads(urllib.request.urlopen(new_tab_req).read().decode())
        tab2_ws_url = tab2_meta["webSocketDebuggerUrl"]
        print(f"[SUCCESS] Tab 2 (Receiver) opened: {tab2_meta['id']} ({tab2_meta['url']})")

        time.sleep(2.0)

        # 4. Connect WebSockets to both tabs
        async with websockets.connect(tab1_ws_url) as ws_sender, websockets.connect(tab2_ws_url) as ws_receiver:
            # Wait for both apps to be initialized
            for _ in range(25):
                ready1 = await cdp_eval(ws_sender, "typeof window.app !== 'undefined' && app.nodeId != null")
                ready2 = await cdp_eval(ws_receiver, "typeof window.app !== 'undefined' && app.nodeId != null")
                if ready1 and ready2:
                    break
                await asyncio.sleep(0.3)

            s_id = await cdp_eval(ws_sender, "app.nodeId")
            r_id = await cdp_eval(ws_receiver, "app.nodeId")
            print(f"[INIT] Sender nodeId: {s_id} | Receiver nodeId: {r_id}")

            # Configure Sender Identity
            await cdp_eval(ws_sender, """
                app.settings.deviceName = "Sender-Laptop (Windows)";
                app.user.deviceName = app.settings.deviceName;
                document.getElementById('settingDeviceName').value = app.settings.deviceName;
                document.getElementById('sidebarDeviceName').innerText = app.settings.deviceName;
                app.navigate('send');
            """)

            # Configure Receiver Identity
            await cdp_eval(ws_receiver, """
                app.settings.deviceName = "Receiver-Phone (Android)";
                app.user.deviceName = app.settings.deviceName;
                document.getElementById('settingDeviceName').value = app.settings.deviceName;
                document.getElementById('sidebarDeviceName').innerText = app.settings.deviceName;
                app.navigate('receive');
            """)

            print("[STEP 2] Broadcasting beacons on P2P channel and waiting for mutual radar discovery...")
            # Trigger multiple beacon passes and wait
            for _ in range(6):
                await cdp_eval(ws_sender, "app.broadcastBeacon();")
                await cdp_eval(ws_receiver, "app.broadcastBeacon();")
                await asyncio.sleep(0.6)

            # Check if Sender sees Receiver on Radar
            sender_devices = await cdp_eval(ws_sender, """
                Array.from(app.devices.values()).map(d => ({ id: d.id, name: d.name, platform: d.platform }))
            """)
            print(f"[RADAR SCAN] Sender discovered devices: {json.dumps(sender_devices, indent=2)}")
            assert len(sender_devices) >= 1, "Sender should discover Receiver on the radar!"
            target_device = sender_devices[0]

            # Check Radar Dome HTML
            radar_html = await cdp_eval(ws_sender, """
                document.getElementById('radarDevicesLayer').innerHTML
            """)
            has_floating = "radar-floating-device" in radar_html
            print(f"[RADAR HUD] High-Graphics Radar HUD rendered floating device inside dome: {has_floating}")
            assert has_floating, "Target device must float inside the radar HUD!"

            # Step 3: Stage a file to send on Sender
            print("[STEP 3] Staging test file 'Quarterly_Report_2026.pdf' (14.2 MB) on Sender...")
            await cdp_eval(ws_sender, """
                app.stagedFiles = [{
                    id: 'f_test_99',
                    name: 'Quarterly_Report_2026.pdf',
                    size: 14889728, // 14.2 MB
                    ext: 'pdf',
                    category: 'document',
                    selected: true
                }];
                app.renderSendStagedFiles();
            """)

            staged_count = await cdp_eval(ws_sender, "app.stagedFiles.length")
            print(f"[FILE MANAGER] Staged files count on Sender: {staged_count}")

            # Step 4: Click device inside radar to send transfer request
            print(f"[STEP 4] Sending transfer request to '{target_device['name']}'...")
            await cdp_eval(ws_sender, f"app.onDeviceCardClicked('{target_device['id']}')")

            await asyncio.sleep(1.5)

            # Step 5: Check Receiver incoming modal
            incoming_visible = await cdp_eval(ws_receiver, """
                !document.getElementById('incomingModal').classList.contains('hidden')
            """)
            incoming_info = await cdp_eval(ws_receiver, """
                document.getElementById('incomingPeerInfo').innerText
            """)
            print(f"[SECURITY CHECK] Receiver incoming modal visible: {incoming_visible} ({incoming_info})")
            assert incoming_visible, "Receiver should display incoming transfer authorization dialog!"

            # Step 6: Receiver clicks Accept & Save
            print("[STEP 6] Receiver clicks 'Accept & Save'...")
            await cdp_eval(ws_receiver, "document.getElementById('acceptBtn').click()")

            # Step 7: Monitor streaming progress
            print("[STEP 7] Monitoring streaming transfer across offline P2P stream...")
            for tick in range(15):
                await asyncio.sleep(0.4)
                s_stat = await cdp_eval(ws_sender, """
                    ({
                        percent: document.getElementById('bannerPercent')?.innerText || '0%',
                        sub: document.getElementById('bannerSub')?.innerText || '',
                        active: app.activeTransfer != null
                    })
                """)
                r_stat = await cdp_eval(ws_receiver, """
                    ({
                        percent: document.getElementById('bannerPercent')?.innerText || '0%',
                        sub: document.getElementById('bannerSub')?.innerText || '',
                        active: app.activeTransfer != null
                    })
                """)
                print(f"   [Streaming] Sender: {s_stat.get('percent')} | Receiver: {r_stat.get('percent')} | Speed/ETA: {s_stat.get('sub')}")
                if not s_stat.get("active") and not r_stat.get("active"):
                    print("[STREAM COMPLETE] Transfer reached 100% and closed on both ends!")
                    break

            # Step 8: Verify Transfer History & Local Storage on Both Sites
            print("[STEP 8] Verifying persistent transfer history on both sites...")
            sender_history = await cdp_eval(ws_sender, "app.history")
            receiver_history = await cdp_eval(ws_receiver, "app.history")

            print(f"[HISTORY - SENDER] Latest Entry: {json.dumps(sender_history[0] if sender_history else {}, indent=2)}")
            print(f"[HISTORY - RECEIVER] Latest Entry: {json.dumps(receiver_history[0] if receiver_history else {}, indent=2)}")

            assert len(sender_history) >= 1, "Sender must record completed transfer in history!"
            assert len(receiver_history) >= 1, "Receiver must record completed transfer in history!"
            assert sender_history[0]["status"] == "completed"
            assert receiver_history[0]["status"] == "completed"
            assert sender_history[0]["files"][0] == "Quarterly_Report_2026.pdf"
            assert receiver_history[0]["files"][0] == "Quarterly_Report_2026.pdf"

            print("\n=======================================================")
            print("ALL END-TO-END FILE SHARING VERIFICATIONS PASSED 100%!")
            print("=======================================================")

    finally:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except Exception:
            proc.kill()
        if os.path.exists(USER_DATA_DIR):
            try:
                shutil.rmtree(USER_DATA_DIR)
            except Exception:
                pass

if __name__ == "__main__":
    asyncio.run(run_e2e_test())
