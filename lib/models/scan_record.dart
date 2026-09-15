import 'dart:convert';
import 'qr_type.dart';
import 'security_result.dart';

class ScanRecord {
  final String id;
  final String rawContent;
  final QRType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final SecurityResult securityResult;
  final Map<String, dynamic> metadata;

  const ScanRecord({
    required this.id,
    required this.rawContent,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.securityResult,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'rawContent': rawContent,
    'type': type.name,
    'title': title,
    'subtitle': subtitle,
    'timestamp': timestamp.toIso8601String(),
    'securityResult': securityResult.toJson(),
    'metadata': metadata,
  };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
    id: json['id'] as String,
    rawContent: json['rawContent'] as String,
    type: QRType.values.byName(json['type'] as String),
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    securityResult: SecurityResult.fromJson(
      json['securityResult'] as Map<String, dynamic>,
    ),
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
  );

  String toJsonString() => jsonEncode(toJson());

  factory ScanRecord.fromJsonString(String str) =>
      ScanRecord.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
