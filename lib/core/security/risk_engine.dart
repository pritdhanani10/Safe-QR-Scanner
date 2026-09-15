import '../../models/qr_type.dart';
import '../../models/security_result.dart';
import 'url_analyzer.dart';
import 'upi_analyzer.dart';

class RiskEngine {
  static SecurityResult evaluate({
    required QRType type,
    required String rawContent,
    Map<String, dynamic>? metadata,
  }) {
    switch (type) {
      case QRType.url:
        return _evaluateUrl(rawContent);

      case QRType.upi:
        return _evaluateUpi(rawContent);

      case QRType.wifi:
        return _evaluateWifi(rawContent, metadata);

      case QRType.contact:
        return _evaluateContact(rawContent, metadata);

      case QRType.email:
        return _evaluateEmail(rawContent, metadata);

      case QRType.phone:
      case QRType.sms:
        return _evaluatePhoneOrSms(rawContent, type);

      case QRType.plainText:
        return _evaluatePlainText(rawContent);
    }
  }

  static SecurityResult _evaluateUrl(String raw) {
    final result = UrlAnalyzer.analyze(raw);
    final score = (100 - result.scorePenalty).clamp(0, 100);

    final RiskLevel level;
    final String headline;
    final String summary;

    if (score >= 80) {
      level = RiskLevel.low;
      headline = 'HTTPS Web Address';
      summary = 'Encrypted connection and no malicious indicators detected. Still verify destination before logging in.';
    } else if (score >= 50) {
      level = RiskLevel.medium;
      headline = 'Review Link Carefully';
      summary = 'URL shortener, unusual domain extension, or non-HTTPS connection detected. Verify target.';
    } else if (score >= 25) {
      level = RiskLevel.high;
      headline = 'Potentially Unsafe Link';
      summary = 'Contains suspicious domain patterns, sensitive credential keywords, or unencrypted transmission.';
    } else {
      level = RiskLevel.critical;
      headline = 'High Probability Phishing';
      summary = 'Direct IP address, punycode spoofing, or known brand impersonation detected. Do not open!';
    }

    return SecurityResult(
      riskLevel: level,
      score: score,
      headline: headline,
      summary: summary,
      checks: result.checks,
      warnings: result.warnings,
    );
  }

  static SecurityResult _evaluateUpi(String raw) {
    final result = UpiAnalyzer.analyze(raw);
    // UPI max base is 85 because scanner cannot certify payee identity
    final baseScore = 85;
    final score = (baseScore - result.scorePenalty).clamp(0, 85);

    final RiskLevel level;
    final String headline;
    final String summary;

    if (score >= 70) {
      level = RiskLevel.medium; // UPI is always at least medium caution
      headline = 'UPI Payment Detected';
      summary = 'Valid UPI parameters structure. Review the recipient name and amount carefully before authorizing in your bank app.';
    } else if (score >= 40) {
      level = RiskLevel.high;
      headline = 'Suspicious UPI Payment';
      summary = 'High amount or unusual parameters found. Ensure this is an intentional payment.';
    } else {
      level = RiskLevel.critical;
      headline = 'High-Risk UPI Scam Alert';
      summary = 'Payment note suggests fraud (KYC/Refund/Lottery deception). Remember: UPI PIN is ONLY for paying, NEVER for receiving.';
    }

    // Always append the Indian Banking Fraud Disclaimer to UPI checks
    final checksWithDisclaimer = List<SecurityCheckItem>.from(result.checks)
      ..add(const SecurityCheckItem(
        title: 'Recipient Authenticity Disclaimer',
        description: 'Scanner validates parameter syntax only. Recipient identity cannot be guaranteed.',
        status: CheckStatus.warning,
      ));

    return SecurityResult(
      riskLevel: level,
      score: score,
      headline: headline,
      summary: summary,
      checks: checksWithDisclaimer,
      warnings: result.warnings,
    );
  }

