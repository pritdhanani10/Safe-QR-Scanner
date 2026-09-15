enum QRType {
  url,
  upi,
  wifi,
  contact,
  email,
  phone,
  sms,
  plainText;

  String get displayName {
    switch (this) {
      case QRType.url:
        return 'Web URL';
      case QRType.upi:
        return 'UPI Payment';
      case QRType.wifi:
        return 'Wi-Fi Network';
      case QRType.contact:
        return 'Contact (vCard)';
      case QRType.email:
        return 'Email Address';
      case QRType.phone:
        return 'Phone Number';
      case QRType.sms:
        return 'SMS Message';
      case QRType.plainText:
        return 'Plain Text';
    }
  }

  String get iconName {
    switch (this) {
      case QRType.url:
        return 'language';
      case QRType.upi:
        return 'account_balance_wallet';
      case QRType.wifi:
        return 'wifi';
      case QRType.contact:
        return 'badge';
      case QRType.email:
        return 'mail';
      case QRType.phone:
        return 'call';
      case QRType.sms:
        return 'sms';
      case QRType.plainText:
        return 'text_fields';
    }
  }
}
