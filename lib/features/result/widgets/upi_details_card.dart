import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class UpiDetailsCard extends StatelessWidget {
  final Map<String, dynamic> metadata;

  const UpiDetailsCard({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final payeeName = metadata['payeeName'] as String? ?? 'Not Specified';
    final upiId = metadata['upiId'] as String? ?? 'Unknown VPA';
    final amount = metadata['amount'] as String?;
    final note = metadata['note'] as String?;
    final currency = metadata['currency'] as String? ?? 'INR';
    final merchantCode = metadata['merchantCode'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0x153B82F6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.payments_outlined, size: 18, color: Color(0xFF60A5FA)),
                SizedBox(width: 8),
                Text(
                  'UPI PAYMENT DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF60A5FA),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount display if present
                if (amount != null && amount.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'REQUESTED AMOUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹$amount',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          currency == 'INR' ? 'Indian Rupees' : currency,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                _buildDetailRow('Payee Name', payeeName, icon: Icons.person_outline),
                const SizedBox(height: 12),
                _buildDetailRow('UPI ID (VPA)', upiId, icon: Icons.alternate_email, isMono: true),

                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Transaction Note', note, icon: Icons.notes_outlined),
                ],

                if (merchantCode != null && merchantCode.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Merchant Code (MCC)', merchantCode, icon: Icons.storefront_outlined),
                ],

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.riskMedium.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.riskMedium.withOpacity(0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.riskMedium),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Safety Rule: Entering your UPI PIN will DEBIT money from your bank account. You NEVER need to enter your PIN to receive money or refunds.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFDE68A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required IconData icon, bool isMono = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  fontFamily: isMono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
