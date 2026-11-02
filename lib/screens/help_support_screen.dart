import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
                  child: const Icon(Icons.help_outline, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Help & Support',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Guides, offline connection workflows, and troubleshooting.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // How Offline Sharing Works Step by Step
            const Text(
              'HOW AURASHARE WORKS OFFLINE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, letterSpacing: 1),
            ),
            const SizedBox(height: 12),

            _buildWorkflowStep('1', 'Connect to Same Local Network', 'Connect both devices to the same Wi-Fi router, local switch, or enable Portable Wi-Fi Hotspot on one device and connect the other to it. NO internet connection is required!'),
            const SizedBox(height: 10),
            _buildWorkflowStep('2', 'Discover Nearby Device', 'Open Device Discovery on both devices and click "Scan Nearby Devices". AuraShare broadcasts UDP announcement beacons to identify peers instantly.'),
            const SizedBox(height: 10),
            _buildWorkflowStep('3', 'Select Files', 'Go to File Management, click "Add Files", and pick real files from your device storage (documents, photos, 4K videos, zip files).'),
            const SizedBox(height: 10),
            _buildWorkflowStep('4', 'Authorize & Transfer', 'Click "Send to Device". The receiver receives a permission prompt with file name, size, and sender identity. Upon clicking "Accept", files stream directly over TCP socket at full Wi-Fi hardware speeds.'),
            const SizedBox(height: 28),

            // FAQs
            const Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, letterSpacing: 1),
            ),
            const SizedBox(height: 12),

            _buildFaqItem(
              'Does AuraShare use any of my cellular data or internet?',
              'No. AuraShare is 100% offline-first. All data flows directly across the local wireless or wired network without passing through external internet servers or cloud storage.',
            ),
            _buildFaqItem(
              'What should I do if nearby devices cannot find each other?',
              '1. Make sure both devices are on the same Wi-Fi or Hotspot.\n2. In office or public Wi-Fi, "AP Client Isolation" may block broadcast packets. In that case, use the "Direct IP" option in Device Discovery.\n3. On Windows, make sure Windows Defender Firewall allows AuraShare on Private Networks.',
            ),
            _buildFaqItem(
              'Can I transfer files between Android and Windows?',
              'Yes! AuraShare uses standard cross-platform TCP/UDP networking protocols that work identically across Android, Windows, Linux, and macOS.',
            ),
            _buildFaqItem(
              'How are files protected from tampering?',
              'AuraShare calculates SHA-256 cryptographic checksums for files. The receiver verifies the checksum upon receiving the stream, ensuring byte-level integrity.',
            ),
            _buildFaqItem(
              'Where are received files saved on my device?',
              'Received files are stored in your device\'s standard "Downloads/AuraShare" folder, customizable in the Settings screen.',
            ),
            const SizedBox(height: 28),

            // Contact / Feedback
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent, color: AppColors.primary, size: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Offline Support & Diagnostics',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Encountering an issue? Check the Offline Communication screen to inspect bound socket ports and IP interfaces.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowStep(String number, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(answer, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.4)),
        ],
      ),
    );
  }
}
