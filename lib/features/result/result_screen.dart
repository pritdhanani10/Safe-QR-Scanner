import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/qr_type.dart';
import '../../models/scan_record.dart';
import '../../models/security_result.dart';
import 'widgets/parsed_content_card.dart';
import 'widgets/risk_badge.dart';
import 'widgets/security_checklist.dart';
import 'widgets/upi_details_card.dart';

class ResultScreen extends StatelessWidget {
  final ScanRecord record;

  const ResultScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final security = record.securityResult;
    final isCritical = security.riskLevel == RiskLevel.critical;
    final isHigh = security.riskLevel == RiskLevel.high;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security Analysis',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share Payload',
            onPressed: () {
              Share.share(
                'Safe QR Scanner Report:\nType: ${record.type.displayName}\nRisk: ${security.riskLevel.label} (${security.score}/100)\nPayload: ${record.rawContent}',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Risk Assessment Banner
            RiskBadge(result: security),
            const SizedBox(height: 16),

            // 2. UPI Special Details Card (if UPI)
            if (record.type == QRType.upi) ...[
              UpiDetailsCard(metadata: record.metadata),
              const SizedBox(height: 16),
            ],

            // 3. Parsed Content Preview
            ParsedContentCard(
              type: record.type,
              rawContent: record.rawContent,
              metadata: record.metadata,
            ),
            const SizedBox(height: 16),

            // 4. Itemized Security Checklist
            SecurityChecklist(checks: security.checks),
            const SizedBox(height: 24),

            // 5. Action Buttons (Safe-by-default philosophy)
            _buildActionButtons(context, isCritical, isHigh),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isCritical, bool isHigh) {
    return Column(
      children: [
        // Primary Safe Action: Don't Open (if risky) or Open (if low risk)
        if (isCritical || isHigh) ...[
          // For high/critical risk, "Don't Open" is the primary prominent safe button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceElevated,
                foregroundColor: AppTheme.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.shield, color: AppTheme.riskLow, size: 20),
              label: const Text(
                "Don't Open (Recommended)",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary Risky Action: "Open Anyway" with confirmation dialog
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: isCritical ? AppTheme.riskCritical : AppTheme.riskMedium,
                side: BorderSide(
                  color: (isCritical ? AppTheme.riskCritical : AppTheme.riskMedium).withOpacity(0.5),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: isCritical ? AppTheme.riskCritical : AppTheme.riskMedium,
              ),
              label: Text(
                isCritical ? 'Open Anyway (Dangerous)' : 'Proceed Anyway',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onPressed: () => _confirmAndLaunch(context),
            ),
          ),
        ] else ...[
          // Low or Medium Risk: Proceed Button is primary
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: const Color(0xFF001E28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: AppTheme.primary.withOpacity(0.4),
              ),
              icon: Icon(_getActionIcon(record.type), size: 20),
              label: Text(
                _getActionLabel(record.type),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _launchPayload(context),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.surfaceBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Back to Scanner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],

        const SizedBox(height: 12),
        // Copy & Share utilities row
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textMuted),
                label: const Text(
                  'Copy Content',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: record.rawContent));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Content copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            Container(height: 16, width: 1, color: AppTheme.surfaceBorder),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.share_rounded, size: 16, color: AppTheme.textMuted),
                label: const Text(
                  'Share Report',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                onPressed: () {
                  Share.share(
                    'Safe QR Scanner:\nType: ${record.type.displayName}\nPayload: ${record.rawContent}\nRisk Level: ${record.securityResult.riskLevel.label}',
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getActionIcon(QRType type) {
    switch (type) {
      case QRType.url:
        return Icons.open_in_browser_rounded;
      case QRType.upi:
        return Icons.account_balance_wallet_outlined;
      case QRType.wifi:
        return Icons.wifi_password_rounded;
      case QRType.contact:
        return Icons.person_add_alt_1_rounded;
      case QRType.email:
        return Icons.send_rounded;
      case QRType.phone:
        return Icons.call_rounded;
      case QRType.sms:
        return Icons.sms_rounded;
      case QRType.plainText:
        return Icons.copy_rounded;
    }
  }

  String _getActionLabel(QRType type) {
    switch (type) {
      case QRType.url:
        return 'Open in Browser';
      case QRType.upi:
        return 'Open UPI App';
      case QRType.wifi:
        return 'Copy Wi-Fi Password';
      case QRType.contact:
        return 'Copy Contact Details';
      case QRType.email:
        return 'Compose Email';
      case QRType.phone:
        return 'Call Number';
      case QRType.sms:
        return 'Send SMS';
      case QRType.plainText:
        return 'Copy Text';
    }
  }

  void _confirmAndLaunch(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.riskCritical, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.riskCritical),
            SizedBox(width: 8),
            Text('Safety Warning', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'This target has been flagged as ${record.securityResult.riskLevel.label} (${record.securityResult.score}/100).\n\n'
          'Opening this link or executing this payload may lead to phishing, financial loss, or malware.\n\n'
          'Are you sure you want to proceed?',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel (Safe)', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.riskCritical,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Anyway'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _launchPayload(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchPayload(BuildContext context) async {
    try {
      if (record.type == QRType.url) {
        String url = record.rawContent.trim();
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            _showError(context, 'Could not open URL.');
          }
        }
      } else if (record.type == QRType.upi) {
        final uri = Uri.parse(record.rawContent.trim());
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            _showError(context, 'No compatible UPI payment app found on this device.');
          }
        }
      } else if (record.type == QRType.email) {
        final uri = Uri.parse(
          record.rawContent.startsWith('mailto:') ? record.rawContent : 'mailto:${record.rawContent}',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (context.mounted) {
            _showError(context, 'No email app found.');
          }
        }
      } else if (record.type == QRType.phone) {
        final uri = Uri.parse('tel:${record.metadata['phone']}');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (context.mounted) {
            _showError(context, 'No phone dialer found.');
          }
        }
      } else if (record.type == QRType.wifi) {
        final pass = record.metadata['password'] as String? ?? '';
        if (pass.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: pass));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wi-Fi password copied to clipboard!')),
            );
          }
        }
      } else {
        await Clipboard.setData(ClipboardData(text: record.rawContent));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payload copied to clipboard!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Action could not be executed: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.riskCritical),
    );
  }
}
