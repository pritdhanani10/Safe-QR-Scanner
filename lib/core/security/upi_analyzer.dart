import '../../models/security_result.dart';

class UpiAnalysisResult {
  final int scorePenalty;
  final List<SecurityCheckItem> checks;
  final List<String> warnings;
  final Map<String, dynamic> parsedFields;

  const UpiAnalysisResult({
    required this.scorePenalty,
    required this.checks,
    required this.warnings,
    required this.parsedFields,
  });
}

class UpiAnalyzer {
  static UpiAnalysisResult analyze(String upiString) {
    int penalty = 0;
    final List<SecurityCheckItem> checks = [];
    final List<String> warnings = [];

    final uri = Uri.tryParse(upiString);
    final params = uri?.queryParameters ?? {};

    final pa = params['pa']?.trim() ?? ''; // Payee VPA
    final pn = params['pn']?.trim() ?? ''; // Payee Name
    final am = params['am']?.trim() ?? ''; // Amount
    final tn = params['tn']?.trim() ?? ''; // Transaction note
    final cu = params['cu']?.trim().toUpperCase() ?? 'INR'; // Currency
    final mc = params['mc']?.trim() ?? ''; // Merchant Category Code

    // 1. Payee VPA (Virtual Payment Address) check
    final vpaRegex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+$');
    if (pa.isEmpty) {
      penalty += 50;
      checks.add(const SecurityCheckItem(
        title: 'Missing UPI ID (VPA)',
        description: 'The QR code lacks a destination payment address ("pa" parameter).',
        status: CheckStatus.failed,
      ));
      warnings.add('Invalid UPI QR: No payee UPI ID specified.');
    } else if (!vpaRegex.hasMatch(pa)) {
      penalty += 25;
      checks.add(SecurityCheckItem(
        title: 'Non-Standard UPI ID',
        description: 'UPI ID "$pa" deviates from conventional VPA structure.',
        status: CheckStatus.warning,
      ));
      warnings.add('The payee address "$pa" has an unusual format. Double check before paying.');
    } else {
      checks.add(SecurityCheckItem(
        title: 'Valid UPI ID Structure',
        description: 'Recipient VPA: $pa',
        status: CheckStatus.passed,
      ));
    }

    // 2. Payee Name (pn) check
    if (pn.isEmpty) {
      penalty += 15;
      checks.add(const SecurityCheckItem(
        title: 'Payee Name Missing',
        description: 'No displayed name encoded in the QR. Only UPI address is present.',
        status: CheckStatus.warning,
      ));
      warnings.add('No Payee name specified. Your UPI app will show the bank-registered name.');
    } else {
      checks.add(SecurityCheckItem(
        title: 'Payee Name Encoded',
        description: 'Declared as "$pn"',
        status: CheckStatus.passed,
      ));
    }

    // 3. Amount Inspection
    if (am.isNotEmpty) {
      final parsedAmount = double.tryParse(am);
      if (parsedAmount != null) {
        if (parsedAmount >= 5000) {
          checks.add(SecurityCheckItem(
            title: 'High Amount Pre-filled',
            description: 'Fixed payment of ₹$am requested.',
            status: CheckStatus.warning,
          ));
          warnings.add('High payment amount (₹$am). Verify payee carefully before entering PIN.');
        } else {
          checks.add(SecurityCheckItem(
            title: 'Pre-set Amount',
            description: 'Requested amount: ₹$am',
            status: CheckStatus.passed,
          ));
        }
      } else {
        penalty += 20;
        checks.add(SecurityCheckItem(
          title: 'Invalid Amount Format',
          description: 'Amount field contains invalid characters: "$am"',
          status: CheckStatus.failed,
        ));
      }
    } else {
      checks.add(const SecurityCheckItem(
        title: 'Dynamic / Open Amount',
        description: 'Amount is not fixed; user will enter amount in UPI app.',
        status: CheckStatus.passed,
      ));
    }

    // 4. Transaction Note Deception Check
    if (tn.isNotEmpty) {
      final lowerNote = tn.toLowerCase();
      final suspiciousNoteWords = [
        'kyc',
        'refund',
        'cashback',
        'lottery',
        'winner',
        'reward',
        'receive',
        'credit',
        'pending payment',
        'bonus',
      ];

      final matches = suspiciousNoteWords.where((word) => lowerNote.contains(word)).toList();
      if (matches.isNotEmpty) {
        penalty += 35;
        checks.add(SecurityCheckItem(
          title: 'High-Risk Note Wording',
          description: 'Note contains scam trigger keywords: "${matches.join(', ')}"',
          status: CheckStatus.failed,
        ));
        warnings.add(
          'Scam Warning: Scanning a QR code ALWAYS DEBITS your account. You NEVER need to enter UPI PIN to receive money or refunds.',
        );
      } else {
        checks.add(SecurityCheckItem(
          title: 'Transaction Note',
          description: '"$tn"',
          status: CheckStatus.passed,
        ));
      }
    }

    // 5. Currency Check
    if (cu != 'INR') {
      penalty += 20;
      checks.add(SecurityCheckItem(
        title: 'Non-INR Currency',
        description: 'Currency is set to $cu instead of standard Indian Rupee (INR).',
        status: CheckStatus.warning,
      ));
    }

    // 6. Unknown / Non-standard UPI parameters
    final knownParams = {'pa', 'pn', 'am', 'cu', 'mc', 'tr', 'tn', 'url', 'mode', 'orgid', 'sign'};
    final unknownParams = params.keys.where((k) => !knownParams.contains(k.toLowerCase())).toList();
    if (unknownParams.isNotEmpty) {
      penalty += 10;
      checks.add(SecurityCheckItem(
        title: 'Unusual Parameters',
        description: 'Contains non-standard parameters: ${unknownParams.join(', ')}',
        status: CheckStatus.warning,
      ));
    }

    // UPI Always caps at max 85 score because scanner cannot certify the real identity of the recipient
    return UpiAnalysisResult(
      scorePenalty: penalty,
      checks: checks,
      warnings: warnings,
      parsedFields: {
        'pa': pa,
        'pn': pn,
        'am': am,
        'tn': tn,
        'cu': cu,
        'mc': mc,
      },
    );
  }
}
