import 'package:flutter_test/flutter_test.dart';
import 'package:qr/core/security/content_parser.dart';
import 'package:qr/models/qr_type.dart';

void main() {
  group('ContentParser Tests', () {
    test('Detects UPI scheme properly', () {
      final parsed = ContentParser.parse('upi://pay?pa=test@upi&pn=Test');
      expect(parsed.type, equals(QRType.upi));
      expect(parsed.title, equals('Test'));
    });

    test('Detects Wi-Fi network format', () {
      final parsed = ContentParser.parse('WIFI:S:MyCafe;T:WPA;P:SuperSecret;;');
      expect(parsed.type, equals(QRType.wifi));
      expect(parsed.title, equals('MyCafe'));
      expect(parsed.metadata['password'], equals('SuperSecret'));
      expect(parsed.metadata['authType'], equals('WPA'));
    });

    test('Detects vCard contact format', () {
      const vcard = '''BEGIN:VCARD
FN:John Doe
TEL:+1234567890
EMAIL:john@example.com
ORG:Security Co
END:VCARD''';
      final parsed = ContentParser.parse(vcard);
      expect(parsed.type, equals(QRType.contact));
      expect(parsed.title, equals('John Doe'));
      expect(parsed.metadata['phone'], equals('+1234567890'));
      expect(parsed.metadata['email'], equals('john@example.com'));
    });

    test('Detects web URL format', () {
      final parsed = ContentParser.parse('https://example.com/login?ref=123');
      expect(parsed.type, equals(QRType.url));
      expect(parsed.title, equals('example.com'));
      expect(parsed.metadata['path'], equals('/login'));
    });

    test('Detects email mailto format', () {
      final parsed = ContentParser.parse('mailto:support@safeqr.org?subject=Help');
      expect(parsed.type, equals(QRType.email));
      expect(parsed.title, equals('support@safeqr.org'));
      expect(parsed.metadata['subject'], equals('Help'));
    });

    test('Detects plain text format', () {
      final parsed = ContentParser.parse('Hello world this is a test note');
      expect(parsed.type, equals(QRType.plainText));
    });
  });
}
