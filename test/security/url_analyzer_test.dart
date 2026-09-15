import 'package:flutter_test/flutter_test.dart';
import 'package:qr/core/security/url_analyzer.dart';
import 'package:qr/models/security_result.dart';

void main() {
  group('UrlAnalyzer Tests', () {
    test('Valid HTTPS safe URL receives zero or low penalty', () {
      final result = UrlAnalyzer.analyze('https://flutter.dev/docs');
      expect(result.scorePenalty, equals(0));
      expect(result.warnings, isEmpty);
      expect(
        result.checks.any((c) => c.title.contains('HTTPS') && c.status == CheckStatus.passed),
        isTrue,
      );
    });

    test('Insecure cleartext HTTP URL triggers warning and penalty', () {
      final result = UrlAnalyzer.analyze('http://example.com');
      expect(result.scorePenalty, greaterThanOrEqualTo(30));
      expect(result.warnings.any((w) => w.contains('Cleartext HTTP')), isTrue);
      expect(
        result.checks.any((c) => c.title.contains('HTTP') && c.status == CheckStatus.warning),
        isTrue,
      );
    });

    test('Direct IP address triggers high penalty and failure check', () {
      final result = UrlAnalyzer.analyze('http://192.168.1.100/login');
      expect(result.scorePenalty, greaterThanOrEqualTo(45));
      expect(
        result.checks.any((c) => c.title.contains('IP Address') && c.status == CheckStatus.failed),
        isTrue,
      );
    });

    test('URL Shorteners like bit.ly trigger warning', () {
      final result = UrlAnalyzer.analyze('https://bit.ly/my-link');
      expect(result.scorePenalty, greaterThanOrEqualTo(25));
      expect(
        result.checks.any((c) => c.title.contains('Shortener') && c.status == CheckStatus.warning),
        isTrue,
      );
    });

    test('Phishing keywords in path trigger sensitive keywords check', () {
      final result = UrlAnalyzer.analyze('http://my-account-verify-login.xyz/password/reset');
      expect(result.scorePenalty, greaterThanOrEqualTo(50));
      expect(
        result.checks.any((c) => c.title.contains('Urgency Keywords')),
        isTrue,
      );
    });

    test('Typosquatting of brands like paypa1 triggers brand impersonation', () {
      final result = UrlAnalyzer.analyze('https://paypa1-security.com');
      expect(
        result.checks.any((c) => c.title.contains('Impersonation') && c.status == CheckStatus.failed),
        isTrue,
      );
    });
  });
}