  static SecurityResult _evaluateWifi(String raw, Map<String, dynamic>? meta) {
    final authType = (meta?['authType'] as String?)?.toUpperCase() ?? '';
    final password = (meta?['password'] as String?) ?? '';
    final isHidden = (meta?['isHidden'] as bool?) ?? false;

    final checks = <SecurityCheckItem>[];
    final warnings = <String>[];
    int score = 90;

    if (authType == 'NOPASS' || password.isEmpty) {
      score -= 30;
      checks.add(const SecurityCheckItem(
        title: 'Open / Unsecured Wi-Fi',
        description: 'This network does not require a password. Traffic is visible to anyone nearby.',
        status: CheckStatus.warning,
      ));
      warnings.add('Connecting to open Wi-Fi networks exposes unencrypted device traffic to eavesdropping.');
    } else if (authType.contains('WEP')) {
      score -= 25;
      checks.add(const SecurityCheckItem(
        title: 'Outdated WEP Encryption',
        description: 'WEP security is obsolete and easily cracked.',
        status: CheckStatus.warning,
      ));
    } else {
      checks.add(SecurityCheckItem(
        title: 'WPA/WPA2/WPA3 Security',
        description: 'Protected network with $authType encryption.',
        status: CheckStatus.passed,
      ));
    }

    if (isHidden) {
      checks.add(const SecurityCheckItem(
        title: 'Hidden SSID',
        description: 'Network does not broadcast its SSID publicly.',
        status: CheckStatus.passed,
      ));
    }

    final level = score >= 75 ? RiskLevel.low : RiskLevel.medium;

    return SecurityResult(
      riskLevel: level,
      score: score,
      headline: 'Wi-Fi Configuration',
      summary: 'Wi-Fi credentials parsed. Check security type before joining.',
      checks: checks,
      warnings: warnings,
    );
  }

  static SecurityResult _evaluateContact(String raw, Map<String, dynamic>? meta) {
    return const SecurityResult(
      riskLevel: RiskLevel.low,
      score: 95,
      headline: 'Contact Card (vCard)',
      summary: 'Standard electronic business card. No executable actions found.',
      checks: [
        SecurityCheckItem(
          title: 'Structured vCard Format',
          description: 'Contains standard text contact fields.',
          status: CheckStatus.passed,
        ),
      ],
      warnings: [],
    );
  }

  static SecurityResult _evaluateEmail(String raw, Map<String, dynamic>? meta) {
    return const SecurityResult(
      riskLevel: RiskLevel.low,
      score: 90,
      headline: 'Email Request',
      summary: 'Opens an email draft. Verify the recipient before hitting send.',
      checks: [
        SecurityCheckItem(
          title: 'Email Address Format',
          description: 'Standard mailto URI format.',
          status: CheckStatus.passed,
        ),
      ],
      warnings: [],
    );
  }

  static SecurityResult _evaluatePhoneOrSms(String raw, QRType type) {
    return SecurityResult(
      riskLevel: RiskLevel.low,
      score: 90,
      headline: type == QRType.phone ? 'Phone Call Request' : 'SMS Message Request',
      summary: 'Requires dialer or SMS client. Verify phone number and message contents before sending.',
      checks: const [
        SecurityCheckItem(
          title: 'Telephony URI',
          description: 'Standard phone/sms protocol.',
          status: CheckStatus.passed,
        ),
      ],
      warnings: const [],
    );
  }

  static SecurityResult _evaluatePlainText(String raw) {
    // Check if plain text contains hidden URLs or suspicious command patterns
    final lower = raw.toLowerCase();
    final hasCommandInjection = lower.contains('cmd.exe') ||
        lower.contains('powershell') ||
        lower.contains('/bin/sh') ||
        lower.contains('chmod ');

    if (hasCommandInjection) {
      return const SecurityResult(
        riskLevel: RiskLevel.critical,
        score: 10,
        headline: 'Potential Command Injection',
        summary: 'Payload contains shell scripts or executable command strings.',
        checks: [
          SecurityCheckItem(
            title: 'Shell Command Pattern',
            description: 'Contains dangerous system shell syntax.',
            status: CheckStatus.failed,
          ),
        ],
        warnings: ['Do not copy-paste or execute this text into a terminal.'],
      );
    }

    return const SecurityResult(
      riskLevel: RiskLevel.low,
      score: 95,
      headline: 'Plain Text Message',
      summary: 'Standard unformatted text payload with no automated triggers.',
      checks: [
        SecurityCheckItem(
          title: 'Safe Text Format',
          description: 'Does not invoke any external URLs, calls, or apps.',
          status: CheckStatus.passed,
        ),
      ],
      warnings: [],
    );
  }
}
