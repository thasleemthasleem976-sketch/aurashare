import os
import zipfile

def build_offline_zip():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    web_dir = os.path.join(base_dir, "web")
    zip_path = os.path.join(web_dir, "aurashare-offline.zip")

    start_windows_bat = """@echo off
title AuraShare Offline Server
echo ========================================================
echo   Starting AuraShare Offline Application (Zero Internet)
echo ========================================================
echo Starting local web server...
start "" "http://localhost:8080"
python server.py
pause
"""

    start_linux_mac_sh = """#!/bin/bash
echo "========================================================"
echo "  Starting AuraShare Offline Application (Zero Internet)"
echo "========================================================"
python3 server.py &
SERVER_PID=$!
sleep 1
if command -v xdg-open > /dev/null; then
  xdg-open "http://localhost:8080"
elif command -v open > /dev/null; then
  open "http://localhost:8080"
fi
echo "AuraShare running on http://localhost:8080. Press Ctrl+C to stop."
wait $SERVER_PID
"""

    readme_txt = """========================================================================
AuraShare - Secure Offline Peer-to-Peer File Sharing Application
========================================================================

AuraShare allows devices to discover and transfer files directly across
local Wi-Fi, Ethernet, or phone hotspots with 100% offline security.
No internet connection or cloud storage is required.

QUICK START:
1. Windows:
   - Double-click 'start_windows.bat'
   - AuraShare opens in your browser at http://localhost:8080

2. macOS / Linux:
   - Run: chmod +x start_linux_mac.sh && ./start_linux_mac.sh
   - AuraShare opens at http://localhost:8080

3. Android / Mobile:
   - Connect your phone and PC to the same Wi-Fi or turn on Phone Hotspot.
   - Look at the top banner in AuraShare for the Network LAN IP (e.g. http://10.73.110.163:8080).
   - Open that URL in your mobile browser.

FEATURES:
- 100% Offline P2P Transfer (Direct TCP & Local Sockets)
- Real-time High-Graphics Radar HUD Scanner
- End-to-End Receiver Authorization
- Local Offline Vault Authentication
- Zero Cloud Traffic & SHA-256 File Integrity
========================================================================
"""

    # Files to include in the offline ZIP
    files_to_pack = [
        ("web/index.html", "index.html"),
        ("web/style.css", "style.css"),
        ("web/app.js", "app.js"),
        ("web/manifest.json", "manifest.json"),
        ("web/sw.js", "sw.js"),
        ("web/file-sharing-bg.jpg", "file-sharing-bg.jpg"),
        ("web/workspace-bg.png", "workspace-bg.png"),
        ("web/glass-folders-bg.jpg", "glass-folders-bg.jpg"),
        ("web/login-bg.jpg", "login-bg.jpg"),
        ("web/icon-192.png", "icon-192.png"),
        ("web/icon-512.png", "icon-512.png"),
        ("web/icon-maskable-512.png", "icon-maskable-512.png"),
        ("web/favicon.png", "favicon.png"),
        ("web/favicon.ico", "favicon.ico"),
        ("server.py", "server.py"),
    ]

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for src, arc in files_to_pack:
            src_full = os.path.join(base_dir, src)
            if os.path.exists(src_full):
                z.write(src_full, arc)
        
        z.writestr("start_windows.bat", start_windows_bat)
        z.writestr("start_linux_mac.sh", start_linux_mac_sh)
        z.writestr("README.txt", readme_txt)

    size_kb = os.path.getsize(zip_path) / 1024
    print(f"Created {zip_path} successfully ({size_kb:.1f} KB)")

if __name__ == "__main__":
    build_offline_zip()
