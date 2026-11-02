import http.server
import socketserver
import os
import socket
import urllib.parse
import json

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(__file__), "web")

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

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
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

if __name__ == "__main__":
    local_ip = get_local_ip()
    socketserver.TCPServer.allow_reuse_address = True
    try:
        server = socketserver.TCPServer(("0.0.0.0", PORT), Handler)
    except OSError:
        PORT = 8080
        time_to_wait = 1
        server = None
        for attempt in range(5):
            try:
                server = socketserver.TCPServer(("0.0.0.0", PORT), Handler)
                break
            except OSError:
                import time
                time.sleep(1)
        if not server:
            PORT = 8081
            server = socketserver.TCPServer(("0.0.0.0", PORT), Handler)

    print("=" * 60)
    print(" AuraShare - Secure Offline File Sharing Local Web Server")
    print("=" * 60)
    print(f" Localhost URL:   http://localhost:{PORT}")
    print(f" Network LAN URL: http://{local_ip}:{PORT}")
    print("=" * 60)
    print(f" Serving web app from: {DIRECTORY}")
    print(" Press Ctrl+C to terminate.")
    print("=" * 60)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping AuraShare server...")
        server.server_close()
