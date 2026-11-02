import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.code, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Developer Information',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Technical architecture, network framing specifications, and protocols.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // App Specs Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  _buildSpecRow('Application', 'AuraShare Offline File Sharing'),
                  const Divider(height: 18),
                  _buildSpecRow('Core Architecture', 'Offline-First Direct Peer-to-Peer (P2P)'),
                  const Divider(height: 18),
                  _buildSpecRow('Frontend Engine', 'Flutter & Dart (Responsive Material 3)'),
                  const Divider(height: 18),
                  _buildSpecRow('State Management', 'Provider with Reactive Controllers'),
                  const Divider(height: 18),
                  _buildSpecRow('Navigation Framework', 'GoRouter (Declarative Shell Routing)'),
                  const Divider(height: 18),
                  _buildSpecRow('Local Storage', 'Local JSON Vault / Hive / SharedPreferences'),
                  const Divider(height: 18),
                  _buildSpecRow('Transmission Engine', 'RawDatagramSocket (UDP) & ServerSocket (TCP)'),
                  const Divider(height: 18),
                  _buildSpecRow('Integrity Verification', 'Cryptographic SHA-256 Checksum on Byte Streams'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // UDP Discovery Protocol
            const Text(
              'UDP BEACON PROTOCOL (PORT 52345)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            _buildCodeSnippet('''{
  "aura_protocol": "aurashare_v1",
  "type": "AURASHARE_BEACON",
  "id": "device-uuid-v4",
  "name": "Alex's Windows Laptop",
  "platform": "windows",
  "ip": "192.168.1.15",
  "port": 52346,
  "timestamp": "2026-11-02T19:00:00Z"
}'''),
            const SizedBox(height: 24),

            // TCP Transfer Handshake Protocol
            const Text(
              'TCP TRANSFER PROTOCOL (PORT 52346)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            _buildCodeSnippet('''// Step 1: Sender -> Receiver
{
  "action": "TRANSFER_REQUEST",
  "sessionId": "aura_1793649201948",
  "senderId": "device-sender-uuid",
  "senderName": "Alex's Laptop",
  "files": [
    { "id": "f1", "name": "Report.pdf", "size": 15204820, "checksum": "a8f3...b2c1" }
  ]
}

// Step 2: Receiver -> Sender
{
  "action": "TRANSFER_RESPONSE",
  "sessionId": "aura_1793649201948",
  "accepted": true
}

// Step 3: Raw Byte Streaming (64KB Chunks with On-The-Fly SHA-256 Verification)'''),
            const SizedBox(height: 28),

            // Architectural Principles
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Offline-First Architectural Invariants',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text('1. No External Server Fallback: Core file transfer never delegates to cloud storage.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                  SizedBox(height: 6),
                  Text('2. Local Authentication: Password hashes never leave the host device; auth works in air-gapped environments.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                  SizedBox(height: 6),
                  Text('3. Explicit Consent: Receiver authorization is required by default before byte writing commences.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                  SizedBox(height: 6),
                  Text('4. Streaming Performance: High-throughput socket pipes with windowed delta speed and ETA calculations.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildCodeSnippet(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.primary, height: 1.4),
      ),
    );
  }
}
