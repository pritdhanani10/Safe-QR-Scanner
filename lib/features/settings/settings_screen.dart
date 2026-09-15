import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../history/history_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _strictMode = true;
  bool _warnOnShorteners = true;
  bool _offlineOnly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security & Privacy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Privacy Guarantee Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2B3E), Color(0xFF131B2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppTheme.primary, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Zero-Telemetry Privacy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Safe QR Scanner processes all QR data strictly on your device. Scanned links, UPI VPAs, and personal vCards are never uploaded to any cloud server.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 14, color: AppTheme.riskLow),
                      SizedBox(width: 6),
                      Text(
                        '100% Offline Static Risk Engine Active',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.riskLow),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security Preferences
          _buildSectionHeader('RISK ENGINE SETTINGS'),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  SwitchListTile(
                    activeThumbColor: AppTheme.primary,
                    title: const Text('Strict Phishing Guard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Flag subtle look-alike domains and urgent bank keywords', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    value: _strictMode,
                    onChanged: (val) => setState(() => _strictMode = val),
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceBorder),
                  SwitchListTile(
                    activeThumbColor: AppTheme.primary,
                    title: const Text('URL Shortener Alert', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Require confirmation on bit.ly, tinyurl, and masking redirects', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    value: _warnOnShorteners,
                    onChanged: (val) => setState(() => _warnOnShorteners = val),
                  ),
                  const Divider(height: 1, color: AppTheme.surfaceBorder),
                  SwitchListTile(
                    activeThumbColor: AppTheme.primary,
                    title: const Text('Strict Offline-Only Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Prevent background network lookups for link previews', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    value: _offlineOnly,
                    onChanged: (val) => setState(() => _offlineOnly = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Data Management
          _buildSectionHeader('STORAGE & RESET'),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: AppTheme.riskCritical),
                title: const Text('Wipe All Local Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.riskCritical)),
                subtitle: const Text('Permanently erase local scan history', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                onTap: () async {
                  await HistoryRepository().clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All local scan data has been wiped.')),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App Information
          _buildSectionHeader('ABOUT'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safe QR Scanner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Version 1.0.0 • Scan first. Trust later.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                SizedBox(height: 12),
                Text(
                  'Created with a defensive security mindset to protect users from malicious phishing, deceptive links, and UPI payment scams.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
