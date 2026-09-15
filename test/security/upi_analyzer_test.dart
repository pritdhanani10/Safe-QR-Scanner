import 'package:flutter_test/flutter_test.dart';
import 'package:qr/core/security/upi_analyzer.dart';
import 'package:qr/models/security_result.dart';

void main() {
  group('UpiAnalyzer Tests', () {
    test('Standard merchant UPI URL is parsed accurately', () {
      final result = UpiAnalyzer.analyze(
        'upi://pay?pa=store@okaxis&pn=Store%20Name&am=450&cu=INR&tn=Order%2099',
      );
      expect(result.parsedFields['pa'], equals('store@okaxis'));
      expect(result.parsedFields['pn'], equals('Store Name'));
      expect(result.parsedFields['am'], equals('450'));
      expect(result.parsedFields['tn'], equals('Order 99'));
      expect(
        result.checks.any((c) => c.title.contains('UPI ID') && c.status == CheckStatus.passed),
        isTrue,
      );
    });

    test('Missing VPA (pa) parameter is flagged as failed', () {
      final result = UpiAnalyzer.analyze('upi://pay?pn=Unknown&am=100');
      expect(result.scorePenalty, greaterThanOrEqualTo(50));
      expect(
        result.checks.any((c) => c.title.contains('Missing UPI ID') && c.status == CheckStatus.failed),
        isTrue,
      );
    });

    test('High-risk scam note keywords (KYC / refund) are detected and flagged', () {
      final result = UpiAnalyzer.analyze(
        'upi://pay?pa=scammer@upi&pn=Support&am=5000&tn=KYC%20verification%20refund',
      );
      expect(result.scorePenalty, greaterThanOrEqualTo(35));
      expect(
        result.checks.any((c) => c.title.contains('High-Risk Note') && c.status == CheckStatus.failed),
        isTrue,
      );
      expect(result.warnings.any((w) => w.contains('DEBITS your account')), isTrue);
    });

    test('High amount pre-fill triggers review warning', () {
      final result = UpiAnalyzer.analyze(
        'upi://pay?pa=merchant@upi&pn=Retail&am=15000',
      );
      expect(
        result.checks.any((c) => c.title.contains('High Amount') && c.status == CheckStatus.warning),
        isTrue,
      );
    });
  });
}
