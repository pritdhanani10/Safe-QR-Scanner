import '../../models/qr_type.dart';

class ParsedContent {
  final QRType type;
  final String title;
  final String subtitle;
  final Map<String, dynamic> metadata;

  const ParsedContent({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.metadata,
  });
}

class ContentParser {
  static ParsedContent parse(String raw) {
    final trimmed = raw.trim();

    // 1. UPI Detection
    if (trimmed.startsWith('upi://') || trimmed.contains('upi://pay')) {
      return _parseUpi(trimmed);
    }

    // 2. Wi-Fi Detection (WIFI:S:...;T:...;P:...;;)
    if (trimmed.toUpperCase().startsWith('WIFI:')) {
      return _parseWifi(trimmed);
    }

    // 3. Contact (vCard)
    if (trimmed.toUpperCase().contains('BEGIN:VCARD')) {
      return _parseVCard(trimmed);
    }

    // 4. Email (mailto: or pure email address)
    if (trimmed.toLowerCase().startsWith('mailto:') ||
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmed)) {
      return _parseEmail(trimmed);
    }

    // 5. Phone (tel:)
    if (trimmed.toLowerCase().startsWith('tel:')) {
      final phone = trimmed.substring(4).trim();
      return ParsedContent(
        type: QRType.phone,
        title: phone,
        subtitle: 'Telephone Call Request',
        metadata: {'phone': phone},
      );
    }

    // 6. SMS (sms: or smsto:)
    if (trimmed.toLowerCase().startsWith('sms:') || trimmed.toLowerCase().startsWith('smsto:')) {
      return _parseSms(trimmed);
    }

    // 7. Web URL
    if (trimmed.toLowerCase().startsWith('http://') ||
        trimmed.toLowerCase().startsWith('https://') ||
        trimmed.toLowerCase().startsWith('www.') ||
        _looksLikeUrl(trimmed)) {
      return _parseUrl(trimmed);
    }

    // 8. Plain Text default
    final preview = trimmed.length > 50 ? '${trimmed.substring(0, 50)}...' : trimmed;
    return ParsedContent(
      type: QRType.plainText,
      title: 'Text Content',
      subtitle: preview,
      metadata: {'text': trimmed},
    );
  }

  static bool _looksLikeUrl(String str) {
    final uri = Uri.tryParse(str.startsWith('http') ? str : 'https://$str');
    return uri != null && uri.host.isNotEmpty && uri.host.contains('.');
  }

  static ParsedContent _parseUrl(String raw) {
    String normalized = raw;
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'https://$raw';
    }
    final uri = Uri.tryParse(normalized);
    final host = uri?.host.isNotEmpty == true ? uri!.host : raw;
    final path = uri?.path.isNotEmpty == true && uri!.path != '/' ? uri.path : '';

    return ParsedContent(
      type: QRType.url,
      title: host,
      subtitle: path.isNotEmpty ? path : 'Web Address',
      metadata: {
        'url': normalized,
        'scheme': uri?.scheme ?? '',
        'host': host,
        'path': uri?.path ?? '',
        'query': uri?.queryParameters ?? {},
      },
    );
  }

  static ParsedContent _parseUpi(String raw) {
    final uri = Uri.tryParse(raw);
    final params = uri?.queryParameters ?? {};

    final payeeName = params['pn'] ?? 'Unknown Payee';
    final upiId = params['pa'] ?? 'Unknown VPA';
    final amount = params['am'];
    final note = params['tn'];
    final currency = params['cu'] ?? 'INR';

    String subtitle = upiId;
    if (amount != null && amount.isNotEmpty) {
      subtitle += ' • ₹$amount';
    }

    return ParsedContent(
      type: QRType.upi,
      title: payeeName,
      subtitle: subtitle,
      metadata: {
        'payeeName': payeeName,
        'upiId': upiId,
        'amount': amount,
        'note': note,
        'currency': currency,
        'merchantCode': params['mc'],
        'transactionRef': params['tr'],
        'allParams': params,
      },
    );
  }

  static ParsedContent _parseWifi(String raw) {
    // Format: WIFI:T:WPA;S:MyNetwork;P:MyPassword;H:false;;
    final content = raw.substring(5); // strip WIFI:
    final parts = content.split(';');

    String ssid = 'Unknown Network';
    String authType = 'WPA/WPA2';
    String password = '';
    bool isHidden = false;

    for (final part in parts) {
      if (part.startsWith('S:')) {
        ssid = part.substring(2);
      } else if (part.startsWith('T:')) {
        authType = part.substring(2);
      } else if (part.startsWith('P:')) {
        password = part.substring(2);
      } else if (part.startsWith('H:')) {
        isHidden = part.substring(2).toLowerCase() == 'true';
      }
    }

    return ParsedContent(
      type: QRType.wifi,
      title: ssid,
      subtitle: 'Security: $authType ${isHidden ? "(Hidden)" : ""}',
      metadata: {
        'ssid': ssid,
        'authType': authType,
        'password': password,
        'isHidden': isHidden,
      },
    );
  }

  static ParsedContent _parseVCard(String raw) {
    String name = 'Contact';
    String phone = '';
    String email = '';
    String org = '';

    final lines = raw.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      if (line.startsWith('FN:')) {
        name = line.substring(3).trim();
      } else if (line.startsWith('TEL:') || line.contains('TEL;')) {
        phone = line.substring(line.indexOf(':') + 1).trim();
      } else if (line.startsWith('EMAIL:') || line.contains('EMAIL;')) {
        email = line.substring(line.indexOf(':') + 1).trim();
      } else if (line.startsWith('ORG:')) {
        org = line.substring(4).trim();
      }
    }

    return ParsedContent(
      type: QRType.contact,
      title: name,
      subtitle: [phone, org].where((s) => s.isNotEmpty).join(' • '),
      metadata: {
        'name': name,
        'phone': phone,
        'email': email,
        'organization': org,
      },
    );
  }

  static ParsedContent _parseEmail(String raw) {
    String email = raw;
    String subject = '';
    String body = '';

    if (raw.toLowerCase().startsWith('mailto:')) {
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        email = uri.path;
        subject = uri.queryParameters['subject'] ?? '';
        body = uri.queryParameters['body'] ?? '';
      } else {
        email = raw.substring(7);
      }
    }

    return ParsedContent(
      type: QRType.email,
      title: email,
      subtitle: subject.isNotEmpty ? 'Subject: $subject' : 'Email Compose',
      metadata: {
        'email': email,
        'subject': subject,
        'body': body,
      },
    );
  }

  static ParsedContent _parseSms(String raw) {
    String number = '';
    String message = '';

    final colonIdx = raw.indexOf(':');
    if (colonIdx != -1) {
      final remainder = raw.substring(colonIdx + 1);
      final questionIdx = remainder.indexOf('?');
      if (questionIdx != -1) {
        number = remainder.substring(0, questionIdx);
        final uri = Uri.tryParse('sms:$remainder');
        message = uri?.queryParameters['body'] ?? '';
      } else {
        number = remainder;
      }
    }

    return ParsedContent(
      type: QRType.sms,
      title: number.isNotEmpty ? number : 'SMS',
      subtitle: message.isNotEmpty ? message : 'SMS Message',
      metadata: {
        'phone': number,
        'message': message,
      },
    );
  }
}
