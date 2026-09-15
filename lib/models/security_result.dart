import 'package:flutter/material.dart';

enum RiskLevel {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'LOW RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.critical:
        return 'CRITICAL RISK';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.low:
        return const Color(0xFF10B981); // Emerald
      case RiskLevel.medium:
        return const Color(0xFFF59E0B); // Amber
      case RiskLevel.high:
        return const Color(0xFFF97316); // Orange
      case RiskLevel.critical:
        return const Color(0xFFEF4444); // Crimson
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RiskLevel.low:
        return const Color(0x1A10B981);
      case RiskLevel.medium:
        return const Color(0x1AF59E0B);
      case RiskLevel.high:
        return const Color(0x1AF97316);
      case RiskLevel.critical:
        return const Color(0x1AEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.low:
        return Icons.verified_user_rounded;
      case RiskLevel.medium:
        return Icons.warning_amber_rounded;
      case RiskLevel.high:
        return Icons.report_problem_rounded;
      case RiskLevel.critical:
        return Icons.gpp_bad_rounded;
    }
  }
}

enum CheckStatus {
  passed,
  warning,
  failed;

  Color get color {
    switch (this) {
      case CheckStatus.passed:
        return const Color(0xFF10B981);
      case CheckStatus.warning:
        return const Color(0xFFF59E0B);
      case CheckStatus.failed:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case CheckStatus.passed:
        return Icons.check_circle_rounded;
      case CheckStatus.warning:
        return Icons.warning_rounded;
      case CheckStatus.failed:
        return Icons.cancel_rounded;
    }
  }
}

class SecurityCheckItem {
  final String title;
  final String description;
  final CheckStatus status;

  const SecurityCheckItem({
    required this.title,
    required this.description,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'status': status.name,
  };

  factory SecurityCheckItem.fromJson(Map<String, dynamic> json) =>
      SecurityCheckItem(
        title: json['title'] as String,
        description: json['description'] as String,
        status: CheckStatus.values.byName(json['status'] as String),
      );
}

class SecurityResult {
  final RiskLevel riskLevel;
  final int score; // 0 to 100
  final String headline;
  final String summary;
  final List<SecurityCheckItem> checks;
  final List<String> warnings;

  const SecurityResult({
    required this.riskLevel,
    required this.score,
    required this.headline,
    required this.summary,
    required this.checks,
    required this.warnings,
  });

  Map<String, dynamic> toJson() => {
    'riskLevel': riskLevel.name,
    'score': score,
    'headline': headline,
    'summary': summary,
    'checks': checks.map((c) => c.toJson()).toList(),
    'warnings': warnings,
  };

  factory SecurityResult.fromJson(Map<String, dynamic> json) => SecurityResult(
    riskLevel: RiskLevel.values.byName(json['riskLevel'] as String),
    score: json['score'] as int,
    headline: json['headline'] as String,
    summary: json['summary'] as String,
    checks:
        (json['checks'] as List<dynamic>?)
            ?.map((c) => SecurityCheckItem.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [],
    warnings:
        (json['warnings'] as List<dynamic>?)?.map((w) => w as String).toList() ??
        [],
  );
}
