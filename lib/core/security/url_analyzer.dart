import '../../models/security_result.dart';
import '../constants/security_rules.dart';

class UrlAnalysisResult {
  final int scorePenalty;
  final List<SecurityCheckItem> checks;
  final List<String> warnings;

  const UrlAnalysisResult({
    required this.scorePenalty,
    required this.checks,
    required this.warnings,
  });
}

class UrlAnalyzer {
  static UrlAnalysisResult analyze(String urlString) {
    int penalty = 0;
    final List<SecurityCheckItem> checks = [];
    final List<String> warnings = [];

    // Ensure parseable URL
    String normalized = urlString.trim();
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) {
      return UrlAnalysisResult(
        scorePenalty: 60,
        checks: [
          const SecurityCheckItem(
            title: 'URL Format',
            description: 'Malformed or invalid web address structure.',
            status: CheckStatus.failed,
          ),
        ],
        warnings: ['The scanned text cannot be safely parsed as a valid URL.'],
      );
    }

    final host = uri.host.toLowerCase();
    final scheme = uri.scheme.toLowerCase();
    final pathAndQuery = '${uri.path} ${uri.query}'.toLowerCase();

    // 1. HTTPS Protocol Check
    if (scheme == 'https') {
      checks.add(const SecurityCheckItem(
        title: 'HTTPS Encryption',
        description: 'Connection is encrypted using SSL/TLS.',
        status: CheckStatus.passed,
      ));
    } else {
      penalty += 30;
      checks.add(const SecurityCheckItem(
        title: 'Insecure HTTP Connection',
        description: 'Unencrypted cleartext connection. Traffic can be intercepted or modified.',
        status: CheckStatus.warning,
      ));
      warnings.add('Cleartext HTTP connection detected. Login details or passwords may be snooped.');
    }

    // 2. IP Address Host Check
    final isIpAddress = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(host);
    if (isIpAddress) {
      penalty += 45;
      checks.add(SecurityCheckItem(
        title: 'IP Address URL',
        description: 'Direct numeric IP address ($host) instead of a verified domain name.',
        status: CheckStatus.failed,
      ));
      warnings.add('Direct IP address detected. Legitimate services virtually never use raw IP URLs.');
    } else {
      checks.add(const SecurityCheckItem(
        title: 'Domain Resolution',
        description: 'Uses a registered domain name rather than a raw numeric IP.',
        status: CheckStatus.passed,
      ));
    }

    // 3. Punycode & Homograph Attack Check
    final isPunycode = host.contains('xn--');
    bool isTyposquatting = false;
    String matchedBrand = '';

    // Single-pass character normalization to avoid chained replacement conflicts (e.g. 1 -> l -> i)
    final sanitizedHost = host.split('').map((c) {
      switch (c) {
        case '0':
          return 'o';
        case '1':
          return 'l';
        case '3':
          return 'e';
        case '5':
          return 's';
        case '@':
          return 'a';
        default:
          return c;
      }
    }).join('').replaceAll('vv', 'w').replaceAll('rn', 'm');

    for (final brand in SecurityRules.targetedBrands) {
      final isOfficialDomain = host == '$brand.com' ||
          host.endsWith('.$brand.com') ||
          host == '$brand.org' ||
          host.endsWith('.$brand.org') ||
          host == '$brand.in' ||
          host.endsWith('.$brand.in');

      if (!isOfficialDomain) {
        // Did character substitution reveal the brand?
        if (sanitizedHost.contains(brand) && !host.contains(brand)) {
          isTyposquatting = true;
          matchedBrand = brand;
          break;
        }

        // Does the host deceptively include the brand name? (e.g. paypal-security.xyz or account.paypal.spoof.com)
        if (host.contains(brand)) {
          isTyposquatting = true;
          matchedBrand = brand;
          break;
        }
      }
    }

    if (isPunycode) {
      penalty += 50;
      checks.add(const SecurityCheckItem(
        title: 'Internationalized / Punycode Domain',
        description: 'Uses punycode characters (xn--), a classic technique for look-alike deception.',
        status: CheckStatus.failed,
      ));
      warnings.add('Deceptive Unicode/Punycode domain detected.');
    } else if (isTyposquatting) {
      penalty += 45;
      checks.add(SecurityCheckItem(
        title: 'Brand Impersonation / Typosquatting',
        description: 'Domain mimics brand "$matchedBrand" with deceptive spelling or subdomains.',
        status: CheckStatus.failed,
      ));
      warnings.add('Possible phishing attempt mimicking "$matchedBrand".');
    } else {
      checks.add(const SecurityCheckItem(
        title: 'Character Integrity',
        description: 'No punycode or obvious brand impersonation detected in domain.',
        status: CheckStatus.passed,
      ));
    }

    // 4. URL Shorteners Check
    final isShortener = SecurityRules.urlShorteners.any((short) => host == short || host.endsWith('.$short'));
    if (isShortener) {
      penalty += 25;
      checks.add(SecurityCheckItem(
        title: 'URL Shortener Detected',
        description: 'Destination URL is masked by a shortening service ($host).',
        status: CheckStatus.warning,
      ));
      warnings.add('URL shortener masks the actual destination website. Exercise caution.');
    }

    // 5. Suspicious TLD Check
    final hasSuspiciousTld = SecurityRules.suspiciousTlds.any((tld) => host.endsWith(tld));
    if (hasSuspiciousTld) {
      penalty += 20;
      checks.add(const SecurityCheckItem(
        title: 'High-Risk TLD',
        description: 'Domain uses a top-level extension frequently associated with disposable or phishing sites.',
        status: CheckStatus.warning,
      ));
      warnings.add('Domain extension has a high statistical correlation with malicious campaigns.');
    }

    // 6. Suspicious Phishing Keywords in Path / Query
    final foundKeywords = <String>[];
    for (final keyword in SecurityRules.phishingKeywords) {
      if (pathAndQuery.contains(keyword) || host.contains(keyword)) {
        foundKeywords.add(keyword);
      }
    }

    if (foundKeywords.isNotEmpty) {
      // If combined with non-standard or suspicious indicators, increase penalty
      final kwPenalty = (foundKeywords.length * 10).clamp(10, 35);
      penalty += kwPenalty;
      checks.add(SecurityCheckItem(
        title: 'Sensitive Urgency Keywords',
        description: 'Detected keywords associated with account takeovers: ${foundKeywords.take(4).join(', ')}',
        status: foundKeywords.length > 2 ? CheckStatus.failed : CheckStatus.warning,
      ));
      warnings.add('URL contains sensitive keywords (${foundKeywords.take(3).join(', ')}). Never enter passwords or OTPs without verifying.');
    }

    // 7. Excessive Subdomains Check
    final hostSegments = host.split('.');
    if (hostSegments.length >= 4) {
      penalty += 15;
      checks.add(SecurityCheckItem(
        title: 'Complex Subdomain Hierarchy',
        description: 'Domain has ${hostSegments.length} segments, often used to obscure actual domain identity.',
        status: CheckStatus.warning,
      ));
    }

    return UrlAnalysisResult(
      scorePenalty: penalty,
      checks: checks,
      warnings: warnings,
    );
  }
}
