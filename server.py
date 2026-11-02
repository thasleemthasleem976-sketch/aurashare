import http.server
import socketserver
import os
import socket

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(__file__), "web")

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

if __name__ == "__main__":
    local_ip = get_local_ip()
    # Try PORT 8080, fallback to 8081 if occupied
    try:
        server = socketserver.TCPServer(("0.0.0.0", PORT), Handler)
    except OSError:
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
