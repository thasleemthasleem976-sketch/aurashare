import http.server
import os
import socket
import sys

DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "web")

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

def start_server():
    local_ip = get_local_ip()
    server = None
    chosen_port = 8080

    for port in [8080, 8081, 8082, 8000, 8888]:
        try:
            http.server.ThreadingHTTPServer.allow_reuse_address = True
            server = http.server.ThreadingHTTPServer(("", port), Handler)
            chosen_port = port
            break
        except (OSError, PermissionError) as e:
            print(f"Port {port} unavailable ({e}), trying next...")
            continue

    if not server:
        print("Error: Could not bind to any suitable port.")
        sys.exit(1)

    print("=" * 60)
    print(" AuraShare - Secure Offline File Sharing Local Web Server")
    print("=" * 60)
    print(f" Localhost URL:   http://localhost:{chosen_port}")
    print(f" Network LAN URL: http://{local_ip}:{chosen_port}")
    print("=" * 60)
    print(f" Serving web app from: {DIRECTORY}")
    print(" Press Ctrl+C to terminate.")
    print("=" * 60)
    sys.stdout.flush()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping AuraShare server...")
        server.server_close()

if __name__ == "__main__":
    start_server()
