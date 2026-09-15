import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/qr_type.dart';

class ParsedContentCard extends StatefulWidget {
  final QRType type;
  final String rawContent;
  final Map<String, dynamic> metadata;

  const ParsedContentCard({
    super.key,
    required this.type,
    required this.rawContent,
    required this.metadata,
  });

  @override
  State<ParsedContentCard> createState() => _ParsedContentCardState();
}

class _ParsedContentCardState extends State<ParsedContentCard> {
  bool _showRawPayload = false;
  bool _showWifiPassword = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(_getTypeIcon(widget.type), size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  widget.type.displayName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.textSecondary),
                  tooltip: 'Copy Payload',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.rawContent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied payload to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.surfaceBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeSpecificContent(),
                const SizedBox(height: 14),
                // Raw payload reveal button
                InkWell(
                  onTap: () => setState(() => _showRawPayload = !_showRawPayload),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showRawPayload ? 'Hide raw decoded payload' : 'Show raw decoded payload',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        Icon(
                          _showRawPayload ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppTheme.primaryLight,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showRawPayload) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: SelectableText(
                      widget.rawContent,
                      style: AppTheme.monoStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificContent() {
    switch (widget.type) {
      case QRType.url:
        final host = widget.metadata['host'] as String? ?? '';
        final path = widget.metadata['path'] as String? ?? '';
        final scheme = widget.metadata['scheme'] as String? ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme == 'https'
                        ? AppTheme.riskLow.withOpacity(0.2)
                        : AppTheme.riskMedium.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    scheme.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scheme == 'https' ? AppTheme.riskLow : AppTheme.riskMedium,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    host,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (path.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Path: $path',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ],
        );

      case QRType.wifi:
        final ssid = widget.metadata['ssid'] as String? ?? 'Unknown Network';
        final auth = widget.metadata['authType'] as String? ?? 'WPA';
        final password = widget.metadata['password'] as String? ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  ssid,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Security Protocol: $auth', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            if (password.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Password: ${_showWifiPassword ? password : '••••••••••••'}',
                    style: AppTheme.monoStyle(fontSize: 12, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showWifiPassword = !_showWifiPassword),
                    child: Icon(
                      _showWifiPassword ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );

      case QRType.contact:
        final name = widget.metadata['name'] as String? ?? 'Contact';
        final phone = widget.metadata['phone'] as String? ?? '';
        final email = widget.metadata['email'] as String? ?? '';
        final org = widget.metadata['organization'] as String? ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(phone, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ],
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(email, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ],
            if (org.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.business_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(org, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ],
        );

      case QRType.upi:
        // Handled specifically by UpiDetailsCard in result screen
        return const SizedBox.shrink();

      default:
        return Text(
          widget.rawContent,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        );
    }
  }

  IconData _getTypeIcon(QRType type) {
    switch (type) {
      case QRType.url:
        return Icons.link_rounded;
      case QRType.upi:
        return Icons.currency_rupee_rounded;
      case QRType.wifi:
        return Icons.wifi_rounded;
      case QRType.contact:
        return Icons.badge_outlined;
      case QRType.email:
        return Icons.alternate_email_rounded;
      case QRType.phone:
        return Icons.phone_rounded;
      case QRType.sms:
        return Icons.sms_outlined;
      case QRType.plainText:
        return Icons.text_snippet_outlined;
    }
  }
}
