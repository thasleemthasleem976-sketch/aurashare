# AuraShare – Secure Offline File Sharing Application

[![Live Demo](https://img.shields.io/badge/Live%20Demo-GitHub%20Pages-0284c7?style=for-the-badge&logo=githubpages&logoColor=white)](https://thasleemthasleem976-sketch.github.io/aurashare/)
[![PWA Ready](https://img.shields.io/badge/PWA-Installable%20Offline-10b981?style=for-the-badge&logo=pwa&logoColor=white)](https://thasleemthasleem976-sketch.github.io/aurashare/)
[![Liquid Glassmorphism](https://img.shields.io/badge/UI-Liquid%20Glassmorphism-6366f1?style=for-the-badge)](https://thasleemthasleem976-sketch.github.io/aurashare/)
[![Offline P2P](https://img.shields.io/badge/Network-100%25%20Zero%20Internet-f59e0b?style=for-the-badge)](https://thasleemthasleem976-sketch.github.io/aurashare/)

🌐 **Live Web Application (GitHub Pages)**:  
👉 **[https://thasleemthasleem976-sketch.github.io/aurashare/](https://thasleemthasleem976-sketch.github.io/aurashare/)**

---

## 🌟 Overview

**AuraShare** is a next-generation, high-performance, **100% offline-first peer-to-peer file sharing application**. Designed for air-gapped environments, local Wi-Fi, Ethernet, and portable mobile hotspots, AuraShare enables devices to discover each other, verify integrity with SHA-256 hashes, and stream files at line speeds without touching the cloud or consuming internet bandwidth.

Featuring an ultra-premium **Liquid Glass Morphism UI** with frosted translucent glass surfaces, dynamic radar HUD scanner, high-quality login security vault, and full offline PWA installation capability.

---

## 🚀 Key Highlights & Features

- 🌐 **Live Web Application**: Hosted directly on [GitHub Pages](https://thasleemthasleem976-sketch.github.io/aurashare/) with full offline PWA service worker caching.
- 🎨 **Liquid Glassmorphism UI**: Translucent glass surfaces, luminous borders, ambient depth, dynamic light reflections, and responsive desktop/mobile layouts.
- 🔒 **High-Quality Security Vault**: Secure local authentication with encrypted credential storage and crisp background visuals without blur obstruction.
- 📡 **Real-Time Radar HUD Scanner**: High-tech graphical radar sweep scanning local networks with UDP beacons (`port 52345`). Only actively available peers are selectable.
- ⚡ **Direct Socket Streaming**: Fast peer-to-peer binary transfer over TCP (`port 52346`) with real-time transfer speed, ETA timer, and chunk validation.
- 🛡️ **Receiver Authorization**: Explicit receiver consent modals preventing unauthorized file downloads.
- 🔑 **Cryptographic File Integrity**: Automatic SHA-256 verification after every transfer ensuring bit-for-bit file authenticity.
- 📦 **Offline App Bundle Download**: One-click download of the complete offline application zip (`aurashare-offline.zip`) including zero-config `start_windows.bat` and `start_linux_mac.sh`.
- 📱 **Progressive Web App (PWA)**: Installable directly onto Windows, macOS, Android, and iOS home screens for standalone offline operation.

---

## 🖥️ Live Demo & Instant Launch

### 1. Web Access (GitHub Pages)
Visit **[https://thasleemthasleem976-sketch.github.io/aurashare/](https://thasleemthasleem976-sketch.github.io/aurashare/)** in any modern browser (Chrome, Edge, Safari, Firefox).

### 2. Local Python Server (Zero Internet Required)
Run the built-in local server on your machine:
```bash
python server.py
```
Open **[http://localhost:8080](http://localhost:8080)** or access from any phone on the same Wi-Fi using your LAN IP (e.g. `http://192.168.1.X:8080`).

### 3. One-Click Standalone Desktop Launcher
Download `aurashare-offline.zip` directly from the in-app navigation bar:
- **Windows**: Double-click `start_windows.bat`
- **macOS / Linux**: Run `chmod +x start_linux_mac.sh && ./start_linux_mac.sh`

---

## 📱 How AuraShare Works (Project Flow)

```
┌────────────────────────────────────────────────────────┐
│               Liquid Glass Security Vault               │
│         (Local Account Login / Registration)           │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│             Interactive Dashboard & Stats              │
│       (Storage Available, Active Peers, History)       │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│               High-Graphics Radar Scanner              │
│      (UDP Multicast Beacon Sweep on Port 52345)        │
│    * Filters only active, verified available devices   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│            File Selection & Staging Queue             │
│        (Real File Chooser, Multi-File Staging)         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│           Direct TCP Socket Transfer (Port 52346)      │
│     * Receiver Accepts Authorization Handshake         │
│     * 64KB Binary Chunk Stream with Live Speed & ETA   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│           SHA-256 Bit-Integrity Verification           │
│        (Saved to Downloads & Logged in History)        │
└────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

| Component | Technology |
|---|---|
| **Web Frontend** | HTML5, Modern ECMAScript (Vanilla JS), Liquid Glassmorphism CSS |
| **PWA & Offline** | Service Worker Cache API v5, Web App Manifest (Standalone) |
| **Networking** | TCP Raw Sockets (`52346`), UDP Broadcast Beacons (`52345`) |
| **Local Server** | Python 3 Multi-threaded HTTP & WebSocket Server (`server.py`) |
| **Flutter Mobile/Desktop** | Flutter 3.10+ & Dart 3.0+ Material 3 Architecture (`/lib`) |
| **Security** | SHA-256 Checksums, PBKDF2/Salted Hashes, End-to-End Receiver Auth |

---

## 📂 Project Structure

```
aurashare/
├── index.html                 # Root entry point for GitHub Pages
├── style.css                  # Liquid Glassmorphism CSS design system
├── app.js                     # Core application logic, P2P engine & Radar HUD
├── manifest.json              # PWA manifest with standalone display configuration
├── sw.js                      # Cache v5 offline-first Service Worker
├── login-bg.jpg               # High-quality login background image
├── file-sharing-bg.jpg        # Workspace background image
├── glass-folders-bg.jpg       # Glass folder visual accent
├── aurashare-offline.zip      # Complete offline runnable distribution bundle
├── server.py                  # Local Python server with automatic IP detection
├── docs/                      # GitHub Pages /docs mirror
│   ├── index.html
│   ├── style.css
│   ├── app.js
│   └── ...
├── web/                       # Web application source files
├── lib/                       # Flutter cross-platform mobile/desktop codebase
│   ├── main.dart
│   ├── models/
│   ├── providers/
│   ├── screens/
│   └── services/
└── README.md
```

---

## 🔒 Security & Privacy Model

1. **Air-Gapped Operation**: AuraShare requires zero external network access. No telemetry, third-party analytics, or cloud connections exist.
2. **Explicit Consent**: Incoming transfers trigger an authorization prompt with sender identity, device IP, and file manifests. No files are accepted automatically.
3. **Bit-Level Integrity**: All transmitted streams are hashed via SHA-256 and matched upon completion.
4. **Sandboxed Local Storage**: User profiles and transfer logs are strictly stored in local device storage.

---

## 📄 License

Open-source under the [MIT License](LICENSE).
