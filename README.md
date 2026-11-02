# AuraShare – Secure Offline File Sharing Application

AuraShare is a secure, offline-first, cross-platform application designed to transfer files directly between nearby devices without requiring an internet connection or cloud storage.

Built with **Flutter**, **Dart**, and **Material Design 3**, AuraShare enables direct socket streaming over local Wi-Fi, Ethernet LAN, or portable Wi-Fi Hotspots with end-to-end local integrity verification.

---

## 🚀 Key Features

- **100% Offline-First Architecture**: No external internet, cloud servers, or third-party databases required.
- **Nearby Device Discovery**: Automatic peer discovery using UDP multicast beacons on port `52345`.
- **Direct Socket Transmission**: High-speed binary streaming over TCP sockets on port `52346`.
- **Real File Selection**: Full platform file chooser integration with multi-file queue management.
- **Transfer Controls**: Real-time progress percentage, transfer speed (KB/s, MB/s), ETA countdown, and Pause / Resume / Cancel controls.
- **Receiver Authorization**: Explicit accept/reject confirmation dialog before incoming files are written to disk.
- **Cryptographic Security**: SHA-256 integrity checksums, device verification fingerprints, and trusted device lists.
- **Local User Authentication**: Account registration and login authenticated completely offline with salted SHA-256 hashes.
- **Persistent Transfer History**: Offline local storage recording all sent and received files, sizes, timestamps, and peers.
- **Responsive Navigation**: Adaptive desktop sidebar for large displays and mobile bottom navigation with navigation drawer for Android/iOS.

---

## 📱 How AuraShare Works (Project Flow)

```
Splash Screen
      ↓
Welcome Screen
      ↓
Login / Registration (Local Vault)
      ↓
Dashboard (Overview, Quick Actions, Stats)
      ↓
Device Discovery (UDP Beacon Radar Scanner / Direct IP)
      ↓
Select Device & Connect
      ↓
File Management (Real File Picker, Category Filter, Queue)
      ↓
File Transfer Request (TCP Handshake)
      ↓
Receiver Accepts (Permission Prompt)
      ↓
Secure Local Transfer (64KB Chunks, Speed/ETA tracking)
      ↓
Integrity Verification (SHA-256 Checksum Match)
      ↓
Transfer Completed & History Persisted
```

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Frontend Framework** | Flutter 3.10+ & Dart 3.0+ |
| **UI Design System** | Material Design 3 (Responsive Layout) |
| **State Management** | Provider (`ChangeNotifierProvider`) |
| **Application Routing** | GoRouter (`ShellRoute` with persistent navigation) |
| **Local Storage** | SharedPreferences / Local JSON Vault / Hive |
| **Device Discovery** | RawDatagramSocket (UDP Port `52345`) |
| **File Transmission** | ServerSocket & Socket (TCP Port `52346`) |
| **Integrity & Security** | Cryptographic SHA-256 Checksums & Device Fingerprints |
| **File System** | `file_picker` & `path_provider` |

---

## 📂 Project Architecture

```
aurashare/
├── android/
│   └── app/src/main/AndroidManifest.xml   # Network & storage permissions
├── lib/
│   ├── main.dart                          # App entry point, service bootstrapping & providers
│   ├── theme/
│   │   ├── app_colors.dart                # Aura cyan/indigo color system
│   │   └── app_theme.dart                 # Dark & light Material 3 themes
│   ├── models/
│   │   ├── user_model.dart                # User credentials & profile
│   │   ├── device_model.dart              # Discovered nearby peer metadata
│   │   ├── file_item_model.dart           # File metadata, size & checksums
│   │   ├── transfer_session_model.dart    # Active session, queue & progress
│   │   ├── notification_model.dart        # Real-time event notifications
│   │   └── settings_model.dart            # Local preferences & port configs
│   ├── services/
│   │   ├── local_storage_service.dart     # Offline database & preferences
│   │   ├── auth_service.dart              # Offline registration & login
│   │   ├── encryption_service.dart        # SHA-256 hashing & payload encryption
│   │   ├── network_discovery_service.dart # UDP broadcast beacons & socket listener
│   │   ├── socket_transfer_service.dart   # TCP server & streaming client
│   │   └── notification_service.dart      # In-app event dispatcher
│   ├── providers/
│   │   ├── auth_provider.dart             # User session management
│   │   ├── device_provider.dart           # Radar scan & peer connection state
│   │   ├── file_management_provider.dart  # Multi-file staging & category filters
│   │   ├── transfer_provider.dart         # Active transfer, speed & history state
│   │   ├── settings_provider.dart         # User preferences state
│   │   └── notification_provider.dart     # Unread count & notification log
│   ├── routes/
│   │   └── app_router.dart                # GoRouter with ShellRoute navigation
│   ├── widgets/
│   │   ├── app_navigation_scaffold.dart   # Desktop sidebar & mobile navigation
│   │   ├── radar_scan_animation.dart      # Canvas radar sweep animation
│   │   ├── device_card.dart               # Nearby peer card with trust toggle
│   │   ├── transfer_progress_card.dart    # Live speed, progress bar & controls
│   │   ├── incoming_transfer_dialog.dart  # Explicit accept/reject prompt
│   │   └── stat_summary_card.dart         # Dashboard analytics cards
│   └── screens/
│       ├── splash_screen.dart             # Animated launch screen
│       ├── welcome_screen.dart            # Onboarding & feature highlights
│       ├── auth/
│       │   ├── login_screen.dart          # Local offline sign-in
│       │   └── register_screen.dart       # Account creation with validation
│       ├── dashboard_screen.dart          # Main hub with quick actions & metrics
│       ├── device_discovery_screen.dart   # Radar scanner & direct IP probe
│       ├── file_management_screen.dart    # Real file browser & queue builder
│       ├── file_transfer_screen.dart      # Live transfer controller & speed monitor
│       ├── transfer_history_screen.dart   # Filterable persistent history log
│       ├── security_center_screen.dart    # Cryptographic keys & trust policies
│       ├── offline_communication_screen.dart # LAN/Hotspot interfaces & diagnostics
│       ├── notifications_screen.dart      # Event center for transfers & peers
│       ├── settings_screen.dart           # Device name, ports & download folder
│       ├── profile_screen.dart            # Identity & lifetime transfer stats
│       ├── help_support_screen.dart       # Step-by-step guides & troubleshooting
│       └── developer_info_screen.dart     # Protocol frames & socket specifications
├── test/
│   ├── encryption_test.dart               # Cryptographic SHA-256 unit tests
│   └── network_protocol_test.dart         # Serialization & queue tests
└── pubspec.yaml                           # Dependency specifications
```

---

## 🔒 Security & Privacy Model

1. **Zero Cloud Transmission**: Files, credentials, and logs remain strictly within the local device storage and local network packets.
2. **Explicit Consent**: Incoming files trigger a modal displaying sender name, device IP, file list, and total size. No data is stored without receiver acceptance.
3. **Cryptographic Verification**: Every file transmitted includes its SHA-256 hash. The receiver verifies this checksum after the final chunk is received.
4. **Air-Gapped Compatible**: Designed to work in environments with zero external network access (classrooms, rural medical stations, secure facilities).

---

## 💻 Running the Application

### Prerequisites
- Flutter SDK 3.10+
- Dart SDK 3.0+

### Install Dependencies
```bash
flutter pub get
```

### Run on Windows Desktop
```bash
flutter run -d windows
```

### Run on Android Device / Emulator
```bash
flutter run -d android
```

### Run Unit Tests
```bash
flutter test
```
