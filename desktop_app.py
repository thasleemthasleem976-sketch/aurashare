import sys
import os
import time
import socket
import threading
import webbrowser
import subprocess
import http.server
import socketserver
import urllib.parse
import json

def get_base_dir():
    if getattr(sys, 'frozen', False):
        return sys._MEIPASS
    return os.path.dirname(os.path.abspath(__file__))

def get_web_dir():
    base = get_base_dir()
    web_path = os.path.join(base, "web")
    if os.path.exists(web_path):
        return web_path
    return base

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

class AuraShareHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=get_web_dir(), **kwargs)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/ping":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok", "app": "AuraShare", "ip": get_local_ip()}).encode())
            return
        elif parsed.path == "/api/probe":
            params = urllib.parse.parse_qs(parsed.query)
            target_ip = params.get("ip", [""])[0]
            target_port = int(params.get("port", [52346])[0])
            
            available = False
            error_msg = ""
            if target_ip:
                try:
                    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    s.settimeout(1.5)
                    s.connect((target_ip, target_port))
                    s.close()
                    available = True
                except Exception as e:
                    error_msg = str(e)
            
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps({
                "available": available,
                "ip": target_ip,
                "port": target_port,
                "error": error_msg
            }).encode())
            return

        super().do_GET()

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

def run_server(port):
    server = socketserver.TCPServer(("0.0.0.0", port), AuraShareHandler)
    server.serve_forever()

def launch_app_window(url):
    # Try Edge in App Mode (looks like a native desktop app)
    edge_paths = [
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    ]
    for p in edge_paths:
        if os.path.exists(p):
            try:
                subprocess.Popen([p, f"--app={url}", "--window-size=1200,820", "--window-position=100,60"])
                return
            except Exception:
                pass
    
    # Try Chrome in App Mode
    chrome_path = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
    if os.path.exists(chrome_path):
        try:
            subprocess.Popen([chrome_path, f"--app={url}", "--window-size=1200,820"])
            return
        except Exception:
            pass

    # Fallback to default browser
    webbrowser.open(url)

def main():
    port = 52340
    # Find free port
    for p in range(52340, 52360):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.bind(("0.0.0.0", p))
            s.close()
            port = p
            break
        except Exception:
            continue

    local_ip = get_local_ip()
    url = f"http://localhost:{port}"

    t = threading.Thread(target=run_server, args=(port,), daemon=True)
    t.start()
    time.sleep(0.5)

    print("=" * 60)
    print(" AuraShare - Desktop Offline Application Active")
    print(f" Local URL:   {url}")
    print(f" Network URL: http://{local_ip}:{port}")
    print("=" * 60)

    launch_app_window(url)

    # Keep alive
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        sys.exit(0)

if __name__ == "__main__":
    main()
